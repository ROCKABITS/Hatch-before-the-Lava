local RewardService = {}

local function getCoinsStat(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end

	return leaderstats:FindFirstChild("Coins")
end

function RewardService.GetPetMultiplier(player)
	local multiplier = player:GetAttribute("PetMultiplier")

	if type(multiplier) ~= "number" or multiplier < 1 then
		return 1
	end

	return multiplier
end

function RewardService.CalculateCoins(player, baseAmount)
	local multiplier = RewardService.GetPetMultiplier(player)
	return math.max(0, math.floor(baseAmount * multiplier))
end

function RewardService.AddCoins(player, baseAmount)
	local coins = getCoinsStat(player)
	if not coins then
		return 0
	end

	local finalAmount = RewardService.CalculateCoins(player, baseAmount)
	coins.Value += finalAmount

	return finalAmount
end

return RewardService
