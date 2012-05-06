/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVCoreUI_Menu extends DVMovie;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (CoreUI) const array<string>		IgnoredMaps;
var (CoreUI) const string				ServerURL;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GFxClikWidget						LaunchButtonMC;
var GFxClikWidget						LaunchMultiMC;
var GFxClikWidget 						MapListMC;

var GFxObject 							ListDataProvider;
var array<UDKUIDataProvider_MapInfo> 	MapList;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Language settings ---*/
function bool Start(optional bool StartPaused = false)
{
	super.Start();
	SetLabel("MenuTitle", "Menu principal", true);
	return true;
}


/*--- Map list ---*/
function UpdateListDataProvider()
{
	local byte 			i;
	local string 		TempMapName;
	local GFxObject 	TempObj;
	local GFxObject 	DataProvider;
	local array<UDKUIResourceDataProvider> ProviderList;

	// Checking data
	class'UDKUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UDKUIDataProvider_MapInfo', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		TempMapName = UDKUIDataProvider_MapInfo(ProviderList[i]).MapName;
		if (!IsInArray(TempMapName, IgnoredMaps)) 
			MapList.AddItem(UDKUIDataProvider_MapInfo(ProviderList[i]));
	}
	
	// Sending data to menu
	DataProvider = MapListMC.GetObject("dataProvider");
	for (i = 0; i < MapList.Length; i++)
	{
		TempObj = CreateObject("Object");
		TempObj.SetString("label", Caps((MapList[i]).MapName));
		DataProvider.SetElementObject(i, TempObj);
	}
	MapListMC.SetObject("dataProvider", DataProvider);
	MapListMC.SetFloat("rowCount", i);
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- Initialization ---*/
event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch(WidgetName)
	{
		case ('MapList'):
			MapListMC = GetLiveWidget(Widget, 'CLIK_itemClick', OnListItemClick);
			UpdateListDataProvider();	
			break;

		case ('LaunchMap') :
			LaunchButtonMC = GetLiveWidget(Widget, 'CLIK_click', OpenMap);
			break;

		case ('LaunchMulti') :
			LaunchMultiMC = GetLiveWidget(Widget, 'CLIK_click', OpenServ);
			break;
			
		default:
			return super.WidgetInitialized(Widgetname, WidgetPath, Widget);
	}
	return true;
}


/*----------------------------------------------------------
	Click events
----------------------------------------------------------*/

function OnListItemClick(GFxClikWidget.EventData ev)
{
	/* Disabled for secondary button but working
    local GFxObject button;
    button = ev._this.GetObject("target");
	ConsoleCommand("open " $ button.GetString("name"));
	*/
}

function OpenMap(GFxClikWidget.EventData evtd)
{
	ConsoleCommand("open " $ (MapList[MapListMC.GetFloat("selectedIndex")]).MapName);
}

function OpenServ(GFxClikWidget.EventData evtd)
{
	ConsoleCommand("open " $ ServerURL);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	IgnoredMaps=("LD","FX","AMB","ART","DefaultMap")
	ServerURL="deepvoid.eu"
	
	WidgetBindings(1)={(WidgetName="MapList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(2)={(WidgetName="LaunchMap",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(3)={(WidgetName="LaunchMulti",WidgetClass=class'GFxClikWidget')}
}
