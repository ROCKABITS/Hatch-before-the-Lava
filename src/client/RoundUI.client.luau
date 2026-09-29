local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gameState = ReplicatedStorage:WaitForChild("GameState")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local lava = workspace:WaitForChild("Lava")

local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("RoundUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RoundUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.035)
status.Size = UDim2.fromOffset(420, 62)
status.BackgroundTransparency = 0.15
status.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
status.TextColor3 = Color3.new(1, 1, 1)
status.TextScaled = true
status.Font = Enum.Font.GothamBold
status.Parent = gui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 14)
statusCorner.Parent = status

local stats = Instance.new("TextLabel")
stats.Name = "Stats"
stats.AnchorPoint = Vector2.new(1, 0)
stats.Position = UDim2.new(1, -20, 0, 20)
stats.Size = UDim2.fromOffset(250, 142)
stats.BackgroundTransparency = 0.15
stats.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
stats.TextColor3 = Color3.new(1, 1, 1)
stats.TextSize = 21
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.TextYAlignment = Enum.TextYAlignment.Center
stats.Font = Enum.Font.GothamBold
stats.Parent = gui

local statsPadding = Instance.new("UIPadding")
statsPadding.PaddingLeft = UDim.new(0, 16)
statsPadding.Parent = stats

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 14)
statsCorner.Parent = stats

local height = Instance.new("TextLabel")
height.Name = "Height"
height.AnchorPoint = Vector2.new(0.5, 1)
height.Position = UDim2.new(0.5, 0, 1, -28)
height.Size = UDim2.fromOffset(410, 54)
height.BackgroundTransparency = 0.15
height.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
height.TextColor3 = Color3.new(1, 1, 1)
height.TextScaled = true
height.Font = Enum.Font.GothamBold
height.Parent = gui

local heightCorner = Instance.new("UICorner")
heightCorner.CornerRadius = UDim.new(0, 14)
heightCorner.Parent = height

local lavaPanel = Instance.new("Frame")
lavaPanel.Name = "LavaProgress"
lavaPanel.AnchorPoint = Vector2.new(0, 0.5)
lavaPanel.Position = UDim2.new(0, 20, 0.5, 0)
lavaPanel.Size = UDim2.fromOffset(92, 320)
lavaPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
lavaPanel.BackgroundTransparency = 0.15
lavaPanel.Visible = false
lavaPanel.Parent = gui

local lavaPanelCorner = Instance.new("UICorner")
lavaPanelCorner.CornerRadius = UDim.new(0, 14)
lavaPanelCorner.Parent = lavaPanel

local finishLabel = Instance.new("TextLabel")
finishLabel.BackgroundTransparency = 1
finishLabel.Position = UDim2.fromOffset(8, 8)
finishLabel.Size = UDim2.new(1, -16, 0, 30)
finishLabel.Text = "🏁 FINISH"
finishLabel.TextColor3 = Color3.new(1, 1, 1)
finishLabel.TextSize = 14
finishLabel.Font = Enum.Font.GothamBold
finishLabel.Parent = lavaPanel

local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.new(0.5, 0, 0, 43)
track.Size = UDim2.fromOffset(28, 220)
track.BackgroundColor3 = Color3.fromRGB(55, 57, 68)
track.Parent = lavaPanel

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = track

local lavaFill = Instance.new("Frame")
lavaFill.Name = "Lava"
lavaFill.AnchorPoint = Vector2.new(0, 1)
lavaFill.Position = UDim2.fromScale(0, 1)
lavaFill.Size = UDim2.fromScale(1, 0)
lavaFill.BackgroundColor3 = Color3.fromRGB(235, 85, 45)
lavaFill.BorderSizePixel = 0
lavaFill.Parent = track

local lavaFillCorner = Instance.new("UICorner")
lavaFillCorner.CornerRadius = UDim.new(1, 0)
lavaFillCorner.Parent = lavaFill

local playerMarker = Instance.new("TextLabel")
playerMarker.Name = "PlayerMarker"
playerMarker.AnchorPoint = Vector2.new(0.5, 0.5)
playerMarker.Position = UDim2.fromScale(0.5, 1)
playerMarker.Size = UDim2.fromOffset(54, 28)
playerMarker.BackgroundTransparency = 1
playerMarker.Text = "👤"
playerMarker.TextScaled = true
playerMarker.Parent = track

local lavaInfo = Instance.new("TextLabel")
lavaInfo.BackgroundTransparency = 1
lavaInfo.Position = UDim2.new(0, 5, 1, -52)
lavaInfo.Size = UDim2.new(1, -10, 0, 45)
lavaInfo.TextColor3 = Color3.new(1, 1, 1)
lavaInfo.TextSize = 13
lavaInfo.TextWrapped = true
lavaInfo.Font = Enum.Font.GothamBold
lavaInfo.Parent = lavaPanel

local startLavaSizeY = lava.Size.Y
local maxLavaHeight = math.max(GameConfig.Lava.MaxHeight, startLavaSizeY + 1)

local function getStat(name)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return 0
	end

	local value = leaderstats:FindFirstChild(name)
	return value and value.Value or 0
end

local function getLavaProgress()
	return math.clamp(
		(lava.Size.Y - startLavaSizeY) / (maxLavaHeight - startLavaSizeY),
		0,
		1
	)
end

local function getLavaSpeed(progress)
	if progress < GameConfig.Lava.SlowUntil then
		return "🟢 SLOW"
	elseif progress < GameConfig.Lava.NormalUntil then
		return "🟡 MEDIUM"
	else
		return "🔴 FAST"
	end
end

local function updateStatus()
	local state = gameState:GetAttribute("State") or "Waiting"
	local timeLeft = gameState:GetAttribute("TimeLeft") or 0
	local playersRemaining = gameState:GetAttribute("PlayersRemaining") or 0

	if state == "WaitingForPlayers" or state == "Waiting" then
		status.Text = "WAITING FOR PLAYERS"
	elseif state == "Intermission" then
		status.Text = string.format("NEXT ROUND: %d", timeLeft)
	elseif state == "Starting" then
		status.Text = tostring(timeLeft)
	elseif state == "LavaRising" then
		status.Text = string.format("🔥 LAVA IS RISING!  •  %d LEFT", playersRemaining)
	elseif state == "RoundOver" then
		status.Text = "🏁 ROUND OVER!"
	else
		status.Text = tostring(state)
	end

	lavaPanel.Visible =
		state == "LavaRising"
		and player:GetAttribute("InRound") == true
end

local function updateStats()
	stats.Text = string.format(
		"🪙 Coins: %d\n🏆 Wins: %d\n📈 Best: %dm\n🐾 Pets: x%.2f",
		getStat("Coins"),
		getStat("Wins"),
		getStat("BestHeight"),
		player:GetAttribute("PetMultiplier") or 1
	)

	height.Text = string.format(
		"Height: %dm   •   Round: +%d 🪙",
		player:GetAttribute("RoundHeight") or 0,
		player:GetAttribute("RoundCoins") or 0
	)
end

local function updateLavaUI()
	if not lavaPanel.Visible then
		return
	end

	local lavaProgress = getLavaProgress()
	local playerHeight = player:GetAttribute("RoundHeight") or 0
	local playerProgress = math.clamp(playerHeight / maxLavaHeight, 0, 1)
	local lavaRise = math.max(0, math.floor(lava.Size.Y - startLavaSizeY))

	lavaFill.Size = UDim2.fromScale(1, lavaProgress)
	playerMarker.Position = UDim2.fromScale(0.5, 1 - playerProgress)

	lavaInfo.Text = string.format(
		"🌋 %dm\n%s",
		lavaRise,
		getLavaSpeed(lavaProgress)
	)
end

for _, attribute in {"State", "TimeLeft", "PlayersRemaining"} do
	gameState:GetAttributeChangedSignal(attribute):Connect(updateStatus)
end

for _, attribute in {"RoundHeight", "RoundCoins", "InRound", "PetMultiplier"} do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		updateStatus()
		updateStats()
	end)
end

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")

	for _, statName in {"Coins", "Wins", "BestHeight"} do
		leaderstats:WaitForChild(statName).Changed:Connect(updateStats)
	end

	updateStats()
end)

local accumulator = 0
RunService.RenderStepped:Connect(function(deltaTime)
	accumulator += deltaTime

	if accumulator >= 0.10 then
		accumulator = 0
		updateLavaUI()
	end
end)

updateStatus()
updateStats()
updateLavaUI()
