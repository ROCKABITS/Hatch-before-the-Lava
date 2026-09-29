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
local baseOriginCFrame

local movingParts = {}
local spinnerParts = {}
local runtimeConnection

local PLATFORM_COLOR = Color3.fromRGB(75, 65, 62)
local PLATFORM_ACCENT = Color3.fromRGB(108, 92, 83)
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
				part.CFrame = data.baseCFrame * CFrame.new(
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

	if not baseOriginCFrame then
		baseOriginCFrame = CFrame.new(roundSpawn.Position)
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
	checkpoint.Size = Vector3.new(8, 0.5, 8)
	checkpoint.CFrame = CFrame.new(position + Vector3.new(0, 1.1, 0))
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

local function sectionSteps(current, yaw, random)
	local forward, right = directionVectors(yaw)

	for index = 1, 5 do
		local lateral = random:NextNumber(-1.6, 1.6)
		current +=
			forward * random:NextNumber(5.8, 6.8)
			+ right * lateral
			+ Vector3.new(0, 3, 0)

		makePlatform(current, Vector3.new(6, 1, 6), index % 2 == 0)
	end

	return current
end

local function sectionZigZag(current, yaw)
	local forward, right = directionVectors(yaw)

	for index = 1, 6 do
		local side = index % 2 == 0 and -1 or 1

		current +=
			forward * 4.5
			+ right * (side * 4.8)
			+ Vector3.new(0, 2.5, 0)

		makePlatform(current, Vector3.new(5.5, 1, 5.5), index % 2 == 0)
	end

	return current
end

local function sectionStairs(current, yaw)
	local forward = directionVectors(yaw)

	for index = 1, 7 do
		current += forward * 4.6 + Vector3.new(0, 2.2, 0)
		makePlatform(current, Vector3.new(7, 1, 5), index % 2 == 1)
	end

	return current
end

local function sectionTinyPlatforms(current, yaw, random)
	local forward, right = directionVectors(yaw)

	for index = 1, 6 do
		local side = random:NextNumber(-2.8, 2.8)

		current +=
			forward * random:NextNumber(5.2, 6.0)
			+ right * side
			+ Vector3.new(0, 2.7, 0)

		makePlatform(current, Vector3.new(4.2, 1, 4.2), index % 2 == 0)
	end

	return current
end

local function sectionBeam(current, yaw)
	local forward = directionVectors(yaw)
	local target = current + forward * 18 + Vector3.new(0, 8, 0)
	local midpoint = (current + target) / 2
	local distance = (target - current).Magnitude

	local beam = makePart(
		"NarrowBeam",
		Vector3.new(3, 1, distance),
		CFrame.lookAt(midpoint, target),
		PLATFORM_ACCENT,
		Enum.Material.Metal
	)

	beam.CanCollide = true

	current = target
	makePlatform(current, Vector3.new(7, 1, 7), false)

	return current
end

local function sectionMoving(current, yaw, random)
	local forward, right = directionVectors(yaw)
	local moverPosition = current + forward * 7 + Vector3.new(0, 4, 0)
	local landingPosition = current + forward * 14 + Vector3.new(0, 9, 0)

	local mover = makePart(
		"MovingPlatform",
		Vector3.new(6, 1, 6),
		CFrame.new(moverPosition),
		Color3.fromRGB(120, 145, 180),
		Enum.Material.Metal
	)

	addMovingPlatform(
		mover,
		mover.CFrame,
		right,
		3.5,
		random:NextNumber(0.8, 1.15),
		random:NextNumber(0, math.pi * 2)
	)

	current = landingPosition
	makePlatform(current, Vector3.new(8, 1, 8), true)

	return current
end

local function sectionSpinner(current, yaw, random)
	local forward = directionVectors(yaw)
	local arena = current + forward * 8 + Vector3.new(0, 4, 0)

	makePlatform(arena, Vector3.new(13, 1, 13), false)

	local spinner = makePart(
		"Spinner",
		Vector3.new(15, 0.8, 1.3),
		CFrame.new(arena + Vector3.new(0, 1.4, 0)),
		Color3.fromRGB(235, 85, 55),
		Enum.Material.Neon
	)

	addSpinner(
		spinner,
		spinner.CFrame,
		random:NextNumber(1.3, 2.0)
	)

	current = arena + forward * 10 + Vector3.new(0, 4, 0)
	makePlatform(current, Vector3.new(7, 1, 7), true)

	return current
end

local SECTION_BUILDERS = {
	Steps = sectionSteps,
	ZigZag = sectionZigZag,
	Stairs = sectionStairs,
	Tiny = sectionTinyPlatforms,
	Beam = sectionBeam,
	Moving = sectionMoving,
	Spinner = sectionSpinner,
}

local EASY_SECTIONS = {"Steps", "ZigZag", "Stairs"}
local ALL_SECTIONS = {"Steps", "ZigZag", "Stairs", "Tiny", "Beam", "Moving", "Spinner"}

local function chooseSection(random, index, previous)
	local pool = index <= 3 and EASY_SECTIONS or ALL_SECTIONS
	local choice

	repeat
		choice = pool[random:NextInteger(1, #pool)]
	until choice ~= previous or #pool == 1

	return choice
end

function ObbyGenerator.Generate(roundNumber)
	ensureRuntimeConnection()
	clearGenerated()

	local seed = os.time() + (roundNumber * 100003)
	local random = Random.new(seed)

	local origin = baseOriginCFrame.Position
	local current = origin
	local yaw = math.rad(random:NextInteger(0, 3) * 90)
	local previousSection
	local sectionNames = {}

	createStartArea(origin)

	local sectionCount = GameConfig.Obby.SectionCount
	local checkpointEvery = GameConfig.Obby.CheckpointEvery
	local checkpointNumber = 0

	for index = 1, sectionCount do
		local sectionName = chooseSection(random, index, previousSection)
		local builder = SECTION_BUILDERS[sectionName]

		current = builder(current, yaw, random)
		table.insert(sectionNames, sectionName)
		previousSection = sectionName

		if index % checkpointEvery == 0 then
			checkpointNumber += 1
			createCheckpoint(checkpointNumber, current)
		end

		if index < sectionCount and random:NextNumber() < 0.40 then
			local turn = random:NextNumber() < 0.5 and -1 or 1
			yaw += math.rad(90 * turn)
		end
	end

	local forward = directionVectors(yaw)
	current += forward * 7 + Vector3.new(0, 4, 0)
	makePlatform(current, Vector3.new(8, 1, 8), true)

	local finishPosition = current + forward * 7 + Vector3.new(0, 3, 0)
	createFinish(finishPosition)

	workspace:SetAttribute("CurrentObbySeed", seed)
	workspace:SetAttribute("CurrentObbyHeight", math.floor(finishPosition.Y - origin.Y))

	print(
		string.format(
			"🧱 Generated obby for round %d | seed=%d | height=%dm | %s",
			roundNumber,
			seed,
			math.floor(finishPosition.Y - origin.Y),
			table.concat(sectionNames, " > ")
		)
	)

	return {
		Seed = seed,
		Height = math.floor(finishPosition.Y - origin.Y),
		FinishY = finishPosition.Y,
		Sections = sectionNames,
		CheckpointCount = checkpointNumber,
	}
end

ensureRuntimeConnection()

return ObbyGenerator
