/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVCoreUI_HUD extends DVMovie;

/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (HUD) const int			WarningThreshold;

var (HUD) localized string 	lChooseWeapon;
var (HUD) localized string 	lSwitchTeam;
var (HUD) localized string 	lQuitGame;
var (HUD) localized string 	lPointsOn;
var (HUD) localized string 	lPV;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GFxClikWidget 			ResumeButtonMC;
var GFxClikWidget 			RestartButtonMC;
var GFxClikWidget 			SwitchTeamButtonMC;
var GFxClikWidget 			ExitButtonMC;

var GFxClikWidget 			ScoreListRed;
var GFxClikWidget 			ScoreListBlue;

var GFxObject 				AmmoMC;
var GFxObject 				ChatMC;
var GFxObject 				HealthMC;
var GFxObject 				CounterMC;
var GFxObject 				ChatTextMC;

var GFxObject 				WarningMC;
var GFxObject 				SniperMC;

var GFxObject 				Score1MC;
var GFxObject 				Score2MC;
var GFxObject 				Progress1MC;
var GFxObject 				Progress2MC;

var string 					NewWeaponName;

var bool					bChatting;
var bool 					bFirstFrame;
var bool					bWasKilled;


/*----------------------------------------------------------
	Core methods
----------------------------------------------------------*/

/*--- Connection of all controllers : frame 1 ---*/
simulated function InitParts()
{
	super.InitParts();
	
	// Player info
	Banner = 		GetSymbol("Banner");
	AmmoMC = 		GetSymbol("InfoBox.Ammo");
	HealthMC = 		GetSymbol("InfoBox.Health");
	CounterMC = 	GetSymbol("InfoBox.Counter");
	ChatMC = 		GetSymbol("ChatBox.Text");
	ChatTextMC = 	GetSymbol("ChatBox.Input");
	
	// Overlays
	WarningMC = 	GetSymbol("WarningLight");
	SniperMC = 		GetSymbol("SniperEffect");
	
	// Score
	Score1MC = 		GetSymbol("T0.Score");
	Score2MC = 		GetSymbol("T1.Score");
	Progress1MC = 	GetSymbol("T0.Progress");
	Progress2MC = 	GetSymbol("T1.Progress");
	
	// Various init
	ScoreListBlue.SetVisible(false);
	ScoreListRed.SetVisible(false);
	WarningMC.SetVisible(false);
	SniperMC.SetVisible(false);
	bCaptureInput = false;
	ChatMC.SetText("");
}


/*----------------------------------------------------------
	Game methods
----------------------------------------------------------*/

/*--- Ammo & health bars ---*/
simulated function UpdateInfo(int health, int ammo, int max)
{
	if (max == 0) max = 1;
	
	// Bars
	HealthMC.GotoAndStopI(health);
	AmmoMC.GotoAndStopI(100.0 * (float(ammo) / float(max)));
	
	// Text
	CounterMC.SetText(ammo @"/" @max @"         " @health @ lPV);
	
	// Health warning
	if (health <= WarningThreshold)
		WarningMC.SetVisible(true);
}


/*--- Open chat ---*/
simulated function StartTalking()
{
	if (!bChatting)
	{
		PlayUISound(ClickSound);
		ChatTextMC.SetBool("focused", true);
		ChatTextMC.SetString("text", "");
		bCaptureInput = true;
		bChatting = true;
	}
}


/*--- Score update ---*/
simulated function UpdateScore(int s1, int s2, int max)
{
	Score1MC.SetText("" $ s1 @ lPointsOn @max);
	Score2MC.SetText("" $ s2 @ lPointsOn @max);
	Progress1MC.GotoAndStopI(round(100.0 * (float(s1) / float(max))));
	Progress2MC.GotoAndStopI(round(100.0 * (float(s2) / float(max))));
}


/*--- Open chat ---*/
simulated function SendChatMessage()
{
	local string text;
	
	bCaptureInput = false;
	if (bChatting)
	{
		PlayUISound(ClickSound);
		bChatting = false;
		
		text = ChatTextMC.GetString("text");
		if (text != "")
			ConsoleCommand("Say"@text);
		
		ChatTextMC.SetString("text", "...");
		ChatMC.SetBool("focused", true);
	}
}


/*--- New chat line ---*/
simulated function UpdateChat(string text)
{
	ChatMC.SetText(text);
}


/*--- Should we using the sniper effect ---*/
simulated function SetSniperState(bool bZooming)
{
	SniperMC.SetVisible(bZooming);
}


/*--- Open the player list ---*/
reliable client function OpenPlayerList(array<DVPlayerRepInfo> PRList)
{
	ScoreListRed.SetVisible(true);
	ScoreListBlue.SetVisible(true);
	FillPlayerList(ScoreListRed, PRList, 0);
	FillPlayerList(ScoreListBlue, PRList, 1);
}


/*--- Close the player list ---*/
reliable client function ClosePlayerList()
{
	ScoreListRed.SetVisible(false);
	ScoreListBlue.SetVisible(false);
}


/*----------------------------------------------------------
	Data
----------------------------------------------------------*/

/*--- PLayer list filling ---*/
reliable client function FillPlayerList(GFxObject List, array<DVPlayerRepInfo> PRList, byte TeamIndex)
{
	local byte i, j;
	local GFxObject TempObj;
	local GFxObject DataProvider;
	
	// Player filtering
	j = 0;
	DataProvider = List.GetObject("dataProvider");
	for (i = 0; i < PRList.Length; i++)
	{
		if (PRList[i].Team == None)
			continue;
		else if (PRList[i].Team.TeamIndex == TeamIndex)
		{
			TempObj = CreateObject("Object");
			TempObj.SetString("label", PRList[i].PlayerName $ " : "$ PRList[i].KillCount $ " K, "$ PRList[i].DeathCount $ " D");
			DataProvider.SetElementObject(j, TempObj);
			j++;
		}
	}
	List.SetObject("dataProvider", DataProvider);
	List.SetFloat("rowCount", j);
}


/*--- Update the weapon list ---*/
reliable client function UpdateWeaponList()
{
	local byte i;
	local GFxObject TempObject;
	
	// Title
	SetLabel("WeaponTitle", lChooseWeapon, false);
	
	// Weapon list
	for (i = 0; i < PC.WeaponListLength; i++)
	{
		SetupWeaponWidget("Weapon"$i, string(PC.WeaponList[i]));
	}
	
	// Invisible items
	for (i = PC.WeaponListLength; i < 8; i++)
	{
		TempObject = GetSymbol("Weapon"$i);
		if (TempObject != None)
			TempObject.SetVisible(false);
	}
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- Buttons ---*/
event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	local GFxClikWidget TempObject;
	
	switch(WidgetName)
	{
		// Exit
		case ('ExitMenu'):
			ExitButtonMC = GetLiveWidget(Widget, 'CLIK_click', OnExit);
			SetWidgetLabel("ExitMenu", lQuitGame, false);
			
			// By the way...
			UpdateWeaponList();
			break;
		
		// Team switch
		case ('SwitchTeam'):
			SwitchTeamButtonMC = GetLiveWidget(Widget, 'CLIK_click', OnSwitchTeam);
			SetWidgetLabel("SwitchTeam", lSwitchTeam, false);
			SwitchTeamButtonMC.SetVisible(!bFirstFrame && PC.Pawn.Health <= 0);
			break;
		
		/// Lists
		case ('ScoreListRed'):
			ScoreListRed = GFxClikWidget(Widget);
			break;
		case ('ScoreListBlue'):
			ScoreListBlue = GFxClikWidget(Widget);
			break;
		
		// Weapon widgets
		case ('Weapon0'):
		case ('Weapon1'):
		case ('Weapon2'):/*
		case ('Weapon3'):
		case ('Weapon4'):
		case ('Weapon5'):
		case ('Weapon6'):
		case ('Weapon7'):*/
			TempObject = GFxClikWidget(Widget);
			TempObject.AddEventListener('CLIK_click', OnWeaponWidgetClick);
			break;
		
		default: return super.WidgetInitialized(Widgetname, WidgetPath, Widget);
	}
	return true;
}


/*--- Weapon selection ---*/
function OnWeaponWidgetClick(GFxClikWidget.EventData ev)
{
	// Vars
	local int i;
	local GFxObject button;
	local class<DVWeapon> NewWeapon;
	
	// Weapon ID
	button = ev._this.GetObject("target");
	i = int(Right(button.GetString("name"), 1));
	NewWeapon = PC.WeaponList[i];
	
	// Restart
	SetGameUnPaused();
	PC.HUDRespawn(!bFirstFrame, NewWeapon);
	bCaptureInput = false;
	bFirstFrame = false;
}


/*--- Respawn menu ---*/
reliable client simulated function OpenRespawnMenu(optional bool bKilledMenu)
{
	// Settings
	bChatting = false;
	bCaptureInput = false;
	bWasKilled = bKilledMenu;
	
	// Pawn
	if (bFirstFrame)
	{
		DVPawn(PC.Pawn).HideMesh(true);
	}
	
	// Actions
	SetGamePaused();
	Scene.GotoAndPlayI(2);
	Banner = GetSymbol("Banner");
	OpenPlayerList(PC.GetPlayerList());
}


/*--- Pause start ---*/
function TogglePause()
{
	SetGamePaused();
	bCaptureInput = false;
}


/*--- Pause end ---*/
function OnResume(GFxClikWidget.EventData evtd)
{
	// Whoah, take something man.
	if (bFirstFrame)
		return;
	
	// Respawn or just resume
	if (bWasKilled)
	{
		PC.HUDRespawn(true);
	}
	SetGameUnPaused();
	bCaptureInput = false;
}


/*--- Change team ---*/
function OnSwitchTeam(GFxClikWidget.EventData evtd)
{
	PC.SwitchTeam();
}


/*--- Quit to menu ---*/
function OnExit(GFxClikWidget.EventData evtd)
{
	PC.SaveGameStatistics(false, true);
	ConsoleCommand("open UDKFrontEndMap?game=DVCore.DVGame_Menu");
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	bFirstFrame=true
	WarningThreshold=20
	MovieInfo=SwfMovie'DV_CoreUI.HUD'
	
	WidgetBindings(3)={(WidgetName="SwitchTeam",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(4)={(WidgetName="ExitMenu",	WidgetClass=class'GFxClikWidget')}
	
	WidgetBindings(6)={(WidgetName="ScoreListRed",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(7)={(WidgetName="ScoreListBlue",WidgetClass=class'GFxClikWidget')}
	
	WidgetBindings(8)={(WidgetName="Weapon0",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(9)={(WidgetName="Weapon1",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(10)={(WidgetName="Weapon2",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(11)={(WidgetName="Weapon3",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(12)={(WidgetName="Weapon4",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(13)={(WidgetName="Weapon5",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(14)={(WidgetName="Weapon6",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(15)={(WidgetName="Weapon7",WidgetClass=class'GFxClikWidget')}
}
