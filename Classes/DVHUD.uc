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
var (DVHUD) const float					MenuDelay;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var DVUserStats							LocalStats;
var DVUserStats							GlobalStats;

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
	
	// Score
	if (myOwner.PlayerReplicationInfo.Team != None)
	{
		TI0 = DVTeamInfo(myOwner.PlayerReplicationInfo.Team);
		TI1 = myOwner.EnemyTeamInfo;
		if (TI0 != None && TI1 != None)
		{
			HudMovie.UpdateScore( TI0.GetScore(), TI1.GetScore(), myOwner.GetTargetScore());
		}
	}
	
	// End
	ToggleRespawnMenu();
	super.PostRender();
	
	//PutShadedText(BlueColor, DVPawn(myOwner.Pawn).DebugField, 20, 100);
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Spawn ---*/ 
simulated function PostBeginPlay()
{	
	// HUD spawn
	super.PostBeginPlay();
	HudMovie = new HUDClass;
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);
	HudMovie.Start();
	HudMovie.Advance(0);
	
	// Stats
	LocalStats = new class'DVUserStats';
	GlobalStats = new class'DVUserStats';
	LocalStats.EmptyStats();
	GlobalStats.EmptyStats();
	
	// HUD register
	HudMovie.PC = DVPlayerController(PlayerOwner);
	SetTimer(MenuDelay, false, 'ChooseWeapons');
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


/*--- First screen ---*/
simulated function ChooseWeapons()
{
	HudMovie.OpenRespawnMenu();
	bRespawnOpened = true;
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
		HudMovie.OpenRespawnMenu();
		bRespawnOpened = true;
	}
	if (P != None && bRespawnOpened)
		bRespawnOpened = false;
}


/*--- Text box for objectives ---*/
function DrawMessageText(HudLocalizedMessage LocalMessage, float ScreenX, float ScreenY)
{}


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



/*--- TEMPORARY ---*/
function PutShadedText(LinearColor col, string StringMessage2, float ScreenX, float ScreenY)
{
	PutText(col ,StringMessage2, ScreenX, ScreenY, true);
	PutText(col ,StringMessage2, ScreenX, ScreenY, false);
}
function PutText(LinearColor col, string StringMessage2, float ScreenX, float ScreenY, bool bIsShade)
{
	Canvas.Font = GetFontSizeIndex(2);
	
	if (bIsShade)
	{
		Canvas.SetPos(ScreenX + 1.5, ScreenY);
		Canvas.SetDrawColor(0,0,0,255);
		Canvas.DrawText(StringMessage2, false, 1.00, 1.15, TextRenderInfo );
	}
	else
	{
		Canvas.SetPos(ScreenX, ScreenY);
		Canvas.SetDrawColor(col.R, col.G, col.B, 255);
		Canvas.DrawText(StringMessage2, false, , , TextRenderInfo );
	}
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	bRespawnOpened=false
	HUDClass=class'DVCoreUI_HUD'
	
	MenuDelay=0.5
	GameplayMessageTime=3.0
	
	OrangeColor=(R=255.0,G=50.0,B=20.0,A=0.0)
	BlueColor=(R=20.0,G=100.0,B=255.0,A=0.0)
}
