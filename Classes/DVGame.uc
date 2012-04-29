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

var int 							MaxScore;
var float							RestartTimer;


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

event PostBeginPlay()
{
	super.PostBeginPlay();
	SetTimer(1.5, true, 'ScoreUpdated');
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


/*--- Game end ---*/
function GameEnded(byte WinnerIndex)
{
	local DVPlayerController PC;
	local bool bIsWinner;
	
	ForEach AllActors(class'DVPlayerController', PC)
	{
		bIsWinner = CheckForWin(PC, WinnerIndex);
		PC.SignalEndGame(bIsWinner);
	}
	
	ClearTimer('ScoreUpdated');
	SetTimer(RestartTimer, false, 'RestartGame');
}


/*--- Is this controller the winner ? ---*/
simulated function bool CheckForWin(DVPlayerController PC, byte WinnerIndex)
{
	return true;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	MaxScore=30
	RestartTimer=10.0
	
	HUDType=class'DVHUD'
	DefaultPawnClass=class'DVPawn'
	PlayerControllerClass=class'DVPlayerController'
}
