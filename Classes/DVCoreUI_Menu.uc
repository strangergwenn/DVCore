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


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GFxClikWidget 						MapListMC;
var GFxClikWidget 						MenuListMC;
var GFxClikWidget 						ServerListMC;
var GFxClikWidget 						ResListMC;

var GFxClikWidget 						ServerConnect;
var GFxClikWidget 						PlayerConnect;

var array<UDKUIDataProvider_MapInfo> 	MapList;
var array<string>						ServerList;
var array<string>						IPList;

var bool 								bMapsInitialized;
var bool								bIsInRegisterPopup;

var string								ServerURL;


/*----------------------------------------------------------
	PAGE 1 : SERVERS
----------------------------------------------------------*/

/*--- Add a possibly new server to the local database ---*/
function AddServerInfo(string ServerName, string Level, string IP, string Game, int Players, int MaxPlayers)
{
	if (IPList.Find(IP) < 0)
	{
		ServerList.AddItem(FormatServerInfo(ServerName, Level, Game, Players, MaxPlayers));
		IPList.AddItem(IP);
	}
}


/*--- Server browser ---*/
function UpdateServerList()
{
	local byte 			i;
	local GFxObject 	TempObj;
	local GFxObject 	DataProvider;

	// Sending data to menu
	DataProvider = ServerListMC.GetObject("dataProvider");
	for (i = 0; i < ServerList.Length; i++)
	{
		TempObj = CreateObject("Object");
		TempObj.SetString("label", ServerList[i]);
		DataProvider.SetElementObject(i, TempObj);
	}
	ServerListMC.SetObject("dataProvider", DataProvider);
	ServerListMC.SetFloat("rowCount", i);
}


/*--- Return a formatted server string to be displayed in the server browser ---*/
function string FormatServerInfo(string ServerName, string Level, string Game, int Players, int MaxPlayers)
{
	ServerName = Caps(ServerName);
	Game = GetRightMost(Game);
	Level = Caps(Repl(Level, ".udk", "", false));
	return (ServerName $ "\n" $Players $"/" $MaxPlayers $" joueurs, " $Game $"\n" $Level);
}


/*--- Server selection ---*/
function OnServerItemClick(GFxClikWidget.EventData ev)
{
    local GFxObject button;
    local string ServerString;
    
    button = ev._this.GetObject("itemRenderer");
	ServerString = button.GetString("label");
	
	ServerURL = IPList[ServerList.Find(ServerString)];
}


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
	ServerURL = button.GetString("label");
}


/*--- Server connection ---*/
function OpenServer(GFxClikWidget.EventData evtd)
{
	ConsoleCommand("open " $ ServerURL);
}


/*--- Player connexion event ---*/
function OnPlayerConnect(GFxClikWidget.EventData evtd)
{
	OpenConnectionDialog(false);
}


/*--- Open the connection popup ---*/
function OpenConnectionDialog(bool bShowRegister)
{
	local string Text[7];
	
	`log("OpenConnectionDialog");
	if (!bShowRegister)
	{
		Text[0] = "Connexion DeepVoid";
		Text[1] = "Joueur";
		Text[2] = "Mot de passe";
		Text[3] = "";
		Text[4] = "";
		Text[5] = "Connexion";
		Text[6] = "Nouveau ?";
		SetPopup(Text, 2);
	}
	else
	{
		Text[0] = "Nouveau compte";
		Text[1] = "Joueur";
		Text[2] = "E-mail";
		Text[3] = "Mot de passe";
		Text[4] = "Mot de passe";
		Text[5] = "Enregistrement";
		Text[6] = "Retour";
		SetPopup(Text, 3, 4);
	}
}


/*--- Language ---*/
simulated function GetServerContent()
{
	`log("GetServerContent");
	SetLabel("MenuTitle", "Parties en ligne", true);
	SetLabel("MapTitle", "Parties en solo", true);
	SetLabel("ServerTitle", "Parties en ligne", true);
	SetLabel("ButtonsTitle", "Actions", true);
	OpenConnectionDialog(false);
	HidePopup(true);
}


/*--- Popup button 1 : action ---*/
function OnPButton1(GFxClikWidget.EventData evtd)
{
	// Init
	local array<string> Result;
	super.OnPButton1(evtd);
	Result = GetPopupContent();
	
	// Checking
	if (Len(Result[0]) < 4 || Len(Result[1]) < 4)
		SetPopupStatus("Données incorrectes");
	else if (Result[2] != Result[3])
		SetPopupStatus("Mots de passe différents");
	
	// Actions
	else if (!bIsInRegisterPopup)
	{
		PC.MasterServerLink.ConnectToMaster(Result[0], Result[1]);
		SetPopupStatus("Connexion...");
	}
	else
	{
		PC.MasterServerLink.RegisterUser(Result[0], Result[1], Result[2]);
		SetPopupStatus("Enregistrement...");
	}
}


/*--- Popup button 2 : change window ---*/
function OnPButton2(GFxClikWidget.EventData evtd)
{
	super.OnPButton2(evtd);
	bIsInRegisterPopup = !bIsInRegisterPopup;
	OpenConnectionDialog(bIsInRegisterPopup);
}


/*--- Show result on screen ---*/
function GetPopupResult(bool bSuccess, string Msg)
{
	`log("GetPopupResult");
	if (bSuccess)
	{
		HidePopup(true);
	}
	else
	{
		SetPopupStatus((Msg != "") ? Msg : "Un problème s'est produit");
	}
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
	ResListMC.SetInt("selectedIndex", 0);
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
		// Lists
		case ('MapList'):
			MapListMC = GFxClikWidget(Widget);
			UpdateMapList();
			MapListMC.AddEventListener('CLIK_itemClick', OnMapItemClick);
			break;
		case ('ServerList'):
			ServerListMC = GFxClikWidget(Widget);
			UpdateServerList();
			ServerListMC.AddEventListener('CLIK_itemClick', OnServerItemClick);
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
		
		// Buttons
		case ('OpenServerButton'):
			ServerConnect = GFxClikWidget(Widget);
			ServerConnect.AddEventListener('CLIK_click', OpenServer);
			break;
		case ('PlayerConnectButton'):
			PlayerConnect = GFxClikWidget(Widget);
			PlayerConnect.AddEventListener('CLIK_click', OnPlayerConnect);
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


/*--- Get a command response code ---*/
function DisplayResponse (bool bSuccess, string Msg)
{
	GetPopupResult(bSuccess, Msg);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	bCaptureInput=true
	 
	IgnoredMaps=("LD","FX","AMB","ART","DefaultMap")
	
	MenuListData=("Parties","Statistiques","Réglages","Quitter")
	ResListData=("Ecran HD (1080p)","Ecran HDReady (720p)","Résolution maximale")
	
	ServerURL="deepvoid.eu"
	MovieInfo=SwfMovie'DV_CoreUI.MainMenu'
	
	WidgetBindings(3)={(WidgetName="MapList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(4)={(WidgetName="ServerList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(5)={(WidgetName="MenuList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(6)={(WidgetName="ResolutionList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(7)={(WidgetName="OpenServerButton",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(8)={(WidgetName="PlayerConnectButton",WidgetClass=class'GFxClikWidget')}
}
