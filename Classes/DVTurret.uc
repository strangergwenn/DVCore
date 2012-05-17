/**
 *  This work is distributed under the General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVTurret extends Pawn
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVTurret) const  ParticleSystem		MuzzleFlashEmitter;
var (DVTurret) const SoundCue 				FireSound;
var (DVTurret) const class<Projectile> 		ProjClass;
var (DVTurret) const int 					RoundsPerSec;

var (DVTurret) const byte 					TeamIndex;

var (DVTurret) const name 					GunControllerName;
var (DVTurret) const name 					MainControllerName;
var (DVTurret) const name 					FireSocket;

var (DVTurret) const string					KillString;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var DynamicLightEnvironmentComponent 		LightEnvironment;

var SkelControlSingleBone 					GunController;
var SkelControlSingleBone 					MainController;

var Pawn 									EnemyTarget;
var Pawn 									LastEnemyTarget;

var rotator 								FireRotation;
var vector 									FireLocation;
var vector 									LastEnemyDir;
var vector 									EnemyDir;

var int 									MinTurretRotRate;
var int 									MaxTurretRotRate;
var float 									GElapsedTime;
var float 									ElapsedTime;
var float 									FullRevTime;

var float 									YawRotationAlpha;
var float 									YawInterpTime;
var int 									StartYaw;
var int 									TargetYaw;

var float 									PitchRotationAlpha;
var float 									PitchInterpTime;
var int 									StartPitch;
var int 									TargetPitch;



/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Game start ---*/
event PostBeginPlay()
{
	Super.PostBeginPlay();

	GunController=SkelControlSingleBone(Mesh.FindSkelControl(GunControllerName));
	MainController=SkelControlSingleBone(Mesh.FindSkelControl(MainControllerName));
	Mesh.GetSocketWorldLocationAndRotation(FireSocket,FireLocation,FireRotation);
}


/*--- Firing management ---*/
function TimedFire()
{
	local Projectile Proj;

	Proj = Spawn(ProjClass,self,,FireLocation,FireRotation,,True);
	if(Proj != None && !Proj.bDeleteMe )
	{
		Proj.Init(Vector(FireRotation));
		if(MuzzleFlashEmitter != None)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(
				MuzzleFlashEmitter,
				FireLocation,
				FireRotation);
		}
		if(FireSound != None)
			PlaySound(FireSound);
	}
}


/*----------------------------------------------------------
	Targeting
----------------------------------------------------------*/

/*--- Find the ennemy ---*/
simulated function bool GetNearestEnnemy ()
{
	// Vars
	local int 			index, bestIndex, distance, bestDistance;
	local Pawn 			targetPawn, tempPawn;
	local array<Pawn>	ResultPawns;

	// All valid pawns
	foreach WorldInfo.AllPawns(class'Pawn', targetPawn)
	{
		if(IsValidTarget(targetPawn))
		{
			ResultPawns.AddItem(DVPawn(targetPawn));
		}
	}
	if (ResultPawns.Length == 0)
		return false;

	// Nearest pawn
	bestIndex = 0;
	bestDistance = 100000;
	for (index = 0; index < ResultPawns.Length; index++)
	{
		tempPawn = ResultPawns[index];
		distance = VSize(tempPawn.Location - Location);
		if (distance < bestDistance)
		{
			bestDistance = distance;
			bestIndex = index;
		}
	}
	`log("Acquired ennemy "@targetPawn@self);
	EnemyTarget = ResultPawns[bestIndex];
	return true;
}


/*--- Friendly fire avoidance, not shooting dead things either ---*/
simulated function bool IsValidTarget(Pawn P)
{
	if (P != None && FastTrace(P.Location, FireLocation))
	{
		return (P.isA('DVPawn') && P.Health > 0 && TeamIndex != DVPawn(P).GetTeamIndex());
	}
	else
		return false;
}


/*----------------------------------------------------------
	Movement management
----------------------------------------------------------*/

/*--- Launch rotation ---*/
function DoRotation(Rotator NewRotation, Float InterpTime)
{
	StartYaw = MainController.BoneRotation.Yaw;
	TargetYaw = NewRotation.Yaw;
	YawRotationAlpha = 0.0;
	YawInterpTime = InterpTime;

	StartPitch = GunController.BoneRotation.Pitch;
	TargetPitch = NewRotation.Pitch;
	PitchRotationAlpha = 0.0;
	PitchInterpTime = InterpTime;

	SetTimer(0.033,true,'RotateYawTimer');
	SetTimer(0.033,true,'RotatePitchTimer');
}


/*--- Yaw rotation ---*/
function RotateYawTimer()
{
	YawRotationAlpha += 0.033;
	if(YawRotationAlpha <= YawInterpTime)
	{
   		MainController.BoneRotation.Yaw = Lerp(StartYaw, TargetYaw, YawRotationAlpha);
	}
   	else ClearTimer('RotateYawTimer');
}


/*--- Pitch rotation ---*/
function RotatePitchTimer()
{
	PitchRotationAlpha += 0.033;
	if(PitchRotationAlpha <= PitchInterpTime)
	{
   		GunController.BoneRotation.Pitch = Lerp(StartPitch, TargetPitch, PitchRotationAlpha);
	}
   	else ClearTimer('RotatePitchTimer');
}


/*--- Movement ---*/
function Tick(Float Delta)
{
	local bool 			bHasAcquiredTarget;
	local bool			result;

	if (Health <= 0) return;

	if(GElapsedTime > 1.0)
	{
		// Target search
		GElapsedTime = 0.0;
		bHasAcquiredTarget = GetNearestEnnemy();

		// Firing management
		Mesh.GetSocketWorldLocationAndRotation(FireSocket,FireLocation,FireRotation);
		if (bHasAcquiredTarget)
		{
			DoRotation(Rotator((EnemyTarget.Location - FireLocation + vect(0,0,100)) << Rotation), 1.0);
			SetTimer(1.0/RoundsPerSec,true,'TimedFire');
		}
	}
	else GElapsedTime += Delta;

	// Targetting confirmation and timing calculation
	if (EnemyTarget != None && IsValidTarget(EnemyTarget))
		result = CalculateInterpTime(EnemyTarget.Location);
	else
	{
		ClearTimer('TimedFire');
		return;
	}

	if (EnemyTarget != LastEnemyTarget || result)
		ElapsedTime = Delta;
	else
		ElapsedTime += Delta;

	// Moving to position
	if(PitchInterpTime == 0)	PitchRotationAlpha = 1.0;
	else						PitchRotationAlpha = FClamp(ElapsedTime / PitchInterpTime,0.0,1.0);
	GunController.BoneRotation.Pitch = Lerp(StartPitch, TargetPitch, PitchRotationAlpha);

	if(YawInterpTime == 0)		YawRotationAlpha = 1.0;
	else						YawRotationAlpha = FClamp(ElapsedTime / YawInterpTime,0.0,1.0);
	MainController.BoneRotation.Yaw = Lerp(StartYaw, TargetYaw, YawRotationAlpha);

	Mesh.GetSocketWorldLocationAndRotation(FireSocket, FireLocation, FireRotation);
}


/*--- Interpolation settings ---*/
simulated function bool CalculateInterpTime(Vector TargetLocation)
{
	EnemyDir = TargetLocation - Location;
	if(EnemyDir != LastEnemyDir || ElapsedTime >= YawInterpTime || ElapsedTime >= PitchInterpTime)
	{
		LastEnemyDir = EnemyDir;
		LastEnemyTarget = EnemyTarget;

		StartYaw = MainController.BoneRotation.Yaw;
		TargetYaw = Rotator((TargetLocation - FireLocation) << Rotation).Yaw;
		YawInterpTime = Abs(TargetYaw - StartYaw) / Float(MaxTurretRotRate);

		StartPitch = GunController.BoneRotation.Pitch;
		TargetPitch = Rotator((TargetLocation - FireLocation) << Rotation).Pitch;
		PitchInterpTime = Abs(TargetPitch - StartPitch) / Float(MaxTurretRotRate);

		return true;
	}
	else
		return false;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Light
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
	End Object
	LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)
	
	// Mesh settings
	Begin Object class=SkeletalMeshComponent name=TurretMesh
		LightEnvironment=MyLightEnvironment
		BlockActors=true
		BlockZeroExtent=true
		BlockRigidBody=true
		BlockNonzeroExtent=true
		CollideActors=true
		bUseSingleBodyPhysics=1
		bNotifyRigidBodyCollision=true
		bUseAsOccluder=true
	End Object
	Components.Add(TurretMesh)
	CollisionComponent=TurretMesh
	Mesh=TurretMesh
	FireSocket=FireLocation
	GunControllerName=GunController
	MainControllerName=MainController
	
	// Settings
	Health=65000
	Physics=PHYS_RigidBody
	bEdShouldSnap=true
	bStatic=false
	bCollideActors=true
	bCollideWorld=true
	bProjTarget=true
	bBlockActors=true
	bPathColliding=true
}
