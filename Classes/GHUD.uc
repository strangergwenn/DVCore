/**
 *  This work is distributed under the Lesser General Public License,
 *	see LICENSE for details
 *
 *  @author Gwennaël ARBONA
 **/

class GHUD extends UDKHUD;


/*----------------------------------------------------------
	Public attributes
----------------------------------------------------------*/

var (HUD) const float				TraceOffset;

var (HUD) const bool				bUseCursor;

var (HUD) const color 				CursorColor;
var (HUD) const Texture2D 			CursorTexture;


/*----------------------------------------------------------
	Private attributes
----------------------------------------------------------*/

var string							DebugText;

var vector							TargetLocation;
var Vector2D 						MousePosition;
var Vector2D 						OldMousePosition;

var Actor							Target;

var GLabel							FocusActor;


/*----------------------------------------------------------
	Methods
----------------------------------------------------------*/

/**
 * @brief Spawn event
 */ 
simulated function PostBeginPlay()
{
	local GMenu Temp;
	super.PostBeginPlay();

	foreach AllActors(class'GMenu', Temp)
	{
		if (Temp.Index == 0)
		{
			Temp.ChangeMenu(Temp);
			return;
		}
	}
}

/**
 * @brief Post-render calculations, mostly mouse managment
 */
event PostRender()
{
	// Targetting control
	if (PlayerOwner != None) 
	{
		GetMouseWorldLocation();
		if (Target != None)
		{
			if (Target.IsA('GLabel'))
			{
				GLabel(Target).Over();
			}
		}
	}
	
	// Mouse cursor
	if (bUseCursor)
	{
		Canvas.SetPos(MousePosition.X, MousePosition.Y); 
		Canvas.DrawColor = CursorColor;
		Canvas.DrawTile(
		    CursorTexture,
		    CursorTexture.SizeX, CursorTexture.SizeY,
		    0.f, 0.f,
		    CursorTexture.SizeX, CursorTexture.SizeY
		    ,, true
		);
	}
	super.PostRender();
}

/**
 * @brief Register the last key
 * @param Key					Key used
 * @param Evt					Event type
 */
function KeyPressed(name Key, EInputEvent Evt)
{
	Debug(""$Key);
	if (Target == None)
	{
		return;
	}

	// Mouse events
	if (Key == 'LeftMouseButton' || Key == 'RightMouseButton')
	{
		// Focus was lost
		if (GLabel(Target) != FocusActor && FocusActor != None)
		{
			FocusActor.LostFocus();
		}
		
		// Button press and release
		if (Target.IsA('GButton'))
		{
			if (Evt == IE_Pressed)
			{
				FocusActor = GLabel(Target);
				GButton(Target).Press((Key == 'RightMouseButton'));
			}
			else if (Evt == IE_Released)
			{
				GButton(Target).Release((Key == 'RightMouseButton'));
			}
		}
	}
	
	// Keyboard events
	else if (Evt == IE_Pressed && FocusActor.IsA('GTextField'))
	{
		GTextField(FocusActor).KeyPressed(Key);
	}
}

/**
 * @brief Set the mouse world target and return the actor
 */
function GetMouseWorldLocation()
{
	local DVPlayerInput MouseInterfacePlayerInput;
	local Vector MouseWorldOrigin, MouseWorldDirection, HitNormal;
	
	if (Canvas != None && PlayerOwner != None)
	{
		MouseInterfacePlayerInput = DVPlayerInput(PlayerOwner.PlayerInput);
		if (MouseInterfacePlayerInput != None)
		{
			if (bUseCursor)
			{
				MousePosition.X = MouseInterfacePlayerInput.MousePosition.X;
				MousePosition.Y = MouseInterfacePlayerInput.MousePosition.Y;
			}
			else
			{
				MousePosition.X = SizeX / 2;
				MousePosition.Y = SizeY / 2;
			}
			
			if (MousePosition != OldMousePosition)
			{
				Canvas.DeProject(MousePosition, MouseWorldOrigin, MouseWorldDirection);
				Target = Trace(
					TargetLocation,
					HitNormal,
					MouseWorldOrigin + MouseWorldDirection * 65536.f,
					MouseWorldOrigin + MouseWorldDirection * TraceOffset,
					true,,, TRACEFLAG_Bullet
				);
				OldMousePosition = MousePosition;
			}
		}
	}
}

/**
 * @brief Reset the mouse at the center of the screen
 */
function ResetMouse()
{
	DVPlayerInput(PlayerOwner.PlayerInput).ResetMouse();
}

/**
 * @brief Return the current world target
 * @return Targetted actor
 */
function Actor GetCurrentTarget()
{
	return Target;
}

/**
 * @brief Display debug text on HUD
 * @param Data					Text to print
 */
function Debug(string Data)
{
	DebugText = Data;
}


/*----------------------------------------------------------
	Properties
----------------------------------------------------------*/

defaultproperties
{
	bUseCursor=true
	TraceOffset=64.0
	CursorColor=(R=255,G=255,B=255,A=255)
	CursorTexture=Texture2D'EngineResources.Cursors.Arrow'
}
