--[[
	Main – serverio paleidimas.
	Kiekvienas servisas (ServerScriptService/Services) turi :Init(S) ir :Start().
	S – visų servisų lentelė, todėl servisai vienas kito nereikalauja per require
	(taip išvengiama ciklinių priklausomybių).
]]

local ServerScriptService = game:GetService("ServerScriptService")

local servicesFolder = ServerScriptService:WaitForChild("Services")

-- Paleidimo eilė svarbi: duomenys -> šablonai -> žemėlapis -> sklypai -> likusios sistemos
local ORDER = {
	"DataService",
	"TemplateBuilder",
	"MapBuilder",
	"PlotService",
	"MonetizationService",
	"BonusService",
	"EventService",
	"TycoonService",
	"GrannyService",
	"WeaponService",
	"QuizService",
	"RadioService",
	"JailService",
	"GearService",
	"RebirthService",
	"LeaderboardService",
	"AdminService",
}

local S = {}

for _, name in ipairs(ORDER) do
	local module = servicesFolder:WaitForChild(name)
	local ok, result = pcall(require, module)
	if ok then
		S[name] = result
	else
		task.spawn(error, "[Main] Nepavyko įkelti " .. name .. ": " .. tostring(result))
	end
end

for _, name in ipairs(ORDER) do
	local service = S[name]
	if service and service.Init then
		local ok, err = pcall(service.Init, service, S)
		if not ok then
			task.spawn(error, "[Main] " .. name .. ":Init klaida: " .. tostring(err))
		end
	end
end

for _, name in ipairs(ORDER) do
	local service = S[name]
	if service and service.Start then
		local ok, err = pcall(service.Start, service)
		if not ok then
			task.spawn(error, "[Main] " .. name .. ":Start klaida: " .. tostring(err))
		end
	end
end

-- Kai visi servisai paleisti, prijungiami žaidėjai (DataService įkelia jų duomenis)
S.DataService:BeginPlayers()
