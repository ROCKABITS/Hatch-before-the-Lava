local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PetConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetConfig"))

local visualsRoot = workspace:FindFirstChild("ClientPetVisuals")

if not visualsRoot then
	visualsRoot = Instance.new("Folder")
	visualsRoot.Name = "ClientPetVisuals"
	visualsRoot.Parent = workspace
end

local playerVisuals = {}

local SLOT_OFFSETS = {
	Vector3.new(-3.2, 1.7, 4.2),
	Vector3.new(0, 1.9, 5.2),
	Vector3.new(3.2, 1.7, 4.2),
}

local function makePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	return part
end

local function addNameTag(model, body, pet)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Adornee = body
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(150, 42)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.9, 0)
	billboard.Parent = model

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = string.format("%s  [x%.2f]", pet.DisplayName, pet.CoinMultiplier)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.35
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
end

local function createPetModel(petId)
	local pet = PetConfig.Pets[petId]
	if not pet then
		return nil
	end

	local visual = pet.Visual or {}
	local scale = visual.Scale or 1
	local bodyColor = visual.BodyColor or Color3.fromRGB(180, 180, 180)
	local accentColor = visual.AccentColor or bodyColor
	local material = visual.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic

	local model = Instance.new("Model")
	model.Name = petId

	local body = makePart(
		"Body",
		Vector3.new(2.15, 1.85, 2.25) * scale,
		bodyColor,
		material
	)
	body.Parent = model
	model.PrimaryPart = body

	local leftEar = makePart(
		"LeftEar",
		Vector3.new(0.55, 0.8, 0.55) * scale,
		accentColor,
		material
	)
	leftEar.Parent = model

	local rightEar = leftEar:Clone()
	rightEar.Name = "RightEar"
	rightEar.Parent = model

	local leftEye = makePart(
		"LeftEye",
		Vector3.new(0.24, 0.24, 0.18) * scale,
		Color3.fromRGB(20, 20, 20),
		Enum.Material.SmoothPlastic
	)
	leftEye.Parent = model

	local rightEye = leftEye:Clone()
	rightEye.Name = "RightEye"
	rightEye.Parent = model

	local nose = makePart(
		"Nose",
		Vector3.new(0.28, 0.22, 0.18) * scale,
		Color3.fromRGB(40, 30, 30),
		Enum.Material.SmoothPlastic
	)
	nose.Parent = model

	local origin = CFrame.new(0, 0, 0)
	body.CFrame = origin
	leftEar.CFrame = origin * CFrame.new(-0.62 * scale, 1.03 * scale, 0)
	rightEar.CFrame = origin * CFrame.new(0.62 * scale, 1.03 * scale, 0)
	leftEye.CFrame = origin * CFrame.new(-0.43 * scale, 0.18 * scale, -1.13 * scale)
	rightEye.CFrame = origin * CFrame.new(0.43 * scale, 0.18 * scale, -1.13 * scale)
	nose.CFrame = origin * CFrame.new(0, -0.18 * scale, -1.18 * scale)

	addNameTag(model, body, pet)

	return model
end

local function destroyVisualsForPlayer(player)
	local data = playerVisuals[player]
	if not data then
		return
	end

	for _, connection in data.connections do
		connection:Disconnect()
	end

	if data.folder then
		data.folder:Destroy()
	end

	playerVisuals[player] = nil
end

local function rebuildPlayerPets(player)
	local data = playerVisuals[player]
	if not data then
		return
	end

	for _, child in data.folder:GetChildren() do
		child:Destroy()
	end

	data.models = {}

	local equipped = player:FindFirstChild("EquippedPets")
	if not equipped then
		return
	end

	local slots = equipped:GetChildren()
	table.sort(slots, function(a, b)
		return (tonumber(a.Name) or 999) < (tonumber(b.Name) or 999)
	end)

	for index, slot in ipairs(slots) do
		if index > PetConfig.MaxEquipped then
			break
		end

		if slot:IsA("StringValue") and PetConfig.Pets[slot.Value] then
			local model = createPetModel(slot.Value)

			if model then
				model.Name = string.format("%d_%s", index, slot.Value)
				model.Parent = data.folder

				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local offset = SLOT_OFFSETS[index] or Vector3.new((index - 2) * 3, 1.7, 4.5)
					model:PivotTo(root.CFrame * CFrame.new(offset))
				end

				table.insert(data.models, {
					model = model,
					slotIndex = index,
					bobOffset = index * 1.65,
				})
			end
		end
	end
end

local function connectEquippedFolder(player, data, equipped)
	table.insert(data.connections, equipped.ChildAdded:Connect(function()
		task.defer(rebuildPlayerPets, player)
	end))

	table.insert(data.connections, equipped.ChildRemoved:Connect(function()
		task.defer(rebuildPlayerPets, player)
	end))
end

local function setupPlayer(player)
	destroyVisualsForPlayer(player)

	local folder = Instance.new("Folder")
	folder.Name = tostring(player.UserId)
	folder.Parent = visualsRoot

	local data = {
		folder = folder,
		models = {},
		connections = {},
	}

	playerVisuals[player] = data

	task.spawn(function()
		local equipped = player:WaitForChild("EquippedPets", 20)

		if not equipped or playerVisuals[player] ~= data then
			return
		end

		connectEquippedFolder(player, data, equipped)
		rebuildPlayerPets(player)
	end)

	table.insert(data.connections, player.CharacterAdded:Connect(function()
		task.wait(0.25)
		rebuildPlayerPets(player)
	end))
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	destroyVisualsForPlayer(player)
end)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

RunService.RenderStepped:Connect(function(deltaTime)
	local now = time()
	local alpha = 1 - math.exp(-8 * deltaTime)

	for player, data in pairs(playerVisuals) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if root and humanoid and humanoid.Health > 0 then
			for _, petData in ipairs(data.models) do
				local model = petData.model

				if model and model.Parent then
					local offset = SLOT_OFFSETS[petData.slotIndex]
						or Vector3.new((petData.slotIndex - 2) * 3, 1.7, 4.5)

					local bob = math.sin(now * 3 + petData.bobOffset) * 0.28
					local target =
						root.CFrame
						* CFrame.new(offset.X, offset.Y + bob, offset.Z)
						* CFrame.Angles(0, math.rad(180), 0)

					model:PivotTo(model:GetPivot():Lerp(target, alpha))
				end
			end
		end
	end
end)
