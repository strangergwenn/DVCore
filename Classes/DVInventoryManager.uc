/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVInventoryManager extends InventoryManager;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Override ---*/
simulated function SwitchToBestWeapon( optional bool bForceADifferentWeapon )
{
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultProperties
{
	PendingFire(0)=0
	PendingFire(1)=0
}
