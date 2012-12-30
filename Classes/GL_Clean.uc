/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GL_Clean extends GLabel
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
	
	TextScale=3.0
	TextOffsetX=40.0
	TextOffsetY=30.0
	TextMaterialTemplate=Material'DV_UI.Material.M_EmissiveLabel'
}
