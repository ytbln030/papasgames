--!strict

-- Code-generierte, schmale Topbar (decisions/002-ui-code-generated.md,
-- Spec §27, §9 — First-Person-Priorität). Abonniert ausschließlich
-- GameClientController-Signals, bindet sich nicht selbst an das
-- GameEvent-Remote (ARCHITECTURE.md Abschnitt 7). Siehe
-- tasks/010-game-hud.md.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

local GameClientController = require(script.Parent.Parent.Controllers.GameClientController)

type TargetData = GameTypes.TargetData
type GameStateName = GameTypes.GameStateName
type BombOutcome = GameTypes.BombOutcome

export type HudUpdateData = {
	level: number?,
	targets: number?,
	lives: number?,
	score: number?,
}

local GameHudUI = {}

local TOPBAR_HEIGHT = 36
local FEEDBACK_DISPLAY_SECONDS = 1

local SUCCESS_FEEDBACK_TEXT = "PERFECT!"
local MISS_FEEDBACK_TEXT = "MISS"

local hudGui: ScreenGui? = nil
local levelLabel: TextLabel
local targetsLabel: TextLabel
local timeLabel: TextLabel
local livesLabel: TextLabel
local scoreLabel: TextLabel
local feedbackLabel: TextLabel

-- targetsDestroyed existiert nur hier client-lokal: der Server zählt keine
-- Gesamtanzahl erfolgreich zerstörter Targets pro Session (nur
-- score/levelScore, siehe PlayerSessionData), siehe tasks/010 Funktionale
-- Anforderung 2.
local hudState = {
	level = 0,
	targetsDestroyed = 0,
	lives = 0,
	score = 0,
}

local activeTarget: TargetData? = nil

-- Eigener, client-lokaler os.clock()-Ankerpunkt statt TargetData.spawnedAt
-- direkt zu verwenden: os.clock() läuft auf Server und Client in getrennten
-- Prozessen mit unterschiedlicher Epoche, ein Server-Zeitstempel ist auf dem
-- Client nicht direkt vergleichbar. Nur target.lifetime (ein reiner
-- Zeitdauer-Wert) wird vom Server übernommen, der Ankerpunkt selbst ist der
-- Empfangszeitpunkt auf dem Client (tasks/010 Funktionale Anforderung 4).
local localTargetSpawnedAt: number? = nil

-- Schützt den verzögerten `task.delay`-Hide-Call davor, ein inzwischen neu
-- angezeigtes Feedback einer folgenden Runde wieder auszublenden.
local feedbackGeneration = 0

local function formatField(label: string, value: string): string
	return label .. " " .. value
end

local function updateTimeLabel(): ()
	if not activeTarget or not localTargetSpawnedAt then
		timeLabel.Text = formatField("TIME", "-")
		return
	end

	local remaining = math.max(activeTarget.lifetime - (os.clock() - localTargetSpawnedAt), 0)
	timeLabel.Text = formatField("TIME", string.format("%.1f", remaining))
end

local function createStatLabel(parent: Instance, name: string, layoutOrder: number): TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = name
	textLabel.BackgroundTransparency = 1
	textLabel.AutomaticSize = Enum.AutomaticSize.X
	textLabel.Size = UDim2.new(0, 0, 1, 0)
	textLabel.LayoutOrder = layoutOrder
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 18
	textLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
	textLabel.Text = name
	textLabel.Parent = parent
	return textLabel
end

function GameHudUI.Create(): ScreenGui
	if hudGui then
		return hudGui
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHudUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false

	local topbar = Instance.new("Frame")
	topbar.Name = "Topbar"
	topbar.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	topbar.BackgroundTransparency = 0.25
	topbar.BorderSizePixel = 0
	topbar.Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT)
	topbar.Position = UDim2.new(0, 0, 0, 0)
	topbar.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 24)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = topbar

	levelLabel = createStatLabel(topbar, "LEVEL", 1)
	targetsLabel = createStatLabel(topbar, "TARGETS", 2)
	timeLabel = createStatLabel(topbar, "TIME", 3)
	livesLabel = createStatLabel(topbar, "LIVES", 4)
	scoreLabel = createStatLabel(topbar, "SCORE", 5)

	feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "Feedback"
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.AnchorPoint = Vector2.new(0.5, 0)
	feedbackLabel.Position = UDim2.new(0.5, 0, 0, TOPBAR_HEIGHT + 12)
	feedbackLabel.Size = UDim2.new(0, 400, 0, 40)
	feedbackLabel.Font = Enum.Font.GothamBold
	feedbackLabel.TextSize = 28
	feedbackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	feedbackLabel.TextStrokeTransparency = 0.5
	feedbackLabel.Text = ""
	feedbackLabel.Visible = false
	feedbackLabel.Parent = screenGui

	screenGui.Parent = playerGui
	hudGui = screenGui

	GameHudUI.Update({ level = hudState.level, targets = hudState.targetsDestroyed, lives = hudState.lives, score = hudState.score })
	updateTimeLabel()

	return screenGui
end

function GameHudUI.Update(data: HudUpdateData): ()
	if data.level ~= nil then
		hudState.level = data.level
		levelLabel.Text = formatField("LEVEL", tostring(data.level))
	end
	if data.targets ~= nil then
		hudState.targetsDestroyed = data.targets
		targetsLabel.Text = formatField("TARGETS", tostring(data.targets))
	end
	if data.lives ~= nil then
		hudState.lives = data.lives
		livesLabel.Text = formatField("LIVES", tostring(data.lives))
	end
	if data.score ~= nil then
		hudState.score = data.score
		scoreLabel.Text = formatField("SCORE", tostring(data.score))
	end
end

local function setVisible(visible: boolean): ()
	if hudGui then
		hudGui.Enabled = visible
	end
end

local function showFeedback(outcome: BombOutcome): ()
	feedbackGeneration += 1
	local generation = feedbackGeneration

	local isSuccess = outcome == "SUCCESS"
	feedbackLabel.Text = if isSuccess then SUCCESS_FEEDBACK_TEXT else MISS_FEEDBACK_TEXT
	feedbackLabel.TextColor3 = if isSuccess then Color3.fromRGB(120, 255, 150) else Color3.fromRGB(255, 90, 90)
	feedbackLabel.Visible = true

	task.delay(FEEDBACK_DISPLAY_SECONDS, function()
		if feedbackGeneration == generation then
			feedbackLabel.Visible = false
		end
	end)
end

local function onStateChanged(state: GameStateName): ()
	if state == "STARTING" then
		activeTarget = nil
		localTargetSpawnedAt = nil
		feedbackGeneration += 1
		feedbackLabel.Visible = false
		GameHudUI.Update({ level = 1, targets = 0, score = 0 })
		updateTimeLabel()
	end

	setVisible(state ~= "MENU" and state ~= "GAME_OVER")
end

local function onTargetSpawned(target: TargetData): ()
	activeTarget = target
	localTargetSpawnedAt = os.clock()
	updateTimeLabel()
end

local function onTargetCleared(): ()
	activeTarget = nil
	localTargetSpawnedAt = nil
	updateTimeLabel()
end

local function onRoundResult(outcome: BombOutcome): ()
	showFeedback(outcome)
	if outcome == "SUCCESS" then
		GameHudUI.Update({ targets = hudState.targetsDestroyed + 1 })
	end
end

local function onScoreUpdated(data: { score: number, levelScore: number, level: number }): ()
	GameHudUI.Update({ score = data.score, level = data.level })
end

local function onLivesChanged(lives: number): ()
	GameHudUI.Update({ lives = lives })
end

local initialized = false

function GameHudUI.Init(): ()
	if initialized then
		return
	end
	initialized = true

	GameHudUI.Create()

	GameClientController.StateChanged:Connect(onStateChanged)
	GameClientController.TargetSpawned:Connect(onTargetSpawned)
	GameClientController.TargetCleared:Connect(onTargetCleared)
	GameClientController.RoundResult:Connect(onRoundResult)
	GameClientController.ScoreUpdated:Connect(onScoreUpdated)
	GameClientController.LivesChanged:Connect(onLivesChanged)

	RunService.Heartbeat:Connect(updateTimeLabel)
end

return GameHudUI
