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

var (HUD) localized string 	lAmmo;
var (HUD) localized string 	lCannon;
var (HUD) localized string 	lRail;

var (HUD) localized string 	lChangeWeapon;
var (HUD) localized string 	lValidateConfig;
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

var bool					bInMenu;
var bool					bChatting;
var bool 					bFirstFrame;
var bool					bWasKilled;
var bool					bListOpened;


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
	
	// Bugfix
	if (!bListOpened)
		ClosePlayerList();
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
simulated function StartTalking()
{
	if (!bChatting)
	{
		PlayUISound(ClickSound);
		ChatTextMC.SetBool("focused", true);
		ChatTextMC.SetString("text", "");
		bChatting = true;
		PC.IgnoreMoveInput(true);
	}
}


/*--- Open chat ---*/
simulated function SendChatMessage()
{
	local string text;
	
	if (bChatting)
	{
		PlayUISound(ClickSound);
		
		text = ChatTextMC.GetString("text");
		if (text != "")
			ConsoleCommand("Say"@text);
		
		ChatTextMC.SetString("text", "...");
	}
	bChatting = false;
	PC.IgnoreMoveInput(false);
	ChatMC.SetBool("focused", true);
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
	bListOpened = true;
}


/*--- Close the player list ---*/
reliable client function ClosePlayerList()
{
	ScoreListRed.SetVisible(false);
	ScoreListBlue.SetVisible(false);
	bListOpened = false;
}


/*----------------------------------------------------------
	Data
----------------------------------------------------------*/

/*--- Set up an add-on widget ---*/
function SetupAddonWidget(string WidgetName, string LoadClass)
{
	// Vars
	local string ClassToLoad;
	local class<DVWeaponAddon> wpClass;
	if (PC.Pawn != None)
	{
		ModuleName = DVPawn(PC.Pawn).ModuleName;
	}
	ClassToLoad = ModuleName $ "." $ LoadClass;
	wpClass = class<DVWeaponAddon>(DynamicLoadObject(ClassToLoad, class'Class', false));
	
	// Data
	SetLabel(WidgetName $".WName", 	wpClass.default.lAddonName, true);
	SetLabel(WidgetName $".WDesc", 	wpClass.default.lAddonL1, false);
	SetLabel(WidgetName $".WStats", GetSlotName(wpClass.default.SocketID), false);
	SetupIcon(WidgetName$".WIcon",	wpClass.static.GetIcon());
}


/*--- Get an add-on slot name ---*/
function string GetSlotName(byte Index)
{
	switch (Index)
	{
		case 1:
			return lCannon;
		case 2:
			return lRail;
		case 3:
			return lAmmo;
	}
}


/*--- Player list filling ---*/
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
			TempObj.SetString("label",
				  PRList[i].PlayerName $ " : "
				$ PRList[i].KillCount $ " K, "
				$ PRList[i].DeathCount $ " D");
			DataProvider.SetElementObject(j, TempObj);
			j++;
		}
	}
	List.SetObject("dataProvider", DataProvider);
	List.SetFloat("rowCount", j);
	
	// Current player is selected
	if (PC == None)
	{
		return;
	}
	else if (TeamIndex == PC.GetTeamIndex())
	{
		List.SetInt("selectedIndex", PC.GetLocalRank() - 1);
		`log("CoreUI > Highlighting index" @PC.GetLocalRank() - 1);
	}
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


/*--- Update the addons list ---*/
reliable client function UpdateAddonList()
{
	// Vars
	local byte i;
	local DVWeapon wp;
	local GFxObject TempObject;
	
	// Init
	wp = DVWeapon(PC.Pawn.Weapon);
	SetLabel("CannonTitle", lCannon, true);
	SetLabel("AmmoTitle", lAmmo, true);
	SetLabel("SightTitle", lRail, true);
	
	// Weapon list
	for (i = 0; i < wp.AddonList.Length; i++)
	{
		if (wp.AddonList[i] != None)
		{
			SetupAddonWidget("Config"$i, string(wp.AddonList[i]));
		}
		else
		{
			TempObject = GetSymbol("Config"$i);
			if (TempObject != None)
				TempObject.SetVisible(false);
		}
	}
	
	// Invisible items
	for (i = wp.AddonList.Length; i < 16; i++)
	{
		TempObject = GetSymbol("Config"$i);
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
			GetLiveWidget(Widget, 'CLIK_click', OnExit);
			SetWidgetLabel("ExitMenu", lQuitGame, false);
			UpdateWeaponList();
			break;
		
		// Weapon change in config
		case ('ChangeWeapon'):
			GetLiveWidget(Widget, 'CLIK_click', OnSwitchWeapon);
			SetWidgetLabel("ChangeWeapon", lChangeWeapon, false);
			break;
		
		// Validate the addon config
		case ('ValidateConfig'):
			GetLiveWidget(Widget, 'CLIK_click', OnValidateConfig);
			SetWidgetLabel("ValidateConfig", lValidateConfig, false);
			UpdateAddonList();
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
		case ('Weapon2'):
		case ('Weapon3'):
		case ('Weapon4'):
			TempObject = GFxClikWidget(Widget);
			TempObject.AddEventListener('CLIK_click', OnWeaponWidgetClick);
			break;
		
		// Addon widgets
		case ('Config0'):
		case ('Config1'):
		case ('Config2'):
		case ('Config3'):
		case ('Config4'):
		case ('Config5'):
		case ('Config6'):
		case ('Config7'):
		case ('Config8'):
		case ('Config9'):
		case ('Config10'):
		case ('Config11'):
			TempObject = GFxClikWidget(Widget);
			TempObject.AddEventListener('CLIK_click', OnAddonWidgetClick);
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
	`log("CoreUI > Weapon selected");
	SetGameUnPaused();
	PC.HUDRespawn(!bFirstFrame, NewWeapon);
	bFirstFrame = false;
	bInMenu = false;
}


/*--- Addon selection ---*/
function OnAddonWidgetClick(GFxClikWidget.EventData ev)
{
	// Vars
	local DVWeapon wp;
	local GFxObject button;
	
	// Addon ID
	wp = PC.Bench.Weapon;
	button = ev._this.GetObject("target");
	wp.RequestAddon(int(Right(button.GetString("name"), 1)));
}


/*--- Save weapon configuration and respawn ---*/
function OnValidateConfig(GFxClikWidget.EventData ev)
{
	`log("CoreUI > Respawning with weapon configured");
	PC.Bench.Weapon.SaveConfig();
	PC.LockCamera(false);
	PC.HUDRespawn(true);
	SetGameUnPaused();
}


/*--- Weapon selection ---*/
function OnSwitchWeapon(GFxClikWidget.EventData ev)
{
	`log("CoreUI > Respawning for weapon selection");
	SetGameUnPaused();
	OpenRespawnMenu(true);
}


/*--- Respawn menu ---*/
reliable client simulated function OpenRespawnMenu(optional bool bKilledMenu)
{
	// Settings
	`log("CoreUI > Opening respawn menu, kill=" $bKilledMenu);
	bChatting = false;
	bWasKilled = bKilledMenu;
	bInMenu = true;
	
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


/*--- Weapon data ---*/
reliable client simulated function OpenWeaponConfig()
{
	bChatting = false;
	SetGamePaused();
	Scene.GotoAndPlayI(3);
}


/*--- Pause start ---*/
function TogglePause()
{
	SetGamePaused();
}


/*--- Pause end ---*/
function OnResume(GFxClikWidget.EventData evtd)
{
	// No.
	`log("CoreUI > Resuming, kill=" $bWasKilled $",inMenu=" $bInMenu);
	if (bFirstFrame || PC.bConfiguring || !bInMenu)
		return;
	
	// Respawn or just resume
	if (bWasKilled)
	{
		PC.HUDRespawn(true);
		bWasKilled = false;
	}
	SetGameUnPaused();
	PC.LockCamera(false);
	bInMenu = false;
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
	
	WidgetBindings(16)={(WidgetName="Config0",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(17)={(WidgetName="Config1",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(18)={(WidgetName="Config2",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(19)={(WidgetName="Config3",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(20)={(WidgetName="Config4",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(21)={(WidgetName="Config5",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(22)={(WidgetName="Config6",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(23)={(WidgetName="Config7",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(24)={(WidgetName="Config8",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(25)={(WidgetName="Config9",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(26)={(WidgetName="Config10",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(27)={(WidgetName="Config11",WidgetClass=class'GFxClikWidget')}
	
	WidgetBindings(28)={(WidgetName="ValidateConfig",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(29)={(WidgetName="ChangeWeapon",	WidgetClass=class'GFxClikWidget')}
}
