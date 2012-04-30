/**
 *  This work is distributed under the General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVPawn extends UDKPawn;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var (DVPawn) const name			EyeSocket;
var (DVPawn) const name			WeaponSocket;
var (DVPawn) const name			WeaponSocket2;

var (DVPawn) const float 		DefaultFOV;
var (DVPawn) const float		ZoomedGroundSpeed;
var (DVPawn) const float		UnzoomedGroundSpeed;
var (DVPawn) const float		HeadshotMultiplier;
var (DVPawn) const float		JumpDamageMultiplier;
var (DVPawn) const float		DeathFlickerFrequency;

var (DVPawn) ParticleSystem		HitPSCTemplate;
var (DVPawn) ParticleSystem		LargeHitPSCTemplate;
var (DVPawn) ParticleSystem		BloodDecalPSCTemplate;
var (DVPawn) array<MaterialInstanceConstant> TeamMaterials;

var DVKillMarker				KM;
var DVPlayerController 			User;
var MaterialInstanceConstant	TeamMaterial;
var AnimNodeBlend 				FeignDeathBlend;
var	DVWeapon					OldWeaponReference;
var repnotify class<DVWeapon> 	CurrentWeaponClass;
var DynamicLightEnvironmentComponent LightEnvironment;

var repnotify LinearColor		TeamLight;
var LinearColor					OffLight;

var string						Killer;
var string						UserName;
var DVPlayerRepInfo				EnemyPRI;

var bool 						bWasHS;
var bool						bZoomed;
var bool						bJumping;
var bool						bLightIsOn;

var float						RecoilAngle;
var float						RecoilLength;
var float						FeignDeathStartTime;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if ( bNetDirty )
		CurrentWeaponClass, Killer, UserName, EnemyPRI, bWasHS, TeamLight;
}

simulated event ReplicatedEvent(name VarName)
{	
	// Weapon class
	if ( VarName == 'CurrentWeaponClass' )
	{
		WeaponClassChanged();
		return;
	}
	
	// Team color
	if ( VarName == 'TeamLight' && Controller != None)
	{
		UpdateTeamColor(DVPlayerController(Controller).GetTeamIndex());
		return;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Initial setup ---*/
function PostBeginPlay()
{
	super.PostBeginPlay();
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		`log("DVLOG/IPOS/" $ self $ "/" $ WorldInfo.TimeSeconds $ "/X/" $ Location.Y $ "/Y/" $ Location.X $ "/ENDLOG");
		SetTimer(0.5, true, 'LogPosition');
	}
}


/*--- Material setup ---*/
simulated function UpdateTeamColor(byte TeamIndex)
{
	if(TeamMaterials[TeamIndex] != None)
	{
		TeamMaterial = Mesh.CreateAndSetMaterialInstanceConstant(0);
		
		if (TeamMaterial != None)
		{
			TeamMaterial.SetParent(TeamMaterials[TeamIndex]);
			TeamMaterial.GetVectorParameterValue('LightColor', TeamLight);
		}
	}
	`log("Updated "$ self $" color with index " $ TeamIndex);
}


/*--- Position logging ---*/
simulated function LogPosition()
{
	`log("DVLOG/POS/" $ self $ "/" $ WorldInfo.TimeSeconds $ "/X/" $ Location.Y $ "/Y/" $ Location.X $ "/ENDLOG");
}


/*--- Init ---*/
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	if (SkelComp == Mesh)
	{
		AimNode = AnimNodeAimOffset(mesh.FindAnimNode('AimNode'));
		LeftHandIK = SkelControlLimb(mesh.FindSkelControl('LeftHandIK'));
		RightHandIK = SkelControlLimb(mesh.FindSkelControl('RightHandIK'));
		FeignDeathBlend = AnimNodeBlend(Mesh.FindAnimNode('FeignDeathBlend'));
		RootRotControl = SkelControlSingleBone(mesh.FindSkelControl('RootRot'));
		FlyingDirOffset = AnimNodeAimOffset(mesh.FindAnimNode('FlyingDirOffset'));
		GunRecoilNode = GameSkelCtrl_Recoil(mesh.FindSkelControl('GunRecoilNode'));
		LeftRecoilNode = GameSkelCtrl_Recoil(mesh.FindSkelControl('LeftRecoilNode'));
		RightRecoilNode = GameSkelCtrl_Recoil(mesh.FindSkelControl('RightRecoilNode'));
		LeftLegControl = SkelControlFootPlacement(Mesh.FindSkelControl(LeftFootControlName));
		RightLegControl = SkelControlFootPlacement(Mesh.FindSkelControl(RightFootControlName));
	}
}


/*--- Replicated weapon switch ---*/
simulated function WeaponClassChanged()
{
	`log("WeaponClassChanged for " $ self);
	if (Mesh != None && (Weapon == None || Weapon.Class != CurrentWeaponClass))
	{
		if (Weapon != None)
		{
			`log("Destroyed " $ Weapon);
			DVWeapon(Weapon).DetachFrom(Mesh);
			Weapon.Destroy();
			Weapon = None;
		}

		if (CurrentWeaponClass != None)
		{
			Weapon = Spawn(CurrentWeaponClass, self);
			Weapon.Instigator = self;
			`log("Spawned " $ Weapon);
		}
	}
	WeaponChanged(DVWeapon(Weapon));
}


/*--- Weapon attachment ---*/
simulated function WeaponChanged(DVWeapon NewWeapon)
{
	if (Mesh != None && NewWeapon.Mesh != None && Weapon != None)
	{
		`log("WeaponChanged, attaching mesh");
		DVWeapon(Weapon).AttachWeaponTo(Mesh);
	}
	OldWeaponReference = NewWeapon;
}


/*--- Weapon change ---*/
simulated function SwitchToWeapon(class<DVWeapon> WpClass)
{
	if (WorldInfo.NetMode == NM_DedicatedServer && InvManager != None)
	{
		CurrentWeaponClass = WpClass;
		`log("SwitchToWeapon " $ CurrentWeaponClass);
	}
}


/*--- Add ammo ---*/
simulated function AddWeaponAmmo(int amount)
{
	if (Weapon != None)
		Weapon.AddAmmo(amount);
}


/*--- Zoomed view location : socket & offset ---*/
simulated function vector GetZoomViewLocation()
{
	local DVWeapon wp;
	wp = DVWeapon(Weapon);
	
	if (wp != None)
		return wp.GetZoomViewLocation();
	else
		return Location;
}


/*--- Which zoom state ? ---*/
simulated function Vector GetPawnViewLocation()
{
	local vector SMS;
	
	if (bZoomed)
		SMS = GetZoomViewLocation();
	else if (!Mesh.GetSocketWorldLocationAndrotation(EyeSocket, SMS))
		`log("GetSocketWorldLocationAndrotation GetPawnViewLocation failed ");
	
	return SMS;
}

simulated function StartZoom()
{
	bZoomed = true;
	DVWeapon(Weapon).ZoomIn();
	Mesh.GlobalAnimRateScale = (ZoomedGroundSpeed / UnzoomedGroundSpeed);
}

simulated function EndZoom()
{
	bZoomed = false;
	DVWeapon(Weapon).ZoomOut();
	Mesh.GlobalAnimRateScale = 1.0;
}


/*--- Camera status update : view calculation ---*/
simulated function bool CalcCamera(float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV)
{
	// Locked
	if (Controller == None || DVPlayerController(Controller).IsCameraLocked())
		return true;
	
	// Zoomed
	if (bZoomed && Weapon != None && Controller != None)
	{
		out_FOV = DVWeapon(Weapon).ZoomedFOV;
		out_CamLoc = GetZoomViewLocation();
		out_CamRot = Controller.Rotation;
		GroundSpeed = ZoomedGroundSpeed;
	}
	
	// Standard viewpoint
	else
	{
		out_FOV = DefaultFOV;
		out_CamLoc = GetPawnViewLocation();
		
		if (Controller != None)
			out_CamRot = Controller.Rotation;
		else
			out_CamRot = Rotation;
		GroundSpeed = UnzoomedGroundSpeed;
	}

	// Recoil and end
	out_camRot.Pitch += RecoilAngle;
	return true;
}


/*--- Recoil ---*/
simulated function GetWeaponRecoil(float angle)
{
	RecoilAngle += angle;
}


/*--- Pawn tick ---*/
simulated function Tick(float DeltaTime)
{
	if (RecoilAngle > 0.0)
	{
		RecoilAngle -= DeltaTime * RecoilLength;
	}
}


/*--- Set ragdoll on/off ---*/
simulated function SetPawnRBChannels(bool bRagdollMode)
{
	if(bRagdollMode)
	{
		Mesh.SetRBChannel(RBCC_Pawn);
		Mesh.SetRBCollidesWithChannel(RBCC_Default,true);
		Mesh.SetRBCollidesWithChannel(RBCC_Pawn,true);
		Mesh.SetRBCollidesWithChannel(RBCC_Vehicle,true);
		Mesh.SetRBCollidesWithChannel(RBCC_Untitled3,false);
		Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume,true);
	}
	else
	{
		Mesh.SetRBChannel(RBCC_Untitled3);
		Mesh.SetRBCollidesWithChannel(RBCC_Default,false);
		Mesh.SetRBCollidesWithChannel(RBCC_Pawn,false);
		Mesh.SetRBCollidesWithChannel(RBCC_Vehicle,false);
		Mesh.SetRBCollidesWithChannel(RBCC_Untitled3,true);
		Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume,true);
	}
}


/*--- Mesh settings ---*/
simulated function HideMesh(bool Invisible)
{
    if ( LocalPlayer(PlayerController(Controller).Player) != None )
        Mesh.SetHidden(Invisible);
}


/*--- Fire started ---*/
simulated function StartFire(byte FireModeNum)
{
	local DVPlayerController PC;
	PC = DVPlayerController(Controller);
	
	// Camera lock
	if (PC.IsCameraLocked())
		return;
	if (FireModeNum == 1 && PC != None)
		StartZoom();
	
	// Real firing
	else
	{
		super.StartFire( FireModeNum );
	}
}


/*--- Fire ended ---*/
simulated function StopFire(byte FireModeNum)
{
	local DVPlayerController PC;
	PC = DVPlayerController(Controller);
	
	// Camera lock
	if (PC.IsCameraLocked()) return;
	
	if (FireModeNum == 1 && PC != None)
		EndZoom();
	else
	{
		super.StopFire( FireModeNum );
	}
}


/*--- Weapon fire effects ---*/
simulated function WeaponFired(Weapon InWeapon, bool bViaReplication, optional vector HitLocation)
{
	if (Weapon != None)
	{
		DVWeapon(Weapon).PlayFiringEffects();
		if ( HitLocation != Vect(0,0,0) && (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone || bViaReplication) )
		{
			DVWeapon(Weapon).PlayImpactEffects(HitLocation);
		}
	}
}


/* -- Triggers PS effect --*/
simulated function FireParticleSystem(ParticleSystem ps, vector loc, rotator rot)
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(ps, loc, rot);
	}
}


/*--- Damage management for blood FX ---*/
simulated event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local vector EndTrace, BloodImpact, BloodNormal;
	local Actor SplatteredActor;
	
	// Local blood
	if (Role == ROLE_Authority && InstigatedBy != None && Controller != None)
	{
		FireParticleSystem(HitPSCTemplate, HitLocation, rotator(Momentum));
		Killer = DVPlayerController(InstigatedBy).GetPlayerName();
		UserName = (Controller != None) ? DVPlayerController(Controller).GetPlayerName() : "BOT";
		EnemyPRI = DVPlayerRepInfo(InstigatedBy.PlayerReplicationInfo);
	}
	
	// Jumping multiplication
	if (InstigatedBy != None)
	{
		if (InstigatedBy.Pawn != None)
			Damage *= DVPawn(InstigatedBy.Pawn).GetJumpingFactor();
	}
	
	// Headshot management
	if (HitInfo.BoneName == 'b_Head' || HitInfo.BoneName == 'b_Neck')
	{
		bWasHS = true;
		Damage *= HeadshotMultiplier;
	}
	else bWasHS = false;

	// Logging
	if (WorldInfo.NetMode == NM_DedicatedServer)
		`log("DVLOG/HIT/" $ WorldInfo.TimeSeconds $ "/X/" $ Location.Y $ "/Y/" $ Location.X $ "/D/" $ Damage $ "/B/" $ HitInfo.BoneName $ "/ENDLOG");
	
	// Blood impact
	EndTrace = HitLocation + Momentum * 10.0;
	SplatteredActor = Trace(BloodImpact, BloodNormal, EndTrace, HitLocation, true,,,TRACEFLAG_Bullet);
	if (SplatteredActor != None)
	{
		if (!SplatteredActor.IsA('Pawn'))
		{
			if (bWasHS)
				FireParticleSystem(LargeHitPSCTemplate, BloodImpact, rotator(BloodNormal));
			else
				FireParticleSystem(BloodDecalPSCTemplate, BloodImpact, rotator(BloodNormal));
		}
	}
	
	Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}


/*--- Death aftermath ---*/
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	local vector ApplyImpulse, ShotDir;
	local TraceHitInfo HitInfo;

	bTearOff = true;
	bPlayedDeath = true;
	bCanTeleport = false;
	TakeHitLocation = HitLoc;
	HitDamageType = DamageType;
	bReplicateMovement = false;
	
	// Weapon
	`log("PlayDying");
	if (OldWeaponReference != None)
	{
		OldWeaponReference.DetachFrom(Mesh);
		OldWeaponReference.Destroy();
	}
	
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		GotoState('Dying');
		return;
	}
	
	// Kill marker
	KM = Spawn((bWasHS ? class'DVKillMarker_HS' : class'DVKillMarker'), self,,,);
	if (Role == ROLE_Authority)
	{
		KM.SetPlayerData(UserName, Killer, TeamLight);
	}
	
	// Kill attribution
	if (EnemyPRI != None)
		EnemyPRI.ScorePoint(false);

	CheckHitInfo( HitInfo, Mesh, Normal(TearOffMomentum), TakeHitLocation );
	bBlendOutTakeHitPhysics = false;
	SetHandIKEnabled(false);

	if (Physics == PHYS_RigidBody)
	{
		setPhysics(PHYS_Falling);
	}

	PreRagdollCollisionComponent = CollisionComponent;
	CollisionComponent = Mesh;

	Mesh.MinDistFactorForKinematicUpdate = 0.f;
	Mesh.ForceSkelUpdate();
	Mesh.UpdateRBBonesFromSpaceBases(true, true);
	Mesh.PhysicsWeight = 1.0;
	
	SetPhysics(PHYS_RigidBody);
	Mesh.PhysicsAssetInstance.SetAllBodiesFixed(false);
	SetPawnRBChannels(true);
	
	// Momentum
	if( TearOffMomentum != vect(0,0,0) )
	{
		ShotDir = normal(TearOffMomentum);
		ApplyImpulse = ShotDir * DamageType.default.KDamageImpulse;

		if ( Velocity.Z > -10 )
		{
			ApplyImpulse += Vect(0,0,1)*DamageType.default.KDeathUpKick;
		}
		Mesh.AddImpulse(ApplyImpulse, TakeHitLocation, HitInfo.BoneName, true);
	}
	
	GotoState('Dying');
}


/*----------------------------------------------------------
	States
----------------------------------------------------------*/

/*--- Just before dying ---*/
simulated State Dying
{
	ignores OnAnimEnd, Bump, HitWall, PhysicsVolumeChange, Falling, FellOutOfWorld;

	/*-- Corpse apparition ---*/
	simulated function BeginState(Name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);
		if ( Mesh != None )
		{
			Mesh.SetTraceBlocking(true, true);
			Mesh.SetActorCollision(true, false);
			Mesh.SetTickGroup(TG_PostAsyncWork);
		}
		SetTimer(30.0, false);
		SetTimer(DeathFlickerFrequency, true, 'ToggleLighting');
		
		// Logging
		if (WorldInfo.NetMode == NM_DedicatedServer)
		{
			`log("DVLOG/DIED/" $ WorldInfo.TimeSeconds $ "/X/" $ Location.Y $ "/Y/" $ Location.X $ "/ENDLOG");
		}
	}
	
	event bool EncroachingOn(Actor Other)
	{
		return false;
	}
	
	/*--- Marker movement logic ---*/
	simulated function Tick(float DeltaTime)
	{
		// Marker
		if (KM != None)
			KM.SetLocation(Location);
	}
	
	/*-- Corpse removal ---*/
	event Timer()
	{
		Destroy();
	}
	
	/*-- Corpse damage ---*/
	simulated event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		local Vector shotDir, ApplyImpulse;

		CheckHitInfo( HitInfo, Mesh, Normal(Momentum), HitLocation );

		if (Role == ROLE_Authority && InstigatedBy != None && Controller != None)
		{
			FireParticleSystem(LargeHitPSCTemplate, HitLocation, rotator(Momentum));
			Killer = DVPlayerController(InstigatedBy).GetPlayerName();
			UserName = DVPlayerController(Controller).GetPlayerName();
		}

		if( (Physics != PHYS_RigidBody) || (Momentum == vect(0,0,0)) || (HitInfo.BoneName == '') )
			return;

		shotDir = Normal(Momentum);
		ApplyImpulse = (DamageType.Default.KDamageImpulse * shotDir);

		if(Velocity.Z > -10)
		{
			ApplyImpulse += Vect(0,0,1) * DamageType.default.KDeathUpKick;
		}
		Mesh.WakeRigidBody();
		Mesh.AddImpulse(ApplyImpulse, HitLocation, HitInfo.BoneName, true);
	}
}


/*--- Death Lighting ---*/
simulated function ToggleLighting()
{
	if (TeamMaterial != None)
	{
		if (bLightIsOn)
			TeamMaterial.SetVectorParameterValue('LightColor', TeamLight);
		else
			TeamMaterial.SetVectorParameterValue('LightColor', OffLight);
	}
	bLightIsOn = !bLightIsOn;
}


/*--- Jump management ---*/
function bool DoJump( bool bUpdating )
{
	bJumping = true;
	return super.DoJump(bUpdating);
}

event Landed(vector HitNormal, Actor FloorActor)
{
	super.Landed(HitNormal, FloorActor);
	bJumping = false;
}

simulated function float GetJumpingFactor()
{
	return (bJumping ? JumpDamageMultiplier : 1.0);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// I can has light
	Begin Object class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bUseBooleanEnvironmentShadowing=true
		bIsCharacterLightEnvironment=true
		bSynthesizeSHLight=true
		bEnabled=true
		bDynamic=true
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment
	
	// Main mesh
	Begin Object class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		bHasPhysicsAssetInstance=true
		bPerBoneMotionBlur=true
		BlockZeroExtent=true
		BlockRigidBody=true
		CollideActors=true
		Rotation=(Yaw=-16384)
		Scale=2.0
	End Object
	Mesh=SkeletalMeshComponent0
	Components.Add(SkeletalMeshComponent0)
	
	// Materials
	OffLight=(R=0.0,G=0.0,B=0.0,A=0.0)
	
	// Cylinder
	Begin Object Name=CollisionCylinder
		CollisionRadius=40.0
		CollisionHeight=100.0
		BlockZeroExtent=false
	End Object
	CylinderComponent=CollisionCylinder
	CollisionComponent=CollisionCylinder
	
	// Zoom
	bZoomed=false
	DefaultFOV=90
	ZoomedGroundSpeed=300
	UnzoomedGroundSpeed=750
	
	// Weapons
	EyeSocket=EyeSocket
	WeaponSocket=WeaponPoint
	WeaponSocket2=DualWeaponPoint
	InventoryManagerClass=class'DVCore.DVInventoryManager'
	HitPSCTemplate=ParticleSystem'DV_CoreEffects.FX.PS_BloodHit'
	BloodDecalPSCTemplate=ParticleSystem'DV_CoreEffects.FX.PS_BloodDecal'
	LargeHitPSCTemplate=ParticleSystem'DV_CoreEffects.FX.PS_BloodHit_Large'
	
	// Jumping
	JumpZ=600.0
	AirSpeed=800.0
	MaxJumpHeight=110.0
	HeadshotMultiplier=1.5
	JumpDamageMultiplier=1.5
	
	// Gameplay
	bWasHS=false
	bJumping=false
	bLightIsOn=true
	RecoilAngle=0.0
	RecoilLength=7000.0
	Killer="HIMSELF !"
	UserName="SOMEONE"
	DeathFlickerFrequency=1.0
	FeignDeathStartTime = 0.0
}
