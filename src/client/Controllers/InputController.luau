--!strict

-- Übersetzt Spieler-Eingabe (Taste E / mobiler Touch-Button) in den
-- PlaceBomb-Intent und feuert ihn über Net. Keine Abhängigkeit auf
-- GameClientController oder lokalen Spielzustand — der Server validiert,
-- ob die Aktion gerade erlaubt ist (ARCHITECTURE.md Abschnitt 1).
-- Siehe tasks/009-input-controller.md.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net.Net)

local InputController = {}

local PLACE_BOMB_ACTION = "PlaceBomb"

local clientActionRemote: RemoteEvent
local initialized = false

local function onPlaceBombAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult?
	if inputState == Enum.UserInputState.Begin then
		clientActionRemote:FireServer({ type = Net.ClientActionType.PlaceBomb })
	end
	return Enum.ContextActionResult.Pass
end

function InputController.Init(): ()
	if initialized then
		return
	end
	initialized = true

	clientActionRemote = Net.WaitForRemotes()

	ContextActionService:BindActionAtPriority(
		PLACE_BOMB_ACTION,
		onPlaceBombAction,
		true,
		Enum.ContextActionPriority.Default.Value,
		Enum.KeyCode.E
	)
	ContextActionService:SetTitle(PLACE_BOMB_ACTION, "BOMB")
end

return InputController
