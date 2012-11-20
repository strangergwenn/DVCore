/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwenna�l ARBONA
 **/

class DVPlayerInput extends UDKPlayerInput within DVPlayerController
	config(Input);


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var float 							LastAdvanceTime;
var bool  							bHoldDuck;

var IntPoint						MousePosition;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/*--- Mouse input ---*/
event PlayerInput(float DeltaTime)
{
	if (myHUD != None)
	{
		MousePosition.X = Clamp(MousePosition.X + aMouseX, 0, myHUD.SizeX);
		MousePosition.Y = Clamp(MousePosition.Y - aMouseY, 0, myHUD.SizeY);
	}
	
	if (!bWasForward)
	{
		bRun = 0;
		DVPawn(Pawn).SetRunning(false);
	}
		
	super.PlayerInput(DeltaTime);
}


/*--- Ducking is mapped to running so this is RUNNING ---*/
simulated exec function Duck()
{
	// Chatting
	if (IsChatLocked())
		return;
	
	if (Pawn.Health > DVPawn(Pawn).SprintDamage)
	{
		bRun = 1;
		DVPawn(Pawn).SetRunning(true);
	}
}


/*--- Stop running (yeah, running) ---*/
simulated exec function UnDuck()
{
	bRun = 0;
	DVPawn(Pawn).SetRunning(false);
}


/*--- Jump ---*/
exec function Jump()
{
	// Chatting
	if (IsChatLocked())
		return;
	
	super.Jump();
}


/*--- Key pressed delegate ---*/
function bool KeyInput(int ControllerId, name KeyName, EInputEvent IEvent, float AmountDepressed, optional bool bGamepad)
{
	// Main menu keys
	if (IEvent == IE_Pressed && DVHUD_Menu(myHUD) != None)
	{
		DVHUD_Menu(myHUD).HudMovie.SetKeyPressed(string(KeyName));
		DVHUD_Menu(myHUD).CancelHide();
		
		// Popup navigation
		if (KeyName == 'Enter')
			DVHUD_Menu(myHUD).HudMovie.ForceValidate();
		else if (KeyName == 'Escape')
			DVHUD_Menu(myHUD).HudMovie.HidePopup();
		
		`log("DVPI > Pressed" @KeyName);
	}
	return false;
}


/*--- Get a key current binding ---*/
simulated exec function string GetKeyBinding(string Command)
{
    local byte i;

	for (i = 0; i < Bindings.Length; i++)
	{
		if (Bindings[i].Command == Command)
			return string(Bindings[i].Name);
	}
}


/*--- Switch a key binding ---*/
simulated exec function SetKeyBinding(name BindName, string Command)
{
	// Init
    local int i;
    if (Command == "none")
    	Command = "";

	// Setting
	for(i = Bindings.Length - 1; i >= 0; i --)
	{
		if (Bindings[i].Name == BindName)
		{
			Bindings[i].Command = Command;
			SaveConfig();
		}
		else if (Bindings[i].Command == Command)
		{
			Bindings[i].Name = BindName;
			SaveConfig();
		}
	}
	SaveConfig();
}


/*--- Permit to lock movement when stuck ---*/
simulated function PostProcessInput(float DeltaTime)
{
	if (bShouldStop && aBaseY > 0.0)
		aBaseY = 0.0;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	OnReceivedNativeInputKey=KeyInput
}
