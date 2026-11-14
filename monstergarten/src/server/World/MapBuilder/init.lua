-- MapBuilder: builds the lobby into Workspace and the daycare template into ServerStorage.
-- If the author placed their own models at ServerStorage/Maps/Lobby or ServerStorage/Maps/DaycareTemplate,
-- those are used instead (tags/attributes are what the gameplay code relies on).
local ServerStorage = game:GetService("ServerStorage")

local Lobby = require(script.Lobby)
local DaycareTemplate = require(script.DaycareTemplate)
local LightingSetup = require(script.Lighting)

local MapBuilder = {}

local function mapsFolder(): Folder
	local f = ServerStorage:FindFirstChild("Maps")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Maps"
		f.Parent = ServerStorage
	end
	return f :: Folder
end

function MapBuilder.buildLobby(): Model
	local custom = mapsFolder():FindFirstChild("Lobby")
	if custom and custom:IsA("Model") then
		local m = custom:Clone()
		m.Name = "Lobby"
		m.Parent = workspace
		return m
	end
	return Lobby.build(workspace)
end

function MapBuilder.buildTemplate(): Model
	local f = mapsFolder()
	local custom = f:FindFirstChild("DaycareTemplate")
	if custom and custom:IsA("Model") then
		return custom
	end
	local t = DaycareTemplate.build(nil)
	t.Name = "GeneratedDaycareTemplate"
	t.Parent = f
	return t
end

function MapBuilder.setupLighting()
	LightingSetup.setup()
end

return MapBuilder
