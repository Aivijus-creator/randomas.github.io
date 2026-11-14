-- LoadingController: Monstergarten loading screen with a bouncing baby until your data has loaded.
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local C = UI.Theme.Colors
local LoadingController = {}
local gui: ScreenGui

function LoadingController:Init()
	gui = UI.screen("LoadingGui", 100)
	local bg = UI.new("Frame", { BackgroundColor3 = C.Plum, Size = UDim2.fromScale(1, 1), Parent = gui })
	UI.new("UIGradient", { Color = ColorSequence.new(C.Plum, Color3.fromRGB(120, 90, 160)), Rotation = 90, Parent = bg })
	if Assets.Images.Logo ~= 0 then
		UI.new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(520, 200), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = "rbxassetid://" .. Assets.Images.Logo, Parent = bg })
	else
		UI.label("MONSTERGARTEN", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(700, 90), TextColor3 = C.Peach, TextStrokeTransparency = 0.6, Parent = bg })
	end
	local baby = UI.label("👾", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromOffset(110, 110), Parent = bg })
	local tag = UI.label("🍼 ...", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.75), Size = UDim2.fromOffset(500, 36), TextColor3 = C.Cream, Parent = bg })
	UI.bind(tag, "Loading_Tagline")
	TweenService:Create(baby, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true), { Position = UDim2.fromScale(0.5, 0.55), Rotation = 10 }):Play()
end

function LoadingController:Start()
	local function finish()
		if not gui.Parent then
			return
		end
		local bg = gui:FindFirstChildOfClass("Frame")
		if bg then
			for _, d in bg:GetDescendants() do
				if d:IsA("TextLabel") then
					TweenService:Create(d, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
				elseif d:IsA("ImageLabel") then
					TweenService:Create(d, TweenInfo.new(0.6), { ImageTransparency = 1 }):Play()
				end
			end
			TweenService:Create(bg, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
		end
		task.delay(0.9, function()
			gui:Destroy()
		end)
	end
	if State.Data then
		task.delay(1, finish)
	else
		local conn
		conn = State.DataChanged:Connect(function()
			conn:Disconnect()
			task.delay(0.8, finish)
		end)
		task.delay(15, finish)
	end
end

return LoadingController
