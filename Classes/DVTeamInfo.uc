/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVTeamInfo extends TeamInfo;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var repnotify int 		CurrentScore;

replication
{
	if ( bNetDirty )
		CurrentScore;
}

simulated event ReplicatedEvent(name VarName)
{
	`log ("REPLICATION EVENT FOR " $ self $ " OF " $ VarName);
	if ( VarName == 'CurrentScore' )
	{
		LogScore();
		return;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Score management ---*/
reliable server simulated function int GetScore()
{
	return CurrentScore;
}

simulated function LogScore()
{
	`log("New score is "$ CurrentScore);
}

simulated function AddKill(bool bTeamKill)
{
	`log("AddKill " $ self);
	if (bTeamKill)
		CurrentScore -= 1;
	else
		CurrentScore += 1;
	CurrentScore = Clamp (CurrentScore, 0, 65000);
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
	CurrentScore=0
}
