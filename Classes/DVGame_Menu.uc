/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class DVGame_Menu extends GameInfo;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/*--- Login ---*/
event PostLogin (PlayerController NewPlayer)
{
	local DVPlayerController NP;
	
	super.PostLogin(NewPlayer);
	NP = DVPlayerController(NewPlayer);
	
	NP.MasterServerLink = Spawn(class'DVLink');
	NP.MasterServerLink.InitLink(NP);
}


/*----------------------------------------------------------
	Music management
----------------------------------------------------------*/

/*--- Get the music track to play here ---*/
reliable server simulated function SoundCue GetTrackIntro()
{
	return DVMapInfo(WorldInfo.GetMapInfo()).MusicIntro;
}


/*--- Get the music track to play here ---*/
reliable server simulated function SoundCue GetTrackLoop()
{
	return DVMapInfo(WorldInfo.GetMapInfo()).MusicLoop;
}


/*--- Get the music track to play here ---*/
reliable server simulated function float GetIntroLength()
{
	local float Duration;
	
	Duration = DVMapInfo(WorldInfo.GetMapInfo()).MusicIntro.GetCueDuration();
	`log("DVG > GetIntroLength" @Duration);
	
	return Duration;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	HUDType=class'GH_Menu'
	PlayerControllerClass=class'DVPlayerController'
}
