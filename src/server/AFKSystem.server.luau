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

local function getCoinsPerHour(player)
	if GameConfig.AFK.RequireEquippedPet and not hasEquippedPet(player) then
		return 0
	end

	local multiplier = RewardService.GetPetMultiplier(player)

	return math.floor(
		GameConfig.AFK.BaseCoinsPerMinute
		* 60
		* GameConfig.AFK.Efficiency
		* multiplier
	)
end

local function setAFKState(player, isAFK)
	local wasAFK = player:GetAttribute("IsAFK") == true

	if wasAFK == isAFK then
		return
	end

	player:SetAttribute("IsAFK", isAFK)

	if isAFK then
		player:SetAttribute("AFKCoinsEarned", 0)
		print("💤 " .. player.Name .. " entrou na AFK Zone")
	else
		player:SetAttribute("AFKCoinsPerHour", 0)
		fractionalCoins[player] = nil
		print("👋 " .. player.Name .. " saiu da AFK Zone")
	end
end

local function payAFKCoins(player)
	if not player:GetAttribute("DataLoaded") then
		return
	end

	if player:GetAttribute("InRound") then
		player:SetAttribute("AFKCoinsPerHour", 0)
		return
	end

	if GameConfig.AFK.RequireEquippedPet and not hasEquippedPet(player) then
		player:SetAttribute("AFKCoinsPerHour", 0)
		return
	end

	local coins = getCoinsStat(player)
	if not coins then
		return
	end

	local multiplier = RewardService.GetPetMultiplier(player)

	local exactAmount =
		(GameConfig.AFK.BaseCoinsPerMinute / 60)
		* GameConfig.AFK.Efficiency
		* multiplier
		* GameConfig.AFK.TickInterval

	exactAmount += fractionalCoins[player] or 0

	local payout = math.floor(exactAmount)
	fractionalCoins[player] = exactAmount - payout

	player:SetAttribute("AFKCoinsPerHour", getCoinsPerHour(player))

	if payout <= 0 then
		return
	end

	coins.Value += payout
	player:SetAttribute(
		"AFKCoinsEarned",
		(player:GetAttribute("AFKCoinsEarned") or 0) + payout
	)
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("IsAFK", false)
	player:SetAttribute("AFKCoinsEarned", 0)
	player:SetAttribute("AFKCoinsPerHour", 0)
end)

Players.PlayerRemoving:Connect(function(player)
	fractionalCoins[player] = nil
end)

for _, player in Players:GetPlayers() do
	player:SetAttribute("IsAFK", false)
	player:SetAttribute("AFKCoinsEarned", 0)
	player:SetAttribute("AFKCoinsPerHour", 0)
end

while true do
	local inside = getPlayersInsideZone()

	for _, player in Players:GetPlayers() do
		local isInside = inside[player] == true
		setAFKState(player, isInside)

		if isInside then
			payAFKCoins(player)
		end
	end

	task.wait(GameConfig.AFK.TickInterval)
end
