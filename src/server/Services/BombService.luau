--!strict

-- Platziert die Bombe auf der Spieler-Kachel, zeigt die Gefahrenzone, startet
-- die Fuse und validiert nach deren Ablauf Treffer/Fluchtabstand. Liefert den
-- sofortigen Platzierungserfolg als Rückgabewert, das Explosionsergebnis
-- dagegen per Signal (siehe decisions/009-bomb-outcome-via-signal.md), analog
-- zu TargetService.TargetExpired/PlayerService.PlayerFell. Siehe
-- ARCHITECTURE.md Abschnitt 7 und tasks/007-bomb-and-explosion.md.
-- Requiert bewusst nicht GameService (Inversion of Control).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local GameTypes = require(Shared.Types.GameTypes)

local BoardService = require(script.Parent.BoardService)
local TargetService = require(script.Parent.TargetService)

type GridPosition = GameTypes.GridPosition
type LevelConfigData = GameTypes.LevelConfigData
type BombOutcome = GameTypes.BombOutcome

local BOMB_FOLDER_NAME = "Bomb"

-- Reine Darstellungsdetails (wie BoardService.TILE_THICKNESS), kein
-- Spielparameter im Sinne von Spec/GameConfig.
local BOMB_DIAMETER = 1.5
local DANGER_ZONE_THICKNESS = 0.2
local DANGER_ZONE_Y_OFFSET = 0.15
-- Spec §26: "kurze MISS-Einblendung" ohne konkrete Sekundenangabe.
local MISS_DISPLAY_DELAY = 1

local BombService = {}

-- Minimale, selbstgebaute Connect/Fire-Tabellen statt eines externen
-- Signal-Pakets (decisions/004-no-external-framework.md), ein Satz pro
-- Signal analog TargetService.TargetExpired.
export type BombExplodedConnection = { Disconnect: (self: BombExplodedConnection) -> () }
export type BombExplodedSignal = {
	Connect: (self: BombExplodedSignal, handler: (player: Player) -> ()) -> BombExplodedConnection,
}

export type BombResolvedConnection = { Disconnect: (self: BombResolvedConnection) -> () }
export type BombResolvedSignal = {
	Connect: (self: BombResolvedSignal, handler: (player: Player, outcome: BombOutcome) -> ()) -> BombResolvedConnection,
}

local bombExplodedHandlers: { (player: Player) -> () } = {}
local bombResolvedHandlers: { (player: Player, outcome: BombOutcome) -> () } = {}

BombService.BombExploded = ({
	Connect = function(_self, handler: (player: Player) -> ())
		table.insert(bombExplodedHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(bombExplodedHandlers, handler)
			if index then
				table.remove(bombExplodedHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: BombExplodedSignal

BombService.BombResolved = ({
	Connect = function(_self, handler: (player: Player, outcome: BombOutcome) -> ())
		table.insert(bombResolvedHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(bombResolvedHandlers, handler)
			if index then
				table.remove(bombResolvedHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: BombResolvedSignal

local function fireBombExploded(player: Player): ()
	for _, handler in bombExplodedHandlers do
		handler(player)
	end
end

local function fireBombResolved(player: Player, outcome: BombOutcome): ()
	for _, handler in bombResolvedHandlers do
		handler(player, outcome)
	end
end

-- Spec §18/§50: höchstens eine Bombe pro Spieler pro Target. Schlüssel ist
-- die Target-Id, nicht nur ein Bool, damit ein neues Target automatisch
-- wieder eine Platzierung erlaubt, ohne dass hier etwas zurückgesetzt werden
-- muss.
local bombPlacedForTarget: { [Player]: number } = {}

local function clearBombVisual(): ()
	local existing = Workspace:FindFirstChild(BOMB_FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
end

local function createBombPart(worldPos: Vector3): Part
	local bomb = Instance.new("Part")
	bomb.Name = "BombPart"
	bomb.Shape = Enum.PartType.Ball
	bomb.Size = Vector3.new(BOMB_DIAMETER, BOMB_DIAMETER, BOMB_DIAMETER)
	bomb.CFrame = CFrame.new(worldPos.X, worldPos.Y + BOMB_DIAMETER / 2, worldPos.Z)
	bomb.Anchored = true
	bomb.CanCollide = false
	bomb.Material = Enum.Material.Metal
	bomb.Color = Color3.fromRGB(25, 25, 25)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 70, 20)
	light.Range = 12
	light.Brightness = 2
	light.Parent = bomb

	return bomb
end

-- Flache Scheibe statt Ring, um ohne CSG/MeshPart auszukommen: Cylinder-
-- Part, dessen Höhenachse (lokales X) per 90°-Z-Rotation auf die Welt-Y-
-- Achse gedreht wird, Durchmesser = 2 * radius.
local function createDangerZonePart(worldPos: Vector3, radius: number): Part
	local zone = Instance.new("Part")
	zone.Name = "DangerZone"
	zone.Shape = Enum.PartType.Cylinder
	zone.Size = Vector3.new(DANGER_ZONE_THICKNESS, radius * 2, radius * 2)
	zone.CFrame = CFrame.new(worldPos.X, worldPos.Y + DANGER_ZONE_Y_OFFSET, worldPos.Z) * CFrame.Angles(0, 0, math.rad(90))
	zone.Anchored = true
	zone.CanCollide = false
	zone.Material = Enum.Material.Neon
	zone.Color = Color3.fromRGB(255, 40, 40)
	zone.Transparency = 0.6

	return zone
end

local function spawnBombVisual(worldPos: Vector3): ()
	clearBombVisual()

	local folder = Instance.new("Folder")
	folder.Name = BOMB_FOLDER_NAME

	local bombPart = createBombPart(worldPos)
	bombPart.Parent = folder

	local dangerZone = createDangerZonePart(worldPos, GameConfig.SafeDistanceTiles * GameConfig.TileSize)
	dangerZone.Parent = folder

	folder.Parent = Workspace
end

-- Spec §19 letzter Absatz: kleiner Schritt entgegen der Blickrichtung, rein
-- horizontal, damit der Spieler nicht in den Boden/die Luft versetzt wird.
local function applyRecoil(character: Model): ()
	local pivot = character:GetPivot()
	local lookVector = pivot.LookVector
	local horizontal = Vector3.new(-lookVector.X, 0, -lookVector.Z)

	local recoilDirection = if horizontal.Magnitude > 1e-4 then horizontal.Unit else Vector3.new(0, 0, 1)
	character:PivotTo(pivot + recoilDirection * GameConfig.BombRecoilStuds)
end

-- Explosion-Instanz liefert Lichtblitz/Partikel/Sound ohne eigene Asset-Ids
-- (Spec §23). BlastPressure 0 verhindert, dass der Spieler durch den
-- Explosions-Impuls weggeschleudert wird - die Fluchtdistanz-Prüfung soll
-- rein rechnerisch erfolgen (Technische Vorgabe, s.o.), nicht durch Physik.
local function spawnExplosionEffect(worldPos: Vector3, radius: number): ()
	local explosion = Instance.new("Explosion")
	explosion.Position = worldPos
	explosion.BlastRadius = radius
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = Workspace
end

local function getDistanceToPlayer(player: Player, bombWorldPos: Vector3): number
	local character = player.Character
	local rootPart = character and (character:FindFirstChild("HumanoidRootPart") :: BasePart?)
	if not rootPart then
		-- Kein Charakter mehr (z. B. Spieler verlassen) -> kann nicht "zu nah" sein.
		return math.huge
	end
	return (rootPart.Position - bombWorldPos).Magnitude
end

local function resolveBomb(player: Player, bombTile: GridPosition, bombWorldPos: Vector3): ()
	local safeDistance = GameConfig.SafeDistanceTiles * GameConfig.TileSize

	fireBombExploded(player)
	spawnExplosionEffect(bombWorldPos, safeDistance)
	clearBombVisual()

	local tileCorrect = TargetService.ValidateBombTile(bombTile)
	local distanceOk = getDistanceToPlayer(player, bombWorldPos) >= safeDistance

	local outcome: BombOutcome
	if not tileCorrect then
		outcome = "MISS"
	elseif distanceOk then
		outcome = "SUCCESS"
	else
		outcome = "HIT_BY_EXPLOSION"
	end

	if outcome == "MISS" then
		-- GameService erzeugt bei Task 008 sofort ein neues Target auf BombResolved
		-- hin, also noch bevor dieser verzögerte Aufruf feuert. Ohne Id-Vergleich
		-- würde er dann das längst aktive NEUE Target zerstören statt des
		-- gemissten (siehe decisions/010-miss-destroy-targets-by-id.md).
		local missedTarget = TargetService.GetActiveTarget()
		local missedTargetId = missedTarget and missedTarget.id
		task.delay(MISS_DISPLAY_DELAY, function()
			local current = TargetService.GetActiveTarget()
			if current and current.id == missedTargetId then
				TargetService.DestroyActiveTarget()
			end
		end)
	else
		TargetService.DestroyActiveTarget()
	end

	fireBombResolved(player, outcome)
end

function BombService.TryPlaceBomb(player: Player, levelConfig: LevelConfigData): boolean
	local character = player.Character
	local rootPart = character and (character:FindFirstChild("HumanoidRootPart") :: BasePart?)
	if not character or not rootPart then
		return false
	end

	local activeTarget = TargetService.GetActiveTarget()
	if not activeTarget then
		return false
	end

	if bombPlacedForTarget[player] == activeTarget.id then
		return false
	end

	local bombTile = BoardService.GetTileAtWorldPosition(rootPart.Position)
	if not bombTile then
		return false
	end

	bombPlacedForTarget[player] = activeTarget.id

	local bombWorldPos = BoardService.GridToWorld(bombTile)
	applyRecoil(character)
	spawnBombVisual(bombWorldPos)

	task.delay(levelConfig.BombFuse, function()
		resolveBomb(player, bombTile, bombWorldPos)
	end)

	return true
end

function BombService.Init(): ()
end

return BombService
