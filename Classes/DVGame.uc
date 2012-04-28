/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVGame extends UDKGame;

/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var class<DVWeapon>					DefaultWeapon;
var array<class<DVWeapon> > 		DefaultWeaponList;

replication
{
	if ( bNetDirty )
		DefaultWeapon;
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Spawning weapon management ---*/
function AddDefaultInventory(Pawn PlayerPawn)
{
	local class<DVWeapon> Choiced;
	
	`log("AddDefaultInventory for " $ PlayerPawn);
	if (PlayerPawn.Controller != None)
	{
		Choiced = DVPlayerController(PlayerPawn.Controller).UserChoiceWeapon;
		if (Choiced != None)
		{
			PlayerPawn.CreateInventory(Choiced);
		}
	}
	else
	{
		`log("Spawned default weapon, this is wrong.");
		PlayerPawn.CreateInventory(DefaultWeapon);
	}
	PlayerPawn.AddDefaultInventory();
}


/*--- Stub ---*/
function ScoreUpdated(){}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	HUDType=class'DVHUD'
	DefaultPawnClass=class'DVPawn'
	PlayerControllerClass=class'DVPlayerController'
}
