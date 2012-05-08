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
var float							EndGameTick;
var float							RestartTimer;


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

event PostBeginPlay()
{
	super.PostBeginPlay();
	SetTimer(EndGameTick, true, 'ScoreUpdated');
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


/*--- Killed set ---*/
function ScoreKill(Controller Killer, Controller Other)
{
	local DVPlayerRepInfo KillerPRI;
	local bool bIsTeamKill;
	
	// Init
	`log(Killer $ " ScoreKill " $ Other);
	KillerPRI = DVPlayerRepInfo(Killer.PlayerReplicationInfo);
	
	// Score kill
	`log(self $ " KilledBy " $ KillerPRI);
	if (KillerPRI != None)
	{
		if (KillerPRI.Team != None && DVPlayerController(Other) != None)
		{
			bIsTeamKill = (	(Killer == Other)
						 || (DVPlayerController(Killer).GetTeamIndex() == DVPlayerController(Other).GetTeamIndex()));
		}
		else
			bIsTeamKill = (Killer == Other);
		
		`log(Other $ " KilledBy " $ KillerPRI $ ", isTK=" $ bIsTeamKill);
		KillerPRI.ScorePoint(bIsTeamKill);
	}
	
	// Death
	if (DVPlayerController(Other).PlayerReplicationInfo != None)
		DVPlayerRepInfo(DVPlayerController(Other).PlayerReplicationInfo).ScoreDeath();
	else
		`log("ScoreKill could not store repinfo " $ self);
}


/*--- Player start determination ---*/
function PlayerStart ChoosePlayerStart(Controller Player, optional byte InTeam)
{
	local array<playerstart> PlayerStarts;
	local PlayerStart 		P, BestStart;
	local float 			BestRating, NewRating;
	local int 				i, RandStart;

	// All player starts
	foreach WorldInfo.AllNavigationPoints(class'PlayerStart', P)
	{
		if ( P.bEnabled )
			PlayerStarts[PlayerStarts.Length] = P;
	}
	RandStart = Rand(PlayerStarts.Length);

	// Random points : end part
	for (i = RandStart; i < PlayerStarts.Length; i++)
	{
		P = PlayerStarts[i];
		NewRating = RatePlayerStart(P, InTeam, Player);
		
		if ( NewRating >= 30 )
			return P;
		if ( NewRating > BestRating )
		{
			BestRating = NewRating;
			BestStart = P;
		}
	}
	
	// Random points : start part
	for ( i = 0; i < RandStart; i++)
	{
		P = PlayerStarts[i];
		NewRating = RatePlayerStart(P, InTeam, Player);
		
		if ( NewRating >= 30 )
			return P;
		if ( NewRating > BestRating )
		{
			BestRating = NewRating;
			BestStart = P;
		}
	}
	return BestStart;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	MaxScore=30
	EndGameTick=0.5
	RestartTimer=10.0
	
	HUDType=class'DVHUD'
	DefaultPawnClass=class'DVPawn'
	PlayerControllerClass=class'DVPlayerController'
}
