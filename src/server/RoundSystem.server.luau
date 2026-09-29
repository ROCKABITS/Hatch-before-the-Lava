local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local LavaSystem = require(script.Parent:WaitForChild("LavaSystem"))
local RewardService = require(script.Parent:WaitForChild("RewardService"))
local ObbyGenerator = require(script.Parent:WaitForChild("ObbyGenerator"))

local gameState = ReplicatedStorage:FindFirstChild("GameState")

if not gameState then
	gameState = Instance.new("Folder")
	gameState.Name = "GameState"
	gameState.Parent = ReplicatedStorage
end

gameState:SetAttribute("State", "Waiting")
gameState:SetAttribute("TimeLeft", 0)
gameState:SetAttribute("PlayersRemaining", 0)
gameState:SetAttribute("RoundNumber", 0)

local currentRound = {}
local roundActive = false
local roundToken = 0
local roundNumber = 0
local roundStartPart = nil

local function setState(state, timeLeft)
	gameState:SetAttribute("State", state)
	gameState:SetAttribute("TimeLeft", timeLeft or 0)
end

local function getLeaderstat(player, name)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end

	return leaderstats:FindFirstChild(name)
end

local function addWins(player, amount)
	local wins = getLeaderstat(player, "Wins")
	if wins then
		wins.Value += amount
	end
end

local function updatePlayersRemaining()
	local remaining = 0

	for _, data in pairs(currentRound) do
		if not data.finished then
			remaining += 1
		end
	end

	gameState:SetAttribute("PlayersRemaining", remaining)
end

local function updateHeight(player, data)
	if data.finished then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local height = math.max(0, math.floor(root.Position.Y - data.startY))

	if height > data.maxHeight then
		data.maxHeight = height
		player:SetAttribute("RoundHeight", height)

		local bestHeight = getLeaderstat(player, "BestHeight")
		if bestHeight and height > bestHeight.Value then
			bestHeight.Value = height
		end
	end
end

local function awardHeightCoins(player, data)
	if data.heightRewarded then
		return 0
	end

	data.heightRewarded = true

	local baseCoins = math.floor(data.maxHeight * GameConfig.Rewards.CoinsPerMeter)
	local coinsEarned = 0

	if baseCoins > 0 then
		coinsEarned = RewardService.AddCoins(player, baseCoins)
	end

	data.heightCoinsEarned = coinsEarned
	player:SetAttribute("RoundCoins", (player:GetAttribute("RoundCoins") or 0) + coinsEarned)

	return coinsEarned
end

local function finalizePlayer(player, data, escaped)
	if data.finished then
		return
	end

	updateHeight(player, data)
	awardHeightCoins(player, data)

	data.finished = true
	data.escaped = escaped

	player:SetAttribute("InRound", false)
	player:SetAttribute("Escaped", escaped)
	player:SetAttribute("RoundFinalHeight", data.maxHeight)
	player:SetAttribute("RoundResult", escaped and "Escaped" or "Dead")
	player:SetAttribute("LastPlayedRound", roundNumber)

	if escaped then
		addWins(player, GameConfig.Rewards.WinsPerEscape)

		local winCoins = RewardService.AddCoins(player, GameConfig.Rewards.WinCoins)

		player:SetAttribute(
			"RoundCoins",
			(player:GetAttribute("RoundCoins") or 0) + winCoins
		)

		print(
			string.format(
				"🏆 %s ESCAPED! +%d Coins +%d Win(s) [x%.2f pets]",
				player.Name,
				winCoins,
				GameConfig.Rewards.WinsPerEscape,
				RewardService.GetPetMultiplier(player)
			)
		)
	else
		print(
			string.format(
				"💀 %s finished at %dm and earned %d height Coins [x%.2f pets]",
				player.Name,
				data.maxHeight,
				data.heightCoinsEarned or 0,
				RewardService.GetPetMultiplier(player)
			)
		)
	end

	updatePlayersRemaining()
end

local function setupParticipant(player)
	if not roundActive then
		return
	end

	if currentRound[player] then
		return
	end

	if not player:GetAttribute("DataLoaded") or player:GetAttribute("IsAFK") then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	player:SetAttribute("RoundHeight", 0)
	player:SetAttribute("RoundCoins", 0)
	player:SetAttribute("RoundFinalHeight", 0)
	player:SetAttribute("RoundResult", "")
	player:SetAttribute("LastPlayedRound", roundNumber)
	player:SetAttribute("Escaped", false)
	player:SetAttribute("InRound", true)

	local data = {
		startY = root.Position.Y,
		maxHeight = 0,
		finished = false,
		escaped = false,
		heightRewarded = false,
		deathConnection = nil,
	}

	currentRound[player] = data

	data.deathConnection = humanoid.Died:Connect(function()
		if roundActive and currentRound[player] == data then
			finalizePlayer(player, data, false)
		end
	end)

	updatePlayersRemaining()

	print("🎮 " .. player.Name .. " começou a jogar esta ronda")
end

local function getPlayerFromPart(part)
	local character = part and part:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function registerPlayersStandingOnStart()
	if not roundStartPart then
		return
	end

	local seen = {}

	for _, part in workspace:GetPartsInPart(roundStartPart) do
		local player = getPlayerFromPart(part)

		if player and not seen[player] then
			seen[player] = true
			setupParticipant(player)
		end
	end
end

local function cleanupRound()
	for player, data in pairs(currentRound) do
		if data.deathConnection then
			data.deathConnection:Disconnect()
			data.deathConnection = nil
		end

		if player.Parent == Players then
			player:SetAttribute("InRound", false)
		end
	end

	currentRound = {}
	gameState:SetAttribute("PlayersRemaining", 0)
end

local function monitorHeights(token)
	while roundActive and roundToken == token do
		for player, data in pairs(currentRound) do
			if player.Parent == Players and not data.finished then
				updateHeight(player, data)
			end
		end

		task.wait(GameConfig.HeightUpdateInterval)
	end
end

local function countdown(state, seconds)
	for timeLeft = seconds, 1, -1 do
		setState(state, timeLeft)
		task.wait(1)
	end

	setState(state, 0)
end

local function getReadyPlayerCount()
	local count = 0

	for _, player in Players:GetPlayers() do
		if player:GetAttribute("DataLoaded") then
			count += 1
		end
	end

	return count
end

local function waitForPlayers()
	while getReadyPlayerCount() < GameConfig.MinimumPlayers do
		setState("WaitingForPlayers", 0)
		task.wait(1)
	end
end

local function runRound()
	LavaSystem.Reset()
	cleanupRound()

	local nextRoundNumber = roundNumber + 1
	local obbyInfo = ObbyGenerator.Generate(nextRoundNumber)
	gameState:SetAttribute("ObbySeed", obbyInfo.Seed)
	gameState:SetAttribute("ObbyHeight", obbyInfo.Height)
	LavaSystem.SetTargetTopY(obbyInfo.FinishY)

	countdown("Intermission", GameConfig.IntermissionTime)

	if getReadyPlayerCount() < GameConfig.MinimumPlayers then
		return
	end

	countdown("Starting", GameConfig.StartCountdown)

	roundNumber += 1
	roundToken += 1
	gameState:SetAttribute("RoundNumber", roundNumber)

	roundActive = true
	registerPlayersStandingOnStart()
	updatePlayersRemaining()

	local thisRoundToken = roundToken
	task.spawn(monitorHeights, thisRoundToken)

	setState("LavaRising", 0)
	print("🔥 LAVA IS RISING!")

	LavaSystem.Start()

	roundActive = false

	for player, data in pairs(currentRound) do
		if not data.finished and player.Parent == Players then
			finalizePlayer(player, data, false)
		end
	end

	setState("RoundOver", GameConfig.PostRoundTime)
	print("🏁 ROUND OVER!")

	task.wait(GameConfig.PostRoundTime)
	cleanupRound()
end

task.spawn(function()
	roundStartPart = workspace:WaitForChild(GameConfig.RoundStartPart)

	if not roundStartPart:IsA("BasePart") then
		warn("Workspace." .. GameConfig.RoundStartPart .. " precisa de ser uma Part/BasePart.")
		return
	end

	roundStartPart.CanTouch = true
	roundStartPart.CanQuery = true

	roundStartPart.Touched:Connect(function(hit)
		if not roundActive then
			return
		end

		local player = getPlayerFromPart(hit)
		if player then
			setupParticipant(player)
		end
	end)
end)

task.spawn(function()
	local finish = workspace:WaitForChild("Finish")

	if not finish:IsA("BasePart") then
		warn("Workspace.Finish precisa de ser uma Part/BasePart.")
		return
	end

	finish.Touched:Connect(function(hit)
		if not roundActive then
			return
		end

		local player = getPlayerFromPart(hit)
		if not player then
			return
		end

		local data = currentRound[player]
		if not data or data.finished then
			return
		end

		finalizePlayer(player, data, true)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local data = currentRound[player]

	if data then
		if data.deathConnection then
			data.deathConnection:Disconnect()
		end

		currentRound[player] = nil
		updatePlayersRemaining()
	end
end)

while true do
	waitForPlayers()
	runRound()
end
