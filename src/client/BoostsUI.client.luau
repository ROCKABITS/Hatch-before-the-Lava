local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local boostsRemote = remotes:WaitForChild("Boosts")

local oldGui = playerGui:FindFirstChild("BoostsUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BoostsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenBoosts"
openButton.Position = UDim2.fromOffset(18, 148)
openButton.Size = UDim2.fromOffset(118, 54)
openButton.BackgroundColor3 = Color3.fromRGB(120, 82, 145)
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Text = "⚡ BOOSTS"
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
panel.Size = UDim2.fromOffset(590, 405)
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
title.Text = "⚡ BOOSTS"
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
subtitle.Size = UDim2.new(1, -40, 0, 30)
subtitle.Text = "Using another copy extends the remaining time."
subtitle.TextColor3 = Color3.fromRGB(190, 190, 205)
subtitle.TextSize = 16
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = panel

local list = Instance.new("Frame")
list.BackgroundTransparency = 1
list.Position = UDim2.fromOffset(20, 105)
list.Size = UDim2.new(1, -40, 0, 230)
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local feedback = Instance.new("TextLabel")
feedback.AnchorPoint = Vector2.new(0.5, 1)
feedback.Position = UDim2.new(0.5, 0, 1, -18)
feedback.Size = UDim2.new(1, -40, 0, 38)
feedback.BackgroundTransparency = 1
feedback.Text = ""
feedback.TextColor3 = Color3.fromRGB(255, 220, 80)
feedback.TextSize = 17
feedback.Font = Enum.Font.GothamBold
feedback.Parent = panel

local rows = {}
local busy = false

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))

	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60

	return string.format("%02d:%02d", minutes, secs)
end

local function ensureRow(boost)
	local row = rows[boost.Id]

	if row then
		return row
	end

	local frame = Instance.new("Frame")
	frame.Name = boost.Id
	frame.Size = UDim2.new(1, 0, 0, 70)
	frame.BackgroundColor3 = Color3.fromRGB(47, 49, 62)
	frame.Parent = list

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(14, 7)
	name.Size = UDim2.new(1, -165, 0, 28)
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextSize = 19
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Font = Enum.Font.GothamBold
	name.Parent = frame

	local info = Instance.new("TextLabel")
	info.BackgroundTransparency = 1
	info.Position = UDim2.fromOffset(14, 36)
	info.Size = UDim2.new(1, -165, 0, 24)
	info.TextColor3 = Color3.fromRGB(205, 205, 218)
	info.TextSize = 15
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.Font = Enum.Font.Gotham
	info.Parent = frame

	local use = Instance.new("TextButton")
	use.AnchorPoint = Vector2.new(1, 0.5)
	use.Position = UDim2.new(1, -12, 0.5, 0)
	use.Size = UDim2.fromOffset(125, 42)
	use.BackgroundColor3 = Color3.fromRGB(255, 125, 40)
	use.TextColor3 = Color3.new(1, 1, 1)
	use.Text = "USE"
	use.TextSize = 17
	use.Font = Enum.Font.GothamBold
	use.Parent = frame

	local useCorner = Instance.new("UICorner")
	useCorner.CornerRadius = UDim.new(0, 10)
	useCorner.Parent = use

	use.Activated:Connect(function()
		if busy or not use.Active then
			return
		end

		busy = true
		use.Active = false
		use.Text = "..."

		local response = boostsRemote:InvokeServer("Activate", boost.Id)

		busy = false

		if response and response.Success then
			feedback.Text = "⚡ " .. boost.DisplayName .. " activated!"
		else
			feedback.Text = response and response.Message or "Could not activate boost."
		end

		if response and response.Boosts then
			for _, statusBoost in response.Boosts do
				local statusRow = ensureRow(statusBoost)
				statusRow.Data = statusBoost
			end
		end
	end)

	row = {
		Frame = frame,
		Name = name,
		Info = info,
		Use = use,
		Data = boost,
	}

	rows[boost.Id] = row
	return row
end

local function render(response)
	if not response or not response.Success then
		feedback.Text = response and response.Message or "Could not load boosts."
		return
	end

	local activeCount = 0

	for _, boost in response.Boosts or {} do
		local row = ensureRow(boost)
		row.Data = boost

		row.Name.Text = string.format(
			"%s  %s",
			boost.Icon or "⚡",
			boost.DisplayName
		)

		if boost.Active then
			activeCount += 1
			row.Info.Text = string.format(
				"Owned: %d   •   ACTIVE: %s",
				boost.Count,
				formatTime(boost.Remaining)
			)
			row.Frame.BackgroundColor3 = Color3.fromRGB(59, 79, 66)
		else
			row.Info.Text = string.format(
				"Owned: %d   •   Duration: %s",
				boost.Count,
				formatTime(boost.Duration)
			)
			row.Frame.BackgroundColor3 = Color3.fromRGB(47, 49, 62)
		end

		row.Use.Active = boost.Count > 0
		row.Use.AutoButtonColor = row.Use.Active

		if row.Use.Active then
			row.Use.Text = boost.Active and "EXTEND" or "USE"
			row.Use.BackgroundColor3 = Color3.fromRGB(255, 125, 40)
		else
			row.Use.Text = "NONE"
			row.Use.BackgroundColor3 = Color3.fromRGB(75, 75, 88)
		end
	end

	openButton.Text = activeCount > 0 and "⚡ ACTIVE" or "⚡ BOOSTS"
end

local function refresh()
	if busy then
		return
	end

	busy = true
	local response = boostsRemote:InvokeServer("Status")
	busy = false

	render(response)
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
	refresh()
end)

close.Activated:Connect(function()
	panel.Visible = false
end)

task.spawn(function()
	waitForData()
	refresh()

	while gui.Parent do
		task.wait(1)

		if panel.Visible then
			refresh()
		else
			local active = false

			for _, row in pairs(rows) do
				if row.Data and row.Data.Active and row.Data.ActiveUntil > os.time() then
					active = true
					break
				end
			end

			openButton.Text = active and "⚡ ACTIVE" or "⚡ BOOSTS"
		end
	end
end)
