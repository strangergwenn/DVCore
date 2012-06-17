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
var (Bench) const name			WeaponSocket;

var (Bench) const float 		DetectionDistance;
var (Bench) const float 		DetectionPeriod;
var (Bench) const float 		WeaponScale;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var SkeletalMeshComponent		Mesh;

var DVPlayerController			PC;

var DVPawn						OldPawn;

var float 						CurrentPeriod;

var bool 						bConfigLaunched;

var string						ModuleName;

var DVWeapon					Weapon;


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
			if (VSize(P.Location - Location) < DetectionDistance && !bConfigLaunched && P != OldPawn)
			{
				OldPawn = P;
				bConfigLaunched = LaunchConfig(P);
			}
		}
	}
}


/*--- Open the configuration interface ---*/
simulated function bool LaunchConfig(DVPawn P)
{
	// Vars
	local vector WPos;
	local rotator WRot;
	PC = DVPlayerController(P.Controller);
	
	// Init
	if (PC != None)
	{
		Mesh.GetSocketWorldLocationAndRotation(WeaponSocket, WPos, WRot);
		PC.ConfigureWeapons(self);
		ModuleName = P.ModuleName;
		
		// Weapon spawn
		Weapon = Spawn(P.CurrentWeaponClass, self,, WPos);
		Weapon.AttachWeaponTo(Mesh, WeaponSocket);
		Weapon.Mesh.SetScale3D(Vect(1,1,1) * WeaponScale);
		return true;
	}
	
	// Error
	else
		return false;
}


/*--- Not configuring anymore ---*/
simulated function ConfiguringEnded(PlayerController ThePC)
{
	bConfigLaunched = false;
	
	Weapon.DetachFrom(Mesh);
	Weapon.Destroy();
	Weapon = None;
	
	OldPawn.Destroy();
}


/*--- View position ---*/
simulated function bool CalcCamera(float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{	
	Mesh.GetSocketWorldLocationAndRotation(EyeSocket, out_CamLoc, out_CamRot);
	
	out_CamRot.Roll = 0;
	out_CamRot.Pitch = -16384;
	
	return true;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultProperties
{
	// Lighting
	Begin Object class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
		bDynamic=true
	End Object
	Components.Add(MyLightEnvironment)
	
	// Mesh
	Begin Object class=SkeletalMeshComponent name=Bench
		Scale=0.7
		BlockActors=true
		BlockZeroExtent=true
		BlockRigidBody=true
		BlockNonzeroExtent=true
		CollideActors=true
		LightEnvironment=MyLightEnvironment
		SkeletalMesh=SkeletalMesh'DV_Spacegear.Mesh.SK_ConfigBench'
		PhysicsAsset=PhysicsAsset'DV_Spacegear.Mesh.SK_ConfigBench_Physics'
	End Object
	CollisionComponent=Bench
	Components.Add(Bench)
	Mesh=Bench
	
 	// Gameplay
 	WeaponScale=1.8;
	DetectionPeriod=0.25
	DetectionDistance=300.0
	EyeSocket=ViewSocket
	WeaponSocket=WeaponPoint
	
 	// Mesh settings
	bEdShouldSnap=true
	bCollideActors=true
	bCollideWorld=true
	bBlockActors=true
	bPathColliding=true
}
