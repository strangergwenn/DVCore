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


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var class<DVWeapon> 		 		WeaponList[8];
var class<DVWeapon> 				UserChoiceWeapon;

var DVTeamInfo						EnemyTeamInfo;

var DVLink							MasterServerLink;

var byte							WeaponListLength;

var bool							bLocked;

var string 							DebugField;

var array<string>					LeaderBoardStructure;
var array<string>					LeaderBoardStructure2;


/*----------------------------------------------------------
	Replication
----------------------------------------------------------*/

replication
{
	if ( bNetDirty )
		UserChoiceWeapon, EnemyTeamInfo, bLocked, WeaponList, WeaponListLength;
}


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- Pawn possession : is spawned and OK ---*/
event Possess(Pawn aPawn, bool bVehicleTransition)
{
	local string TeamName;
	
	super.Possess(aPawn, bVehicleTransition);
	UpdatePawnColor();
	
	TeamName = (GetTeamIndex() == 0) ? "rouge" : "bleue";
	ShowGenericMessage("Vous êtes dans l'équipe " $ TeamName);
}


/*--- Master server callback ---*/
reliable client event TcpCallback(string Command, bool bIsOK, string Msg, optional int data[8])
{
	// Standard response if useful
	if (myHUD.IsA('DVHUD_Menu'))
		DVHUD_Menu(myHUD).DisplayResponse(bIsOK, Msg);
	
	// Get back the stats
	if (Command == "CONNECT")
	{
		DVHUD_Menu(myHUD).SignalConnected();
		MasterServerLink.GetLeaderboard(LeaderBoardLength, LocalLeaderBoardOffset);
	}
}


/*--- Stats getting ---*/
reliable client event TcpGetStats(array<string> Data)
{
	// Init
	local byte i;
	local DVUserStats GStats;
	GStats = DVHUD(myHUD).GlobalStats;
	
	// Parsing
	switch(Data[0])
	{
		// Global game stats
		case "GET_GSTATS":
			GStats.SetIntValue("Kills", 	int(Data[1]));
			GStats.SetIntValue("Deaths", 	int(Data[2]));
			GStats.SetIntValue("TeamKills", int(Data[3]));
			GStats.SetIntValue("Points", 	int(Data[4]));
			GStats.SetIntValue("Shots", 	int(Data[5]));
			GStats.SetIntValue("Headshots", int(Data[6]));
			break;
		
		// Weapon stats
		case "GET_WSTATS":
			for (i = 0; i < WeaponListLength; i++)
			{
				GStats.SetArrayIntValue("WeaponScores", i, int(Data[i + 1]));
			}
			break;
	}
}


/*--- Player rank info ---*/
reliable client event AddBestPlayer(string PlayerName, int Rank, int PlayerPoints, bool bIsLocal)
{
	if (bIsLocal)
	{
		LeaderBoardStructure.AddItem(PlayerName $ " : " $ PlayerPoints $ " points");
	}
	else
	{
		LeaderBoardStructure2.AddItem(PlayerName $ " : " $ PlayerPoints $ " points");
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


/*--- Beam toggle ---*/
exec function Use()
{
	if (Pawn != None && DVWeapon(Pawn.Weapon) != None)
	{
		DVPawn(Pawn).SetBeamStatus(! DVPawn(Pawn).GetBeamStatus() );
	}
}


/*--- Switch weapon class ---*/
exec simulated function ChangeWeaponClass(class<DVWeapon> NewWeapon)
{
	`log("SwitchToWeaponClass choice : " $ NewWeapon);
	SetUserChoice(NewWeapon, false);
	ServerSetUserChoice(NewWeapon, false);
}


/*--- Fire started ---*/
exec function StartFire(optional byte FireModeNum = 0)
{
	if (IsCameraLocked())
		return;
	else
	{
		super.StartFire(FireModeNum);
	}
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Notify a new player ---*/ 
unreliable server simulated function ServerNotifyNewPlayer(string PlayerName)
{
	NotifyNewPlayer(PlayerName);
}
unreliable client simulated function NotifyNewPlayer(string PlayerName)
{
	ShowGenericMessage("" $PlayerName $ " a rejoint la partie");
}


/*--- Show the killer message ---*/ 
unreliable client simulated function ShowKilledBy(string KillerName)
{
	RegisterDeath();
	ShowGenericMessage("Vous avez été tué par " $ KillerName $ " !");
}


/*--- Show the killed message ---*/ 
unreliable client simulated function ShowKilled(string KilledName, bool bTeamKill)
{
	RegisterKill(bTeamKill);
	ShowGenericMessage("Vous avez tué " $ KilledName $ " !");
}


/*--- Show the killer message ---*/ 
unreliable client simulated function ShowEmptyAmmo()
{
	ShowGenericMessage("Votre arme est vide !");
}


/*--- Show a generic message ---*/ 
unreliable client simulated function ShowGenericMessage(string text)
{
	DVHUD(myHUD).GameplayMessage(text);
}


/*--- Play the hit sound ---*/ 
unreliable client simulated function PlayHitSound()
{
	if(DVHUD(myHUD).LocalStats.bUseSoundOnHit)
		PlaySound(HitSound);
}


/*--- Camera lock management ---*/
simulated function LockCamera(bool NewState)
{
	bLocked = NewState;
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


/*--- No TTS ---*/
simulated function SpeakTTS( coerce string S, optional PlayerReplicationInfo PRI )
{}


/*--- End of game ---*/
reliable client simulated function SignalEndGame(bool bHasWon)
{
	`log("End of game " $ self);
	DVHUD(myHUD).ShowPlayerList();
	LockCamera(true);
	
	ShowGenericMessage((bHasWon) ? 
		"Vous avez gagné la partie !" : 
		"Vous avez perdu la partie !"
	);
	
	SaveGameStatistics(bHasWon);
	GotoState('RoundEnded');
}


/*--- Ammo ---*/
simulated function float GetAmmoPercentage()
{
	local DVWeapon wp;
	wp = DVWeapon(Pawn.Weapon);
	
	if (wp != None)
		return 100.0 * wp.GetAmmoRatio();
	else
		return 0.0;	
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
reliable server simulated function HUDRespawn(class<DVWeapon> NewWeapon)
{
	ServerSetUserChoice(NewWeapon, true);
	SetUserChoice(NewWeapon, true);
	ServerReStartPlayer();
}


/* Client weapon switch */
reliable client simulated function SetUserChoice(class<DVWeapon> NewWeapon, bool bShouldKill)
{
	`log("Player choosed " $ NewWeapon);
	
	// Survivors will be shot again
	if (bShouldKill && Pawn != None)
	{
		if (Pawn.Health > 0)
		{
			Pawn.KilledBy(Pawn);
		}
		Pawn.SetHidden(True);
	}
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
}


/*--- Register the weapon to use on respawn ---*/
reliable server simulated function ServerSetUserChoice(class<DVWeapon> NewWeapon, bool bShouldKill)
{
	if (bShouldKill && Pawn != None)
		Pawn.Destroy();
	UserChoiceWeapon = NewWeapon;
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


/*----------------------------------------------------------
	Statistics database and ranking
----------------------------------------------------------*/

/*--- Remember client ---*/
reliable client simulated function SaveIDs(string User, string Pass)
{
	local DVUserStats LStats;
	LStats = DVHUD_Menu(myHUD).LocalStats;
	LStats.SetStringValue("UserName", User);
	LStats.SetStringValue("PassWord", Pass);
	LStats.SaveConfig();
}


/*--- Store kill in DB ---*/
reliable client simulated function RegisterDeath()
{
	local DVUserStats LStats;
	LStats = DVHUD(myHUD).LocalStats;
	LStats.SetIntValue("Deaths" , LStats.Deaths + 1);
}


/*--- Store shot in DB ---*/
reliable client simulated function RegisterShot()
{
	local DVUserStats LStats;
	LStats = DVHUD(myHUD).LocalStats;
	LStats.SetIntValue("ShotsFired" , LStats.ShotsFired + 1);
}


/*--- Store kill in DB ---*/
reliable client simulated function RegisterKill(optional bool bTeamKill)
{
	local DVUserStats LStats;
	local int index;
	
	LStats = DVHUD(myHUD).LocalStats;
	index = GetCurrentWeaponIndex();
	
	if (bTeamKill)
	{
		LStats.SetIntValue("TeamKills" , LStats.TeamKills + 1);
	}
	else
	{
		LStats.SetIntValue("Kills" , LStats.Kills + 1);
		LStats.SetArrayIntValue("WeaponScores", index, LStats.WeaponScores[index] + 1);
	}
}


/*--- Weapon index being used ---*/
reliable client simulated function byte GetCurrentWeaponIndex()
{
	local byte i;
	
	for (i = 0; i < WeaponListLength; i++)
	{
		if (WeaponList[i] == DVPawn(Pawn).CurrentWeaponClass)
			return i;
	}
	return WeaponListLength;
}


/*--- End of game : saving ---*/
reliable client simulated function SaveGameStatistics(bool bHasWon, optional bool bLeaving)
{
	local DVUserStats LStats;
	
	LStats = DVHUD(myHUD).LocalStats;
	LStats.SetBoolValue("bHasLeft", bLeaving);
	LStats.SetIntValue("Rank", GetLocalRank());
	LStats.SaveConfig();
	
	MasterServerLink.SaveGame(
		LStats.Kills,
		LStats.Deaths,
		LStats.TeamKills,
		LStats.Rank,
		LStats.ShotsFired,
		LStats.WeaponScores
	);
}


/*--- Get the player rank in the game ---*/
reliable client simulated function int GetLocalRank()
{
	local array<DVPlayerRepInfo> PList;
	local byte i;
	
	PList = GetPlayerList();
	
	for (i = 0; i < PList.Length; i ++)
	{
		`log("Comparing " $ PList[i] $ " to " $ DVPlayerRepInfo(PlayerReplicationInfo));
		if (PList[i] == DVPlayerRepInfo(PlayerReplicationInfo))
			return i;
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
	local byte i;
	local array<string> Result;
	
	for (i = 0; i < LeaderBoardLength; i++)
	{
		Result.AddItem((bIsLocal?i+142:i+1) $ ". " $ "Player" $ " : " $ ((bIsLocal?1561:6373)-173*i) $ " pts");
	}
	
	return Result;
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
	
	ScoreLength=4.0
	LeaderBoardLength=10
	LocalLeaderBoardOffset=4

	HitSound=SoundCue'DV_Sound.UI.A_Click'
	InputClass=class'DVPlayerInput'
}
