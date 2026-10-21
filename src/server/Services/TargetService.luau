--!strict

-- Erzeugt das namensgebende Kreuz aus vier gleichfarbigen Kugeln, verwaltet
-- dessen Lebenszeit und stellt die Validierung einer Bombenkachel bereit.
-- Siehe ARCHITECTURE.md Abschnitt 7 und tasks/005-target-system.md.
-- Ruft bewusst nicht BombService/GameService auf (reine Datenbereitstellung,
-- Konsequenzen zieht GameService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local GameTypes = require(Shared.Types.GameTypes)
local GridMath = require(Shared.Util.GridMath)

local BoardService = require(script.Parent.BoardService)

type GridPosition = GameTypes.GridPosition
type LevelConfigData = GameTypes.LevelConfigData
type TargetData = GameTypes.TargetData

local TARGET_FOLDER_NAME = "Target"
local MAX_GENERATION_ATTEMPTS = 50

local TargetService = {}

-- Minimale, selbstgebaute Connect/Fire-Tabelle statt eines externen
-- Signal-Pakets (decisions/004-no-external-framework.md), analog zu
-- PlayerService.PlayerFell.
export type TargetExpiredConnection = { Disconnect: (self: TargetExpiredConnection) -> () }
export type TargetExpiredSignal = {
	Connect: (self: TargetExpiredSignal, handler: () -> ()) -> TargetExpiredConnection,
}

local targetExpiredHandlers: { () -> () } = {}

TargetService.TargetExpired = ({
	Connect = function(_self, handler: () -> ())
		table.insert(targetExpiredHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(targetExpiredHandlers, handler)
			if index then
				table.remove(targetExpiredHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: TargetExpiredSignal

local function fireTargetExpired(): ()
	for _, handler in targetExpiredHandlers do
		handler()
	end
end

local nextId = 1
local activeTarget: TargetData? = nil
local activeTimerThread: thread? = nil

local function stopActiveTimer(): ()
	if activeTimerThread then
		task.cancel(activeTimerThread)
		activeTimerThread = nil
	end
end

local function createBall(gridPos: GridPosition, color: Color3, name: string): Part
	local worldPos = BoardService.GridToWorld(gridPos)

	local ball = Instance.new("Part")
	ball.Name = name
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(GameConfig.ObjectDiameter, GameConfig.ObjectDiameter, GameConfig.ObjectDiameter)
	ball.CFrame = CFrame.new(worldPos.X, worldPos.Y + GameConfig.ObjectHeight, worldPos.Z)
	ball.Anchored = true
	ball.CanCollide = false
	ball.Material = Enum.Material.Neon
	ball.Color = color

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 20
	light.Brightness = 3
	light.Parent = ball

	return ball
end

-- Wählt einen gültigen Mittelpunkt + vier Distanzen unter Beachtung von
-- Margin (Spec §15) und Mindestabstand zur Spielerposition (Spec §46,
-- decisions/006-spawn-before-target.md). enforceMinDistance wird nach
-- Erschöpfung der Wiederholversuche fallengelassen (Validität/Rand bleiben
-- zwingend).
type Candidate = {
	center: GridPosition,
	leftDist: number,
	rightDist: number,
	topDist: number,
	bottomDist: number,
}

local function generateCandidate(
	levelConfig: LevelConfigData,
	playerPosition: GridPosition,
	enforceMinDistance: boolean
): Candidate?
	local boardSize = levelConfig.BoardSize
	local margin = levelConfig.Margin
	local minDist = levelConfig.MinTargetDistance
	local maxDist = levelConfig.MaxTargetDistance

	local minX = 1 + margin + maxDist
	local maxX = boardSize - margin - maxDist
	local minY = 1 + margin + maxDist
	local maxY = boardSize - margin - maxDist

	if minX > maxX or minY > maxY then
		return nil
	end

	local center: GridPosition = {
		x = math.random(minX, maxX),
		y = math.random(minY, maxY),
	}

	if enforceMinDistance and GridMath.GridDistance(center, playerPosition) < GameConfig.MinSpawnDistanceFromTarget then
		return nil
	end

	local leftDist = math.random(minDist, maxDist)
	local rightDist = math.random(minDist, maxDist)
	local topDist = math.random(minDist, maxDist)
	local bottomDist = math.random(minDist, maxDist)

	if center.x - leftDist < 1 + margin or center.x + rightDist > boardSize - margin then
		return nil
	end
	if center.y - topDist < 1 + margin or center.y + bottomDist > boardSize - margin then
		return nil
	end

	return {
		center = center,
		leftDist = leftDist,
		rightDist = rightDist,
		topDist = topDist,
		bottomDist = bottomDist,
	}
end

function TargetService.CreateTarget(levelConfig: LevelConfigData, playerPosition: GridPosition): TargetData
	TargetService.DestroyActiveTarget()

	local candidate: Candidate? = nil

	for attempt = 1, MAX_GENERATION_ATTEMPTS do
		local enforceMinDistance = attempt < MAX_GENERATION_ATTEMPTS
		candidate = generateCandidate(levelConfig, playerPosition, enforceMinDistance)
		if candidate then
			break
		end
	end

	if not candidate then
		error("TargetService.CreateTarget: konnte keinen gültigen Mittelpunkt generieren (Margin/Distanz-Konfiguration prüfen)")
	end

	local center = candidate.center
	local left: GridPosition = { x = center.x - candidate.leftDist, y = center.y }
	local right: GridPosition = { x = center.x + candidate.rightDist, y = center.y }
	local top: GridPosition = { x = center.x, y = center.y - candidate.topDist }
	local bottom: GridPosition = { x = center.x, y = center.y + candidate.bottomDist }

	local color = GameConfig.ColorPalette[math.random(1, #GameConfig.ColorPalette)]

	local folder = Instance.new("Folder")
	folder.Name = TARGET_FOLDER_NAME

	local leftBall = createBall(left, color, "Left")
	local rightBall = createBall(right, color, "Right")
	local topBall = createBall(top, color, "Top")
	local bottomBall = createBall(bottom, color, "Bottom")
	leftBall.Parent = folder
	rightBall.Parent = folder
	topBall.Parent = folder
	bottomBall.Parent = folder
	folder.Parent = Workspace

	local id = nextId
	nextId += 1

	local target: TargetData = {
		id = id,
		center = center,
		left = left,
		right = right,
		top = top,
		bottom = bottom,
		color = color,
		spawnedAt = os.clock(),
		lifetime = levelConfig.TargetLifetime,
	}

	activeTarget = target

	activeTimerThread = task.delay(levelConfig.TargetLifetime, function()
		activeTimerThread = nil
		activeTarget = nil

		local existingFolder = Workspace:FindFirstChild(TARGET_FOLDER_NAME)
		if existingFolder then
			existingFolder:Destroy()
		end

		fireTargetExpired()
	end)

	return target
end

function TargetService.GetActiveTarget(): TargetData?
	return activeTarget
end

function TargetService.ValidateBombTile(pos: GridPosition): boolean
	if not activeTarget then
		return false
	end
	return pos.x == activeTarget.center.x and pos.y == activeTarget.center.y
end

function TargetService.DestroyActiveTarget(): ()
	stopActiveTimer()
	activeTarget = nil

	local existingFolder = Workspace:FindFirstChild(TARGET_FOLDER_NAME)
	if existingFolder then
		existingFolder:Destroy()
	end
end

return TargetService
