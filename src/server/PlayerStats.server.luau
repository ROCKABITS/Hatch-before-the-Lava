local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetConfig"))

local PlayerStore = DataStoreService:GetDataStore(GameConfig.Data.StoreName)

local DEFAULT_DATA = {
	Coins = 0,
	Wins = 0,
	BestHeight = 0,
	PetInventory = {},
	EquippedPets = {},
	TutorialSeen = false,
	DailyRewardDay = 0,
	LastDailyClaimDay = -1,
	LuckBoosts = 0,
	PetXPPotions = 0,
}

local saving = {}

local resetPlayerData = script.Parent:FindFirstChild("ResetPlayerData")

if not resetPlayerData then
	resetPlayerData = Instance.new("BindableFunction")
	resetPlayerData.Name = "ResetPlayerData"
	resetPlayerData.Parent = script.Parent
end

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

local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)

	if folder and folder:IsA("Folder") then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent

	return folder
end

local function clearChildren(parent)
	for _, child in parent:GetChildren() do
		child:Destroy()
	end
end

local function createPlayerValues(player)
	local leaderstats = ensureFolder(player, "leaderstats")
	ensureIntValue(leaderstats, "Coins", DEFAULT_DATA.Coins)
	ensureIntValue(leaderstats, "Wins", DEFAULT_DATA.Wins)
	ensureIntValue(leaderstats, "BestHeight", DEFAULT_DATA.BestHeight)

	ensureFolder(player, "PetInventory")
	ensureFolder(player, "EquippedPets")

	player:SetAttribute("RoundHeight", 0)
	player:SetAttribute("RoundCoins", 0)
	player:SetAttribute("RoundFinalHeight", 0)
	player:SetAttribute("RoundResult", "")
	player:SetAttribute("LastPlayedRound", 0)
	player:SetAttribute("Escaped", false)
	player:SetAttribute("InRound", false)
	player:SetAttribute("PetMultiplier", 1)
	player:SetAttribute("IsAFK", false)
	player:SetAttribute("AFKCoinsEarned", 0)
	player:SetAttribute("AFKCoinsPerMinute", 0)
	player:SetAttribute("AFKCoinsPerHour", 0)
	player:SetAttribute("TutorialSeen", DEFAULT_DATA.TutorialSeen)
	player:SetAttribute("DailyRewardDay", DEFAULT_DATA.DailyRewardDay)
	player:SetAttribute("LastDailyClaimDay", DEFAULT_DATA.LastDailyClaimDay)
	player:SetAttribute("LuckBoosts", DEFAULT_DATA.LuckBoosts)
	player:SetAttribute("PetXPPotions", DEFAULT_DATA.PetXPPotions)
	player:SetAttribute("DataLoaded", false)
end

local function applyPetData(player, data)
	local inventoryFolder = ensureFolder(player, "PetInventory")
	local equippedFolder = ensureFolder(player, "EquippedPets")

	clearChildren(inventoryFolder)
	clearChildren(equippedFolder)

	if type(data.PetInventory) == "table" then
		for petId, amount in pairs(data.PetInventory) do
			if PetConfig.Pets[petId] and type(amount) == "number" and amount > 0 then
				local value = Instance.new("IntValue")
				value.Name = petId
				value.Value = math.floor(amount)
				value.Parent = inventoryFolder
			end
		end
	end

	if type(data.EquippedPets) == "table" then
		for index, petId in ipairs(data.EquippedPets) do
			if index > PetConfig.MaxEquipped then
				break
			end

			if PetConfig.Pets[petId] then
				local slot = Instance.new("StringValue")
				slot.Name = tostring(index)
				slot.Value = petId
				slot.Parent = equippedFolder
			end
		end
	end
end

local function applyData(player, data)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	leaderstats.Coins.Value = tonumber(data.Coins) or DEFAULT_DATA.Coins
	leaderstats.Wins.Value = tonumber(data.Wins) or DEFAULT_DATA.Wins
	leaderstats.BestHeight.Value = tonumber(data.BestHeight) or DEFAULT_DATA.BestHeight
	player:SetAttribute("TutorialSeen", data.TutorialSeen == true)
	player:SetAttribute("DailyRewardDay", tonumber(data.DailyRewardDay) or DEFAULT_DATA.DailyRewardDay)
	player:SetAttribute("LastDailyClaimDay", tonumber(data.LastDailyClaimDay) or DEFAULT_DATA.LastDailyClaimDay)
	player:SetAttribute("LuckBoosts", tonumber(data.LuckBoosts) or DEFAULT_DATA.LuckBoosts)
	player:SetAttribute("PetXPPotions", tonumber(data.PetXPPotions) or DEFAULT_DATA.PetXPPotions)

	applyPetData(player, data)
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
		else
			applyPetData(player, DEFAULT_DATA)
		end

		player:SetAttribute("DataLoaded", true)
		print("💾 Data loaded for " .. player.Name)
	else
		warn("Failed to load data for " .. player.Name .. ": " .. tostring(result))
		warn("Using temporary default data for this session.")
		applyPetData(player, DEFAULT_DATA)
		player:SetAttribute("DataLoaded", true)
	end
end

local function getPetData(player)
	local inventory = {}
	local equipped = {}

	local inventoryFolder = player:FindFirstChild("PetInventory")
	if inventoryFolder then
		for _, value in inventoryFolder:GetChildren() do
			if value:IsA("IntValue") and value.Value > 0 then
				inventory[value.Name] = value.Value
			end
		end
	end

	local equippedFolder = player:FindFirstChild("EquippedPets")
	if equippedFolder then
		local slots = equippedFolder:GetChildren()

		table.sort(slots, function(a, b)
			return tonumber(a.Name) < tonumber(b.Name)
		end)

		for _, slot in slots do
			if slot:IsA("StringValue") and PetConfig.Pets[slot.Value] then
				table.insert(equipped, slot.Value)
			end
		end
	end

	return inventory, equipped
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

	local inventory, equipped = getPetData(player)

	return {
		Coins = coins.Value,
		Wins = wins.Value,
		BestHeight = bestHeight.Value,
		PetInventory = inventory,
		EquippedPets = equipped,
		TutorialSeen = player:GetAttribute("TutorialSeen") == true,
		DailyRewardDay = player:GetAttribute("DailyRewardDay") or DEFAULT_DATA.DailyRewardDay,
		LastDailyClaimDay = player:GetAttribute("LastDailyClaimDay") or DEFAULT_DATA.LastDailyClaimDay,
		LuckBoosts = player:GetAttribute("LuckBoosts") or DEFAULT_DATA.LuckBoosts,
		PetXPPotions = player:GetAttribute("PetXPPotions") or DEFAULT_DATA.PetXPPotions,
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

local function resetSessionValues(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		local wins = leaderstats:FindFirstChild("Wins")
		local bestHeight = leaderstats:FindFirstChild("BestHeight")

		if coins then
			coins.Value = DEFAULT_DATA.Coins
		end

		if wins then
			wins.Value = DEFAULT_DATA.Wins
		end

		if bestHeight then
			bestHeight.Value = DEFAULT_DATA.BestHeight
		end
	end

	applyPetData(player, DEFAULT_DATA)

	player:SetAttribute("RoundHeight", 0)
	player:SetAttribute("RoundCoins", 0)
	player:SetAttribute("RoundFinalHeight", 0)
	player:SetAttribute("RoundResult", "")
	player:SetAttribute("LastPlayedRound", 0)
	player:SetAttribute("Escaped", false)
	player:SetAttribute("InRound", false)
	player:SetAttribute("PetMultiplier", 1)
	player:SetAttribute("IsAFK", false)
	player:SetAttribute("AFKCoinsEarned", 0)
	player:SetAttribute("AFKCoinsPerMinute", 0)
	player:SetAttribute("AFKCoinsPerHour", 0)
	player:SetAttribute("TutorialSeen", false)
	player:SetAttribute("DailyRewardDay", DEFAULT_DATA.DailyRewardDay)
	player:SetAttribute("LastDailyClaimDay", DEFAULT_DATA.LastDailyClaimDay)
	player:SetAttribute("LuckBoosts", DEFAULT_DATA.LuckBoosts)
	player:SetAttribute("PetXPPotions", DEFAULT_DATA.PetXPPotions)
end

resetPlayerData.OnInvoke = function(player)
	if not player or player.Parent ~= Players then
		return false, "Invalid player"
	end

	if player:GetAttribute("DataLoaded") ~= true then
		return false, "Data is not loaded"
	end

	-- Stop new autosaves while any current save finishes.
	player:SetAttribute("DataLoaded", false)

	while saving[player] do
		task.wait()
	end

	local key = "Player_" .. player.UserId

	local success, result = pcall(function()
		PlayerStore:RemoveAsync(key)
	end)

	if not success then
		player:SetAttribute("DataLoaded", true)
		return false, tostring(result)
	end

	resetSessionValues(player)

	-- Re-enable normal saving. The next save will contain only clean/default data.
	player:SetAttribute("DataLoaded", true)

	print("🧹 Data reset for " .. player.Name)
	return true
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
