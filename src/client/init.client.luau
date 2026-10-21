-- Composition Root. Bootstrap-Reihenfolge siehe ARCHITECTURE.md Abschnitt 3.
-- EffectsController folgt in Task 012.
--
-- GameHudUI wird hier (statt wie in Abschnitt 3 ursprünglich vorgesehen
-- lazy von GameClientController beim ersten GameEvent) direkt analog zu
-- InputController gestartet: die UI entsteht zwar sofort, bleibt aber bis
-- zum ersten StateChanged-Event ausgeblendet (ScreenGui.Enabled = false),
-- was dasselbe sichtbare Verhalten ergibt, ohne dass GameClientController
-- eine Abhängigkeit auf ein UI-Modul bekommt (tasks/010-game-hud.md).

local GameClientController = require(script.Controllers.GameClientController)
local InputController = require(script.Controllers.InputController)
local GameHudUI = require(script.UI.GameHudUI)
local MainMenuUI = require(script.UI.MainMenuUI)

GameClientController.Init()
InputController.Init()
GameHudUI.Init()
MainMenuUI.Init()
