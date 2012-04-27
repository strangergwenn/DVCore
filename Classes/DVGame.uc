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

var class<DVWeapon>						DefaultWeapon;
var (DVPC) array<class<DVWeapon> > 		DefaultWeaponList;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Spawning weapon management ---*/
function AddDefaultInventory(Pawn PlayerPawn)
{
	local class<DVWeapon> Choiced;
	
	if (PlayerPawn.Controller != None)
	{
		Choiced = DVPlayerController(PlayerPawn.Controller).UserChoiceWeapon;
		if (Choiced != None)
		{
			`log("Choice : " $ Choiced);
			PlayerPawn.CreateInventory(Choiced);
		}
	}
	else
	{
		`log("VERY WRONG - BAD WEAPON SPAWNED");
		PlayerPawn.CreateInventory(DefaultWeapon);
	}
	PlayerPawn.AddDefaultInventory();
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	HUDType=class'DVHUD'
	DefaultPawnClass=class'DVPawn'
	PlayerControllerClass=class'DVPlayerController'
}
