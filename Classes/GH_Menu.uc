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

var GMenu								LoginMenu;


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
	
	LoginMenu = CurrentMenu.GetMenuById(3000);
	
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
	`log("DVM > ApplyResolutionSetting" @code @flag);
	switch (code)
	{
		case ("720p"):
			ConsoleCommand("SetRes 1280x720" $flag);
			break;
		case ("1080p"):
			ConsoleCommand("SetRes 1920x1080" $flag);
			break;
		case ("max"):
			ConsoleCommand("SetRes 6000x3500" $flag);
			break;
	}
}


/*--- Launch autoconnection ---*/
simulated function AutoConnect()
{
	//HudMovie.SetConnectState(1);
}


/*--- Called when the connection has been established ---*/
function SignalConnected()
{
	DVPlayerController(PlayerOwner).SignalConnected();
	//HudMovie.SetConnectState(2);
}


/*--- Show a command response code ---*/
function DisplayResponse (bool bSuccess, string Msg, string Command)
{
	/*if (HudMovie.StoredLevel < 2)
	{
		//HudMovie.DisplayResponse(bSuccess, Msg, Command);
		if (//HudMovie.bIsPopupVisible)
		{
			CancelHide();
			SetTimer(PopupTimer, false, 'HidePopup');
		}
	}*/
}


/*--- Cancel every timer closing the popup ---*/
function CancelHide()
{
	/*if (HudMovie.bIsPopupVisible && HudMovie.StoredLevel < 2)
	{
		ClearTimer('HidePopup');
	}*/
}


/*--- Server data ---*/  
function AddServerInfo(string ServerName, string Level, string IP, string Game, int Players, int MaxPlayers, bool bIsPassword)
{
	//HudMovie.AddServerInfo(ServerName, Level, IP, Game, Players, MaxPlayers, bIsPassword);
	//HudMovie.UpdateServerList();
}


/*--- Popup suppression ---*/
function HidePopup()
{
	//HudMovie.HidePopup(true);
	//HudMovie.PopupState = PS_None;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	PopupTimer=2.0
}
