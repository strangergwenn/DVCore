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
reliable client simulated function InitLink(DVPlayerController LinkedController)
{
	`log("DVLINK : InitLink");
	PC = LinkedController;
	resolve(MasterServerIP);
}


/*--- Connect to server using player IDs ---*/
reliable client simulated function ConnectToMaster(string Username, string Password)
{
	local array<string> Params;
	
	`log("DVLINK : ConnectToMaster");
	Params.AddItem(Username);
	Params.AddItem(Password);
	SendServerCommand("CONNECT", Params, false);
}


/*--- Register at the master server : player version ---*/
reliable client simulated function RegisterUser(string Username, string Email, string Password)
{
	local array<string> Params;
	
	`log("DVLINK : RegisterUser");
	Params.AddItem(Username);
	Params.AddItem(Email);
	Params.AddItem(Password);
	SendServerCommand("REG_USER", Params, false);
}


/*--- Register at the master server : game server version ---*/
reliable client simulated function RegisterServer(string Username, string Email, string Password)
{
	local array<string> Params;
	
	`log("DVLINK : RegisterServer");
	Params.AddItem(Username);
	Params.AddItem(Email);
	Params.AddItem(Password);
	SendServerCommand("REG_SERVER", Params, false);
}


/*--- Server heartbeat ---*/
reliable client simulated function Heartbeat(string MapName, string GameName, int PlayerCount, int PlayerMax)
{
	local array<string> Params;
	
	`log("DVLINK : Heartbeat");
	Params.AddItem(""$CurrentID);
	Params.AddItem(MapName);
	Params.AddItem(GameName);
	Params.AddItem(""$PlayerCount);
	Params.AddItem(""$PlayerMax);
	SendServerCommand("HEARTBEAT", Params, true);
}


/*--- Get servers ---*/
reliable client simulated function GetServers(optional string GameName, optional string MapName)
{
	local array<string> Params;
	
	`log("DVLINK : GetServers");
	Params.AddItem(GameName);
	Params.AddItem(MapName);
	SendServerCommand("GET_SERVERS", Params, false);
}


/*--- Get the best players ---*/
reliable client simulated function GetLeaderboard(int PlayerCount, int LocalOffset)
{
	local array<string> Params;
	
	`log("DVLINK : GetLeaderboard");
	Params.AddItem(""$PlayerCount);
	SendServerCommand("TOP_PLAYERS", Params, false);
	Params.AddItem(""$LocalOffset);
	SendServerCommand("LOC_PLAYERS", Params, false);
}


/*--- Save the current game statistics ---*/
reliable client simulated function SaveGame(int kills, int deaths, int teamkills, int rank, int shots, array<int> WeaponScores)
{
	local array<string> Params;
	
	`log("DVLINK : SaveGame");
	Params.AddItem(""$CurrentID);
	Params.AddItem(""$kills);
	Params.AddItem(""$deaths);
	Params.AddItem(""$teamkills);
	Params.AddItem(""$rank);
	Params.AddItem(""$shots);
	SendServerCommand("SAVE_GAME", Params, true);
	
	SaveWeaponsStats(WeaponScores);
}


/*--- Save the current game's weapon statistics ---*/
reliable client simulated function SaveWeaponsStats(array<int> WeaponScores)
{
	local array<string> Params;
	local int i;
	
	`log("DVLINK : SaveWeaponsStats");
	for (i = 0; i < WeaponScores.Length; i++)
	{
		Params.AddItem("" $ WeaponScores[i]);
	}
	SendServerCommand("SAVE_WGAME", Params, true);
}


/*--- Get all statistics ---*/
reliable client simulated function GetStats()
{
	local array<string> Params;
	`log("DVLINK : GetStats");

	Params.AddItem(""$CurrentID);
	SendServerCommand("GET_GSTATS", Params, true);
	SendServerCommand("GET_LSTATS", Params, true);
	SendServerCommand("GET_WSTATS", Params, true);
}


/*--- Disarm timeout ---*/
simulated function AbortTimeout()
{
	ClearTimer('SignalTimeout');
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/*--- Send a command to the master server ---*/
reliable client simulated function SendServerCommand(string Command, array<string> Params, bool bRequireNet)
{
	local string ParamsString;
	
	// If failed connexion, retry...
	if (!bIsOpened)
	{
		`log("DVLINK : Reconnecting");
		resolve(MasterServerIP);
	}
	
	// Not yet connected
	else if (CurrentID == 0 && bRequireNet)
	{
		`log("DVLINK : Cannot send commands while disconnected");
		return;
	}
	
	// Good to go
	else
	{
		LastCommandSent = Command;
		if (Params.Length > 0)
		{
			JoinArray(Params, ParamsString, ",");
			Command $= ",";
			Command $= ParamsString;
		}
		
		`log("DVLINK : Sending command " $ Command);
		AbortTimeout();
		SetTimer(TimeoutLength, false, 'SignalTimeout');
		SendText(Command $"\n");
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
	`log("DVLINK : Command timeout...");
	SignalController("NET", false, "Serveur indisponible");
}


/*--- Server OK processing ---*/
simulated function ProcessACK(string Param)
{
	// Data
	`log("DVLINK : ProcessACK" @LastCommandSent);
	SignalController(LastCommandSent, true, "Requête validée !");
	AbortTimeout();
}


/*--- Call back the controller to inform it ---*/
simulated function SignalController(string Command, bool bIsOK, optional string Msg)
{
	if (PC != None)
		PC.TcpCallback(Command, bIsOK, Msg);
	else
		`log("DVLINK : Could not inform the controller because it does not exist");
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- TCP connexion answer ---*/
event Resolved(IpAddr Addr)
{
	`log("DVLINK : Successfully resolved master server" @IpAddrToString(Addr));
	
	Addr.Port = MasterServerPort;
	AbortTimeout();
	SetTimer(TimeoutLength, false, 'SignalTimeout');
	
	`Log("DVLINK : Bound to port" @BindPort());
	if (!Open(Addr))
	{
		`log ("DVLINK : Could not connect to master server...");
	}
}


/*--- No connexion ! ---*/
event ResolveFailed()
{
	`log("DVLINK : Failed to resolve master server");
	bIsConnected = false;
	bIsOpened = false;
	SignalController("NET", false, "Hors ligne");
}


/*--- Server accepted the connexion ---*/
event Opened()
{
	`log("DVLINK : Successfully opened master server");
	bIsConnected = false;
	bIsOpened = true;
	SetTimer(ServerListUpdateFrequency, true, 'GetServers'); 
}


/*--- Closed connexion ---*/
event Closed()
{
	`log("DVLINK : Closed master server");
	bIsConnected = false;
	bIsOpened = false;
	SignalController("NET", false);
}


/*--- Text mode ---*/
event ReceivedText(string Text)
{
	if (Len(Text) > 0)
		ReceivedLine(Text);
}


/*--- Main event callback : get all server commands and answers ---*/
event ReceivedLine(string Line)
{
	// Init
	local array<string> Command;
	Command = GetServerCommand(Line);
	`log("DVLINK : Received master command >" $ Command[0] $"<");
	
	// Standard ACK
	if (IsEqual(Command[0], "OK"))
	{
		// Connection speficic case
		if (IsEqual(LastCommandSent, "CONNECT"))
		{
			CurrentID = int(Command[1]);
			bIsConnected = true;
		}
		
		// Default case
		ProcessACK(Command[1]);
	}
		
	// Error
	else if (IsEqual(Command[0], "NOK"))
		SignalController(LastCommandSent, false, "Requête refusée");
		
	// Leaderboards
	else if (IsEqual(Command[0], "TOP_PLAYER"))
		PC.AddBestPlayer(Command[2], int(Command[6]), int(Command[7]), true);
	else if (IsEqual(Command[0], "LOC_PLAYER"))
		PC.AddBestPlayer(Command[2], int(Command[6]), int(Command[7]), false);
	
	// Server list
	else if (IsEqual(Command[0], "SERVER"))
	{
		DVHUD_Menu(PC.myHUD).AddServerInfo(
			Command[1],
			Command[2],
			Command[3],
			Command[4], 
			int(Command[5]),
			int(Command[6])
		);
	}
	
	// Player statistics
	else if (  InStr(Command[0], "GET_GSTATS") != -1
			|| InStr(Command[0], "GET_LSTATS") != -1
			|| InStr(Command[0], "GET_WSTATS") != -1
	){
		PC.TcpGetStats(Command);
	}
}


/*--- Check if command is as expected ---*/
simulated function bool IsEqual(string Data, string Command)
{
	return (InStr(Data, Command) != -1);
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
	LinkMode=MODE_Text
	ReceiveMode=RMODE_Event
	
	MasterServerIP="master.deepvoid.eu"
	MasterServerPort=9999
}
