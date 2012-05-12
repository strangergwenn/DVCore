/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVUserStats extends Object
	config(UserStats);

/*----------------------------------------------------------
	Database attributes
----------------------------------------------------------*/

var (Database) config array<int>				WeaponScores;

var (Database) config int						ShotsFired;
var (Database) config int						teamkills;
var (Database) config int						Headshots;
var (Database) config int						Kills;
var (Database) config int						Deaths;

var (Database) config int						Rank;
var (Database) config int						Points;

var (Database) config bool						bHasWon;
var (Database) config bool						bHasLeft;

var (Database) config bool						bFullScreen;
var (Database) config bool						bUseSoundOnHit;
var (Database) config bool						bBackgroundMusic;

var (Database) config string					UserName;
var (Database) config string					Password;
var (Database) config string					Resolution;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Stats erasing (global stats on init) ---*/
function EmptyStats()
{
	ShotsFired = 0;
	TeamKills = 0;
	Headshots = 0;
	Kills = 0;
	Deaths = 0;
	Rank = 0;
	Points = 0;
}


/*--- Set the new data value : boolean ---*/
function SetBoolValue(string PropertyName, bool NV)
{
	switch(PropertyName)
	{
		case ("bHasWon"): 			bHasWon = NV; 			break;
		case ("bHasLeft"): 			bHasLeft = NV; 			break;
		case ("bFullScreen"): 		bFullScreen = NV; 		break;
		case ("bUseSoundOnHit"): 	bUseSoundOnHit = NV; 	break;
		case ("bBackgroundMusic"): 	bBackgroundMusic = NV; 	break;
		default : 											break;
	}
}
 

/*--- Get the new data value : integer ---*/
function SetIntValue(string PropertyName, int NV)
{
	switch(PropertyName)
	{
		case ("ShotsFired"): 		ShotsFired = NV; 		break;
		case ("TeamKills"): 		teamkills = NV; 		break;
		case ("Headsots"): 			Headshots = NV; 		break;
		case ("Kills"): 			Kills = NV; 			break;
		case ("Rank"): 				Rank = NV; 				break;
		case ("Points"): 			Points = NV; 			break;
		case ("Deaths"): 			Deaths = NV; 			break;
		default : 											break;
	}
}


/*--- Set the new data value : integer ---*/
function SetArrayIntValue(string PropertyName, int NV, int index)
{
	switch(PropertyName)
	{
		case ("WeaponScores"): 	WeaponScores[index] = NV; 		break;
		default : 												break;
	}
}


/*--- Set the new data value : string ---*/
function SetStringValue(string PropertyName, string NV)
{
	switch(PropertyName)
	{
		case ("UserName"): 			UserName = NV; 			break;
		case ("PassWord"): 			Password = NV; 			break;
		case ("Resolution"): 		Resolution = NV; 		break;
		default : 											break;
	}
}
