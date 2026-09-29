local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local PlayerStore = DataStoreService:GetDataStore(GameConfig.Data.StoreName)

local DEFAULT_DATA = {
	Coins = 0,
	Wins = 0,
	BestHeight = 0,
}

local saving = {}

local function ensureIntValue(parent, name, defaultValue)
	local value = parent:FindFirstChild(name)

	if value and value:IsA("IntValue") then
		return value
	end

	value = Instance.new("IntValue")
	value.Name = name
	value.Value = defaultValue
	value.Parent = parent

	return value
end

local function createPlayerValues(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	ensureIntValue(leaderstats, "Coins", DEFAULT_DATA.Coins)
	ensureIntValue(leaderstats, "Wins", DEFAULT_DATA.Wins)
	ensureIntValue(leaderstats, "BestHeight", DEFAULT_DATA.BestHeight)

	player:SetAttribute("RoundHeight", 0)
	player:SetAttribute("RoundCoins", 0)
	player:SetAttribute("Escaped", false)
	player:SetAttribute("InRound", false)
	player:SetAttribute("DataLoaded", false)
end

local function applyData(player, data)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	leaderstats.Coins.Value = tonumber(data.Coins) or DEFAULT_DATA.Coins
	leaderstats.Wins.Value = tonumber(data.Wins) or DEFAULT_DATA.Wins
	leaderstats.BestHeight.Value = tonumber(data.BestHeight) or DEFAULT_DATA.BestHeight
end

local function loadData(player)
	local key = "Player_" .. player.UserId

	local success, result = pcall(function()
		return PlayerStore:GetAsync(key)
	end)

	if not player.Parent then
		return
	end

	if success then
		if type(result) == "table" then
			applyData(player, result)
		end

		player:SetAttribute("DataLoaded", true)
		print("💾 Data loaded for " .. player.Name)
	else
		warn("Failed to load data for " .. player.Name .. ": " .. tostring(result))
		warn("Using temporary default data for this session.")
		player:SetAttribute("DataLoaded", true)
	end
end

local function getCurrentData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end

	local coins = leaderstats:FindFirstChild("Coins")
	local wins = leaderstats:FindFirstChild("Wins")
	local bestHeight = leaderstats:FindFirstChild("BestHeight")

	if not coins or not wins or not bestHeight then
		return nil
	end

	return {
		Coins = coins.Value,
		Wins = wins.Value,
		BestHeight = bestHeight.Value,
	}
end

local function saveData(player)
	if not player:GetAttribute("DataLoaded") then
		return false
	end

	if saving[player] then
		return false
	end

	local data = getCurrentData(player)
	if not data then
		return false
	end

	saving[player] = true

	local key = "Player_" .. player.UserId

	local success, result = pcall(function()
		return PlayerStore:UpdateAsync(key, function()
			return data
		end)
	end)

	saving[player] = nil

	if success then
		print("💾 Data saved for " .. player.Name)
		return true
	else
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(result))
		return false
	end
end

local function setupPlayer(player)
	createPlayerValues(player)
	task.spawn(loadData, player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	saving[player] = nil
end)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

task.spawn(function()
	while true do
		task.wait(GameConfig.Data.AutosaveInterval)

		for _, player in Players:GetPlayers() do
			task.spawn(saveData, player)
		end
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		saveData(player)
	end
end)
