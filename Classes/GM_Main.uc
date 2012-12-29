/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Main extends GMenu;


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


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Menu data
	Index=0
	MenuName="Home"
	MenuComment="Main menu"
}