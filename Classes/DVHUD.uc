/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVHUD extends UDKHUD;

/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var LinearColor			OrangeColor;
var LinearColor			BlueColor;

var Vector 				MouseHitWorldLocation;
var Vector  			MouseHitWorldNormal;
var Vector  			MousePositionWorldLocation;
var Vector  			MousePositionWorldNormal;

var Vector 				RayDir;
var Vector 				StartTrace;
var Vector				EndTrace;

var DVGFxHUD   			HudMovie;
var class<DVGFxHUD> 	HUDClass;

var bool				bRespawnOpened;
var float				MenuDelay;


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
		HudMovie.UpdateHealth(myOwner.Pawn.Health);
		HudMovie.UpdateAmmo(myOwner.GetAmmoPercentage());
	}
	
	// Score
	TI0 = DVTeamInfo(myOwner.PlayerReplicationInfo.Team);
	TI1 = myOwner.EnemyTeamInfo;
	if (TI0 != None && TI1 != None)
	{
		HudMovie.UpdateScore( TI0.GetScore(), TI1.GetScore());
	}

	
	// End
	ToggleRespawnMenu();
	super.PostRender();
	//PutShadedText("", DVPawn(myOwner.Pawn).DebugField, 20, 30);
	
	// Scores
	if (myOwner.bPrintScores)
		UpdateAllScores();
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
	
	// HUD register
	HudMovie.PC = DVPlayerController(PlayerOwner);
	SetTimer(MenuDelay, false, 'ChooseWeapons');
}


/*--- First screen ---*/
simulated function ChooseWeapons()
{
	HudMovie.OpenRespawnMenu();
	bRespawnOpened = true;
}


/*--- Score management ---*/
simulated function UpdateAllScores()
{
	local DVPlayerRepInfo PRI;
	local int i;
	
	i = 0;
	ForEach AllActors(class'DVPlayerRepInfo', PRI)
	{
		PutShadedText((DVTeamInfo(PRI.Team).TeamIndex == 1) ? BlueColor : OrangeColor,
			PRI.PlayerName $ " " $ PRI.GetPointCount() $ " kills, " $ PRI.GetDeathCount() $ " deaths",
			200, 100 + 30 * i);
		i += 1;
	}
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
	// Init
    local int Idx;
    local string text;
	if (ConsoleMessages.Length < 1 )
		return;
	
	// Text display
    for (Idx = 0; Idx < ConsoleMessages.Length; Idx++)
    {
		if ( ConsoleMessages[Idx].Text == "" || ConsoleMessages[Idx].MessageLife < WorldInfo.TimeSeconds )
		{
			if (Idx > 0)
				ConsoleMessages.Remove(Idx--,1);
			else
				ConsoleMessages.Remove(Idx, 1);
		}
    }
    text = "" $ ConsoleMessages[ConsoleMessages.Length - 1].Text $ "\n" $ ConsoleMessages[ConsoleMessages.Length - 2].Text;
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
	HUDClass=class'DVGFxHUD'
	bRespawnOpened=false
	MenuDelay=0.5
	OrangeColor=(R=255.0,G=50.0,B=20.0,A=0.0)
	BlueColor=(R=20.0,G=50.0,B=255.0,A=0.0)
}
