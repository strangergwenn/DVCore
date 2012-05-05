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
	Methods
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
	if (PC != None)
	{
		PC.LockCamera(false);
	}
	Scene.GotoAndPlayI(1);
	InitParts();
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- Button behaviour connection ---*/
event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch(WidgetName)
	{
		case ('QuitDesktop'):
			QuitButton = GFxClikWidget(Widget);
			QuitButton.AddEventListener('CLIK_click', QuitToDesktop);
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
	WidgetBindings(0)={(WidgetName="QuitDesktop",WidgetClass=class'GFxClikWidget')}
}
