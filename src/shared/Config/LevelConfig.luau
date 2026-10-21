--!strict

-- Level-1..3-Tabelle + GetConfig(level). Siehe ARCHITECTURE.md Abschnitt 5.
-- Kein require(GameTypes) hier (siehe Task 002, "keine zirkulären Abhängigkeiten" -
-- LevelConfig/GameConfig requiren nichts weiter); die Rückgabeform entspricht
-- strukturell GameTypes.LevelConfigData.

local Levels = {
	{
		Level = 1,
		BoardSize = 30,
		TargetLifetime = 20,
		BombFuse = 2,
		ScoreRequired = 1000,
		MinTargetDistance = 3,
		MaxTargetDistance = 5,
		Margin = 1,
	},
	{
		Level = 2,
		BoardSize = 30,
		TargetLifetime = 18,
		BombFuse = 2,
		ScoreRequired = 1500,
		MinTargetDistance = 3,
		MaxTargetDistance = 6,
		Margin = 1,
	},
	{
		Level = 3,
		BoardSize = 30,
		TargetLifetime = 16,
		BombFuse = 2,
		ScoreRequired = 2000,
		MinTargetDistance = 3,
		MaxTargetDistance = 7,
		Margin = 1,
	},
}

local LevelConfig = {
	Levels = Levels,
}

function LevelConfig.GetConfig(level: number)
	if level < 1 then
		error(("LevelConfig.GetConfig: level muss >= 1 sein, erhalten: %d"):format(level))
	end

	local clampedLevel = math.min(level, #Levels)
	return Levels[clampedLevel]
end

return LevelConfig
