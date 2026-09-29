return {
	MinimumPlayers = 1,
	IntermissionTime = 15,
	StartCountdown = 3,
	PostRoundTime = 3,
	HeightUpdateInterval = 0.10,

	Rounds = {
		AutoRequeue = false,
	},

	Data = {
		StoreName = "HatchBeforeLava_PlayerData_v1",
		AutosaveInterval = 60,
	},

	Spawns = {
		Lobby = "LobbySpawn",
		Round = "RoundSpawn",
		OffsetY = 3,
	},

	AFK = {
		Enabled = true,
		BaseCoinsPerMinute = 100,
		Efficiency = 0.25,
		TickInterval = 5,
		RequireEquippedPet = true,
	},

	Lava = {
		StartHeight = 1,
		MaxHeight = 255,

		-- Test settings
		CanCollide = true,
		KillOnTouch = false,

		SlowSpeed = 1.5,
		NormalSpeed = 2.5,
		FastSpeed = 4,

		SlowUntil = 0.30,
		NormalUntil = 0.75,
	},

	Checkpoints = {
		BaseCoins = 50,
		CoinsPerCheckpoint = 25,
	},

	Rewards = {
		CoinsPerMeter = 3,
		WinCoins = 2500,
		WinsPerEscape = 1,
	},
}
