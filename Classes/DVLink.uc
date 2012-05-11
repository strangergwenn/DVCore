/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author GwennaÃ«l ARBONA
 **/

class DVLink extends TcpLink;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVLink) const int				MasterServerPort;

var (DVLink) const float			TimeoutLength;
var (DVLink) const float			ServerListUpdateFrequency;

var (DVLink) const string 			MasterServerIP;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var bool							bIsOpened;
var bool							bIsConnected;

var int								CurrentID;

var string							LastCommandSent;

var DVPlayerController				PC;


/*----------------------------------------------------------
	Game methods
----------------------------------------------------------*/

/*--- Initialization ---*/
simulated function InitLink(DVPlayerController LinkedController)
{
	`log("InitLink");
	PC = LinkedController;
	resolve(MasterServerIP);
}


/*--- Connect to server using player IDs ---*/
simulated function ConnectToMaster(string Username, string Password)
{
	local array<string> Params;
	
	`log("ConnectToMaster");
	Params.AddItem(Username);
	Params.AddItem(Password);
	SendServerCommand("CONNECT", Params, false);
	GetStats();
}


/*--- Register at the master server : player version ---*/
simulated function RegisterUser(string Username, string Email, string Password)
{
	local array<string> Params;
	
	`log("RegisterUser");
	Params.AddItem(Username);
	Params.AddItem(Email);
	Params.AddItem(Password);
	SendServerCommand("REG_USER", Params, false);
}


/*--- Register at the master server : game server version ---*/
simulated function RegisterServer(string Username, string Email, string Password)
{
	local array<string> Params;
	
	`log("RegisterServer");
	Params.AddItem(Username);
	Params.AddItem(Email);
	Params.AddItem(Password);
	SendServerCommand("REG_SERVER", Params, false);
}


/*--- Server heartbeat ---*/
simulated function Heartbeat(string MapName, string GameName, int PlayerCount, int PlayerMax)
{
	local array<string> Params;
	
	`log("Heartbeat");
	Params.AddItem(""$CurrentID);
	Params.AddItem(MapName);
	Params.AddItem(GameName);
	Params.AddItem(""$PlayerCount);
	Params.AddItem(""$PlayerMax);
	SendServerCommand("HEARTBEAT", Params, true);
}


/*--- Get servers ---*/
simulated function GetServers(optional string GameName, optional string MapName)
{
	local array<string> Params;
	
	`log("GetServers");
	Params.AddItem(GameName);
	Params.AddItem(MapName);
	SendServerCommand("GET_SERVERS", Params, false);
}


/*--- Get the best players ---*/
simulated function GetLeaderboard(int Count)
{
	local array<string> Params;
	
	`log("GetLeaderboard");
	Params.AddItem(""$Count);
	SendServerCommand("TOP_PLAYERS", Params, false);
}


/*--- Save the current game statistics ---*/
simulated function SaveGame(int kills, int deaths, int teamkills, int rank, int shots)
{
	local array<string> Params;
	
	`log("SaveGame");
	Params.AddItem(""$CurrentID);
	Params.AddItem(""$kills);
	Params.AddItem(""$deaths);
	Params.AddItem(""$teamkills);
	Params.AddItem(""$rank);
	Params.AddItem(""$shots);
	SendServerCommand("SAVE_GAME", Params, true);
}


/*--- Save the current game's weapon statistics ---*/
simulated function SaveWeaponsStats(array<int> WeaponScores)
{
	local array<string> Params;
	local int i;
	
	`log("SaveWeaponsStats");
	for (i = 0; i < WeaponScores.Length; i++)
	{
		Params.AddItem("" $ WeaponScores[i]);
	}
	SendServerCommand("SAVE_WGAME", Params, true);
}


/*--- Get all statistics ---*/
simulated function GetStats()
{
	local array<string> Params;

	Params.AddItem(""$CurrentID);
	SendServerCommand("GET_GSTATS", Params, true);
	SendServerCommand("GET_LSTATS", Params, true);
	SendServerCommand("GET_WSTATS", Params, true);
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/*--- Send a command to the master server ---*/
simulated function SendServerCommand(string Command, array<string> Params, bool bRequireNet)
{
	local string ParamsString;
	
	// If failed connexion, retry...
	if (!bIsOpened)
	{
		`log("Reconnecting");
		resolve(MasterServerIP);
	}
	
	// Not yet connected
	else if (CurrentID == 0 && bRequireNet)
	{
		`log("Cannot send commands while disconnected");
		return;
	}
	
	// Good to go
	else
	{
		JoinArray(Params, ParamsString, ",");
		LastCommandSent = Command;
		Command $= ",";
		Command $= ParamsString;
		
		`log("Sending command " $ Command);
		SetTimer(TimeoutLength, false, 'SignalTimeout');
		SendText(Command);
	}
}


/*--- Command reception ---*/
simulated function array<string> GetServerCommand(string Input)
{
	local array<string> OutputArray;
	ParseStringIntoArray(Input, OutputArray, ",", false);
	return OutputArray;
}


/*--- Command timeout ---*/
simulated function SignalTimeout()
{
	`warn("Command timeout...");
	SignalController("NET", false, "Serveur indisponible");
}


/*--- Server OK processing ---*/
simulated function ProcessACK(string Param)
{
	switch(LastCommandSent)
	{
		case "CONNECT":
			CurrentID = int(Param);
			bIsConnected = true;
			break;
	 }
	SignalController(LastCommandSent, true, "Requête validée !");
}


/*--- Call back the controller to inform it ---*/
simulated function SignalController(string Command, bool bIsOK, optional string Msg)
{
	if (PC != None)
		PC.TcpCallback(Command, bIsOK, Msg);
	else
		`warn("Could not inform the controller because it does not exist");
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- TCP connexion answer ---*/
event Resolved(IpAddr Addr)
{
	`log("Successfully resolved master server");
	
	Addr.Port = MasterServerPort;
	SetTimer(TimeoutLength, false, 'SignalTimeout');
	
	if (!Open(Addr))
	{
		`warn ("Could not connect to master server...");
	}
}


/*--- No connexion ! ---*/
event ResolveFailed()
{
	`log("Failed to resolve master server");
	bIsConnected = false;
	bIsOpened = false;
	SignalController("NET", false, "Hors ligne");
}


/*--- Server accepted the connexion ---*/
event Opened()
{
	`log("Successfully opened master server");
	bIsConnected = false;
	bIsOpened = true;
	SetTimer(ServerListUpdateFrequency, true, 'GetServers'); 
}


/*--- Closed connexion ---*/
event Closed()
{
	`log("Closed master server");
	bIsConnected = false;
	bIsOpened = false;
	SignalController("NET", false);
}


/*--- Main event callback : get all server commands and answers ---*/
event ReceivedLine(string Line)
{
	// Init
	local array<string> Command;
	Command = GetServerCommand(Line);
	`log("Received master command : " $ Line);
	
	// Parsing
	switch (Command[0])
	{
		// Standard ACK
		case "OK":
			ProcessACK(Command[1]);
			break;
		
		// Error
		case "NOK":
			SignalController(LastCommandSent, false, "Requête refusée");
			break;
		
		// Leaderboard
		case "TOP_PLAYER":
			break;
		
		// Server list
		case "SERVER":
			DVHUD_Menu(PC.myHUD).AddServerInfo(
				Command[1],
				Command[2],
				Command[3],
				Command[4], 
				int(Command[5]),
				int(Command[6])
			);
			break;
		
		// Global player statistics
		case "GET_GSTATS":
			break;
		
		// Last game statistics
		case "GET_LSTATS":
			break;
		
		// Weapons statistics
		case "GET_WSTATS":
			break;
	}
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	bIsOpened=false
	bIsConnected=false
	
	CurrentID=0
	TimeoutLength=5.0
	ServerListUpdateFrequency=20.0
	
	MasterServerIP="server2.arbona.eu"
	MasterServerPort=1337
}

