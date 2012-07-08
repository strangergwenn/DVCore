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

var DVCoreUI_Menu   					HudMovie;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Spawn ---*/ 
simulated function PostBeginPlay()
{
	// Init
	local DVPlayerController PC;
	super.PostBeginPlay();
	PC = DVPlayerController(PlayerOwner);
	
	// Movie
	HudMovie = new HUDClass;
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);
	HudMovie.Start();
	HudMovie.Advance(0);
	HudMovie.PC = PC;
	
	// User settings
	HudMovie.ApplyResolutionSetting(PC.LocalStats.Resolution, (PC.LocalStats.bFullScreen ? "f" : "w"));
}


/*--- Launch autoconnection ---*/
simulated function AutoConnect()
{
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
	if (HudMovie.StoredLevel < 2)
	{
		HudMovie.DisplayResponse(bSuccess, Msg, Command);
		if (HudMovie.bIsPopupVisible)
		{
			CancelHide();
			SetTimer(PopupTimer, false, 'HidePopup');
		}
	}
}


/*--- Cancel every timer closing the popup ---*/
function CancelHide()
{
	if (HudMovie.bIsPopupVisible && HudMovie.StoredLevel < 2)
	{
		ClearTimer('HidePopup');
	}
}


/*--- Server data ---*/  
function AddServerInfo(string ServerName, string Level, string IP, string Game, int Players, int MaxPlayers, bool bIsPassword)
{
	HudMovie.AddServerInfo(ServerName, Level, IP, Game, Players, MaxPlayers, bIsPassword);
	HudMovie.UpdateServerList();
}


/*--- Popup suppression ---*/
function HidePopup()
{
	HudMovie.HidePopup(true);
	HudMovie.PopupState = PS_None;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	PopupTimer=2.0
	HUDClass=class'DVCoreUI_Menu'
}
