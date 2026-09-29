local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local LavaSystem = require(script.Parent:WaitForChild("LavaSystem"))

local gameState = ReplicatedStorage:FindFirstChild("GameState")

if not gameState then
	gameState = Instance.new("Folder")
	gameState.Name = "GameState"
	gameState.Parent = ReplicatedStorage
end

gameState:SetAttribute("State", "Waiting")
gameState:SetAttribute("TimeLeft", 0)

local function setState(state, timeLeft)
	gameState:SetAttribute("State", state)
	gameState:SetAttribute("TimeLeft", timeLeft or 0)
end

local function countdown(state, seconds)
	for timeLeft = seconds, 1, -1 do
		setState(state, timeLeft)
		task.wait(1)
	end

	setState(state, 0)
end

local function waitForPlayers()
	while #Players:GetPlayers() < GameConfig.MinimumPlayers do
		setState("WaitingForPlayers", 0)
		task.wait(1)
	end
end

local function runRound()
	LavaSystem.Reset()

	countdown("Intermission", GameConfig.IntermissionTime)
	countdown("Starting", GameConfig.StartCountdown)

	setState("LavaRising", 0)
	print("🔥 LAVA IS RISING!")

	LavaSystem.Start()

	setState("RoundOver", GameConfig.PostRoundTime)
	print("🏁 ROUND OVER!")

	task.wait(GameConfig.PostRoundTime)
end

while true do
	waitForPlayers()
	runRound()
end
