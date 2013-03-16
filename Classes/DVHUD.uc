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

var (DVHUD) const class<DVCoreUI_HUD>	HUDClass;

var (DVHUD) const color					OrangeColor;
var (DVHUD) const color					BlueColor;

var (DVHUD) const float					GameplayMessageTime;
var (DVHUD) const float					HitWarningLength;
var (DVHUD) const float					MenuDelay;

var (DVHUD) const float					MaxNameDistance;
var (DVHUD) const float					MinNameAngle;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var vector2D 							ViewportSize;
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
	
	// Debug
	PutShadedText(WhiteColor, "WIP - NOTHING IS FINAL - CLOSED DEVELOPPER VERSION - CODE CL 1164", 400, 10);

	// End
	LabelAllIfViewed(class'DVPawn', MinNameAngle, MaxNameDistance * (myOwner.Zoomed() ? 2.0:1.0));
	ToggleRespawnMenu();
	super.PostRender();
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Target painting ---*/
simulated function LabelAllIfViewed(class<Actor> TargetClass, float MinAngle, float MaxDistance)
{
	local Actor Temp;
	local float Distance;
	local float DotResult;
	local DVPlayerController myOwner;
	local vector ScreenPos, Unused1, Unused2;

	myOwner = DVPlayerController(PlayerOwner);
	foreach AllActors(TargetClass, Temp)
	{
		ScreenPos = Canvas.Project(Temp.Location);
		Distance = VSize(Temp.Location - myOwner.Pawn.Location);
		if (Trace(Unused1, Unused2, Temp.Location, myOwner.Pawn.Location) == None && Distance != 0)
		{
			DotResult = (Temp.Location - myOwner.Pawn.Location) dot vector(myOwner.Rotation);
			if (DotResult / Distance > MinAngle && Distance < MaxDistance)
			{
				PaintActor(Temp, ScreenPos.X, ScreenPos.Y);
			}
		}
	}
}


/*--- Target painting method ---*/
simulated function PaintActor(Actor Target, float X, float Y)
{
	local DVPawn Trg;
	local color TrgColor;
	Trg = DVPawn(Target);

	if (Trg != None)
	{
		TrgColor = (Trg.GetTeamIndex() == 1) ? BlueColor:OrangeColor;
		PutShadedText(TrgColor, Trg.UserName, X - 10, Y - 50);
	}
}


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
	LocalPlayer(PC.Player).ViewportClient.GetViewportSize(ViewportSize);

	OpenWeaponMenu();
	if (!PC.PlayerReplicationInfo.bOnlySpectator)
	{
		SetTimer(2.0, true, 'OpenWeaponMenu');
	}
	else
	{
		HideWeaponMenu();
		SetTimer(1.0, true, 'HideWeaponMenu');
	}
}


/*-- Open the weapon choice menu --*/
simulated function OpenWeaponMenu()
{
	local DVPlayerController PC;
	PC = DVPlayerController(PlayerOwner);
	HudMovie.PC = PC;
	HudMovie.InitParts();
	HudMovie.Scene.GotoAndPlayI(0);
	HudMovie.Scene.GotoAndPlayI(2);
}

/*-- Open the weapon choice menu --*/
simulated function HideWeaponMenu()
{
	HudMovie.HideWeaponList();
}


/*-- Open the weapon choice menu --*/
simulated function DisarmWeaponMenu()
{
	ClearTimer('OpenWeaponMenu');
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
		//if (!P.Controller.PlayerReplicationInfo.bOnlySpectator)
		//{
			HudMovie.OpenRespawnMenu(true);
			SetTimer(1.0, true, 'OpenWeaponMenu');
			bRespawnOpened = true;
		//}
	}
	else if (P != None && bRespawnOpened)
		bRespawnOpened = false;
}

/*--- Unpause game ---*/
function Close()
{
	HudMovie.SetGameUnPaused();
	DisarmWeaponMenu();
	HudMovie.Close();
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
	if (HUDMovie != None)
		HUDMovie.UpdateChat(text);
}


/*--- Text box for objectives ---*/
function DrawMessageText(HudLocalizedMessage LocalMessage, float ScreenX, float ScreenY)
{}


/*--- TEMPORARY ---*/
function PutShadedText(color col, string StringMessage2, float ScreenX, float ScreenY)
{
	PutText(col, StringMessage2, ScreenX, ScreenY, true);
	PutText(col, StringMessage2, ScreenX, ScreenY, false);
}
function PutText(color col, string StringMessage2, float ScreenX, float ScreenY, bool bIsShade)
{
	Canvas.Font = GetFontSizeIndex(0);
	
	if (bIsShade)
	{
		Canvas.SetPos(ScreenX + 1.5, ScreenY);
		Canvas.SetDrawColor(0,0,0,255);
		Canvas.DrawText(StringMessage2, false, 1.00, 1.2, TextRenderInfo );
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
	bRespawnOpened=true
	HUDClass=class'DVCoreUI_HUD'
	
	MenuDelay=0.5
	HitWarningLength=0.2
	GameplayMessageTime=3.0
	MaxNameDistance=5000
	MinNameAngle=0.95
	
	OrangeColor=(R=255,G=50,B=20,A=0)
	BlueColor=(R=20,G=100,B=255,A=0)
}
