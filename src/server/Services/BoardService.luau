--!strict

-- Erzeugt das begehbare, schwebende Kachelfeld und stellt Grid<->World-
-- Konvertierung sowie Kachel-Lookups bereit. Siehe ARCHITECTURE.md Abschnitt 7
-- und tasks/003-board-system.md. Keine Abhängigkeit von Players/Humanoid.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local GameTypes = require(Shared.Types.GameTypes)
local GridMath = require(Shared.Util.GridMath)

type GridPosition = GameTypes.GridPosition
type LevelConfigData = GameTypes.LevelConfigData

local BOARD_NAME = "Board"

-- Kachel-Höhe ist ein reines Darstellungsdetail (nicht in GameConfig, da kein
-- vom Spec vorgegebener Spielparameter). BOARD_CENTER_Y ist die Y-Ebene, auf
-- der die Kachel-Mittelpunkte (nicht die begehbare Oberfläche) liegen.
local TILE_THICKNESS = 1
local BOARD_CENTER_Y = 0

-- Subtile Grauton-Variation je Kanal, Spec §7 (Beispiel: RGB 120-132).
local GRAY_MIN = 120
local GRAY_MAX = 132

local MAX_RANDOM_TILE_ATTEMPTS = 50

local BoardService = {}

local boardOrigin = Vector3.new(0, BOARD_CENTER_Y + TILE_THICKNESS / 2, 0)
local currentBoardSize = 0

local function randomTileColor(): Color3
	return Color3.fromRGB(
		math.random(GRAY_MIN, GRAY_MAX),
		math.random(GRAY_MIN, GRAY_MAX),
		math.random(GRAY_MIN, GRAY_MAX)
	)
end

local function isExcluded(pos: GridPosition, exclude: { GridPosition }?): boolean
	if not exclude then
		return false
	end

	for _, excludedPos in exclude do
		if excludedPos.x == pos.x and excludedPos.y == pos.y then
			return true
		end
	end

	return false
end

function BoardService.CreateBoard(levelConfig: LevelConfigData): ()
	local existingBoard = Workspace:FindFirstChild(BOARD_NAME)
	if existingBoard then
		existingBoard:Destroy()
	end

	local boardSize = levelConfig.BoardSize
	local tileSize = GameConfig.TileSize
	local tileGap = GameConfig.TileGap

	currentBoardSize = boardSize

	-- Board wird um den Weltursprung zentriert, unabhängig von boardSize.
	boardOrigin = Vector3.new(
		-(boardSize + 1) * tileSize / 2,
		BOARD_CENTER_Y + TILE_THICKNESS / 2,
		-(boardSize + 1) * tileSize / 2
	)

	local folder = Instance.new("Folder")
	folder.Name = BOARD_NAME

	for x = 1, boardSize do
		for y = 1, boardSize do
			local gridPos: GridPosition = { x = x, y = y }
			local tileTop = GridMath.GridToWorld(gridPos, tileSize, boardOrigin)

			local tile = Instance.new("Part")
			tile.Name = string.format("Tile_%d_%d", x, y)
			tile.Anchored = true
			tile.CanCollide = true
			tile.Material = Enum.Material.SmoothPlastic
			tile.TopSurface = Enum.SurfaceType.Smooth
			tile.BottomSurface = Enum.SurfaceType.Smooth
			tile.Size = Vector3.new(tileSize - tileGap, TILE_THICKNESS, tileSize - tileGap)
			tile.CFrame = CFrame.new(tileTop.X, tileTop.Y - TILE_THICKNESS / 2, tileTop.Z)
			tile.Color = randomTileColor()
			tile:SetAttribute("GridX", x)
			tile:SetAttribute("GridY", y)
			tile.Parent = folder
		end
	end

	folder.Parent = Workspace
end

function BoardService.GridToWorld(pos: GridPosition): Vector3
	return GridMath.GridToWorld(pos, GameConfig.TileSize, boardOrigin)
end

function BoardService.WorldToGrid(worldPos: Vector3): GridPosition
	return GridMath.WorldToGrid(worldPos, GameConfig.TileSize, boardOrigin)
end

function BoardService.IsValidTile(pos: GridPosition): boolean
	return GridMath.IsWithinBoard(pos, currentBoardSize)
end

function BoardService.GetRandomTile(exclude: { GridPosition }?): GridPosition
	for _ = 1, MAX_RANDOM_TILE_ATTEMPTS do
		local candidate: GridPosition = {
			x = math.random(1, currentBoardSize),
			y = math.random(1, currentBoardSize),
		}
		if not isExcluded(candidate, exclude) then
			return candidate
		end
	end

	for x = 1, currentBoardSize do
		for y = 1, currentBoardSize do
			local candidate: GridPosition = { x = x, y = y }
			if not isExcluded(candidate, exclude) then
				return candidate
			end
		end
	end

	error("BoardService.GetRandomTile: keine gültige Kachel außerhalb von exclude gefunden")
end

function BoardService.GetTileAtWorldPosition(worldPos: Vector3): GridPosition?
	local pos = BoardService.WorldToGrid(worldPos)
	if BoardService.IsValidTile(pos) then
		return pos
	end
	return nil
end

return BoardService
