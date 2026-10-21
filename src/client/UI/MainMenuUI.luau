--!strict

-- Code-generierte Start-/Game-Over-UI (decisions/002-ui-code-generated.md,
-- Spec §4, §26), analog zu GameHudUI. Abonniert ausschließlich
-- GameClientController-Signale (StateChanged, GameOver), bindet sich nicht
-- selbst an das GameEvent-Remote (ARCHITECTURE.md Abschnitt 7). Siehe
-- tasks/011-main-menu-and-game-over.md.
--
-- Initialer State "MENU" wird vom Server beim PlayerAdded nur lokal gesetzt,
-- ohne StateChanged-Event (GameService.onPlayerAdded) — MainMenuUI.Init()
-- zeigt den Startscreen deshalb proaktiv an, statt auf ein erstes Signal zu
-- warten, und verlässt sich danach ausschließlich auf StateChanged/GameOver.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

local GameClientController = require(script.Parent.Parent.Controllers.GameClientController)

type GameStateName = GameTypes.GameStateName

local MainMenuUI = {}

local GAME_TITLE = "PAPA"
local GAME_OVER_TITLE = "GAME OVER"
local PLAY_ACTION = "MainMenuPlay"

local menuGui: ScreenGui? = nil
local startScreen: Frame
local gameOverScreen: Frame
local scoreLabel: TextLabel

local function onPlayClicked(): ()
	MainMenuUI.Hide()
	GameClientController.RequestPlay()
end

-- Taste E löst denselben PLAY-Intent aus wie der Button-Klick. Nur gebunden,
-- während der Menü-/Game-Over-Screen sichtbar ist (bind/unbind in
-- ShowStart/ShowGameOver/Hide), damit E während einer aktiven Session
-- ausschließlich InputController.PlaceBomb auslöst und nicht zusätzlich
-- GameClientController.RequestPlay() (würde die laufende Session
-- zurücksetzen, siehe GameService.onRequestPlay).
local function onPlayAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult?
	if inputState == Enum.UserInputState.Begin then
		onPlayClicked()
	end
	return Enum.ContextActionResult.Pass
end

local function bindPlayAction(): ()
	ContextActionService:BindActionAtPriority(
		PLAY_ACTION,
		onPlayAction,
		false,
		Enum.ContextActionPriority.Default.Value,
		Enum.KeyCode.E
	)
end

local function unbindPlayAction(): ()
	ContextActionService:UnbindAction(PLAY_ACTION)
end

local function createPlayButton(parent: Instance, layoutOrder: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = "PlayButton"
	button.LayoutOrder = layoutOrder
	button.AutomaticSize = Enum.AutomaticSize.None
	button.Size = UDim2.new(0, 260, 0, 56)
	button.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
	button.AutoButtonColor = true
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 24
	button.TextColor3 = Color3.fromRGB(10, 10, 14)
	button.Text = "PLAY [E]"
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	button.Activated:Connect(onPlayClicked)

	return button
end

local function createLabel(parent: Instance, name: string, text: string, textSize: number, layoutOrder: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.LayoutOrder = layoutOrder
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = Color3.fromRGB(235, 235, 240)
	label.Text = text
	label.Parent = parent
	return label
end

local function createScreen(name: string, parent: Instance): Frame
	local screen = Instance.new("Frame")
	screen.Name = name
	screen.BackgroundColor3 = Color3.fromRGB(8, 8, 11)
	screen.BackgroundTransparency = 0.1
	screen.BorderSizePixel = 0
	screen.Size = UDim2.new(1, 0, 1, 0)
	screen.Visible = false
	screen.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 18)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = screen

	return screen
end

function MainMenuUI.Create(): ScreenGui
	if menuGui then
		return menuGui
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10
	screenGui.Enabled = false

	startScreen = createScreen("StartScreen", screenGui)
	createLabel(startScreen, "Title", GAME_TITLE, 48, 1)
	createPlayButton(startScreen, 2)

	gameOverScreen = createScreen("GameOverScreen", screenGui)
	createLabel(gameOverScreen, "Title", GAME_OVER_TITLE, 40, 1)
	scoreLabel = createLabel(gameOverScreen, "Score", "SCORE 0", 24, 2)
	createPlayButton(gameOverScreen, 3)

	screenGui.Parent = playerGui
	menuGui = screenGui

	return screenGui
end

function MainMenuUI.ShowStart(): ()
	local gui = MainMenuUI.Create()
	startScreen.Visible = true
	gameOverScreen.Visible = false
	gui.Enabled = true
	bindPlayAction()
end

function MainMenuUI.ShowGameOver(score: number): ()
	local gui = MainMenuUI.Create()
	scoreLabel.Text = ("SCORE %d"):format(score)
	startScreen.Visible = false
	gameOverScreen.Visible = true
	gui.Enabled = true
	bindPlayAction()
end

function MainMenuUI.Hide(): ()
	if menuGui then
		menuGui.Enabled = false
	end
	unbindPlayAction()
end

local function onStateChanged(state: GameStateName): ()
	if state == "MENU" then
		MainMenuUI.ShowStart()
	elseif state ~= "GAME_OVER" then
		MainMenuUI.Hide()
	end
end

local function onGameOver(score: number): ()
	MainMenuUI.ShowGameOver(score)
end

local initialized = false

function MainMenuUI.Init(): ()
	if initialized then
		return
	end
	initialized = true

	GameClientController.StateChanged:Connect(onStateChanged)
	GameClientController.GameOver:Connect(onGameOver)

	MainMenuUI.ShowStart()
end

return MainMenuUI
