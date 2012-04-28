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
var (DVPC) string					DebugString0;
var (DVPC) string					DebugString1;
var (DVPC) string					DebugString2;

var (DVPC) array<class<DVWeapon> > 	WeaponList;

var class<DVWeapon> 				UserChoiceWeapon;
var DVTeamInfo						EnemyTeamInfo;

var bool							bPrintScores;
var float 							ScoreLength;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if ( bNetDirty )
		bUseBeam, UserChoiceWeapon, EnemyTeamInfo;
}

simulated event ReplicatedEvent(name VarName)
{
	`log ("REPLICATION EVENT FOR " $ self $ " OF " $ VarName);
	Super.ReplicatedEvent(VarName);
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


/*--- Debug ---*/
event PlayerTick( float DeltaTime )
{
	if (PlayerReplicationInfo != None)
	{
		if (PlayerReplicationInfo.Team != None)
			SetDebug0("PC is "$ self $" team is " $ DVPlayerRepInfo(PlayerReplicationInfo).Team.TeamIndex);
	}
	super.PlayerTick(DeltaTime);
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
	`log("NotifyPawnDied for " $ self);
	if (PlayerReplicationInfo != None)
		DVPlayerRepInfo(PlayerReplicationInfo).ScoreDeath();
	else
		`log("NotifyPawnDied could not store repinfo " $ self);
}


/*--- Debug ---*/
simulated function SetDebug0 (string str)
{
	DebugString0 = str;
}

simulated function SetDebug1 (string str)
{
	DebugString1 = str;
}

simulated function SetDebug2 (string str)
{
	DebugString2 = str;
}


/*----------------------------------------------------------
	Reliable client/server code
----------------------------------------------------------*/

/*--- Call this to respawn the player ---*/
reliable server simulated function HUDRespawn(byte NewWeapon)
{
	`log("HUDRespawn choice : " $ WeaponList[NewWeapon]);
	ServerSetUserChoice(WeaponList[NewWeapon], true);
	SetUserChoice(WeaponList[NewWeapon], true);
	ServerReStartPlayer();
}


/* Client weapon switch */
reliable client simulated function SetUserChoice(class<DVWeapon> NewWeapon, bool bShouldKill)
{
	`log("SetUserChoice choice : " $ NewWeapon);
	
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
	`log("UpdatePawnColor");
	if (PlayerReplicationInfo != None)
		DVPawn(Pawn).UpdateTeamColor(DVPlayerRepInfo(PlayerReplicationInfo).Team.TeamIndex);
}


reliable server simulated function SetEnemyTeamInfo(DVTeamInfo TI)
{
	`log("SetEnemyTeamInfo " $ TI);
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
	
	`log("ServerSetUserChoice choice : " $ NewWeapon);
	UserChoiceWeapon = NewWeapon;
}


reliable client simulated function HideScores()
{
	bPrintScores = false;
}


reliable server simulated function SetBeamStatus(bool NewStatus)
{
	`log("SetBeamStatus " $ NewStatus);
	bUseBeam = NewStatus;
}

/*----------------------------------------------------------
	States
----------------------------------------------------------*/

state Dead
{
	exec function StartFire( optional byte FireModeNum )
	{}
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	ScoreLength=3.0
	bPrintScores=false
	
	bUseBeam=true
	
	DebugString0=""
	DebugString1="Unconnected"
	DebugString2="Unconnected"
}
