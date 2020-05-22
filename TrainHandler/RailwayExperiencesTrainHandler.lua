local RE_TrainHandle = {}
RE_TrainHandle.Trains = {}

--//Variables
local RunService = game:GetService("RunService")

local TrainClass = require(script.TrainClass)

--//Private Functions
local function CreateValue(name, value, parent, vType)
	local newValue = Instance.new(vType)
	newValue.Value = value
	newValue.Name = name
	newValue.Parent = parent
end

local function GetOrCreate(name, parent, createIfNotExist)
	local obj = parent:FindFirstChild(name)

	if not obj then	
		obj = Instance.new(createIfNotExist)
		obj.Name = name
		obj.Parent = parent
	end
	
	return obj
end

--[[local function DropPlugins(train, folder)
	--//Handles dropping off plugin modules in the train's plugin folder and client control
	
	local cPluginFolder = folder.Plugins
	local tPluginFolder = train.RailwayExperiencesEnvironment.Plugins
	
	for _, v in pairs(cPluginFolder:GetChildren()) do
		local p = v:Clone()
		p.Parent = train.RE_Tune.Plugins
	end
	
	for _, v in pairs(script.GlobalPlugins:GetChildren()) do
		if not cPluginFolder:FindFirstChild(v.Name) then
			local drop = v:Clone()
			drop.Parent = tPluginFolder
		end
	end
	
	if not folder:FindFirstChild("ClientController") then
		local newControl = ClientController:Clone()
		newControl.Name = "ClientController"
		newControl.Parent = train.RE_Tune
	end
end

local function Drop(train, coachModel, Reversed, StartCFrame, ZIndex, Name)
	coachModel.RE_CoachConfig.Direction.Value = (Reversed == true and - 1) or 1
	
	local getStartPos = StartCFrame + (StartCFrame.lookVector * -ZIndex)
	
	local trainLength = coachModel:GetExtentsSize().Z
	
	local spawnPos = getStartPos + Vector3.new(0,0,trainLength / 2)
	coachModel:SetPrimaryPartCFrame(spawnPos)
	
	if Reversed then
		coachModel:SetPrimaryPartCFrame(coachModel:GetPrimaryPartCFrame() * CFrame.fromOrientation(0, math.pi, 0))
	end
	coachModel.Name = Name
	coachModel.Parent = train
	return coachModel, trainLength
end

local function Couple(train, coach1, coach2, rod_name)
	local rod = Instance.new("WeldConstraint")
	rod.Attachment0 = (coach1.RE_CoachConfig.Direction.Value == 1 and coach1.CouplerRear) or coach1.CouplerFront
	rod.Attachment1 = (coach2.RE_CoachConfig.Direction.Value == 1 and coach2.CouplerFront) or coach2.CouplerRear
	
	rod.Name = rod_name or "WeldConstraint"
	rod.Parent = train.RailwayExperiencesEnvironment.CouplerConstraints
end]]--
--kept for reference, do not use these functions

--//

--//Public Functions
function RE_TrainHandle:GetTrain(trainID)
	if not RE_TrainHandle.Trains[trainID] then error(trainID .. " does not exist, if calling from a client, fire the RemoteEvent 'GetSelf' found in the Environment folder") end
	return RE_TrainHandle.Trains[trainID]
end

function RE_TrainHandle:CreateTrain(consist)
	if RunService:IsClient() then error("This function can only be called from the backend server") end
	
	--uses the new TrainClass object to create an object
	local train = TrainClass.new(consist, consist.Folder:FindFirstChild("Tune") or script.RE_SimulationParts.Tune)	
	RE_TrainHandle.Trains[train.ID] = train
	
	train.ClientController = consist.Folder:FindFirstChild("ClientController") or script.DefaultClientController
	
	local GetSelfRemote = GetOrCreate("GetSelf", train.Train.RailwayExperiencesEnvironment, "RemoteFunction")
	GetSelfRemote.OnServerInvoke = function(p)
		if p == train.Train.RailwayExperiencesEnvironment.Driver.Value then
			return RE_TrainHandle:GetTrain(train.ID)
		end
	end
	
	return train
end

return RE_TrainHandle
