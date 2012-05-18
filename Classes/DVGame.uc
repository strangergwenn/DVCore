/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVGame extends UDKGame;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (DVGame) const class<DVWeapon> 		DefaultWeaponList[8];

var (DVGame) const class<DVTeamInfo> 	TeamInfoClass;

var (DVGame) const int					WeaponListLength;
var (DVGame) const int 					MaxScore;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var class<DVWeapon>					DefaultWeapon;

var	DVTeamInfo						Teams[2];

var float							EndGameTick;
var float							RestartTimer;


/*----------------------------------------------------------
	Events
----------------------------------------------------------*/

/*--- Standard team creation ---*/
function PreBeginPlay()
{
	super.PreBeginPlay();
	CreateTeam(0);
	CreateTeam(1);
}


/*--- Score update ---*/
event PostBeginPlay()
{
	super.PostBeginPlay();
	SetTimer(EndGameTick, true, 'ScoreUpdated');
}


/*--- Team attribution ---*/
event PostLogin (PlayerController NewPlayer)
{
	local Actor A;
	local DVPlayerController P;
	Super.PostLogin(NewPlayer);
	
	DVPlayerController(NewPlayer).SetWeaponList(DefaultWeaponList, WeaponListLength);
	
	if (LocalPlayer(NewPlayer.Player) == None)
		return;
	
	foreach AllActors(class'Actor', A)
		A.NotifyLocalPlayerTeamReceived();
	
	foreach AllActors(class'DVPlayerController', P)
	{
		if (P != NewPlayer)
			P.ServerNotifyNewPlayer(DVPlayerController(NewPlayer).GetPlayerName());
	}
	DVPlayerController(NewPlayer).MaxScore = MaxScore;
	DVPlayerController(NewPlayer).StartMusicIfAvailable();
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Spawning weapon management ---*/
function AddDefaultInventory(Pawn PlayerPawn)
{
	local class<DVWeapon> Choiced;
	
	`log("AddDefaultInventory for " $ PlayerPawn);
	if (PlayerPawn.Controller != None)
	{
		Choiced = DVPlayerController(PlayerPawn.Controller).UserChoiceWeapon;
		if (Choiced != None)
		{
			PlayerPawn.CreateInventory(Choiced);
		}
	}
	else
	{
		`log("Spawned default weapon, this is wrong.");
		PlayerPawn.CreateInventory(DefaultWeapon);
	}
	PlayerPawn.AddDefaultInventory();
}


/*--- Stub ---*/
function ScoreUpdated()
{
	// Init
	local int S0, S1;
	S0 = Teams[0].GetScore();
	S1 = Teams[1].GetScore();
	
	// Victory
	if (S0 >= MaxScore || S1 >= MaxScore)
	{
		GameEnded( (S0 > S1) ? 0 : 1);
	}
}


/*--- Game end ---*/
function GameEnded(byte WinnerIndex)
{
	local DVPlayerController PC;
	local bool bIsWinner;
	
	ForEach AllActors(class'DVPlayerController', PC)
	{
		bIsWinner = CheckForWin(PC, WinnerIndex);
		PC.SignalEndGame(bIsWinner);
	}
	
	ClearTimer('ScoreUpdated');
	SetTimer(RestartTimer, false, 'RestartGame');
}


/*--- Is this controller the winner ? ---*/
simulated function bool CheckForWin(DVPlayerController PC, byte WinnerIndex)
{
	return (PC.GetTeamIndex() == WinnerIndex);
}


/*--- Killed set ---*/
function ScoreKill(Controller Killer, Controller Other)
{
	local DVPlayerRepInfo KillerPRI, OtherPRI;
	local bool bIsTeamKill;
	
	// Init
	`log(Killer $ " ScoreKill " $ Other);
	KillerPRI = DVPlayerRepInfo(Killer.PlayerReplicationInfo);
	OtherPRI = DVPlayerRepInfo(Other.PlayerReplicationInfo);
	
	// Score kill
	`log(self $ " KilledBy " $ KillerPRI);
	if (KillerPRI != None)
	{
		if (KillerPRI.Team != None && DVPlayerController(Other) != None)
		{
			bIsTeamKill = (	(Killer == Other)
						 || (DVPlayerController(Killer).GetTeamIndex() == DVPlayerController(Other).GetTeamIndex()));
		}
		else
			bIsTeamKill = (Killer == Other);
		
		`log(Other $ " KilledBy " $ KillerPRI $ ", isTK=" $ bIsTeamKill);
		KillerPRI.ScorePoint(bIsTeamKill);
		DVPlayerController(Other).ShowKilledBy(KillerPRI.PlayerName);
	}
	
	// Death
	if (OtherPRI != None && OtherPRI != KillerPRI)
	{
		DVPlayerController(Killer).ShowKilled(OtherPRI.PlayerName, bIsTeamKill);
		OtherPRI.ScoreDeath();
	}
}


/*--- Player start determination ---*/
function PlayerStart ChoosePlayerStart(Controller Player, optional byte InTeam)
{
	local array<playerstart> PlayerStarts;
	local PlayerStart 		P, BestStart;
	local float 			BestRating, NewRating;
	local int 				i, RandStart;

	// All player starts
	foreach WorldInfo.AllNavigationPoints(class'PlayerStart', P)
	{
		if ( P.bEnabled )
			PlayerStarts[PlayerStarts.Length] = P;
	}
	RandStart = Rand(PlayerStarts.Length);

	// Random points : end part
	for (i = RandStart; i < PlayerStarts.Length; i++)
	{
		P = PlayerStarts[i];
		NewRating = RatePlayerStart(P, InTeam, Player);
		
		if ( NewRating >= 30 )
			return P;
		if ( NewRating > BestRating )
		{
			BestRating = NewRating;
			BestStart = P;
		}
	}
	
	// Random points : start part
	for ( i = 0; i < RandStart; i++)
	{
		P = PlayerStarts[i];
		NewRating = RatePlayerStart(P, InTeam, Player);
		
		if ( NewRating >= 30 )
			return P;
		if ( NewRating > BestRating )
		{
			BestRating = NewRating;
			BestStart = P;
		}
	}
	return BestStart;
}


/*---Team attribution ---*/
function SetTeam(Controller Other, DVTeamInfo NewTeam, bool bNewTeam)
{
	local Actor A;

	// Init
	if ( Other.PlayerReplicationInfo == None )
		return;
	if (Other.PlayerReplicationInfo.Team != None || !ShouldSpawnAtStartSpot(Other))
		Other.StartSpot = None;

	// Team removal
	if ( Other.PlayerReplicationInfo.Team != None )
	{
		Other.PlayerReplicationInfo.Team.RemoveFromTeam(Other);
		Other.PlayerReplicationInfo.Team = none;
	}
	
	// Team setting
	if ( NewTeam == None || (NewTeam != None && NewTeam.AddToTeam(Other)) )
	{
		if ( (NewTeam!=None) && ((WorldInfo.NetMode != NM_Standalone) || (PlayerController(Other) == None) || (PlayerController(Other).Player != None)) )
			BroadcastLocalizedMessage( GameMessageClass, 3, Other.PlayerReplicationInfo, None, NewTeam );
	}
	if ( (PlayerController(Other) != None) && (LocalPlayer(PlayerController(Other).Player) != None) )
	{
		ForEach AllActors(class'Actor', A)
		{
			A.NotifyLocalPlayerTeamReceived();
		}
	}
	
	// Enemy team
	if (NewTeam.TeamIndex == 0)
		DVPlayerController(Other).SetEnemyTeamInfo(Teams[1]);
	else
		DVPlayerController(Other).SetEnemyTeamInfo(Teams[0]);
}


/*--- Pick a team ! ---*/
function byte PickTeam(byte num, Controller C)
{
	if (Teams[0].Size > Teams[1].Size)
		return 1;
	else
		return 0;
}


/*--- Team storage ---*/
function CreateTeam(int TeamIndex)
{
	Teams[TeamIndex] = spawn(TeamInfoClass);
	Teams[TeamIndex].Initialize(TeamIndex);
	GameReplicationInfo.SetTeam(TeamIndex, Teams[TeamIndex]);
}


/*--- Changing teams ---*/
function bool ChangeTeam(Controller Other, int num, bool bNewTeam)
{
	`log("ChangeTeam "$ Other $" "$ num $" "$ bNewTeam);
	SetTeam(Other, Teams[num], bNewTeam);
	return true;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Settings
	bTeamGame=true
	EndGameTick=0.5
	
	// Classes
	HUDType=class'DVHUD'
	DefaultPawnClass=class'DVPawn'
	TeamInfoClass=class'DVCore.DVTeamInfo'
	PlayerControllerClass=class'DVPlayerController'
	PlayerReplicationInfoClass=class'DVCore.DVPlayerRepInfo'
}
