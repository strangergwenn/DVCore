/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Login extends GMenu
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics, Attachment);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const string					BackText;
var (Menu) const string					BackComment;
var (Menu) const string					ConnectText;
var (Menu) const string					ConnectComment;

var (Menu) const string					UsernameText;
var (Menu) const string					PasswordText;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GButton								Connect;
var GTextField							Username;
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
}

/**
 * @brief Called on enter key
 */
simulated function Enter()
{
	GoConnect(None);
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
	AddButton(Vect(-300,0,0), BackText, BackComment, GoBack);
	Connect = AddButton(Vect(300,0,0), ConnectText, BackComment, GoConnect);
	
	AddLabel(Vect(0,0,250), MenuComment, class'GLabel');
	AddLabel(Vect(-100,0,200), UsernameText);
	AddLabel(Vect(-100,0,150), PasswordText);
	
	Username = AddTextField(Vect(105,0,200));
	Password = AddTextField(Vect(105,0,150));
	Password.SetPassword(true);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Index=3000
	LabelClass=class'GL_Clean'
	MenuName="Login"
	MenuComment="Account management"
	
	BackText="Back"
	BackComment="Previous menu"
	ConnectText="Connect"
	ConnectComment="Connect"
	UsernameText="Username"
	PasswordText="Password"
}
