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

var DynamicLightEnvironmentComponent LightEnvironment;


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
}


/*----------------------------------------------------------
	States
----------------------------------------------------------*/

auto state Pickup
{
	function SpawnCopyFor(Pawn P)
	{
		PlaySound(PickupSound, false, true);
	}
	
	function bool ValidTouch(Pawn Other)
	{
		local DVPlayerController PC;
		
		if (Other == None)
		{
			return false;
		}
		else if (Other.Controller == None)
		{
			SetTimer( 0.2, false, nameof(RecheckValidTouch) );
			return false;
		}
		else
		{
			PC = DVPlayerController(Other.Controller);
			return (PC.GetAmmoCount() != PC.GetAmmoMax());
		}
	}
	
	event BeginState(name PreviousStateName)
	{
		TriggerEventClass(class'SeqEvent_PickupStatusChange', None, 0);
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
