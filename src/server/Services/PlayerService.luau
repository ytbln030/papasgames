--!strict

-- Platziert Spieler bei Charakter-Erzeugung sowie nach einem Sturz sicher auf
-- einer zufälligen Board-Kachel und meldet Stürze über das Signal PlayerFell
-- nach oben, ohne selbst Leben/Score zu verwalten. Siehe ARCHITECTURE.md
-- Abschnitt 7 und tasks/004-player-spawn-and-safety.md.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BoardService = require(script.Parent.BoardService)

local PlayerService = {}

-- Minimale, selbstgebaute Connect/Fire-Tabelle statt eines externen
-- Signal-Pakets (decisions/004-no-external-framework.md). Fire bleibt bewusst
-- modul-intern (siehe firePlayerFell unten), damit nur PlayerService selbst
-- das Event auslösen kann.
export type PlayerFellConnection = { Disconnect: (self: PlayerFellConnection) -> () }
export type PlayerFellSignal = {
	Connect: (self: PlayerFellSignal, handler: (player: Player) -> ()) -> PlayerFellConnection,
}

local playerFellHandlers: { (player: Player) -> () } = {}

PlayerService.PlayerFell = ({
	Connect = function(_self, handler: (player: Player) -> ())
		table.insert(playerFellHandlers, handler)
		local connection = {}
		function connection.Disconnect()
			local index = table.find(playerFellHandlers, handler)
			if index then
				table.remove(playerFellHandlers, index)
			end
		end
		return connection
	end,
} :: any) :: PlayerFellSignal

local function firePlayerFell(player: Player): ()
	for _, handler in playerFellHandlers do
		handler(player)
	end
end

-- Sperrt PlayerFell für einen Spieler, solange sein Charakter die DeathZone
-- seit dem letzten Sturz noch nicht wieder verlassen hat (Debounce, siehe
-- Funktionale Anforderung 4).
local fallLocked: { [Player]: boolean } = {}

local function placeCharacterOnRandomTile(character: Model): ()
	local rootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local humanoid = (character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)) :: Humanoid?
	if not rootPart or not humanoid then
		warn(string.format("PlayerService: Charakter %s hat kein HumanoidRootPart/Humanoid, Spawn abgebrochen", character.Name))
		return
	end

	local tile = BoardService.GetRandomTile()
	local tileTop = BoardService.GridToWorld(tile)

	-- Abstand Fußsohle -> HumanoidRootPart-Mittelpunkt, damit der Charakter mit
	-- den Füßen auf der Kachel-Oberfläche steht statt mit dem RootPart-Zentrum.
	local groundOffset = humanoid.HipHeight + rootPart.Size.Y / 2
	character:PivotTo(CFrame.new(tileTop + Vector3.new(0, groundOffset, 0)))
end

function PlayerService.SpawnPlayer(player: Player): ()
	local character = player.Character or player.CharacterAdded:Wait()
	placeCharacterOnRandomTile(character)
end

function PlayerService.RespawnPlayer(player: Player): ()
	local character = player.Character
	if not character then
		return
	end
	placeCharacterOnRandomTile(character)
end

-- Nur das HumanoidRootPart löst die Reaktion aus, nicht jedes der ca. 14
-- R15-Körperteile. Grund: DeathZone.Touched/TouchEnded feuert unabhängig pro
-- BasePart, und beim Sturz überlappen mehrere Körperteile zeitlich versetzt
-- über mehrere Physik-Schritte hinweg (beobachtet und verifiziert während der
-- manuellen Prüfung dieses Tasks) - ein TouchEnded eines bereits wieder
-- verlassenen Teils kann dadurch den Debounce freigeben, während ein anderes
-- Teil desselben Sturzes noch gar nicht als berührend registriert wurde, was
-- PlayerFell mehrfach pro Sturz auslösen würde. Das HumanoidRootPart ist die
-- kanonische Positionsreferenz des Charakters und liefert einen einzelnen,
-- verlässlichen Kontakt pro Sturz.
local function isCharacterRootPart(otherPart: BasePart, character: Instance): boolean
	return otherPart == character:FindFirstChild("HumanoidRootPart")
end

local function onDeathZoneTouched(otherPart: BasePart): ()
	local character = otherPart.Parent
	if not character or not isCharacterRootPart(otherPart, character) then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	if fallLocked[player] then
		return
	end
	fallLocked[player] = true

	firePlayerFell(player)
	PlayerService.RespawnPlayer(player)
end

local function onDeathZoneTouchEnded(otherPart: BasePart): ()
	local character = otherPart.Parent
	if not character or not isCharacterRootPart(otherPart, character) then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	fallLocked[player] = nil
end

local initialized = false

function PlayerService.Init(): ()
	if initialized then
		return
	end
	initialized = true

	local deathZone = Workspace:WaitForChild("DeathZone") :: BasePart
	deathZone.Touched:Connect(onDeathZoneTouched)
	deathZone.TouchEnded:Connect(onDeathZoneTouchEnded)

	Players.PlayerRemoving:Connect(function(player: Player)
		fallLocked[player] = nil
	end)
end

return PlayerService
