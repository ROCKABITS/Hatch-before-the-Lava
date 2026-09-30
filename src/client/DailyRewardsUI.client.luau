local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local DailyRewardsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DailyRewardsConfig")
)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local dailyRewards = remotes:WaitForChild("DailyRewards")

local oldGui = playerGui:FindFirstChild("DailyRewardsUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "DailyRewardsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenDaily"
openButton.Position = UDim2.fromOffset(18, 20)
openButton.Size = UDim2.fromOffset(118, 54)
openButton.BackgroundColor3 = Color3.fromRGB(92, 92, 120)
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Text = "🎁 DAILY"
openButton.TextScaled = true
openButton.Font = Enum.Font.GothamBold
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 14)
openCorner.Parent = openButton

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(680, 410)
panel.BackgroundColor3 = Color3.fromRGB(28, 29, 38)
panel.Visible = false
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(22, 14)
title.Size = UDim2.new(1, -90, 0, 46)
title.Text = "🎁 DAILY REWARDS"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 30
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -60, 0, 12)
close.Size = UDim2.fromOffset(44, 44)
close.BackgroundColor3 = Color3.fromRGB(60, 62, 78)
close.TextColor3 = Color3.new(1, 1, 1)
close.Text = "×"
close.TextScaled = true
close.Font = Enum.Font.GothamBold
close.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = close

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(22, 62)
subtitle.Size = UDim2.new(1, -44, 0, 30)
subtitle.Text = "Come back every day to keep the 7-day cycle going."
subtitle.TextColor3 = Color3.fromRGB(190, 190, 205)
subtitle.TextSize = 17
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = panel

local cards = {}

for day = 1, 7 do
	local card = Instance.new("Frame")
	card.Name = "Day" .. day
	card.Position = UDim2.fromOffset(20 + ((day - 1) * 92), 110)
	card.Size = UDim2.fromOffset(82, 150)
	card.BackgroundColor3 = Color3.fromRGB(48, 50, 64)
	card.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	local dayLabel = Instance.new("TextLabel")
	dayLabel.BackgroundTransparency = 1
	dayLabel.Position = UDim2.fromOffset(6, 8)
	dayLabel.Size = UDim2.new(1, -12, 0, 30)
	dayLabel.Text = "DAY " .. day
	dayLabel.TextColor3 = Color3.new(1, 1, 1)
	dayLabel.TextSize = 17
	dayLabel.Font = Enum.Font.GothamBold
	dayLabel.Parent = card

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromOffset(8, 42)
	icon.Size = UDim2.new(1, -16, 0, 42)
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Parent = card

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Position = UDim2.fromOffset(6, 88)
	rewardLabel.Size = UDim2.new(1, -12, 0, 54)
	rewardLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	rewardLabel.TextSize = 14
	rewardLabel.TextWrapped = true
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.Parent = card

	local reward = DailyRewardsConfig.Rewards[day]

	if reward.Type == "Coins" then
		icon.Text = "🪙"
	elseif reward.Type == "LuckBoost" then
		icon.Text = "🍀"
	elseif reward.Type == "PetXPPotion" then
		icon.Text = "🧪"
	elseif reward.Type == "Egg" then
		icon.Text = "🥚"
	else
		icon.Text = "🐉"
	end

	rewardLabel.Text = reward.Display

	cards[day] = {
		Frame = card,
		Reward = rewardLabel,
	}
end

local inventory = Instance.new("TextLabel")
inventory.BackgroundTransparency = 1
inventory.Position = UDim2.fromOffset(22, 274)
inventory.Size = UDim2.new(1, -44, 0, 28)
inventory.TextColor3 = Color3.fromRGB(205, 205, 218)
inventory.TextSize = 16
inventory.TextXAlignment = Enum.TextXAlignment.Center
inventory.Font = Enum.Font.Gotham
inventory.Parent = panel

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(22, 306)
status.Size = UDim2.new(1, -44, 0, 30)
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 18
status.Font = Enum.Font.GothamBold
status.Parent = panel

local claim = Instance.new("TextButton")
claim.AnchorPoint = Vector2.new(0.5, 1)
claim.Position = UDim2.new(0.5, 0, 1, -20)
claim.Size = UDim2.fromOffset(260, 54)
claim.BackgroundColor3 = Color3.fromRGB(255, 125, 40)
claim.TextColor3 = Color3.new(1, 1, 1)
claim.Text = "CLAIM"
claim.TextSize = 22
claim.Font = Enum.Font.GothamBold
claim.Parent = panel

local claimCorner = Instance.new("UICorner")
claimCorner.CornerRadius = UDim.new(0, 14)
claimCorner.Parent = claim

local currentStatus = nil
local busy = false

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	return string.format("%02dh %02dm", hours, minutes)
end

local function applyStatus(response)
	currentStatus = response

	if not response or not response.Success then
		status.Text = response and response.Message or "Could not load daily rewards."
		claim.Active = false
		claim.AutoButtonColor = false
		claim.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		return
	end

	for day = 1, 7 do
		local selected = day == response.Day
		cards[day].Frame.BackgroundColor3 =
			selected and Color3.fromRGB(83, 72, 47) or Color3.fromRGB(48, 50, 64)
	end

	inventory.Text = string.format(
		"🍀 Luck Boosts: %d    •    🧪 Pet XP Potions: %d",
		response.LuckBoosts or player:GetAttribute("LuckBoosts") or 0,
		response.PetXPPotions or player:GetAttribute("PetXPPotions") or 0
	)

	if response.CanClaim then
		status.Text = string.format("Day %d reward is ready!", response.Day)
		claim.Text = "🎁 CLAIM REWARD"
		claim.Active = true
		claim.AutoButtonColor = true
		claim.BackgroundColor3 = Color3.fromRGB(255, 125, 40)
		openButton.Text = "🎁 DAILY!"
	else
		local remaining = (response.NextClaimUnix or os.time()) - os.time()
		status.Text = "Next reward in " .. formatTime(remaining)
		claim.Text = "✓ CLAIMED"
		claim.Active = false
		claim.AutoButtonColor = false
		claim.BackgroundColor3 = Color3.fromRGB(70, 115, 78)
		openButton.Text = "✓ DAILY"
	end
end

local function loadStatus()
	if busy then
		return
	end

	busy = true
	local response = dailyRewards:InvokeServer("Status")
	busy = false

	applyStatus(response)
end

local function waitForData()
	if player:GetAttribute("DataLoaded") == true then
		return
	end

	repeat
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	until player:GetAttribute("DataLoaded") == true
end

openButton.Activated:Connect(function()
	panel.Visible = true
	loadStatus()
end)

close.Activated:Connect(function()
	panel.Visible = false
end)

claim.Activated:Connect(function()
	if busy or not claim.Active then
		return
	end

	busy = true
	claim.Active = false
	claim.Text = "CLAIMING..."

	local response = dailyRewards:InvokeServer("Claim")
	busy = false

	if response and response.Success and response.Claimed then
		status.Text = "🎉 You received: " .. tostring(response.Reward)
	end

	applyStatus(response)
end)

task.spawn(function()
	waitForData()
	loadStatus()

	while gui.Parent do
		task.wait(30)

		if currentStatus and not currentStatus.CanClaim and currentStatus.NextClaimUnix then
			local remaining = currentStatus.NextClaimUnix - os.time()

			if remaining <= 0 then
				loadStatus()
			elseif panel.Visible then
				status.Text = "Next reward in " .. formatTime(remaining)
			end
		end
	end
end)
