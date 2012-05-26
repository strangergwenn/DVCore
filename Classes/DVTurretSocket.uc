/**
 *  This work is distributed under the General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVTurretSocket extends UDKTeamPlayerStart
	placeable
	ClassGroup(DeepVoid);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVTS) const class<DVTurretController>	TurretControllerClass;


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	TurretControllerClass=class'DVTurretController'
}
