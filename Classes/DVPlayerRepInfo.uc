/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVPlayerRepInfo extends PlayerReplicationInfo;


/*----------------------------------------------------------
	Attributes
----------------------------------------------------------*/

var int 							KillCount;
var int								DeathCount;

replication
{
	if (bNetDirty)
		DeathCount, KillCount;
}


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Replication code ---*/
simulated event ReplicatedEvent(name VarName)
{
	local DVPawn DVP;
	if ( VarName == 'Team' )
	{
		foreach WorldInfo.AllPawns(class'DVPawn', DVP)
		{
			if (DVP.PlayerReplicationInfo == self)
			{
				DVP.NotifyTeamChanged();
			}
		}
	}

	super.ReplicatedEvent(VarName);
}


/*--- Kill scored ---*/
reliable server simulated function ScorePoint (bool bTeamKill)
{
	DVTeamInfo(Team).AddKill(bTeamKill);
	
	if (bTeamKill)
		KillCount -= 1;
	else
		KillCount += 1;
}

simulated function int GetPointCount()
{
	return KillCount;
}


/*--- Death scored ---*/
reliable server simulated function ScoreDeath()
{
	DeathCount += 1;
}

simulated function int GetDeathCount()
{
	return DeathCount;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{	
	KillCount=0
	DeathCount=0
}
