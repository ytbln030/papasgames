local workspace = game:GetService("Workspace")
local terrain = workspace.Terrain

local BASEPLATE_SIZE = Vector3.new(512, 20, 512)
local BASEPLATE_POSITION = Vector3.new(0, -10, 0)

terrain.Decoration = true
terrain:FillBlock(CFrame.new(BASEPLATE_POSITION), BASEPLATE_SIZE, Enum.Material.Grass)

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.Transparency = 1
	baseplate.CanCollide = false
end
