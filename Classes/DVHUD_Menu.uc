/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVHUD_Menu extends UDKHUD;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var DVUserStats						LocalStats;
var DVUserStats						GlobalStats;

var const class<DVCoreUI_Menu>		HUDClass;
var DVCoreUI_Menu   				HudMovie;

var float							PopupTimer;


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
	
	// Debug
	AddServerInfo(
		"DeepVoid.eu (hardcode)",
		"LEVEL_01.udk",
		"deepvoid.eu",
		"G_TeamDeathmatch",
		12,
		16
	);
}


/*--- Show a command response code ---*/
function DisplayResponse (bool bSuccess, string Msg)
{
	HudMovie.DisplayResponse(bSuccess, Msg);
	SetTimer(PopupTimer, false, 'HidePopup');
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
