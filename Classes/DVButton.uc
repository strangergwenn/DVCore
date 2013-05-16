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

var (Button) MaterialInstanceConstant	ButtonMaterial;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var StaticMeshComponent					Mesh;
var MaterialInstanceConstant			CurrentButtonMaterial;


/*----------------------------------------------------------
	Display code
----------------------------------------------------------*/

/*--- Startup ---*/
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	CurrentButtonMaterial = Mesh.CreateAndSetMaterialInstanceConstant(0);
	if (CurrentButtonMaterial != None)
	{
		CurrentButtonMaterial.SetParent(ButtonMaterial);
	}
}


/*--- Activate button : ready to use ---*/
simulated function Activate()
{
	if (!bIsActivated)
	{
		`log("DVB > Activate");
		SetCollisionType(COLLIDE_NoCollision);
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
	SetCollisionType(COLLIDE_BlockAll);
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
		StaticMesh=StaticMesh'Grounds.Mesh.ST_GROUNDS_Pl-001'
		Rotation=(Pitch=32768,Yaw=-16384,Roll=-16384)
		Translation=(Z=25)
		Scale=0.2
	End Object
	Mesh=MyStaticMeshComponent
 	Components.Add(MyStaticMeshComponent)
	CollisionComponent=MyStaticMeshComponent
	ButtonMaterial=MaterialInstanceConstant'DV_Spacegear.Material.MI_TargetManager-Hol'
	
	// Physics
	bEdShouldSnap=true
	bCollideActors=true
	bCollideWorld=true
	bBlockActors=true
	bPathColliding=true
}
