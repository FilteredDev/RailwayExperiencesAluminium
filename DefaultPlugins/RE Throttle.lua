--//RE THROTTLE
--//VERSION ?0.1
--//FilteredDev and Ondrik132

--//SERVICES
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local LocalPlayer = game:GetService("Players").LocalPlayer

--//VARIABLES
local Environment = script.Parent
local Camera = workspace.CurrentCamera
local Train = Environment.TrainModel.Value

local Object = Train.RailwayExperiencesEnvironment.GetSelf:InvokeServer()
local _Tune = Object.TrainTune

local Values = Environment.Values
local Motors = {}
local ContextActions = {}
local CALocks = {}

--//Simulation Variables
local Speed = 0
local Acceleration = 0

local PowerPercent = 0
local BrakePercent = 0

local ThrottleNotch = 0
local BrakeNotch = 0
local IsCombinedLever = _Tune.IsCombinedLever or false

local TargetPowerPercent = 0
local TargetBrakePercent = 0

--//CONSTANTS
local FRONT = Object.GlobalValues.Front
local REAR = Object.GlobalValues.Rear
local CABINDEX_TONUMBER = {Front = 1, Rear = -1}

--//VARIABLE DECLARATION FUNCTION
local function GetOrCreate(name, parent, createIfNotExist)
	local obj = parent:FindFirstChild(name)

	if not obj then	
		obj = Instance.new(createIfNotExist)
		obj.Name = name
		obj.Parent = parent
	end
	
	return obj
end

--//IsKeyDownAnalog function
local function IsKeyDownAnalog(inputObject)
	--//Adds support for analog buttons on gamepads
	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		return UserInputService:IsKeyDown(inputObject.KeyCode)
	else
		return inputObject.Delta.Z > 0
	end
end

--//VALUE CREATION
local SpeedValue = GetOrCreate("Speed", Environment.Values, "NumberValue")
local AccelerationValue = GetOrCreate("Acceleration", Environment.Values, "NumberValue")
local ThrottleLeverValue = GetOrCreate("ThrottleLeverPosition", Environment.Values, "NumberValue")
local BrakeLeverValue = GetOrCreate("BrakeLeverPosition", Environment.Values, "NumberValue")
local PowerValue = GetOrCreate("PowerPercentage", Environment.Values, "NumberValue")
local BrakeValue = GetOrCreate("BrakePercentage", Environment.Values, "NumberValue")
local PowerTargetValue = GetOrCreate("PowerTargetPercentage", Environment.Values, "NumberValue")
local BrakeTargetValue = GetOrCreate("BrakeTargetPercentage", Environment.Values, "NumberValue")
local CabIndex = GetOrCreate("CabIndex", Environment.Values, "NumberValue")

--//OTHER FUNCTIONS
local function BindCamera()
	local getCoach = (CabIndex.Value == "Front" and FRONT) or REAR
	Camera.CameraSubject = getCoach.Coach:FindFirstChild("Body") or getCoach.Coach.PrimaryPart or getCoach.Coach:FindFirstChildWhichIsA("Part")
end

local function Switch(state)
	if state == Enum.UserInputState.Begin then
		if Speed <= _Tune.CabSwitchSpeed then
			CabIndex.Value = (CabIndex.Value == "Front" and "Rear") or "Front"
			BindCamera()
		end
	end
end

local function InitialiseMotors()
	for _, v in pairs(Train:GetChildren()) do
		if v:IsA("Model") then
			local BodyVelocity = v.PrimaryPart:FindFirstChildWhichIsA("BodyVelocity")
			if not BodyVelocity then
				BodyVelocity = Instance.new("BodyVelocity")
				BodyVelocity.MaxForce = Vector3.new()
				BodyVelocity.Parent = v.PrimaryPart
			end
				
			Motors[#Motors + 1] = BodyVelocity
		end
	end
end

local function SetTargets(isCombined)
	if isCombined == true then
		TargetPowerPercent = math.clamp(ThrottleNotch, 0, _Tune.Lever1Notches) * (_Tune.MaxPower / _Tune.Lever1Notches)				
		TargetBrakePercent = math.clamp(-ThrottleNotch, 0, _Tune.Lever2Notches) * (_Tune.MaxBrake / _Tune.Lever2Notches)
	else
		TargetPowerPercent = math.clamp(ThrottleNotch, 0, _Tune.Lever1Notches) * (_Tune.MaxPower / _Tune.Lever1Notches)				
		TargetBrakePercent = math.clamp(BrakeNotch, 0, _Tune.Lever2Notches) * (_Tune.MaxBrake / _Tune.Lever2Notches)
	end
	
	PowerTargetValue.Value = TargetPowerPercent
	BrakeTargetValue.Value = TargetBrakePercent
	ThrottleLeverValue.Value = ThrottleNotch
	BrakeLeverValue.Value = BrakeNotch
end

local function UpdateStats(delta)
	local PowerSpeed = _Tune.PowerMovementSpeed * delta
	local BrakeSpeed = _Tune.BrakeMovementSpeed * delta
	
	if PowerPercent < TargetPowerPercent then
		PowerPercent = math.clamp(PowerPercent + PowerSpeed, 0, TargetPowerPercent)
	elseif PowerPercent > TargetPowerPercent then
		PowerPercent = math.clamp(PowerPercent - PowerSpeed, TargetPowerPercent, math.huge)
	else
		PowerPercent = TargetPowerPercent
	end
	
	if BrakePercent < TargetBrakePercent then
		BrakePercent = math.clamp(BrakePercent + BrakeSpeed, 0, TargetBrakePercent)
	elseif BrakePercent > TargetBrakePercent then
		BrakePercent = math.clamp(BrakePercent - BrakeSpeed, TargetBrakePercent, math.huge)
	else
		BrakePercent = TargetBrakePercent
	end
	
	Acceleration = PowerPercent - BrakePercent
	
	PowerValue.Value = PowerPercent
	BrakeValue.Value = BrakePercent
	AccelerationValue.Value = Acceleration
end

ContextActions.IncreaseLever1 = function(inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		CALocks.IncreaseLever1 = true
		while IsKeyDownAnalog(inputObject) and ThrottleNotch < _Tune.Lever1Notches do
			local Clamp = (IsCombinedLever == true and -_Tune.Lever2Notches) or 0
			
			ThrottleNotch = math.clamp(ThrottleNotch + 1, Clamp, _Tune.Lever1Notches)	
			SetTargets(IsCombinedLever)
			
			wait(0.2)
		end
		CALocks.IncreaseLever1 = nil
	end
end

ContextActions.DecreaseLever1 = function(inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		CALocks.DecreaseLever1 = true
		local Clamp = (IsCombinedLever == true and -_Tune.Lever2Notches) or 0
		while IsKeyDownAnalog(inputObject) and ThrottleNotch > Clamp do
			
			ThrottleNotch = math.clamp(ThrottleNotch - 1, Clamp, _Tune.Lever1Notches)	
			SetTargets(IsCombinedLever)
			
			wait(0.2)
		end
		CALocks.DecreaseLever1 = nil
	end
end

ContextActions.IncreaseLever2 = function(inputState, inputObject)
	if IsCombinedLever == true then return end
	if inputState == Enum.UserInputState.Begin then
		CALocks.IncreaseLever2 = true
		while IsKeyDownAnalog(inputObject) and BrakeNotch < _Tune.Lever2Notches do
			BrakeNotch = math.clamp(BrakeNotch + 1, 0, _Tune.Lever2Notches)	
			SetTargets(IsCombinedLever)
			
			wait(0.2)
		end
		CALocks.IncreaseLever2 = nil
	end
end

ContextActions.DecreaseLever2 = function(inputState, inputObject)
	if IsCombinedLever == true then return end
	if inputState == Enum.UserInputState.Begin then
		CALocks.DecreaseLever2 = true
		while IsKeyDownAnalog(inputObject) and BrakeNotch > 0 do
			BrakeNotch = math.clamp(BrakeNotch - 1, 0, _Tune.Lever2Notches)	
			SetTargets(IsCombinedLever)
			
			wait(0.2)
		end
		CALocks.DecreaseLever2 = nil
	end
end

ContextActions.SwitchCab = Switch

--//CAS Binding
local function ActionHandler(actionName, state, obj)
	if CALocks[actionName] then return end
	if ContextActions[actionName] then
		ContextActions[actionName](state, obj)
	end
end

--//MAIN
ContextActionService:BindAction("IncreaseLever1", ActionHandler, false, _Tune.Keybinds.Keyboard.IncreaseLever1, _Tune.Keybinds.Gamepad.IncreaseLever1)
ContextActionService:BindAction("DecreaseLever1", ActionHandler, false, _Tune.Keybinds.Keyboard.DecreaseLever1, _Tune.Keybinds.Gamepad.DecreaseLever1)
ContextActionService:BindAction("IncreaseLever2", ActionHandler, false, _Tune.Keybinds.Keyboard.IncreaseLever2, _Tune.Keybinds.Gamepad.IncreaseLever2)
ContextActionService:BindAction("DecreaseLever2", ActionHandler, false, _Tune.Keybinds.Keyboard.IncreaseLever2, _Tune.Keybinds.Gamepad.DecreaseLever2)
ContextActionService:BindAction("SwitchCab", ActionHandler, false, _Tune.Keybinds.Keyboard.SwitchCab, _Tune.Keybinds.Gamepad.SwitchCab)

InitialiseMotors()
BindCamera()

RunService.Heartbeat:Connect(function(delta)
	UpdateStats(delta)
	
	Speed = math.clamp(Speed + (Acceleration * delta), 0, _Tune.MaxSpeed)
	SpeedValue.Value = Speed
	
	for _, v in pairs(Motors) do
		local look = v.Parent.CFrame.LookVector
		local cdir = v.Parent.Parent.RE_CoachConfig.Direction.Value
		
		v.MaxForce = Vector3.new(
			math.abs(_Tune.MaxForce.X * look.X),
			math.abs(_Tune.MaxForce.Y * look.Y),
			math.abs(_Tune.MaxForce.Z * look.Z)
		)
		
		v.Velocity = Speed * look * cdir * CABINDEX_TONUMBER[CabIndex.Value]
	end
end)
