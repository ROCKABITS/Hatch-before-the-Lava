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
panel.Size = UDim2.fromOffset(430, 126)
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
title.Text = "💤 AFK FARMING"
title.TextColor3 = Color3.fromRGB(255, 224, 92)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.Parent = panel

local accumulated = Instance.new("TextLabel")
accumulated.BackgroundTransparency = 1
accumulated.Position = UDim2.fromOffset(16, 43)
accumulated.Size = UDim2.new(1, -32, 0, 32)
accumulated.TextColor3 = Color3.new(1, 1, 1)
accumulated.TextSize = 20
accumulated.Font = Enum.Font.GothamBold
accumulated.Parent = panel

local rate = Instance.new("TextLabel")
rate.BackgroundTransparency = 1
rate.Position = UDim2.fromOffset(16, 77)
rate.Size = UDim2.new(1, -32, 0, 34)
rate.TextColor3 = Color3.fromRGB(160, 230, 160)
rate.TextSize = 18
rate.Font = Enum.Font.Gotham
rate.Parent = panel

local function update()
	local isAFK = player:GetAttribute("IsAFK") == true
	panel.Visible = isAFK

	if not isAFK then
		return
	end

	local stored = player:GetAttribute("AFKCoinsStored") or 0
	local perMinute = player:GetAttribute("AFKCoinsPerMinute") or 0
	local perHour = player:GetAttribute("AFKCoinsPerHour") or 0

	accumulated.Text = string.format("💰 Accumulated: %d Coins", stored)

	if perMinute <= 0 then
		rate.Text = "Equip at least 1 pet to start earning"
	else
		rate.Text = string.format(
			"📈 Earning: +%.1f Coins/min   •   ~%d/hour",
			perMinute,
			perHour
		)
	end
end

for _, attribute in {
	"IsAFK",
	"AFKCoinsStored",
	"AFKCoinsPerMinute",
	"AFKCoinsPerHour",
} do
	player:GetAttributeChangedSignal(attribute):Connect(update)
end

update()
