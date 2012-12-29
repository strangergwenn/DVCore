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
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function SpawnUI()
{
	super.SpawnUI();
	AddMenuLink(Vect(0,0,100), GetMenuByID(2000));
	AddMenuLink(Vect(0,0,250), GetMenuByID(3000));
	AddButton(Vect(400,0,0), "Quit", "Quit the game", GoExit);
}
