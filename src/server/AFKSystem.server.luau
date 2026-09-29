local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local RewardService = require(script.Parent:WaitForChild("RewardService"))

if not GameConfig.AFK.Enabled then
	return
end

local zone = workspace:WaitForChild("AFKZone")

if not zone:IsA("BasePart") then
	error("Workspace.AFKZone precisa de ser uma Part/BasePart.")
end

zone.CanQuery = true

local fractionalCoins = {}

local function hasEquippedPet(player)
	local equipped = player:FindFirstChild("EquippedPets")
	return equipped ~= nil and #equipped:GetChildren() > 0
end

local function getCoinsStat(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Coins")
end

local function getPlayersInsideZone()
	local inside = {}

	for _, part in workspace:GetPartsInPart(zone) do
		local character = part:FindFirstAncestorOfClass("Model")
		if character then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				inside[player] = true
			end
		end
	end

	return inside
end

local function getCoinsPerMinute(player)
	if GameConfig.AFK.RequireEquippedPet and not hasEquippedPet(player) then
		return 0
	end

	local multiplier = RewardService.GetPetMultiplier(player)

	return
		GameConfig.AFK.BaseCoinsPerMinute
		* GameConfig.AFK.Efficiency
		* multiplier
end

local function updateRate(player)
	local perMinute = getCoinsPerMinute(player)
	player:SetAttribute("AFKCoinsPerMinute", perMinute)
	player:SetAttribute("AFKCoinsPerHour", math.floor(perMinute * 60))
end

local function collectStoredCoins(player)
	local stored = math.max(0, math.floor(player:GetAttribute("AFKCoinsStored") or 0))

	if stored <= 0 then
		player:SetAttribute("AFKCoinsStored", 0)
		return 0
	end

	local coins = getCoinsStat(player)
	if not coins then
		return 0
	end

	coins.Value += stored
	player:SetAttribute("AFKCoinsStored", 0)

	print(string.format("💰 %s recolheu %d Coins da AFK Zone", player.Name, stored))

	return stored
end

local function setAFKState(player, isAFK)
	local wasAFK = player:GetAttribute("IsAFK") == true

	if wasAFK == isAFK then
		return
	end

	if isAFK then
		player:SetAttribute("AFKCoinsStored", 0)
		fractionalCoins[player] = 0
		player:SetAttribute("IsAFK", true)
		updateRate(player)
		print("💤 " .. player.Name .. " entrou na AFK Zone")
	else
		collectStoredCoins(player)
		player:SetAttribute("IsAFK", false)
		player:SetAttribute("AFKCoinsPerMinute", 0)
		player:SetAttribute("AFKCoinsPerHour", 0)
		fractionalCoins[player] = nil
		print("👋 " .. player.Name .. " saiu da AFK Zone")
	end
end

local function accumulateAFKCoins(player)
	if not player:GetAttribute("DataLoaded") then
		return
	end

	if player:GetAttribute("InRound") then
		player:SetAttribute("AFKCoinsPerMinute", 0)
		player:SetAttribute("AFKCoinsPerHour", 0)
		return
	end

	if GameConfig.AFK.RequireEquippedPet and not hasEquippedPet(player) then
		player:SetAttribute("AFKCoinsPerMinute", 0)
		player:SetAttribute("AFKCoinsPerHour", 0)
		return
	end

	updateRate(player)

	local perMinute = getCoinsPerMinute(player)
	local exactAmount =
		(perMinute / 60)
		* GameConfig.AFK.TickInterval
		+ (fractionalCoins[player] or 0)

	local wholeCoins = math.floor(exactAmount)
	fractionalCoins[player] = exactAmount - wholeCoins

	if wholeCoins <= 0 then
		return
	end

	player:SetAttribute(
		"AFKCoinsStored",
		(player:GetAttribute("AFKCoinsStored") or 0) + wholeCoins
	)
end

local function setupPlayer(player)
	player:SetAttribute("IsAFK", false)
	player:SetAttribute("AFKCoinsStored", 0)
	player:SetAttribute("AFKCoinsPerMinute", 0)
	player:SetAttribute("AFKCoinsPerHour", 0)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	-- PlayerStats includes AFKCoinsStored in its save total, so pending
	-- AFK rewards are not lost even if the player closes the game in the zone.
	fractionalCoins[player] = nil
end)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

while true do
	local inside = getPlayersInsideZone()

	for _, player in Players:GetPlayers() do
		local isInside = inside[player] == true
		setAFKState(player, isInside)

		if isInside then
			accumulateAFKCoins(player)
		end
	end

	task.wait(GameConfig.AFK.TickInterval)
end
