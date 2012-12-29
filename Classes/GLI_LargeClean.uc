/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GLI_LargeClean extends GListItem
	placeable;


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Begin Object Name=LabelMesh
		StaticMesh=StaticMesh'DV_UI.Mesh.SM_SimpleLabel'
		Scale=2.5
	End Object
	
	Effect=None
	TextScale=1.5
	TextOffsetX=30.0
	TextOffsetY=25.0
	TextMaterialTemplate=Material'DV_UI.Material.M_EmissiveLabel'
}
