/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GMenu extends Actor
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics, Attachment);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const int					Index;

var (Menu) const vector					ViewOffset;

var (Menu) const string					MenuName;
var (Menu) const string					MenuComment;

var (Menu) const class<GButton>			ButtonClass;
var (Menu) const class<GLabel>			LabelClass;

var (Menu) GViewPoint					ViewPoint;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GLabel								Label;
var array<GLabel>						Items;

var GMenu 								PreviousMenu;
var GMenu 								NextMenu;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Set the label on the menu
 * @param Text				Label data
 */
simulated function SetLabel(string Text)
{
	if (Text != "")
	{
		Label.Set(Text, "");
	}
	else
	{
		Label.Set(MenuName @"-" @MenuComment, "");
	}
}


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Exit the game
 */
delegate GoExit(Actor Caller)
{
	ConsoleCommand("quit");
}

/**
 * @brief Go to previous
 */
delegate GoPrevious(Actor Caller)
{
	if (PreviousMenu != None)
	{
		ChangeMenu(PreviousMenu);
	}
}

/**
 * @brief Go to next
 */
delegate GoNext(Actor Caller)
{
	if (NextMenu != None)
	{
		ChangeMenu(NextMenu);
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
	local PlayerController PC;
	local ViewTargetTransitionParams TransitionParams;
	PC = GetALocalPlayerController();
	`log("GM > ChangeMenu" @NewMenu @self);

	if (PC != None)
	{
		TransitionParams.BlendTime = 0.5;
		TransitionParams.BlendFunction = VTBlend_EaseInOut;
		TransitionParams.BlendExp = 2.0;
		TransitionParams.bLockOutgoing = false;
		PC.SetViewTarget(NewMenu.ViewPoint, TransitionParams);
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
 * @brief Add a button on the menu
 * @param Pos				Offset from menu origin
 * @param Text				Button name
 * @param Comment			Button help
 * @param CB				Method to call on button press
 * @return added item
 */
simulated function GButton AddButton(vector Pos, string Text, string Comment, delegate<GButton.PressCB> CB)
{
	local GButton Temp;
	Temp = Spawn(ButtonClass, self, , Location + (Pos >> Rotation));
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
 * @return added item
 */
simulated function GLabel AddLabel(vector Pos, string Text)
{
	local GLabel Temp;
	Temp = Spawn(LabelClass, self, , Location + (Pos >> Rotation));
	Temp.Set(Text, "");
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
	PreviousMenu = GetRelatedMenu(true);
	NextMenu = GetRelatedMenu(false);
	
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
	
	// Menu switching buttons
	if (PreviousMenu != None)
	{
		AddButton(Vect(-220,0,0), PreviousMenu.MenuName, PreviousMenu.MenuComment, GoPrevious);
	}
	if (NextMenu != None)
	{
		AddButton(Vect(220,0,0), NextMenu.MenuName, NextMenu.MenuComment, GoNext);
	}
	AddButton(Vect(400,0,0), "Quit", "Quit the game", GoExit);
	
	// Helper label
	Label = Spawn(LabelClass, self, , Location);
	Label.SetRotation(Rotation);
	Label.Set(MenuName @"-" @MenuComment, "");
	Items.AddItem(Label);
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
	Index=10
	MenuName="Menu"
	MenuComment="Change menu"
	
	// Behaviour
	bEdShouldSnap=true
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
}
