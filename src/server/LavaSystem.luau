local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local LavaSystem = {}

local lava = workspace:WaitForChild("Lava")

local startSize = lava.Size
local startPosition = lava.Position
local running = false
local touchConnection = nil

local function applySettings()
	lava.CanCollide = GameConfig.Lava.CanCollide
end

local function getSpeed(progress)
	if progress < GameConfig.Lava.SlowUntil then
		return GameConfig.Lava.SlowSpeed
	elseif progress < GameConfig.Lava.NormalUntil then
		return GameConfig.Lava.NormalSpeed
	else
		return GameConfig.Lava.FastSpeed
	end
end

local function getProgress()
	local currentHeight = lava.Size.Y
	local startHeight = startSize.Y
	local maxHeight = GameConfig.Lava.MaxHeight

	if maxHeight <= startHeight then
		return 1
	end

	return math.clamp((currentHeight - startHeight) / (maxHeight - startHeight), 0, 1)
end

local function connectDamage()
	if touchConnection then
		return
	end

	touchConnection = lava.Touched:Connect(function(hit)
		if not GameConfig.Lava.KillOnTouch then
			return
		end

		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)
end

function LavaSystem.Reset()
	running = false
	applySettings()
	lava.Size = startSize
	lava.Position = startPosition
end

function LavaSystem.Stop()
	running = false
end

function LavaSystem.GetProgress()
	return getProgress()
end

function LavaSystem.GetHeight()
	return lava.Size.Y
end

function LavaSystem.Start()
	applySettings()
	connectDamage()
	running = true

	while running and lava.Size.Y < GameConfig.Lava.MaxHeight do
		local deltaTime = RunService.Heartbeat:Wait()

		local progress = getProgress()
		local speed = getSpeed(progress)
		local increase = speed * deltaTime

		increase = math.min(
			increase,
			GameConfig.Lava.MaxHeight - lava.Size.Y
		)

		lava.Size += Vector3.new(0, increase, 0)
		lava.Position += Vector3.new(0, increase / 2, 0)
	end

	running = false
end

applySettings()
connectDamage()
LavaSystem.Reset()

return LavaSystem
