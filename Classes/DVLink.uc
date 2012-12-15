/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVLink extends TcpLink;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVLink) const int				MasterServerPort;

var (DVLink) const float			TimeoutLength;
var (DVLink) const float			ServerListUpdateFrequency;

var (DVLink) const string 			MasterServerIP;

var (DVLink) string					CurrentID;

var (DVLink) localized string 		lOK;
var (DVLink) localized string 		lNOK;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var bool							bIsOpened;
var bool							bIsConnected;

var string							LastCommandSent;

var DVPlayerController				PC;


/*----------------------------------------------------------
	Game methods
----------------------------------------------------------*/

/*--- Initialization ---*/
simulated function InitLink(DVPlayerController LinkedController)
{
	`log("DVLINK > InitLink");
	PC = LinkedController;
	resolve(MasterServerIP);
}


/*--- Connect to server using player IDs
	CONNECT,Username,Password
---*/
simulated function ConnectToMaster(string Username, string Password)
{
	local array<string> Params;
	
	`log("DVLINK > ConnectToMaster");
	Params.AddItem(Username);
	Params.AddItem(Password);
	SendServerCommand("CONNECT", Params, false);
}


/*--- Register at the master server : player version 
	REG_USER,Username,Email,Password
---*/
reliable client simulated function RegisterUser(string Username, string Email, string Password)
{
	local array<string> Params;
	Params.AddItem(Username);
	Params.AddItem(Email);
	Params.AddItem(Password);
	SendServerCommand("REG_USER", Params, false);
}


/*--- Register at the master server : game server version
	REG_SERVER,ServerName,Email,bUsePassword
---*/
reliable server simulated function RegisterServer(string ServerName, string Email, bool bUsePassword)
{
	local array<string> Params;
	Params.AddItem(ServerName);
	Params.AddItem(Email);
	Params.AddItem(bUsePassword ? "1":"0");
	SendServerCommand("REG_SERVER", Params, false);
}


/*--- Server heartbeat
	HEARTBEAT,ServerID,MapName,GameName,PlayerCount,PlayerMax
---*/
reliable server simulated function Heartbeat(string MapName, string GameName, int PlayerCount, int PlayerMax)
{
	local array<string> Params;
	
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		Params.AddItem(CurrentID);
		Params.AddItem(MapName);
		Params.AddItem(GameName);
		Params.AddItem(""$PlayerCount);
		Params.AddItem(""$PlayerMax);
		SendServerCommand("HEARTBEAT", Params, true);
	}
}


/*--- Get servers
	GET_SERVERS[,GameName[,MapName]]
---*/
reliable client simulated function GetServers(optional string GameName, optional string MapName)
{
	local array<string> Params;
	
	`log("DVLINK > GetServers");
	if (GameName != "")
		Params.AddItem(GameName);
	if (MapName != "")
		Params.AddItem(MapName);
	SendServerCommand("GET_SERVERS", Params, false);
}


/*--- Get the best players
	TOP_PLAYERS,PlayerCount
	LOC_PLAYERS,PlayerCount,ID
---*/
reliable client simulated function GetLeaderboard(int PlayerCount, string ID)
{
	local array<string> Params;
	
	`log("DVLINK > GetLeaderboard");
	PC.CleanBestPlayer();
	Params.AddItem(""$PlayerCount);
	SendServerCommand("TOP_PLAYERS", Params, false);
	Params.AddItem(""$ID);
	SendServerCommand("LOC_PLAYERS", Params, false);
}


/*--- Save the current game statistics : the command is sent by the server for each client
	SAVE_GAME,ServerID,ClientID,kills,deaths,teamkills,rank,shots,headshots
	
---*/
reliable server simulated function SaveGame(int kills, int deaths, int teamkills, int rank, int shots, int headshots, array<int> WeaponScores, string clientID)
{
	local array<string> Params;
	
	// Server + client ID
	Params.AddItem(CurrentID);
	Params.AddItem(clientID);
	
	// Data
	Params.AddItem(""$kills);
	Params.AddItem(""$deaths);
	Params.AddItem(""$teamkills);
	Params.AddItem(""$rank);
	Params.AddItem(""$shots);
	Params.AddItem(""$headshots);
	
	// Saving
	`log("DVLINK > SaveGame for" @clientID);
	SendServerCommand("SAVE_GAME", Params, true);
	SaveWeaponsStats(WeaponScores, clientID);
}


/*--- Save the current game's weapon statistics
	SAVE_WGAME,ClientID,{8*WeaponScores}
---*/
reliable server simulated function SaveWeaponsStats(array<int> WeaponScores, string clientID)
{
	local array<string> Params;
	local int i;
	
	// Server + client ID
	Params.AddItem(CurrentID);
	Params.AddItem(clientID);
	
	// Data
	for (i = 0; i < WeaponScores.Length; i++)
	{
		Params.AddItem("" $ WeaponScores[i]);
	}
	
	// Saving
	`log("DVLINK > SaveWeaponsStats for" @clientID);
	SendServerCommand("SAVE_WGAME", Params, true);
}


/*--- Get all statistics
	GET_GSTATS,ClientID
	GET_WSTATS,ClientID
---*/
reliable client simulated function GetStats()
{
	local array<string> Params;

	Params.AddItem(""$CurrentID);
	SendServerCommand("GET_GSTATS", Params, true);
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
simulated function SendServerCommand(string Command, array<string> Params, bool bRequireNet)
{
	local string ParamsString;
	
	// If failed connexion, retry...
	if (!bIsOpened)
	{
		`log("DVLINK > Reconnecting");
		resolve(MasterServerIP);
	}
	
	// Not yet connected
	else if (CurrentID == "0" && bRequireNet)
	{
		`log("DVLINK > Cannot send commands while disconnected");
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
		
		`log("DVLINK >>" $ Command $"<<");
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
	`log("DVLINK > Command timeout...");
	SignalController("NET", false, "Serveur indisponible");
}


/*--- Server OK processing ---*/
simulated function ProcessACK(string Param)
{
	// Data
	`log("DVLINK > ProcessACK" @LastCommandSent);
	SignalController(LastCommandSent, true, lOK);
	AbortTimeout();
}


/*--- Call back the controller to inform it ---*/
simulated function SignalController(string Command, bool bIsOK, optional string Msg)
{
	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
	else if (PC != None)
		PC.TcpCallback(Command, bIsOK, Msg);
	else
		`log("DVLINK > Could not inform the controller because it does not exist");
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- TCP connexion answer ---*/
event Resolved(IpAddr Addr)
{
	`log("DVLINK > Successfully resolved master server" @IpAddrToString(Addr));
	
	Addr.Port = MasterServerPort;
	AbortTimeout();
	SetTimer(TimeoutLength, false, 'SignalTimeout');
	
	`log("DVLINK > Bound to port" @BindPort());
	if (!Open(Addr))
	{
		`log("DVLINK > Could not connect to master server...");
	}
}


/*--- No connexion ! ---*/
event ResolveFailed()
{
	`log("DVLINK > Failed to resolve master server");
	bIsOpened = false;
	SignalController("NET", false, "Hors ligne");
}


/*--- Server accepted the connexion ---*/
event Opened()
{
	local bool bUsePassword;
	bIsOpened = true;
	`log("DVLINK > Successfully opened master server");
	
	// On client : get the server list
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (DVHUD_Menu(PC.myHUD) != None)
		{
			SetTimer(ServerListUpdateFrequency, true, 'GetServers');
		}
		SignalController("INIT", true, "");
	}
	
	// On server : register
	else
	{
		bUsePassword = WorldInfo.Game.AccessControl.RequiresPassword();
		RegisterServer(WorldInfo.ComputerName, "admin@deepvoid.eu", bUsePassword);
	}
}


/*--- Closed connexion ---*/
event Closed()
{
	`log("DVLINK > Closed master server");
	bIsConnected = false;
	bIsOpened = false;
	SignalController("NET", false);
}


/*--- Text mode : we need to clean this shit up ---*/
event ReceivedText(string Text)
{
	local array<string> InputArray;
	local int i;
	
	ParseStringIntoArray(Text, InputArray, "\n", false);
	for (i = 0; i < InputArray.Length; i++)
	{
		if (Len(InputArray[i]) > 0)
			ReceivedLine(InputArray[i]);
	}
}


/*--- Main event callback : get all server commands and answers ---*/
event ReceivedLine(string Line)
{
	// Init
	local array<string> Command;
	Command = GetServerCommand(Line);
	`log("DVLINK > MS command >" $ Line);
	
	// Error
	if (IsEqual(Command[0], "NOK"))
		SignalController(LastCommandSent, false, lNOK);
	
	// Standard ACK
	else if (IsEqual(Command[0], "OK"))
	{
		// Connection speficic case
		if ((IsEqual(LastCommandSent, "CONNECT") || IsEqual(LastCommandSent, "REG_SERVER")) && Command[1] != "0")
		{
			bIsConnected = true;
			CurrentID = Left(Command[1], 20);
			`log("DVLINK > Connection validated for ID" @CurrentID);
		}
		
		// Default case
		ProcessACK(Command[1]);
	}
		
	// Leaderboards
	else if (IsEqual(Command[0], "TOP_PLAYER"))
		PC.AddBestPlayer(Command[2], int(Command[6]), int(Command[7]), true);
	else if (IsEqual(Command[0], "LOC_PLAYER"))
		PC.AddBestPlayer(Command[2], int(Command[6]), int(Command[7]), false);
	
	// Server list
	else if (IsEqual(Command[0], "SERVER") && PC.myHUD != None)
	{
		if (DVHUD_Menu(PC.myHUD) != None)
		{
			//SERVER,ServerName,Level,IP,Game,Players,MaxPlayers,bIsPassword
			DVHUD_Menu(PC.myHUD).AddServerInfo(
				Command[1],
				Command[2],
				Command[3],
				Command[4], 
				int(Command[5]),
				int(Command[6]),
				Left(Command[7],1) != "0"
			);
		}
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
	
	CurrentID="0"
	TimeoutLength=5.0
	ServerListUpdateFrequency=5.0
	LinkMode=MODE_Text
	ReceiveMode=RMODE_Event
	
	MasterServerIP="master.deepvoid.eu"
	MasterServerPort=9999
}
