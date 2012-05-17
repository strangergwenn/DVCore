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


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GFxClikWidget 			ResumeButtonMC;
var GFxClikWidget 			RestartButtonMC;
var GFxClikWidget 			SwitchTeamButtonMC;
var GFxClikWidget 			ExitButtonMC;

var GFxClikWidget 			WeaponListMC;
var GFxClikWidget 			ScoreListRed;
var GFxClikWidget 			ScoreListBlue;

var GFxObject 				AmmoMC;
var GFxObject 				ChatMC;
var GFxObject 				HealthMC;
var GFxObject 				WarningMC;
var GFxObject 				CounterMC;
var GFxObject 				ChatTextMC;

var GFxObject 				Score1MC;
var GFxObject 				Score2MC;
var GFxObject 				Progress1MC;
var GFxObject 				Progress2MC;

var string 					NewWeaponName;

var bool					bChatting;
var bool 					bFirstFrame;


/*----------------------------------------------------------
	Core methods
----------------------------------------------------------*/

/*--- Connection of all controllers : frame 1 ---*/
simulated function InitParts()
{
	super.InitParts();
	
	// Player info
	Banner = 		GetSymbol("Banner");
	WarningMC = 	GetSymbol("WarningLight");
	AmmoMC = 		GetSymbol("InfoBox.Ammo");
	HealthMC = 		GetSymbol("InfoBox.Health");
	CounterMC = 	GetSymbol("InfoBox.Counter");
	ChatMC = 		GetSymbol("ChatBox.Text");
	ChatTextMC = 	GetSymbol("ChatBox.Input");
	
	// Score
	Score1MC = 		GetSymbol("T0.Score");
	Score2MC = 		GetSymbol("T1.Score");
	Progress1MC = 	GetSymbol("T0.Progress");
	Progress2MC = 	GetSymbol("T1.Progress");
	
	// Various init
	ScoreListBlue.SetVisible(false);
	ScoreListRed.SetVisible(false);
	WarningMC.SetVisible(false);
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
	CounterMC.SetText(ammo @"/" @max @"           " @health $"pv");
	
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


/*--- Score update ---*/
simulated function UpdateScore(int s1, int s2, int max)
{
	Score1MC.SetText("" $ s1 @ "points sur "@max);
	Score2MC.SetText("" $ s1 @ "points sur "@max);
	Progress1MC.GotoAndStopI(100.0 * float(s1 / max));
	Progress2MC.GotoAndStopI(100.0 * float(s2 / max));
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
		if (PRList[i].Team.TeamIndex == TeamIndex)
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
	// Vars
	local byte i;
	local GFxObject TempObj;
	local GFxObject DataProvider;
	local class<DVWeapon> wpClass;
	local string WeaponClassToLoad;
	
	`log("UpdateWeaponList");
	
	// Actual menu setting
	DataProvider = WeaponListMC.GetObject("dataProvider");
	`log(""$DataProvider @WeaponListMC.GetFloat("rowCount"));
	for (i = 0; i < PC.WeaponListLength; i++)
	{
		// Load a weapon class
		WeaponClassToLoad = PC.GameModuleName() $"." $ PC.WeaponList[i];
		wpClass = class<DVWeapon>(DynamicLoadObject(WeaponClassToLoad, class'Class', false));
		`log(""$wpClass.default.WeaponName);
		
		// List item	
		TempObj = CreateObject("Object");
		TempObj.SetString("label", wpClass.default.WeaponName);
		DataProvider.SetElementObject(i, TempObj);
	}
	
	// List update
	`log("WeaponListMC = "@WeaponListMC);
	WeaponListMC.SetObject("dataProvider", DataProvider);
	WeaponListMC.SetInt("rowCount", i);
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- Buttons ---*/
event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch(WidgetName)
	{
		// Buttons
		case ('ExitMenu'):
			ExitButtonMC = GetLiveWidget(Widget, 'CLIK_click', OnExit);
			SetWidgetLabel("ExitMenu", "Quitter la partie", false);
			break;
		case ('SwitchTeam'):
			SwitchTeamButtonMC = GetLiveWidget(Widget, 'CLIK_click', OnSwitchTeam);
			SetWidgetLabel("SwitchTeam", "Changer d'équipe", false);
			SwitchTeamButtonMC.SetVisible(!bFirstFrame && PC.Pawn.Health <= 0);
			bFirstFrame=false;
			break;
		
		/// Lists
		case ('WeaponList'):
			WeaponListMC = GetLiveWidget(Widget, 'CLIK_itemClick', OnWeaponClick);
			UpdateWeaponList();
			break;
		case ('ScoreListRed'):
			ScoreListRed = GFxClikWidget(Widget);
			break;
		case ('ScoreListBlue'):
			ScoreListBlue = GFxClikWidget(Widget);
			break;
			
		default: return super.WidgetInitialized(Widgetname, WidgetPath, Widget);
	}
	return true;
}


/*--- Weapon selection ---*/
function OnWeaponClick(GFxClikWidget.EventData ev)
{
	local int i;
	local class<DVWeapon> NewWeapon;
	
	// List data usage
	NewWeaponName = GetListItemClicked(ev);
	for (i = 0; i < PC.WeaponListLength; i++)
	{
		if (InStr(NewWeaponName, PC.WeaponList[i].name) != -1)
		{
			NewWeapon = PC.WeaponList[i];
		}
	}
	
	// Restart
	SetGameUnPaused();
	PC.HUDRespawn(NewWeapon);
	bCaptureInput = false;
}


/*--- Respawn menu ---*/
reliable client simulated function OpenRespawnMenu()
{
	bChatting = false;
	bCaptureInput = false;
	
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
	
	WidgetBindings(5)={(WidgetName="WeaponList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(6)={(WidgetName="ScoreListRed",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(7)={(WidgetName="ScoreListBlue",WidgetClass=class'GFxClikWidget')}
}
