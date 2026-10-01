return {
	MinimumPlayers = 1,
	IntermissionTime = 15,
	StartCountdown = 3,
	PostRoundTime = 6,
	HeightUpdateInterval = 0.10,
	RoundStartPart = "RoundSpawn",

	Data = {
		StoreName = "HatchBeforeLava_PlayerData_v1",
		AutosaveInterval = 60,
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

		-- CONFIGURAÇÃO RÁPIDA
		DamageEnabled = true, -- true = mata ao tocar / false = não dá dano
		SpeedMultiplier = 1, -- 0.5 = metade / 1 = normal / 2 = dobro
		CanCollide = true,

		-- Velocidades base das 3 fases
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
