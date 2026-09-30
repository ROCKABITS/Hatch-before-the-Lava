local RewardService = {}

local function reportQuestCoins(player, amount)
	local event = script.Parent:FindFirstChild("QuestProgress")

	if event and event:IsA("BindableEvent") and amount > 0 then
		event:Fire(player, "Coins", amount)
	end
end

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

function RewardService.GetCoinBoostMultiplier(player)
	local activeUntil = player:GetAttribute("ActiveCoinBoostUntil") or 0

	if activeUntil > os.time() then
		return 2
	end

	return 1
end

function RewardService.CalculateCoins(player, baseAmount)
	local petMultiplier = RewardService.GetPetMultiplier(player)
	local boostMultiplier = RewardService.GetCoinBoostMultiplier(player)

	return math.max(
		0,
		math.floor(baseAmount * petMultiplier * boostMultiplier)
	)
end

function RewardService.AddCoins(player, baseAmount)
	local coins = getCoinsStat(player)
	if not coins then
		return 0
	end

	local finalAmount = RewardService.CalculateCoins(player, baseAmount)
	coins.Value += finalAmount
	reportQuestCoins(player, finalAmount)

	return finalAmount
end

return RewardService
