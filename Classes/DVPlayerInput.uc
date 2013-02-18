/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwenna�l ARBONA
 **/

class DVPlayerInput extends GPlayerInput within DVPlayerController
	config(Input);


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var float 							LastAdvanceTime;
var bool  							bHoldDuck;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/** @brief Ducking is mapped to running so this is RUNNING */
simulated exec function Duck()
{
	// Chatting
	if (IsChatLocked())
		return;
	
	if (bRun == 0 && Pawn.Health > DVPawn(Pawn).SprintDamage)
	{
		bRun = 1;
		DVPawn(Pawn).SetRunning(true);
	}
}


/** @brief Stop running (yeah, running) */
simulated exec function UnDuck()
{
	bRun = 0;
	DVPawn(Pawn).SetRunning(false);
}


/** @brief Jump */
exec function Jump()
{
	// Chatting
	if (IsChatLocked())
		return;
	
	super.Jump();
}


/** @brief Key pressed delegate */
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
	}
	
	// Ingame tab key
	if (DVHUD(myHUD) != None)
	{
		if (KeyName == 'Tab' && !DVHUD(myHUD).HudMovie.bChatting)
		{
			DVHUD(myHUD).HudMovie.CloseChat();
		}
	}

	// New menu
	else if (GHUD(myHUD) != None)
	{
		GHUD(myHUD).KeyPressed(KeyName, IEvent);
		return true;
	}
	return false;
}

/** @brief Permit to lock movement when stuck */
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
}
