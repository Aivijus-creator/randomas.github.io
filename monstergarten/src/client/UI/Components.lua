-- Tiny UI builder: rounded pastel panels, squishy buttons, bars, windows and live-localized text.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared.Strings)
local Tween = require(Shared.Util.Tween)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors
local UI = {}
UI.Theme = Theme

local bindings = setmetatable({}, { __mode = "k" }) :: { [Instance]: { key: string, args: { any } } }
local clickSound: (() -> ())? = nil

function UI.setClickSound(fn: () -> ())
	clickSound = fn
end

-- Generic constructor: UI.new("Frame", { props }, { children })
function UI.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in props do
			if k == "Parent" then
				parent = v
			elseif typeof(k) == "string" then
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.corner(parent: Instance, radius: UDim?)
	return UI.new("UICorner", { CornerRadius = radius or Theme.Corner, Parent = parent })
end

function UI.stroke(parent: Instance, color: Color3?, thickness: number?)
	return UI.new("UIStroke", { Color = color or C.Plum, Thickness = thickness or Theme.Stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
end

function UI.padding(parent: Instance, px: number)
	return UI.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = parent,
	})
end

function UI.list(parent: Instance, padding: number?, horizontal: boolean?, align: Enum.HorizontalAlignment?)
	return UI.new("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = parent,
	})
end

function UI.grid(parent: Instance, cell: UDim2, padding: number?)
	return UI.new("UIGridLayout", {
		CellSize = cell,
		CellPadding = UDim2.fromOffset(padding or 8, padding or 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

-- Text bound to a Strings key: re-localizes when the language changes.
function UI.bind(label: Instance, key: string, ...: any)
	bindings[label] = { key = key, args = { ... } }
	;(label :: any).Text = Strings.t(key, ...)
end

function UI.relocalize()
	for label, b in bindings do
		if label.Parent then
			(label :: any).Text = Strings.t(b.key, table.unpack(b.args))
		end
	end
end

function UI.screen(name: string, order: number?): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local sg = UI.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 1,
		Parent = pg,
	})
	-- Scale everything down on small screens (phones).
	local scale = UI.new("UIScale", { Parent = sg })
	local function rescale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min(vp.X / 1280, vp.Y / 720) * 1.05, 0.55, 1.15)
	end
	rescale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	return sg
end

function UI.panel(props: { [string]: any }?, color: Color3?): Frame
	local f = UI.new("Frame", { BackgroundColor3 = color or C.Cream, BorderSizePixel = 0 })
	if props then
		for k, v in props do
			if k ~= "Parent" then
				(f :: any)[k] = v
			end
		end
	end
	UI.corner(f)
	UI.stroke(f)
	if props and props.Parent then
		f.Parent = props.Parent
	end
	return f
end

function UI.label(text: string, props: { [string]: any }?): TextLabel
	local l = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.Font,
		Text = text,
		TextColor3 = C.Plum,
		TextScaled = true,
		Size = UDim2.new(1, 0, 0, 28),
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = 40, Parent = l })
	if props then
		for k, v in props do
			if k ~= "Parent" then
				(l :: any)[k] = v
			end
		end
		if props.Parent then
			l.Parent = props.Parent
		end
	end
	return l
end

function UI.button(text: string, color: Color3?, onClick: (() -> ())?, props: { [string]: any }?): TextButton
	local b = UI.new("TextButton", {
		BackgroundColor3 = color or C.Mint,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Theme.Font,
		Text = text,
		TextColor3 = C.Plum,
		TextScaled = true,
		Size = UDim2.fromOffset(140, 44),
	})
	UI.corner(b, UDim.new(0, 16))
	UI.stroke(b)
	UI.new("UITextSizeConstraint", { MaxTextSize = 30, Parent = b })
	UI.padding(b, 6)
	if props then
		for k, v in props do
			if k ~= "Parent" then
				(b :: any)[k] = v
			end
		end
	end
	local base = b.BackgroundColor3
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = base:Lerp(C.White, 0.25) }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
	end)
	b.Activated:Connect(function()
		Tween.pop(b)
		if clickSound then
			clickSound()
		end
		if onClick then
			onClick()
		end
	end)
	if props and props.Parent then
		b.Parent = props.Parent
	end
	return b
end

-- Progress bar; returns the frame and a setter(0..1, color?).
function UI.bar(props: { [string]: any }?, fillColor: Color3?): (Frame, (number, Color3?) -> ())
	local bg = UI.new("Frame", { BackgroundColor3 = C.Dark, BackgroundTransparency = 0.3, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 10) })
	UI.corner(bg, UDim.new(1, 0))
	local fill = UI.new("Frame", { Name = "Fill", BackgroundColor3 = fillColor or C.Mint, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Parent = bg })
	UI.corner(fill, UDim.new(1, 0))
	if props then
		for k, v in props do
			if k ~= "Parent" then
				(bg :: any)[k] = v
			end
		end
		if props.Parent then
			bg.Parent = props.Parent
		end
	end
	local function set(v: number, color: Color3?)
		TweenService:Create(fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(math.clamp(v, 0, 1), 1) }):Play()
		if color then
			fill.BackgroundColor3 = color
		end
	end
	return bg, set
end

-- Modal window with a title and close button. Returns { Frame, Content, Open(), Close(), Toggle(), IsOpen() }.
function UI.window(parent: Instance, titleKey: string, size: UDim2, color: Color3?)
	local frame = UI.panel({
		Name = "Window_" .. titleKey,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		Visible = false,
		Parent = parent,
		ZIndex = 5,
	}, color or C.Cream)
	local title = UI.label("", { Size = UDim2.new(1, -70, 0, 44), Position = UDim2.fromOffset(16, 8), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	UI.bind(title, titleKey)
	local content = UI.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 1, -72),
		Parent = frame,
	})
	local scale = UI.new("UIScale", { Parent = frame })
	local api = {}
	local closeBtn = UI.button("✖", C.Pink, function()
		api.Close()
	end, { Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -54, 0, 8), Parent = frame })
	closeBtn.Name = "Close"
	api.Frame = frame
	api.Content = content
	api.Title = title
	api.OnOpen = nil :: (() -> ())?
	function api.Open()
		if frame.Visible then
			return
		end
		frame.Visible = true
		scale.Scale = 0.6
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		if api.OnOpen then
			api.OnOpen()
		end
		UI.WindowOpened(api)
	end
	function api.Close()
		frame.Visible = false
	end
	function api.Toggle()
		if frame.Visible then
			api.Close()
		else
			api.Open()
		end
	end
	function api.IsOpen()
		return frame.Visible
	end
	UI.Windows[api] = true
	return api
end

UI.Windows = {} :: { [any]: boolean }
-- Only one modal at a time.
function UI.WindowOpened(opened)
	for w in UI.Windows do
		if w ~= opened and w.IsOpen() then
			w.Close()
		end
	end
end

function UI.closeAll()
	for w in UI.Windows do
		if w.IsOpen() then
			w.Close()
		end
	end
end

function UI.scroll(parent: Instance, props: { [string]: any }?): ScrollingFrame
	local s = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.Plum,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
	if props then
		for k, v in props do
			(s :: any)[k] = v
		end
	end
	return s
end

return UI
