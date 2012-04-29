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


simulated event ReplicatedEvent(name VarName)
{
	`log ("REPLICATION EVENT IN " $ self $ " FOR " $ VarName);
	if ( VarName == 'Score' )
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
	return Score * 2;
}

reliable server simulated function LogScore()
{
	`log("New score is "$ Score);
}

reliable server simulated function AddKill(bool bTeamKill)
{
	`log("AddKill " $ self);
	if (bTeamKill)
		Score -= 1;
	else
		Score += 1;
	
	// End
	Score = Clamp (Score, 0, 65000);
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
