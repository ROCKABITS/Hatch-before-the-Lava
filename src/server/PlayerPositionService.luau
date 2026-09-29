local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local PlayerPositionService = {}

local function getSpawn(name)
	local spawn = workspace:FindFirstChild(name)

	if spawn and spawn:IsA("BasePart") then
		return spawn
	end

	return nil
end

local function moveCharacterToPart(character, targetPart)
	if not character or not targetPart then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or humanoid.Health <= 0 or not root then
		return false
	end

	local targetCFrame =
		targetPart.CFrame
		* CFrame.new(0, GameConfig.Spawns.OffsetY or 3, 0)

	character:PivotTo(targetCFrame)

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	return true
end

function PlayerPositionService.MoveToLobby(player)
	local lobbySpawn = getSpawn(GameConfig.Spawns.Lobby)

	if not lobbySpawn then
		warn("Missing Workspace." .. GameConfig.Spawns.Lobby)
		return false
	end

	return moveCharacterToPart(player.Character, lobbySpawn)
end

function PlayerPositionService.MoveToRoundStart(player)
	local roundSpawn = getSpawn(GameConfig.Spawns.Round)

	if not roundSpawn then
		warn("Missing Workspace." .. GameConfig.Spawns.Round)
		return false
	end

	return moveCharacterToPart(player.Character, roundSpawn)
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.15)

		if not player:GetAttribute("InRound") then
			PlayerPositionService.MoveToLobby(player)
		end
	end)

	if player.Character and not player:GetAttribute("InRound") then
		task.defer(function()
			task.wait(0.15)
			PlayerPositionService.MoveToLobby(player)
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

return PlayerPositionService
