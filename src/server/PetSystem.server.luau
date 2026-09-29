local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetConfig"))

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local hatchEgg = remotes:FindFirstChild("HatchEgg")
if not hatchEgg then
	hatchEgg = Instance.new("RemoteFunction")
	hatchEgg.Name = "HatchEgg"
	hatchEgg.Parent = remotes
end

local toggleEquipPet = remotes:FindFirstChild("ToggleEquipPet")
if not toggleEquipPet then
	toggleEquipPet = Instance.new("RemoteFunction")
	toggleEquipPet.Name = "ToggleEquipPet"
	toggleEquipPet.Parent = remotes
end

local random = Random.new()

local function getInventoryFolder(player)
	return player:FindFirstChild("PetInventory")
end

local function getEquippedFolder(player)
	return player:FindFirstChild("EquippedPets")
end

local function getCoins(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Coins")
end

local function getOwnedCount(player, petId)
	local inventory = getInventoryFolder(player)
	if not inventory then
		return 0
	end

	local value = inventory:FindFirstChild(petId)
	return value and value.Value or 0
end

local function getEquippedCount(player, petId)
	local equipped = getEquippedFolder(player)
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

local function getEquippedSlots(player)
	local equipped = getEquippedFolder(player)
	if not equipped then
		return {}
	end

	local slots = equipped:GetChildren()
	table.sort(slots, function(a, b)
		return (tonumber(a.Name) or 999) < (tonumber(b.Name) or 999)
	end)

	return slots
end

local function recalculateMultiplier(player)
	local multiplier = 1

	for _, slot in getEquippedSlots(player) do
		if slot:IsA("StringValue") then
			local pet = PetConfig.Pets[slot.Value]
			if pet then
				multiplier += math.max(0, pet.CoinMultiplier - 1)
			end
		end
	end

	player:SetAttribute("PetMultiplier", math.round(multiplier * 100) / 100)
end

local function compactSlots(player)
	local equipped = getEquippedFolder(player)
	if not equipped then
		return
	end

	local petIds = {}
	for _, slot in getEquippedSlots(player) do
		if slot:IsA("StringValue") and PetConfig.Pets[slot.Value] then
			table.insert(petIds, slot.Value)
		end
	end

	for _, child in equipped:GetChildren() do
		child:Destroy()
	end

	for index, petId in ipairs(petIds) do
		if index > PetConfig.MaxEquipped then
			break
		end

		local slot = Instance.new("StringValue")
		slot.Name = tostring(index)
		slot.Value = petId
		slot.Parent = equipped
	end
end

local function validateEquipped(player)
	local equipped = getEquippedFolder(player)
	if not equipped then
		return
	end

	local used = {}
	for _, slot in getEquippedSlots(player) do
		local petId = slot.Value
		used[petId] = (used[petId] or 0) + 1

		if not PetConfig.Pets[petId] or used[petId] > getOwnedCount(player, petId) then
			slot:Destroy()
		end
	end

	compactSlots(player)
	recalculateMultiplier(player)
end

local function addPet(player, petId)
	local inventory = getInventoryFolder(player)
	if not inventory then
		return false
	end

	local value = inventory:FindFirstChild(petId)

	if not value then
		value = Instance.new("IntValue")
		value.Name = petId
		value.Value = 0
		value.Parent = inventory
	end

	value.Value += 1
	return true
end

local function rollPet(egg)
	local roll = random:NextNumber(0, 100)
	local cumulative = 0

	for _, drop in ipairs(egg.Drops) do
		cumulative += drop.Chance
		if roll <= cumulative then
			return drop.PetId
		end
	end

	return egg.Drops[#egg.Drops].PetId
end

local function equipPet(player, petId)
	local equipped = getEquippedFolder(player)
	if not equipped then
		return false, "Pet data not ready"
	end

	local slots = getEquippedSlots(player)
	if #slots >= PetConfig.MaxEquipped then
		return false, "All pet slots are full"
	end

	if getEquippedCount(player, petId) >= getOwnedCount(player, petId) then
		return false, "You do not own another copy of this pet"
	end

	local slot = Instance.new("StringValue")
	slot.Name = tostring(#slots + 1)
	slot.Value = petId
	slot.Parent = equipped

	recalculateMultiplier(player)
	return true
end

local function unequipOne(player, petId)
	for _, slot in getEquippedSlots(player) do
		if slot:IsA("StringValue") and slot.Value == petId then
			slot:Destroy()
			compactSlots(player)
			recalculateMultiplier(player)
			return true
		end
	end

	return false
end

local function autoEquipIfPossible(player, petId)
	local equipped = getEquippedSlots(player)

	if #equipped < PetConfig.MaxEquipped and getEquippedCount(player, petId) < getOwnedCount(player, petId) then
		equipPet(player, petId)
	end
end

hatchEgg.OnServerInvoke = function(player, eggId)
	if not player:GetAttribute("DataLoaded") then
		return { Success = false, Message = "Data is still loading" }
	end

	local egg = PetConfig.Eggs[eggId]
	if not egg then
		return { Success = false, Message = "Unknown egg" }
	end

	if egg.Currency ~= "Coins" then
		return { Success = false, Message = "Unsupported currency" }
	end

	local coins = getCoins(player)
	if not coins then
		return { Success = false, Message = "Coins not ready" }
	end

	if coins.Value < egg.Price then
		return { Success = false, Message = "Not enough Coins" }
	end

	coins.Value -= egg.Price

	local petId = rollPet(egg)
	if not addPet(player, petId) then
		coins.Value += egg.Price
		return { Success = false, Message = "Could not add pet" }
	end

	autoEquipIfPossible(player, petId)
	recalculateMultiplier(player)

	local pet = PetConfig.Pets[petId]

	return {
		Success = true,
		PetId = petId,
		DisplayName = pet.DisplayName,
		Rarity = pet.Rarity,
		Multiplier = pet.CoinMultiplier,
	}
end

toggleEquipPet.OnServerInvoke = function(player, petId)
	if not player:GetAttribute("DataLoaded") then
		return { Success = false, Message = "Data is still loading" }
	end

	if not PetConfig.Pets[petId] or getOwnedCount(player, petId) <= 0 then
		return { Success = false, Message = "You do not own this pet" }
	end

	if getEquippedCount(player, petId) > 0 then
		unequipOne(player, petId)
		return { Success = true, Equipped = false }
	end

	local success, message = equipPet(player, petId)
	return {
		Success = success,
		Equipped = success,
		Message = message,
	}
end

local function setupPlayer(player)
	local initialized = false
	local dataLoadedConnection

	local function ready()
		if initialized or player:GetAttribute("DataLoaded") ~= true then
			return
		end

		initialized = true

		if dataLoadedConnection then
			dataLoadedConnection:Disconnect()
			dataLoadedConnection = nil
		end

		validateEquipped(player)

		local inventory = getInventoryFolder(player)
		local equipped = getEquippedFolder(player)

		if inventory then
			inventory.ChildAdded:Connect(function()
				validateEquipped(player)
			end)
			inventory.ChildRemoved:Connect(function()
				validateEquipped(player)
			end)
		end

		if equipped then
			equipped.ChildAdded:Connect(function()
				recalculateMultiplier(player)
			end)
			equipped.ChildRemoved:Connect(function()
				recalculateMultiplier(player)
			end)
		end

		-- Loaded equipped pets must immediately count toward rewards.
		recalculateMultiplier(player)
	end

	if player:GetAttribute("DataLoaded") == true then
		ready()
	else
		dataLoadedConnection = player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
			if player:GetAttribute("DataLoaded") == true then
				ready()
			end
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
