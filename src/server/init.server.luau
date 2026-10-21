-- Composition Root. Bootstrap-Reihenfolge siehe ARCHITECTURE.md Abschnitt 3.

local BoardService = require(script.Services.BoardService)
local PlayerService = require(script.Services.PlayerService)
local TargetService = require(script.Services.TargetService)
local BombService = require(script.Services.BombService)
local GameService = require(script.Services.GameService)

PlayerService.Init()
BombService.Init()
GameService.Init()
