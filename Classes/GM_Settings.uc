/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Settings extends GMenu;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const string					UsernameText;
var (Menu) const string					PasswordText;
var (Menu) const string					Separator;

var (Menu) const array<string>			BindListData;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var bool								bIsKeyEditing;

var int									CurrentKeyID;

var string								CurrentKeyData;

var GButton								Validate;
var GDropList							ResDropList;
var GToggleButton						CurrentKeyButton;

var GToggleButton						BackgroundMusic;
var GToggleButton						UseSoundOnHit;
var GToggleButton						FullScreen;

var GToggleButton						Invert;
var GTextField							Sensitivity;

var array<GToggleButton>				EditKeyButtons;


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Key setting buttons
 * @param Reference				Caller actor
 */
delegate GoKey(Actor Caller)
{
	CurrentKeyButton = GToggleButton(Caller);
	if (!bIsKeyEditing)
	{
		CurrentKeyData = CurrentKeyButton.Text;
		CurrentKeyID = (IsInArray(Split(CurrentKeyData, Separator, true), KeyListData, true) + 1);
		CurrentKeyButton.Set(lWaitingForKey, "");
		bIsKeyEditing = true;
	}
	else
	{
		CurrentKeyButton.SetState(false);
	}
}

/**
 * @brief Key press event
 * @param Key					Key used
 * @param Evt					Event type
 * @return true if event is consummed, false to keep it propagating
 */
function bool KeyPressed(name Key, EInputEvent Evt)
{
	if (bIsKeyEditing && Evt == IE_Released)
	{
		switch(Key)
		{
			// Cancel
			case 'Escape':
				CurrentKeyButton.Set(CurrentKeyData, "");
				bIsKeyEditing = false;
				break;
			
			// Key editing
			default:
				CurrentKeyButton.Set(Key $ Separator $ KeyListData[CurrentKeyID-1], "");
				CurrentKeyButton.SetState(false);
				bIsKeyEditing = false;
				break;
		}
		return true;
	}
	else
	{
		return false;
	}
}

/**
 * @brief Called on tab key
 * @param bIsGoingUp			Unused
 */
simulated function Tab(bool bIsGoingUp)
{
	if (!bIsKeyEditing)
	{
		Super.Tab(bIsGoingUp);
	}
}

/**
 * @brief Called on enter key
 */
simulated function Enter()
{
	GoValidate(None);
}

/**
 * @brief Validate button
 * @param Reference				Caller actor
 */
delegate GoValidate(Actor Caller)
{
	// Resolution
	local byte i;
	local string res, flag;
	local DVUserStats LS;
	PC = DVPlayerController(GetALocalPlayerController());
	LS = DVPlayerController(PC).LocalStats;
	res = Split(ResDropList.GetSelectedContent(), "[", false);
	
	// Application
	flag = (FullScreen.GetState() ? "f" : "w");
	res = Repl(Repl(res, "[", ""), "]", "");
	GH_Menu(PC.myHUD).ApplyResolutionSetting(res, flag);
	
	// Options
	LS.SetBoolValue("bBackgroundMusic", BackgroundMusic.GetState());
	LS.SetBoolValue("bUseSoundOnHit", UseSoundOnHit.GetState());
	LS.SetBoolValue("bFullScreen", FullScreen.GetState());
	LS.SetStringValue("Resolution", res);
	LS.SaveConfig();
	
	// Keys
	for (i = 0; i < KeyListData.Length; i++)
	{
		res = Left(EditKeyButtons[i].Text, InStr(EditKeyButtons[i].Text, Separator));
		DVPlayerInput(PC.PlayerInput).SetKeyBinding(name(res), BindListData[i]);
	}

	// Mouse
	DVPLayerController(PC).SetMouse(float(Sensitivity.GetText()));
}

/**
 * @brief Back button
 * @param Reference				Caller actor
 */
delegate GoBack(Actor Caller)
{
	`log("GM > GoBack" @self);
	if (Origin != None && !bIsKeyEditing)
	{
		ChangeMenu(Origin);
	}
}

/**
 * @brief Toggle button callback for settings
 * @param Reference				Caller actor
 */
delegate GoToggle(Actor Caller)
{
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function SpawnUI()
{
	// Init
	local byte i;
	local string Key;
	local DVUserStats LS;
	local GMenu PreviousMenu;
	local GToggleButton Temp;
	LS = DVPlayerController(PC).LocalStats;
	
	// Video
	AddLabel(Vect(-300,0,400), lVideo);
	BackgroundMusic = GToggleButton(AddButton(Vect(-280,0,370), lIngameMusic, "", GoToggle));
	BackgroundMusic.SetState(LS.bBackgroundMusic);
	UseSoundOnHit = GToggleButton(AddButton(Vect(-280,0,340), lImpactIndicator, "", GoToggle));
	UseSoundOnHit.SetState(LS.bUseSoundOnHit);
	FullScreen = GToggleButton(AddButton(Vect(-280,0,310), lFullScreen, "", GoToggle));
	FullScreen.SetState(LS.bFullScreen);
	ResDropList = AddDropList(Vect(-280,0,280), "Resolution", "Resolution", ResListData, class'GDL_Small');
	
	// Mouse
	AddLabel(Vect(-300,0,210), lMouse);
	AddLabel(Vect(-280,0,180), lSensitivity);
	Sensitivity = AddTextField(Vect(-80,0,180));
	Sensitivity.SetText(""$(DVPlayerInput(PC.PlayerInput).MouseSensitivity * 2.5));
	Invert = GToggleButton(AddButton(Vect(-280,0,150), lInvert, "", GoToggle));
	Invert.SetState(DVPlayerInput(PC.PlayerInput).bInvertMouse);

	// Key editing
	for (i = 0; i < KeyListData.Length; i++)
	{
		Key = DVPlayerInput(PC.PlayerInput).GetKeyBinding(BindListData[i]);
		Temp = GToggleButton(AddButton(
			Vect(300,0,400) - i * Vect(0,0,30), 
			Key $ Separator $ KeyListData[i],
			"",
			GoKey
		));
		EditKeyButtons.AddItem(Temp);
	}
	
	// Setting save
	PreviousMenu = GetRelatedMenu(true);
	AddMenuLink(Vect(-300,0,70), PreviousMenu, class'GButton');
	Validate = AddButton(Vect(300,0,70), lSaveSettings, lSaveSettings, GoValidate, class'GButton');
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Index=30
	Separator="   |   "
	bIsKeyEditing=false
	ButtonClass=class'GToggleButton'
	BindListData=("GBA_MoveForward","GBA_Backward","GBA_StrafeLeft","GBA_StrafeRight","GBA_Jump","GBA_Duck","GBA_Use","GBA_ShowCommandMenu","GBA_Talk","GBA_Activate")
}
