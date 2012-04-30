/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVTeamInfo extends TeamInfo;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Score management ---*/
reliable server simulated function int GetScore()
{
	return Score * 2;
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
		return "Red";
	else
		return "Blue";
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
