/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVHUD extends UDKHUD;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVHUD) const LinearColor			OrangeColor;
var (DVHUD) const LinearColor			BlueColor;
var (DVHUD) const class<DVCoreUI_HUD>	HUDClass;

var (DVHUD) const float					GameplayMessageTime;
var (DVHUD) const float					HitWarningLength;
var (DVHUD) const float					MenuDelay;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var DVCoreUI_HUD   						HudMovie;
var bool								bRespawnOpened;


/*----------------------------------------------------------
	Main thread
----------------------------------------------------------*/

event PostRender()
{
	local DVPlayerController myOwner;
	local DVTeamInfo TI0;
	local DVTeamInfo TI1;
	
	// PC
	myOwner = DVPlayerController(PlayerOwner);
	if (myOwner.Pawn != None)
	{
		HudMovie.UpdateInfo(myOwner.Pawn.Health, myOwner.GetAmmoCount(), myOwner.GetAmmoMax());
	}
	
	// Score display using team replication data
	if (myOwner.PlayerReplicationInfo.Team != None)
	{
		TI0 = DVTeamInfo(myOwner.PlayerReplicationInfo.Team);
		TI1 = myOwner.EnemyTeamInfo;
		if (TI0 != None && TI1 != None)
		{
			if (TI0.TeamIndex == 0)
				HudMovie.UpdateScore(TI0.GetScore(), TI1.GetScore(), myOwner.GetTargetScore());
			else
				HudMovie.UpdateScore(TI1.GetScore(), TI0.GetScore(), myOwner.GetTargetScore());
		}
	}
	
	// End
	ToggleRespawnMenu();
	super.PostRender();
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Spawn ---*/ 
simulated function PostBeginPlay()
{	
	// HUD spawn
	local DVPlayerController PC;
	super.PostBeginPlay();
	PC = DVPlayerController(PlayerOwner);
	
	// Movie
	HudMovie = new HUDClass;
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);
	HudMovie.Start();
	HudMovie.Advance(0);
	
	// HUD register
	PC.SetName(PC.LocalStats.UserName);
	PC.LocalStats.EmptyStats();
	HudMovie.PC = PC;
	HudMovie.OpenRespawnMenu(false);
}


/*--- Shot effect ---*/
simulated function ShowHit()
{
	HudMovie.WarningMC.SetVisible(true);
	SetTimer(HitWarningLength, false, 'HideHit');
}
simulated function HideHit()
{
	HudMovie.WarningMC.SetVisible(false);
}


/*--- Should we using the sniper effect ---*/
simulated function SetSniperState(bool bZooming)
{
	HudMovie.SetSniperState(bZooming);
}


/*--- Put an on-screen message for some time ---*/
simulated function GameplayMessage(string text)
{
	HudMovie.ShowBannerInfo(true, text);
	PlaySound(HudMovie.BipSound);
	SetTimer(GameplayMessageTime, false, 'ShutdownMessage');
	AddConsoleMessage(text, class'LocalMessage', PlayerOwner.PlayerReplicationInfo); 
}


/*--- Hide on-screen message ---*/
simulated function ShutdownMessage()
{
	HudMovie.ShowBannerInfo(false);
}


/*--- Weapon data ---*/
reliable client simulated function OpenWeaponConfig()
{
	HudMovie.OpenWeaponConfig();
}


/*--- Score management ---*/
reliable client simulated function ShowPlayerList()
{
	local array<DVPlayerRepInfo> PRList;
	PRList = DVPlayerController(PlayerOwner).GetPlayerList();
	HudMovie.OpenPlayerList(PRList);
}


/*--- Score management ---*/
reliable client simulated function HidePlayerList()
{
	HudMovie.ClosePlayerList();
}


/*--- Open weapon choice menu ---*/
function ToggleRespawnMenu()
{
	local DVPawn P;
	P = DVPawn(PlayerOwner.Pawn);
	
	if (P == None && !bRespawnOpened)
	{
		HudMovie.OpenRespawnMenu(true);
		bRespawnOpened = true;
	}
	if (P != None && bRespawnOpened)
		bRespawnOpened = false;
}


/*--- Console message between players ---*/
function DisplayConsoleMessages()
{
	local string text;
	local byte i;
	text = "";
	
	for (i = 0; i < ConsoleMessages.length; i++)
	{
		text $= ConsoleMessages[i].Text;
		text $= "\n";
	}
	HUDMovie.UpdateChat(text);
}


/*--- Text box for objectives ---*/
function DrawMessageText(HudLocalizedMessage LocalMessage, float ScreenX, float ScreenY)
{}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	bRespawnOpened=true
	HUDClass=class'DVCoreUI_HUD'
	
	MenuDelay=0.5
	HitWarningLength=0.2
	GameplayMessageTime=3.0
	
	OrangeColor=(R=255.0,G=50.0,B=20.0,A=0.0)
	BlueColor=(R=20.0,G=100.0,B=255.0,A=0.0)
}
