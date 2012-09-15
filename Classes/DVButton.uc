/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVButton extends Actor
	HideCategories(Display,Collision,Physics)
	ClassGroup(DeepVoid)
	placeable;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Button) SoundCue					SoundOnActivate;
var (Button) SoundCue					SoundOnDeActivate;

var (Button) bool						bIsActivated;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var StaticMeshComponent					Mesh;


/*----------------------------------------------------------
	Display code
----------------------------------------------------------*/

/*--- Activate button : ready to use ---*/
simulated function Activate()
{
	if (!bIsActivated)
	{
		`log("DVB > Activate");
		if (SoundOnActivate != None)
		{
			PlaySound(SoundOnActivate);
		}
		bIsActivated = true;
	}
}


/*--- Activate ---*/
simulated function DeActivate()
{
	`log("DVB > DeActivate");
	if (SoundOnDeActivate != None)
	{
		PlaySound(SoundOnDeActivate);
	}
	bIsActivated = false;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	//Gameplay
	SoundOnActivate=SoundCue'DV_Sound.UI.A_Bip'
	SoundOnDeActivate=SoundCue'DV_Sound.UI.A_Bip'
	
	// Light
	Begin Object class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
		bDynamic=true
	End Object
	Components.Add(MyLightEnvironment)

	// Mesh
	Begin Object class=StaticMeshComponent Name=MyStaticMeshComponent
		LightEnvironment=MyLightEnvironment
		BlockActors=true
		BlockZeroExtent=true
		BlockRigidBody=true
		BlockNonzeroExtent=true
		CollideActors=true
		StaticMesh=StaticMesh'DV_Spacegear.Mesh.SM_TargetManager'
	End Object
	Mesh=MyStaticMeshComponent
 	Components.Add(MyStaticMeshComponent)
	CollisionComponent=MyStaticMeshComponent
	
	// Physics
	bEdShouldSnap=true
	bCollideActors=true
	bCollideWorld=true
	bBlockActors=true
	bPathColliding=true
}
