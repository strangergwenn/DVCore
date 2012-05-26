/**
 *  This work is distributed under the General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVConsole extends Console;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

function bool InputKey( int ControllerId, name Key, EInputEvent Event, float AmountDepressed = 1.f, bool bGamepad = FALSE )
{
	if (Event == IE_Pressed)
	{
		bCaptureKeyInput = false;

		if (Key == ConsoleKey)
		{
			GotoState('Open');
			bCaptureKeyInput = true;
		}
		else if (Key == TypeKey)
		{
			GotoState('Typing');
			bCaptureKeyInput = true;
		}
	}

	return bCaptureKeyInput;
}

state Typing
{
	function bool InputKey(int ControllerId, name Key, EInputEvent Event, float AmountDepressed = 1.f, bool bGamepad = FALSE )
	{
		if (Key == 'Escape' && Event == IE_Released)
		{
			GotoState('');
			return true;
		}

		return Super.InputKey(ControllerId, Key, Event, AmountDepressed, bGamepad);
	}
}
