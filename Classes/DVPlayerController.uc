/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVPlayerController extends UDKPlayerController;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVPC) const SoundCue			HitSound;

var (DVPC) const float 				ScoreLength;

var (DVPC) const int 				TickDivisor;
var (DVPC) const int 				LeaderBoardLength;
var (DVPC) const int 				LocalLeaderBoardOffset;
var (DVPC) const int				ObjectCheckDistance;


/*----------------------------------------------------------
	Localized attributes
----------------------------------------------------------*/

var (DVPC) localized string			lYouAreInTeam;
var (DVPC) localized string			lTeamSwitch;
var (DVPC) localized string			lEmptyWeapon;
var (DVPC) localized string			lJoinedGame;

var (DVPC) localized string			lKilledBy;
var (DVPC) localized string			lKilled;
var (DVPC) localized string			lLost;
var (DVPC) localized string			lWon;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var DVUserStats						LocalStats;
var DVUserStats						GlobalStats;

var DVConfigBench					Bench;
var Actor							TargetObject;

var class<DVWeapon> 		 		WeaponList[8];
var class<DVWeapon> 				UserChoiceWeapon;

var DVTeamInfo						EnemyTeamInfo;

var DVLink							MasterServerLink;

var int								MaxScore;
var int								FrameCount;

var byte							WeaponListLength;

var bool							bLocked;
var bool							bShouldStop;
var bool							bConfiguring;
var bool							bMusicStarted;

var array<string>					LeaderBoardStructure;
var array<string>					LeaderBoardStructure2;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if ( bNetDirty )
		UserChoiceWeapon, EnemyTeamInfo, bLocked, WeaponList, WeaponListLength, MaxScore;
}

/*----------------------------------------------------------
	Events and net behaviour
----------------------------------------------------------*/

/*--- Initial spawn ---*/ 
simulated function PostBeginPlay()
{
	// Init
	super.PostBeginPlay();
	`log("DVPC > PostBeginPlay");
	SetTimer(1.0, false, 'StartMusicIfAvailable');
	bConfiguring = false;
	
	// Stats
	LocalStats = new class'DVUserStats';
	GlobalStats = new class'DVUserStats';
	SetName(LocalStats.UserName);
	GlobalStats.EmptyStats();
	
	// Connexion
	MasterServerLink = spawn(class'DVLink');
	MasterServerLink.InitLink(self);
}


/*--- Pawn possession : is spawned and OK ---*/
event Possess(Pawn aPawn, bool bVehicleTransition)
{
	super.Possess(aPawn, bVehicleTransition);
	UpdatePawnColor();
	ShowTeam();
	bConfiguring = false;
	HideScores();
}


/*--- Inform of the team ---*/
reliable client simulated function ShowTeam()
{
	local string TeamName;
	TeamName = (PlayerReplicationInfo.Team != None) ? PlayerReplicationInfo.Team.GetHumanReadableName() : "";
	ShowGenericMessage(lYouAreInTeam @ TeamName);
}


/*--- Launch autoconnection ---*/
simulated function AutoConnect()
{
	if (Len(LocalStats.UserName) > 3
	 && Len(LocalStats.Password) > 3
	 && MasterServerLink != None)
	{
		MasterServerLink.ConnectToMaster(LocalStats.UserName, LocalStats.Password);
	}
}


/*--- Called when the connection has been established ---*/
function SignalConnected()
{
	SetName(LocalStats.UserName);
	LocalStats.SaveConfig();
}


/*--- Master server callback ---*/
reliable client event TcpCallback(string Command, bool bIsOK, string Msg, optional int data[8])
{
	// Init, on-screen ACK for menu
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}
	else if (myHUD != None)
	{
		if (myHUD.IsA('DVHUD_Menu'))
			DVHUD_Menu(myHUD).DisplayResponse(bIsOK, Msg, Command);
	}
	
	// First data : autoconnection if available
	if (Command == "INIT" && bIsOK)
	{
		AutoConnect();
		if (myHUD.IsA('DVHUD_Menu'))
		{
			DVHUD_Menu(myHUD).AutoConnect();
		}
	}
	
	// Upload & get back the stats on main menu, store the player ID in PRI
	else if (Command == "CONNECT" && bIsOK && myHUD != None)
	{
		if (myHUD.IsA('DVHUD_Menu'))
		{
			DVHUD_Menu(myHUD).SignalConnected();
			MasterServerLink.GetLeaderboard(LeaderBoardLength, MasterServerLink.CurrentID);
			MasterServerLink.GetStats();
		}
		else if (PlayerReplicationInfo != None)
		{
			DVPlayerRepInfo(PlayerReplicationInfo).SetClientId(MasterServerLink.CurrentID);
			`log("DVPC > Logged in with ID" @MasterServerLink.CurrentID);
		}
	}
}


/*--- New player ---*/
reliable client simulated function Register(string user, string email, string passwd)
{
	MasterServerLink.RegisterUser(user, email, passwd);
}


/*--- Connection ---*/
reliable client simulated function Connect(string user, string passwd)
{
	MasterServerLink.ConnectToMaster(user, passwd);
}


/*--- Return a copy of the user statistics ---*/
reliable server simulated function DVUserStats GetClientStats()
{
	return GlobalStats;
}


/*--- Disarm timeout to avoid popup-hiding ---*/
reliable client simulated function CancelTimeout()
{
	MasterServerLink.AbortTimeout();
}


/*--- Stats getting ---*/
reliable client event TcpGetStats(array<string> Data)
{
	// Init
	local byte i;
	
	// Global game stats
	if (InStr(Data[0], "GET_GSTATS") != -1)
	{
		`log("DVPC > Got game data");
		GlobalStats.SetIntValue("Kills", 		int(Data[1]));
		GlobalStats.SetIntValue("Deaths", 		int(Data[2]));
		GlobalStats.SetIntValue("TeamKills", 	int(Data[3]));
		GlobalStats.SetIntValue("Points", 		int(Data[5]));
		GlobalStats.SetIntValue("ShotsFired", 	int(Data[6]));
		GlobalStats.SetIntValue("Headshots", 	int(Data[7]));
	}
	
	// Weapon stats
	else if (InStr(Data[0], "GET_WSTATS") != -1)
	{
		`log("DVPC > Got weapon data");
		for (i = 0; i < 8; i++)
		{
			GlobalStats.SetArrayIntValue("WeaponScores", int(Data[i + 1]), i);
		}
	}
}


/*--- Player rank info ---*/
reliable client event CleanBestPlayer()
{
	local array<string> Empty;
	Empty.AddItem("");
	Empty.RemoveItem("");
	LeaderBoardStructure = Empty;
	LeaderBoardStructure2 = Empty;
}


/*--- Player rank info ---*/
reliable client event AddBestPlayer(string PlayerName, int Rank, int PlayerPoints, bool bIsLocal)
{
	if (bIsLocal)
	{
		LeaderBoardStructure2.AddItem(string(Rank) $"." @PlayerName $ " : " $ PlayerPoints $ " points");
	}
	else
	{
		LeaderBoardStructure.AddItem(string(Rank) $"." @PlayerName $ " : " $ PlayerPoints $ " points");
	}
}


/*----------------------------------------------------------
	Player actions
----------------------------------------------------------*/

/*--- Scores ---*/
exec function ShowCommandMenu()
{
	// Chatting
	if (IsChatLocked())
		return;
	
	DVHUD(myHUD).ShowPlayerList();
	SetTimer(ScoreLength, false, 'HideScores');
}


/*--- Addon toggle ---*/
exec function Use()
{
	// Chatting
	if (IsChatLocked())
		return;
	
	if (Pawn != None && DVWeapon(Pawn.Weapon) != None)
	{
		DVPawn(Pawn).SetAddonStatus(! DVPawn(Pawn).GetAddonStatus() );
	}
}


/*--- Object activation ---*/
exec function Activate()
{
	// Init
	if (IsChatLocked())
		return;
	`log("DVPC > Activate" @TargetObject);
	
	// Activate
	if (TargetObject != None && VSize(TargetObject.Location - Pawn.Location) < ObjectCheckDistance)
	{
		if (TargetObject.IsA('DVButton'))
		{
			DVButton(TargetObject).Activate();
		}
		else if (TargetObject.IsA('DVConfigBench'))
		{
			DVConfigBench(TargetObject).LaunchConfig(DVPawn(Pawn));
		}
	}
}


/*--- Fire started ---*/
exec function StartFire(optional byte FireModeNum = 0)
{
	// Chatting
	if (IsChatLocked())
		return;
	
	if (IsCameraLocked() || bShouldStop)
		return;
	else
	{
		super.StartFire(FireModeNum);
	}
}


/*--- Team switch ---*/
exec function SwitchTeam()
{
	// Chatting
	if (IsChatLocked())
		return;
	
	super.SwitchTeam();
	DVHUD(myHUD).GameplayMessage(lTeamSwitch);
}


/*--- Send text ---*/
exec function Talk()
{
	DVHUD(myHUD).HudMovie.StartTalking();
}


/*--- Nope ---*/
exec function TeamTalk()
{}


/*--- Tick tick tick ---*/
event PlayerTick(float DeltaTime)
{
	// Data
	local vector StartTrace, EndTrace, HitLocation, HitNormal;
	local rotator TraceDir;
	local DVPawn P;
	local Actor Target;
	FrameCount += 1;
	
	if (Pawn != None && Pawn.Weapon != None && FrameCount % TickDivisor == 0)
	{
		// Input lock : freeze movement
		P = DVPawn(Pawn);
		P.Mesh.GetSocketWorldLocationAndRotation(P.EyeSocket, StartTrace, TraceDir);
		EndTrace = DVWeapon(P.Weapon).GetEffectLocation();
		
		// Should we lock input ?
		Target = None;
		Target = Trace(HitLocation, HitNormal, EndTrace, StartTrace);
		bShouldStop = (Target != None);
	}
	super.PlayerTick(DeltaTime);
}


/*--- Nope ---*/
function bool SetPause(bool bPause, optional delegate<CanUnpause> CanUnpauseDelegate=CanUnpause)
{}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Open weapon management ---*/
function ConfigureWeapons(DVConfigBench TheBench)
{
	Bench = TheBench;
	bConfiguring = true;
	SetViewTargetWithBlend(TheBench);
	DVHUD(myHUD).OpenWeaponConfig();
	DVPawn(Pawn).HideMesh(true);
}


/*--- Signal shot received ---*/
reliable client simulated function ClientSignalHit(Controller InstigatedBy, bool bWasHeadshot)
{
	ServerSignalHit(InstigatedBy, bWasHeadshot);
	if (bWasHeadshot)
	{
		LocalStats.SetIntValue("HeadShots" , LocalStats.HeadShots + 1);
	}
}
reliable server simulated function ServerSignalHit(Controller InstigatedBy, bool bWasHeadshot)
{
	DVPlayerController(InstigatedBy).NotifyHit(bWasHeadshot);
	GlobalStats.SetIntValue("HeadShots" , GlobalStats.HeadShots + 1);
}


/*--- Successful hit notification ---*/
reliable server simulated function NotifyHit(bool bWasHeadshot)
{
	PlayHitSound(bWasHeadshot);
}
unreliable client simulated function PlayHitSound(bool bWasHeadshot)
{
	if(LocalStats.bUseSoundOnHit)
	{
		PlaySound(HitSound);
	}
}


/*--- Camera lock management ---*/
simulated function LockCamera(bool NewState)
{
	bLocked = NewState;
	IgnoreMoveInput(bLocked);
}


/*--- Camera lock getter ---*/
simulated function bool IsCameraLocked()
{
	return bLocked;
}


/*--- Chat lock getter ---*/
simulated function bool IsChatLocked()
{
	if (DVHUD(myHUD) != None)
		return DVHUD(myHUD).HudMovie.bChatting;
	else
		return false;
}


/*--- Player viewpoint ---*/
simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
{
	if (ViewTarget != None && bConfiguring)
	{
		ViewTarget.CalcCamera(0, out_Location, out_Rotation, FOVAngle);
	}
	else
	{
		super.GetPlayerViewPoint(out_Location, out_Rotation);
	}
}


/*--- Camera management  ---*/
function UpdateRotation(float DeltaTime)
{
	local Rotator	DeltaRot, newRotation, ViewRotation;
	local bool bAmIZoomed;
	local float ZoomSensitivity;
	
	// Zoom management
	bAmIZoomed = false;
	ViewRotation = Rotation;
	if (Pawn != None)
	{
		Pawn.SetDesiredRotation(ViewRotation);
		if (DVPawn(Pawn).Weapon != None)
		{
			bAmIZoomed = DVWeapon(Pawn.Weapon).IsZoomed();
			ZoomSensitivity = DVWeapon(Pawn.Weapon).GetZoomFactor();
		}
	}

	// Calculate Delta
	DeltaRot.Yaw	= PlayerInput.aTurn * (bAmIZoomed ? ZoomSensitivity : 1.0);
	DeltaRot.Pitch	= PlayerInput.aLookUp * (bAmIZoomed ? ZoomSensitivity : 1.0);

	ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
	SetRotation(ViewRotation);
	NewRotation = ViewRotation;
	NewRotation.Roll = Rotation.Roll;

	if ( Pawn != None )
		Pawn.FaceRotation(NewRotation, deltatime);
}


/*--- Camera lock ---*/
simulated function ProcessViewRotation(float DeltaTime, out Rotator out_ViewRotation, rotator DeltaRot)
{
	if (Pawn != None && !IsCameraLocked())
		super.ProcessViewRotation(DeltaTime, out_ViewRotation, DeltaRot );
}


/*--- Launch crouching ---*/
function CheckJumpOrDuck()
{
	super.CheckJumpOrDuck();
	if ( Pawn.Physics != PHYS_Falling && Pawn.bCanCrouch )
	{
		Pawn.ShouldCrouch(bDuck != 0);
	}
}


/*--- No TTS ---*/
simulated function SpeakTTS( coerce string S, optional PlayerReplicationInfo PRI )
{}


/*--- End of game ---*/
reliable client simulated function SignalEndGame(bool bHasWon)
{
	`log("DVPC > End of game " $ self);
	DVHUD(myHUD).ShowPlayerList();
	LockCamera(true);
	
	ShowGenericMessage((bHasWon) ? lWon : lLost); 
	
	SaveGameStatistics(bHasWon);
	GotoState('RoundEnded');
}


/*--- Ammo count ---*/
simulated function int GetAmmoCount()
{
	local DVWeapon wp;
	wp = DVWeapon(Pawn.Weapon);
	return ((wp != None) ? wp.GetAmmoCount() : 0);
}


/*--- Ammo count maximum ---*/
simulated function int GetAmmoMax()
{
	local DVWeapon wp;
	wp = DVWeapon(Pawn.Weapon);
	return ((wp != None) ? wp.GetAmmoMax() : 0);
}


/*--- Team index management ---*/
simulated function byte GetTeamIndex()
{
	if (PlayerReplicationInfo != None)
	{
		if (DVPlayerRepInfo(PlayerReplicationInfo).Team != None)
			return DVPlayerRepInfo(PlayerReplicationInfo).Team.TeamIndex;
		else
			return -1;
	}
	else
		return -1;
}


/*--- Player name management ---*/
simulated function string GetPlayerName()
{
	local string PlayerName;
	PlayerName = PlayerReplicationInfo != None ? PlayerReplicationInfo.PlayerName : "UNNAMED";
	return PlayerName;
}


/*----------------------------------------------------------
	Reliable client/server code
----------------------------------------------------------*/

/*--- Call this to respawn the player ---*/
reliable server simulated function HUDRespawn(bool bShouldKill, optional class<DVWeapon> NewWeapon)
{
	if (bConfiguring)
	{
		Bench.ConfiguringEnded(self);
		Bench = None;
		bShouldKill = true;
		bConfiguring = false;
		DVPawn(Pawn).HideMesh(true);
	}
	if (NewWeapon == None)
	{
		NewWeapon = UserChoiceWeapon;
	}
	ServerSetUserChoice(NewWeapon, bShouldKill);
	ServerReStartPlayer();
}


/*--- Register the weapon to use on respawn ---*/
reliable server simulated function ServerSetUserChoice(class<DVWeapon> NewWeapon, bool bShouldKill)
{
	if (Pawn != None)
	{
		if (bShouldKill)
			Pawn.KilledBy(Pawn);
		else
		{
			Pawn.SetHidden(True);
			Pawn.Destroy();	
		}
	}
	UserChoiceWeapon = NewWeapon;
}


/* Client weapon switch */
reliable client simulated function SetUserChoice(class<DVWeapon> NewWeapon)
{
	UserChoiceWeapon = NewWeapon;
	DVHUD(myHUD).DisarmWeaponMenu();
}


/* Server team update */
reliable server simulated function UpdatePawnColor()
{
	local byte i;
	i = GetTeamIndex();
	
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		PlayerReplicationInfo.bForceNetUpdate = true;
	}
	else
	{
		if (i != -1)
			DVPawn(Pawn).UpdateTeamColor(i);
	}
	MaxScore = DVGame(WorldInfo.Game).MaxScore;
}


/*--- Return the server score target ---*/
reliable client simulated function int GetTargetScore()
{
	return MaxScore;
}


/*--- Register the ennemy team ---*/
reliable server simulated function SetEnemyTeamInfo(DVTeamInfo TI)
{
	EnemyTeamInfo = TI;
}


/*--- Set the new weapon list ---*/
reliable server function SetWeaponList(class<DVWeapon> NewList[8], byte NewWeaponListLength)
{
	local byte i;
	WeaponListLength = NewWeaponListLength;
	for (i = 0; i < WeaponListLength; i++)
	{
		if (NewList[i] != None)
			WeaponList[i] = NewList[i];
	}
}


/*--- Hide the score screen ---*/
reliable client simulated function HideScores()
{
	DVHUD(myHUD).HidePlayerList();
}


/*--- Suicide ---*/
reliable server function ServerSuicide()
{
	if (Pawn != None)
	{
		Pawn.Suicide();
	}
}


/*----------------------------------------------------------
	Notifications
----------------------------------------------------------*/

/*--- Notify a new player ---*/ 
reliable server function ServerNotifyNewPlayer(string PlayerName)
{
	NotifyNewPlayer(PlayerName);
}
reliable client simulated function NotifyNewPlayer(string PlayerName)
{
	ShowGenericMessage("" $PlayerName @ lJoinedGame);
}


/*--- Show the killer message ---*/ 
unreliable client simulated function ShowKilledBy(string KillerName)
{
	RegisterDeath();
	ShowGenericMessage(lKilledBy @ KillerName $ " !");
}


/*--- Show the killed message ---*/ 
unreliable client simulated function ShowKilled(string KilledName, bool bTeamKill)
{
	RegisterKill(bTeamKill);
	ShowGenericMessage(lKilled @ KilledName $ " !");
}


/*--- Show the killer message ---*/ 
unreliable client simulated function ShowEmptyAmmo()
{
	ShowGenericMessage(lEmptyWeapon);
}


/*--- Show a generic message ---*/ 
unreliable client simulated function ShowGenericMessage(string text)
{
	if (WorldInfo.NetMode == NM_DedicatedServer || myHUD == None)
		return;
	DVHUD(myHUD).GameplayMessage(text);
}


/*----------------------------------------------------------
	Statistics database and ranking
----------------------------------------------------------*/

/*--- Remember client ---*/
reliable client simulated function SaveIDs(string User, string Pass)
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		LocalStats.SetStringValue("UserName", User);
		LocalStats.SetStringValue("PassWord", Pass);
		LocalStats.SaveConfig();
	}
}


/*--- Get the player ID ---*/
reliable server simulated function string GetCurrentID()
{
	if (PlayerReplicationInfo != None)
		return DVPlayerRepInfo(PlayerReplicationInfo).CurrentId;
	else 
		return "TELL_GWENN_ABOUT_THIS";
}


/*--- Store kill in DB ---*/
reliable client simulated function RegisterDeath()
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		LocalStats.SetIntValue("Deaths" , LocalStats.Deaths + 1);
	}
}


/*--- Store shot in DB ---*/
reliable server simulated function ServerRegisterShot()
{
	GlobalStats.SetIntValue("ShotsFired" , GlobalStats.ShotsFired + 1);
}
reliable client simulated function RegisterShot()
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		LocalStats.SetIntValue("ShotsFired" , LocalStats.ShotsFired + 1);
	}
}


/*--- Store kill in DB : server side ---*/
reliable server simulated function StoreKillData(bool bIsTeamKill)
{
	local int index;
	index = GetCurrentWeaponIndex();
	if (bIsTeamKill)
	{
		GlobalStats.SetIntValue("TeamKills" , GlobalStats.TeamKills + 1);
	}
	else
	{
		GlobalStats.SetIntValue("Kills" , GlobalStats.Kills + 1);
		GlobalStats.SetArrayIntValue("WeaponScores", GlobalStats.WeaponScores[index] + 1, index);
	}
}


/*--- Store kill in DB : client side ---*/
reliable client simulated function RegisterKill(optional bool bTeamKill)
{
	local int index;
	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
	
	index = GetCurrentWeaponIndex();
	
	if (bTeamKill)
	{
		LocalStats.SetIntValue("TeamKills" , LocalStats.TeamKills + 1);
	}
	else
	{
		LocalStats.SetIntValue("Kills" , LocalStats.Kills + 1);
		LocalStats.SetArrayIntValue("WeaponScores", LocalStats.WeaponScores[index] + 1, index);
	}
}


/*--- Weapon index being used ---*/
reliable client simulated function byte GetCurrentWeaponIndex()
{
	local byte i;
	
	for (i = 0; i < WeaponListLength; i++)
	{
		if (WeaponList[i] == DVPawn(Pawn).CurrentWeaponClass)
		{
			return i;
		}
	}
	return WeaponListLength;
}


/*--- End of game : saving ---*/
reliable client simulated function SaveGameStatistics(bool bHasWon, optional bool bLeaving)
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		LocalStats.SetBoolValue("bHasLeft", bLeaving);
		LocalStats.SetBoolValue("bHasWon", bHasWon);
		LocalStats.SetIntValue("Rank", GetLocalRank());
		LocalStats.SaveConfig();
	}
}


/*--- Get the player rank in the game ---*/
reliable client simulated function int GetLocalRank()
{
	local array<DVPlayerRepInfo> PList;
	local byte i;
	
	PList = GetPlayerList();
	
	for (i = 0; i < PList.Length; i ++)
	{
		if (PList[i] == DVPlayerRepInfo(PlayerReplicationInfo))
		{
			`log("DVPC > GetLocalRank"@i);
			return i + 1;
		}
	}
	return 0;
}


/*--- Get the local PRI list, sorted by rank ---*/
reliable client simulated function array<DVPlayerRepInfo> GetPlayerList()
{
	local array<DVPlayerRepInfo> PRList;
	local DVPlayerRepInfo PRI;
	
	foreach AllActors(class'DVPlayerRepInfo', PRI)
	{
		PRList.AddItem(PRI);
		`log("DVPC > GetPlayerList" @PRI);
	}
	PRList.Sort(SortPlayers);
	return PRList;
}


/*--- Sorting method ---*/
simulated function int SortPlayers(DVPlayerRepInfo A, DVPlayerRepInfo B)
{
	return A.GetPointCount() < B.GetPointCount() ? -1 : 0;
}


/*--- Get the leaderboard structure ---*/
simulated function array<string> GetBestPlayers(bool bIsLocal)
{
	return (bIsLocal) ? LeaderBoardStructure : LeaderBoardStructure2;
}


/*----------------------------------------------------------
	Music management
----------------------------------------------------------*/

reliable server simulated function StartMusicIfAvailable()
{
	if (!bMusicStarted && WorldInfo != None)
	{
		bMusicStarted = true;
		ClientPlaySound(GetTrackIntro());
		SetTimer(GetIntroLength(), false, 'StartMusicLoop');
	}
}


/*--- Music loop ---*/
reliable server simulated function StartMusicLoop()
{
	ClearTimer('StartMusicLoop');
	ClientPlaySound(GetTrackLoop());
}


/*--- Music sound if used ---*/
unreliable client event ClientPlaySound(SoundCue ASound)
{
	if (LocalStats.bBackgroundMusic)
		ClientHearSound(ASound, self, Location, false, false);
}


/*--- Get the music track to play here ---*/
reliable server simulated function SoundCue GetTrackIntro()
{
	if (WorldInfo.Game != None)
	{
		return DVGame(WorldInfo.Game).GetTrackIntro();
	}
	else
	{
		return None;
	}
}


/*--- Get the music track to play here ---*/
reliable server simulated function SoundCue GetTrackLoop()
{
	if (WorldInfo.Game != None)
	{
		return DVGame(WorldInfo.Game).GetTrackLoop();
	}
	else
	{
		return None;
	}
}


/*--- Get the music track to play here ---*/
reliable server simulated function float GetIntroLength()
{
	if (WorldInfo.Game != None)
	{
		return DVGame(WorldInfo.Game).GetIntroLength();
	}
	else
	{
		return 0.0;
	}
}


/*----------------------------------------------------------
	States
----------------------------------------------------------*/

state PlayerWalking
{
	function ProcessMove( float DeltaTime, vector newAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		if( Pawn == None )
		{
			return;
		}
		
		if (DoubleClickMove == DCLICK_Forward && Pawn.Health > DVPawn(Pawn).SprintDamage)
		{
			bRun = 1;
			DVPawn(Pawn).SetRunning(true);
		}

		if (Role == ROLE_Authority)
		{
			Pawn.SetRemoteViewPitch( Rotation.Pitch );
		}

		Pawn.Acceleration = NewAccel;
		CheckJumpOrDuck();
	}
}


state Dead
{
	exec function StartFire(optional byte FireModeNum)
	{}
}


state RoundEnded
{
	// Nope
	ignores KilledBy, Falling, TakeDamage, Suicide, DrawHud;
	exec function ShowCommandMenu(){}
	function PlayerMove(float DeltaTime){}
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	bLocked=true
	
	TickDivisor=5
	ScoreLength=4.0
	LeaderBoardLength=10
	ObjectCheckDistance=300
	LocalLeaderBoardOffset=4
	DesiredFOV=85.000000
	DefaultFOV=85.000000

	HitSound=SoundCue'DV_Sound.UI.A_Click'
	InputClass=class'DVPlayerInput'
}
