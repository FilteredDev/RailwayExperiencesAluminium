local HttpService = game:GetService("HttpService")
local Environment = script.Parent

local DefaultWeld = require(Environment.DefaultWeld)

local Module = {}
local Methods = {}
Methods.__index = Methods

--//PRIVATE FUNCTIONS
local function GetOrCreate(name, parent, createIfNotExist)
	local obj = parent:FindFirstChild(name)

	if not obj then	
		obj = Instance.new(createIfNotExist)
		obj.Name = name
		obj.Parent = parent
	end
	
	return obj
end

local function Modify(part, props)
	for property, value in pairs(props) do
		part[property] = value
	end
end

local function CreateGui(player, cab, object)
	local gui = object.ClientController:Clone()
	local CabIndex = GetOrCreate("CabIndex", gui.Values, "StringValue")
	
	local front = object:GetGlobalValue("Front")
	local rear = object:GetGlobalValue("Rear")
	
	print(cab, front.Coach.Name)
	
	if cab == front.Coach.Name then
		cab = "Front"
	else
		cab = "Rear"
	end
	
	CabIndex.Value = cab
	for _, v in pairs(object.Train.RailwayExperiencesEnvironment.Plugins:GetChildren()) do
		if not v:IsA("ModuleScript") then
			local Plugin = v:Clone()
			Plugin.Parent = gui
		end
	end
	
	gui.TrainModel.Value = object.Train
	gui.Parent = player.PlayerGui
	
	object.ClientController = gui
end

local function CreateValue(name, value, parent, vType)
	local newValue = Instance.new(vType)
	newValue.Value = value
	newValue.Name = name
	newValue.Parent = parent
end

local function Couple(object, coach1, coach2, rod_name)
	local rod = Instance.new("RodConstraint")
	
	local Part0 = (coach1.RE_CoachConfig.Direction.Value == 1 and coach1.CouplerRear) or coach1.CouplerFront
	local Part1 = (coach2.RE_CoachConfig.Direction.Value == 1 and coach2.CouplerFront) or coach2.CouplerRear
	
	rod.Attachment0 = Part0.Attachment
	rod.Attachment1 = Part1.Attachment
	
	rod.Name = rod_name or "RodConstraint"
	rod.Parent = Part0
	rod.Length = rod.CurrentDistance
end

local function LoadModules(obj)
	for _, v in pairs(obj.Train.RailwayExperiencesEnvironment.Plugins:GetChildren()) do
		if v:IsA("ModuleScript") then
			local s, e = pcall(function() require(v).initialise(obj.ID) end)
			if s == false then warn(v.Name, e) end
		end
	end
end

--//OBJECT METHODS
function Methods:AddCarriageToModel(coachModel, Reversed, StartCFrame, ZIndex, Name)
	coachModel.RE_CoachConfig.Direction.Value = (Reversed == true and - 1) or 1
	
	local getStartPos = StartCFrame + (StartCFrame.lookVector * -ZIndex)
	
	local trainLength = coachModel:GetExtentsSize().Z
	
	local spawnPos = getStartPos + Vector3.new(0,0,trainLength / 2)
	coachModel:SetPrimaryPartCFrame(spawnPos)
	
	if Reversed then
		coachModel:SetPrimaryPartCFrame(coachModel:GetPrimaryPartCFrame() * CFrame.fromOrientation(0, math.pi, 0))
	end
	
	coachModel.Name = Name or HttpService:GenerateGUID(false)
	coachModel.Parent = self.Train
	return trainLength
end

function Methods:SetGlobalValue(name, value)
	self.GlobalValues[name] = value
end

function Methods:GetGlobalValue(name)
	return self.GlobalValues[name]
end

function Methods:Weld(weldScript)
	DefaultWeld.WeldAll(self.Train)
end

function Methods:SpawnTrain(regionStartPoint, spawnBackwards)
	self.Train.Parent = GetOrCreate("RE_LoadedTrains", workspace, "Folder")
	
	for i, v in ipairs(self.Coaches) do
		local cl = self:AddCarriageToModel(v.Coach, v.Reversed, regionStartPoint, self.Length)
		self.Length = self.Length + cl
		
		if i ~= 1 then
			Couple(self, self.Coaches[i-1].Coach, v.Coach, i-1 .. "_" .. i)
		end
	end
	
	if spawnBackwards == true then
		self:SetGlobalValue("Front", self.Coaches[#self.Coaches])
		self:SetGlobalValue("Rear", self.Coaches[1])
	else
		self:SetGlobalValue("Rear", self.Coaches[#self.Coaches])
		self:SetGlobalValue("Front", self.Coaches[1])
	end
	
	self:Weld()
	LoadModules(self)
	
	self.Train.ChildRemoved:Connect(function(car)
		if self.Despawning == true then return nil end
		if car:IsA("Model") then
			self.Despawning = true
			warn(string.format("[%s]: Fell out of world exception", self.Train.Name))
			
			local drv=self.Train.RailwayExperiencesEnvironment.Driver.Value
			if drv then
				drv.PlayerGui.ClientController:Destroy()
			end
			
			self.Train:Destroy()
			self = nil
		end
	end)
end

function Methods:ClaimTrain(player, cab)
	if self.Train.RailwayExperiencesEnvironment.Driver.Value then return nil end
	self.Train.RailwayExperiencesEnvironment.Driver.Value = player
	
	for _, v in pairs(self.Train:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Anchored == false then
				v:SetNetworkOwner(player)
			end
		end
	end
	
	CreateGui(player, cab, self)
end

function Methods:UnclaimTrain(plr)
	self.Train.RailwayExperiencesEnvironment.Driver.Value = nil
	for _, v in pairs(self.Train:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Anchored == false then
				v:SetNetworkOwner()
			end
		end
	end
	
	if self.ClientController then
		self.ClientController:Destroy()
	end
end

--//PRIVATE CONSTRUCTOR FUNCTIONS
local function setConsist(Object, consist)
	for i, v in pairs(consist.Consist) do
		local Coach = {
			Coach = v.Model:Clone(),
			Reversed = v.Reversed
		}
		
		Coach.Coach.RE_CoachConfig.Direction.Value = (Coach.Reversed == true and -1) or 1
		Object.Coaches[i] = Coach
	end
end

local function setPlugins(Object, consist)
	local TRAIN_PLUGIN_FOLDER = GetOrCreate("Plugins", Object.Train.RailwayExperiencesEnvironment, "Folder")

	local cPluginFolder = consist.Folder.Plugins
	local tPluginFolder = TRAIN_PLUGIN_FOLDER
	
	for _, v in pairs(cPluginFolder:GetChildren()) do
		local p = v:Clone()
		p.Parent = tPluginFolder
	end
	
	for _, v in pairs(Environment.GlobalPlugins:GetChildren()) do
		if not cPluginFolder:FindFirstChild(v.Name) then
			local drop = v:Clone()
			drop.Parent = tPluginFolder
		end
	end
end


--//PUBLIC CONSTRUCTOR
function Module.new(consist, tuningStats)
	local obj = setmetatable({}, Methods)
	obj.ID = HttpService:GenerateGUID(false)
	
	obj.Coaches = {}
	obj.CouplerConstraints = {}
	obj.GlobalValues = {}
	
	obj.TrainTune = require(tuningStats)
	
	obj.ClientController = nil
	obj.Length = 0
	obj.Despawning = false
	
	obj.Train = Environment.DefaultRETrain:Clone()
	obj.Train.Name = obj.ID
	
	--//Loader Constructors (do not use these please :3)
	setConsist(obj, consist)
	setPlugins(obj, consist)
	
	obj:SetGlobalValue("ID", obj.ID)
	
	return obj
end

return Module
