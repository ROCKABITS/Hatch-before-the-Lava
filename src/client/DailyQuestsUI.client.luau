local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local dailyQuests = remotes:WaitForChild("DailyQuests")

local oldGui = playerGui:FindFirstChild("DailyQuestsUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "DailyQuestsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenQuests"
openButton.Position = UDim2.fromOffset(18, 84)
openButton.Size = UDim2.fromOffset(118, 54)
openButton.BackgroundColor3 = Color3.fromRGB(72, 110, 145)
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Text = "📋 QUESTS"
openButton.TextScaled = true
openButton.Font = Enum.Font.GothamBold
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 14)
openCorner.Parent = openButton

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(620, 430)
panel.BackgroundColor3 = Color3.fromRGB(28, 29, 38)
panel.Visible = false
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 12)
title.Size = UDim2.new(1, -90, 0, 48)
title.Text = "📋 DAILY QUESTS"
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
subtitle.Position = UDim2.fromOffset(20, 62)
subtitle.Size = UDim2.new(1, -40, 0, 28)
subtitle.Text = "3 quests change every day."
subtitle.TextColor3 = Color3.fromRGB(190, 190, 205)
subtitle.TextSize = 17
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = panel

local list = Instance.new("Frame")
list.BackgroundTransparency = 1
list.Position = UDim2.fromOffset(20, 102)
list.Size = UDim2.new(1, -40, 0, 250)
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local feedback = Instance.new("TextLabel")
feedback.BackgroundTransparency = 1
feedback.AnchorPoint = Vector2.new(0.5, 1)
feedback.Position = UDim2.new(0.5, 0, 1, -18)
feedback.Size = UDim2.new(1, -40, 0, 36)
feedback.Text = ""
feedback.TextColor3 = Color3.fromRGB(255, 220, 80)
feedback.TextSize = 18
feedback.Font = Enum.Font.GothamBold
feedback.Parent = panel

local loading = false
local lastStatus = nil

local function clearRows()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function makeClaimButton(parent)
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -12, 0.5, 0)
	button.Size = UDim2.fromOffset(120, 42)
	button.BackgroundColor3 = Color3.fromRGB(255, 125, 40)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "CLAIM"
	button.TextSize = 17
	button.Font = Enum.Font.GothamBold
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return button
end

local function renderStatus(response)
	lastStatus = response
	clearRows()

	if not response or not response.Success then
		feedback.Text = response and response.Message or "Could not load quests."
		return
	end

	local claimableCount = 0

	for index, quest in ipairs(response.Quests or {}) do
		local row = Instance.new("Frame")
		row.Name = quest.Id
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, 76)
		row.BackgroundColor3 = Color3.fromRGB(47, 49, 62)
		row.Parent = list

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 12)
		rowCorner.Parent = row

		local questTitle = Instance.new("TextLabel")
		questTitle.BackgroundTransparency = 1
		questTitle.Position = UDim2.fromOffset(14, 8)
		questTitle.Size = UDim2.new(1, -160, 0, 28)
		questTitle.Text = quest.Title
		questTitle.TextColor3 = Color3.new(1, 1, 1)
		questTitle.TextSize = 19
		questTitle.TextXAlignment = Enum.TextXAlignment.Left
		questTitle.Font = Enum.Font.GothamBold
		questTitle.Parent = row

		local progress = Instance.new("TextLabel")
		progress.BackgroundTransparency = 1
		progress.Position = UDim2.fromOffset(14, 39)
		progress.Size = UDim2.new(1, -160, 0, 25)
		progress.Text = string.format(
			"%d / %d   •   🎁 %s",
			quest.Progress,
			quest.Target,
			quest.Reward
		)
		progress.TextColor3 = Color3.fromRGB(205, 205, 218)
		progress.TextSize = 16
		progress.TextXAlignment = Enum.TextXAlignment.Left
		progress.Font = Enum.Font.Gotham
		progress.Parent = row

		local claimButton = makeClaimButton(row)

		if quest.Claimed then
			claimButton.Text = "✓ CLAIMED"
			claimButton.Active = false
			claimButton.AutoButtonColor = false
			claimButton.BackgroundColor3 = Color3.fromRGB(70, 115, 78)
		elseif quest.Complete then
			claimableCount += 1
			claimButton.Text = "CLAIM"
		else
			claimButton.Text = string.format("%d%%", math.floor((quest.Progress / quest.Target) * 100))
			claimButton.Active = false
			claimButton.AutoButtonColor = false
			claimButton.BackgroundColor3 = Color3.fromRGB(75, 75, 88)
		end

		claimButton.Activated:Connect(function()
			if loading or not claimButton.Active then
				return
			end

			loading = true
			claimButton.Active = false
			claimButton.Text = "..."

			local claimResponse = dailyQuests:InvokeServer("Claim", quest.Id)

			loading = false

			if claimResponse and claimResponse.Success and claimResponse.Claimed then
				feedback.Text = "🎉 Reward: " .. tostring(claimResponse.Reward)
			else
				feedback.Text = claimResponse and claimResponse.Message or "Could not claim reward."
			end

			renderStatus(claimResponse)
		end)
	end

	if claimableCount > 0 then
		openButton.Text = "📋 QUESTS!"
	else
		openButton.Text = "📋 QUESTS"
	end
end

local function loadStatus()
	if loading then
		return
	end

	loading = true
	local response = dailyQuests:InvokeServer("Status")
	loading = false
	renderStatus(response)
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
	feedback.Text = ""
	loadStatus()
end)

close.Activated:Connect(function()
	panel.Visible = false
end)

task.spawn(function()
	waitForData()
	loadStatus()

	while gui.Parent do
		task.wait(1)

		if panel.Visible then
			loadStatus()
		end
	end
end)
