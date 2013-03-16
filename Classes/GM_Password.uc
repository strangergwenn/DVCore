/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Password extends GMenu;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const string					BackComment;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var string								URL;

var GButton								Connect;

var GTextField							Password;


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Connect button
 * @param Reference				Caller actor
 */
delegate GoConnect(Actor Caller)
{
	ConsoleCommand("open " $URL $"?game=?password=" $Password.GetText());
	Connect.Deactivate();
}

/**
 * @brief Called on enter key
 */
simulated function Enter()
{
	GoConnect(None);
}


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Set the target
 */
simulated function SetURL(string NewUrl)
{
	URL = NewUrl;
	Connect.Activate();
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function SpawnUI()
{
	Label.Destroy();
	AddButton(Vect(-320,0,0), lPBack, lPBack, GoBack);
	Connect = AddButton(Vect(320,0,0), lPConnectButton, lPConnect, GoConnect);
	AddLabel(Vect(-100,0,250), lPPassword);
	Password = AddTextField(Vect(105,0,250));
	Password.SetPassword(true);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Index=4500
}
