/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVPlayerController extends UDKPlayerController;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var (DVPC) bool						bUseBeam;

var (DVPC) array<class<DVWeapon> > 	WeaponList;

var class<DVWeapon> 				UserChoiceWeapon;
var DVTeamInfo						EnemyTeamInfo;

var bool							bPrintScores;
var float 							ScoreLength;
var float							CleanUpFrequency;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if ( bNetDirty )
		bUseBeam, UserChoiceWeapon, EnemyTeamInfo;
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/


/*--- Controller started ---*/
simulated event PostBeginPlay()
{	
	super.PostBeginPlay();
	UpdatePawnColor();
}


/*--- Pawn possession : is spawned and OK ---*/
event Possess(Pawn aPawn, bool bVehicleTransition)
{
	super.Possess(aPawn, bVehicleTransition);
	UpdatePawnColor();
}


/*----------------------------------------------------------
	Player actions
----------------------------------------------------------*/

/*--- Scores ---*/
exec function ShowCommandMenu()
{
	bPrintScores = true;
	SetTimer(ScoreLength, false, 'HideScores');
}


/*--- Beam toggle ---*/
exec function Use()
{
	if (Pawn != None && DVWeapon(Pawn.Weapon) != None)
	{
		SetBeamStatus(!bUseBeam);
	}
}


/*--- Switch weapon class ---*/
exec simulated function ChangeWeaponClass(class<DVWeapon> NewWeapon)
{
	`log("SwitchToWeaponClass choice : " $ NewWeapon);
	SetUserChoice(NewWeapon, false);
	ServerSetUserChoice(NewWeapon, false);
}


/*--- This is serious debug ---*/
exec simulated function EndThisRightNow()
{
	local int i;
	if (PlayerReplicationInfo != None)
	{
		for (i = 0; i < 42; i++)
			DVPlayerRepInfo(PlayerReplicationInfo).ScorePoint(false);
	}
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Camera management  ---*/
function UpdateRotation( float DeltaTime )
{
	local Rotator	DeltaRot, newRotation, ViewRotation;
	local bool bAmIZoomed;
	local float ZoomSensitivity;
	
	// Zoom management
	bAmIZoomed = false;
	ViewRotation = Rotation;
	if (Pawn != None)
	{
		Pawn.SetDesiredRotation(ViewRotation);
		if (DVPawn(Pawn).Weapon != None)
		{
			bAmIZoomed = DVWeapon(Pawn.Weapon).IsZoomed();
			ZoomSensitivity = DVWeapon(Pawn.Weapon).GetZoomFactor();
		}
	}

	// Calculate Delta
	DeltaRot.Yaw	= PlayerInput.aTurn * (bAmIZoomed ? ZoomSensitivity : 1.0);
	DeltaRot.Pitch	= PlayerInput.aLookUp * (bAmIZoomed ? ZoomSensitivity : 1.0);

	ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
	SetRotation(ViewRotation);
	NewRotation = ViewRotation;
	NewRotation.Roll = Rotation.Roll;

	if ( Pawn != None )
		Pawn.FaceRotation(NewRotation, deltatime);
}


/*--- Camera lock ---*/
simulated function ProcessViewRotation(float DeltaTime, out Rotator out_ViewRotation, rotator DeltaRot)
{
	if (Pawn != None && !DVPawn(Pawn).IsCameraLocked())
		super.ProcessViewRotation(DeltaTime, out_ViewRotation, DeltaRot );
}


/*--- End of game ---*/
simulated function SignalEndGame(bool bHasWon)
{
	bPrintScores = true;
	DVPawn(Pawn).LockCamera(true);
}


/*--- Ammo ---*/
simulated function float GetAmmoPercentage()
{
	local DVWeapon wp;
	wp = DVWeapon(Pawn.Weapon);
	
	if (wp != None)
		return 100.0 * wp.GetAmmoRatio();
	else
		return 0.0;	
}


/*--- Team index management ---*/
simulated function byte GetTeamIndex()
{
	if (PlayerReplicationInfo != None)
		return DVPlayerRepInfo(PlayerReplicationInfo).Team.TeamIndex;
	else
		return -1;
}


/*--- Player name management ---*/
simulated function string GetPlayerName()
{
	local string PlayerName;
	PlayerName = PlayerReplicationInfo != None ? PlayerReplicationInfo.PlayerName : "UNNAMED";
	return PlayerName;
}


/*--- Pawn death ---*/
function NotifyPawnDied()
{
	// Replication data
	`log("NotifyPawnDied for " $ self);
	if (PlayerReplicationInfo != None)
		DVPlayerRepInfo(PlayerReplicationInfo).ScoreDeath();
	else
		`log("NotifyPawnDied could not store repinfo " $ self);
}


/*----------------------------------------------------------
	Reliable client/server code
----------------------------------------------------------*/

/*--- Call this to respawn the player ---*/
reliable server simulated function HUDRespawn(byte NewWeapon)
{
	ServerSetUserChoice(WeaponList[NewWeapon], true);
	SetUserChoice(WeaponList[NewWeapon], true);
	ServerReStartPlayer();
}


/* Client weapon switch */
reliable client simulated function SetUserChoice(class<DVWeapon> NewWeapon, bool bShouldKill)
{
	`log("Player choosed " $ NewWeapon);
	
	// Survivors will be shot again
	if (bShouldKill && Pawn != None)
	{
		if (Pawn.Health > 0)
		{
			Pawn.KilledBy(Pawn);
		}
		Pawn.SetHidden(True);
	}
	UserChoiceWeapon = NewWeapon;
}


reliable client simulated function bool GetBeamStatus()
{
	return bUseBeam;
}


reliable server simulated function UpdatePawnColor()
{
	local byte i;
	i = GetTeamIndex();
	if (i != -1)
		DVPawn(Pawn).UpdateTeamColor(i);
}


reliable server simulated function SetEnemyTeamInfo(DVTeamInfo TI)
{
	EnemyTeamInfo = TI;
}


reliable server function SetWeaponList(array<class<DVWeapon> > NewList)
{
	WeaponList = NewList;
}


reliable server simulated function ServerSetUserChoice(class<DVWeapon> NewWeapon, bool bShouldKill)
{
	if (bShouldKill && Pawn != None)
		Pawn.Destroy();
	UserChoiceWeapon = NewWeapon;
}


reliable client simulated function HideScores()
{
	bPrintScores = false;
}


reliable server simulated function SetBeamStatus(bool NewStatus)
{
	bUseBeam = NewStatus;
}


/*----------------------------------------------------------
	States
----------------------------------------------------------*/

state Dead
{
	exec function StartFire(optional byte FireModeNum)
	{}
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	ScoreLength=3.0
	
	bUseBeam=true
	bPrintScores=false
}
