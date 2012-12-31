/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GLI_Small extends GListItem
	placeable;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Setup the button picture
 * @param PicPath				Texture path
 */
simulated function SetPicture(Texture2D PicPath)
{
}


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
	OnLight=(R=1.5,G=0.3,B=0.0,A=1.0)
	OffLight=(R=1.5,G=0.3,B=0.0,A=1.0)
	TextMaterialTemplate=Material'DV_UI.Material.M_EmissiveLabel'
}
