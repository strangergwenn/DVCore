/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVGame_Menu extends GameInfo;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Login ---*/
event PostLogin (PlayerController NewPlayer)
{
	local DVPlayerController NP;
	
	super.PostLogin(NewPlayer);
	NP = DVPlayerController(NewPlayer);
	
	NP.MasterServerLink = Spawn(class'DVLink');
	NP.MasterServerLink.InitLink(NP);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	HUDType=class'GH_Menu'
	PlayerControllerClass=class'DVPlayerController'
}
