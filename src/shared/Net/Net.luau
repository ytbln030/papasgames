--!strict

-- RemoteEvent-Wrapper + Event-Namenskonstanten. Siehe ARCHITECTURE.md Abschnitt 6.
-- In diesem Task (002) werden die Remotes nur bereitgestellt, nicht gefeuert
-- oder abgehört (folgt in Task 006).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.ClientActionType = {
	RequestPlay = "RequestPlay",
	PlaceBomb = "PlaceBomb",
}

Net.GameEventType = {
	StateChanged = "StateChanged",
	TargetSpawned = "TargetSpawned",
	TargetCleared = "TargetCleared",
	BombPlaced = "BombPlaced",
	RoundResult = "RoundResult",
	ScoreUpdated = "ScoreUpdated",
	LivesChanged = "LivesChanged",
	GameOver = "GameOver",
}

local REMOTES_FOLDER_NAME = "Remotes"
local CLIENT_ACTION_NAME = "ClientAction"
local GAME_EVENT_NAME = "GameEvent"

function Net.EnsureRemotes(): ()
	-- RunService:IsServer() ist im Studio-Edit-Modus (Command-Bar, nicht spielend)
	-- fälschlich false, obwohl dieser Kontext serverseitige Autorität hat. Daher
	-- nur während einer laufenden Play-Session (IsRunning) auf IsServer prüfen.
	if RunService:IsRunning() and not RunService:IsServer() then
		error("Net.EnsureRemotes darf nur auf dem Server aufgerufen werden")
	end

	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end

	if not remotesFolder:FindFirstChild(CLIENT_ACTION_NAME) then
		local clientAction = Instance.new("RemoteEvent")
		clientAction.Name = CLIENT_ACTION_NAME
		clientAction.Parent = remotesFolder
	end

	if not remotesFolder:FindFirstChild(GAME_EVENT_NAME) then
		local gameEvent = Instance.new("RemoteEvent")
		gameEvent.Name = GAME_EVENT_NAME
		gameEvent.Parent = remotesFolder
	end
end

function Net.WaitForRemotes(): (RemoteEvent, RemoteEvent)
	local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	local clientAction = remotesFolder:WaitForChild(CLIENT_ACTION_NAME) :: RemoteEvent
	local gameEvent = remotesFolder:WaitForChild(GAME_EVENT_NAME) :: RemoteEvent
	return clientAction, gameEvent
end

return Net
