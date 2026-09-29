local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("AFKUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "AFKUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -90)
panel.Size = UDim2.fromOffset(390, 92)
panel.BackgroundColor3 = Color3.fromRGB(31, 34, 45)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -32, 0, 34)
title.Text = "💤 AFK FARM ACTIVE"
title.TextColor3 = Color3.fromRGB(255, 224, 92)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.Parent = panel

local info = Instance.new("TextLabel")
info.BackgroundTransparency = 1
info.Position = UDim2.fromOffset(16, 42)
info.Size = UDim2.new(1, -32, 0, 40)
info.TextColor3 = Color3.new(1, 1, 1)
info.TextSize = 18
info.Font = Enum.Font.Gotham
info.Parent = panel

local function update()
	local isAFK = player:GetAttribute("IsAFK") == true
	panel.Visible = isAFK

	if not isAFK then
		return
	end

	local earned = player:GetAttribute("AFKCoinsEarned") or 0
	local perHour = player:GetAttribute("AFKCoinsPerHour") or 0

	if perHour <= 0 then
		info.Text = "Equip at least 1 pet to earn AFK Coins"
	else
		info.Text = string.format("+%d Coins this session   •   ~%d/hour", earned, perHour)
	end
end

for _, attribute in {"IsAFK", "AFKCoinsEarned", "AFKCoinsPerHour"} do
	player:GetAttributeChangedSignal(attribute):Connect(update)
end

update()
