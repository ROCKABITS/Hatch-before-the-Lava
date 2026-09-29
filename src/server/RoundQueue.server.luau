local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local toggleQueue = remotes:FindFirstChild("ToggleRoundQueue")
if not toggleQueue then
	toggleQueue = Instance.new("RemoteFunction")
	toggleQueue.Name = "ToggleRoundQueue"
	toggleQueue.Parent = remotes
end

local function setupPlayer(player)
	if player:GetAttribute("WantToPlay") == nil then
		player:SetAttribute("WantToPlay", false)
	end

	player:GetAttributeChangedSignal("IsAFK"):Connect(function()
		if player:GetAttribute("IsAFK") then
			player:SetAttribute("WantToPlay", false)
		end
	end)
end

toggleQueue.OnServerInvoke = function(player)
	if not player:GetAttribute("DataLoaded") then
		return {
			Success = false,
			Message = "Os teus dados ainda estão a carregar.",
		}
	end

	if player:GetAttribute("InRound") then
		return {
			Success = false,
			Message = "Já estás numa ronda.",
		}
	end

	if player:GetAttribute("IsAFK") then
		return {
			Success = false,
			Message = "Sai da AFK Zone para jogar.",
		}
	end

	local newValue = not (player:GetAttribute("WantToPlay") == true)
	player:SetAttribute("WantToPlay", newValue)

	return {
		Success = true,
		Queued = newValue,
	}
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
