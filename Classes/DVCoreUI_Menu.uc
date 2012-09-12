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
var (CoreUI) const array<string>		BindListData;

/*----------------------------------------------------------
	Localized attributes
----------------------------------------------------------*/

var (CoreUI) localized string			lGameStats;
var (CoreUI) localized string			lGlobalStats;
var (CoreUI) localized string			lLastGame;
var (CoreUI) localized string			lRanking;
var (CoreUI) localized string			lBestPlayers;
var (CoreUI) localized string			lEfficiency;
var (CoreUI) localized string			lVictims;
var (CoreUI) localized string			lDeadlyShots;
var (CoreUI) localized string			lHeadshots;
var (CoreUI) localized string			lEffByWeapon;
var (CoreUI) localized string			lFledGame;
var (CoreUI) localized string			lTeamHas;
var (CoreUI) localized string			lWon;
var (CoreUI) localized string			lLost;
var (CoreUI) localized string			lLastrank;
var (CoreUI) localized string			lDeaths;
var (CoreUI) localized string			lShotsFired;
var (CoreUI) localized string			lYouAreRanked;
var (CoreUI) localized string			lYouAreNotRanked;
var (CoreUI) localized string			lYouHave;
var (CoreUI) localized string			lPoints;
var (CoreUI) localized string			lWeapon0;
var (CoreUI) localized string			lWeapon1;
var (CoreUI) localized string			lWeapon2;
var (CoreUI) localized string			lWeapon3;
var (CoreUI) localized string			lWeapon4;
var (CoreUI) localized string			lMultiplayerGames;
var (CoreUI) localized string			lLocalGames;
var (CoreUI) localized string			lLaboratory;
var (CoreUI) localized string			lPlayerCustom;
var (CoreUI) localized string			lServerList;
var (CoreUI) localized string			lServerProtected;
var (CoreUI) localized string			lActions;
var (CoreUI) localized string			lPlayers;
var (CoreUI) localized string			lConnect;
var (CoreUI) localized string			lConnecting;
var (CoreUI) localized string			lRegistering;
var (CoreUI) localized string			lConnected;
var (CoreUI) localized string			lPConnect;
var (CoreUI) localized string			lPPlayer;
var (CoreUI) localized string			lPPassword;
var (CoreUI) localized string			lPConnectButton;
var (CoreUI) localized string			lPNewPlayer;
var (CoreUI) localized string			LPNewAccount;
var (CoreUI) localized string			LPEmail;
var (CoreUI) localized string			LPRegister;
var (CoreUI) localized string			lPBack;
var (CoreUI) localized string			lIncorrectData;
var (CoreUI) localized string			lWrongPassword;
var (CoreUI) localized string			lProblem;
var (CoreUI) localized string			lSettings;
var (CoreUI) localized string			lVideo;
var (CoreUI) localized string			lKeys;
var (CoreUI) localized string			lIngameMusic;
var (CoreUI) localized string			lImpactIndicator;
var (CoreUI) localized string			lFullScreen;
var (CoreUI) localized string			lWaitingForKey;
var (CoreUI) localized string			lJoinGame;
var (CoreUI) localized string			lSaveSettings;

var (CoreUI) localized array<string>	MenuListData;
var (CoreUI) localized array<string>	ResListData;
var (CoreUI) localized array<string>	KeyListData;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

enum EPopupState
{
    PS_None,
    PS_Password,
    PS_Login,
    PS_Register
};

var GFxClikWidget 						MapListMC;
var GFxClikWidget 						MenuListMC;
var GFxClikWidget 						ServerListMC;
var GFxClikWidget 						ResListMC;

var GFxClikWidget 						LeaderboardMC;
var GFxClikWidget 						Leaderboard2MC;

var GFxClikWidget 						ServerConnect;
var GFxClikWidget 						PlayerConnect;
var GFxClikWidget 						SaveVideoSettings;

var array<UDKUIDataProvider_MapInfo> 	MapList;
var array<string>						ServerList;
var array<string>						IPList;

var EPopupState							PopupState;

var bool 								bIsPasswordProtected;
var bool 								bMapsInitialized;
var bool								bIsKeyEditing;

var string								ServerURL;

var int									KeyBeingEdited;
var int									StoredLevel;


/*----------------------------------------------------------
	PAGE 1 : SERVERS
----------------------------------------------------------*/

/*--- First actions ---*/
function GetServerContent()
{
	// Init
	`log("CoreUI  > GetServerContent");
	OpenConnectionDialog(false);
	HidePopup(true);
	
	// Labels
	SetLabel("MenuTitle", lMultiplayerGames, true);
	SetLabel("MapTitle", lLocalGames, true);
	SetLabel("ServerTitle", lServerList, true);
	SetLabel("ButtonsTitle", lActions, true);
}


/*--- Add a possibly new server to the local database ---*/
function AddServerInfo(string ServerName, string Level, string IP, string Game, int Players, int MaxPlayers, bool bIsPassword)
{
	if (IPList.Find(IP) < 0)
	{
		ServerList.AddItem(FormatServerInfo(ServerName, Level, Game, Players, MaxPlayers, bIsPassword));
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
		TempObj.SetString("iconimage", "img://IcoThumbs.Textures.TX_THUMBNAIL_Level01");
		DataProvider.SetElementObject(i, TempObj);
	}
	ServerListMC.SetObject("dataProvider", DataProvider);
	ServerListMC.SetFloat("rowCount", i);
}


/*--- Return a formatted server string to be displayed in the server browser ---*/
function string FormatServerInfo(string ServerName, string Level, string Game, int Players, int MaxPlayers, bool bIsPassword)
{
	ServerName = Caps(ServerName);
	
	if (bIsPassword)
		ServerName @= "-" @lServerProtected;
	
	Game = GetRightMost(Game);
	Level = Caps(Repl(Level, ".udk", "", false));
	return (ServerName $ "\n" $Players $"/" $MaxPlayers @ lPlayers $"," @Game $"\n" $Level);
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
			if (IsInArray(TempMapName, IgnoredMaps) == -1) 
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


/*--- Server selection ---*/
function OnServerItemClick(GFxClikWidget.EventData ev)
{
	local string ServerString;
	ServerString = GetListItemClicked(ev);
	
	ServerURL = IPList[ServerList.Find(ServerString)];
	bIsPasswordProtected = (InStr(ServerString, lServerProtected) != -1);
	ServerConnect.SetBool("enabled", true);
}


/*--- Map click ---*/
function OnMapItemClick(GFxClikWidget.EventData ev)
{
	bIsPasswordProtected = false;
	ServerURL = GetListItemClicked(ev);
	ServerConnect.SetBool("enabled", true);
}


/*--- Server connection ---*/
function OpenServer(GFxClikWidget.EventData evtd)
{
	PlayUISound(ClickSound);
	
	if (bIsPasswordProtected)
	{
		OpenPasswordDialog();
	}
	else
	{
		ConsoleCommand("open " $ ServerURL $ "?game=");
	}
}


/*--- Player connexion event ---*/
function OnPlayerConnect(GFxClikWidget.EventData evtd)
{
	PlayUISound(ClickSound);
	OpenConnectionDialog(false);
}


/*--- Open the password popup ---*/
function OpenPasswordDialog()
{
	local string Text[7];
	
	Text[0] = lPPassword;
	Text[1] = lPPassword;
	Text[5] = lPConnectButton;
	Text[6] = lPBack;
	SetPopup(Text, 1);
	PopupState = PS_Password;
	
	if (PC != None)
	{
		PC.CancelTimeout();
	}
}


/*--- Open the connection popup ---*/
function OpenConnectionDialog(bool bShowRegister)
{
	local string Text[7];
	
	if (!bShowRegister)
	{
		Text[0] = lPConnect;
		Text[1] = lPPlayer;
		Text[2] = lPPassword;
		Text[3] = "";
		Text[4] = "";
		Text[5] = lPConnectButton;
		Text[6] = lPNewPlayer;
		SetPopup(Text, 2);
		PopupState = PS_Login;
	}
	else
	{
		Text[0] = lPNewAccount;
		Text[1] = lPPlayer;
		Text[2] = lPPassword;
		Text[3] = lPPassword;
		Text[4] = LPEmail;
		Text[5] = LPRegister;
		Text[6] = lPBack;
		SetPopup(Text, 2, 3);
		PopupState = PS_Register;
	}
	if (PC != None)
	{
		SetPopupContent(1, PC.LocalStats.UserName);
		SetPopupContent(2, PC.LocalStats.Password);
		PC.CancelTimeout();
	}
}


/*--- Popup button 1 : action ---*/
function OnPButton1(GFxClikWidget.EventData evtd)
{
	// Init
	local array<string> Result;
	super.OnPButton1(evtd);
	Result = GetPopupContent();
	
	// Checking
	if (Len(Result[0]) < 4 || ((PopupState == PS_Register) && Len(Result[3]) < 10))
		SetPopupStatus(lIncorrectData);
	else if ((PopupState == PS_Register) && Result[1] != Result[2])
		SetPopupStatus(lWrongPassword);
	
	// Register
	else if (PopupState == PS_Register)
	{
		PC.Register(Result[0], Result[3], Result[1]);
		SetPopupStatus(lRegistering);
	}
	
	// Login
	else if (PopupState == PS_Login)
	{
		PC.SaveIDs(Result[0], Result[1]);
		PC.Connect(Result[0], Result[1]);
		SetPopupStatus(lConnecting);
		SetConnectState(1);
	}
	
	// Password
	else if (PopupState == PS_Password)
	{
		ConsoleCommand("open " $ ServerURL $ "?Password=" $Result[0] $"?game=");
	}
}


/*--- Popup button 2 : change window ---*/
function OnPButton2(GFxClikWidget.EventData evtd)
{
	super.OnPButton2(evtd);
	
	// Register
	if (PopupState == PS_Register)
	{
		PopupState = PS_Login;
		OpenConnectionDialog(false);
	}
	
	// Login
	else if (PopupState == PS_Login)
	{
		PopupState = PS_Register;
		OpenConnectionDialog(true);
	}
	
	// Password
	else if (PopupState == PS_Password)
	{
		HidePopup(true);
		PC.CancelTimeout();
	}
}


/*--- Display the server connection state ---*/
function SetConnectState(optional int Level)
{
	local string Message;
	
	PlayerConnect.SetBool("enabled", (Level == 0));
	switch (Level)
	{
		case (0):
			Message = lConnect;
			break; 
		case (1):
			Message = lConnecting;
			break; 
		case (2):
			Message = lConnected;
			break; 
	}
	StoredLevel = Level;
	PlayerConnect.SetString("label", Message);
}


/*--- Show result on screen ---*/
function GetConnectionResult(bool bSuccess)
{
	`log("CoreUI  > GetConnectionResult" @bSuccess);
	if (bSuccess)
	{
		SetConnectState(2);
	}
	else
	{
		SetConnectState(0);
	}
}

/*--- Show result on screen ---*/
function GetPopupResult(string Msg)
{
	SetPopupStatus((Msg != "") ? Msg : lProblem);
}


/*----------------------------------------------------------
	PAGE 2 : STATS
----------------------------------------------------------*/

/*--- Content ---*/
simulated function GetStatsContent()
{
	// Init
	local string RankInfo;
	
	// General
	SetLabel("MenuTitle", lGameStats, true);
	SetLabel("StatGenTitle1", lGlobalStats, true);
	SetLabel("StatGenTitle2", lLastGame, true);
	SetLabel("StatGenTitle3", lRanking, true);
	SetLabel("StatGenTitle4", lBestPLayers, true);
	
	// Stat block 1
	SetLabel("StatTitle1", lEfficiency, true);
	SetLabel("Stat10", string(PC.GlobalStats.Kills) @lVictims, false);
	SetLabel("Stat11", string(100 * (PC.GlobalStats.Headshots) / PC.GlobalStats.Kills) $"%" @lHeadshots, false);
	SetLabel("Stat12", string((100 * PC.GlobalStats.Kills) / PC.GlobalStats.Deaths) $"% K/D", false);
	SetPieChart("PieStat1", "Stat13", lDeadlyShots, PC.GlobalStats.Kills / PC.GlobalStats.ShotsFired);
	
	// Stat block 2
	SetLabel("StatTitle2", lEffByWeapon, true);
	SetLabel("Stat20", lWeapon0 @":" @string(PC.GlobalStats.WeaponScores[0]) @lVictims, false);
	SetLabel("Stat21", lWeapon1 @":" @string(PC.GlobalStats.WeaponScores[1]) @lVictims, false);
	SetLabel("Stat22", lWeapon2 @":" @string(PC.GlobalStats.WeaponScores[2]) @lVictims, false);
	SetLabel("Stat23", lWeapon3 @":" @string(PC.GlobalStats.WeaponScores[3]) @lVictims, false);
	SetLabel("Stat24", lWeapon4 @":" @string(PC.GlobalStats.WeaponScores[4]) @lVictims, false);
	
	// Stat block 3
	if (PC.LocalStats.bHasLeft)
		SetLabel("Stat30", lFledGame, false);
	else
		SetLabel("Stat30", lTeamHas $ (PC.LocalStats.bHasWon ? lWon : lLost), false);
	
	SetLabel("Stat31", lLastRank @string(PC.LocalStats.Rank), false);
	SetLabel("Stat32", string(PC.LocalStats.Kills) @lVictims, false);
	SetLabel("Stat33", string(PC.LocalStats.Deaths) @lDeaths, false);
	SetLabel("Stat34", string(PC.LocalStats.ShotsFired) @lShotsfired, false);
	
	// Stat block 4
	if (PC.GlobalStats.Rank > 0)
		RankInfo = lYouAreRanked @ string(PC.GlobalStats.Rank);
	else
		RankInfo = lYouAreNotRanked;
	SetLabel("Stat40", RankInfo, false);
	SetLabel("Stat41", lYouHave @ string(PC.GlobalStats.Points) @lPoints, false);
}


/*--- Get a generic leaderboard structure ---*/
simulated function UpdateLeaderboard(GFxObject List, bool bIsLocal)
{
	local byte 			i;
	local GFxObject 	TempObj;
	local GFxObject 	DataProvider;
	local array<string>	PlayerList;
	
	PlayerList = PC.GetBestPlayers(bIsLocal);
	DataProvider = List.GetObject("dataProvider");
	for (i = 0; i < PlayerList.Length; i++)
	{
		TempObj = CreateObject("Object");
		TempObj.SetString("label", PlayerList[i]);
		DataProvider.SetElementObject(i, TempObj);
	}
	List.SetObject("dataProvider", DataProvider);
	List.SetInt("selectedIndex", (bIsLocal ? PC.LocalLeaderBoardOffset - 1 : 0));
}


/*----------------------------------------------------------
	PAGE 3 : SETTINGS
----------------------------------------------------------*/

/*--- Content ---*/
simulated function GetOptionsContent()
{
	local GFxObject tmpDisabled;
	local string Key;
	local byte i;
	
	// General
	SetLabel("MenuTitle", lSettings, true);
	SetLabel("OptionGenTitle1", lVideo, true);
	SetLabel("OptionGenTitle3", lKeys, true);
	
	// Unused
	tmpDisabled = GetSymbol("OptionGenTitle2");
	tmpDisabled.SetVisible(false);
	
	// Option block 1
	SetWidgetLabel("OptionCB1", lIngameMusic, false);
	SetWidgetLabel("OptionCB2", lImpactIndicator, false);
	SetWidgetLabel("OptionCB3", lFullScreen, false);
	SetChecked("OptionCB1", PC.LocalStats.bBackgroundMusic);
	SetChecked("OptionCB2", PC.LocalStats.bUseSoundOnHit);
	SetChecked("OptionCB3", PC.LocalStats.bFullScreen);
	
	// Keys
	for (i = 0; i < KeyListData.Length; i++)
	{
		Key = DVPlayerInput(PC.PlayerInput).GetKeyBinding(BindListData[i]);
		SetLabel("Key" $(i + 1), Key $ "   |   " $ KeyListData[i], false);
	}
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
	ResListMC.SetInt("selectedIndex", IsInArray(PC.LocalStats.Resolution, ResListData, true));
}


/*--- Launch key editing ---*/
function EditKey(GFxClikWidget.EventData ev)
{
	local GFxObject button;
	
	if (!bIsKeyEditing)
	{
	    button = ev._this.GetObject("target");
	    
		KeyBeingEdited = (IsInArray(Split(button.GetString("text"), "   |   ", true), KeyListData, true) + 1);
		SetLabel("Key" $KeyBeingEdited, lWaitingForKey, false);
		
		bIsKeyEditing = true;
		bCaptureInput = false;
	}
}


/*--- Save key pressed ---*/
function SetKeyPressed(string KeyName)
{
	local string Key;
	
	// Cancel
	if (KeyName == "Escape")
	{
		Key = DVPlayerInput(PC.PlayerInput).GetKeyBinding(BindListData[KeyBeingEdited - 1]);
		SetLabel("Key" $KeyBeingEdited, Key $ "   |   " $KeyListData[KeyBeingEdited - 1], false);
		bIsKeyEditing = false;
		bCaptureInput = true;
	}
	
	// Key editing
	else if (bIsKeyEditing)
	{
		SetLabel("Key" $KeyBeingEdited, KeyName $ "   |   " $KeyListData[KeyBeingEdited - 1], false);
		bIsKeyEditing = false;
		bCaptureInput = true;
	}
	PlayUISound(ClickSound);
}


/*--- Settings saved ---*/
function ValidateSettings(GFxClikWidget.EventData ev)
{
	// Vars
	local GFxObject button;
	local string res, flag;
	local byte i;
	
	// Resolution
	button = GetSymbol("ResolutionList");
	res = Split(ResListData[int(button.GetString("selectedIndex"))], "[", false);
	`log("CoreUI  > Clicked resolution " $ res);
	
	// Application
	PlayUISound(ClickSound);
	flag = (IsChecked("OptionCB3") ? "f" : "w");
	res = Repl(res, "[", "");
	res = Repl(res, "]", "");
	ApplyResolutionSetting(res, flag);
	
	// Options
	PC.LocalStats.SetBoolValue("bBackgroundMusic", IsChecked("OptionCB1"));
	PC.LocalStats.SetBoolValue("bUseSoundOnHit", IsChecked("OptionCB2"));
	PC.LocalStats.SetBoolValue("bFullScreen", IsChecked("OptionCB3"));
	PC.LocalStats.SetStringValue("Resolution", res);
	PC.LocalStats.SaveConfig();
	
	// Keys
	for (i = 0; i < KeyListData.Length; i++)
	{
		button = GetSymbol("Key" $(i + 1));
		res = Left(button.GetString("text"), InStr(button.GetString("text"), "   |   "));
		DVPlayerInput(PC.PlayerInput).SetKeyBinding(name(res), BindListData[i]);
	}
}


/*----------------------------------------------------------
	Common methods
----------------------------------------------------------*/

/*--- Initialization ---*/
event bool WidgetInitialized (name WidgetName, name WidgetPath, GFxObject Widget)
{
	local GFxClikWidget TempObject;
	
	switch(WidgetName)
	{
		// Lists
		case ('MapList'):
			MapListMC = GetLiveWidget(Widget, 'CLIK_itemClick', OnMapItemClick);
			UpdateMapList();
			break;
		case ('ServerList'):
			ServerListMC = GetLiveWidget(Widget, 'CLIK_itemClick', OnServerItemClick);
			UpdateServerList();
			break;
		case ('MenuList'):
			MenuListMC = GetLiveWidget(Widget, 'CLIK_itemClick', OnMenuItemClick);
			UpdateMenuList();
			break;
		case ('Leaderboard'):
			LeaderboardMC = GFxClikWidget(Widget);
			UpdateLeaderboard(LeaderboardMC, false);
			break;
		case ('Leaderboard2'):
			Leaderboard2MC = GFxClikWidget(Widget);
			UpdateLeaderboard(Leaderboard2MC, true);
			break;
		
		// Buttons
		case ('OpenServerButton'):
			ServerConnect = GetLiveWidget(Widget, 'CLIK_click', OpenServer);
			ServerConnect.SetString("label", lJoinGame);
			ServerConnect.SetBool("enabled", false);
			break;
		case ('PlayerConnectButton'):
			PlayerConnect = GetLiveWidget(Widget, 'CLIK_click', OnPlayerConnect);
			SetConnectState(StoredLevel);
			break;
		case ('ResolutionList'):
			ResListMC = GFxClikWidget(Widget);
			UpdateResList();
			break;
		
		// Keys settings
		case ('Key1'):
		case ('Key2'):
		case ('Key3'):
		case ('Key4'):
		case ('Key5'):
		case ('Key6'):
		case ('Key7'):
		case ('Key8'):
		case ('Key9'):
		case ('Key10'):
			TempObject = GFxClikWidget(Widget);
			TempObject.AddEventListener('CLIK_click', EditKey);
			break;
		
		// Various
		case ('SaveVideoSettings'):
			SaveVideoSettings = GFxClikWidget(Widget);
			SaveVideoSettings.AddEventListener('CLIK_click', ValidateSettings);
			SaveVideoSettings.SetString("label", lSaveSettings);
			break;
			
		default: return super.WidgetInitialized(Widgetname, WidgetPath, Widget);
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
	PlayUISound(BipSound);
    button = ev._this.GetObject("itemRenderer");
    
	if(button.GetString("label") == MenuListData[3])
	{
		ConsoleCommand("exit");
	}
	else
	{
		GoToFrame(button.GetInt("index"));
	}
}


/*--- Get a command response code ---*/
function DisplayResponse (bool bSuccess, string Msg, string Command)
{
	if (Command == "CONNECT" || Command == "NET")
		GetConnectionResult(bSuccess);
	GetPopupResult(Msg);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Game settings
	bCaptureInput=true
	MovieInfo=SwfMovie'DV_CoreUI.MainMenu'
	IgnoredMaps=("LD","FX","AMB","ART","DefaultMap")
	BindListData=("GBA_MoveForward","GBA_Backward","GBA_StrafeLeft","GBA_StrafeRight","GBA_Jump","GBA_Duck","GBA_Use","GBA_ShowCommandMenu","GBA_Talk")
	
	// Bindings
	WidgetBindings(3)={(WidgetName="MapList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(4)={(WidgetName="ServerList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(5)={(WidgetName="MenuList",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(6)={(WidgetName="ResolutionList",WidgetClass=class'GFxClikWidget')}
	
	WidgetBindings(7)={(WidgetName="OpenServerButton",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(8)={(WidgetName="PlayerConnectButton",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(9)={(WidgetName="SaveVideoSettings",WidgetClass=class'GFxClikWidget')}
	
	WidgetBindings(10)={(WidgetName="OptionCB1",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(11)={(WidgetName="OptionCB2",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(12)={(WidgetName="OptionCB3",WidgetClass=class'GFxClikWidget')}
	
	WidgetBindings(13)={(WidgetName="Leaderboard",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(14)={(WidgetName="Leaderboard2",WidgetClass=class'GFxClikWidget')}
	
	WidgetBindings(15)={(WidgetName="Key1",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(16)={(WidgetName="Key2",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(17)={(WidgetName="Key3",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(18)={(WidgetName="Key4",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(19)={(WidgetName="Key5",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(20)={(WidgetName="Key6",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(21)={(WidgetName="Key7",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(22)={(WidgetName="Key8",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(23)={(WidgetName="Key9",WidgetClass=class'GFxClikWidget')}
	WidgetBindings(24)={(WidgetName="Key10",WidgetClass=class'GFxClikWidget')}
}
