/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Main extends GMenu;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const Texture2D				SoloPicture;
var (Menu) const Texture2D				MultiPicture;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var GButton								Connect;


/*----------------------------------------------------------
	Private methods
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
 * @brief Back button
 * @param Reference				Caller actor
 */
delegate GoBack(Actor Caller)
{
}

/**
 * @brief Spawn event
 */
simulated function SpawnUI()
{
	Local GListItem Temp;
	super.SpawnUI();
	Temp = GListItem(AddMenuLink(Vect(-150,0,100), GetMenuByID(2000), class'GLIT_Large'));
	Temp.SetPicture(SoloPicture);
	Temp = GListItem(AddMenuLink(Vect(150,0,100), GetMenuByID(2100), class'GLIT_Large'));
	Temp.SetPicture(MultiPicture);
	
	Connect = AddMenuLink(Vect(0,0,470), GetMenuByID(9999));
	AddButton(Vect(420,0,50), "Quit", "Quit the game", GoExit);
}


/**
 * @brief Lock the login button
 * @param Username				username to display
 */
simulated function LockLogin(string Username)
{
	Connect.Set(Username, "");
	Connect.Deactivate();
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Menu data
	Index=0
	SoloPicture=Texture2D'DV_UI.Textures.LEVEL_00'
	MultiPicture=Texture2D'DV_UI.Textures.LEVEL_02'
}
