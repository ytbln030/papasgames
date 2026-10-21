-- Composition Root. Bootstrap-Reihenfolge siehe ARCHITECTURE.md Abschnitt 3.
-- EffectsController folgt in Task 012.

local GameClientController = require(script.Controllers.GameClientController)
local InputController = require(script.Controllers.InputController)

GameClientController.Init()
InputController.Init()
