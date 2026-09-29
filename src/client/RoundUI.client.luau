local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gameState = ReplicatedStorage:WaitForChild("GameState")

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
stats.Size = UDim2.fromOffset(250, 115)
stats.BackgroundTransparency = 0.15
stats.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
stats.TextColor3 = Color3.new(1, 1, 1)
stats.TextSize = 22
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
height.Size = UDim2.fromOffset(300, 50)
height.BackgroundTransparency = 0.15
height.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
height.TextColor3 = Color3.new(1, 1, 1)
height.TextScaled = true
height.Font = Enum.Font.GothamBold
height.Parent = gui

local heightCorner = Instance.new("UICorner")
heightCorner.CornerRadius = UDim.new(0, 14)
heightCorner.Parent = height

local function getStat(name)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return 0
	end

	local value = leaderstats:FindFirstChild(name)
	return value and value.Value or 0
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
end

local function updateStats()
	stats.Text = string.format(
		"🪙 Coins: %d\n🏆 Wins: %d\n📈 Best: %dm",
		getStat("Coins"),
		getStat("Wins"),
		getStat("BestHeight")
	)

	height.Text = string.format(
		"Height: %dm   •   Round: +%d 🪙",
		player:GetAttribute("RoundHeight") or 0,
		player:GetAttribute("RoundCoins") or 0
	)
end

for _, attribute in {"State", "TimeLeft", "PlayersRemaining"} do
	gameState:GetAttributeChangedSignal(attribute):Connect(updateStatus)
end

for _, attribute in {"RoundHeight", "RoundCoins"} do
	player:GetAttributeChangedSignal(attribute):Connect(updateStats)
end

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")

	for _, statName in {"Coins", "Wins", "BestHeight"} do
		leaderstats:WaitForChild(statName).Changed:Connect(updateStats)
	end

	updateStats()
end)

updateStatus()
updateStats()
