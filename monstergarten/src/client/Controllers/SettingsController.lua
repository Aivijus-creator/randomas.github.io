-- SettingsController: music / sfx volume, language, camera shake, effects quality, replay tutorial.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Strings = require(Shared.Strings)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local C = UI.Theme.Colors
local SettingsController = {
	Settings = { MusicVolume = 0.5, SfxVolume = 0.8, Language = "auto", CameraShake = true, Quality = "High" },
}
local window
local rows = {}

local function set(key: string, value: any)
	SettingsController.Settings[key] = value
	Remotes.event("SetSetting"):FireServer(key, value)
	SettingsController:Refresh()
	if key == "Language" then
		local lang = Strings.resolve(value, State.player.LocaleId)
		Strings.setLanguage(lang)
		UI.relocalize()
		State.LanguageChanged:Fire(lang)
	end
end

function SettingsController:Quality(): string
	local q = self.Settings.Quality
	if q == "Auto" or q == nil then
		return if UserInputService.TouchEnabled then "Low" else "High"
	end
	return q
end

function SettingsController:Refresh()
	local s = self.Settings
	if rows.Music then
		rows.Music.Text = ("%d%%"):format(math.floor(s.MusicVolume * 100 + 0.5))
		rows.Sfx.Text = ("%d%%"):format(math.floor(s.SfxVolume * 100 + 0.5))
		rows.Lang.Text = if s.Language == "auto" then Strings.t("Settings_Auto") else string.upper(s.Language)
		rows.Shake.Text = Strings.t(if s.CameraShake then "On" else "Off")
		rows.Quality.Text = Strings.t("Quality_" .. tostring(s.Quality))
	end
end

local function row(parent, order: number, labelKey: string, build: (Frame) -> ())
	local r = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), LayoutOrder = order, Parent = parent })
	local l = UI.label("", { Size = UDim2.new(0.45, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = r })
	UI.bind(l, labelKey)
	local right = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.45, 0), Size = UDim2.fromScale(0.55, 1), Parent = r })
	UI.list(right, 6, true, Enum.HorizontalAlignment.Right)
	build(right)
end

function SettingsController:Open()
	window.Open()
end

function SettingsController:Init()
	local gui = UI.screen("SettingsGui", 20)
	window = UI.window(gui, "Settings_Title", UDim2.fromOffset(520, 470))
	local list = window.Content
	UI.list(list, 8)
	local function volumeRow(order, key, settingKey, rowKey)
		row(list, order, key, function(right)
			UI.button("−", C.Peach, function()
				set(settingKey, math.max(0, math.floor((self.Settings[settingKey] - 0.1) * 10 + 0.5) / 10))
			end, { Size = UDim2.fromOffset(44, 44), LayoutOrder = 1, Parent = right })
			rows[rowKey] = UI.label("", { Size = UDim2.fromOffset(80, 44), LayoutOrder = 2, Parent = right })
			UI.button("+", C.Mint, function()
				set(settingKey, math.min(1, math.floor((self.Settings[settingKey] + 0.1) * 10 + 0.5) / 10))
			end, { Size = UDim2.fromOffset(44, 44), LayoutOrder = 3, Parent = right })
		end)
	end
	volumeRow(1, "Settings_Music", "MusicVolume", "Music")
	volumeRow(2, "Settings_Sfx", "SfxVolume", "Sfx")
	row(list, 3, "Settings_Language", function(right)
		rows.Lang = UI.button("", C.Lavender, function()
			local order = { "auto", "en", "lt" }
			local i = table.find(order, self.Settings.Language) or 1
			set("Language", order[(i % #order) + 1])
		end, { Size = UDim2.fromOffset(150, 44), Parent = right })
	end)
	row(list, 4, "Settings_Shake", function(right)
		rows.Shake = UI.button("", C.Lavender, function()
			set("CameraShake", not self.Settings.CameraShake)
		end, { Size = UDim2.fromOffset(150, 44), Parent = right })
	end)
	row(list, 5, "Settings_Quality", function(right)
		rows.Quality = UI.button("", C.Lavender, function()
			local order = { "High", "Low", "Auto" }
			local i = table.find(order, self.Settings.Quality) or 1
			set("Quality", order[(i % #order) + 1])
		end, { Size = UDim2.fromOffset(150, 44), Parent = right })
	end)
	-- Music Box game pass: pick a lobby track (only tracks with uploaded ids)
	local tracks = {}
	for _, t in require(Shared.Config.Assets).MusicBox do
		if t.Id ~= 0 then
			table.insert(tracks, t)
		end
	end
	if #tracks > 0 then
		row(list, 5.5, "Settings_MusicBox", function(right)
			local idx = 0
			rows.MusicBox = UI.button("🎶 -", C.Peach, function()
				if not State.player:GetAttribute("MusicBox") then
					return
				end
				idx = (idx % (#tracks + 1)) + 1
				local t = tracks[idx]
				rows.MusicBox.Text = if t then ("🎶 " .. t.Name) else "🎶 -"
				State.Controllers.SoundController:SetMusicBox(t and t.Id or nil)
			end, { Size = UDim2.fromOffset(200, 44), Parent = right })
		end)
	end
	row(list, 6, "Settings_Tutorial", function(right)
		local b = UI.button("", C.Yellow, function()
			window.Close()
			Remotes.event("TutorialAction"):FireServer("Replay")
		end, { Size = UDim2.fromOffset(150, 44), Parent = right })
		UI.bind(b, "Settings_Replay")
	end)
	self:Refresh()
end

function SettingsController:Start()
	State.DataChanged:Connect(function(data)
		if data and data.Settings then
			for k, v in data.Settings do
				self.Settings[k] = v
			end
			self:Refresh()
		end
	end)
	State.LanguageChanged:Connect(function()
		UI.relocalize()
		self:Refresh()
	end)
end

return SettingsController
