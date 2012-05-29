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

var DVUserStats						LocalStats;
var DVUserStats						GlobalStats;

var DVCoreUI_Menu   				HudMovie;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Spawn ---*/ 
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	HudMovie = new HUDClass;
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);
	HudMovie.Start();
	HudMovie.Advance(0);
	HudMovie.PC = DVPlayerController(PlayerOwner);
	
	// User settings
	LocalStats = new class'DVUserStats';
	GlobalStats = new class'DVUserStats';
	GlobalStats.EmptyStats();
	HudMovie.ApplyResolutionSetting(LocalStats.Resolution, (LocalStats.bFullScreen ? "f" : "w"));
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
	`log("AutoConnect");
	if (Len(LocalStats.UserName) > 3
	 && Len(LocalStats.Password) > 3
	 && DVPlayerController(PlayerOwner).MasterServerLink != None)
	{
		DVPlayerController(PlayerOwner).MasterServerLink.ConnectToMaster(
			LocalStats.UserName, LocalStats.Password);
		HudMovie.SetConnectState(1);
	}
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


/*--- Called when the connection has been established ---*/
function SignalConnected()
{
	HudMovie.SetConnectState(2);
	ConsoleCommand("SetName" @LocalStats.UserName);
	`log("Setting name " @LocalStats.UserName);
	
	if (LocalStats.bWasUploaded == false)
	{
		DVPlayerController(PlayerOwner).MasterServerLink.SaveGame(
			LocalStats.Kills,
			LocalStats.Deaths,
			LocalStats.TeamKills,
			LocalStats.Rank,
			LocalStats.ShotsFired,
			LocalStats.WeaponScores
		);
		LocalStats.SetBoolValue("bWasUploaded", true);
		LocalStats.SaveConfig();
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
