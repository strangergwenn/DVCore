/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GLabel extends Actor
	placeable;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Label) bool					bEnabled;

var (Label) string					Text;
var (Label) string					Comment;

var (Label) const float 			TextScale;
var (Label) const float				TextOffsetX;
var (Label) const float				TextOffsetY;

var (Label) const vector			ClickMove;

var (Label) const color 			TextColor;
var (Label) const LinearColor 		TextClearColor;
var (Label) const LinearColor		OnLight;
var (Label) const LinearColor		OffLight;

var (Label) MaterialInstanceConstant TextMaterial;

var (Label) const SoundCue 			OverSound;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var bool							bOver;
var bool							bLastOver;
var bool							bTickEnabled;

var ScriptedTexture					CanvasTexture;
var MaterialInterface 				TextMaterialTemplate;

var editinline const StaticMeshComponent Mesh;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Set the label data and activates it
 * @param T					Text to display
 * @param C					Comment to display
 */
simulated function Set(string T, string C)
{
	Text = T;
	Comment = C;
	bEnabled = true;
	
	CanvasTexture = ScriptedTexture(class'ScriptedTexture'.static.Create(1024,1024,,TextClearColor));
	CanvasTexture.Render = OnRender;
	if (TextMaterialTemplate != None)
	{
		TextMaterial = Mesh.CreateAndSetMaterialInstanceConstant(0);
		if (TextMaterial != None)
		{
			TextMaterial.SetParent(TextMaterialTemplate);
			TextMaterial.SetTextureParameterValue('CanvasTexture', CanvasTexture);
			TextMaterial.SetVectorParameterValue('Color', OnLight);
		}
	}
}

/**
 * @brief Enable the label
 */
simulated function Activate()
{
	bEnabled = true;
	TextMaterial.SetVectorParameterValue('Color', OnLight);
}

/**
 * @brief Disable the label
 */
simulated function Deactivate()
{
	bEnabled = false;
	TextMaterial.SetVectorParameterValue('Color', OffLight);
}

/**
 * @brief Signal an over event from HUD
 */
simulated function Over()
{
	if (bEnabled)
	{
		bOver = true;
	}
}

/**
 * @brief Entering over state
 */
simulated function OverIn()
{
	MoveSmooth((-ClickMove) >> Rotation);
	GMenu(Owner).SetLabel(Comment);
	PlayUISound(OverSound);
}


/**
 * @brief Exiting over state
 */
simulated function OverOut()
{
	MoveSmooth(ClickMove >> Rotation);
	GMenu(Owner).SetLabel("");
}

/**
 * @brief Called when the focus is lost (click etc)
 */
simulated function LostFocus()
{
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	Set(""$self, "I am a label");
}

/**
 * @brief Rendering method
 */
function OnRender(Canvas C)
{	
	C.SetOrigin(TextOffsetX, TextOffsetY);
	C.SetPos(0, 0);
	C.SetDrawColorStruct(TextColor);
	C.DrawText(Text,, TextScale, TextScale);
	CanvasTexture.bNeedsUpdate = true;
}

/**
 * @brief Tick event (thread)
 * @param DeltaTime			Time since last tick
 */
simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	
	if (bTickEnabled)
	{
		if (bLastOver)
		{
			if (!bOver)
			{
				OverOut();
			}
		}
		else if (bOver)
		{
			OverIn();
			bTickEnabled = false;
			SetTimer(0.5, false, 'EnableTick');
		}
		bLastOver = bOver;
		bOver = false;
	}
}

/**
 * @brief Enable the tick back
 */
simulated function EnableTick()
{
	bTickEnabled = true;
}

/**
 * @brief Play a sound
 * @param sound					Sound to play
 **/
function PlayUISound(SoundCue Sound)
{
	local PlayerController PC;
	PC = GetALocalPlayerController();
	
	if (PC != None && Sound != None)
	{
		PC.PlaySound(Sound);
	}
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
	Begin Object Class=StaticMeshComponent Name=LabelMesh
		LightEnvironment=MyLightEnvironment
		StaticMesh=StaticMesh'DV_UI.Mesh.SM_Label'
		Rotation=(Yaw=32768)
	End Object
	Mesh=LabelMesh
	Components.Add(LabelMesh)
	CollisionComponent=LabelMesh
	
	// Text
	TextMaterialTemplate=Material'DV_UI.Material.M_Label'
	TextScale=4.5
	TextOffsetX=30.0
	TextOffsetY=30.0
	TextClearColor=(R=0.0,G=0.0,B=0.0,A=0.0)
	TextColor=(R=255,G=255,B=255,A=255)
	
	// Behaviour
	bOver=false
	bTickEnabled=true
	OnLight=(R=5.0,G=0.3,B=0.0,A=1.0)
	OffLight=(R=0.1,G=0.1,B=0.1,A=1.0)
	
	// Physics
	bEdShouldSnap=true
	bCollideActors=true
	bCollideWorld=true
	bBlockActors=true
}
