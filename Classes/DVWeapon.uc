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
var (DVWeapon) const SoundCue				SilencedWeaponSound;
var (DVWeapon) const array<SoundCue>		WeaponFireSnd;
var (DVWeapon) const MaterialImpactEffect 	ImpactEffect;

var (DVWeapon) const ParticleSystem			MuzzleFlashPSCTemplate;

var (DVWeapon) vector						ZoomOffset;

var (DVWeapon) bool							bHasLens;
var (DVWeapon) bool							bSilenced;
var (DVWeapon) bool							bLongRail;
var (DVWeapon) bool							bCannonMount;

var (DVWeapon) float						SmoothingFactor;
var (DVWeapon) float 						ZoomSensitivity;
var (DVWeapon) float						RecoilAngle;
var (DVWeapon) float 						ZoomedFOV;

var (DVWeapon) int							MaxAmmo;
var (DVWeapon) int							TickDivisor;

var (DVWeapon) const name					WeaponFireAnim;
var (DVWeapon) const array<name> 			EffectSockets;
var (DVWeapon) name							ZoomSocket;

var (DVWeapon) Texture2D					WeaponIcon;
var (DVWeapon) string						WeaponIconPath;
var (DVWeapon) string						WeaponModuleName;


/*----------------------------------------------------------
	Configurable attributes
----------------------------------------------------------*/

var (DVWeapon) config string				AddonClass1;
var (DVWeapon) config string				AddonClass2;
var (DVWeapon) config string				AddonClass3;

var (DVWeapon) config array<string> 		AvailableAddons;


/*----------------------------------------------------------
	Localized attributes
----------------------------------------------------------*/

var (DVWeapon) localized string				lWeaponName;
var (DVWeapon) localized string				lWeaponDesc;
var (DVWeapon) localized string				lWeaponDamage;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var ParticleSystemComponent		MuzzleFlashPSC;

var bool						bWeaponEmpty;
var bool						bZoomed;

var int							FrameCount;

var repnotify string			PlayerAddonClass1;
var repnotify string			PlayerAddonClass2;
var repnotify string			PlayerAddonClass3;

var string						OldPlayerAddonClass1;
var string						OldPlayerAddonClass2;
var string						OldPlayerAddonClass3;

var DVWeaponAddon				Addon1;
var DVWeaponAddon				Addon2;
var DVWeaponAddon				Addon3;
var array< class<DVWeaponAddon> > AddonList;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if ( bNetDirty )
		MaxAmmo, bZoomed, bWeaponEmpty, PlayerAddonClass1, PlayerAddonClass2, PlayerAddonClass3;
}


simulated event ReplicatedEvent(name VarName)
{	
	`log("DVW > ReplicatedEvent" @VarName);
	if (VarName == 'PlayerAddonClass1' && PlayerAddonClass1 != OldPlayerAddonClass1)
	{
		SetAddon(Addon1,OldPlayerAddonClass1, PlayerAddonClass1);
		OldPlayerAddonClass1 = PlayerAddonClass1;
		return;
	}
	if (VarName == 'PlayerAddonClass2' && PlayerAddonClass2 != OldPlayerAddonClass2)
	{
		SetAddon(Addon2,OldPlayerAddonClass2, PlayerAddonClass2);
		OldPlayerAddonClass2 = PlayerAddonClass2;
		return;
	}
	if (VarName == 'PlayerAddonClass3' && PlayerAddonClass3 != OldPlayerAddonClass3)
	{
		SetAddon(Addon3,OldPlayerAddonClass3, PlayerAddonClass3);
		OldPlayerAddonClass3 = PlayerAddonClass3;
		return;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}



/*----------------------------------------------------------
		Various methods
----------------------------------------------------------*/


/*--- Target designation --*/
simulated function Tick(float DeltaTime)
{
	// Init
	local vector Impact, SL, Unused;
	local rotator SR;
	FrameCount += 1;
	
	if (FrameCount % TickDivisor == 0 && Owner != None)
	{
		// Trace
		SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation('Mount1', SL, SR);
		if (DVPawn(Owner) != None)
		{
			if (DVPawn(Owner).Controller != None)
			{
				DVPlayerController(DVPawn(Owner).Controller).TargetObject = Trace(
					Impact,
					Unused,
					SL + vector(SR) * 10000.0,
					SL,
					true,,, TRACEFLAG_Bullet
				);
			}
		}
	}
}


/* --- Attachment ---*/
simulated function TimeWeaponEquipping()
{
	local DVPawn ZP;
	ZP = DVPawn(Owner);
	AmmoCount = MaxAmmo;
	
	if ((WorldInfo.NetMode == NM_StandAlone || WorldInfo.NetMode == NM_DedicatedServer) 
	 && ZP != None)
	{
		`log("DVW > TimeWeaponEquipping" @AddonClass1 @AddonClass2 @AddonClass3 @self);
		if (WorldInfo.NetMode == NM_StandAlone)
		{
			SetupAddons();
		}
		ZP.CurrentWeaponClass = self.class;
		ZP.WeaponClassChanged();
	}
	
	SetTimer(0.5, false, 'WeaponEquipped');
}


/*--- Config bench ---*/
simulated function TimeBenchEquipping()
{
	ServerSetAddonClasses(AddonClass1, AddonClass2, AddonClass3);
}

/*--- Weapon attachment ---*/
simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	// Init
	local DVPawn target;
	target = DVPawn(Owner);
	if (SkeletalMeshComponent(Mesh) == None)
		return;
	Mesh.SetHidden(false);
	FillAddonList();
	
	// Config bench
	if (Owner.IsA('DVConfigBench'))
	{
		MeshCpnt.AttachComponentToSocket(SkeletalMeshComponent(Mesh), SocketName);
		Mesh.SetLightEnvironment(DVConfigBench(Owner).LightEnvironment);
	}
	
	// Standard game
	else
	{
		// Socket name
		if (SocketName == '')
			SocketName = target.WeaponSocket;
		
		// Mesh
		AttachComponent(Mesh);
		if (target.Mesh != None && Mesh != None)
		{
			Mesh.SetShadowParent(target.Mesh);
			Mesh.SetLightEnvironment(target.LightEnvironment);
			target.Mesh.AttachComponentToSocket(SkeletalMeshComponent(Mesh), SocketName);
		}
	}
	
	// Flash
	MuzzleFlashPSC = new(Outer) class'ParticleSystemComponent';
	MuzzleFlashPSC.bAutoActivate = false;
	MuzzleFlashPSC.SetTemplate(MuzzleFlashPSCTemplate);
	SkeletalMeshComponent(Mesh).AttachComponentToSocket(MuzzleFlashPSC, EffectSockets[0]);
	
	// Weapon add-ons
	if (WorldInfo.NetMode == NM_StandAlone)
	{
		SpawnAddon(PlayerAddonClass1);
		SpawnAddon(PlayerAddonClass2);
		SpawnAddon(PlayerAddonClass3);
	}
	else if (Role == ROLE_Authority)
	{
		SetupAddons();
	}
	`log("DVW > AttachWeaponTo" @PlayerAddonClass1 @PlayerAddonClass2 @PlayerAddonClass3 @self);
}


/*--- Addons ---*/
reliable client simulated function SetupAddons()
{
	ServerSetAddonClasses(AddonClass1, AddonClass2, AddonClass3);
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
	
	// Weapon add-ons
	RemoveAddon(Addon1);
	RemoveAddon(Addon2);
	RemoveAddon(Addon3);
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


/*----------------------------------------------------------
	Add-ons management
----------------------------------------------------------*/

/*--- Save status ---*/
simulated function SaveStatus()
{
	AddonClass1 = PlayerAddonClass1;
	AddonClass2 = PlayerAddonClass2;
	AddonClass3 = PlayerAddonClass3;
	SaveConfig();
	`log("DVW > SaveStatus" @AddonClass1 @AddonClass2 @AddonClass3 @self);
}


/*--- Addon classes ---*/
reliable server simulated function ServerSetAddonClasses(string A1, string A2, string A3)
{
	if (WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_StandAlone)
	{
		PlayerAddonClass1 = A1;
		PlayerAddonClass2 = A2;
		PlayerAddonClass3 = A3;
		bForceNetUpdate = true;
	}
	`log("DVW > ServerSetAddonClasses" @PlayerAddonClass1 @PlayerAddonClass2 @PlayerAddonClass3 @self);
}


/*--- Fill the available addons list ---*/
simulated function FillAddonList()
{
	local byte i;
	
	for (i = 0; i < 16; i++)
	{
		if (AvailableAddons[i] != "")
		{
			AddonList.AddItem(class<DVWeaponAddon>(DynamicLoadObject(
				GetModuleName() $"." $AvailableAddons[i],
				class'Class',
				false))
			);
		}
		else
			AddonList.AddItem(None);
	}
}


/*--- Manage an add-on request (add or delete) ---*/
simulated function RequestAddon(byte AddonID)
{
	`log("DVW > RequestAddon" @AddonID @self);
	
	switch (AddonList[AddonID].default.SocketID)
	{
		case 1:
			SetAddon(Addon1, PlayerAddonClass1, string(AddonList[AddonID]));
			OldPlayerAddonClass1 = PlayerAddonClass1;
			break;		
		case 2:
			SetAddon(Addon2, PlayerAddonClass2, string(AddonList[AddonID]));
			OldPlayerAddonClass2 = PlayerAddonClass2;
			break;
		case 3:
			SetAddon(Addon3, PlayerAddonClass3, string(AddonList[AddonID]));
			OldPlayerAddonClass3 = PlayerAddonClass3;
			break;
	}
}


/*--- Add-on toggle ---*/
simulated function SetAddon(DVWeaponAddon OldAddon, string OldClass, string NewClass)
{
	`log("DVW > SetAddon -" @OldClass @"-" @NewClass @self);
	
	if (OldClass != "")
		RemoveAddon(OldAddon);
	if (OldClass != NewClass)
		SpawnAddon(NewClass);
}


/*--- Add-on creation ---*/
simulated function SpawnAddon(string AddonClass)
{
	local DVWeaponAddon NewAddon;
	`log("DVW > SpawnAddon" @AddonClass @"-" @PlayerAddonClass1 @PlayerAddonClass2 @PlayerAddonClass3 @self);	
	
	if (AddonClass != "")
	{
		NewAddon = GetAddon(AddonClass);
		switch (NewAddon.SocketID)
		{
			case 1:
				Addon1 = NewAddon;
				PlayerAddonClass1 = AddonClass;
				Addon1.AttachToWeapon(self);
				break;
			case 2:
				Addon2 = NewAddon;
				PlayerAddonClass2 = AddonClass;
				Addon2.AttachToWeapon(self);
				break;
			case 3:
				Addon3 = NewAddon;
				PlayerAddonClass3 = AddonClass;
				Addon3.AttachToWeapon(self);
				break;
		}
	}
}


/*--- Add-on deletion ---*/
simulated function RemoveAddon(DVWeaponAddon OldAddon)
{
	`log("DVW > RemoveAddon" @OldAddon @self);	
	
	if (OldAddon != None)
	{
		switch (OldAddon.SocketID)
		{
			case 1:
				Addon1.DetachFromWeapon(self);
				PlayerAddonClass1 = "";
				Addon1 = None;
				break;
			case 2:
				Addon2.DetachFromWeapon(self);
				PlayerAddonClass2 = "";
				Addon2 = None;
				break;
			case 3:
				Addon3.DetachFromWeapon(self);
				PlayerAddonClass3 = "";
				Addon3 = None;
				break;
		}
	}
}


/*--- Add-on loading ---*/
simulated function DVWeaponAddon GetAddon(string AddonClass)
{
	local DVWeaponAddon wpAdd;
	if (AddonClass != "")
	{
		wpAdd = Spawn(
			class<DVWeaponAddon>(DynamicLoadObject(
				GetModuleName() $"." $AddonClass,
				class'Class',
				false)),
			self
		);
	}
	`log("DVW > GetAddon >" @AddonClass @">" @wpAdd @self);
	return wpAdd;
}


/*--- Path for loading parts ---*/
simulated function string GetModuleName()
{
	local string ModuleName;
	
	if (Owner == None)
		ModuleName = WeaponModuleName;
	else if (Owner.IsA('DVConfigBench'))
		ModuleName = DVConfigBench(Owner).ModuleName;
	else
		ModuleName = DVPawn(Owner).ModuleName;
		
	return ModuleName;
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
			`log("DVW > GetSocketWorldLocationAndrotation GetZoomViewLocation failed ");
		
		GetAxes(rot, X, Y, Z);
		return loc + ZoomOffset.X * X +  ZoomOffset.Y * Y +  ZoomOffset.Z * Z;
	}
	else
	{
		return Location;
	}
}


/*--- Zoom state ---*/
simulated function bool IsZoomed()
{
	return bZoomed;	
}


/*--- Zoomed sensitivity factor ---*/
simulated function float GetZoomFactor()
{
	return ZoomSensitivity;
}


/*--- Begin zoom state ---*/
simulated function ZoomIn()
{
	if (HasLensEffect())
		DVHUD(DVPlayerController(DVPawn(Owner).Controller).myHUD).SetSniperState(true);
	bZoomed = true;
}


/*--- End zoom state ---*/
simulated function ZoomOut()
{
	if (HasLensEffect())
		DVHUD(DVPlayerController(DVPawn(Owner).Controller).myHUD).SetSniperState(false);
	bZoomed = false;
}


/*--- Use lens effect ---*/
simulated function bool HasLensEffect()
{
	return bHasLens;
}


/*----------------------------------------------------------
	Firing methods
----------------------------------------------------------*/

/*--- Trace start ---*/
simulated function vector InstantFireStartTrace()
{
	return GetEffectLocation();
}


/*--- Trace end ---*/
simulated function vector InstantFireEndTrace(vector StartTrace)
{
	local rotator rot;
	local vector loc;
	
	if (!SkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation(EffectSockets[0], loc, rot))
		`log("DVW > GetSocketWorldLocationAndrotation InstantFireEndTrace failed ");
	
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
		DVPlayerController(DVPawn(Owner).Controller).ServerRegisterShot();
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
	
	// Addons
	if (Addon1 != None)
		Addon1.FireAmmo();
	if (Addon2 != None)
		Addon2.FireAmmo();
	
	// Logging
	AmmoCount -= 1;
	PC.RegisterShot();
	P.ServerLogAction("SHOOT");
	
	// Firing
	PlayFiringSound();
	SkeletalMeshComponent(Mesh).PlayAnim(WeaponFireAnim);
	if (!(HasLensEffect() && bZoomed))
		P.GunRecoilNode.bPlayRecoil = true;
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
simulated function PlayFiringEffects(vector HitLocation)
{
	if (!bSilenced && MuzzleFlashPSC != None)
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
		HitActor = Trace(NewHitLoc, HitNormal, (HitLocation - (HitNormal * 32)), 
			HitLocation + (HitNormal * 32),
			true,, HitInfo, TRACEFLAG_Bullet);
		if(Pawn(HitActor) != none)
		{
			CheckHitInfo(HitInfo, Pawn(HitActor).Mesh, -HitNormal, NewHitLoc);
		}
		
		// Sound effects
		if (HitInfo.PhysMaterial != None)
		{
			if (HitInfo.PhysMaterial.ImpactSound != None)
				PlaySound(HitInfo.PhysMaterial.ImpactSound, false, true, false, HitLocation);
		}
		
		// Particle system template
		if ( HitActor != None && (Pawn(HitActor) == None || Vehicle(HitActor) != None) 
		 && (ImpactEffect.ParticleTemplate != None))
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
			`log("DVW > GetSocketWorldLocationAndrotation GetEffectLocation failed");
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
	if (bSilenced && SilencedWeaponSound != None)
	{
			MakeNoise(1.0);
			PlaySound(SilencedWeaponSound, false, true, false, Owner.Location);
	}
	else if (CurrentFireMode<WeaponFireSnd.Length)
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


/*--- Texture icon ---*/
function static string GetIcon()
{
	return "img://" $ default.WeaponIconPath $ ".Icon." $ default.WeaponIcon;
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
	Spread(0)=0.0
	Spread(1)=0.0

	// User settings
	WeaponModuleName="DeepVoid"
	TickDivisor=5
	ZoomedFOV=60
	ZoomSocket=Mount2
	ZoomSensitivity=0.3
	SmoothingFactor=0.7
	ZoomOffset=(X=0,Y=0,Z=1.0)
	
	// Effects
	MuzzleFlashPSCTemplate=ParticleSystem'DV_CoreEffects.FX.PS_Flash'
	WeaponFireSnd[0]=None
	WeaponFireSnd[1]=None
	EffectSockets(0)=MF
	EffectSockets(1)=MF
	
	// Initialization
	OldPlayerAddonClass1=""
	OldPlayerAddonClass2=""
	OldPlayerAddonClass3=""
	bZoomed=false
	bHidden=false
	bWeaponEmpty=false
	bOnlyRelevantToOwner=false
	bOnlyDirtyReplication=false
}
