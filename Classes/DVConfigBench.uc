/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVConfigBench extends Actor
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Bench) const name			EyeSocket;

var (Bench) const float 		DetectionDistance;
var (Bench) const float 		DetectionPeriod;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var SkeletalMeshComponent		Mesh;

var float 						CurrentPeriod;

var bool 						bConfigLaunched;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Detection tick ---*/
simulated function Tick(float DeltaTime)
{
	local DVPawn P;
	CurrentPeriod -= DeltaTime;
	
	if (CurrentPeriod <= 0)
	{
		CurrentPeriod = DetectionPeriod;
		foreach AllActors(class'DVPawn', P)
		{
			if (VSize(P.Location - Location) < DetectionDistance && !bConfigLaunched)
			{
				LaunchConfig(P);
				bConfigLaunched = true;
			}
		}
	}
}


/*--- Not configuring anymore ---*/
event EndViewTarget(PlayerController PC)
{
	bConfigLaunched = false;
}


/*--- Open the configuration interface ---*/
simulated function LaunchConfig(DVPawn P)
{
	local DVPlayerController PC;
	PC = DVPlayerController(P.Controller);
	PC.ConfigureWeapons(self);
}


/*--- View position ---*/
simulated function bool CalcCamera(float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{	
	Mesh.GetSocketWorldLocationAndRotation(EyeSocket, out_CamLoc, out_CamRot);
	
	out_CamRot.Roll = 0;
	out_CamRot.Pitch = -16384;
	out_FOV = 110;
	
	return true;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultProperties
{
	// Mesh
	Begin Object class=SkeletalMeshComponent name=Bench
		BlockActors=true
		BlockZeroExtent=true
		BlockRigidBody=true
		BlockNonzeroExtent=true
		CollideActors=true
		SkeletalMesh=SkeletalMesh'DV_Spacegear.Mesh.SK_ConfigBench'
		PhysicsAsset=PhysicsAsset'DV_Spacegear.Mesh.SK_ConfigBench_Physics'
	End Object
	CollisionComponent=Bench
	Components.Add(Bench)
	Mesh=Bench
	
 	// Gameplay
	DetectionDistance=300.0
	DetectionPeriod=0.25
	EyeSocket=ViewSocket
	
 	// Mesh settings
	Physics=PHYS_RigidBody
	bEdShouldSnap=true
	bCollideActors=true
	bCollideWorld=true
	bBlockActors=true
	bPathColliding=true
}
