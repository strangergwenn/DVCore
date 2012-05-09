/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVCoreUI_HUD extends DVMovie;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GFxClikWidget 	ResumeButtonMC;
var GFxClikWidget 	ExitButtonMC;
var GFxClikWidget 	WeaponListMC;

var GFxObject 		AmmoMC;
var GFxObject 		ChatMC;
var GFxObject 		ScoreMC;
var GFxObject 		HealthMC;
var GFxObject 		IndicationMC;

var GFxObject 		ListDataProvider;

var int				LastIndex;


/*----------------------------------------------------------
	Core methods
----------------------------------------------------------*/

/*--- Connection of all controllers ---*/
simulated function InitParts()
{
	super.InitParts();
	AmmoMC = GetSymbol("Ammo");
	HealthMC = GetSymbol("Health");
	ChatMC = GetSymbol("ChatBox");
	ScoreMC = GetSymbol("Score");
	IndicationMC = GetSymbol("Indication");
	
	ChatMC.SetText("");
	IndicationMC.SetText("WORK IN PROGRESS - DEVELOPPEMENT EN COURS");
	Banner = GetSymbol("Banner");
}


/*----------------------------------------------------------
	Game methods
----------------------------------------------------------*/

reliable client simulated function OpenRespawnMenu()
{
	SetGamePaused();
	Scene.GotoAndPlayI(3);
	Banner = GetSymbol("Banner");
}


simulated function UpdateHealth(int amount)
{
	HealthMC.GotoAndStopI(amount);
}


simulated function UpdateAmmo(int amount)
{
	AmmoMC.GotoAndStopI(amount);
}


simulated function UpdateChat(string text)
{
	ChatMC.SetText(text);
}


simulated function UpdateScore(int s1, int s2)
{
	ScoreMC.SetText("Votre équipe : "$ s1 $" - Equipe ennemie : "$ s2);
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- Buttons ---*/
event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch(WidgetName)
	{
		/*--- Pause ---*/
		case ('Resume'):
			ResumeButtonMC = GetLiveWidget(Widget, 'CLIK_click', OnResume);
			break;
		
		case ('QuitMenu'):
			ExitButtonMC = GetLiveWidget(Widget, 'CLIK_click', OnExit);
			break;
		
		case ('WeaponList'):
			WeaponListMC = GetLiveWidget(Widget, 'CLIK_itemClick', OnListItemClick);
			UpdateListDataProvider();
			break;
			
		default:
			return super.WidgetInitialized(Widgetname, WidgetPath, Widget);
	}
	return true;
}


/*--- Update the weapon list ---*/
reliable client function UpdateListDataProvider()
{
	local byte i;
	local GFxObject TempObj;
	local GFxObject DataProvider;
	`log("UpdateListDataProvider");
	
	// Actual menu setting
	DataProvider = WeaponListMC.GetObject("dataProvider");
	for (i = 0; i < PC.WeaponListLength; i++)
	{
		TempObj = CreateObject("Object");
		TempObj.SetString("label", string(PC.WeaponList[i]));
		TempObj.SetString("testdata", ""$i);
		
		DataProvider.SetElementObject(i, TempObj);
		`log("UpdateListDataProvider : e "$ TempObj $ " for " $ DataProvider);
	}
	
	`log("UpdateListDataProvider : saved index "$ LastIndex $" with " $ i $ " elements"); 
	WeaponListMC.SetObject("dataProvider", DataProvider);
	WeaponListMC.SetFloat("rowCount", i);
	WeaponListMC.SetFloat("selectedIndex", LastIndex);
}


/*----------------------------------------------------------
	Click events
----------------------------------------------------------*/

function OnListItemClick(GFxClikWidget.EventData ev)
{
    local int i;
    local GFxObject button;
    local string NewWeaponName;
    local class<DVWeapon> NewWeapon;
    
    button = ev._this.GetObject("itemRenderer");
	NewWeaponName = button.GetString("label");
	
	for (i = 0; i < PC.WeaponListLength; i++)
	{
		if (InStr(NewWeaponName, PC.WeaponList[i].name) != -1)
		{
			LastIndex = i;
			NewWeapon = PC.WeaponList[i];
		}
	}
	
	SetGameUnPaused();
	PC.HUDRespawn(NewWeapon);
}

function TogglePause()
{
	SetGamePaused();
}

function OnResume(GFxClikWidget.EventData evtd)
{
	SetGameUnPaused();
}

function OnExit(GFxClikWidget.EventData evtd)
{
	`log("Loading...");
	ConsoleCommand("open UDKFrontEndMap?game=DVCore.DVGame_Menu");
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// HUD Settings
	LastIndex=0
	MovieInfo=SwfMovie'zUI.HUD'
	
	// Bindings
	WidgetBindings(1)={(WidgetName="Resume",	WidgetClass=class'GFxClikWidget')}
	WidgetBindings(2)={(WidgetName="QuitMenu",	WidgetClass=class'GFxClikWidget')}
	WidgetBindings(3)={(WidgetName="WeaponList",WidgetClass=class'GFxClikWidget')}
}
