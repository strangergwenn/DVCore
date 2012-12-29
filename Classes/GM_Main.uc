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
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function SpawnUI()
{
	Local GListItem Temp;
	super.SpawnUI();
	Temp = GListItem(AddMenuLink(Vect(-150,0,100), GetMenuByID(2000), class'GLI_Large'));
	Temp.SetPicture(SoloPicture);
	Temp = GListItem(AddMenuLink(Vect(150,0,100), GetMenuByID(2100), class'GLI_Large'));
	Temp.SetPicture(MultiPicture);
	
	AddMenuLink(Vect(150,0,430), GetMenuByID(3000));
	AddButton(Vect(300,0,430), "Quit", "Quit the game", GoExit);
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
	SoloPicture=Texture2D'DV_UI.Textures.LEVEL_00'
	MultiPicture=Texture2D'DV_UI.Textures.LEVEL_02'
}