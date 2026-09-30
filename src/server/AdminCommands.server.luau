local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local resetPlayerData = script.Parent:WaitForChild("ResetPlayerData")

local MAX_COINS_PER_COMMAND = 100000000
local MAX_BOOSTS_PER_COMMAND = 100

local BOOST_ATTRIBUTES = {
	coin = "CoinBoosts",
	coins = "CoinBoosts",
	luck = "LuckBoosts",
	petxp = "PetXPBoosts",
	xp = "PetXPBoosts",
}

-- Add extra Roblox UserIds here later if the game becomes group-owned.
local EXTRA_ADMIN_USER_IDS = {}

local function isAdmin(player)
	if RunService:IsStudio() then
		return true
	end

	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end

	for _, userId in EXTRA_ADMIN_USER_IDS do
		if player.UserId == userId then
			return true
		end
	end

	return false
end

local function getCoins(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Coins")
end

local function parseCoinsCommand(message)
	local amountText =
		message:match("^/coins%s+([%d,]+)$")
		or message:match("^!coins%s+([%d,]+)$")
		or message:match("^/money%s+([%d,]+)$")
		or message:match("^!money%s+([%d,]+)$")

	if not amountText then
		return nil
	end

	amountText = amountText:gsub(",", "")
	local amount = tonumber(amountText)

	if not amount then
		return nil
	end

	amount = math.floor(amount)

	if amount < 1 then
		return nil
	end

	return math.clamp(amount, 1, MAX_COINS_PER_COMMAND)
end

local function parseBoostCommand(message)
	local boostType, amountText =
		message:match("^/boost%s+(%w+)%s*(%d*)$")
		or message:match("^!boost%s+(%w+)%s*(%d*)$")

	if not boostType then
		return nil
	end

	boostType = string.lower(boostType)
	local attribute = BOOST_ATTRIBUTES[boostType]

	if not attribute then
		return nil
	end

	local amount = tonumber(amountText)
	if not amount then
		amount = 1
	end

	amount = math.clamp(math.floor(amount), 1, MAX_BOOSTS_PER_COMMAND)

	return attribute, amount, boostType
end

local function setupPlayer(player)
	player.Chatted:Connect(function(message)
		local isWipeCommand =
			message == "/wipedata confirm"
			or message == "!wipedata confirm"
			or message == "/resetdata confirm"
			or message == "!resetdata confirm"

		local amount = parseCoinsCommand(message)
		local boostAttribute, boostAmount, boostType = parseBoostCommand(message)

		if not amount and not isWipeCommand and not boostAttribute then
			return
		end

		if not isAdmin(player) then
			warn(string.format(
				"Admin command blocked for %s (%d)",
				player.Name,
				player.UserId
			))
			return
		end

		if player:GetAttribute("DataLoaded") ~= true then
			warn("Admin command ignored because data is still loading for " .. player.Name)
			return
		end

		if boostAttribute then
			local current = player:GetAttribute(boostAttribute) or 0
			player:SetAttribute(boostAttribute, current + boostAmount)

			print(string.format(
				"🛠️ ADMIN: %s added %d %s boost(s).",
				player.Name,
				boostAmount,
				boostType
			))

			return
		end

		if isWipeCommand then
			local success, errorMessage = resetPlayerData:Invoke(player)

			if not success then
				warn("Could not reset data for " .. player.Name .. ": " .. tostring(errorMessage))
				return
			end

			print("🧹 ADMIN: " .. player.Name .. " wiped their own saved data.")

			task.defer(function()
				if player.Parent == Players then
					player:Kick("Account data cleared. Rejoin to start fresh.")
				end
			end)

			return
		end

		local coins = getCoins(player)
		if not coins then
			warn("Could not find Coins for " .. player.Name)
			return
		end

		coins.Value += amount

		print(string.format(
			"🛠️ ADMIN: %s added %d Coins to themselves. New balance: %d",
			player.Name,
			amount,
			coins.Value
		))
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
