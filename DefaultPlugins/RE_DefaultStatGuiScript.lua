local TextService = game:GetService("TextService")
local NAME_STRING = "Throttle for Railway Experiences"

local Gui = script.Parent
local StatLabel = script.LabelTemplate
local FORMAT_STRING = "%s: %s"

local Environment = Gui.Parent
local Values = Environment.Values

wait(1)

function makeLabel(txt)
	local nl = StatLabel:Clone()
	local TextBounds = TextService:GetTextSize(txt, 14, Enum.Font.Code, Vector2.new(math.huge, 14))
	
	nl.Text = txt
	nl.Size = UDim2.new(0, TextBounds.X, 0, 14)
	nl.Parent = Gui
	
	nl.Visible = true
	
	return nl
end

makeLabel(NAME_STRING)

for i, v in ipairs(Values:GetChildren()) do
	if not v:IsA("ValueBase") then continue end
	
	local label = makeLabel(string.format(FORMAT_STRING, v.Name, v.Value))
	label.LayoutOrder = i
	
	v:GetPropertyChangedSignal("Value"):Connect(function()
		local Value = v.Value
		local Text = string.format(FORMAT_STRING, v.Name, v.Value)
		
		local TextBounds = TextService:GetTextSize(Text, 14, Enum.Font.Code, Vector2.new(math.huge, 14))
		label.Text = Text
		label.Size = UDim2.new(0, TextBounds.X, 0, 14)
	end)
end
