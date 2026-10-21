--!strict

-- Platzhaltermodul für Task 007. Stellt die in ARCHITECTURE.md Abschnitt 3
-- vorgesehene Bootstrap-Position (BombService vor GameService) sicher, ohne
-- bereits Funktionalität zu implementieren. Task 007 implementiert dieses
-- Modul vollständig aus, ohne die hier definierte Schnittstelle zu brechen.

local BombService = {}

function BombService.Init(): ()
end

function BombService.TryPlaceBomb(_player: Player): nil
	return nil
end

return BombService
