/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVTeamInfo extends TeamInfo;


/*----------------------------------------------------------
	Localized attributes
----------------------------------------------------------*/

var (DVTI) localized string			lName0;
var (DVTI) localized string			lName1;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Score management ---*/
reliable server simulated function int GetScore()
{
	return Score;
}

reliable server simulated function AddKill(bool bTeamKill)
{
	`log("AddKill " $ self);
	if (!bTeamKill)
		Score += 1;
}


/*--- Team name ---*/
simulated function string GetHumanReadableName()
{
	if (TeamIndex == 0)
		return lName0;
	else
		return lName1;
}


/*--- Team index ---*/
function Initialize(int NewTeamIndex)
{
	TeamIndex = NewTeamIndex;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/
defaultproperties
{
	Score=0
}
