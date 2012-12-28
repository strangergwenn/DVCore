/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GListMenu extends GMenu
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics, Attachment);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const vector					ListOffset;
var (Menu) const vector					ScrollOffset;

var (Menu) const array<string>			IgnoreList;

var (Menu) const class<GListItem>		ListItemClass;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

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
 * @brief Called on scroll
 * @param bIsGoingUp			Is the player going up ?
 */
simulated function Scroll(bool bIsGoingUp)
{
	local Actor Temp;
	foreach AllActors(ListItemClass, Temp)
	{
		Temp.SetCollisionType(COLLIDE_NoCollision);
	}
	foreach AllActors(ListItemClass, Temp)
	{
		Temp.MoveSmooth((bIsGoingUp? -ScrollOffset : ScrollOffset) >> Rotation);
	}
	foreach AllActors(ListItemClass, Temp)
	{
		Temp.SetCollisionType(COLLIDE_BlockAll);
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
	AddButton(Vect(-300,0,0), "Back", "Go to the previous menu", GoBack);
	Launch = AddButton(Vect(300,0,0), "Launch", "Launch the game", GoLaunch);
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


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	MenuName="List menu"
	MenuComment="List some items"
	ListItemClass=class'GListItem'
	ListOffset=(X=0,Y=-100,Z=100)
	ScrollOffset=(X=0,Y=0,Z=50)
}
