/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Login extends GMenu;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) int							StoredLevel;

var (Menu) const float					BackDelay;

var (Menu) const string					BackComment;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var bool								bLoggingIn;
var bool								bRegistering;

var GLabel								Label2;
var GLabel								Password2Label;
var GLabel								EmailLabel;

var GButton								Connect;
var GButton								NewPlayer;

var GTextField							Username;
var GTextField							Password;
var GTextField							Password2;
var GTextField							Email;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Display the server connection state
 * @param Level					Connect state : 0 - KO, 1 - WIP, 2 - OK
 */
function SetConnectState(optional int Level)
{
	local string Message;
	
	switch (Level)
	{
		case (0):
			Message = lPConnect;
			Connect.Activate();
			NewPlayer.Activate();
			break; 
		case (1):
			Message = lConnecting;
			Connect.Deactivate();
			NewPlayer.Deactivate();
			break; 
		case (2):
			Message = lConnected;
			Connect.Deactivate();
			NewPlayer.Deactivate();
			Username.Deactivate();
			Password.Deactivate();
			Password2.Deactivate();
			Email.Deactivate();
			break; 
	}
	StoredLevel = Level;
	Connect.Set(Message, lConnect);
}

/**
 * @brief Display a response code from server
 * @param bSuccess				Wether it was successful
 * @param Msg					Message sent if any
 * @param Command				Command sent by client (unreliable)
 */
 function DisplayResponse (bool bSuccess, string Msg, string Command)
{
	// Show it's OK
	if (Command == "CONNECT" || Command == "NET")
	{
		SetConnectState(bSuccess? 2:0);
	}
	Label2.Set(Msg, "");
	
	// Login if just registered
	if (bRegistering)
	{
		DVPlayerController(PC).SaveIDs(Username.GetText(), Password.GetText());
		DVPlayerController(PC).Connect(Username.GetText(), Password.GetText());
		Label2.Set(lConnecting, "");
		bRegistering = false;
		SetConnectState(1);
		
		Password2.Destroy();
		Email.Destroy();
		Password2Label.Destroy();
		EmailLabel.Destroy();
	}
	else if (bSuccess && bLoggingIn)
	{
		SuccessQuit();
	}
}

/**
 * @brief Exit the menu after login
 */
simulated function SuccessQuit()
{
	GM_Main(Origin).LockLogin(Username.GetText());
	SetTimer(BackDelay, false, 'GoBack');
	bLoggingIn = false;
}


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Register button
 * @param Reference				Caller actor
 */
delegate GoRegister(Actor Caller)
{
	bRegistering = true;
	NewPlayer.Deactivate();
	Label2.Set(LPNewAccount, "");
	Connect.Set(LPRegister, LPNewAccount);
	
	Password2Label = AddLabel(Vect(-100,0,200), lPPassword);
	EmailLabel = AddLabel(Vect(-100,0,150), LPEmail);
	Password2 = AddTextField(Vect(105,0,200));
	Password2.SetPassword(true);
	Email = AddTextField(Vect(105,0,150));
}

/**
 * @brief Connect button
 * @param Reference				Caller actor
 */
delegate GoConnect(Actor Caller)
{
	// Get
	local string UserData;
	local string Password1Data;
	local string Password2Data;
	local string EmailData;
	UserData = Username.GetText();
	Password1Data = Password.GetText();
	Password2Data = Password2.GetText();
	EmailData = Email.GetText();
	
	// Check
	if (Len(UserData) < 4 || (bRegistering && Len(EmailData) < 10))
		Label2.Set(lIncorrectData, "");
	else if (bRegistering && Password1Data != Password2Data)
		Label2.Set(lWrongPassword, "");
	
	// Register
	else if (bRegistering)
	{
		DVPlayerController(PC).Register(UserData, EmailData, Password1Data);
		Label2.Set(lRegistering, "");
	}
	
	// Login
	else
	{
		bLoggingIn = true;
		DVPlayerController(PC).SaveIDs(UserData, Password1Data);
		DVPlayerController(PC).Connect(UserData, Password1Data);
		Label2.Set(lConnecting, "");
		SetConnectState(1);
	}
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
	AddButton(Vect(-320,0,0), lPBack, lPBack, GoBack);
	Connect = AddButton(Vect(320,0,0), lPConnectButton, lPConnect, GoConnect);
	NewPlayer = AddButton(Vect(0,0,0), lPNewPlayer, LPNewAccount, GoRegister);
	
	bRegistering = false;
	Label.Destroy();
	Label2 = AddLabel(Vect(-320,0,470), lGMenuComment, class'GLabel');
	
	AddLabel(Vect(-100,0,300), lPPlayer);
	AddLabel(Vect(-100,0,250), lPPassword);
	Username = AddTextField(Vect(105,0,300));
	Password = AddTextField(Vect(105,0,250));
	Password.SetPassword(true);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Index=3000
	BackDelay=1.0
}
