-- Creates the post-processing stack. Lighting.Technology = Future is set in default.project.json
-- (it cannot be changed from scripts). The client LightingController animates values per player.
local Lighting = game:GetService("Lighting")

local L = {}

local function ensure(className: string, name: string): Instance
	local inst = Lighting:FindFirstChild(name)
	if not inst then
		inst = Instance.new(className)
		inst.Name = name
		inst.Parent = Lighting
	end
	return inst
end

function L.setup()
	Lighting.ClockTime = 18.5
	Lighting.Brightness = 2
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.Ambient = Color3.fromRGB(90, 80, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 105, 140)
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.4

	local atm = ensure("Atmosphere", "Atmosphere") :: Atmosphere
	atm.Density = 0.35
	atm.Offset = 0.2
	atm.Color = Color3.fromRGB(230, 190, 210)
	atm.Decay = Color3.fromRGB(120, 90, 140)
	atm.Glare = 0.3
	atm.Haze = 1.6

	local bloom = ensure("BloomEffect", "Bloom") :: BloomEffect
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6

	local cc = ensure("ColorCorrectionEffect", "ColorCorrection") :: ColorCorrectionEffect
	cc.Saturation = 0.12
	cc.Contrast = 0.05
	cc.TintColor = Color3.fromRGB(255, 240, 245)

	local rays = ensure("SunRaysEffect", "SunRays") :: SunRaysEffect
	rays.Intensity = 0.06
	rays.Spread = 0.6

	local dof = ensure("DepthOfFieldEffect", "DepthOfField") :: DepthOfFieldEffect
	dof.FarIntensity = 0.12
	dof.FocusDistance = 60
	dof.InFocusRadius = 60
	dof.NearIntensity = 0

	-- Darkness overlay used by blackouts / dark rooms (client drives it).
	local dark = ensure("ColorCorrectionEffect", "DarkCorrection") :: ColorCorrectionEffect
	dark.Brightness = 0
	dark.Saturation = 0
	dark.Enabled = true

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		local s = Instance.new("Sky")
		s.StarCount = 3000
		s.CelestialBodiesShown = true
		s.MoonAngularSize = 14
		s.Parent = Lighting
	end
end

return L
