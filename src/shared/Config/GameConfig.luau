--!strict

-- Levelunabhängige, globale Spielparameter. Siehe ARCHITECTURE.md Abschnitt 5.
local GameConfig = {
	TileSize = 6,
	TileGap = 0.1,
	ObjectHeight = 3.5,
	ObjectDiameter = 3,
	DeathY = -50,
	StartingLives = 3,
	SafeDistanceTiles = 2,
	MinSpawnDistanceFromTarget = 4,

	Scoring = {
		BasePoints = 100,
		TimeBonusPerSecond = 10,
	},

	BombRecoilStuds = 1.5,

	ColorPalette = {
		Color3.fromRGB(237, 28, 36), -- Rot
		Color3.fromRGB(0, 120, 215), -- Blau
		Color3.fromRGB(34, 177, 76), -- Grün
		Color3.fromRGB(255, 221, 0), -- Gelb
		Color3.fromRGB(255, 127, 0), -- Orange
		Color3.fromRGB(255, 105, 180), -- Pink
		Color3.fromRGB(0, 200, 200), -- Türkis
		Color3.fromRGB(163, 73, 164), -- Lila
	},
}

return GameConfig
