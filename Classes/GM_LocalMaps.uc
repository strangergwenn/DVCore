/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_LocalMaps extends GListMenu;


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Launch button
 * @param Reference				Caller actor
 */
delegate GoLaunch(Actor Caller)
{
	if (CurrentData != "")
	{
		ConsoleCommand("open" @CurrentData);
	}
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Create a map list
 */
function UpdateList()
{
	local byte i;
	local GButton Temp;
	local string TempData;
	local Texture2D MapPicture;
	local array<UDKUIResourceDataProvider> ProviderList;

	class'UDKUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UDKUIDataProvider_MapInfo', ProviderList);
	for (i = 0; i < ProviderList.Length; i++)
	{
		TempData = UDKUIDataProvider_MapInfo(ProviderList[i]).MapName;
		if (IsInArray(Caps(TempData), IgnoreList) == -1
		 && Caps(TempData) == TempData)
		{
			MapPicture = class'DVMapInfo'.static.GetTextureFromLevel(TempData);
			Temp = AddButton(
				ListOffset + ListCount * ScrollOffset, 
				TempData,
				"Launch level"@TempData, 
				GoSelect,
				ListItemClass
			);
			GListItem(Temp).SetData(TempData);
			GListItem(Temp).SetPicture(MapPicture);
			ListCount++;
		}
	}
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	Index=2000
	MenuName="Local games"
	MenuComment="Try out levels"
	ListOffset=(X=0,Y=-50,Z=30)
	ScrollOffset=(X=0,Y=0,Z=90)
	IgnoreList=("LD","FX","AMB","ART","FX","PROPS","LIGHTS","DECALS","ENVIRO","ENVIRONMENT","DEFAULTMAP")
}
