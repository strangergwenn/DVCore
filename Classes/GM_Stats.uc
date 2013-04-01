/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GM_Stats extends GMenu;

/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var GList							Leaderboard;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Update the stats
 */
simulated function UpdateLeaderboard()
{
	// Init
	local string RankInfo;
	local DVUserStats LS;
	local DVUserStats GS;
	local array<string>	PlayerList;
	GS = DVPlayerController(PC).GlobalStats;
	LS = DVPlayerController(PC).LocalStats;

	// Stat block 1
	AddLabel(Vect(-300,0,400), lGlobalStats);
	AddLabel(Vect(-280,0,370), string(GS.Kills) @lVictims);
	AddLabel(Vect(-280,0,340), string(100 * (GS.Headshots) / GS.Kills) $"%" @lHeadshots);
	AddLabel(Vect(-280,0,310), string((100 * GS.Kills) / GS.Deaths) $"% K/D");
	AddLabel(Vect(-280,0,280), string(GS.ShotsFired) @lShotsfired);

	// Stat block 2
	AddLabel(Vect(-300,0,180), lEffByWeapon);
	AddLabel(Vect(-280,0,150), lWeapon0 @":" @string(GS.WeaponScores[0]) @lVictims);
	AddLabel(Vect(-280,0,120), lWeapon1 @":" @string(GS.WeaponScores[1]) @lVictims);
	AddLabel(Vect(-280,0,90), lWeapon2 @":" @string(GS.WeaponScores[2]) @lVictims);
	AddLabel(Vect(-280,0,60), lWeapon3 @":" @string(GS.WeaponScores[3]) @lVictims);
	AddLabel(Vect(-280,0,30), lWeapon4 @":" @string(GS.WeaponScores[4]) @lVictims);

	// Stat block 3
	AddLabel(Vect(-20,0,400), lLastGame);
	if (LS.bHasLeft)
		AddLabel(Vect(0,0,370), lFledGame);
	else
		AddLabel(Vect(0,0,370), lTeamHas @ (LS.bHasWon ? lWon : lLost));

	AddLabel(Vect(0,0,340), lLastRank @string(LS.Rank));
	AddLabel(Vect(0,0,310), string(LS.Kills) @lVictims);
	AddLabel(Vect(0,0,280), string(LS.Deaths) @lDeaths);
	AddLabel(Vect(0,0,250), string(LS.ShotsFired) @lShotsfired);

	// Stat block 4
	AddLabel(Vect(-20,0,180), lRanking);
	if (GS.Rank > 0)
		RankInfo = lYouAreRanked @ string(GS.Rank);
	else
		RankInfo = lYouAreNotRanked;
	AddLabel(Vect(0,0,150), RankInfo);
	AddLabel(Vect(0,0,120), lYouHave @ string(GS.Points) @lPoints);

	// Stat block 5
	PlayerList = DVPlayerController(PC).GetBestPlayers(false);
	Leaderboard.Set(PlayerList);
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function SpawnUI()
{
	// Init
	local GMenu NextMenu;
	local array<string>	PlayerList;

	NextMenu = GetRelatedMenu(false);
	AddMenuLink(Vect(0,0,50), NextMenu);

	// Stat block 5
	AddLabel(Vect(250,0,400), lBestPLayers);
	PlayerList = DVPlayerController(PC).GetBestPlayers(false);
	Leaderboard = AddList(Vect(270,0,400), PlayerList, class'GLI_Small');
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Menu data
	Index=-10
}
