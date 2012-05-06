/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVMovie extends GFxMoviePlayer;


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
	Advance(0);
	InitParts();
	return true;
}


/*--- Do this on start & restart --*/
function InitParts()
{
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


/*----------------------------------------------------------
	Game methods
----------------------------------------------------------*/


/*--- Return to desktop ---*/
function QuitToDesktop(GFxClikWidget.EventData evtd)
{
	ConsoleCommand("exit");
}


/*--- Pause menu ---*/
function SetGamePaused()
{
	if (PC != None)
	{
		PC.LockCamera(true);
	}
}


/*--- Game resume ---*/
function SetGameUnPaused()
{
	Scene.GotoAndPlayI(1);
	InitParts();
	if (PC != None)
	{
		PC.LockCamera(false);
	}
}


/*----------------------------------------------------------
	Getters / Setters
----------------------------------------------------------*/

/*--- Get a Flash text and set it ---*/
function SetLabel(string SymbolName, string Text, bool bIsCaps)
{
	local GFxObject Symbol;
	Symbol = GetSymbol(SymbolName);
	
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
	
	// Bindings
	WidgetBindings(0)={(WidgetName="ExitButton",WidgetClass=class'GFxClikWidget')}
}
