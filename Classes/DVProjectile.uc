/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVProjectile extends UDKProjectile
	abstract;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var bool 						bSuppressExplosionFX;
var bool						bAdvanceExplosionEffect;

var float 						DurationOfDecal;
var float 						MaxEffectDistance;
var float 						GlobalCheckRadiusTweak;
var float 						DecalWidth, DecalHeight;

var SoundCue					ExplosionSound;

var ParticleSystemComponent		ProjEffects;
var ParticleSystem 				ProjFlightTemplate;
var ParticleSystem 				ProjExplosionTemplate;

var MaterialInterface 			ExplosionDecal;

var PointLightComponent 		ProjectileLight;
var class<PointLightComponent>	ProjectileLightClass;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Light management ---*/
simulated event CreateProjectileLight()
{
	ProjectileLight = new(self) ProjectileLightClass;
	AttachComponent(ProjectileLight);
}


/*--- Hit ---*/
simulated event Landed(vector HitNormal, actor FloorActor)
{
	HitWall(HitNormal, FloorActor, None);
}


/*--- Flight effects ---*/
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if (WorldInfo.NetMode != NM_DedicatedServer && ProjFlightTemplate != None)
	{
		ProjEffects = WorldInfo.MyEmitterPool.SpawnEmitterCustomLifetime(ProjFlightTemplate);
		ProjEffects.SetAbsolute(false, false, false);
		ProjEffects.SetLODLevel(WorldInfo.bDropDetail ? 1 : 0);
		ProjEffects.OnSystemFinished = MyOnParticleSystemFinished;
		ProjEffects.bUpdateComponentInTick = true;
		AttachComponent(ProjEffects);
	}
}

simulated event SetInitialState()
{
	bScriptInitialized = true;
	if (Role < ROLE_Authority && AccelRate != 0.f)
	{
		GotoState('WaitingForVelocity');
	}
	else
	{
		GotoState((InitialState != 'None') ? InitialState : 'Auto');
	}
}


/*--- Setup speed and acceleration at shot ---*/
function Init(vector Direction)
{
	SetRotation(rotator(Direction));
	Velocity = Speed * Direction;
	Acceleration = AccelRate * Normal(Velocity);
	SetPhysics(PHYS_Falling);
}


/*--- Impact ---*/
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if (DamageRadius > 0)
	{
		if (!bShuttingDown)
		{
			ProjectileHurtRadius(HitLocation, HitNormal);
		}
	}
	Other.TakeDamage(Damage,InstigatorController,HitLocation,MomentumTransfer * Normal(Velocity), MyDamageType,, self);
	Shutdown();
}


/*--- Explosion effects ---*/
simulated function SpawnExplosionEffects(vector HitLocation, vector HitNormal)
{
	local vector Direction;
	local Actor EffectAttachActor;
	local ParticleSystemComponent ProjExplosion;

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		// Light effect
		if (ProjectileLight != None)
		{
			DetachComponent(ProjectileLight);
			ProjectileLight = None;
		}
		
		// Explosion effect
		if (ProjExplosionTemplate != None && EffectIsRelevant(Location, false, MaxEffectDistance))
		{
			EffectAttachActor = None;
			if (!bAdvanceExplosionEffect)
			{
				ProjExplosion = WorldInfo.MyEmitterPool.SpawnEmitter(ProjExplosionTemplate, HitLocation, rotator(HitNormal), EffectAttachActor);
			}
			else
			{
				Direction = normal(Velocity - 2.0 * HitNormal * (Velocity dot HitNormal)) * Vect(1,1,0);
				ProjExplosion = WorldInfo.MyEmitterPool.SpawnEmitter(ProjExplosionTemplate, HitLocation, rotator(Direction), EffectAttachActor);
				ProjExplosion.SetVectorParameter('Velocity',Direction);
				ProjExplosion.SetVectorParameter('HitNormal',HitNormal);
			}
		}

		// Sound
		if (ExplosionSound != None)
		{
			PlaySound(ExplosionSound, true);
		}
		bSuppressExplosionFX = true;
	}
}


/*--- End of flight ---*/
simulated function Shutdown()
{
	local MeshComponent MeshPart;
	local vector HitLocation, HitNormal;
	
	// Init
	bShuttingDown = true;
	SetPhysics(PHYS_None);
	HitNormal = normal(Velocity * -1);
	Trace(HitLocation,HitNormal,(Location + (HitNormal*-32)), Location + (HitNormal*32),true,vect(0,0,0));

	// Shutdown of various systems
	if (ProjEffects != None)
	{
		ProjEffects.DeactivateSystem();
	}
	if (WorldInfo.NetMode != NM_DedicatedServer && !bSuppressExplosionFX)
	{
		SpawnExplosionEffects(Location, HitNormal);
	}
	foreach ComponentList(class'MeshComponent', MeshPart)
	{
		MeshPart.SetHidden(true);
	}
	SetCollision(false,false);
	Destroy();
}


simulated function Destroyed()
{
	if (WorldInfo.NetMode != NM_DedicatedServer && !bSuppressExplosionFX)
	{
		SpawnExplosionEffects(Location, vector(Rotation) * -1);
	}

	if (ProjEffects != None)
	{
		DetachComponent(ProjEffects);
		WorldInfo.MyEmitterPool.OnParticleSystemFinished(ProjEffects);
		ProjEffects = None;
	}

	super.Destroyed();
}

simulated function MyOnParticleSystemFinished(ParticleSystemComponent PSC)
{
	if (PSC == ProjEffects)
	{
		DetachComponent(ProjEffects);
		WorldInfo.MyEmitterPool.OnParticleSystemFinished(ProjEffects);
		ProjEffects = None;
	}
}



/*--- Hit ETA ---*/
static final function float CalculateTravelTime(float Dist, float MoveSpeed, float MaxMoveSpeed, float AccelMag)
{
	local float ProjTime, AccelTime, AccelDist;

	if (AccelMag == 0.0)
	{
		return (Dist / MoveSpeed);
	}
	else
	{
		ProjTime = (-MoveSpeed + Sqrt(Square(MoveSpeed) - (2.0 * AccelMag * -Dist))) / AccelMag;
		AccelTime = (MaxMoveSpeed - MoveSpeed) / AccelMag;
		if (ProjTime > AccelTime)
		{
			AccelDist = (MoveSpeed * AccelTime) + (0.5 * AccelMag * Square(AccelTime));
			ProjTime = AccelTime + ((Dist - AccelDist) / MaxMoveSpeed);
		}
		return ProjTime;
	}
}

static simulated function float StaticGetTimeToLocation(vector TargetLoc, vector StartLoc, Controller RequestedBy)
{
	return CalculateTravelTime(VSize(TargetLoc - StartLoc), default.Speed, default.MaxSpeed, default.AccelRate);
}

simulated function float GetTimeToLocation(vector TargetLoc)
{
	return CalculateTravelTime(VSize(TargetLoc - Location), Speed, MaxSpeed, AccelRate);
}


/*--- Maximum check distance ---*/
simulated static function float GetRange()
{
	return 15000.0;
}


/*----------------------------------------------------------
	States
----------------------------------------------------------*/

state WaitingForVelocity
{
	simulated function Tick(float DeltaTime)
	{
		if (!IsZero(Velocity))
		{
			Acceleration = AccelRate * Normal(Velocity);
			GotoState((InitialState != 'None') ? InitialState : 'Auto');
		}
	}
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	DamageRadius=+0.0
	DurationOfDecal=24.0
	TerminalVelocity=3500.0
	CustomGravityScaling=1.0
	MaxEffectDistance=+10000.0
	
	bShuttingDown=false
	bCollideComplex=true
	bBlockedByInstigator=false
	bSwitchToZeroCollision=true
}

