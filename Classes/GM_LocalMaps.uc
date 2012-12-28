/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_LocalMaps extends GMenu
	placeable
	ClassGroup(DeepVoid)
	hidecategories(Collision, Physics, Attachment);


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Menu) const array<string>			IgnoredMaps;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var string								CurrentLevel;

var GButton								Launch;


/*----------------------------------------------------------
	Button callbacks
----------------------------------------------------------*/

/**
 * @brief Launch button
 * @param Reference				Caller actor
 */
delegate GoLaunch(Actor Caller)
{
	if (CurrentLevel != "")
	{
		ConsoleCommand("open" @CurrentLevel);
	}
}

/**
 * @brief Selection callback
 * @param Reference				Caller actor
 */
delegate GoSelect(Actor Caller)
{
	local GB_Map Temp;
	local GB_Map Ref;
	Ref = GB_Map(Caller);
	CurrentLevel = Ref.LevelName;
	
	foreach AllActors(class'GB_Map', Temp)
	{
		if (Temp != Ref && Temp.GetState())
		{
			Temp.SetState(false);
		}
	}
	
	if (Ref.GetState())
		Launch.Activate();
	else
		Launch.Deactivate();
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief UI setup
 */
simulated function SpawnUI()
{
	AddButton(Vect(-300,0,0), "Back", "Go to the previous menu", GoBack);
	Launch = AddButton(Vect(300,0,0), "Launch", "Launch the game", GoLaunch);
	Launch.Deactivate();
	UpdateMapList();
}

/**
 * @brief Tick event (thread)
 * @param DeltaTime			Time since last tick
 */
simulated event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	if (CurrentLevel == "")
	{
		Launch.Deactivate();
	}
}

/**
 * @brief Create a map list
 */
function UpdateMapList()
{
	local byte i, Count;
	local GButton Temp;
	local string TempMapName;
	local array<UDKUIResourceDataProvider> ProviderList;

	Count = 0;
	class'UDKUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UDKUIDataProvider_MapInfo', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		TempMapName = UDKUIDataProvider_MapInfo(ProviderList[i]).MapName;
		if (IsInArray(Caps(TempMapName), IgnoredMaps) == -1)
		{
			Temp = AddButton(
				Vect(0,0,100) + Count * Vect(0,0,50), 
				TempMapName,
				"Launch level"@TempMapName, 
				GoSelect,
				class'GB_Map'
			);
			GB_Map(Temp).SetLevel(TempMapName, "");
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
	IgnoredMaps=("LD","FX","AMB","ART","FX","PROPS","LIGHTS","DECALS","ENVIRO","ENVIRONMENT","DEFAULTMAP")
}
