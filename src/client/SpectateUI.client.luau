local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gameState = ReplicatedStorage:WaitForChild("GameState")
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("SpectateUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SpectateUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local resultPanel = Instance.new("Frame")
resultPanel.AnchorPoint = Vector2.new(0.5, 0.5)
resultPanel.Position = UDim2.fromScale(0.5, 0.74)
resultPanel.Size = UDim2.fromOffset(390, 150)
resultPanel.BackgroundColor3 = Color3.fromRGB(28, 29, 38)
resultPanel.BackgroundTransparency = 0.08
resultPanel.Visible = false
resultPanel.Parent = gui

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 16)
resultCorner.Parent = resultPanel

local resultTitle = Instance.new("TextLabel")
resultTitle.BackgroundTransparency = 1
resultTitle.Position = UDim2.fromOffset(14, 10)
resultTitle.Size = UDim2.new(1, -28, 0, 38)
resultTitle.TextColor3 = Color3.new(1, 1, 1)
resultTitle.TextSize = 26
resultTitle.Font = Enum.Font.GothamBold
resultTitle.Parent = resultPanel

local resultInfo = Instance.new("TextLabel")
resultInfo.BackgroundTransparency = 1
resultInfo.Position = UDim2.fromOffset(14, 49)
resultInfo.Size = UDim2.new(1, -28, 0, 38)
resultInfo.TextColor3 = Color3.fromRGB(220, 220, 230)
resultInfo.TextSize = 18
resultInfo.Font = Enum.Font.Gotham
resultInfo.Parent = resultPanel

local spectateButton = Instance.new("TextButton")
spectateButton.AnchorPoint = Vector2.new(0.5, 0)
spectateButton.Position = UDim2.new(0.5, 0, 0, 98)
spectateButton.Size = UDim2.fromOffset(190, 40)
spectateButton.BackgroundColor3 = Color3.fromRGB(255, 125, 40)
spectateButton.TextColor3 = Color3.new(1, 1, 1)
spectateButton.Text = "👀 SPECTATE"
spectateButton.TextSize = 20
spectateButton.Font = Enum.Font.GothamBold
spectateButton.Parent = resultPanel

local spectateCorner = Instance.new("UICorner")
spectateCorner.CornerRadius = UDim.new(0, 12)
spectateCorner.Parent = spectateButton

local spectateBar = Instance.new("Frame")
spectateBar.AnchorPoint = Vector2.new(0.5, 0)
spectateBar.Position = UDim2.fromScale(0.5, 0.12)
spectateBar.Size = UDim2.fromOffset(470, 62)
spectateBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
spectateBar.BackgroundTransparency = 0.08
spectateBar.Visible = false
spectateBar.Parent = gui

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 14)
barCorner.Parent = spectateBar

local previous = Instance.new("TextButton")
previous.Position = UDim2.fromOffset(8, 8)
previous.Size = UDim2.fromOffset(52, 46)
previous.BackgroundColor3 = Color3.fromRGB(55, 57, 70)
previous.TextColor3 = Color3.new(1, 1, 1)
previous.Text = "◀"
previous.TextScaled = true
previous.Font = Enum.Font.GothamBold
previous.Parent = spectateBar

local nextButton = previous:Clone()
nextButton.Position = UDim2.new(1, -60, 0, 8)
nextButton.Text = "▶"
nextButton.Parent = spectateBar

local stopButton = Instance.new("TextButton")
stopButton.Position = UDim2.new(1, -118, 0, 8)
stopButton.Size = UDim2.fromOffset(50, 46)
stopButton.BackgroundColor3 = Color3.fromRGB(145, 55, 55)
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.Text = "✕"
stopButton.TextScaled = true
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = spectateBar

for _, button in {previous, nextButton, stopButton} do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
end

local targetLabel = Instance.new("TextLabel")
targetLabel.BackgroundTransparency = 1
targetLabel.Position = UDim2.fromOffset(70, 8)
targetLabel.Size = UDim2.new(1, -198, 0, 46)
targetLabel.TextColor3 = Color3.new(1, 1, 1)
targetLabel.TextSize = 20
targetLabel.Font = Enum.Font.GothamBold
targetLabel.Parent = spectateBar

local spectating = false
local targetIndex = 1
local resultDismissedRound = nil
local resultTimerRound = nil
local RESULT_VISIBLE_TIME = 5

local function getActivePlayers()
	local active = {}

	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player and otherPlayer:GetAttribute("InRound") then
			local character = otherPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health > 0 then
				table.insert(active, otherPlayer)
			end
		end
	end

	table.sort(active, function(a, b)
		return a.Name < b.Name
	end)

	return active
end

local function restoreCamera()
	local camera = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	camera.CameraType = Enum.CameraType.Custom

	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function stopSpectating()
	spectating = false
	spectateBar.Visible = false
	targetIndex = 1
	restoreCamera()
end

local function showTarget()
	if not spectating then
		return
	end

	local active = getActivePlayers()

	if #active == 0 then
		stopSpectating()
		return
	end

	if targetIndex > #active then
		targetIndex = 1
	elseif targetIndex < 1 then
		targetIndex = #active
	end

	local target = active[targetIndex]
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		stopSpectating()
		return
	end

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid

	targetLabel.Text = "👀 " .. target.DisplayName
	spectateBar.Visible = true
end

local function updateResultPanel()
	local state = gameState:GetAttribute("State")
	local currentRound = gameState:GetAttribute("RoundNumber") or 0
	local lastPlayedRound = player:GetAttribute("LastPlayedRound") or 0
	local inRound = player:GetAttribute("InRound") == true
	local result = player:GetAttribute("RoundResult") or ""

	local shouldShow =
		state == "LavaRising"
		and not inRound
		and lastPlayedRound == currentRound
		and result ~= ""
		and resultDismissedRound ~= currentRound

	resultPanel.Visible = shouldShow

	if not shouldShow then
		if spectating then
			stopSpectating()
		end
		return
	end

	local finalHeight = player:GetAttribute("RoundFinalHeight") or 0
	local roundCoins = player:GetAttribute("RoundCoins") or 0

	if result == "Escaped" then
		resultTitle.Text = "🏆 ESCAPED!"
		resultTitle.TextColor3 = Color3.fromRGB(255, 220, 80)
	else
		resultTitle.Text = "💀 RUN ENDED"
		resultTitle.TextColor3 = Color3.fromRGB(255, 110, 100)
	end

	resultInfo.Text = string.format("Height: %dm   •   Earned: %d Coins", finalHeight, roundCoins)

	local active = getActivePlayers()
	spectateButton.Visible = #active > 0

	if resultTimerRound ~= currentRound then
		resultTimerRound = currentRound

		task.delay(RESULT_VISIBLE_TIME, function()
			if (gameState:GetAttribute("RoundNumber") or 0) ~= currentRound then
				return
			end

			resultDismissedRound = currentRound
			resultPanel.Visible = false
		end)
	end
end

spectateButton.Activated:Connect(function()
	local active = getActivePlayers()
	if #active == 0 then
		return
	end

	spectating = true
	targetIndex = 1
	resultPanel.Visible = false
	showTarget()
end)

previous.Activated:Connect(function()
	if not spectating then
		return
	end

	targetIndex -= 1
	showTarget()
end)

nextButton.Activated:Connect(function()
	if not spectating then
		return
	end

	targetIndex += 1
	showTarget()
end)

stopButton.Activated:Connect(function()
	stopSpectating()
	updateResultPanel()
end)

for _, attribute in {"State", "RoundNumber"} do
	gameState:GetAttributeChangedSignal(attribute):Connect(updateResultPanel)
end

for _, attribute in {
	"InRound",
	"RoundResult",
	"RoundFinalHeight",
	"RoundCoins",
	"LastPlayedRound",
} do
	player:GetAttributeChangedSignal(attribute):Connect(updateResultPanel)
end

player.CharacterAdded:Connect(function()
	task.wait(0.2)

	if not spectating then
		restoreCamera()
	end
end)

task.spawn(function()
	while true do
		task.wait(0.5)

		if spectating then
			if gameState:GetAttribute("State") ~= "LavaRising" then
				stopSpectating()
			else
				showTarget()
			end
		end

		updateResultPanel()
	end
end)

updateResultPanel()
