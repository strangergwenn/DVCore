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

var (DVPC) string	DebugString0;
var (DVPC) string	DebugString1;
var (DVPC) string	DebugString2;

var (DVPC) array<class<DVWeapon> > 		WeaponList;

var repnotify class<DVWeapon> 			UserChoiceWeapon;
var DVTeamInfo							EnnemyTeamInfo;

var bool				bPrintScores;
var int 				KillCount;
var int					DeathCount;
var float 				ScoreLength;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if ( bNetDirty )
		UserChoiceWeapon, EnnemyTeamInfo, KillCount, DeathCount;
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/


/*--- Controller started ---*/
simulated event PostBeginPlay()
{	
	super.PostBeginPlay();
	UpdatePawnColor();
	
	WeaponList = DVGame(WorldInfo.Game).DefaultWeaponList;
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


/*--- Register a kill ---*/
simulated function ScorePoint (bool bTeamKill)
{
	if (PlayerReplicationInfo != None)
	{
		DVTeamInfo(PlayerReplicationInfo.Team).AddKill(bTeamKill);
	}
	if (bTeamKill)
		KillCount -= 1;
	else
		KillCount += 1;
}


/*--- Register a death ---*/
simulated function ScoreDeath()
{
	DeathCount += 1;
}


/*--- Scores ---*/
exec function ShowCommandMenu()
{
	bPrintScores = true;
	SetTimer(ScoreLength, false, 'HideScores');
}
reliable client simulated function HideScores()
{
	bPrintScores = false;
}


/*--- Pawn possession : is spawned and OK ---*/
event Possess(Pawn aPawn, bool bVehicleTransition)
{
	super.Possess(aPawn, bVehicleTransition);
	UpdatePawnColor();
}

simulated function UpdatePawnColor()
{
	`log("UpdatePawnColor");
	if (PlayerReplicationInfo != None)
		DVPawn(Pawn).UpdateTeamColor(DVPlayerRepInfo(PlayerReplicationInfo).Team.TeamIndex);
}


/*--- Beam toggle ---*/
exec function Use()
{
	if (Pawn != None)
	{
		if (DVWeapon(Pawn.Weapon) != None)
		{
			DVWeapon(Pawn.Weapon).ToggleBeam();
		}
	}
}


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


/*--- Call this to respawn the player ---*/
reliable client simulated function HUDRespawn(byte NewWeapon)
{
	`log("HUDRespawn choice : " $ WeaponList[NewWeapon]);
	
	ServerSetUserChoice(WeaponList[NewWeapon], true);
	SetUserChoice(WeaponList[NewWeapon], true);
	ServerReStartPlayer();
}

exec simulated function ChangeWeaponClass(class<DVWeapon> NewWeapon)
{
	`log("SwitchToWeaponClass choice : " $ NewWeapon);
	SetUserChoice(NewWeapon, false);
	ServerSetUserChoice(NewWeapon, false);
}

/* Client weapon switch */
reliable client simulated function SetUserChoice(class<DVWeapon> NewWeapon, bool bShouldKill)
{
	`log("SetUserChoice choice : " $ NewWeapon);
	
	// Survivors will be shot again
	if (bShouldKill && Pawn != None)
	{
		`log("ServerSetUserChoice killed " $ Pawn);
		if (Pawn.Health > 0)
		{
			Pawn.KilledBy(Pawn);
		}
		Pawn.SetHidden(True);
	}
	UserChoiceWeapon = NewWeapon;
}

/* Server weapon switch */
reliable server simulated function ServerSetUserChoice(class<DVWeapon> NewWeapon, bool bShouldKill)
{
	if (bShouldKill && Pawn != None)
		Pawn.Destroy();
	
	`log("ServerSetUserChoice choice : " $ NewWeapon);
	UserChoiceWeapon = NewWeapon;
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
	DeathCount=0
	KillCount=0
	
	ScoreLength=3.0
	bPrintScores=false
	
	DebugString0=""
	DebugString1="Unconnected"
	DebugString2="Unconnected"
}
