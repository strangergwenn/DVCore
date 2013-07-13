/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVMapInfo extends UDKMapInfo;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVGame) const SoundCue				MusicIntro;
var (DVGame) const SoundCue				MusicLoop;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Get a map icon
 * @param LevelName				Level name
 * @return Texture to use
 */
static function Texture2D GetTextureFromLevel(string LevelName)
{
	switch (LevelName)
	{
		case "LEVEL_00_TRAINING" :
			return Texture2D'DV_UI.Textures.LEVEL_00';
			break;
		case "LEVEL_01" :
			return Texture2D'DV_UI.Textures.LEVEL_01';
			break;
		case "LEVEL_02" :
			return Texture2D'DV_UI.Textures.LEVEL_02';
			break;
		case "LEVEL_03" :
			return Texture2D'DV_UI.Textures.LEVEL_03';
			break;
		default :
			return Texture2D'DV_UI.Textures.LEVEL_0x';	
	}
}
