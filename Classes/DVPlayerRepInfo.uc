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

var int								DeathCount;
var int								KillCount;
var bool							bUseBeam;

replication
{
	if (bNetDirty)
		DeathCount, KillCount, bUseBeam;
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
	if (role == ROLE_Authority)
	{
		DVTeamInfo(Team).AddKill(bTeamKill);
	}
	`log("ScorePoint for " $ self);
	bForceNetUpdate = true;
	
	if (bTeamKill)
		KillCount -= 1;
	else
		KillCount += 1;
}

simulated function int GetPointCount()
{
	return KillCount;
}


/*--- Replicated beam status ---*/
reliable server simulated function SetBeamState(bool NewStatus)
{
	bUseBeam = NewStatus;
	bForceNetUpdate = true;
}


/*--- Death scored ---*/
reliable server simulated function ScoreDeath()
{
	DVTeamInfo(Team).AddKill(false);
	DeathCount += 1;
	bForceNetUpdate = true;
}

simulated function int GetDeathCount()
{
	return Clamp(DeathCount, 0, 65000);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	bUseBeam=true
	KillCount=0
	DeathCount=0
}
