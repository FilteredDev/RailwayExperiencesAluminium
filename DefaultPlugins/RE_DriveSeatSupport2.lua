local module = {}
--//Adds DriveSeat support to RE (updated for the OOP Changes to RETS)
local Players = game:GetService("Players")
local RETS_v2 = require(game:GetService("ServerStorage").Modules.RailwayExperiencesTrainHandler)

local Events = {}
local FrontSeat
local RearSeat
local Object
local Train
local ActiveSeat

local DestroyOnLeave = true

local function SeatHandler(seat)
	local Driver = Train.RailwayExperiencesEnvironment.Driver.Value
	local oc = seat.Occupant
	
	if oc and Driver == nil and ActiveSeat == nil then
		local c = oc.Parent
		local getPlr = Players:GetPlayerFromCharacter(c)
		if getPlr then
			ActiveSeat = seat
			Object:ClaimTrain(getPlr, seat.Parent.Name)
		end
	elseif oc == nil and seat == ActiveSeat then
		local getDriver = Train.RailwayExperiencesEnvironment.Driver.Value
		Object:UnclaimTrain(getDriver)
		ActiveSeat = nil
		
		if DestroyOnLeave == true then
			Object.Despawning = true --we want to block the internal deletion methods
			Train:Destroy()
		end
	end
end

function module.initialise(train_id) --train is now fetched using the OOP object
	Object = RETS_v2:GetTrain(train_id)
	Train = Object.Train
	FrontSeat = Object.Coaches[1].Coach.DriveSeat
	RearSeat = Object.Coaches[#Object.Coaches].Coach.DriveSeat
	
	FrontSeat:GetPropertyChangedSignal("Occupant"):Connect(function() SeatHandler(FrontSeat) end)
	RearSeat:GetPropertyChangedSignal("Occupant"):Connect(function() SeatHandler(RearSeat) end)
end

return module
