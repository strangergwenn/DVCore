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
var (CoreUI) const array<string>		MenuListData;
var (CoreUI) const array<string>		ResListData;
var (CoreUI) const string				ServerURL;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

//var GFxClikWidget						LaunchButtonMC;
var GFxClikWidget 						MapListMC;
var GFxClikWidget 						MenuListMC;
var GFxClikWidget 						ResListMC;

var GFxObject 							ListDataProvider;
var array<UDKUIDataProvider_MapInfo> 	MapList;

var bool 								bMapsInitialized;


/*----------------------------------------------------------
	PAGE 1 : SERVERS
----------------------------------------------------------*/

/*--- Map list ---*/
function UpdateMapList()
{
	local byte 			i;
	local string 		TempMapName;
	local GFxObject 	TempObj;
	local GFxObject 	DataProvider;
	local array<UDKUIResourceDataProvider> ProviderList;

	// Checking data
	if (!bMapsInitialized)
	{
		class'UDKUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UDKUIDataProvider_MapInfo', ProviderList);
		for (i = 0; i < ProviderList.length; i++)
		{
			TempMapName = UDKUIDataProvider_MapInfo(ProviderList[i]).MapName;
			if (!IsInArray(TempMapName, IgnoredMaps)) 
				MapList.AddItem(UDKUIDataProvider_MapInfo(ProviderList[i]));
		}
		bMapsInitialized = true;
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


/*--- Map click ---*/
function OnMapItemClick(GFxClikWidget.EventData ev)
{
    local GFxObject button;
    button = ev._this.GetObject("itemRenderer");
	ConsoleCommand("open " $ button.GetString("label"));
}


/*--- Server connection ---*/
function OpenServer(GFxClikWidget.EventData evtd)
{
	ConsoleCommand("open " $ ServerURL);
}


/*--- Language ---*/
simulated function GetServerContent()
{
	SetLabel("MenuTitle", "Serveurs de jeu disponibles", true);
	SetLabel("MapTitle", "Maps disponibles", true);
}


/*----------------------------------------------------------
	PAGE 2 : STATS
----------------------------------------------------------*/

/*--- Content ---*/
simulated function GetStatsContent()
{
	// General
	SetLabel("MenuTitle", "Statistiques de jeu", true);
	SetLabel("StatGenTitle1", "Statistiques globales", true);
	SetLabel("StatGenTitle2", "Dernière partie", true);
	SetLabel("StatGenTitle3", "DeepVoid rank", true);
	
	// Stat block 1
	SetLabel("StatTitle1", "Efficacité", true);
	SetAlignedLabel("Stat10", "Victimes", "466");
	SetAlignedLabel("Stat11", "Précision", "12%");
	SetAlignedLabel("Stat12", "Ratio K/D", "1.2");
	SetPieChart("PieStat1", "Stat13", "Headshots", 70.0);
	
	// Stat block 2
	SetLabel("StatTitle2", "Victimes par arme", true);
	SetAlignedLabel("Stat20", "Fusil d'assaut", "81");
	SetAlignedLabel("Stat21", "Sniper", "66");
	SetAlignedLabel("Stat22", "Shotgun", "45");
	SetPieChart("PieStat2", "Stat23", "One-shots", 15.0);
	
	// Stat block 3
	SetLabel("Stat30", "Votre équipe a gagné", false);
	SetAlignedLabel("Stat31", "Rang final", "4°");
	SetAlignedLabel("Stat32", "Victimes", "17");
	SetAlignedLabel("Stat33", "Arme favorite", "Sniper");
	
	// Stat block 4
	SetLabel("Stat40", "Vous êtes classé au rang 1", false);
	SetLabel("Stat41", "Vous avez 87468 points", false);
}


/*----------------------------------------------------------
	PAGE 3 : SETTINGS
----------------------------------------------------------*/

/*--- Content ---*/
simulated function GetOptionsContent()
{
	// General
	SetLabel("MenuTitle", "Configuration du jeu", true);
	SetLabel("OptionGenTitle1", "Audio & Vidéo", true);
	SetLabel("OptionGenTitle2", "Gameplay", true);
	SetLabel("OptionGenTitle3", "Touches", true);
	
	// Option block 1
	SetLabel("OptionCB1", "Musique de fond", true);
	SetLabel("OptionCB2", "Plein écran", true);
	
	// Option block 2
	
	
	// Option block 3
	
}


/*--- Resolution list ---*/
function UpdateResList()
{
	local byte 			i;
	local GFxObject 	TempObj;
	local GFxObject 	DataProvider;
	
	// Sending data to menu
	DataProvider = ResListMC.GetObject("dataProvider");
	for (i = 0; i < ResListData.Length; i++)
	{
		TempObj = CreateObject("Object");
		TempObj.SetString("label", ResListData[i]);
		DataProvider.SetElementObject(i, TempObj);
	}
	ResListMC.SetObject("dataProvider", DataProvider);
}


/*--- Resolution navigation ---*/
function OnResItemClick(GFxClikWidget.EventData ev)
{
    local GFxObject button;
    button = ev._this.GetObject("itemRenderer");
    
    `log("res = " $ button.GetString("label"));
    
    if (InStr("1080", button.GetString("label")) != -1)
			ConsoleCommand("SetRes 1920*1080");
    if (InStr("720", button.GetString("label")) != -1)
			ConsoleCommand("SetRes 1280*720");
    if (InStr("max", button.GetString("label")) != -1)
			ConsoleCommand("SetRes 6000*3500");
}


/*----------------------------------------------------------
	Common methods
----------------------------------------------------------*/

/*--- Initialization ---*/
event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch(WidgetName)
	{
		case ('MapList'):
			MapListMC = GFxClikWidget(Widget);
			UpdateMapList();
			MapListMC.AddEventListener('CLIK_itemClick', OnMapItemClick);
			break;
		case ('MenuList'):
			MenuListMC = GFxClikWidget(Widget);
			UpdateMenuList();
			MenuListMC.AddEventListener('CLIK_itemClick', OnMenuItemClick);
			break;
		case ('ResolutionList'):
			ResListMC = GFxClikWidget(Widget);
			UpdateResList();
			ResListMC.AddEventListener('CLIK_itemClick', OnResItemClick);
			break;

		case ('LaunchMulti') :
			//LaunchMultiMC = GetLiveWidget(Widget, 'CLIK_click', OpenServer);
			break;
			
		default:
			return super.WidgetInitialized(Widgetname, WidgetPath, Widget);
	}
	return true;
}


/*--- Menu list ---*/
function UpdateMenuList()
{
	local byte 			i;
	local GFxObject 	TempObj;
	local GFxObject 	DataProvider;
	
	// Sending data to menu
	DataProvider = MenuListMC.GetObject("dataProvider");
	for (i = 0; i < MenuListData.Length; i++)
	{
		TempObj = CreateObject("Object");
		TempObj.SetString("label", MenuListData[i]);
		DataProvider.SetElementObject(i, TempObj);
	}
	MenuListMC.SetObject("dataProvider", DataProvider);
}


/*--- Menu navigation ---*/
function OnMenuItemClick(GFxClikWidget.EventData ev)
{
    local GFxObject button;
    button = ev._this.GetObject("itemRenderer");
    
	if(button.GetString("label") == MenuListData[3])
	{
		ConsoleCommand("exit");
	}
	else
	{
		GoToFrame(button.GetInt("index"));
	}
	PlayUISound(BipSound);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	IgnoredMaps=("LD","FX","AMB","ART","DefaultMap")
	
	MenuListData=("Serveurs","Statistiques","Réglages","Quitter")
	ResListData=("Ecran HD (1080p)","Ecran HDReady (720p)","Résolution maximale")
	
	ServerURL="deepvoid.eu"
	MovieInfo=SwfMovie'DV_CoreUI.MainMenu'
	
	WidgetBindings(1)={(WidgetName="MapList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(2)={(WidgetName="MenuList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(3)={(WidgetName="ResolutionList",WidgetClass=class'GFxClikWidget')}
	//WidgetBindings(3)={(WidgetName="LaunchMulti",WidgetClass=class'GFxClikWidget')}
}
