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
	lava.CanTouch = true
	lava.CanQuery = true
end

local function getSpeed(progress)
	local baseSpeed

	if progress < GameConfig.Lava.SlowUntil then
		baseSpeed = GameConfig.Lava.SlowSpeed
	elseif progress < GameConfig.Lava.NormalUntil then
		baseSpeed = GameConfig.Lava.NormalSpeed
	else
		baseSpeed = GameConfig.Lava.FastSpeed
	end

	return baseSpeed * (GameConfig.Lava.SpeedMultiplier or 1)
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

local function damageCharacterFromPart(hit)
	if not GameConfig.Lava.DamageEnabled then
		return
	end

	local character = hit and hit:FindFirstAncestorOfClass("Model")
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

local function damagePlayersInsideLava()
	if not GameConfig.Lava.DamageEnabled then
		return
	end

	for _, part in workspace:GetPartsInPart(lava) do
		damageCharacterFromPart(part)
	end
end

local function connectDamage()
	if touchConnection then
		return
	end

	touchConnection = lava.Touched:Connect(function(hit)
		damageCharacterFromPart(hit)
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

		-- Touched can miss stationary players when an anchored Part grows into them,
		-- so also check everything currently overlapping the lava.
		damagePlayersInsideLava()
	end

	running = false
end

applySettings()
connectDamage()
LavaSystem.Reset()

return LavaSystem
