local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DailyQuestConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DailyQuestConfig")
)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local dailyQuests = remotes:FindFirstChild("DailyQuests")

if not dailyQuests then
	dailyQuests = Instance.new("RemoteFunction")
	dailyQuests.Name = "DailyQuests"
	dailyQuests.Parent = remotes
end

local questProgressEvent = script.Parent:FindFirstChild("QuestProgress")

if not questProgressEvent then
	questProgressEvent = Instance.new("BindableEvent")
	questProgressEvent.Name = "QuestProgress"
	questProgressEvent.Parent = script.Parent
end

local trackedPlayers = {}

local function getUtcDay()
	return math.floor(os.time() / 86400)
end

local function getQuestFolder(player)
	local folder = player:FindFirstChild("DailyQuests")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "DailyQuests"
		folder.Parent = player
	end

	return folder
end

local function createQuestState(parent, questId)
	local questFolder = parent:FindFirstChild(questId)

	if not questFolder then
		questFolder = Instance.new("Folder")
		questFolder.Name = questId
		questFolder.Parent = parent
	end

	local progress = questFolder:FindFirstChild("Progress")

	if not progress then
		progress = Instance.new("IntValue")
		progress.Name = "Progress"
		progress.Value = 0
		progress.Parent = questFolder
	end

	local claimed = questFolder:FindFirstChild("Claimed")

	if not claimed then
		claimed = Instance.new("BoolValue")
		claimed.Name = "Claimed"
		claimed.Value = false
		claimed.Parent = questFolder
	end

	return questFolder, progress, claimed
end

local function ensureDailyQuests(player)
	local today = getUtcDay()
	local folder = getQuestFolder(player)
	local activeIds = DailyQuestConfig.GetActiveQuestIds(today)
	local activeLookup = {}

	for _, questId in activeIds do
		activeLookup[questId] = true
	end

	if player:GetAttribute("DailyQuestDay") ~= today then
		for _, child in folder:GetChildren() do
			child:Destroy()
		end

		player:SetAttribute("DailyQuestDay", today)
	end

	for _, child in folder:GetChildren() do
		if child:IsA("Folder") and not activeLookup[child.Name] then
			child:Destroy()
		end
	end

	for _, questId in activeIds do
		createQuestState(folder, questId)
	end

	return activeIds
end

local function getQuestState(player, questId)
	local folder = getQuestFolder(player)
	local questFolder = folder:FindFirstChild(questId)

	if not questFolder then
		return nil
	end

	local progress = questFolder:FindFirstChild("Progress")
	local claimed = questFolder:FindFirstChild("Claimed")

	if not progress or not claimed then
		return nil
	end

	return questFolder, progress, claimed
end

local function addProgress(player, progressType, amount)
	if player:GetAttribute("DataLoaded") ~= true then
		return
	end

	amount = tonumber(amount) or 0

	if amount <= 0 then
		return
	end

	local activeIds = ensureDailyQuests(player)

	for _, questId in activeIds do
		local quest = DailyQuestConfig.GetQuest(questId)

		if quest and quest.Type == progressType then
			local _, progress, claimed = getQuestState(player, questId)

			if progress and claimed and not claimed.Value then
				if progressType == "Height" then
					progress.Value = math.min(
						quest.Target,
						math.max(progress.Value, math.floor(amount))
					)
				else
					progress.Value = math.min(
						quest.Target,
						progress.Value + math.floor(amount)
					)
				end
			end
		end
	end
end

local function grantReward(player, reward)
	if reward.Type == "Coins" then
		local leaderstats = player:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:FindFirstChild("Coins")

		if not coins then
			return false, "Coins are not ready"
		end

		coins.Value += reward.Amount
		return true
	elseif reward.Type == "LuckBoost" then
		player:SetAttribute(
			"LuckBoosts",
			(player:GetAttribute("LuckBoosts") or 0) + reward.Amount
		)
		return true
	elseif reward.Type == "CoinBoost" then
		player:SetAttribute(
			"CoinBoosts",
			(player:GetAttribute("CoinBoosts") or 0) + reward.Amount
		)
		return true
	elseif reward.Type == "PetXPBoost" then
		player:SetAttribute(
			"PetXPBoosts",
			(player:GetAttribute("PetXPBoosts") or 0) + reward.Amount
		)
		return true
	elseif reward.Type == "PetXPPotion" then
		player:SetAttribute(
			"PetXPPotions",
			(player:GetAttribute("PetXPPotions") or 0) + reward.Amount
		)
		return true
	end

	return false, "Unsupported quest reward"
end

local function makeStatus(player)
	local activeIds = ensureDailyQuests(player)
	local quests = {}

	for _, questId in activeIds do
		local quest = DailyQuestConfig.GetQuest(questId)
		local _, progress, claimed = getQuestState(player, questId)

		if quest and progress and claimed then
			table.insert(quests, {
				Id = quest.Id,
				Title = quest.Title,
				Target = quest.Target,
				Progress = progress.Value,
				Claimed = claimed.Value,
				Complete = progress.Value >= quest.Target,
				Reward = quest.Reward.Display,
			})
		end
	end

	return {
		Success = true,
		Day = getUtcDay(),
		Quests = quests,
	}
end

questProgressEvent.Event:Connect(function(player, progressType, amount)
	if not player or player.Parent ~= Players then
		return
	end

	addProgress(player, progressType, amount)
end)

local function connectTracking(player)
	if trackedPlayers[player] then
		ensureDailyQuests(player)
		return
	end

	trackedPlayers[player] = true
	ensureDailyQuests(player)

	player:GetAttributeChangedSignal("RoundHeight"):Connect(function()
		if player:GetAttribute("DataLoaded") == true then
			addProgress(player, "Height", player:GetAttribute("RoundHeight") or 0)
		end
	end)

	player:GetAttributeChangedSignal("RoundResult"):Connect(function()
		if player:GetAttribute("DataLoaded") ~= true then
			return
		end

		local result = player:GetAttribute("RoundResult")

		if result == "Dead" or result == "Escaped" then
			addProgress(player, "Rounds", 1)

			if result == "Escaped" then
				addProgress(player, "Wins", 1)
			end
		end
	end)
end

local function setupPlayer(player)
	if player:GetAttribute("DataLoaded") == true then
		connectTracking(player)
	end

	player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
		if player:GetAttribute("DataLoaded") == true then
			connectTracking(player)
		end
	end)
end

dailyQuests.OnServerInvoke = function(player, action, questId)
	if player:GetAttribute("DataLoaded") ~= true then
		return {
			Success = false,
			Message = "Data is still loading",
		}
	end

	if action == "Status" then
		return makeStatus(player)
	end

	if action ~= "Claim" then
		return {
			Success = false,
			Message = "Unknown action",
		}
	end

	ensureDailyQuests(player)

	local quest = DailyQuestConfig.GetQuest(questId)
	local _, progress, claimed = getQuestState(player, questId)

	if not quest or not progress or not claimed then
		return {
			Success = false,
			Message = "Quest is not active today",
		}
	end

	if claimed.Value then
		return {
			Success = false,
			Message = "Reward already claimed",
		}
	end

	if progress.Value < quest.Target then
		return {
			Success = false,
			Message = "Quest is not complete",
		}
	end

	local success, message = grantReward(player, quest.Reward)

	if not success then
		return {
			Success = false,
			Message = message or "Could not grant quest reward",
		}
	end

	claimed.Value = true

	local response = makeStatus(player)
	response.Claimed = true
	response.Reward = quest.Reward.Display

	return response
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	trackedPlayers[player] = nil
end)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
