/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GMenu extends GLocalizedObject
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics, Attachment);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const int					Index;

var (Menu) const float					MenuSwitchTime;

var (Menu) const vector					ViewOffset;

var (Menu) const string					MenuName;
var (Menu) const string					MenuComment;

var (Menu) const class<GTextField>		TextFieldClass;
var (Menu) const class<GButton>			ButtonClass;
var (Menu) const class<GLabel>			LabelClass;

var (Menu) GViewPoint					ViewPoint;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GLabel								Label;
var array<GLabel>						Items;

var GMenu								Origin;

var StaticMeshComponent					Mesh;

var DVPlayerController					PC;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Set the label on the menu
 * @param Text				Label data
 */
simulated function SetLabel(string Text)
{
	if (Text != "" && Label != None)
	{
		Label.Set(Text, "");
	}
	else if (Label != None)
	{
		Label.Set(MenuName @"-" @MenuComment, "");
	}
}

/**
 * @brief Set the previous menu data
 * @param Org				Previous menu reference
 */
simulated function SetOrigin(GMenu Org)
{
	if (Origin == None || Index > 1000)
	{
		Origin = Org;
	}
}

/**
 * @brief Check the string presence in an array
 * @param str					String to search
 * @param data					Array to search in
 * @param bInvert				Invert the searching mode
 * @return Index found or -1
 */
simulated function int IsInArray(string str, array<string> data, optional bool bInvert)
{
	local byte i;
	
	for (i = 0; i < data.Length; i++)
	{
		if (   (!bInvert && InStr(str, data[i]) != -1)
			|| (bInvert && InStr(data[i], str) != -1))
			return i;
	}
	return -1;
}


/*----------------------------------------------------------
	Key methods
----------------------------------------------------------*/

/**
 * @brief Called on tab key
 * @param bIsGoingUp			Unused
 */
simulated function Tab(bool bIsGoingUp)
{
	// Find all the available buttons
	local byte i, iNext;
	local GToggleButton Old;
	local array<GToggleButton> ToggleItems;
	for (i = 0; i < Items.Length; i++)
	{
		if (Items[i].IsA('GToggleButton'))
		{
			ToggleItems.AddItem(GToggleButton(Items[i]));
		}
	}
	
	// Find the old button
	if (ToggleItems.Length == 0)
	{
		return;
	}
	Old = None;
	for (i = 0; i < ToggleItems.Length; i++)
	{
		if (ToggleItems[i].GetState())
		{
			Old = ToggleItems[i];
			break;
		}
	}
	
	// No one is selected ? toggle default
	if (Old == None)
	{
		`log("GM > Tab > Toggle default" @ToggleItems[0]);
		GHUD(PC.myHUD).ForceFocus(ToggleItems[0]);
	}
	else
	{
		iNext = (bIsGoingUp ? i-1 : i+1);
		if (iNext < 0)
			iNext = ToggleItems.Length - 1;
		else if (iNext >= ToggleItems.Length)
			iNext = 0;
		
		if (Old.GetState())
		{
			Old.SetState(false);
		}
		GHUD(PC.myHUD).ForceFocus(ToggleItems[iNext]);
		`log("GM > Tab > Toggle item" @ToggleItems[iNext] @i);
	}
}

/**
 * @brief Called on scroll
 * @param bIsGoingUp			Is the player going up ?
 */
simulated function Scroll(bool bIsGoingUp)
{
}

/**
 * @brief Called on enter key
 */
simulated function Enter()
{
}


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Exit the game
 * @param Caller			Caller actor
 */
delegate GoExit(Actor Caller)
{
	`log("GM > GoExit" @self);
	ConsoleCommand("quit");
}

/**
 * @brief Change menu
 * @param Caller			Caller actor
 */
delegate GoChangeMenu(Actor Caller)
{
	`log("GM > GoChangeMenu" @self);
	if (GButton(Caller).TargetMenu != None)
	{
		ChangeMenu(GButton(Caller).TargetMenu);
	}
}

/**
 * @brief Back button
 * @param Reference				Caller actor
 */
delegate GoBack(Actor Caller)
{
	`log("GM > GoBack" @self);
	if (Origin != None)
	{
		ChangeMenu(Origin);
	}
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Change the current menu
 * @param NewMenu			New menu to use
 */
simulated function ChangeMenu(GMenu NewMenu)
{
	local ViewTargetTransitionParams TransitionParams;
	`log("GM > ChangeMenu" @NewMenu @self);

	if (PC == None)
	{
		PC = DVPlayerController(GetALocalPlayerController());
	}
	if (PC != None)
	{
		NewMenu.SetOrigin(self);
		TransitionParams.BlendTime = MenuSwitchTime;
		TransitionParams.BlendFunction = VTBlend_EaseInOut;
		TransitionParams.BlendExp = 2.0;
		TransitionParams.bLockOutgoing = false;
		PC.SetViewTarget(NewMenu.ViewPoint, TransitionParams);
		GHUD(PC.myHUD).SetCurrentMenu(NewMenu, MenuSwitchTime);
	}
}

/**
 * @brief Get the next (or previous) menu by index
 * @param bPrevious			If true, search backward
 * @return The closest menu in the chosen direction or None
 */
simulated function GMenu GetRelatedMenu(bool bPrevious)
{
	local GMenu Temp;
	local GMenu Result;
	local int BestIndex;
	BestIndex = (bPrevious ? -1000 : 1000);
	Result = None;

	foreach AllActors(class'GMenu', Temp)
	{
		if (((Temp.Index < Index) && (Temp.Index > BestIndex) && bPrevious)
		 ||  (Temp.Index > Index) && (Temp.Index < BestIndex) && !bPrevious)
		{
			Result = Temp; 
			BestIndex = Temp.Index;
		}
	}
	
	return Result;
}

/**
 * @brief Get a menu by index
 * @param SearchID			Menu index
 * @return The found menu or None
 */
simulated function GMenu GetMenuByID(int SearchID)
{
	local GMenu Temp;
	foreach AllActors(class'GMenu', Temp)
	{
		if (Temp.Index == SearchID)
		{
			return Temp;
		}
	}
	return None;
}

/**
 * @brief Get a menu by name
 * @param SearchName		Menu name
 * @return The found menu or None
 */
simulated function GMenu GetMenuByName(string SearchName)
{
	local GMenu Temp;
	foreach AllActors(class'GMenu', Temp)
	{
		if (Temp.MenuName == SearchName)
		{
			return Temp;
		}
	}
	return None;
}

/**
 * @brief Add a menu link on the menu
 * @param Pos				Offset from menu origin
 * @param Target			Target menu
 * @param SpawnClass		Optional class to use
 * @return added item
 */
simulated function GButton AddMenuLink(vector Pos, GMenu Target,
	optional class<GButton> SpawnClass=ButtonClass)
{
	local GButton Temp;
	if (Target != None)
	{
		Temp = AddButton(Pos, Target.MenuName, Target.MenuComment, GoChangeMenu, SpawnClass);
		Temp.SetTarget(Target);
	}
	return Temp;
}

/**
 * @brief Add a button on the menu
 * @param Pos				Offset from menu origin
 * @param Text				Button name
 * @param Comment			Button help
 * @param CB				Method to call on button press
 * @param SpawnClass		Optional class to use
 * @return added item
 */
simulated function GButton AddButton(vector Pos, string Text, string Comment, delegate<GButton.PressCB> CB,
	optional class<GButton> SpawnClass=ButtonClass)
{
	local GButton Temp;
	Temp = Spawn(SpawnClass, self, , Location + (Pos >> Rotation));
	Temp.Set(Text, Comment);
	Temp.SetPress(CB);
	Temp.SetRotation(Rotation);
	Items.AddItem(Temp);
	return Temp;
}

/**
 * @brief Add a label on the menu
 * @param Pos				Offset from menu origin
 * @param Text				Label name
 * @param SpawnClass		Optional class to use
 * @return added item
 */
simulated function GLabel AddLabel(vector Pos, string Text, 
	optional class<GLabel> SpawnClass=LabelClass)
{
	local GLabel Temp;
	Temp = Spawn(SpawnClass, self, , Location + (Pos >> Rotation));
	Temp.Set(Text, "");
	Temp.SetRotation(Rotation);
	Items.AddItem(Temp);
	return Temp;
}

/**
 * @brief Add a text field on the menu
 * @param Pos				Offset from menu origin
 * @param SpawnClass		Optional class to use
 * @return added item
 */
simulated function GTextField AddTextField(vector Pos, 
	optional class<GTextField> SpawnClass=TextFieldClass)
{
	local GTextField Temp;
	Temp = Spawn(SpawnClass, self, , Location + (Pos >> Rotation));
	Temp.SetRotation(Rotation);
	Items.AddItem(Temp);
	return Temp;
}

/**
 * @brief Spawn event : basic setup
 */
simulated function PostBeginPlay()
{
	local vector X, Y, Z;
	local rotator ViewRot;
	super.PostBeginPlay();
	Mesh.SetHidden(true);
	
	// Viewpoint rotation (spawn a reference actor)
	ViewRot.Pitch -= 0;
	ViewRot.Yaw -= 16384;
	ViewRot.Roll -= 0;
	GetAxes(ViewRot, X, Y, Z);
	ViewPoint = Spawn(
		class'GViewPoint', self,,
		Location + (ViewOffset >> Rotation),
		OrthoRotation(X >> Rotation, Y >> Rotation, Z >> Rotation)
	);
	
	// Helper label and custom UI
	Label = Spawn(LabelClass, self, , Location + (Vect(-300,0,430) >> Rotation));
	Label.SetRotation(Rotation);
	Label.Set(MenuName @"-" @MenuComment, "");
	Items.AddItem(Label);
	GetPC();
}

/**
 * @brief Get a player
 **/
simulated function GetPC()
{
	PC = DVPlayerController(GetALocalPlayerController());
	if (PC == None)
	{
		SetTimer(0.5, false, 'GetPC');
	}
	else
	{
		SpawnUI();
	}
}

/**
 * @brief Launch the UI fo this menu
 */
simulated function SpawnUI()
{
	local GMenu PreviousMenu, NextMenu;
	PreviousMenu = GetRelatedMenu(true);
	NextMenu = GetRelatedMenu(false);
	
	AddMenuLink(Vect(-300,0,0), PreviousMenu);
	AddMenuLink(Vect(300,0,0), NextMenu);
}

/**
 * @brief Tick event (thread)
 * @param DeltaTime			Time since last tick
 */
simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Menu data
	Index=9000
	MenuName="Menu"
	MenuComment="Change menu"
	
	// Behaviour
	MenuSwitchTime=0.7
	bEdShouldSnap=true
	TextFieldClass=class'GTextField'
	ButtonClass=class'GButton'
	LabelClass=class'GLabel'
	ViewOffset=(X=0,Y=500,Z=250)
	
	// Mesh
	Begin Object class=StaticMeshComponent name=MenuBase		
		BlockActors=true
		CollideActors=true
		BlockRigidBody=true
		BlockZeroExtent=true
		BlockNonzeroExtent=true
		CastShadow=false
		bAcceptsLights=true
		bCastDynamicShadow=false
		bForceDirectLightMap=true
		Scale=0.7
		Translation=(Z=-48)
		StaticMesh=StaticMesh'DV_Spacegear.Mesh.SM_FlagBase'
	End Object
	Components.Add(MenuBase)
	Mesh=MenuBase
}
