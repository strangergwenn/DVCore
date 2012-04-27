/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwenna�l ARBONA
 **/
 
class DVKillMarker extends Actor;

/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var (DVKillMarker) Color 			TextColor;
var (DVKillMarker) LinearColor 		ClearColor;
var (DVKillMarker) LinearColor 		LightColor;

var (DVKillMarker) float 			TextScale;
var (DVKillMarker) float			TextOffsetX;
var (DVKillMarker) float			TextOffsetY;
var (DVKillMarker) float			ExpirationTime;
var (DVKillMarker) float 			YawRotationRate;

var (DVKillMarker) ScriptedTexture 	CanvasTexture;
var (DVKillMarker) MaterialInstanceConstant MarkerMaterial;

var string				 			MarkerText1;
var string				 			MarkerText2;
var int 							MarkerMaterialIndex;
var name 							CanvasTextureParamName;

var MaterialInterface 				MarkerMaterialTemplate;
var editinline const 				StaticMeshComponent Mesh;
var editinline const 				StaticMeshComponent Mesh2;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if ( bNetDirty )
		MarkerText1, MarkerText2, LightColor, MarkerMaterial;
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Initial setup ---*/
function PostBeginPlay()
{
	super.PostBeginPlay();
	CanvasTexture = ScriptedTexture(class'ScriptedTexture'.static.Create(1024, 1024,, ClearColor));
	CanvasTexture.Render = OnRender;
	
	// Material setup
	if(MarkerMaterialTemplate != none)
	{
		MarkerMaterial = Mesh.CreateAndSetMaterialInstanceConstant(MarkerMaterialIndex);
		if(MarkerMaterial != none)
		{
			MarkerMaterial.SetParent(MarkerMaterialTemplate);
			if(CanvasTextureParamName != '')
				MarkerMaterial.SetTextureParameterValue(CanvasTextureParamName, CanvasTexture);
		}
	}
	SetTimer(ExpirationTime, false, 'RemoveMe');
}


/*--- Removal ---*/
simulated function RemoveMe()
{
	Destroy();
}


/*--- Text edit ---*/
function SetPlayerData(string P1, string P2, LinearColor NewLight)
{
	MarkerText1 = P1;
	MarkerText2 = P2;
	MarkerMaterial.SetVectorParameterValue('Color', NewLight);
}


/*--- Rendering method ---*/
function OnRender(Canvas C)
{	
	local float offset;
	
	offset = 0;
	C.SetOrigin(TextOffsetX, TextOffsetY);
	
	offset += DrawLine(C, MarkerText1, offset);
	offset += DrawLine(C, "KILLED BY", offset);
	offset += DrawLine(C, MarkerText2, offset);
	
	CanvasTexture.bNeedsUpdate = true;
}


/*--- Actual drawing logic ---*/
function float DrawLine(Canvas C, string text, int offset)
{
	local int Min;
	local Vector2D TextSize;
	local float LocalTextScale;
	
	// Scale
	Min = 10.0;
	LocalTextScale = 1.0;
	if (Len(text) >= Min)
		LocalTextScale = Min / Len(text);
	C.TextSize(text, TextSize.X, TextSize.Y);
	TextSize *= TextScale * LocalTextScale;
	
	// Draw
	C.SetPos(0, offset);
	C.SetDrawColorStruct(TextColor);
	C.DrawText(text,, TextScale * LocalTextScale, TextScale * LocalTextScale);
	return TextSize.Y;
}


/*--- Rotation logic ---*/
simulated event Tick(float DeltaTime)
{
	Local Rotator NewRotation;

	if(WorldInfo.NetMode != NM_DedicatedServer && (WorldInfo.TimeSeconds - LastRenderTime < 0.2) )
	{
		if (Mesh != None)
		{
			NewRotation = Mesh.Rotation;
			NewRotation.Yaw += DeltaTime * YawRotationRate;
			Mesh.SetRotation(NewRotation);
		}
		if (Mesh2 != None)
		{
			NewRotation = Mesh2.Rotation;
			NewRotation.Yaw += DeltaTime * YawRotationRate;
			Mesh2.SetRotation(NewRotation);
		}
	}
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Content
	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
   		StaticMesh=StaticMesh'GameEffects.Mesh.SM_DoubleSquare'
   		Translation=(Z=-10)
   		Scale=0.5
	End Object
	Mesh = StaticMeshComp1
	Components.Add(StaticMeshComp1)
	CanvasTextureParamName=CanvasTexture
	MarkerMaterialTemplate=Material'GameEffects.Material.M_DynamicText'
	
	// Symbol
	Begin Object class=StaticMeshComponent Name=StaticMeshComp2
   		Translation=(Z=100)
	End Object
	Mesh2 = StaticMeshComp2
	Components.Add(StaticMeshComp2)

	// Settings
	MarkerText1="<>"
	MarkerText2="<>"
	TextScale=4.5
	TextOffsetX=350.0
	TextOffsetY=150.0
	ClearColor=(R=0.0,G=0.0,B=0.0,A=0.0)
	TextColor=(R=255,G=255,B=255,A=255)
	LightColor=(R=255,G=255,B=255,A=255)
	
	ExpirationTime=25.0
	YawRotationRate=20000
	Physics=PHYS_Interpolating
}