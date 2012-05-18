/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVMovie extends GFxMoviePlayer;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVMovie) const int					LSize;
var (DVMovie) const int 				SpaceSizeFactor;
var (DVMovie) const int 				PopupFieldCount;

var (DVMovie) const SoundCue 			BipSound;
var (DVMovie) const SoundCue 			ClickSound;

var (DVMovie) const string				PopupName;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var DVPlayerController					PC;

var GFxObject 							Scene;
var GFxObject 							Banner;

var GFxClikWidget 						QuitButton;
var GFxClikWidget 						PopupButton1;
var GFxClikWidget 						PopupButton2;

var GFxObject							PopupWindow;


/*----------------------------------------------------------
	Core methods
----------------------------------------------------------*/

/*--- Registering widgets ---*/
function bool Start(optional bool StartPaused = false)
{
	super.Start();
	
	`log("Gfx start");
	Advance(0);
	InitParts();
	
	return true;
}


/*--- Do this on start & restart --*/
function InitParts()
{
	`log("Gfx init parts");
	Scene = GetVariableObject("_root");
	Banner = GetSymbol("Banner");
	ShowBannerInfo(false);
}


/*--- Return index if a data line is found in str or else ---*/
function int IsInArray(string str, array<string> data, optional bool bInvert)
{
	local byte i;
	
	for (i = 0; i < data.Length; i++)
	{
		if (   (!bInvert && InStr(str, data[i]) != -1)
			|| (bInvert && InStr(data[i], str) != -1))
			return i;
	}
	return -1;
}


/*--- Go to a 0-i indexed frame ---*/
function GoToFrame(int index)
{
	Scene.GotoAndStopI(1 + index);
	InitParts();
}


/*----------------------------------------------------------
	Game methods
----------------------------------------------------------*/


/*--- Return to desktop ---*/
function QuitToDesktop(GFxClikWidget.EventData evtd)
{
	`log("Gfx exiting");
	PC.SaveGameStatistics(false, true);
	ConsoleCommand("exit");
}


/*--- Pause menu ---*/
function SetGamePaused()
{
	`log("Gfx paused game");
	if (PC != None)
	{
		PC.LockCamera(true);
	}
}


/*--- Game resume ---*/
function SetGameUnPaused()
{
	`log("Gfx resumed game");
	if (PC != None)
	{
		PC.LockCamera(false);
	}
	Scene.GotoAndStopI(1);
	InitParts();
}


/*--- Banner information to player ---*/
function ShowBannerInfo(bool NewState, optional string BannerText)
{
	// Checking
	if (Banner == None)
		return;
	
	// Actual info
	Banner.SetVisible(NewState);
	Banner.SetText(BannerText);
}


/*--- Play a sound ---*/
function PlayUISound(SoundCue sound)
{
	if (PC != None)
	{
		PC.PlaySound(sound);
	}
}


/*--- Apply a resolution code ---*/
function ApplyResolutionSetting(string code, string flag)
{
	switch (code)
	{
		case ("720p"):
			ConsoleCommand("SetRes 1280x720" $flag);
			break;
		case ("1080p"):
			ConsoleCommand("SetRes 1920x1080" $flag);
			break;
		case ("max"):
			ConsoleCommand("SetRes 6000x3500" $flag);
			break;
	}	
	
}


/*----------------------------------------------------------
	Weapon widget
----------------------------------------------------------*/

/*--- Set up a weapon widget ---*/
function SetupWeaponWidget(string WidgetName, string WeaponClass)
{
	// Vars
	local class<DVWeapon> wpClass;
	local string WeaponClassToLoad;
	local string IconPath;

	// Load a weapon class
	WeaponClassToLoad = "zGame." $ WeaponClass;
	wpClass = class<DVWeapon>(DynamicLoadObject(WeaponClassToLoad, class'Class', false));
	IconPath = wpClass.static.GetWeaponPath() $ string(wpClass.static.GetWeaponIcon());
	
	// Data
	SetLabel(WidgetName $".WName", 	wpClass.default.WeaponName, true);
	SetLabel(WidgetName $".WDesc", 	wpClass.default.WeaponDesc, false);
	SetLabel(WidgetName $".WStats", wpClass.default.WeaponDamage, false);
	SetupIcon(WidgetName$".WIcon",	IconPath);
}


/*----------------------------------------------------------
	Popup management
----------------------------------------------------------*/

/*--- Set up a popup using a text array, with 2 optional password fields ---*/
function SetPopup(string Text[7], optional int PField, optional int PField2)
{
	// Init
	local GFxObject TempObject;
	local byte i;
	PopupWindow = GetSymbol(PopupName);
	if (PopupWindow == None)
		return;
	
	// Text settings
	SetLabel(PopupName $ ".PopupTitle", Text[0], true);
	for (i = 1; i < PopupFieldCount + 2; i++)
	{
		if (i < PopupFieldCount)
		{
			// Label block
			TempObject = GetSymbol(PopupName $ ".PopupLabel" $ i);
			if (Text[i] != "")
			{
				TempObject.SetText(Text[i]);
				TempObject.SetVisible(true);
			}
			else
				TempObject.SetVisible(false);
			
			// Password block
			TempObject = GetSymbol(PopupName $ ".PopupField" $ i);
			if (Text[i] == "")
			{
				TempObject.SetVisible(false);
			}
			else if (i == PField || i == PField2)
			{
				TempObject.SetBool("displayAsPassword", true);
				TempObject.SetVisible(true);
				TempObject.SetText("");
			}
			else
			{
				TempObject.SetBool("displayAsPassword", false);
				TempObject.SetVisible(true);
			}
		}
		
		// Buttons
		else
		{
			TempObject = GetSymbol(PopupName $ ".PopupButton" $ (i + 1 - PopupFieldCount));
			if (Text[i] == "")
				TempObject.SetVisible(false);
			else
			{
				TempObject.SetString("label", Text[i]);
				TempObject.SetVisible(true);
			}
		}
	}
	SetPopupStatus("");
	PopupWindow.SetVisible(true);
	PlayUISound(BipSound);
}


/*--- Get popup content ---*/
function array<string> GetPopupContent()
{
	local array<string> Result;
	local GFxObject TempObject;
	local byte i;
	
	// Content
	for (i = 1; i < PopupFieldCount; i++)
	{
		TempObject = GetSymbol(PopupName $ ".PopupField" $ i);
		Result.AddItem(TempObject.GetString("text"));
	}
	return Result;
}


/*--- Set popup content ---*/
function SetPopupContent(int FieldID, string Content)
{
	local GFxObject TempObject;
	TempObject = GetSymbol(PopupName $ ".PopupField" $ FieldID);
	TempObject.SetText(Content);
}


/*--- Hide the popup ---*/
function HidePopup(optional bool bHide)
{
	PopupWindow.SetVisible(!bHide);
}


/*--- Set the status ---*/
function SetPopupStatus(string NewStatus)
{
	local GFxObject StatusField;
	
	StatusField = GetSymbol(PopupName $ ".PopupStatus");
	StatusField.SetText(NewStatus);
	
	StatusField.SetVisible(NewStatus != "");
}


/*--- Popup button 1 ---*/
function OnPButton1(GFxClikWidget.EventData evtd)
{
	PlayUISound(BipSound);
}


/*--- Popup button 2 ---*/
function OnPButton2(GFxClikWidget.EventData evtd)
{
	PlayUISound(BipSound);
}


/*----------------------------------------------------------
	Various interface widgets
----------------------------------------------------------*/

/*--- Set the loader content ---*/
simulated function SetupIcon(string IconName, string ImageData)
{
	// Vars
	local GFxObject Icon;
	local array<ASValue> Args;
	local ASValue ASVal;
	
	// Data
	ASVal.Type = AS_String;
	ASVal.s = ImageData;
	Args[0] = ASVal;
	Icon = GetSymbol(IconName);
	Icon.Invoke("LoadIcon", Args);
}


/*--- Set a pie chart and associated label ---*/
function SetPieChart(string PieName, string LabelName, string LabelText, float x)
{
	local GfxObject PieStat1;
	
	SetAlignedLabel(LabelName, LabelText, "" $ round(x) $ "%");
	PieStat1 = GetSymbol("" $ PieName $ ".percentage");
	PieStat1.GotoAndStopI(round(x * 3.6));
}


/*--- Get a Flash text, set it and align it using spaces ---*/
function SetAlignedLabel(string SymbolName, string Text1, string Text2)
{
	local int CurrentSize;
	local int SpaceFactor;
	local string Spacer;
	local byte i;
	
	Spacer = "";
	CurrentSize = Len(Text1) + Len(Text2);
	SpaceFactor = (float(LSize) / float(CurrentSize)) * SpaceSizeFactor;
	if (CurrentSize < LSize)
	{
		for (i = CurrentSize; i < round(LSize + SpaceFactor); i++)
		Spacer $= " ";
	}
	
	SetLabel(SymbolName, Text1 $ Spacer $ Text2, false);
}


/*--- Get a Flash text and set it ---*/
function SetLabel(string SymbolName, string Text, bool bIsCaps)
{
	local GFxObject Symbol;
	Symbol = GetSymbol(SymbolName);
	
	if (Symbol == None)
	{
		`warn("Null symbol : " $ SymbolName);
		return;
	}
	
	if (bIsCaps)
	{
		Text = Caps(Text);
	}
	Symbol.SetText(Text);
}


/*--- Get a Flash widget and set it ---*/
function SetWidgetLabel(string SymbolName, string Text, bool bIsCaps)
{
	local GFxObject Symbol;
	Symbol = GetSymbol(SymbolName);
	
	if (Symbol == None)
	{
		`warn("Null symbol : " $ SymbolName);
		return;
	}
	
	if (bIsCaps)
	{
		Text = Caps(Text);
	}
	Symbol.SetString("label", Text);
}


/*--- Get a Flash object reference --*/
function GFxObject GetSymbol(string SymbolName)
{
	return GetVariableObject("_root." $ SymbolName);
}


/*--- Get a list item name ---*/
function string GetListItemClicked(GFxClikWidget.EventData ev)
{
	local GFxObject button;
	
	button = ev._this.GetObject("itemRenderer");
	return button.GetString("label");
}


/*--- Get an event-connected widget ---*/
function GFxClikWidget GetLiveWidget(GFxObject Widget, name type, delegate<GFxClikWidget.EventListener> listener)
{
	local GFxClikWidget wg;
	
	wg = GFxClikWidget(Widget);
	wg.AddEventListener(type, listener);
	
	return wg;
}


/*--- Get a checkbox value ---*/
function bool IsChecked(string Symbol)
{
	Local GFxObject button; 
	button = GetSymbol(Symbol);
	return button.GetBool("selected");
}


/*--- Set a checbox value ---*/
function SetChecked(string Symbol, bool Value)
{
	Local GFxObject button; 
	button = GetSymbol(Symbol);
	button.SetBool("selected", Value);
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- Button behaviour connection ---*/
event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch(WidgetName)
	{
		case ('ExitButton'):
			QuitButton = GetLiveWidget(Widget, 'CLIK_click', QuitToDesktop);
			break;
			
		case ('PopupButton1'):
			PopupButton1 = GFxClikWidget(Widget);
			PopupButton1.AddEventListener('CLIK_click', OnPButton1);
			break;
		
		case ('PopupButton2'):
			PopupButton2 = GFxClikWidget(Widget);
			PopupButton2.AddEventListener('CLIK_click', OnPButton2);
			break;
		
		default: break;
	}
	return true;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// HUD Settings
	bAllowInput=true
	bAllowFocus=true
	bDisplayWithHudOff=false
	
	// Settings
	LSize=40
	SpaceSizeFactor=1
	PopupFieldCount=5
	PopupName="PopupWindow"
	BipSound=SoundCue'DV_Sound.UI.A_Bip'
	ClickSound=SoundCue'DV_Sound.UI.A_Click'
	
	// Bindings
	WidgetBindings(0)={(WidgetName="ExitButton",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(1)={(WidgetName="PopupButton1",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(2)={(WidgetName="PopupButton2",WidgetClass=class'GFxClikWidget')}
}
