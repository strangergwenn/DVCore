/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GTextField extends GToggleButton
	placeable;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

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
	if (bEnabled)
	{
		if (Key == 'BackSpace')
			Text = Left(Text, Len(Text) -1);
		else
			Text $= Key;
	}
}

/**
 * @brief Called when the focus is lost (click etc)
 */
simulated function LostFocus()
{
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
	Set("", "I am a text field");
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
}
