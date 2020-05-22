return {
	--//Physics
	MaxForce = Vector3.new(2500000, 0, 2500000)					;
	
	MaxSpeed = 187.5											;
	MaxPower = 10												;
	MaxBrake = 20												;
	
	PowerMovementSpeed = 5										;
	BrakeMovementSpeed = 5										;

	IsCombinedLever = true										; --Use a combined brake/lever handle
	
	Lever1Notches = 4											; --(THROTTLE LEVER)
	Lever2Notches = 6											; --(BRAKE LEVER) if IsCombinedLever is true, this will act as the brake section
	
	--//Keybinds
	Keybinds = {
		Keyboard = {
			IncreaseLever1 = Enum.KeyCode.W						;
			DecreaseLever1 = Enum.KeyCode.S						;
			
			IncreaseLever2 = Enum.KeyCode.L 					;
			DecreaseLever2 = Enum.KeyCode.Semicolon 			;
			
			SwitchCab = Enum.KeyCode.C							;
		}														;
		
		Gamepad = {
			IncreaseLever1 = Enum.KeyCode.ButtonR2				;
			DecreaseLever1 = Enum.KeyCode.ButtonR1				;
			
			IncreaseLever2 = Enum.KeyCode.ButtonL2				;
			DecreaseLever2 = Enum.KeyCode.ButtonL1 				;
			
			SwitchCab = Enum.KeyCode.ButtonY					;
		}														;
	}															;
	
	--//Misc
	CabSwitchSpeed = 0
}
