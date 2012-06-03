/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVHUD_Menu extends UDKHUD;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (CoreUI) const class<DVCoreUI_Menu>	HUDClass;

var (CoreUI) const float				PopupTimer;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var DVCoreUI_Menu   				HudMovie;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Spawn ---*/ 
simulated function PostBeginPlay()
{
	local DVPlayerController PC;
	super.PostBeginPlay();
	PC = DVPlayerController(PlayerOwner);
	
	HudMovie = new HUDClass;
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);
	HudMovie.Start();
	HudMovie.Advance(0);
	HudMovie.PC = PC;
	
	// User settings
	HudMovie.ApplyResolutionSetting(PC.LocalStats.Resolution, (PC.LocalStats.bFullScreen ? "f" : "w"));
	`log("HUD is ready");
}


/*--- Launch autoconnection in one second ---*/
simulated function DelayedAutoConnect()
{
	ClearTimer('AutoConnect');
	SetTimer(1.0, false, 'AutoConnect');
}


/*--- Launch autoconnection ---*/
simulated function AutoConnect()
{
	DVPlayerController(PlayerOwner).AutoConnect();
	HudMovie.SetConnectState(1);
}


/*--- Called when the connection has been established ---*/
function SignalConnected()
{
	DVPlayerController(PlayerOwner).SignalConnected();
	HudMovie.SetConnectState(2);
}


/*--- Show a command response code ---*/
function DisplayResponse (bool bSuccess, string Msg, string Command)
{
	HudMovie.DisplayResponse(bSuccess, Msg, Command);
	if (HudMovie.bIsPopupVisible)
	{
		ClearTimer('HidePopup');
		SetTimer(PopupTimer, false, 'HidePopup');
	}
}


/*--- Popup suppression ---*/
function HidePopup()
{
	HudMovie.HidePopup(true);
	HudMovie.bIsInRegisterPopup = false;
}


/*--- Server data ---*/  
function AddServerInfo(string ServerName, string Level, string IP, string Game, int Players, int MaxPlayers)
{
	HudMovie.AddServerInfo(ServerName, Level, IP, Game, Players, MaxPlayers);
	HudMovie.UpdateServerList();
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	PopupTimer=2.0
	HUDClass=class'DVCoreUI_Menu'
}
