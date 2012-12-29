/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Settings extends GMenu
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics, Attachment);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const string					UsernameText;
var (Menu) const string					PasswordText;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GButton								Validate;
var GToggleButton						BackgroundMusic;
var GToggleButton						UseSoundOnHit;
var GToggleButton						FullScreen;


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Toggle button callback for settings
 * @param Reference				Caller actor
 */
delegate GoToggle(Actor Caller)
{
}

/**
 * @brief Validate button
 * @param Reference				Caller actor
 */
delegate GoValidate(Actor Caller)
{
}

/**
 * @brief Called on enter key
 */
simulated function Enter()
{
	GoValidate(None);
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function SpawnUI()
{
	super.SpawnUI();
	Label.Destroy();
	
	BackgroundMusic = GToggleButton(AddButton(Vect(-300,0,300), "Music",
		"", GoToggle, class'GB_Clean'));
	BackgroundMusic.SetState(PC.LocalStats.bBackgroundMusic);
	
	UseSoundOnHit = GToggleButton(AddButton(Vect(-300,0,250), "Sound on hit",
		"", GoToggle, class'GB_Clean'));
	UseSoundOnHit.SetState(PC.LocalStats.bUseSoundOnHit);
	
	FullScreen = GToggleButton(AddButton(Vect(-300,0,200), "Fullscreen",
		"", GoToggle, class'GB_Clean'));
	FullScreen.SetState(PC.LocalStats.bFullScreen);
	
	AddButton(Vect(220,0,0), "Validate", "", GoValidate);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Index=30
	LabelClass=class'GL_Clean'
	MenuName="Settings"
	MenuComment="Setup the game"
}
