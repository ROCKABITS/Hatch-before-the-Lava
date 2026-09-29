local Players = game:GetService("Players")

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

local function setupPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	ensureIntValue(leaderstats, "Coins", 0)
	ensureIntValue(leaderstats, "Wins", 0)
	ensureIntValue(leaderstats, "BestHeight", 0)

	if player:GetAttribute("RoundHeight") == nil then
		player:SetAttribute("RoundHeight", 0)
	end

	if player:GetAttribute("RoundCoins") == nil then
		player:SetAttribute("RoundCoins", 0)
	end

	if player:GetAttribute("Escaped") == nil then
		player:SetAttribute("Escaped", false)
	end

	if player:GetAttribute("InRound") == nil then
		player:SetAttribute("InRound", false)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
