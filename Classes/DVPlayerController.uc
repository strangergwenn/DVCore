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

var (DVPC) const int 				LeaderBoardLength;
var (DVPC) const int 				LocalLeaderBoardOffset;
var (DVPC) const int 				TickDivisor;


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

var class<DVWeapon> 		 		WeaponList[8];
var class<DVWeapon> 				UserChoiceWeapon;

var DVTeamInfo						EnemyTeamInfo;

var DVLink							MasterServerLink;

var int								MaxScore;
var int								FrameCount;

var byte							WeaponListLength;

var bool							bLocked;
var bool							bShouldStop;
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
	super.PostBeginPlay();
	LocalStats = new class'DVUserStats';
	GlobalStats = new class'DVUserStats';
	SetName(LocalStats.UserName);
	GlobalStats.EmptyStats();
}


/*--- Pawn possession : is spawned and OK ---*/
event Possess(Pawn aPawn, bool bVehicleTransition)
{
	local string TeamName;
	super.Possess(aPawn, bVehicleTransition);
	UpdatePawnColor();
	
	TeamName = (PlayerReplicationInfo.Team != None) ? PlayerReplicationInfo.Team.GetHumanReadableName() : "";
	ShowGenericMessage(lYouAreInTeam @ TeamName);
	SetTimer(1.0, false, 'StartMusicIfAvailable');
}


/*--- Launch autoconnection ---*/
simulated function AutoConnect()
{
	`log("DVPC : autoConnect");
	
	if (Len(LocalStats.UserName) > 3
	 && Len(LocalStats.Password) > 3
	 && MasterServerLink != None)
	{
		MasterServerLink.ConnectToMaster(
			LocalStats.UserName, LocalStats.Password);
	}
}


/*--- Called when the connection has been established ---*/
function SignalConnected()
{
	`log("Setting name " @LocalStats.UserName);
	SetName(LocalStats.UserName);
	LocalStats.SaveConfig();
}


/*--- Master server callback ---*/
reliable client event TcpCallback(string Command, bool bIsOK, string Msg, optional int data[8])
{
	// Init, on-screen ACK for menu
	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
	else if (myHUD != None)
	{
		if (myHUD.IsA('DVHUD_Menu'))
			DVHUD_Menu(myHUD).DisplayResponse(bIsOK, Msg, Command);
	}
	
	// First data : autoconnection if available
	if (Command == "INIT" && bIsOK)
	{
		// Are we on main menu
		if (myHUD.IsA('DVHUD_Menu'))
		{
			MasterServerLink.GetLeaderboard(LeaderBoardLength, LocalLeaderBoardOffset);
			DVHUD_Menu(myHUD).DelayedAutoConnect();
		}
		
		// Ingame
		else
			DVHUD(myHUD).AutoConnect();
	}
	
	// Upload & get back the stats on main menu
	else if (Command == "CONNECT" && bIsOK && myHUD != None)
	{
		if (myHUD.IsA('DVHUD_Menu'))
		{
			DVHUD_Menu(myHUD).SignalConnected();
			UploadGame();
			MasterServerLink.GetLeaderboard(LeaderBoardLength, LocalLeaderBoardOffset);
			MasterServerLink.GetStats();
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


/*--- Upload game statistics ---*/
reliable client simulated function UploadGame()
{
	// Checking data
	`log("DVPC : Uploading game...");
	
	// Stats upload
	if (LocalStats != None && LocalStats.bWasUploaded == false)
	{
		MasterServerLink.SaveGame(
			LocalStats.Kills,
			LocalStats.Deaths,
			LocalStats.TeamKills,
			LocalStats.Rank,
			LocalStats.ShotsFired,
			LocalStats.WeaponScores
		);
		LocalStats.SetBoolValue("bWasUploaded", true);
		LocalStats.SaveConfig();
		`log("DVPC : Uploading sent");
	}
	
	// Will be tried again on menu
	else
		`log("DVPC : Uploading aborted");
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
		GlobalStats.SetIntValue("Kills", 	int(Data[1]));
		GlobalStats.SetIntValue("Deaths", 	int(Data[2]));
		GlobalStats.SetIntValue("TeamKills", int(Data[3]));
		GlobalStats.SetIntValue("Points", 	int(Data[5]));
		GlobalStats.SetIntValue("Shots", 	int(Data[6]));
		GlobalStats.SetIntValue("Headshots", int(Data[7]));
	}
	
	// Weapon stats
	else if (InStr(Data[0], "GET_WSTATS") != -1)
	{
		for (i = 0; i < WeaponListLength; i++)
		{
			GlobalStats.SetArrayIntValue("WeaponScores", i, int(Data[i + 1]));
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
	DVHUD(myHUD).ShowPlayerList();
	SetTimer(ScoreLength, false, 'HideScores');
}


/*--- Addon toggle ---*/
exec function Use()
{
	if (Pawn != None && DVWeapon(Pawn.Weapon) != None)
	{
		DVPawn(Pawn).SetAddonStatus(! DVPawn(Pawn).GetAddonStatus() );
	}
}


/*--- Fire started ---*/
exec function StartFire(optional byte FireModeNum = 0)
{
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
	super.SwitchTeam();
	DVHUD(myHUD).GameplayMessage(lTeamSwitch);	
}


/*--- Send text ---*/
exec function Talk()
{
	`log("Talk");
	DVHUD(myHUD).HudMovie.StartTalking();
}


/*--- Nope ---*/
exec function TeamTalk()
{}


/*--- Tick tick tick ---*/
event PlayerTick(float DeltaTime)
{
	local vector StartTrace, EndTrace, HitLocation, HitNormal;
	local rotator TraceDir;
	local DVPawn P;
	local Actor Target;
	
	FrameCount += 1;
	if (Pawn != None && Pawn.Weapon != None && FrameCount % TickDivisor == 0)
	{
		// Data
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
	Music management
----------------------------------------------------------*/

reliable server simulated function StartMusicIfAvailable()
{
	`log("DVPC : StartMusicIfAvailable");
	
	if (!bMusicStarted)
	{
		bMusicStarted = true;
		ClientPlaySound(GetTrackIntro());
		SetTimer(GetIntroLength(), false, 'StartMusicLoop');
	}
}


/*--- Music loop ---*/
reliable server simulated function StartMusicLoop()
{
	`log("DVPC : StartMusicLoop");
	
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
	return DVGame(WorldInfo.Game).GetTrackIntro();
}


/*--- Get the music track to play here ---*/
reliable server simulated function SoundCue GetTrackLoop()
{
	return DVGame(WorldInfo.Game).GetTrackLoop();
}


/*--- Get the music track to play here ---*/
reliable server simulated function float GetIntroLength()
{
	return DVGame(WorldInfo.Game).GetIntroLength();
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Signal shot received ---*/
reliable client simulated function ClientSignalHit(Controller InstigatedBy, bool bWasHeadshot)
{
	ServerSignalHit(InstigatedBy, bWasHeadshot);
}
reliable server simulated function ServerSignalHit(Controller InstigatedBy, bool bWasHeadshot)
{
	DVPlayerController(InstigatedBy).NotifyHit(bWasHeadshot);
}


/*--- Successful hit notification ---*/
reliable server simulated function NotifyHit(bool bWasHeadshot)
{
	PlayHitSound(bWasHeadshot);
}


/*--- Notify a new player ---*/ 
unreliable server simulated function ServerNotifyNewPlayer(string PlayerName)
{
	NotifyNewPlayer(PlayerName);
}
unreliable client simulated function NotifyNewPlayer(string PlayerName)
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


/*--- Play the hit sound ---*/ 
unreliable client simulated function PlayHitSound(bool bWasHeadshot)
{
	if(LocalStats.bUseSoundOnHit)
		PlaySound(HitSound);
	
	if (bWasHeadshot)
		LocalStats.SetIntValue("HeadShots" , LocalStats.HeadShots + 1);
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
	`log("DVPC : End of game " $ self);
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
	if (NewWeapon == None)
	{
		NewWeapon = UserChoiceWeapon;
	}
	ServerSetUserChoice(NewWeapon, bShouldKill);
	SetUserChoice(NewWeapon);
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
	Statistics database and ranking
----------------------------------------------------------*/

/*--- Remember client ---*/
reliable client simulated function SaveIDs(string User, string Pass)
{
	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
	LocalStats.SetStringValue("UserName", User);
	LocalStats.SetStringValue("PassWord", Pass);
	LocalStats.SaveConfig();
}


/*--- Store kill in DB ---*/
reliable client simulated function RegisterDeath()
{
	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
	LocalStats.SetIntValue("Deaths" , LocalStats.Deaths + 1);
}


/*--- Store shot in DB ---*/
reliable client simulated function RegisterShot()
{
	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
	LocalStats.SetIntValue("ShotsFired" , LocalStats.ShotsFired + 1);
}


/*--- Store kill in DB ---*/
exec reliable client simulated function RegisterKill(optional bool bTeamKill)
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
			`log("DVPC : GetCurrentWeaponIndex" @i);
			return i;
		}
	}
	return WeaponListLength;
}


/*--- End of game : saving ---*/
reliable client simulated function SaveGameStatistics(bool bHasWon, optional bool bLeaving)
{
	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
	
	`log("DVPC : SaveGameStatistics");
	LocalStats.SetBoolValue("bHasLeft", bLeaving);
	LocalStats.SetBoolValue("bWasUploaded", false);
	LocalStats.SetIntValue("Rank", GetLocalRank());
	LocalStats.SaveConfig();
	UploadGame();
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
			`log("DVPC : GetLocalRank"@i);
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
	
	ForEach AllActors(class'DVPlayerRepInfo', PRI)
	{
		PRList.AddItem(PRI);
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
	States
----------------------------------------------------------*/

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
	LocalLeaderBoardOffset=4

	HitSound=SoundCue'DV_Sound.UI.A_Click'
	InputClass=class'DVPlayerInput'
}
