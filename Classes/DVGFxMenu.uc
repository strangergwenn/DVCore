/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVGFxMenu extends GFxMoviePlayer;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var GFxObject 			MenuTitleMC;
var GFxClikWidget 		ExitButtonMC;
var GFxClikWidget		LaunchButtonMC;
var GFxClikWidget		LaunchMultiMC;
var GFxClikWidget 		MapListMC;

var GFxObject 			ListDataProvider;
var array<UDKUIDataProvider_MapInfo> MapList;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

function bool Start(optional bool StartPaused = false)
{
	super.Start();
	Advance(0);
	
	MenuTitleMC = GetVariableObject("_root.MenuTitle");
	MenuTitleMC.SetText("MENU PRINCIPAL");
	
	return true;
}

event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch(WidgetName)
	{
		case ('MapList'):
			MapListMC = GFxClikWidget(Widget);
			UpdateListDataProvider();
			
			MapListMC.AddEventListener('CLIK_itemClick', OnListItemClick);
			break;

		case ('ExitButton') :
			ExitButtonMC = GFxClikWidget(Widget);
			ExitButtonMC.AddEventListener('CLIK_click', OnExit);
			break;

		case ('LaunchMap') :
			LaunchButtonMC = GFxClikWidget(Widget);
			LaunchButtonMC.AddEventListener('CLIK_click', OpenMap);
			break;

		case ('LaunchMulti') :
			LaunchMultiMC = GFxClikWidget(Widget);
			LaunchMultiMC.AddEventListener('CLIK_click', OpenServ);
			break;
			
		default: return Super.WidgetInitialized(Widgetname, WidgetPath, Widget);
	}
	return true;
}

function OnListItemClick(GFxClikWidget.EventData ev)
{
	MapListMC.SetFloat("selectedIndex", ev.index);
}

function OpenMap(GFxClikWidget.EventData evtd)
{
	ConsoleCommand("open " $ (MapList[MapListMC.GetFloat("selectedIndex")]).MapName);
}

function OpenServ(GFxClikWidget.EventData evtd)
{
	ConsoleCommand("open deepvoid.eu");
}

function OnExit(GFxClikWidget.EventData evtd)
{
	ConsoleCommand("exit");
}

function UpdateListDataProvider()
{
	local byte i;
	local string TempMapName;
	local GFxObject TempObj;
	local GFxObject DataProvider;
	local array<UDKUIResourceDataProvider> ProviderList;

	// Data parsing
	class'UDKUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UDKUIDataProvider_MapInfo', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		TempMapName = UDKUIDataProvider_MapInfo(ProviderList[i]).MapName;
		if ((InStr(TempMapName, "LD",			true) == -1)
		 && (InStr(TempMapName, "FX",			true) == -1)
		 && (InStr(TempMapName, "AMB",			true) == -1)
		 && (InStr(TempMapName, "ART",			true) == -1)
		 && (InStr(TempMapName, "DefaultMap",	true) == -1))
		{
			MapList.AddItem(UDKUIDataProvider_MapInfo(ProviderList[i]));
		}
	}
	
	// Actual menu setting
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
	Properties
----------------------------------------------------------*/

defaultproperties
{
	WidgetBindings(0)={(WidgetName="ExitButton",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(1)={(WidgetName="MapList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(2)={(WidgetName="LaunchMap",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(3)={(WidgetName="LaunchMulti",WidgetClass=class'GFxClikWidget')}
}
