local DailyQuestConfig = {}

DailyQuestConfig.QuestCount = 3

DailyQuestConfig.Pool = {
	{
		Id = "Reach500",
		Type = "Height",
		Title = "Reach 500m",
		Target = 500,
		Reward = {
			Type = "Coins",
			Amount = 1000,
			Display = "1,000 Coins",
		},
	},
	{
		Id = "Complete3Rounds",
		Type = "Rounds",
		Title = "Complete 3 rounds",
		Target = 3,
		Reward = {
			Type = "Coins",
			Amount = 750,
			Display = "750 Coins",
		},
	},
	{
		Id = "Open5Eggs",
		Type = "Eggs",
		Title = "Open 5 Eggs",
		Target = 5,
		Reward = {
			Type = "LuckBoost",
			Amount = 1,
			Display = "1 Luck Boost",
		},
	},
	{
		Id = "Collect50Coins",
		Type = "Coins",
		Title = "Collect 50 Coins",
		Target = 50,
		Reward = {
			Type = "Coins",
			Amount = 500,
			Display = "500 Coins",
		},
	},
	{
		Id = "Win2Rounds",
		Type = "Wins",
		Title = "Win 2 rounds",
		Target = 2,
		Reward = {
			Type = "PetXPPotion",
			Amount = 1,
			Display = "1 Pet XP Potion",
		},
	},
}

local byId = {}

for _, quest in DailyQuestConfig.Pool do
	byId[quest.Id] = quest
end

function DailyQuestConfig.GetQuest(questId)
	return byId[questId]
end

function DailyQuestConfig.GetActiveQuestIds(utcDay)
	local count = #DailyQuestConfig.Pool
	local startIndex = (utcDay % count) + 1
	local offsets = {0, 2, 4}
	local ids = {}

	for index = 1, math.min(DailyQuestConfig.QuestCount, #offsets) do
		local poolIndex = ((startIndex - 1 + offsets[index]) % count) + 1
		table.insert(ids, DailyQuestConfig.Pool[poolIndex].Id)
	end

	return ids
end

return DailyQuestConfig
