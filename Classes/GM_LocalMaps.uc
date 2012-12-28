/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_LocalMaps extends GListMenu
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics, Attachment);


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
	local byte i, Count;
	local GButton Temp;
	local string TempData;
	local array<UDKUIResourceDataProvider> ProviderList;

	Count = 0;
	class'UDKUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UDKUIDataProvider_MapInfo', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		TempData = UDKUIDataProvider_MapInfo(ProviderList[i]).MapName;
		if (IsInArray(Caps(TempData), IgnoreList) == -1)
		{
			Temp = AddButton(
				ListOffset + Count * ScrollOffset, 
				TempData,
				"Launch level"@TempData, 
				GoSelect,
				ListItemClass
			);
			GListItem(Temp).SetData(TempData, "");
			Count++;
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
	ListItemClass=class'GListItem'
	IgnoreList=("LD","FX","AMB","ART","FX","PROPS","LIGHTS","DECALS","ENVIRO","ENVIRONMENT","DEFAULTMAP")
}
