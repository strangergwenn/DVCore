/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVWeaponAddon extends Actor;


/*----------------------------------------------------------
	Public attributes : new properties for attached weapons
----------------------------------------------------------*/

var (Addon) vector			ZoomOffset;

var (Addon) float			SmoothingFactor;
var (Addon) float 			ZoomSensitivity;
var (Addon) float 			ZoomedFOV;

var (Addon) float			PrecisionBonus;
var (Addon) float			FireRateBonus;
var (Addon) float			KineticBonus;
var (Addon) float			DamageBonus;
var (Addon) float			AmmoBonus;

var (Addon) byte			SocketID;

var (Addon) bool			bUseLens;
var (Addon) bool			bSilenced;
var (Addon) bool			bLongRail;
var (Addon) bool			bCannonMount;

var (Addon) DVWeapon		Weap;

var (Addon) Texture2D		Icon;
var (Addon) string			IconPath;


/*----------------------------------------------------------
	Localized attributes
----------------------------------------------------------*/

var (Addon) localized string lAddonName;
var (Addon) localized string lAddonL1;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var StaticMeshComponent 	Mesh;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Get the socket name ---*/
simulated function name MountSocket()
{
	return name("Mount" $SocketID);
}


/*--- Weapon attachment ---*/
simulated function AttachToWeapon(DVWeapon wp)
{
	if (MountSocket() == '' || Mesh == None || SkeletalMeshComponent(wp.Mesh) == None)
		return;
	
	// Mesh
	AttachComponent(Mesh);
	Mesh.SetShadowParent(wp.Mesh);
	Mesh.SetLightEnvironment(wp.Mesh.LightEnvironment);
	SkeletalMeshComponent(wp.Mesh).AttachComponentToSocket(Mesh, MountSocket());
	Weap = wp;
	
	// Properties override
	if (SmoothingFactor != 0.0)
		wp.SmoothingFactor = SmoothingFactor;
	if (ZoomSensitivity != 0.0)
		wp.ZoomSensitivity = ZoomSensitivity;
	if (ZoomedFOV != 0.0)
		wp.ZoomedFOV = ZoomedFOV;
	if (ZoomOffset != vect(0,0,0))
	{
		wp.ZoomSocket = MountSocket();
		wp.ZoomOffset = ZoomOffset;
	}
	
	// Lens override
	if (bUseLens && !wp.bHasLens)
		wp.bHasLens = true;
	
	// Silencer
	if (bSilenced && !wp.bSilenced)
		wp.bSilenced = true;
	
	// Bonus
	if (AmmoBonus != 0.0)
		wp.MaxAmmo *= AmmoBonus;
	if (DamageBonus != 0.0)
		wp.InstantHitDamage[0] *= DamageBonus;
	if (FireRateBonus != 0.0)
		wp.FireInterval[0] /= FireRateBonus;
	if (KineticBonus != 0.0)
		wp.InstantHitMomentum[0] *= KineticBonus;
	if (PrecisionBonus != 0.0)
	{
		wp.Spread[0] /= PrecisionBonus;
	}
		
	
	`log("DVWA > Mounted add-on" @self);
}


/*--- Destroying ---*/
simulated function DetachFromWeapon(DVWeapon wp)
{
	// Mesh
	if (Mesh != None)
	{
		Mesh.SetShadowParent(None);
		Mesh.SetLightEnvironment(None);
		Mesh.SetHidden(true);
		
		if (wp.Mesh != None)
			SkeletalMeshComponent(wp.Mesh).DetachComponent(Mesh);
	}
	
	// Properties override
	if (SmoothingFactor != 0.0)
		wp.SmoothingFactor = wp.default.SmoothingFactor;
	if (ZoomSensitivity != 0.0)
		wp.ZoomSensitivity = wp.default.ZoomSensitivity;
	if (ZoomedFOV != 0.0)
		wp.ZoomedFOV = wp.default.ZoomedFOV;
	if (ZoomOffset != vect(0,0,0))
	{
		wp.ZoomOffset = wp.default.ZoomOffset;
	}
	wp.bSilenced = false;
	wp.bHasLens = false;
	
	// Bonus
	if (AmmoBonus != 0.0)
		wp.MaxAmmo /= AmmoBonus;
	if (DamageBonus != 0.0)
		wp.InstantHitDamage[0] /= DamageBonus;
	if (FireRateBonus != 0.0)
		wp.FireInterval[0] *= FireRateBonus;
	
	// Ending
	`log("DVWA > Removed add-on" @self);
	Destroy();
}


/*--- Called when firing ammos ---*/
simulated function FireAmmo()
{}


/*--- Is addon activated ---*/
reliable client simulated function bool UseAddon()
{
	local DVPawn P;
	if (Weap != None)
	{
		P = DVPawn(Weap.Owner);
		if (P != None)
			return P.GetAddonStatus();
	}
	return true;
}


/*--- Texture icon ---*/
function static string GetIcon()
{
	return "img://" $ default.IconPath $ ".Icon." $ default.Icon;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Lighting
	Begin Object class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
		bDynamic=true
	End Object
	Components.Add(MyLightEnvironment)
	
	// Mesh
	Begin Object Class=StaticMeshComponent Name=AddonMesh
		LightEnvironment=MyLightEnvironment
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOnlyOwnerSee=false
	End Object
	Mesh=AddonMesh
	Components.Add(AddonMesh)
	
	// Properties
	SmoothingFactor=0.0
	ZoomSensitivity=0.0
	FireRateBonus=0.0
	DamageBonus=0.0
	ZoomedFOV=0.0
	AmmoBonus=0.0
	bUseLens=false
	bSilenced=false
	bLongRail=true
	bCannonMount=true
}
