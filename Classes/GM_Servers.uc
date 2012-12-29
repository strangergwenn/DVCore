/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwenna�l ARBONA
 **/

class GM_Servers extends GListMenu;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var bool 								bIsPasswordProtected;

var string								ServerURL;

var array<string>						ServerList;
var array<string>						IPList;


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
	idx = IPList.Find(IP);
	
	if (MaxPlayers != 0)
	{
		if (idx < 0)
		{
			ServerList.AddItem(FormatServerInfo(ServerName, Level, Game, Players, MaxPlayers, bIsPassword));
			IPList.AddItem(IP);
		}
		else
		{
			ServerList[idx] = FormatServerInfo(ServerName, Level, Game, Players, MaxPlayers, bIsPassword);
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
		ServerString = GListItem(Caller).Data;
		ServerURL = IPList[ServerList.Find(ServerString)];
		bIsPasswordProtected = (InStr(ServerString, lServerProtected) != -1);
	}
	else
	{
		Launch.Deactivate();
		CurrentData = "";
	}
}


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

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
			ConsoleCommand("open " $ ServerURL $ "?game=");
		}
		else
		{
			ConsoleCommand("open " $ ServerURL $ "?game=");
		}
	}
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
		GListItem(Temp).SetData(ServerList[i], "");
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
	ListItemClass=class'GLI_LargeClean'
}
