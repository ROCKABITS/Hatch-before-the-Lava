local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DailyRewardsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DailyRewardsConfig")
)
local PetConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetConfig")
)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local dailyRewards = remotes:FindFirstChild("DailyRewards")

if not dailyRewards then
	dailyRewards = Instance.new("RemoteFunction")
	dailyRewards.Name = "DailyRewards"
	dailyRewards.Parent = remotes
end

local random = Random.new()

local function getUtcDay()
	return math.floor(os.time() / 86400)
end

local function getStatus(player)
	local today = getUtcDay()
	local lastClaimDay = player:GetAttribute("LastDailyClaimDay") or -1
	local previousRewardDay = player:GetAttribute("DailyRewardDay") or 0

	if lastClaimDay == today then
		return {
			CanClaim = false,
			Day = math.clamp(previousRewardDay, 1, 7),
			NextClaimUnix = (today + 1) * 86400,
		}
	end

	local nextRewardDay = 1

	if lastClaimDay == today - 1 and previousRewardDay >= 1 then
		nextRewardDay = (previousRewardDay % 7) + 1
	end

	return {
		CanClaim = true,
		Day = nextRewardDay,
		NextClaimUnix = 0,
	}
end

local function addCoins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")

	if not coins then
		return false, "Coins are not ready"
	end

	coins.Value += amount
	return true
end

local function addPet(player, petId)
	if not PetConfig.Pets[petId] then
		return false, "Unknown pet"
	end

	local inventory = player:FindFirstChild("PetInventory")

	if not inventory then
		return false, "Pet inventory is not ready"
	end

	local value = inventory:FindFirstChild(petId)

	if not value then
		value = Instance.new("IntValue")
		value.Name = petId
		value.Value = 0
		value.Parent = inventory
	end

	value.Value += 1
	return true
end

local function rollEggPet(eggId)
	local egg = PetConfig.Eggs[eggId]

	if not egg or not egg.Drops or #egg.Drops == 0 then
		return nil
	end

	local roll = random:NextNumber(0, 100)
	local cumulative = 0

	for _, drop in ipairs(egg.Drops) do
		cumulative += drop.Chance

		if roll <= cumulative then
			return drop.PetId
		end
	end

	return egg.Drops[#egg.Drops].PetId
end

local function grantReward(player, day)
	local reward = DailyRewardsConfig.Rewards[day]

	if not reward then
		return false, "Unknown daily reward"
	end

	if reward.Type == "Coins" then
		local success, message = addCoins(player, reward.Amount)
		return success, message, reward.Display
	elseif reward.Type == "LuckBoost" then
		player:SetAttribute(
			"LuckBoosts",
			(player:GetAttribute("LuckBoosts") or 0) + reward.Amount
		)

		return true, nil, reward.Display
	elseif reward.Type == "PetXPPotion" then
		player:SetAttribute(
			"PetXPPotions",
			(player:GetAttribute("PetXPPotions") or 0) + reward.Amount
		)

		return true, nil, reward.Display
	elseif reward.Type == "Egg" then
		local petId = rollEggPet(reward.EggId)

		if not petId then
			return false, "Could not open reward egg"
		end

		local success, message = addPet(player, petId)

		if not success then
			return false, message
		end

		local pet = PetConfig.Pets[petId]
		return true, nil, string.format("%s → %s", reward.Display, pet.DisplayName)
	elseif reward.Type == "Pet" then
		local success, message = addPet(player, reward.PetId)

		if not success then
			return false, message
		end

		local pet = PetConfig.Pets[reward.PetId]
		return true, nil, pet and pet.DisplayName or reward.Display
	end

	return false, "Unsupported reward type"
end

dailyRewards.OnServerInvoke = function(player, action)
	if player:GetAttribute("DataLoaded") ~= true then
		return {
			Success = false,
			Message = "Data is still loading",
		}
	end

	local status = getStatus(player)

	if action == "Status" then
		return {
			Success = true,
			CanClaim = status.CanClaim,
			Day = status.Day,
			NextClaimUnix = status.NextClaimUnix,
			LuckBoosts = player:GetAttribute("LuckBoosts") or 0,
			PetXPPotions = player:GetAttribute("PetXPPotions") or 0,
		}
	end

	if action ~= "Claim" then
		return {
			Success = false,
			Message = "Unknown action",
		}
	end

	if not status.CanClaim then
		return {
			Success = false,
			Message = "Today's reward has already been claimed",
			CanClaim = false,
			Day = status.Day,
			NextClaimUnix = status.NextClaimUnix,
		}
	end

	local success, message, rewardText = grantReward(player, status.Day)

	if not success then
		return {
			Success = false,
			Message = message or "Could not grant reward",
		}
	end

	local today = getUtcDay()
	player:SetAttribute("DailyRewardDay", status.Day)
	player:SetAttribute("LastDailyClaimDay", today)

	return {
		Success = true,
		Claimed = true,
		Reward = rewardText,
		Day = status.Day,
		CanClaim = false,
		NextClaimUnix = (today + 1) * 86400,
		LuckBoosts = player:GetAttribute("LuckBoosts") or 0,
		PetXPPotions = player:GetAttribute("PetXPPotions") or 0,
	}
end
