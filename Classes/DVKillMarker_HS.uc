/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/
 
class DVKillMarker_HS extends DVKillMarker;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var (DVKillMarker) MaterialInstanceConstant 	MarkerMaterial2;
var MaterialInterface 						HeadshotMaterialTemplate;

replication
{
	if (bNetDirty)
		MarkerMaterial2;
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/


/*--- Initial setup ---*/
function PostBeginPlay()
{
	super.PostBeginPlay();
	if(MarkerMaterialTemplate != none)
	{
		MarkerMaterial2 = Mesh2.CreateAndSetMaterialInstanceConstant(MarkerMaterialIndex);
		if(MarkerMaterial2 != none)
			MarkerMaterial2.SetParent(HeadshotMaterialTemplate);
	}
}

/*--- Text edit ---*/
function SetPlayerData(string P1, string P2, LinearColor NewLight)
{
	Super.SetPlayerData(P1, P2, NewLight);
	MarkerMaterial2.SetVectorParameterValue('Color', NewLight);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Begin Object Name=StaticMeshComp2
   		StaticMesh=StaticMesh'DV_CoreEffects.Mesh.SM_Headshot'
   		Scale=0.2
	End Object
	HeadshotMaterialTemplate=Material'DV_CoreEffects.Material.M_Headshot'
}
