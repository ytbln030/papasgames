--!strict

-- Einziger GameEvent-Listener auf Client-Seite. Hält einen lokalen Spiegel
-- von PlayerSessionData (state/score/levelScore/level/lives) + aktuellem
-- TargetData und verteilt eigene, abgeleitete Signale an andere
-- Client-Module, statt dass diese selbst an GameEvent binden. Siehe
-- ARCHITECTURE.md Abschnitt 7 und tasks/006-networking-and-state-machine.md,
-- tasks/010-game-hud.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)
local Net = require(Shared.Net.Net)

type GameStateName = GameTypes.GameStateName
type TargetData = GameTypes.TargetData
type BombOutcome = GameTypes.BombOutcome

export type ScoreUpdatedData = { score: number, levelScore: number, level: number }

local GameClientController = {}

-- Minimale, selbstgebaute Connect/Fire-Tabellen statt eines externen
-- Signal-Pakets (decisions/004-no-external-framework.md), analog zu
-- PlayerService.PlayerFell/TargetService.TargetExpired: ein Satz pro Signal.
export type StateChangedConnection = { Disconnect: (self: StateChangedConnection) -> () }
export type StateChangedSignal = {
	Connect: (self: StateChangedSignal, handler: (state: GameStateName) -> ()) -> StateChangedConnection,
}

export type TargetSpawnedConnection = { Disconnect: (self: TargetSpawnedConnection) -> () }
export type TargetSpawnedSignal = {
	Connect: (self: TargetSpawnedSignal, handler: (target: TargetData) -> ()) -> TargetSpawnedConnection,
}

export type TargetClearedConnection = { Disconnect: (self: TargetClearedConnection) -> () }
export type TargetClearedSignal = {
	Connect: (self: TargetClearedSignal, handler: () -> ()) -> TargetClearedConnection,
}

export type BombPlacedConnection = { Disconnect: (self: BombPlacedConnection) -> () }
export type BombPlacedSignal = {
	Connect: (self: BombPlacedSignal, handler: () -> ()) -> BombPlacedConnection,
}

export type RoundResultConnection = { Disconnect: (self: RoundResultConnection) -> () }
export type RoundResultSignal = {
	Connect: (self: RoundResultSignal, handler: (outcome: BombOutcome) -> ()) -> RoundResultConnection,
}

export type ScoreUpdatedConnection = { Disconnect: (self: ScoreUpdatedConnection) -> () }
export type ScoreUpdatedSignal = {
	Connect: (self: ScoreUpdatedSignal, handler: (data: ScoreUpdatedData) -> ()) -> ScoreUpdatedConnection,
}

export type LivesChangedConnection = { Disconnect: (self: LivesChangedConnection) -> () }
export type LivesChangedSignal = {
	Connect: (self: LivesChangedSignal, handler: (lives: number) -> ()) -> LivesChangedConnection,
}

export type GameOverConnection = { Disconnect: (self: GameOverConnection) -> () }
export type GameOverSignal = {
	Connect: (self: GameOverSignal, handler: (score: number) -> ()) -> GameOverConnection,
}

local stateChangedHandlers: { (state: GameStateName) -> () } = {}
local targetSpawnedHandlers: { (target: TargetData) -> () } = {}
local targetClearedHandlers: { () -> () } = {}
local bombPlacedHandlers: { () -> () } = {}
local roundResultHandlers: { (outcome: BombOutcome) -> () } = {}
local scoreUpdatedHandlers: { (data: ScoreUpdatedData) -> () } = {}
local livesChangedHandlers: { (lives: number) -> () } = {}
local gameOverHandlers: { (score: number) -> () } = {}

GameClientController.StateChanged = ({
	Connect = function(_self, handler: (state: GameStateName) -> ())
		table.insert(stateChangedHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(stateChangedHandlers, handler)
			if index then
				table.remove(stateChangedHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: StateChangedSignal

GameClientController.TargetSpawned = ({
	Connect = function(_self, handler: (target: TargetData) -> ())
		table.insert(targetSpawnedHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(targetSpawnedHandlers, handler)
			if index then
				table.remove(targetSpawnedHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: TargetSpawnedSignal

GameClientController.TargetCleared = ({
	Connect = function(_self, handler: () -> ())
		table.insert(targetClearedHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(targetClearedHandlers, handler)
			if index then
				table.remove(targetClearedHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: TargetClearedSignal

GameClientController.BombPlaced = ({
	Connect = function(_self, handler: () -> ())
		table.insert(bombPlacedHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(bombPlacedHandlers, handler)
			if index then
				table.remove(bombPlacedHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: BombPlacedSignal

GameClientController.RoundResult = ({
	Connect = function(_self, handler: (outcome: BombOutcome) -> ())
		table.insert(roundResultHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(roundResultHandlers, handler)
			if index then
				table.remove(roundResultHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: RoundResultSignal

GameClientController.ScoreUpdated = ({
	Connect = function(_self, handler: (data: ScoreUpdatedData) -> ())
		table.insert(scoreUpdatedHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(scoreUpdatedHandlers, handler)
			if index then
				table.remove(scoreUpdatedHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: ScoreUpdatedSignal

GameClientController.LivesChanged = ({
	Connect = function(_self, handler: (lives: number) -> ())
		table.insert(livesChangedHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(livesChangedHandlers, handler)
			if index then
				table.remove(livesChangedHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: LivesChangedSignal

GameClientController.GameOver = ({
	Connect = function(_self, handler: (score: number) -> ())
		table.insert(gameOverHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(gameOverHandlers, handler)
			if index then
				table.remove(gameOverHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: GameOverSignal

local function fireStateChanged(state: GameStateName): ()
	for _, handler in stateChangedHandlers do
		handler(state)
	end
end

local function fireTargetSpawned(target: TargetData): ()
	for _, handler in targetSpawnedHandlers do
		handler(target)
	end
end

local function fireTargetCleared(): ()
	for _, handler in targetClearedHandlers do
		handler()
	end
end

local function fireBombPlaced(): ()
	for _, handler in bombPlacedHandlers do
		handler()
	end
end

local function fireRoundResult(outcome: BombOutcome): ()
	for _, handler in roundResultHandlers do
		handler(outcome)
	end
end

local function fireScoreUpdated(data: ScoreUpdatedData): ()
	for _, handler in scoreUpdatedHandlers do
		handler(data)
	end
end

local function fireLivesChanged(lives: number): ()
	for _, handler in livesChangedHandlers do
		handler(lives)
	end
end

local function fireGameOver(score: number): ()
	for _, handler in gameOverHandlers do
		handler(score)
	end
end

local localState: {
	state: GameStateName?,
	activeTarget: TargetData?,
	score: number,
	levelScore: number,
	level: number,
	lives: number,
} = {
	state = nil,
	activeTarget = nil,
	score = 0,
	levelScore = 0,
	level = 0,
	lives = 0,
}

local clientActionRemote: RemoteEvent
local gameEventRemote: RemoteEvent
local initialized = false

local function onGameEvent(payload: any): ()
	if type(payload) ~= "table" then
		return
	end

	if payload.type == Net.GameEventType.StateChanged then
		localState.state = payload.state
		fireStateChanged(payload.state)
	elseif payload.type == Net.GameEventType.TargetSpawned then
		localState.activeTarget = payload.target
		fireTargetSpawned(payload.target)
	elseif payload.type == Net.GameEventType.TargetCleared then
		localState.activeTarget = nil
		fireTargetCleared()
	elseif payload.type == Net.GameEventType.BombPlaced then
		fireBombPlaced()
	elseif payload.type == Net.GameEventType.RoundResult then
		fireRoundResult(payload.outcome)
	elseif payload.type == Net.GameEventType.ScoreUpdated then
		localState.score = payload.score
		localState.levelScore = payload.levelScore
		localState.level = payload.level
		fireScoreUpdated({ score = payload.score, levelScore = payload.levelScore, level = payload.level })
	elseif payload.type == Net.GameEventType.LivesChanged then
		localState.lives = payload.lives
		fireLivesChanged(payload.lives)
	elseif payload.type == Net.GameEventType.GameOver then
		fireGameOver(payload.score)
	end
end

function GameClientController.GetState(): GameStateName?
	return localState.state
end

function GameClientController.GetActiveTarget(): TargetData?
	return localState.activeTarget
end

function GameClientController.GetScore(): number
	return localState.score
end

function GameClientController.GetLevel(): number
	return localState.level
end

function GameClientController.GetLives(): number
	return localState.lives
end

function GameClientController.RequestPlay(): ()
	clientActionRemote:FireServer({ type = Net.ClientActionType.RequestPlay })
end

function GameClientController.Init(): ()
	if initialized then
		return
	end
	initialized = true

	clientActionRemote, gameEventRemote = Net.WaitForRemotes()
	gameEventRemote.OnClientEvent:Connect(onGameEvent)
end

return GameClientController
