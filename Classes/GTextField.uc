/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GTextField extends GToggleButton
	placeable;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var bool							bEditing;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Get the text content
 * @param Data				Text to set
 **/
simulated function SetText(string Data)
{
	Text = Data;
}

/**
 * @brief Get the text content
 * @return Text data
 **/
simulated function string GetText()
{
	return Text;
}

/**
 * @brief Set the button state
 * @param bNewState			New state to set
 */
simulated function SetState(bool bNewState)
{
	super.SetState(bNewState);
	if (bNewState)
	{
		SetText("");
	}
}

/**
 * @brief Key callback
 * @param Key				Name of the pressed key
 */
simulated function KeyPressed(name Key)
{
	if (bEnabled && bIsActive)
	{
		switch(Key)
		{
			case 'BackSpace':
				Text = Left(Text, Len(Text) -1);
				break;
			case 'Enter':
				break;
			case 'NumPadOne':
				Text $= "1";
				break;
			case 'NumPadTwo':
				Text $= "2";
				break;
			case 'NumPadThree':
				Text $= "3";
				break;
			case 'NumPadFour':
				Text $= "4";
				break;
			case 'NumPadFive':
				Text $= "5";
				break;
			case 'NumPadSix':
				Text $= "6";
				break;
			case 'NumPadSeven':
				Text $= "7";
				break;
			case 'NumPadEight':
				Text $= "8";
				break;
			case 'NumPadNine':
				Text $= "9";
				break;
			case 'NumPadZero':
				Text $= "0";
				break;
			default:
				Text $= Key;
		}
	}
}

/**
 * @brief Called when the focus is lost (click etc)
 */
simulated function LostFocus()
{
	SetState(false);
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	Set("", "Text field");
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Effect=None
}
