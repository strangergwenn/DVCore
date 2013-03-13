/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GH_Menu extends GHUD;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (CoreUI) const float				PopupTimer;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GM_Login							LoginMenu;
var GM_Servers							ServerMenu;
var GM_Stats							StatsMenu;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function PostBeginPlay()
{
	local DVPlayerController PC;
	super.PostBeginPlay();
	
	ServerMenu = GM_Servers(CurrentMenu.GetMenuById(2100));
	LoginMenu = GM_Login(CurrentMenu.GetMenuById(9999));
	StatsMenu = GM_Stats(CurrentMenu.GetMenuById(-10));
	
	PC = DVPlayerController(PlayerOwner);
	PC.FOV(PC.Default.DefaultFOV);
	ApplyResolutionSetting(PC.LocalStats.Resolution, (PC.LocalStats.bFullScreen ? "f" : "w"));
}

/**
 * @brief Apply a resolution code
 * @param code 				Resolution name
 * @param flag				Fullscreen mode
 */
function ApplyResolutionSetting(string code, string flag)
{
	local DVPlayerController PC;
	PC = DVPlayerController(PlayerOwner);
	`log("GHM > ApplyResolutionSetting" @code @flag);
	
	switch (code)
	{
		case ("720p"):
			PC.ConsoleCommand("SetRes 1280x720" $flag);
			break;
		case ("1080p"):
			PC.ConsoleCommand("SetRes 1920x1080" $flag);
			break;
		case ("max"):
			PC.ConsoleCommand("SetRes 6000x3500" $flag);
			break;
	}
}

/**
 * @brief Launch autoconnection
*/
simulated function AutoConnect()
{
	DVPlayerController(PlayerOwner).AutoConnect();
}

/**
 * @brief Launch autoconnection
*/
simulated function AutoConnectLaunched()
{
	LoginMenu.SetConnectState(1);
}

/**
 * @brief Called when the connection has been established
 */
function SignalConnected(string usr)
{
	DVPlayerController(PlayerOwner).SignalConnected();
	LoginMenu.SetConnectState(2);
	LoginMenu.AutoSuccessQuit(usr);
}

/**
 * @brief Show a command response code
 */
function DisplayResponse (bool bSuccess, string Msg, string Command)
{
	if (LoginMenu.StoredLevel < 2)
	{
		LoginMenu.DisplayResponse(bSuccess, Msg, Command);
	}
}

/**
 * @brief User data
 */
function AddUserInfo()
{
	StatsMenu.UpdateLeaderBoard();
}

/**
 * @brief Server data
 */  
function AddServerInfo(string ServerName, string Level, string IP, string Game, int Players, int MaxPlayers, bool bIsPassword)
{
	ServerMenu.AddServerInfo(ServerName, Level, IP, Game, Players, MaxPlayers, bIsPassword);
}

function DisplayServerInfo()
{
	ServerMenu.UpdateList();
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	PopupTimer=2.0
}
