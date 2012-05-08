/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVHUD_Menu extends UDKHUD;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var const class<DVCoreUI_Menu>		HUDClass;
var DVCoreUI_Menu   				HudMovie;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Spawn ---*/ 
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	HudMovie = new HUDClass;
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);
	HudMovie.Start();
	HudMovie.Advance(0);
	HudMovie.PC = DVPlayerController(PlayerOwner);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	HUDClass=class'DVCoreUI_Menu'
}
