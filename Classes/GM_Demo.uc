/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Demo extends GMenu
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics, Attachment);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Method definition for press event callbacks
 * @param Reference				Caller actor
 */
delegate GoVoid(Actor Caller)
{
	`log(Caller @"was clicked");
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
	
	AddMenuLink(Vect(0,0,100), GetMenuByID(2000));
	
	Spawn(class'GTextField', self, , Location + (Vect(0,0,300) >> Rotation));
}

/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
}
