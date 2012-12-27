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


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	//AddButton(Vect(0,0,50), "Quit", "Quit", GoExit);
}

/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
}
