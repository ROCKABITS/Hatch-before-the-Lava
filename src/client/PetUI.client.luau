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
panel.Size = UDim2.fromOffset(560, 500)
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
result.TextSize = 20
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

local function getEquippedCount(petId)
	local equipped = player:FindFirstChild("EquippedPets")
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

local function refresh()
	if refreshing then
		return
	end
	refreshing = true

	multiplier.Text = string.format("Coin Multiplier: x%.2f   •   Equipped: %d/%d", player:GetAttribute("PetMultiplier") or 1, #(player:FindFirstChild("EquippedPets") and player.EquippedPets:GetChildren() or {}), PetConfig.MaxEquipped)

	for _, child in list:GetChildren() do
		if child:IsA("TextButton") then
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
					local equippedCount = getEquippedCount(value.Name)

					local button = Instance.new("TextButton")
					button.Name = value.Name
					button.LayoutOrder = index
					button.Size = UDim2.new(1, 0, 0, 56)
					button.BackgroundColor3 = equippedCount > 0 and Color3.fromRGB(75, 145, 80) or Color3.fromRGB(48, 50, 64)
					button.TextColor3 = Color3.new(1, 1, 1)
					button.TextSize = 18
					button.Font = Enum.Font.GothamBold
					button.Text = string.format("%s  x%d   [%s]   x%.2f Coins   •   Equipped: %d", pet.DisplayName, value.Value, pet.Rarity, pet.CoinMultiplier, equippedCount)
					button.Parent = list

					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 10)
					corner.Parent = button

					button.Activated:Connect(function()
						local response = toggleEquipPet:InvokeServer(value.Name)
						if response and not response.Success then
							result.Text = response.Message or "Could not change pet"
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

	inventory.ChildAdded:Connect(refresh)
	inventory.ChildRemoved:Connect(refresh)
	equipped.ChildAdded:Connect(refresh)
	equipped.ChildRemoved:Connect(refresh)

	refresh()
end)
