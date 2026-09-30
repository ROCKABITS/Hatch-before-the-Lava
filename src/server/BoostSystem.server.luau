local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoostsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BoostsConfig")
)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local boostsRemote = remotes:FindFirstChild("Boosts")

if not boostsRemote then
	boostsRemote = Instance.new("RemoteFunction")
	boostsRemote.Name = "Boosts"
	boostsRemote.Parent = remotes
end

local function getBoostStatus(player, boostId)
	local config = BoostsConfig[boostId]

	if not config then
		return nil
	end

	local count = player:GetAttribute(config.InventoryAttribute) or 0
	local activeUntil = player:GetAttribute(config.ActiveUntilAttribute) or 0
	local remaining = math.max(0, activeUntil - os.time())

	return {
		Id = boostId,
		DisplayName = config.DisplayName,
		Icon = config.Icon,
		Count = count,
		ActiveUntil = activeUntil,
		Remaining = remaining,
		Duration = config.Duration,
		Multiplier = config.Multiplier,
		Active = remaining > 0,
	}
end

local function makeStatus(player)
	local boosts = {}

	for boostId in pairs(BoostsConfig) do
		table.insert(boosts, getBoostStatus(player, boostId))
	end

	table.sort(boosts, function(a, b)
		return a.Id < b.Id
	end)

	return {
		Success = true,
		Boosts = boosts,
	}
end

local function activateBoost(player, boostId)
	local config = BoostsConfig[boostId]

	if not config then
		return {
			Success = false,
			Message = "Unknown boost",
		}
	end

	local count = player:GetAttribute(config.InventoryAttribute) or 0

	if count <= 0 then
		return {
			Success = false,
			Message = "You do not own this boost",
		}
	end

	local now = os.time()
	local currentUntil = player:GetAttribute(config.ActiveUntilAttribute) or 0
	local baseTime = math.max(now, currentUntil)
	local newUntil = baseTime + config.Duration

	player:SetAttribute(config.InventoryAttribute, count - 1)
	player:SetAttribute(config.ActiveUntilAttribute, newUntil)

	local response = makeStatus(player)
	response.Activated = boostId

	return response
end

boostsRemote.OnServerInvoke = function(player, action, boostId)
	if player:GetAttribute("DataLoaded") ~= true then
		return {
			Success = false,
			Message = "Data is still loading",
		}
	end

	if action == "Status" then
		return makeStatus(player)
	elseif action == "Activate" then
		return activateBoost(player, boostId)
	end

	return {
		Success = false,
		Message = "Unknown action",
	}
end
