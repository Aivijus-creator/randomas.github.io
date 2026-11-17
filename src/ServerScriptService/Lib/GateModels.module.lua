--[[
	GateModels – sklypo vartų išvaizda pagal lygį (lentynos patobulinimas „Vartai“):
	  0 – rąstų vartai (pradžia): apvalūs rąstai su nusmailintomis viršūnėmis
	  1 – dailidės vartai: tašyti stulpai su kepurėmis, gontų stogelis, saulutė
	  2 – plytų vartai: raudonų plytų bokštai su dantytais viršais ir arka
	Visi bokštai ~12 studų aukščio (ant jų stovi fakelai ir vėliava).

	GateModels.Build(parent, plotCF, level, gateX, gateZ, gateWidth)
]]

local Build = require(script.Parent:WaitForChild("Build"))

local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local CYL_UP = CFrame.Angles(0, 0, math.rad(90))

local GateModels = {}

local function p(parent, plotCF, name, size, cf, color, material, shape)
	return Build.Part({ Name = name, Parent = parent, Size = size, CFrame = plotCF * cf, Color = color, Material = material, Shape = shape })
end

local function logGate(parent, plotCF, gateX, z, width)
	local log = C(125, 88, 52)
	for _, side in ipairs({ -1, 1 }) do
		local x = side * gateX
		for k, off in ipairs({ { -0.7, -0.5 }, { 0.7, -0.5 }, { 0, 0.7 } }) do
			local h = 10.5 + (k % 2) * 0.8
			p(parent, plotCF, "GateLog", V(h, 1.4, 1.4), CF(x + off[1], h / 2, z + off[2]) * CYL_UP, log, M.Wood, Enum.PartType.Cylinder)
			for t = 0, 2 do
				local d = 1.2 - t * 0.35
				p(parent, plotCF, "GateLogTip", V(0.35, d, d), CF(x + off[1], h + 0.15 + t * 0.32, z + off[2]) * CYL_UP, log:Lerp(C(80, 55, 30), 0.3), M.Wood, Enum.PartType.Cylinder)
			end
		end
		-- Virvės raištis
		p(parent, plotCF, "GateRope", V(0.5, 3.2, 3.2), CF(x, 7.5, z) * CYL_UP, C(190, 160, 110), M.Fabric, Enum.PartType.Cylinder)
		p(parent, plotCF, "GateTop", V(2.6, 0.5, 2.6), CF(x, 11.6, z), log, M.Wood)
	end
	p(parent, plotCF, "GateBeamLog", V(width + 6, 1.6, 1.6), CF(0, 11, z), log, M.Wood, Enum.PartType.Cylinder)
end

local function carvedGate(parent, plotCF, gateX, z, width)
	local wood = C(150, 100, 55)
	local dark = C(90, 58, 30)
	for _, side in ipairs({ -1, 1 }) do
		local x = side * gateX
		p(parent, plotCF, "GatePost", V(2.6, 11.4, 2.6), CF(x, 5.7, z), wood, M.WoodPlanks)
		for _, dx in ipairs({ -1.25, 1.25 }) do
			for _, dz in ipairs({ -1.25, 1.25 }) do
				p(parent, plotCF, "GatePostTrim", V(0.3, 11.4, 0.3), CF(x + dx, 5.7, z + dz), dark, M.Wood)
			end
		end
		-- Išdrožinėti rombai stulpo priekyje
		for k = 0, 3 do
			p(parent, plotCF, "GateCarving", V(0.6, 0.6, 0.12), CF(x, 3 + k * 1.8, z - 1.36) * CFrame.Angles(0, 0, math.rad(45)), C(230, 190, 110), M.Wood)
		end
		-- Piramidinė kepurė
		p(parent, plotCF, "GatePostCap", V(3.2, 0.5, 3.2), CF(x, 11.65, z), dark, M.Wood)
		p(parent, plotCF, "GatePostCap2", V(2.2, 0.5, 2.2), CF(x, 12.1, z), dark, M.Wood)
	end
	p(parent, plotCF, "GateBeamCarved", V(width + 7, 1.8, 2.2), CF(0, 11, z), wood, M.WoodPlanks)
	-- Gontų stogelis virš sijos
	for _, side in ipairs({ -1, 1 }) do
		p(parent, plotCF, "GateRoof", V(width + 8, 0.35, 2.4), CF(0, 12.55, z + side * 0.95) * CFrame.Angles(math.rad(side * 28), 0, 0), C(95, 60, 40), M.WoodPlanks)
	end
	p(parent, plotCF, "GateRidge", V(width + 8.2, 0.35, 0.35), CF(0, 13.15, z), dark, M.Wood)
	-- Saulutė (tradicinis lietuviškas ornamentas) sijos viduryje
	p(parent, plotCF, "GateSun", V(0.15, 1.3, 1.3), CF(0, 11, z - 1.2) * CFrame.Angles(0, math.rad(90), 0), C(240, 190, 60), M.Wood, Enum.PartType.Cylinder)
	for k = 0, 7 do
		local a = k * math.pi / 4
		p(parent, plotCF, "GateSunRay", V(0.18, 0.7, 0.1), CF(math.cos(a) * 0.95, 11 + math.sin(a) * 0.95, z - 1.2) * CFrame.Angles(0, 0, a - math.pi / 2), C(240, 190, 60), M.Wood)
	end
end

local function brickGate(parent, plotCF, gateX, z, width)
	local brick = C(165, 65, 48)
	local stone = C(200, 190, 175)
	for _, side in ipairs({ -1, 1 }) do
		local x = side * gateX
		p(parent, plotCF, "GateTower", V(4, 12, 4), CF(x, 6, z), brick, M.Brick)
		p(parent, plotCF, "GateTowerBase", V(4.4, 1.2, 4.4), CF(x, 0.6, z), stone, M.Limestone)
		p(parent, plotCF, "GateTowerBand", V(4.3, 0.4, 4.3), CF(x, 11.6, z), stone, M.Limestone)
		for _, dx in ipairs({ -1.4, 1.4 }) do
			for _, dz in ipairs({ -1.4, 1.4 }) do
				p(parent, plotCF, "Crenel", V(1.1, 1.2, 1.1), CF(x + dx, 12.6, z + dz), brick, M.Brick)
			end
		end
		p(parent, plotCF, "GateWindow", V(0.6, 1.4, 0.15), CF(x, 8, z - 2.05), C(30, 22, 18), M.SmoothPlastic)
	end
	p(parent, plotCF, "GateBeamBrick", V(width + 8, 2, 3), CF(0, 11, z), brick, M.Brick)
	p(parent, plotCF, "GateArch", V(width + 4.2, 0.6, 3.2), CF(0, 9.8, z), stone, M.Limestone)
	for i = -2, 2 do
		p(parent, plotCF, "GateArchStone", V(0.5, 0.9, 3.25), CF(i * 2.2, 9.6, z), stone:Lerp(C(150, 140, 125), 0.3), M.Limestone)
	end
end

local BUILDERS = { [0] = logGate, [1] = carvedGate, [2] = brickGate }

function GateModels.Build(parent, plotCF, level, gateX, gateZ, gateWidth)
	local builder = BUILDERS[level] or logGate
	builder(parent, plotCF, gateX, gateZ, gateWidth)
end

return GateModels
