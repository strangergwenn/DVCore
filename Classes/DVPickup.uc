/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVPickup extends UDKPickupFactory
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVPickup) const int				RespawnTime;
var (DVPickup) const SoundCue			PickupSound;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var DynamicLightEnvironmentComponent 	LightEnvironment;
var PointLightComponent 				FlagLight;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if (bNetDirty)
		FlagLight;
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Taken directly from Actor.uc since it overrides PickupFactory.uc ---*/
simulated event SetInitialState()
{
	bScriptInitialized = true;
	if( InitialState!='' )
		GotoState( InitialState );
	else
		GotoState( 'Auto' );
}


/*--- Rotation logic ---*/
simulated event Tick(float DeltaTime)
{
	Local Rotator NewRotation;

	if(WorldInfo.NetMode != NM_DedicatedServer && (WorldInfo.TimeSeconds - LastRenderTime < 0.2) )
	{
		if (PickupMesh != None)
		{
			NewRotation = PickupMesh.Rotation;
			NewRotation.Yaw += DeltaTime * YawRotationRate;
			PickupMesh.SetRotation(NewRotation);
		}
	}
}

/*--- Respawn time ---*/
function float GetRespawnTime()
{
	return RespawnTime;
}

function SetRespawn()
{
	StartSleeping();
}


/*--- Mesh ---*/
simulated function InitializePickup()
{
	SetPickupMesh();
	PickupMesh.SetLightEnvironment(LightEnvironment);
}

simulated function SetPickupMesh()
{
	AttachComponent(PickupMesh);
	SetPickupVisible();
	FlagLight.SetEnabled(true);
}


/*----------------------------------------------------------
	States
----------------------------------------------------------*/

auto state Pickup
{
	simulated function SpawnCopyFor(Pawn P)
	{
		PlaySound(PickupSound, false, true);
		FlagLight.SetEnabled(false);
	}
	
	simulated function bool ValidTouch(Pawn Other)
	{
		return true;
	}
	
	simulated event BeginState(name PreviousStateName)
	{
		TriggerEventClass(class'SeqEvent_PickupStatusChange', None, 0);
		FlagLight.SetEnabled(true);
	}
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
    // Lighting
 	Begin Object Class=DynamicLightEnvironmentComponent Name=PickupLightEnvironment
		bEnabled=true
 	    bDynamic=true
 	    bCastShadows=false
 	End Object
  	LightEnvironment=PickupLightEnvironment
  	Components.Add(PickupLightEnvironment)
  	
	// Ambient light
	Begin Object class=PointLightComponent name=DynLightComponent
		Brightness=20.0
		LightColor=(R=250,G=140,B=10)
		Radius=140.0
		bEnabled=true
		CastShadows=false
		bRenderLightShafts=false
		bForceDynamicLight=true
		LightingChannels=(Dynamic=true,CompositeDynamic=true)
	End Object
	FlagLight=DynLightComponent
	Components.Add(DynLightComponent)
	
 	// Mesh
	Begin Object Class=StaticMeshComponent Name=BaseMeshComp
		LightEnvironment=PickupLightEnvironment
		CollideActors=false
		CastShadow=false
		bCastDynamicShadow=false
		bAcceptsLights=true
		bForceDirectLightMap=true
	End Object
	PickupMesh=BaseMeshComp
	Components.Add(BaseMeshComp)
	CollisionComponent=CollisionCylinder
	
	// Settings
	YawRotationRate=16384
	bRotatingPickup=true
	bMovable=false
    bStatic=false
}
