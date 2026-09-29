local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local ObbyGenerator = {}

local GENERATED_FOLDER_NAME = "GeneratedObby"
local CHECKPOINT_FOLDER_NAME = "Checkpoints"

local generatedFolder
local checkpointsFolder
local roundSpawn
local finishPart
local baseOrigin

local movingParts = {}
local spinnerParts = {}
local runtimeConnection

local PLATFORM_COLOR = Color3.fromRGB(76, 68, 64)
local PLATFORM_ACCENT = Color3.fromRGB(112, 96, 86)
local METAL_COLOR = Color3.fromRGB(115, 125, 140)
local DANGER_COLOR = Color3.fromRGB(235, 82, 55)
local CHECKPOINT_COLOR = Color3.fromRGB(80, 220, 255)
local FINISH_COLOR = Color3.fromRGB(255, 220, 75)
local START_COLOR = Color3.fromRGB(95, 215, 120)

local function ensureRuntimeConnection()
	if runtimeConnection then
		return
	end

	runtimeConnection = RunService.Heartbeat:Connect(function(deltaTime)
		local now = workspace:GetServerTimeNow()

		for _, data in ipairs(movingParts) do
			local part = data.part

			if part and part.Parent then
				local offset = math.sin(now * data.speed + data.phase) * data.distance

				part.CFrame =
					data.baseCFrame
					* CFrame.new(
						data.axis.X * offset,
						data.axis.Y * offset,
						data.axis.Z * offset
					)
			end
		end

		for _, data in ipairs(spinnerParts) do
			local part = data.part

			if part and part.Parent then
				data.angle += data.speed * deltaTime
				part.CFrame = data.baseCFrame * CFrame.Angles(0, data.angle, 0)
			end
		end
	end)
end

local function ensureWorkspaceObjects()
	generatedFolder = workspace:FindFirstChild(GENERATED_FOLDER_NAME)

	if not generatedFolder then
		generatedFolder = Instance.new("Folder")
		generatedFolder.Name = GENERATED_FOLDER_NAME
		generatedFolder.Parent = workspace
	end

	checkpointsFolder = workspace:FindFirstChild(CHECKPOINT_FOLDER_NAME)

	if not checkpointsFolder then
		checkpointsFolder = Instance.new("Folder")
		checkpointsFolder.Name = CHECKPOINT_FOLDER_NAME
		checkpointsFolder.Parent = workspace
	end

	roundSpawn = workspace:FindFirstChild(GameConfig.RoundStartPart)

	if not roundSpawn then
		roundSpawn = Instance.new("Part")
		roundSpawn.Name = GameConfig.RoundStartPart
		roundSpawn.Size = Vector3.new(12, 6, 12)
		roundSpawn.CFrame = CFrame.new(0, 4, 0)
		roundSpawn.Parent = workspace
	end

	if not roundSpawn:IsA("BasePart") then
		error("Workspace." .. GameConfig.RoundStartPart .. " precisa de ser uma Part/BasePart.")
	end

	finishPart = workspace:FindFirstChild("Finish")

	if not finishPart then
		finishPart = Instance.new("Part")
		finishPart.Name = "Finish"
		finishPart.Parent = workspace
	end

	if not finishPart:IsA("BasePart") then
		error("Workspace.Finish precisa de ser uma Part/BasePart.")
	end

	if not baseOrigin then
		baseOrigin = roundSpawn.Position - Vector3.new(0, 3, 0)
	end

	roundSpawn.Anchored = true
	roundSpawn.CanCollide = false
	roundSpawn.CanTouch = true
	roundSpawn.CanQuery = true
	roundSpawn.Transparency = 1
	roundSpawn.Size = Vector3.new(12, 6, 12)

	finishPart.Anchored = true
	finishPart.CanCollide = true
	finishPart.CanTouch = true
	finishPart.CanQuery = true
	finishPart.Material = Enum.Material.Neon
	finishPart.Color = FINISH_COLOR
end

local function clearGenerated()
	ensureWorkspaceObjects()

	for _, child in generatedFolder:GetChildren() do
		child:Destroy()
	end

	for _, child in checkpointsFolder:GetChildren() do
		if child:IsA("BasePart") and tonumber(child.Name) then
			child:Destroy()
		end
	end

	movingParts = {}
	spinnerParts = {}
end

local function makePart(name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.Material = material or Enum.Material.Slate
	part.Color = color or PLATFORM_COLOR
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = generatedFolder

	return part
end

local function makePlatform(position, size, accent)
	return makePart(
		"Platform",
		size or Vector3.new(6, 1, 6),
		CFrame.new(position),
		accent and PLATFORM_ACCENT or PLATFORM_COLOR,
		Enum.Material.Slate
	)
end

local function addBillboard(part, text, textColor)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(240, 56)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
end

local function directionVectors(yaw)
	local forward = Vector3.new(math.sin(yaw), 0, -math.cos(yaw))
	local right = Vector3.new(math.cos(yaw), 0, math.sin(yaw))

	return forward, right
end

local function createCheckpoint(number, position)
	local checkpoint = Instance.new("Part")
	checkpoint.Name = tostring(number)
	checkpoint.Size = Vector3.new(9, 0.5, 9)
	checkpoint.CFrame = CFrame.new(position + Vector3.new(0, 1.15, 0))
	checkpoint.Anchored = true
	checkpoint.CanCollide = false
	checkpoint.CanTouch = true
	checkpoint.CanQuery = true
	checkpoint.Material = Enum.Material.Neon
	checkpoint.Color = CHECKPOINT_COLOR
	checkpoint.Transparency = 0.2
	checkpoint.Parent = checkpointsFolder

	addBillboard(checkpoint, "🚩 CHECKPOINT " .. number, CHECKPOINT_COLOR)
end

local function createStartArea(origin)
	local startPlatform = makePart(
		"StartPlatform",
		Vector3.new(14, 1, 14),
		CFrame.new(origin),
		START_COLOR,
		Enum.Material.SmoothPlastic
	)

	addBillboard(startPlatform, "🌋 START", START_COLOR)
	roundSpawn.CFrame = CFrame.new(origin + Vector3.new(0, 3, 0))
end

local function createFinish(position)
	finishPart.Size = Vector3.new(14, 1, 14)
	finishPart.CFrame = CFrame.new(position)
	finishPart.Transparency = 0

	for _, child in finishPart:GetChildren() do
		if child:IsA("BillboardGui") then
			child:Destroy()
		end
	end

	addBillboard(finishPart, "🏁 FINISH", FINISH_COLOR)
end

local function addMovingPlatform(part, baseCFrame, axis, distance, speed, phase)
	table.insert(movingParts, {
		part = part,
		baseCFrame = baseCFrame,
		axis = axis,
		distance = distance,
		speed = speed,
		phase = phase,
	})
end

local function addSpinner(part, baseCFrame, speed)
	table.insert(spinnerParts, {
		part = part,
		baseCFrame = baseCFrame,
		speed = speed,
		angle = 0,
	})
end

-- Every floor is mostly horizontal. Height is gained between floors,
-- so the obby spreads around a large footprint instead of becoming
-- a straight vertical stack of platforms.

local function floorJumpPads(startPosition, yaw, random)
	local forward, right = directionVectors(yaw)
	local current = startPosition

	for index = 1, 5 do
		local side = random:NextNumber(-2.2, 2.2)
		current =
			startPosition
			+ forward * (index * 6.2)
			+ right * side
			+ Vector3.new(0, random:NextNumber(-0.5, 0.7), 0)

		makePlatform(current, Vector3.new(5.2, 1, 5.2), index % 2 == 0)
	end

	local finish = startPosition + forward * 37
	makePlatform(finish, Vector3.new(9, 1, 9), false)

	return finish
end

local function floorZigZag(startPosition, yaw)
	local forward, right = directionVectors(yaw)

	for index = 1, 6 do
		local side = index % 2 == 0 and -1 or 1
		local position =
			startPosition
			+ forward * (index * 5.3)
			+ right * (side * 4.3)

		makePlatform(position, Vector3.new(5.5, 1, 5.5), index % 2 == 0)
	end

	local finish = startPosition + forward * 37
	makePlatform(finish, Vector3.new(9, 1, 9), false)

	return finish
end

local function floorBeam(startPosition, yaw)
	local forward = directionVectors(yaw)
	local beamStart = startPosition + forward * 5
	local beamEnd = startPosition + forward * 30
	local midpoint = (beamStart + beamEnd) / 2
	local distance = (beamEnd - beamStart).Magnitude

	makePart(
		"NarrowBeam",
		Vector3.new(2.8, 1, distance),
		CFrame.lookAt(midpoint, beamEnd),
		METAL_COLOR,
		Enum.Material.Metal
	)

	local finish = startPosition + forward * 37
	makePlatform(finish, Vector3.new(9, 1, 9), true)

	return finish
end

local function floorMoving(startPosition, yaw, random)
	local forward, right = directionVectors(yaw)

	local first = startPosition + forward * 8
	makePlatform(first, Vector3.new(7, 1, 7), false)

	local moverPosition = startPosition + forward * 19
	local mover = makePart(
		"MovingPlatform",
		Vector3.new(6.5, 1, 6.5),
		CFrame.new(moverPosition),
		METAL_COLOR,
		Enum.Material.Metal
	)

	addMovingPlatform(
		mover,
		mover.CFrame,
		right,
		4,
		random:NextNumber(0.85, 1.15),
		random:NextNumber(0, math.pi * 2)
	)

	local third = startPosition + forward * 29
	makePlatform(third, Vector3.new(7, 1, 7), true)

	local finish = startPosition + forward * 37
	makePlatform(finish, Vector3.new(9, 1, 9), false)

	return finish
end

local function floorSpinner(startPosition, yaw, random)
	local forward = directionVectors(yaw)
	local arena = startPosition + forward * 19

	makePlatform(arena, Vector3.new(18, 1, 18), false)

	local spinner = makePart(
		"Spinner",
		Vector3.new(19, 0.9, 1.4),
		CFrame.new(arena + Vector3.new(0, 1.4, 0)),
		DANGER_COLOR,
		Enum.Material.Neon
	)

	addSpinner(
		spinner,
		spinner.CFrame,
		random:NextNumber(1.1, 1.7)
	)

	local finish = startPosition + forward * 38
	makePlatform(finish, Vector3.new(9, 1, 9), true)

	return finish
end

local function floorSlalom(startPosition, yaw)
	local forward, right = directionVectors(yaw)

	for index = 1, 5 do
		local side = index % 2 == 0 and -1 or 1
		local center =
			startPosition
			+ forward * (index * 6)
			+ right * (side * 3.6)

		makePart(
			"SlalomPad",
			Vector3.new(8, 1, 4),
			CFrame.new(center),
			index % 2 == 0 and PLATFORM_ACCENT or PLATFORM_COLOR,
			Enum.Material.Slate
		)
	end

	local finish = startPosition + forward * 37
	makePlatform(finish, Vector3.new(9, 1, 9), false)

	return finish
end

local FLOOR_BUILDERS = {
	JumpPads = floorJumpPads,
	ZigZag = floorZigZag,
	Beam = floorBeam,
	Moving = floorMoving,
	Spinner = floorSpinner,
	Slalom = floorSlalom,
}

local EASY_FLOORS = {"JumpPads", "ZigZag", "Slalom"}
local ALL_FLOORS = {"JumpPads", "ZigZag", "Beam", "Moving", "Spinner", "Slalom"}

local function chooseFloor(random, floorNumber, previous)
	local pool = floorNumber <= 2 and EASY_FLOORS or ALL_FLOORS
	local choice

	repeat
		choice = pool[random:NextInteger(1, #pool)]
	until choice ~= previous or #pool == 1

	return choice
end

local function buildRise(startPosition, yaw, floorHeight)
	local forward = directionVectors(yaw)
	local stepCount = 5
	local risePerStep = floorHeight / stepCount
	local runPerStep = 3.4
	local current = startPosition

	for index = 1, stepCount do
		current =
			startPosition
			+ forward * (index * runPerStep)
			+ Vector3.new(0, index * risePerStep, 0)

		makePlatform(
			current,
			Vector3.new(7, 1, 5),
			index % 2 == 0
		)
	end

	local landing =
		startPosition
		+ forward * ((stepCount + 1) * runPerStep)
		+ Vector3.new(0, floorHeight, 0)

	makePlatform(landing, Vector3.new(10, 1, 10), true)

	return landing
end

local function addFloorMarker(floorNumber, position)
	local marker = makePart(
		"FloorMarker",
		Vector3.new(1, 1, 1),
		CFrame.new(position + Vector3.new(0, 4, 0)),
		PLATFORM_COLOR,
		Enum.Material.SmoothPlastic
	)

	marker.Transparency = 1
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false

	addBillboard(marker, "FLOOR " .. floorNumber, Color3.new(1, 1, 1))
end

function ObbyGenerator.Generate(roundNumber)
	ensureRuntimeConnection()
	clearGenerated()

	local seed = os.time() + (roundNumber * 100003)
	local random = Random.new(seed)

	local origin = baseOrigin
	local current = origin
	local initialYaw = math.rad(random:NextInteger(0, 3) * 90)
	local turnDirection = random:NextNumber() < 0.5 and -1 or 1
	local yaw = initialYaw
	local previousFloor
	local floorNames = {}

	createStartArea(origin)

	local floorCount = GameConfig.Obby.FloorCount
	local floorHeight = GameConfig.Obby.FloorHeight
	local checkpointEvery = GameConfig.Obby.CheckpointEvery
	local checkpointNumber = 0

	for floorNumber = 1, floorCount do
		addFloorMarker(floorNumber, current)

		local floorName = chooseFloor(random, floorNumber, previousFloor)
		local builder = FLOOR_BUILDERS[floorName]

		current = builder(current, yaw, random)
		table.insert(floorNames, floorName)
		previousFloor = floorName

		if floorNumber % checkpointEvery == 0 then
			checkpointNumber += 1
			createCheckpoint(checkpointNumber, current)
		end

		if floorNumber < floorCount then
			current = buildRise(current, yaw, floorHeight)
			yaw += math.rad(90 * turnDirection)
		end
	end

	local forward = directionVectors(yaw)
	local finishPosition = current + forward * 8
	makePlatform(finishPosition, Vector3.new(15, 1, 15), true)
	createFinish(finishPosition + Vector3.new(0, 0.65, 0))

	local totalHeight = math.floor(finishPosition.Y - origin.Y)

	workspace:SetAttribute("CurrentObbySeed", seed)
	workspace:SetAttribute("CurrentObbyHeight", totalHeight)

	print(
		string.format(
			"🧱 Generated round %d | seed=%d | height=%dm | %s",
			roundNumber,
			seed,
			totalHeight,
			table.concat(floorNames, " > ")
		)
	)

	return {
		Seed = seed,
		Height = totalHeight,
		FinishY = finishPosition.Y,
		Sections = floorNames,
		CheckpointCount = checkpointNumber,
	}
end

ensureRuntimeConnection()

return ObbyGenerator
