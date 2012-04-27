/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVAmmunitionFactory extends UDKPickupFactory
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics);


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var (Ammunition) int			AmmoRechargeAmount;


/*----------------------------------------------------------
	States
----------------------------------------------------------*/

auto state Pickup
{
	function SpawnCopyFor( Pawn Recipient )
	{
		`log("SpawnCopyFor " $ Recipient);
		DVPawn(Recipient).AddWeaponAmmo(AmmoRechargeAmount);
	}
	
	function bool ValidTouch( Pawn Other )
	{
		if (Other == None)
		{
			return false;
		}
		else if (Other.Controller == None)
		{
			SetTimer( 0.2, false, nameof(RecheckValidTouch) );
			return false;
		}
		return true;
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
 	    bDynamic=true
 	    bCastShadows=true
 	End Object
	
 	// Mesh
	Begin Object Class=StaticMeshComponent Name=BaseMeshComp
		LightEnvironment=PickupLightEnvironment
		LightingChannels=(BSP=true,Dynamic=true,Static=true,CompositeDynamic=true)
		bForceDirectLightMap=true
		bCastDynamicShadow=false
		CollideActors=false
		bAcceptsLights=true
		CastShadow=false
		Translation=(Z=-50)
	End Object
	PickupMesh=BaseMeshComp
	Components.Add(BaseMeshComp)
	CollisionComponent=CollisionCylinder
	
	// Gameplay
	AmmoRechargeAmount=50
	InventoryType=class'UTGameContent.UTJumpBoots'
	
	// Settings
	YawRotationRate=32768
	bRotatingPickup=true
	bMovable=false
    bStatic=false
}
