/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GToggleButton extends GButton
	placeable;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (Button) const vector			EffectLoc;

var (Button) const rotator			EffectRot;

var (Button) const ParticleSystem	Effect;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var bool							bIsActive;


/*----------------------------------------------------------
	Public methods
----------------------------------------------------------*/

/**
 * @brief Set the label data and activates it
 * @param T					Text to display
 * @param C					Comment to display
 */
simulated function Set(string T, string C)
{
	super.Set(T, C);
	TextMaterial.SetVectorParameterValue('Color', (bIsActive ? OnLight : OffLight));
}

/**
 * @brief Set the button state
 * @param bNewState			New state to set
 */
simulated function SetState(bool bNewState)
{
	if (bEnabled)
	{
		bIsActive = bNewState;
		if (bNewState && Effect != None && WorldInfo.NetMode != NM_DedicatedServer)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(
				Effect,
				Location + (EffectLoc >> Rotation),
				EffectRot + Rotation
			);
		}
	}
	MoveSmooth((bNewState ? -ClickMove : ClickMove) >> Rotation);
	TextMaterial.SetVectorParameterValue('Color', (bNewState ? OnLight : OffLight));
}

/**
 * @brief Get the button state
 * @return					true if on
 */
simulated function bool GetState()
{
	return bIsActive;
}

/**
 * @brief Entering over state
 */
simulated function OverIn()
{
	GMenu(Owner).SetLabel(Comment);
	PlayUISound(OverSound);
}


/**
 * @brief Exiting over state
 */
simulated function OverOut()
{
	GMenu(Owner).SetLabel("");
}


/**
 * @brief Signal a release event from HUD
 * @param					true if right click (false if left)
 */
simulated function Release(bool bIsRightClick)
{
	if (bEnabled)
	{
		`log("GTB > Release" @bIsRightClick @Text);
		
		// Toggle mode
		if (bClicking)
		{
			bClicking = false;
			SetState(!bisActive);
			if (!bIsRightClick)
			{
				PressEvent(self);
			}
		}
		ClearTimer('PressTimeout');
		PlayUISound(ClickSound);
	}
}


/*----------------------------------------------------------
	Private methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	SetPress(PressCB);
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	// Behaviour
	bIsActive=false
	EffectLoc=(X=70,Y=0,Z=35)
	OffLight=(R=5.0,G=0.3,B=0.0,A=1.0)
	OnLight=(R=0.0,G=0.3,B=5.0,A=1.0)
	Effect=ParticleSystem'DV_CoreEffects.FX.PS_Flash'
}
