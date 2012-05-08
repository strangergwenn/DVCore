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

var (DVMovie) const SoundCue 			BipSound;
var (DVMovie) const SoundCue 			ClickSound;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var DVPlayerController					PC;

var GFxObject 							Scene;
var GFxClikWidget 						QuitButton;


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
}


/*--- Return true if str is found in data ---*/
function bool IsInArray(string str, array<string> data)
{
	local byte i;
	
	for (i = 0; i < data.Length; i++)
	{
		if (InStr(str, data[i]) != -1)
			return true;
	}
	return false;
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
	Scene.GotoAndPlayI(1);
	InitParts();
}


/*----------------------------------------------------------
	Getters / Setters
----------------------------------------------------------*/

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

/*--- Get a Flash object reference --*/
function GFxObject GetSymbol(string SymbolName)
{
	return GetVariableObject("_root." $ SymbolName);
}


/*--- Get an event-connected widget ---*/
function GFxClikWidget GetLiveWidget(GFxObject Widget, name type, delegate<GFxClikWidget.EventListener> listener)
{
	local GFxClikWidget wg;
	
	wg = GFxClikWidget(Widget);
	wg.AddEventListener(type, listener);
	
	return wg;
} 


/*--- Play a sound ---*/
function PlayUISound(SoundCue sound)
{
	if (PC != None)
	{
		PC.PlaySound(sound);
	}
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
	BipSound=SoundCue'DV_Sound.UI.A_Bip'
	ClickSound=SoundCue'DV_Sound.UI.A_Click'
	
	// Bindings
	WidgetBindings(0)={(WidgetName="ExitButton",WidgetClass=class'GFxClikWidget')}
}
