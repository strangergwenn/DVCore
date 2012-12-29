/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GB_Clean extends GToggleButton
	placeable;


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Begin Object Name=LabelMesh
		StaticMesh=StaticMesh'DV_UI.Mesh.SM_SimpleLabel'
		Scale=0.8
	End Object
	
	Effect=None
	TextScale=5.0
	TextOffsetX=30.0
	TextOffsetY=25.0
	TextMaterialTemplate=Material'DV_UI.Material.M_EmissiveLabel'
}
