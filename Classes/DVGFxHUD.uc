/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVGFxHUD extends GFxMoviePlayer;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var GFxClikWidget 	WeaponListMC;
var GFxClikWidget 	RestartButtonMC;
var GFxClikWidget 	ResumeButtonMC;
var GFxClikWidget 	ExitButtonMC;
var GFxClikWidget 	QuitButtonMC;

var GFxClikWidget 	RifleButtonMC;
var GFxClikWidget 	SniperButtonMC;
var GFxClikWidget 	ShotgunButtonMC;

var GFxObject 		AmmoMC;
var GFxObject 		ChatMC;
var GFxObject 		SceneMC;
var GFxObject 		ScoreMC;
var GFxObject 		HealthMC;
var GFxObject 		IndicationMC;

var DVPlayerController PC;
var GFxObject 		ListDataProvider;

var float			LastIndex;


/*----------------------------------------------------------
	UI elements
----------------------------------------------------------*/

/*--- Registering ---*/
function bool Start(optional bool StartPaused = false)
{
	super.Start();
	Advance(0);
	InitParts();
	return true;
}


/*--- Connection of all controllers ---*/
simulated function InitParts()
{
	SceneMC = GetVariableObject("_root");
	AmmoMC = GetVariableObject("_root.Ammo");
	HealthMC = GetVariableObject("_root.Health");
	ChatMC = GetVariableObject("_root.ChatBox");
	ScoreMC = GetVariableObject("_root.Score");
	IndicationMC = GetVariableObject("_root.Indication");
	
	ChatMC.SetText("");
	IndicationMC.SetText("WORK IN PROGRESS - DEVELOPPEMENT EN COURS");
}


/*--- Scrollers ---*/
simulated function UpdateHealth(int amount)
{
	HealthMC.GotoAndStopI(amount);
}
simulated function UpdateAmmo(int amount)
{
	AmmoMC.GotoAndStopI(amount);
}


/*--- Chat ---*/
simulated function UpdateChat(string text)
{
	ChatMC.SetText(text);
}


/*--- Score ---*/
simulated function UpdateScore(int s1, int s2)
{
	ScoreMC.SetText("Votre équipe : "$ s1 $" - Equipe ennemie : "$ s2);
}


/*--- Pause menu ---*/
function TogglePause()
{
	if (PC.Pawn != None)
	{
		DVPawn(PC.Pawn).LockCamera(true);
	}
}

/*--- Respawn menu ---*/
reliable client simulated function OpenRespawnMenu()
{
	if (PC.Pawn != None)
	{
		DVPawn(PC.Pawn).LockCamera(true);
	}
	SceneMC.GotoAndPlayI(3);
}

simulated function CloseRespawnMenu()
{
	// Init
	//local float x;
	//x = WeaponListMC.GetFloat("selectedIndex");
	
	// HUD
	if (PC.Pawn != None)
	{
		DVPawn(PC.Pawn).LockCamera(false);
	}
	SceneMC.GotoAndPlayI(1);
	InitParts();
	
	// Game
	/*PC.HUDRespawn(WeaponList[x]);
	`log("Spawning "$ WeaponList[x]);*/
	PC.HUDRespawn(LastIndex);
}


/*--- Buttons ---*/
event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch(WidgetName)
	{
		/*--- Pause ---*/
		case ('Resume'):
			ResumeButtonMC = GFxClikWidget(Widget);
			ResumeButtonMC.AddEventListener('CLIK_click', OnResume);
			break;
		case ('QuitMenu'):
			ExitButtonMC = GFxClikWidget(Widget);
			ExitButtonMC.AddEventListener('CLIK_click', OnExit);
			break;
		case ('QuitDesktop'):
			QuitButtonMC = GFxClikWidget(Widget);
			QuitButtonMC.AddEventListener('CLIK_click', OnQuit);
			break;
		
		/*--- Weapon buttons ---*/
		case ('Rifle'):
			RifleButtonMC = GFxClikWidget(Widget);
			RifleButtonMC.AddEventListener('CLIK_click', OnSelectRifle);
			break;	
		case ('Sniper'):
			SniperButtonMC = GFxClikWidget(Widget);
			SniperButtonMC.AddEventListener('CLIK_click', OnSelectSniper);
			break;
		case ('Shotgun'):
			ShotgunButtonMC = GFxClikWidget(Widget);
			ShotgunButtonMC.AddEventListener('CLIK_click', OnSelectShotgun);
			break;
		/*
		case ('Restart'):
			RestartButtonMC = GFxClikWidget(Widget);
			RestartButtonMC.AddEventListener('CLIK_click', OnRestart);
			break;
		case ('WeaponList'):
			WeaponListMC = GFxClikWidget(Widget);
			UpdateListDataProvider();
			WeaponListMC.AddEventListener('CLIK_itemClick', OnListItemClick);
			break;*/
			
		default: break;
	}
	return true;
}


/*--- Update the weapon list ---*
reliable client function UpdateListDataProvider()
{
	local byte i;
	local GFxObject TempObj;
	local GFxObject DataProvider;
	`log("UpdateListDataProvider");
	
	// Actual menu setting
	DataProvider = WeaponListMC.GetObject("dataProvider");
	for (i = 0; i < WeaponList.Length; i++)
	{
		TempObj = CreateObject("Object");
		TempObj.SetString("label", string(WeaponList[i]));
		
		DataProvider.SetElementObject(i, TempObj);
		`log("UpdateListDataProvider : e "$ TempObj $ " for " $ DataProvider);
	}
	
	`log("UpdateListDataProvider : saved index "$ LastIndex $" with " $ i $ " elements"); 
	WeaponListMC.SetObject("dataProvider", DataProvider);
	WeaponListMC.SetFloat("rowCount", i);
	WeaponListMC.SetFloat("selectedIndex", LastIndex);
}*/


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/
/*
function OnListItemClick(GFxClikWidget.EventData ev)
{
	WeaponListMC.SetFloat("selectedIndex", ev.index);
	`log("Clicked list");
}

function OnRestart(GFxClikWidget.EventData evtd)
{
	local float x;
	x = WeaponListMC.GetFloat("selectedIndex");
	
	if (x != -1)
	{
		LastIndex = x;
		`log("OnRestart : saving index "$ LastIndex);
	}
	else
		`log("OnRestart : no valid index - Empty menu !");
	CloseRespawnMenu();
}*/

/*--- Button selection ---*/
function OnSelectRifle(GFxClikWidget.EventData evtd)
{
	LastIndex = 0;
	CloseRespawnMenu();
}
function OnSelectSniper(GFxClikWidget.EventData evtd)
{
	LastIndex = 1;
	CloseRespawnMenu();
}
function OnSelectShotgun(GFxClikWidget.EventData evtd)
{
	LastIndex = 2;
	CloseRespawnMenu();
}

function OnResume(GFxClikWidget.EventData evtd)
{
	`log("Resuming...");
	DVPawn(PC.Pawn).LockCamera(false);
	SceneMC.GotoAndPlayI(1);
	InitParts();
}

function OnExit(GFxClikWidget.EventData evtd)
{
	`log("Loading...");
	ConsoleCommand("open UDKFrontEndMap");
}

function OnQuit(GFxClikWidget.EventData evtd)
{
	`log("Exiting");
	ConsoleCommand("quit");
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// HUD Settings
	LastIndex=0.0
	bAllowInput=true
	bAllowFocus=true
	bDisplayWithHudOff=false
	MovieInfo=SwfMovie'zUI.HUD'
	
	// Bindings
	WidgetBindings(0)={(WidgetName="Resume",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(1)={(WidgetName="QuitMenu",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(2)={(WidgetName="QuitDesktop",WidgetClass=class'GFxClikWidget')}
	
	WidgetBindings(3)={(WidgetName="Rifle",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(4)={(WidgetName="Sniper",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(5)={(WidgetName="Shotgun",WidgetClass=class'GFxClikWidget')}
	
	//WidgetBindings(4)={(WidgetName="WeaponList",WidgetClass=class'GFxClikWidget')}
	//WidgetBindings(1)={(WidgetName="Restart",WidgetClass=class'GFxClikWidget')}
	
	
}
