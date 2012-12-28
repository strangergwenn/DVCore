/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GB_Map extends GToggleButton
	placeable;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Button) string						LevelName;
var (Button) string						LevelPictureName;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Setup the button
 * @param Path					Level path
 * @param PicPath				Texture path
 */
simulated function SetLevel(string Path, string PicPath)
{
	LevelName = Path;
	LevelPictureName = PicPath;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Mesh
	Begin Object Name=LabelMesh
		StaticMesh=StaticMesh'DV_UI.Mesh.SM_Label'
		Rotation=(Yaw=32768)
	End Object
	
	// Effects
	Effect=None
	TextOffsetX=30.0
	TextOffsetY=30.0
}
