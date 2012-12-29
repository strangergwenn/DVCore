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
var bool							bClearNext;
var bool							bIsPassword;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Set the text content
 * @param Data				Text to set
 **/
simulated function SetText(string Data)
{
	Text = Data;
}
/**
 * @brief Set the password attribute
 * @param bPassword			True is data masked
 **/
simulated function SetPassword(bool bPassword)
{
	bIsPassword = bPassword;
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
 * @brief Called when the focus is lost (click etc)
 */
simulated function LostFocus()
{
	SetState(false);
}

/**
 * @brief Key callback
 * @param Key				Name of the pressed key
 */
simulated function KeyPressed(string Key)
{
	if (bClearNext)
	{
		bClearNext = false;
		return;	
	}
	
	if (Key != "" && bEnabled && bIsActive)
	{
		if (Key == "BackSpace")
		{
			bClearNext = true;
			Text = Left(Text, Len(Text) -1);
		}
		else if (Len(Key) == 1)
		{
			Text $= Key;
		}
		else
		{
			bClearNext = true;
		}
	}
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
	Set("...", "Text field");
}

/**
 * @brief Rendering method
 */
function OnRender(Canvas C)
{
	local byte i;
	local string DisplayText;
	DisplayText = Text;
	C.SetOrigin(TextOffsetX, TextOffsetY);
	C.SetPos(0, 0);
	C.SetDrawColorStruct(TextColor);
	
	if (bIsPassword)
	{
		DisplayText = "";
		for (i = 0; i < Len(Text); i++)
		{
			DisplayText $= "*";
		}
	}
	
	C.DrawText(DisplayText,, TextScale, TextScale);
	CanvasTexture.bNeedsUpdate = true;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Begin Object Name=LabelMesh
		StaticMesh=StaticMesh'DV_UI.Mesh.SM_SimpleLabel'
		Scale=0.8
	End Object
	
	bClearNext=false
	Effect=None
	TextScale=5.0
	TextOffsetX=30.0
	TextOffsetY=25.0
	TextMaterialTemplate=Material'DV_UI.Material.M_EmissiveLabel'
}
