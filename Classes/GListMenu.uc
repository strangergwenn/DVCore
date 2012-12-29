/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GListMenu extends GMenu;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const int					ListMinSize;

var (Menu) const vector					ListOffset;
var (Menu) const vector					ScrollOffset;

var (Menu) const string					BackText;
var (Menu) const string					BackComment;
var (Menu) const string					LaunchText;
var (Menu) const string					LaunchComment;
var (Menu) const array<string>			IgnoreList;

var (Menu) const class<GListItem>		ListItemClass;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var int									ListCount;
var int									ScrollCount;

var string								CurrentData;

var GButton								Launch;


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Launch button
 * @param Reference				Caller actor
 */
delegate GoLaunch(Actor Caller)
{
}

/**
 * @brief Selection callback
 * @param Reference				Caller actor
 */
delegate GoSelect(Actor Caller)
{
	local Actor Temp;
	CurrentData = GListItem(Caller).Data;
	
	foreach AllActors(ListItemClass, Temp)
	{
		if (Temp != Caller && GToggleButton(Temp).GetState())
		{
			GToggleButton(Temp).SetState(false);
		}
	}
	
	if (GToggleButton(Caller).GetState())
	{
		Launch.Activate();
	}
	else
	{
		Launch.Deactivate();
		CurrentData = "";
	}
}

/**
 * @brief Change collision status
 * @param bState				New collision state
 */
simulated function SetListItemsCollision(bool bState)
{
	local Actor Temp;
	foreach AllActors(ListItemClass, Temp)
	{
		Temp.SetCollisionType((bState? COLLIDE_BlockAll : COLLIDE_NoCollision));
	}
}

/**
 * @brief Called on scroll
 * @param bIsGoingUp			Is the player going up ?
 */
simulated function Scroll(bool bIsGoingUp)
{
	local Actor Temp;
	if (( bIsGoingUp && (ScrollCount < ListCount - ListMinSize))
	 || (!bIsGoingUp && (ScrollCount > ListMinSize - ListCount)))
	{
		SetListItemsCollision(false);
		foreach AllActors(ListItemClass, Temp)
		{
			Temp.MoveSmooth((bIsGoingUp? -ScrollOffset : ScrollOffset) >> Rotation);
		}
		SetListItemsCollision(true);
		ScrollCount += (bIsGoingUp ? 1 : -1);
	}
}

/**
 * @brief Called on enter key
 */
simulated function Enter()
{
	GoLaunch(None);
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief UI setup
 */
simulated function SpawnUI()
{
	AddButton(Vect(-300,0,0), BackText, BackComment, GoBack);
	Launch = AddButton(Vect(300,0,0), LaunchText, BackComment, GoLaunch);
	Launch.Deactivate();
	UpdateList();
}

/**
 * @brief Tick event (thread)
 * @param DeltaTime			Time since last tick
 */
simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	if (CurrentData == "")
	{
		Launch.Deactivate();
	}
}

/**
 * @brief Create a data list
 */
function UpdateList()
{
}

/**
 * @brief Create a data list
 */
function EmptyList()
{
	local Actor Temp;
	foreach AllActors(ListItemClass, Temp)
	{
		Temp.Destroy();
	}
	ListCount = 0;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	ListCount=0
	ScrollCount=0
	ListMinSize=6
	
	MenuName="List menu"
	MenuComment="List some items"
	BackText="Back"
	BackComment="Previous menu"
	LaunchText="Launch"
	LaunchComment=""

	ListItemClass=class'GListItem'
	ListOffset=(X=0,Y=-50,Z=100)
	ScrollOffset=(X=0,Y=0,Z=50)
}
