local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local completeTutorial = remotes:FindFirstChild("CompleteTutorial")

if not completeTutorial then
	completeTutorial = Instance.new("RemoteEvent")
	completeTutorial.Name = "CompleteTutorial"
	completeTutorial.Parent = remotes
end

completeTutorial.OnServerEvent:Connect(function(player)
	if player:GetAttribute("DataLoaded") ~= true then
		return
	end

	player:SetAttribute("TutorialSeen", true)
end)
