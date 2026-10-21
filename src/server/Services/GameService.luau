--!strict

-- Zentrale Zustandsmaschine (Spec §34) und einzige Stelle, die
-- PlayerSessionData mutiert. Orchestriert BoardService/PlayerService/
-- TargetService/BombService, reagiert auf ClientAction und broadcastet
-- GameEvent. Siehe ARCHITECTURE.md Abschnitt 7/8, tasks/006-networking-and-
-- state-machine.md, tasks/007-bomb-and-explosion.md und tasks/008-scoring-
-- and-level-progression.md (vollständige Score-/Level-/Game-Over-Logik).

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

-- Interner Diskriminator für HandleFailure, bewusst kein GameTypes.BombOutcome
-- (Timeout/Sturz sind keine Bomben-Ergebnisse) und bewusst kein neuer Typ in
-- GameTypes.luau (Task 008 betrifft laut Scope nur GameService.luau).
type FailureReason = "TIMEOUT" | "MISS" | "HIT_BY_EXPLOSION" | "FALL"

local GameService = {}

-- Spec §25: ca. 0,5-1s Verzögerung nach Erfolg, bevor automatisch das
-- nächste Target entsteht.
local SUCCESS_NEXT_TARGET_DELAY = 0.75

local sessions: { [Player]: PlayerSessionData } = {}

-- Board ist pro Session global, nicht pro Spieler (decisions/007-board-size-
-- fixed-per-session.md) - ein boolescher Schalter statt eines Zählers genügt
-- für das Singleplayer-MVP.
local boardCreated = false

-- Restzeit des Target-Timers zum Platzierungszeitpunkt der Bombe (Spec §28)
-- muss zwischengespeichert werden, weil BombService.BombResolved erst nach
-- Ablauf der Fuse feuert - zu diesem Zeitpunkt ist die "Restzeit beim
-- Platzieren" nicht mehr aus dem Target selbst rekonstruierbar.
local pendingRemainingTime: { [Player]: number } = {}

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

-- Gemeinsamer Pfad für den automatischen Zustandswechsel NEXT_TARGET →
-- TARGET_ACTIVE (Spec §17/§25/§26) - verwendet sowohl nach Erfolg (mit
-- Verzögerung) als auch nach jedem Fehlversuch ohne Game Over (sofort).
-- Prüft bei verzögerter Ausführung erneut auf GAME_OVER/MENU, damit ein in
-- der Zwischenzeit erfolgter Game-Over- oder RequestPlay-Übergang nicht
-- durch ein verspätetes Target überschrieben wird.
local function spawnNextTarget(player: Player, delaySeconds: number): ()
	local function doSpawn(): ()
		local session = sessions[player]
		if not session or session.state == "GAME_OVER" or session.state == "MENU" then
			return
		end

		setState(player, "NEXT_TARGET")

		local levelConfig = LevelConfig.GetConfig(session.level)
		local playerGridPosition = getPlayerGridPosition(player)
		local target = TargetService.CreateTarget(levelConfig, playerGridPosition)
		fireGameEvent(player, { type = Net.GameEventType.TargetSpawned, target = target })

		setState(player, "TARGET_ACTIVE")
	end

	if delaySeconds > 0 then
		task.delay(delaySeconds, doSpawn)
	else
		doSpawn()
	end
end

-- Spec §28/§30: Punkte- und Zeitbonus-Berechnung plus Level-Aufstieg.
-- score bleibt beim Aufstieg unverändert (§30), nur levelScore wird
-- zurückgesetzt.
local function applySuccessScore(player: Player, remainingTimeSeconds: number): ()
	local session = sessions[player]
	if not session then
		return
	end

	local gained = GameConfig.Scoring.BasePoints + math.floor(remainingTimeSeconds * GameConfig.Scoring.TimeBonusPerSecond)
	session.score += gained
	session.levelScore += gained

	print(("GameService: %s SUCCESS, Restzeit=%.2fs, +%d Punkte -> score=%d levelScore=%d"):format(
		player.Name, remainingTimeSeconds, gained, session.score, session.levelScore))

	local currentLevelConfig = LevelConfig.GetConfig(session.level)
	if session.levelScore >= currentLevelConfig.ScoreRequired then
		session.level += 1
		session.levelScore = 0
		print(("GameService: %s Level-Aufstieg -> Level %d (nächstes Target TargetLifetime=%ds)"):format(
			player.Name, session.level, LevelConfig.GetConfig(session.level).TargetLifetime))
	end

	fireGameEvent(player, {
		type = Net.GameEventType.ScoreUpdated,
		score = session.score,
		levelScore = session.levelScore,
		level = session.level,
	})
end

-- Einziger Pfad "Fehlversuch verarbeiten" (Spec §17/§24/§26, Task 008
-- Technische Vorgabe) für alle vier Fehlerquellen. Zieht genau 1 Leben ab,
-- nie kumuliert, und entscheidet zwischen Game Over und neuem Target.
-- Sturz (decisions/008-fall-does-not-reset-target.md) ist die Ausnahme:
-- außer beim finalen Game-Over-Übergang bleiben Zustand und aktives Target
-- unverändert.
local function handleFailure(player: Player, reason: FailureReason): ()
	local session = sessions[player]
	if not session then
		return
	end

	local livesBefore = session.lives
	session.lives = math.max(session.lives - 1, 0)
	print(("GameService: %s Fehlversuch (%s), lives: %d -> %d"):format(player.Name, reason, livesBefore, session.lives))

	-- Deckt auch den stillen Sturz-Fall ab (reason == "FALL" ohne Game Over
	-- feuert sonst gar kein GameEvent), siehe decisions/011.
	fireGameEvent(player, { type = Net.GameEventType.LivesChanged, lives = session.lives })

	if session.lives <= 0 then
		setState(player, "GAME_OVER")
		fireGameEvent(player, { type = Net.GameEventType.GameOver, score = session.score })
		print(("GameService: %s GAME_OVER, score=%d"):format(player.Name, session.score))
		return
	end

	if reason == "FALL" then
		return
	end

	spawnNextTarget(player, 0)
end

local function onRequestPlay(player: Player): ()
	local session = getOrCreateSession(player)

	session.lives = GameConfig.StartingLives
	session.score = 0
	session.levelScore = 0
	session.level = 1
	fireGameEvent(player, { type = Net.GameEventType.LivesChanged, lives = session.lives })
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

	-- Restzeit zum Platzierungszeitpunkt sichern (Spec §28 - die Fuse-Zeit
	-- zählt nicht als Restzeit, siehe tasks/008 Funktionale Anforderung 1).
	local activeTarget = TargetService.GetActiveTarget()
	if activeTarget then
		local elapsed = os.clock() - activeTarget.spawnedAt
		pendingRemainingTime[player] = math.max(activeTarget.lifetime - elapsed, 0)
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

-- Validiertes Ergebnis von BombService (Spec §24): bei SUCCESS Punkte-/
-- Levellogik, bei MISS/HIT_BY_EXPLOSION der gemeinsame Fehlversuch-Pfad.
local function onBombResolved(player: Player, outcome: BombOutcome): ()
	local session = sessions[player]
	if not session then
		return
	end

	setState(player, "ROUND_RESULT")
	fireGameEvent(player, { type = Net.GameEventType.RoundResult, outcome = outcome })

	local remainingTime = pendingRemainingTime[player] or 0
	pendingRemainingTime[player] = nil

	if outcome == "SUCCESS" then
		applySuccessScore(player, remainingTime)
		spawnNextTarget(player, SUCCESS_NEXT_TARGET_DELAY)
	elseif outcome == "MISS" then
		handleFailure(player, "MISS")
	else
		handleFailure(player, "HIT_BY_EXPLOSION")
	end
end

-- Abgelaufenes Target ohne platzierte Bombe zählt als Fehlversuch (Spec
-- §17). Reagiert nur für Spieler, deren Session gerade aktiv auf dieses
-- Target wartet.
local function onTargetExpired(): ()
	for player, session in sessions do
		if session.state == "TARGET_ACTIVE" then
			setState(player, "ROUND_RESULT")
			fireGameEvent(player, { type = Net.GameEventType.TargetCleared })
			handleFailure(player, "TIMEOUT")
		end
	end
end

-- Sturz (decisions/008-fall-does-not-reset-target.md): Lebensverlust über
-- den gemeinsamen Fehlversuch-Pfad, aber ohne Zustands-/Targetwechsel außer
-- beim finalen Übergang nach GAME_OVER.
local function onPlayerFell(player: Player): ()
	local session = sessions[player]
	if not session then
		return
	end
	if session.state == "MENU" or session.state == "GAME_OVER" then
		return
	end

	handleFailure(player, "FALL")
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
	pendingRemainingTime[player] = nil
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
