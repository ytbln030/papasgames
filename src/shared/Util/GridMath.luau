--!strict

-- Reine Grid<->World-Funktionen, keine Roblox-Instanzen (nur Vector3-Wertetypen).
local GameTypes = require(script.Parent.Parent.Types.GameTypes)

type GridPosition = GameTypes.GridPosition

local GridMath = {}

function GridMath.GridToWorld(pos: GridPosition, tileSize: number, boardOrigin: Vector3): Vector3
	return boardOrigin + Vector3.new(pos.x * tileSize, 0, pos.y * tileSize)
end

function GridMath.WorldToGrid(worldPos: Vector3, tileSize: number, boardOrigin: Vector3): GridPosition
	local relative = worldPos - boardOrigin
	return {
		x = math.round(relative.X / tileSize),
		y = math.round(relative.Z / tileSize),
	}
end

function GridMath.IsWithinBoard(pos: GridPosition, boardSize: number): boolean
	return pos.x >= 1 and pos.x <= boardSize and pos.y >= 1 and pos.y <= boardSize
end

-- Chebyshev-Distanz (max(|dx|, |dy|)) statt euklidisch gewählt, weil sie an der
-- tatsächlichen Grid-Nachbarschaft orientiert ist: auf einem Kachelgitter sind
-- diagonal benachbarte Kacheln genauso "einen Schritt" entfernt wie horizontal/
-- vertikal benachbarte, was der euklidischen Distanz nicht entspricht.
function GridMath.GridDistance(a: GridPosition, b: GridPosition): number
	return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

return GridMath
