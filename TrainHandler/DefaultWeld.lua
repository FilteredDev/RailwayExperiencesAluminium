--RE Precision Weld Module.

local weld = {}

function weld.MakeWeld(part1, part2)
	local w = Instance.new("Weld")
	w.Part0 = part1
	w.Part1 = part2
	
	w.C0 = CFrame.new()
	w.C1 = part2.CFrame:toObjectSpace(part1.CFrame)
	
	w.Name = part2.Name
	w.Parent = part1
	
	part2.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,1,1)
end

function weld.WeldModel(model, joinModelTo)
	local ppart = model.PrimaryPart or model:FindFirstChildWhichIsA("Part")
	for _, v in pairs(model:GetChildren()) do
		if v:IsA("BasePart") and v ~= ppart and v.Anchored == true then
			weld.MakeWeld(ppart, v)
		end
	end
	
	if joinModelTo and ppart.Anchored == true then
		weld.MakeWeld(joinModelTo, ppart)
	end
	
	for _, v in pairs(model:GetChildren()) do
		if v:IsA("BasePart") then
			v.Anchored  = false
		end
	end
end

function weld.WeldAll(Train)
	for _, v in pairs(Train:GetDescendants()) do
		if v:IsA("Model") then
			local join
			if v.Parent ~= Train then
				join = v.Parent.PrimaryPart or v.Parent:FindFirstChildWhichIsA("Part")
			end
			
			weld.WeldModel(v, join)
		end
	end
end

return weld
