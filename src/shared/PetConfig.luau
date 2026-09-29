return {
	MaxEquipped = 3,

	Pets = {
		Dog = {
			DisplayName = "Dog",
			Rarity = "Common",
			CoinMultiplier = 1.10,
		},
		Cat = {
			DisplayName = "Cat",
			Rarity = "Common",
			CoinMultiplier = 1.15,
		},
		Bunny = {
			DisplayName = "Bunny",
			Rarity = "Rare",
			CoinMultiplier = 1.25,
		},
		Fox = {
			DisplayName = "Fox",
			Rarity = "Epic",
			CoinMultiplier = 1.50,
		},
		GoldenDog = {
			DisplayName = "Golden Dog",
			Rarity = "Legendary",
			CoinMultiplier = 2.00,
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
