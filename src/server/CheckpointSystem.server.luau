local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local checkpointsFolder = workspace:FindFirstChild("Checkpoints")

if not checkpointsFolder then
	checkpointsFolder = Instance.new("Folder")
	checkpointsFolder.Name = "Checkpoints"
	checkpointsFolder.Parent = workspace
	warn("Workspace.Checkpoints foi criado. Adiciona Parts chamadas 1, 2, 3, ...")
end

local connected = {}

local function getCoinsStat(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end

	return leaderstats:FindFirstChild("Coins")
end

local function getCheckpointNumber(part)
	return tonumber(part.Name)
end

local function connectCheckpoint(part)
	if connected[part] or not part:IsA("BasePart") then
		return
	end

	local checkpointNumber = getCheckpointNumber(part)
	if not checkpointNumber then
		warn("Checkpoint ignorado: " .. part:GetFullName() .. " (usa nomes 1, 2, 3, ...)")
		return
	end

	connected[part] = true

	part.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player or not player:GetAttribute("InRound") then
			return
		end

		local attributeName = "Checkpoint_" .. checkpointNumber

		if player:GetAttribute(attributeName) then
			return
		end

		player:SetAttribute(attributeName, true)

		local reward =
			GameConfig.Checkpoints.BaseCoins
			+ ((checkpointNumber - 1) * GameConfig.Checkpoints.CoinsPerCheckpoint)

		local coins = getCoinsStat(player)
		if coins then
			coins.Value += reward
		end

		player:SetAttribute(
			"RoundCoins",
			(player:GetAttribute("RoundCoins") or 0) + reward
		)

		player:SetAttribute("LastCheckpoint", checkpointNumber)

		print(
			string.format(
				"✅ %s chegou ao checkpoint %d (+%d Coins)",
				player.Name,
				checkpointNumber,
				reward
			)
		)
	end)
end

local function resetPlayerCheckpoints(player)
	for attributeName in pairs(player:GetAttributes()) do
		if string.sub(attributeName, 1, 11) == "Checkpoint_" then
			player:SetAttribute(attributeName, nil)
		end
	end

	player:SetAttribute("LastCheckpoint", 0)
end

local function setupPlayer(player)
	resetPlayerCheckpoints(player)

	player:GetAttributeChangedSignal("InRound"):Connect(function()
		if player:GetAttribute("InRound") then
			resetPlayerCheckpoints(player)
		end
	end)
end

for _, child in checkpointsFolder:GetChildren() do
	connectCheckpoint(child)
end

checkpointsFolder.ChildAdded:Connect(connectCheckpoint)

Players.PlayerAdded:Connect(setupPlayer)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
