/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVWeapon extends UDKWeapon
	config(Weapon);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVWeapon) const SoundCue				WeaponEmptySound;
var (DVWeapon) const array<SoundCue>		WeaponFireSnd;
var (DVWeapon) const MaterialImpactEffect 	ImpactEffect;

var (DVWeapon) const ParticleSystem			MuzzleFlashPSCTemplate;
var (DVWeapon) const ParticleSystem			BeamPSCTemplate_Red;
var (DVWeapon) const ParticleSystem			BeamPSCTemplate_Blue;

var (DVWeapon) vector						ZoomOffset;

var (DVWeapon) float						SmoothingFactor;
var (DVWeapon) float 						ZoomSensitivity;
var (DVWeapon) float						RecoilAngle;
var (DVWeapon) float 						ZoomedFOV;

var (DVWeapon) int							MaxAmmo;

var (DVWeapon) const name					LaserBeamSocket;
var (DVWeapon) const name					WeaponFireAnim;
var (DVWeapon) const array<name> 			EffectSockets;
var (DVWeapon) name							ZoomSocket;

var (DVWeapon) string						WeaponName;
var (DVWeapon) string						WeaponIcon;
var (DVWeapon) string						WeaponDesc;
var (DVWeapon) string						WeaponDamage;

var (DVWeapon) DVWeaponAddon				Addon1;
var (DVWeapon) DVWeaponAddon				Addon2;
var (DVWeapon) class<DVWeaponAddon>			AddonClass1;
var (DVWeapon) class<DVWeaponAddon>			AddonClass2;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var ParticleSystemComponent		MuzzleFlashPSC;
var ParticleSystemComponent		BeamPSC;

var bool						bWeaponEmpty;
var bool						bBeamActive;
var bool						bZoomed;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if ( bNetDirty )
		bZoomed, bBeamActive, Addon1, Addon2, bWeaponEmpty;
}


/*----------------------------------------------------------
	Various methods
----------------------------------------------------------*/

/* --- Attachment ---*/
simulated function TimeWeaponEquipping()
{
	local DVPawn ZP;
	
	ZP = DVPawn(Owner);
	AmmoCount = MaxAmmo;
	Mesh.SetHidden(false);
	
	if ((WorldInfo.NetMode == NM_StandAlone || WorldInfo.NetMode == NM_DedicatedServer) && ZP != None)
	{
		ZP.CurrentWeaponClass = self.class;
		ZP.WeaponClassChanged();
	}
	
	SetTimer(0.5, false, 'WeaponEquipped');
}


/*--- Weapon attachment ---*/
simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	local DVPawn target;
	target = DVPawn(Owner);
	
	if (SocketName == '')
		SocketName = target.WeaponSocket;
	if (SkeletalMeshComponent(Mesh) == None)
		return;
	
	// Mesh
	AttachComponent(Mesh);
	if (target.Mesh != None && Mesh != None)
	{
		Mesh.SetShadowParent(target.Mesh);
		Mesh.SetLightEnvironment(target.LightEnvironment);
		target.Mesh.AttachComponentToSocket(SkeletalMeshComponent(Mesh), SocketName);
	}
	
	// Flash
	MuzzleFlashPSC = new(Outer) class'ParticleSystemComponent';
	MuzzleFlashPSC.bAutoActivate = false;
	MuzzleFlashPSC.SetTemplate(MuzzleFlashPSCTemplate);
	SkeletalMeshComponent(Mesh).AttachComponentToSocket(MuzzleFlashPSC, EffectSockets[0]);
	
	// FX : beam
	BeamPSC = new(Outer) class'ParticleSystemComponent';
	BeamPSC.bAutoActivate = false;
	if (DVPlayerRepInfo(target.PlayerReplicationInfo).Team.TeamIndex == 1)
		BeamPSC.SetTemplate(BeamPSCTemplate_Blue);
	else
		BeamPSC.SetTemplate(BeamPSCTemplate_Red);
	BeamPSC.bUpdateComponentInTick = true;
	BeamPSC.SetTickGroup(TG_EffectsUpdateWork);
	SkeletalMeshComponent(Mesh).AttachComponentToSocket(BeamPSC, LaserBeamSocket);
	
	// Weapon add-ons
	if (AddonClass1 != None)
	{
		Addon1 = Spawn(AddonClass1, self);
		Addon1.AttachToWeapon(self);
	}
	if (AddonClass2 != None)
	{
		Addon2 = Spawn(AddonClass2, self);
		Addon2.AttachToWeapon(self);
	}
}


/*--- Detach weapon from pawn ---*/
simulated function DetachFrom(SkeletalMeshComponent MeshCpnt)
{
	if (Mesh != None)
	{
		Mesh.SetShadowParent(None);
		Mesh.SetLightEnvironment(None);
		
		if (MeshCpnt != None)
			MeshCpnt.DetachComponent(Mesh);
	}
	BeamPSC.DeactivateSystem();
}


/*--- Laser pointer end --*/
simulated function Tick(float DeltaTime)
{
	local vector EndTrace, SocketLocation;
	local rotator SocketRotation;
	local ImpactInfo Impact;
	local DVPawn target;
	
	// Init
	Super.Tick(DeltaTime);
	target = DVPawn(Owner);
	if (target == None)
		return;
	
	// Mesh
	Mesh.SetHidden(false);
	if (!SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(LaserBeamSocket, SocketLocation, SocketRotation))
		`warn("GetSocketWorldLocationAndrotation Tick failed ");
	
	// Impact location calculation
	SocketLocation = DVPawn(Owner).GetZoomViewLocation(); // ignore previous result !
	EndTrace = SocketLocation + vector(SocketRotation) * 3000.0;
	Impact = CalcWeaponFire(SocketLocation, EndTrace);
	
	// Laser pointer
	if (BeamPSC != None)
	{
		if (UseBeam() && !bBeamActive)
		{
			BeamPSC.ActivateSystem();
			bBeamActive = true;
		}
		else if (!UseBeam() && bBeamActive)
		{
			BeamPSC.DeactivateSystem();
			bBeamActive = false;
		}
		if (bBeamActive)
		{
			BeamPSC.SetVectorParameter('BeamEnd', Impact.HitLocation);
		}
	}
}


/*--- Ammo ---*/
simulated function int AddAmmo(int amount)
{
	local int PreviousAmmo;
	
	bWeaponEmpty = false;
	PreviousAmmo = AmmoCount;
	AmmoCount = Clamp(AmmoCount + amount, 0, MaxAmmo);
	return AmmoCount - PreviousAmmo;
}


/*--- Is beam online ---*/
reliable client simulated function bool UseBeam()
{
	local DVPawn P;
	P = DVPawn(Owner);
	
	if (P != None)
	{
		return P.GetBeamStatus();
	}
	else
		return true;
}


/*----------------------------------------------------------
	Zoom methods
----------------------------------------------------------*/

/*--- Zoom location ---*/
simulated function vector GetZoomViewLocation()
{
	local vector loc, X, Y, Z;
	local rotator rot;
	
	if (Mesh != None)
	{
		if (!SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndrotation(ZoomSocket, loc, rot))
			`warn("GetSocketWorldLocationAndrotation GetZoomViewLocation failed ");
		
		GetAxes(rot, X, Y, Z);
		return loc + ZoomOffset.X * X +  ZoomOffset.Y * Y +  ZoomOffset.Z * Z;
	}
	else
	{
		return Location;
	}
}


/*--- Zoom managment ---*/
simulated function bool IsZoomed()
{
	return bZoomed;	
}
simulated function float GetZoomFactor()
{
	return ZoomSensitivity;
}
simulated function ZoomIn()
{
	bZoomed = true;
}
simulated function ZoomOut()
{
	bZoomed = false;
}


/*----------------------------------------------------------
	Firing methods
----------------------------------------------------------*/

/*--- Tracing ---*/
simulated function vector InstantFireStartTrace()
{
	return GetEffectLocation();
}
simulated function vector InstantFireEndTrace(vector StartTrace)
{
	local rotator rot;
	local vector loc;
	
	if (!SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(EffectSockets[0], loc, rot))
		`warn("GetSocketWorldLocationAndrotation InstantFireEndTrace failed ");
	
	return StartTrace + vector(rot) * GetTraceRange();
}


/*--- Instant hit ---*/
simulated function InstantFire()
{
	local vector StartTrace, EndTrace;
	local Array<ImpactInfo>	ImpactList;
	local ImpactInfo RealImpact;
	local int i;

	StartTrace = InstantFireStartTrace();
	EndTrace = InstantFireEndTrace(StartTrace);
	RealImpact = CalcWeaponFire(StartTrace, EndTrace, ImpactList);

	for (i = 0; i < ImpactList.length; i++)
	{
		ProcessInstantHit(CurrentFireMode, ImpactList[i]);
	}
	
	if (Role == ROLE_Authority)
	{
		SetFlashLocation(RealImpact.HitLocation);
	}
}


/*--- Firing effects ---*/
simulated function FireAmmunition()
{
	local DVPawn P;
	local DVPlayerController PC;
	
	// Init
	PC = DVPlayerController(Instigator.Controller);
	if (PC == None) return;
	P = DVPawn(Owner);
	
	// Empty ammo ?
	if (bWeaponEmpty)
	{
		return;
	}
	else if (AmmoCount <= 0)
	{
		PlaySound(WeaponEmptySound, false, true, false, P.Location);
		PC.ShowEmptyAmmo();
		bWeaponEmpty = true;
		return;
	}
	
	// Logging
	AmmoCount -= 1;
	PC.RegisterShot();
	P.ServerLogAction("SHOOT");
	
	// Firing
	PlayFiringSound();
	SkeletalMeshComponent(Mesh).PlayAnim(WeaponFireAnim);
	P.GetWeaponRecoil(RecoilAngle);
	Super.FireAmmunition();
}


/*--- Instant hit processing ---*/
simulated function ProcessInstantHit(byte FiringMode, ImpactInfo Impact, optional int NumHits)
{
	local bool bFixMomentum;
	if (Impact.HitActor != None && !Impact.HitActor.bStatic && (Impact.HitActor != Instigator))
	{
		if ( Impact.HitActor.Role == ROLE_Authority && Impact.HitActor.bProjTarget
			&& !WorldInfo.GRI.OnSameTeam(Instigator, Impact.HitActor)
			&& Impact.HitActor.Instigator != Instigator
			&& PhysicsVolume(Impact.HitActor) == None )
		{
			HitEnemy++;
		}
		
		if ((UDKPawn(Impact.HitActor) == None) && (InstantHitMomentum[FiringMode] == 0))
		{
			InstantHitMomentum[FiringMode] = 1;
			bFixMomentum = true;
		}
		
		Super.ProcessInstantHit(FiringMode, Impact, NumHits);
		if (bFixMomentum)
		{
			InstantHitMomentum[FiringMode] = 0;
		}
	}
}


/*--- Muzzle flash ---*/
simulated function PlayFiringEffects()
{
	MuzzleFlashPSC.ActivateSystem();
}


/*--- Impact effects ---*/
simulated function PlayImpactEffects(vector HitLocation)
{
	// Init
	local vector NewHitLoc, HitNormal, FireDir;
	local TraceHitInfo HitInfo;
	local Actor HitActor;
	local DVPawn P;
	
	// Effects
	HitNormal = Normal(Owner.Location - HitLocation);
	FireDir = -1 * HitNormal;
	P = DVPawn(Owner);
	if (P != None)
	{		
		// Taking fire !
		HitActor = Trace(NewHitLoc, HitNormal, (HitLocation - (HitNormal * 32)), HitLocation + (HitNormal * 32), true,, HitInfo, TRACEFLAG_Bullet);
		if(Pawn(HitActor) != none)
		{
			CheckHitInfo(HitInfo, Pawn(HitActor).Mesh, -HitNormal, NewHitLoc);
		}
		
		// Sound effects
		if (ImpactEffect.Sound != None)
		{
			PlaySound(ImpactEffect.Sound, true,,, HitLocation);
		}
		if (DVPawn(HitActor) != None)
		{
			DVPlayerController(P.Controller).PlayHitSound();
		}
		
		// Particle system template
		if ( HitActor != None && (Pawn(HitActor) == None || Vehicle(HitActor) != None) && (ImpactEffect.ParticleTemplate != None))
		{
			HitNormal = normal(FireDir - ( 2 *  HitNormal * (FireDir dot HitNormal) ) ) ;
			FireParticleSystem(ImpactEffect.ParticleTemplate, HitLocation, rotator(HitNormal));
		}
	}
}


/*--- Effects location ---*/
simulated function vector GetEffectLocation()
{
	local vector SocketLocation;

	if (SkeletalMeshComponent(Mesh) != None && EffectSockets[CurrentFireMode] != '')
	{
		if (!SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(EffectSockets[CurrentFireMode], SocketLocation))
		{
			`log("GetSocketWorldLocationAndrotation GetEffectLocation failed");
			SocketLocation = Location;
		}
	}
	else
	{
		SocketLocation = Location;
	}
 	return SocketLocation;
}


/* -- Triggers PS effect --*/
simulated function FireParticleSystem(ParticleSystem ps, vector loc, rotator rot)
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(ps, loc, rot);
	}
}


/*--- Sound ---*/
simulated function PlayFiringSound()
{
	if (CurrentFireMode<WeaponFireSnd.Length)
	{
		if ( WeaponFireSnd[CurrentFireMode] != None )
		{
			MakeNoise(1.0);
			PlaySound(WeaponFireSnd[CurrentFireMode], false, true, false, Owner.Location);
		}
	}
}


/*--- Ammo for HUD : current ---*/
simulated function int GetAmmoCount()
{
	return AmmoCount;
}


/*--- Ammo for HUD : max---*/
simulated function int GetAmmoMax()
{
	return MaxAmmo;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Anims
	Begin Object class=AnimNodeSequence Name=MeshSequenceA
	End Object
	WeaponFireAnim=WeaponFire
	
	// Lighting
	Begin Object class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
		bDynamic=true
	End Object
	Components.Add(MyLightEnvironment)
	
	// Mesh
	Begin Object Class=SkeletalMeshComponent Name=WeaponMesh
		bOverrideAttachmentOwnerVisibility=true
		LightEnvironment=MyLightEnvironment
		Animations=MeshSequenceA
		bPerBoneMotionBlur=true
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		Rotation=(Yaw=-16384)
		bOnlyOwnerSee=false
	End Object
	Mesh=WeaponMesh
	
	// Gameplay
	InstantHitDamageTypes(0)=class'DamageType'
	InstantHitDamageTypes(1)=class'DamageType'
	FiringStatesArray(0)=WeaponFiring
	FiringStatesArray(1)=WeaponFiring
	WeaponFireTypes(0)=EWFT_InstantHit
	WeaponFireTypes(1)=EWFT_Custom
	
	// Shots
	InstantHitMomentum(0)=0.0
	InstantHitMomentum(1)=0.0
	InstantHitDamage(0)=0.0
	InstantHitDamage(1)=0.0
	FireInterval(0)=1.0
	FireInterval(1)=1.0
	WeaponRange=22000
	RecoilAngle=100.0
	Spread(0)=0.0
	Spread(1)=0.0

	// User settings
	ZoomedFOV=60
	ZoomSocket=Mount2
	ZoomSensitivity=0.3
	SmoothingFactor=0.7
	ZoomOffset=(X=0,Y=0,Z=1.0)
	
	// Effects
	BeamPSCTemplate_Blue=ParticleSystem'DV_CoreEffects.FX.PS_LaserBeamEffect_Blue'
	BeamPSCTemplate_Red=ParticleSystem'DV_CoreEffects.FX.PS_LaserBeamEffect'
	MuzzleFlashPSCTemplate=ParticleSystem'DV_CoreEffects.FX.PS_Flash'
	LaserBeamSocket=Mount1
	WeaponFireSnd[0]=None
	WeaponFireSnd[1]=None
	EffectSockets(0)=MF
	EffectSockets(1)=MF
	
	// Initialization
	bZoomed=false
	bHidden=false
	bBeamActive=false
	bWeaponEmpty=false
	bOnlyRelevantToOwner=false
	bOnlyDirtyReplication=false
}
