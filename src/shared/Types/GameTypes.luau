--!strict

export type GridPosition = { x: number, y: number }

export type GameStateName =
	"MENU" | "STARTING" | "TARGET_ACTIVE" | "BOMB_PLACED"
	| "EXPLODING" | "ROUND_RESULT" | "NEXT_TARGET" | "GAME_OVER"

export type TargetData = {
	id: number,
	center: GridPosition,
	left: GridPosition,
	right: GridPosition,
	top: GridPosition,
	bottom: GridPosition,
	color: Color3,
	spawnedAt: number,
	lifetime: number,
}

export type BombOutcome = "SUCCESS" | "MISS" | "HIT_BY_EXPLOSION"

export type PlayerSessionData = {
	lives: number,
	score: number,
	levelScore: number,
	level: number,
	state: GameStateName,
}

export type LevelConfigData = {
	Level: number,
	BoardSize: number,
	TargetLifetime: number,
	BombFuse: number,
	ScoreRequired: number,
	MinTargetDistance: number,
	MaxTargetDistance: number,
	Margin: number,
}

return {}
