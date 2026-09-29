local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PetConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local hatchEgg = remotes:WaitForChild("HatchEgg")
local toggleEquipPet = remotes:WaitForChild("ToggleEquipPet")

local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("PetUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "PetUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenPets"
openButton.Position = UDim2.new(0, 18, 0.5, -55)
openButton.Size = UDim2.fromOffset(110, 54)
openButton.BackgroundColor3 = Color3.fromRGB(255, 170, 45)
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Text = "🐾 PETS"
openButton.TextScaled = true
openButton.Font = Enum.Font.GothamBold
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 14)
openCorner.Parent = openButton

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(610, 520)
panel.BackgroundColor3 = Color3.fromRGB(28, 29, 38)
panel.Visible = false
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 12)
title.Size = UDim2.new(1, -90, 0, 50)
title.Text = "🐾 PETS"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 30
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -60, 0, 12)
close.Size = UDim2.fromOffset(44, 44)
close.BackgroundColor3 = Color3.fromRGB(60, 62, 78)
close.Text = "×"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextScaled = true
close.Font = Enum.Font.GothamBold
close.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = close

local multiplier = Instance.new("TextLabel")
multiplier.BackgroundTransparency = 1
multiplier.Position = UDim2.fromOffset(20, 64)
multiplier.Size = UDim2.new(1, -40, 0, 34)
multiplier.TextColor3 = Color3.fromRGB(255, 220, 80)
multiplier.TextSize = 22
multiplier.TextXAlignment = Enum.TextXAlignment.Left
multiplier.Font = Enum.Font.GothamBold
multiplier.Parent = panel

local hatch = Instance.new("TextButton")
hatch.Position = UDim2.fromOffset(20, 108)
hatch.Size = UDim2.new(1, -40, 0, 60)
hatch.BackgroundColor3 = Color3.fromRGB(255, 122, 40)
hatch.TextColor3 = Color3.new(1, 1, 1)
hatch.Text = "🥚 HATCH STARTER EGG — 500 COINS"
hatch.TextScaled = true
hatch.Font = Enum.Font.GothamBold
hatch.Parent = panel

local hatchCorner = Instance.new("UICorner")
hatchCorner.CornerRadius = UDim.new(0, 14)
hatchCorner.Parent = hatch

local result = Instance.new("TextLabel")
result.BackgroundTransparency = 1
result.Position = UDim2.fromOffset(20, 176)
result.Size = UDim2.new(1, -40, 0, 38)
result.Text = ""
result.TextColor3 = Color3.new(1, 1, 1)
result.TextSize = 18
result.Font = Enum.Font.GothamBold
result.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(20, 220)
list.Size = UDim2.new(1, -40, 1, -240)
list.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
list.BorderSizePixel = 0
list.ScrollBarThickness = 8
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 14)
listCorner.Parent = list

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = list

local refreshing = false
local inventoryConnections = {}

local function getEquippedFolder()
	return player:FindFirstChild("EquippedPets")
end

local function getEquippedCount(petId)
	local equipped = getEquippedFolder()
	if not equipped then
		return 0
	end

	local count = 0
	for _, slot in equipped:GetChildren() do
		if slot:IsA("StringValue") and slot.Value == petId then
			count += 1
		end
	end

	return count
end

local function getTotalEquipped()
	local equipped = getEquippedFolder()
	return equipped and #equipped:GetChildren() or 0
end

local function makeSmallButton(parent, text, position, background)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(46, 46)
	button.Position = position
	button.BackgroundColor3 = background
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = text
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return button
end

local function refresh()
	if refreshing then
		return
	end

	refreshing = true

	local totalEquipped = getTotalEquipped()

	multiplier.Text = string.format(
		"Coin Multiplier: x%.2f   •   Equipped: %d/%d",
		player:GetAttribute("PetMultiplier") or 1,
		totalEquipped,
		PetConfig.MaxEquipped
	)

	for _, child in list:GetChildren() do
		if child:IsA("Frame") and child.Name == "PetRow" then
			child:Destroy()
		end
	end

	local inventory = player:FindFirstChild("PetInventory")

	if inventory then
		local pets = inventory:GetChildren()

		table.sort(pets, function(a, b)
			return a.Name < b.Name
		end)

		for index, value in ipairs(pets) do
			if value:IsA("IntValue") and value.Value > 0 then
				local pet = PetConfig.Pets[value.Name]

				if pet then
					local petId = value.Name
					local ownedCount = value.Value
					local equippedCount = getEquippedCount(petId)

					local row = Instance.new("Frame")
					row.Name = "PetRow"
					row.LayoutOrder = index
					row.Size = UDim2.new(1, 0, 0, 68)
					row.BackgroundColor3 = equippedCount > 0
						and Color3.fromRGB(55, 92, 62)
						or Color3.fromRGB(48, 50, 64)
					row.Parent = list

					local rowCorner = Instance.new("UICorner")
					rowCorner.CornerRadius = UDim.new(0, 10)
					rowCorner.Parent = row

					local info = Instance.new("TextLabel")
					info.BackgroundTransparency = 1
					info.Position = UDim2.fromOffset(12, 6)
					info.Size = UDim2.new(1, -132, 1, -12)
					info.TextColor3 = Color3.new(1, 1, 1)
					info.TextXAlignment = Enum.TextXAlignment.Left
					info.TextYAlignment = Enum.TextYAlignment.Center
					info.TextSize = 17
					info.Font = Enum.Font.GothamBold
					info.Text = string.format(
						"%s  x%d  [%s]\nx%.2f Coins   •   Equipped: %d",
						pet.DisplayName,
						ownedCount,
						pet.Rarity,
						pet.CoinMultiplier,
						equippedCount
					)
					info.Parent = row

					local minus = makeSmallButton(
						row,
						"−",
						UDim2.new(1, -106, 0.5, -23),
						Color3.fromRGB(150, 65, 65)
					)

					local plus = makeSmallButton(
						row,
						"+",
						UDim2.new(1, -54, 0.5, -23),
						Color3.fromRGB(65, 145, 80)
					)

					minus.Active = equippedCount > 0
					minus.AutoButtonColor = minus.Active
					if not minus.Active then
						minus.BackgroundColor3 = Color3.fromRGB(75, 75, 82)
					end

					plus.Active =
						totalEquipped < PetConfig.MaxEquipped
						and equippedCount < ownedCount
					plus.AutoButtonColor = plus.Active
					if not plus.Active then
						plus.BackgroundColor3 = Color3.fromRGB(75, 75, 82)
					end

					minus.Activated:Connect(function()
						if not minus.Active then
							return
						end

						minus.Active = false
						local response = toggleEquipPet:InvokeServer(petId, "Unequip")

						if response and response.Success then
							result.Text = "Unequipped " .. pet.DisplayName
						else
							result.Text = response and response.Message or "Could not unequip pet"
						end

						task.wait()
						refresh()
					end)

					plus.Activated:Connect(function()
						if not plus.Active then
							return
						end

						plus.Active = false
						local response = toggleEquipPet:InvokeServer(petId, "Equip")

						if response and response.Success then
							result.Text = "Equipped " .. pet.DisplayName
						else
							result.Text = response and response.Message or "Could not equip pet"
						end

						task.wait()
						refresh()
					end)
				end
			end
		end
	end

	refreshing = false
end

local function connectInventoryValue(value)
	if not value:IsA("IntValue") or inventoryConnections[value] then
		return
	end

	inventoryConnections[value] = value.Changed:Connect(refresh)
end

openButton.Activated:Connect(function()
	panel.Visible = true
	refresh()
end)

close.Activated:Connect(function()
	panel.Visible = false
end)

hatch.Activated:Connect(function()
	hatch.Active = false
	hatch.Text = "HATCHING..."

	local response = hatchEgg:InvokeServer("Starter")

	if response and response.Success then
		result.Text = string.format("🎉 You hatched %s! [%s]", response.DisplayName, response.Rarity)
	else
		result.Text = response and response.Message or "Hatch failed"
	end

	hatch.Text = "🥚 HATCH STARTER EGG — 500 COINS"
	hatch.Active = true
	refresh()
end)

player:GetAttributeChangedSignal("PetMultiplier"):Connect(refresh)

task.spawn(function()
	local inventory = player:WaitForChild("PetInventory")
	local equipped = player:WaitForChild("EquippedPets")

	for _, value in inventory:GetChildren() do
		connectInventoryValue(value)
	end

	inventory.ChildAdded:Connect(function(value)
		connectInventoryValue(value)
		refresh()
	end)

	inventory.ChildRemoved:Connect(function(value)
		local connection = inventoryConnections[value]
		if connection then
			connection:Disconnect()
			inventoryConnections[value] = nil
		end
		refresh()
	end)

	equipped.ChildAdded:Connect(refresh)
	equipped.ChildRemoved:Connect(refresh)

	refresh()
end)
