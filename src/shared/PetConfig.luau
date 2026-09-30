return {
	MaxEquipped = 3,

	Pets = {
		Dog = {
			DisplayName = "Dog",
			Rarity = "Common",
			CoinMultiplier = 1.10,
			Visual = {
				BodyColor = Color3.fromRGB(184, 132, 86),
				AccentColor = Color3.fromRGB(126, 82, 49),
				Scale = 1,
			},
		},
		Cat = {
			DisplayName = "Cat",
			Rarity = "Common",
			CoinMultiplier = 1.15,
			Visual = {
				BodyColor = Color3.fromRGB(150, 157, 170),
				AccentColor = Color3.fromRGB(105, 111, 125),
				Scale = 1,
			},
		},
		Bunny = {
			DisplayName = "Bunny",
			Rarity = "Rare",
			CoinMultiplier = 1.25,
			Visual = {
				BodyColor = Color3.fromRGB(235, 235, 245),
				AccentColor = Color3.fromRGB(255, 155, 190),
				Scale = 1.05,
			},
		},
		Fox = {
			DisplayName = "Fox",
			Rarity = "Epic",
			CoinMultiplier = 1.50,
			Visual = {
				BodyColor = Color3.fromRGB(237, 104, 47),
				AccentColor = Color3.fromRGB(255, 220, 177),
				Scale = 1.1,
			},
		},
		GoldenDog = {
			DisplayName = "Golden Dog",
			Rarity = "Legendary",
			CoinMultiplier = 2.00,
			Visual = {
				BodyColor = Color3.fromRGB(255, 193, 48),
				AccentColor = Color3.fromRGB(255, 235, 115),
				Scale = 1.2,
				Glow = true,
			},
		},
		LavaDragon = {
			DisplayName = "Lava Dragon",
			Rarity = "Special",
			CoinMultiplier = 2.25,
			Visual = {
				BodyColor = Color3.fromRGB(92, 35, 30),
				AccentColor = Color3.fromRGB(255, 92, 35),
				Scale = 1.25,
				Glow = true,
			},
		},
	},

	Eggs = {
		Starter = {
			DisplayName = "Starter Egg",
			Price = 500,
			Currency = "Coins",

			Drops = {
				{ PetId = "Dog", Chance = 45 },
				{ PetId = "Cat", Chance = 30 },
				{ PetId = "Bunny", Chance = 15 },
				{ PetId = "Fox", Chance = 8 },
				{ PetId = "GoldenDog", Chance = 2 },
			},
		},
	},
}
