--!strict

-- Zentrale Zustandsmaschine (Spec §34) und einzige Stelle, die
-- PlayerSessionData mutiert. Orchestriert BoardService/PlayerService/
-- TargetService/BombService, reagiert auf ClientAction und broadcastet
-- GameEvent. Siehe ARCHITECTURE.md Abschnitt 7/8, tasks/006-networking-and-
-- state-machine.md und tasks/007-bomb-and-explosion.md.
--
-- Vollständige, geprüfte Score-/Level-/Game-Over-Logik (Task 008) ist hier
-- bewusst nur als rudimentärer Lebens-Dekrement vorhanden, damit der
-- Spiel-Loop nicht einfriert.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local LevelConfig = require(Shared.Config.LevelConfig)
local GameTypes = require(Shared.Types.GameTypes)
local Net = require(Shared.Net.Net)

local BoardService = require(script.Parent.BoardService)
local PlayerService = require(script.Parent.PlayerService)
local TargetService = require(script.Parent.TargetService)
local BombService = require(script.Parent.BombService)

type GridPosition = GameTypes.GridPosition
type GameStateName = GameTypes.GameStateName
type PlayerSessionData = GameTypes.PlayerSessionData
type BombOutcome = GameTypes.BombOutcome

local GameService = {}

local sessions: { [Player]: PlayerSessionData } = {}

-- Board ist pro Session global, nicht pro Spieler (decisions/007-board-size-
-- fixed-per-session.md) - ein boolescher Schalter statt eines Zählers genügt
-- für das Singleplayer-MVP.
local boardCreated = false

local clientActionRemote: RemoteEvent
local gameEventRemote: RemoteEvent

local function fireGameEvent(player: Player, payload: any): ()
	gameEventRemote:FireClient(player, payload)
end

local function setState(player: Player, newState: GameStateName): ()
	local session = sessions[player]
	if not session then
		return
	end

	session.state = newState
	fireGameEvent(player, { type = Net.GameEventType.StateChanged, state = newState })
end

local function getOrCreateSession(player: Player): PlayerSessionData
	local session = sessions[player]
	if not session then
		session = {
			lives = 0,
			score = 0,
			levelScore = 0,
			level = 0,
			state = "MENU",
		}
		sessions[player] = session
	end
	return session
end

local function getPlayerGridPosition(player: Player): GridPosition
	local character = player.Character
	local rootPart = character and (character:FindFirstChild("HumanoidRootPart") :: BasePart?)
	assert(rootPart, "GameService: Spieler hat kein HumanoidRootPart nach PlayerService.SpawnPlayer")
	return BoardService.WorldToGrid(rootPart.Position)
end

local function onRequestPlay(player: Player): ()
	local session = getOrCreateSession(player)

	session.lives = GameConfig.StartingLives
	session.score = 0
	session.levelScore = 0
	session.level = 1
	setState(player, "STARTING")

	local levelConfig = LevelConfig.GetConfig(1)

	if not boardCreated then
		BoardService.CreateBoard(levelConfig)
		boardCreated = true
	end

	PlayerService.SpawnPlayer(player)

	local playerGridPosition = getPlayerGridPosition(player)
	local target = TargetService.CreateTarget(levelConfig, playerGridPosition)
	fireGameEvent(player, { type = Net.GameEventType.TargetSpawned, target = target })

	setState(player, "TARGET_ACTIVE")
end

-- Task 007: delegiert an BombService.TryPlaceBomb, nur solange die Session
-- im Zustand TARGET_ACTIVE ist (Spec §18). BombService garantiert zusätzlich
-- selbst höchstens eine Bombe pro Target, auch bei direkten Aufrufen ohne
-- GameService (z. B. Command-Bar-Tests).
local function onPlaceBomb(player: Player): ()
	local session = sessions[player]
	if not session or session.state ~= "TARGET_ACTIVE" then
		return
	end

	local levelConfig = LevelConfig.GetConfig(session.level)
	local placed = BombService.TryPlaceBomb(player, levelConfig)
	if not placed then
		return
	end

	setState(player, "BOMB_PLACED")
	fireGameEvent(player, { type = Net.GameEventType.BombPlaced })
end

local function onClientAction(player: Player, action: any): ()
	if type(action) ~= "table" then
		return
	end

	if action.type == Net.ClientActionType.RequestPlay then
		onRequestPlay(player)
	elseif action.type == Net.ClientActionType.PlaceBomb then
		onPlaceBomb(player)
	end
end

-- Fuse abgelaufen, Explosion läuft, Ergebnis steht noch nicht fest (Spec
-- §23). Nur ein StateChanged, keine eigene Spielkonsequenz.
local function onBombExploded(player: Player): ()
	local session = sessions[player]
	if session and session.state == "BOMB_PLACED" then
		setState(player, "EXPLODING")
	end
end

-- Validiertes Ergebnis von BombService (Spec §24). Score-/Lebens-
-- Konsequenzen folgen in Task 008 - hier nur der State-Übergang plus
-- Broadcast des Ergebnisses.
local function onBombResolved(player: Player, outcome: BombOutcome): ()
	local session = sessions[player]
	if not session then
		return
	end

	setState(player, "ROUND_RESULT")
	fireGameEvent(player, { type = Net.GameEventType.RoundResult, outcome = outcome })
end

-- Platzhalter-Reaktion (volle Konsequenz-Logik inkl. Game-Over-Prüfung folgt
-- in Task 008): mindestens muss ein neues Target entstehen, damit der Loop
-- nicht einfriert. Reagiert nur für Spieler, deren Session gerade aktiv auf
-- dieses Target wartet.
local function onTargetExpired(): ()
	for player, session in sessions do
		if session.state == "TARGET_ACTIVE" then
			session.lives = math.max(session.lives - 1, 0)
			fireGameEvent(player, { type = Net.GameEventType.TargetCleared })

			local levelConfig = LevelConfig.GetConfig(session.level)
			local playerGridPosition = getPlayerGridPosition(player)
			local target = TargetService.CreateTarget(levelConfig, playerGridPosition)
			fireGameEvent(player, { type = Net.GameEventType.TargetSpawned, target = target })
		end
	end
end

-- Platzhalter-Reaktion analog onTargetExpired. Ändert bewusst weder Zustand
-- noch aktives Target (decisions/008-fall-does-not-reset-target.md) - nur ein
-- rudimentärer Lebens-Dekrement, volle Prüfung folgt in Task 008.
local function onPlayerFell(player: Player): ()
	local session = sessions[player]
	if not session then
		return
	end
	if session.state == "MENU" or session.state == "GAME_OVER" then
		return
	end

	session.lives = math.max(session.lives - 1, 0)
end

local function onPlayerAdded(player: Player): ()
	sessions[player] = {
		lives = 0,
		score = 0,
		levelScore = 0,
		level = 0,
		state = "MENU",
	}
end

local function onPlayerRemoving(player: Player): ()
	sessions[player] = nil
end

local initialized = false

function GameService.Init(): ()
	if initialized then
		return
	end
	initialized = true

	Net.EnsureRemotes()
	clientActionRemote, gameEventRemote = Net.WaitForRemotes()

	clientActionRemote.OnServerEvent:Connect(onClientAction)
	TargetService.TargetExpired:Connect(onTargetExpired)
	PlayerService.PlayerFell:Connect(onPlayerFell)
	BombService.BombExploded:Connect(onBombExploded)
	BombService.BombResolved:Connect(onBombResolved)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return GameService
