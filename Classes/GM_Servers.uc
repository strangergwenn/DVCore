/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Servers extends GListMenu;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var bool 								bIsPasswordProtected;

var GButton 							Spectate;

var string								ServerURL;

var array<string>						IPList;
var array<string>						ServerList;
var array<Texture2D>					PictureList;


/*----------------------------------------------------------
	Core
----------------------------------------------------------*/

/**
 * @brief UI setup
 */
simulated function SpawnUI()
{
	Super.SpawnUI();
	Spectate = AddButton(Vect(0,0,0), lMSpectateText, lMSpectateComment, GoSpectate);
	Spectate.Deactivate();
}


/**
 * @brief Tick event (thread)
 * @param DeltaTime			Time since last tick
 */
simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	if (CurrentData == "" && Launch != None)
	{
		Launch.Deactivate();
		Spectate.Deactivate();
	}
}


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Add a server entry to the menu
 * @param ServerName			Server friendly name
 * @param Level					Level name
 * @param IP					IP address to connect to
 * @param Game					Current game mode
 * @param Players				Current players
 * @param MaxPlayers			Max players
 * @param bIsPassword			true if password protected
 */
function AddServerInfo(string ServerName, string Level, string IP, string Game, int Players, int MaxPlayers, bool bIsPassword)
{
	local int idx;
	local Texture2D MapPicture;
	idx = IPList.Find(IP);
	MapPicture = class'DVMapInfo'.static.GetTextureFromLevel(Level);
	
	if (MaxPlayers != 0)
	{
		if (idx < 0)
		{
			ServerList.AddItem(FormatServerInfo(ServerName, Level, Game, Players, MaxPlayers, bIsPassword));
			IPList.AddItem(IP);
			PictureList.AddItem(MapPicture);
		}
		else
		{
			ServerList[idx] = FormatServerInfo(ServerName, Level, Game, Players, MaxPlayers, bIsPassword);
			PictureList[idx] = MapPicture;
		}
	}
}

/**
 * @brief Selection callback
 * @param Reference				Caller actor
 */
delegate GoSelect(Actor Caller)
{
	local Actor Temp;
	local string ServerString;
	CurrentData = GListItem(Caller).Data;
	
	foreach AllActors(ListItemClass, Temp)
	{
		if (Temp != Caller && GToggleButton(Temp).GetState())
		{
			GToggleButton(Temp).SetState(false);
		}
	}
	
	if (GToggleButton(Caller).GetState())
	{
		Launch.Activate();
		Spectate.Activate();
		ServerString = GListItem(Caller).Data;
		ServerURL = IPList[ServerList.Find(ServerString)];
		bIsPasswordProtected = (InStr(ServerString, lServerProtected) != -1);
	}
	else
	{
		Launch.Deactivate();
		Spectate.Deactivate();
		CurrentData = "";
	}
}


/**
 * @brief Launch button
 * @param Reference				Caller actor
 */
delegate GoLaunch(Actor Caller)
{
	if (ServerURL != "")
	{
		if (bIsPasswordProtected)
		{
			//TODO
			ConsoleCommand("open " $ ServerURL $ "?game=");
		}
		else
		{
			ConsoleCommand("open " $ ServerURL $ "?game=");
		}
	}
}


/**
 * @brief Spectate button
 * @param Reference				Caller actor
 */
delegate GoSpectate(Actor Caller)
{
	ServerURL $= "?SpectatorOnly=1";
	GoLaunch(Caller);
}



/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Create a map list
 */
function UpdateList()
{
	local byte i;
	local GButton Temp;
	
	EmptyList();
	for (i = 0; i < ServerList.Length; i++)
	{
		Temp = AddButton(
			ListOffset + ListCount * ScrollOffset, 
			ServerList[i],
			"Open server",
			GoSelect,
			ListItemClass
		);
		GListItem(Temp).SetData(i, ServerList[i]);
		GListItem(Temp).SetPicture(PictureList[i]);
		ListCount++;
	}
}


/**
 * @brief Add a server entry to the menu
 * @param ServerName			Server friendly name
 * @param Level					Level name
 * @param Game					Current game mode
 * @param Players				Current players
 * @param MaxPlayers			Max players
 * @param bIsPassword			true if password protected
 * @return a formatted string
 */
function string FormatServerInfo(string ServerName, string Level, string Game, int Players, int MaxPlayers, bool bIsPassword)
{
	ServerName = Caps(ServerName);
	
	if (bIsPassword)
		ServerName @= "-" @lServerProtected;
	
	Game = GetRightMost(Game);
	Level = Caps(Repl(Level, ".udk", "", false));
	return (ServerName $ "\n" $Players $"/" $MaxPlayers @ lPlayers $"," @Game $"\n" $Level);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Index=2100
	MenuName="Servers"
	MenuComment="Network games"
	ListOffset=(X=120,Y=-50,Z=30)
	ScrollOffset=(X=0,Y=0,Z=90)
}
