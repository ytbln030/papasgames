--!strict

-- Einziger GameEvent-Listener auf Client-Seite. Hält einen lokalen Spiegel
-- von state/aktivem TargetData und verteilt eigene, abgeleitete Signale an
-- andere Client-Module, statt dass diese selbst an GameEvent binden. Siehe
-- ARCHITECTURE.md Abschnitt 7 und tasks/006-networking-and-state-machine.md.
--
-- BombPlaced/RoundResult/ScoreUpdated/GameOver folgen in Task 007/008.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)
local Net = require(Shared.Net.Net)

type GameStateName = GameTypes.GameStateName
type TargetData = GameTypes.TargetData

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

local stateChangedHandlers: { (state: GameStateName) -> () } = {}
local targetSpawnedHandlers: { (target: TargetData) -> () } = {}
local targetClearedHandlers: { () -> () } = {}

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

local localState: { state: GameStateName?, activeTarget: TargetData? } = {
	state = nil,
	activeTarget = nil,
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
	end
end

function GameClientController.GetState(): GameStateName?
	return localState.state
end

function GameClientController.GetActiveTarget(): TargetData?
	return localState.activeTarget
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
