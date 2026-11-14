-- KitchenService: ingredient sources, appliances (oven / pot / blender / freezer), cooking, overcooking -> fire.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Recipes = require(Shared.Config.Recipes)
local RecipeMatch = require(Shared.Logic.RecipeMatch)
local ServerUtil = require(script.Parent.Parent.ServerUtil)
local Interact = require(script.Parent.Parent.Interact)
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)

local KitchenService = {}
local S

local function publish(app)
	local m = app.Model
	m:SetAttribute("State", app.State)
	m:SetAttribute("Contents", table.concat(app.Contents, ","))
	m:SetAttribute("Dish", app.Dish or "")
	app.AddPrompt.Enabled = app.State == "Idle"
	app.TakePrompt.Enabled = app.State == "Ready" or app.State == "Burnt"
	app.TakePrompt.ActionText = if app.State == "Burnt" then "Take (burnt)" else "Take"
end

local function allowEvent(session): boolean
	return session.ActiveEvent ~= nil and session.ActiveEvent.Id == "Birthday"
end

local function cookTime(session, app, recipe): number
	local t = recipe.Time
	if app.Kind == "Blender" and session.Upgrades.MegaBlender then
		t *= 0.5
	end
	return t
end

local function speedMult(session, app): number
	-- A happy Sparky next to the oven speeds cooking up.
	if app.Kind ~= "Oven" then
		return 1
	end
	local pos = app.Model:GetPivot().Position
	for _, b in session.BabyList do
		if b.Def.Id == "Sparky" and not b.Tantrum and BabyBase.mood(b) > 70 and (BabyBase.position(b) - pos).Magnitude < 10 then
			return 1.5
		end
	end
	return 1
end

function KitchenService:SetupSession(session)
	session.Appliances = {}
	session.Sources = {}
	for _, m in session:Tagged("Appliance") do
		local kind = m:GetAttribute("Kind")
		local slot = m:FindFirstChild("Slot") or (m :: Model).PrimaryPart
		if kind and slot then
			local app = {
				Model = m,
				Kind = kind,
				Slot = slot,
				State = "Idle", -- Idle | Cooking | Ready | Burnt
				Contents = {} :: { string },
				Progress = 0,
				Time = 0,
				Dish = nil :: string?,
				ReadyFor = 0,
				BurntFor = 0,
			}
			local root = (m :: Model).PrimaryPart or slot
			app.AddPrompt = ServerUtil.prompt(root, "AddIngredient", { Text = "Add", Object = kind, Need = "Kind:Ingredient", Distance = 7 })
			app.TakePrompt = ServerUtil.prompt(root, "TakeDish", { Text = "Take", Object = kind, Need = "Empty", Distance = 7 })
			session.Appliances[m] = app
			publish(app)
		end
	end
	for _, m in session:Tagged("IngredientSource") do
		local ing = m:GetAttribute("Ingredient")
		local root = (m :: Model).PrimaryPart
		if ing and root then
			local pp = ServerUtil.prompt(root, "TakeIngredient", { Text = "Take", Object = ing, Need = "Empty", Distance = 7 })
			pp:SetAttribute("Ingredient", ing)
			table.insert(session.Sources, { Model = m, Ingredient = ing, Prompt = pp, Electric = m:GetAttribute("Electric") == true, RegrowAt = 0 })
		end
	end
	for _, m in session:Tagged("AutoFeeder") do
		local root = (m :: Model).PrimaryPart
		if root then
			ServerUtil.prompt(root, "AutoFeeder", { Text = "Feed everyone", Object = "Auto Feeder", Need = "Any", Hold = 1, Distance = 7 })
		end
	end
end

function KitchenService:Tick(session, dt)
	for _, app in session.Appliances do
		local electric = Recipes.Appliances[app.Kind] and Recipes.Appliances[app.Kind].Electric
		local powered = not electric or session.PowerOn
		if app.State == "Cooking" and powered then
			app.Progress += dt * speedMult(session, app)
			app.Model:SetAttribute("Progress", math.clamp(app.Progress / app.Time, 0, 1))
			if app.Progress >= app.Time then
				app.State = "Ready"
				app.ReadyFor = 0
				publish(app)
				session:Sound("Kitchen_Ding", app.Slot.Position)
				session:Effect("Ding", { Position = app.Slot.Position })
			end
		elseif app.State == "Ready" and Recipes.Appliances[app.Kind].CanBurn and not session.Upgrades.AutoShutoff then
			app.ReadyFor += dt
			if app.ReadyFor >= Recipes.OvercookTime then
				app.State = "Burnt"
				app.Dish = "Burnt"
				app.BurntFor = 0
				publish(app)
				session:Sound("Kitchen_Overheat", app.Slot.Position)
			end
		elseif app.State == "Burnt" then
			app.BurntFor += dt
			if app.BurntFor >= Recipes.BurnToFire and not app.FireStarted then
				app.FireStarted = true
				S.HazardService:SpawnFire(session, app.Model:GetPivot().Position, app.Model)
			end
		end
	end
	-- Berry bushes regrow; electric sources follow power.
	for _, src in session.Sources do
		if src.Model:GetAttribute("Regrow") then
			if not src.Model:GetAttribute("Ready") and session.Time >= src.RegrowAt then
				src.Model:SetAttribute("Ready", true)
				local b = src.Model:FindFirstChild("Berries")
				if b then
					for _, p in b:GetChildren() do
						if p:IsA("BasePart") then
							p.Transparency = 0
						end
					end
				end
			end
			src.Prompt.Enabled = src.Model:GetAttribute("Ready") == true
		elseif src.Electric then
			src.Prompt.Enabled = session.PowerOn
		end
	end
end

function KitchenService:Init(services)
	S = services

	Interact.on("TakeIngredient", function(player, prompt, session)
		if not session or not S.ToolService:IsEmpty(player) then
			return
		end
		for _, src in session.Sources do
			if src.Prompt == prompt then
				if src.Electric and not session.PowerOn then
					ServerUtil.notify(player, "Kitchen_NoPower", "error")
					return
				end
				if src.Model:GetAttribute("Regrow") then
					if not src.Model:GetAttribute("Ready") then
						return
					end
					src.Model:SetAttribute("Ready", false)
					src.RegrowAt = session.Time + (src.Model:GetAttribute("Regrow") or 20)
					local b = src.Model:FindFirstChild("Berries")
					if b then
						for _, p in b:GetChildren() do
							if p:IsA("BasePart") then
								p.Transparency = 1
							end
						end
					end
				end
				S.ToolService:SetHeld(player, { Kind = "Ingredient", Id = src.Ingredient })
				session:Sound("Pickup", src.Model:GetPivot().Position)
				S.TutorialService:OnEvent(session, "Ingredient:" .. src.Ingredient, player)
				return
			end
		end
	end)

	Interact.on("AddIngredient", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		if not held or held.Kind ~= "Ingredient" then
			return
		end
		for _, app in session.Appliances do
			if app.AddPrompt == prompt then
				if app.State ~= "Idle" then
					return
				end
				local electric = Recipes.Appliances[app.Kind].Electric
				if electric and not session.PowerOn then
					ServerUtil.notify(player, "Kitchen_NoPower", "error")
					return
				end
				if not RecipeMatch.canAdd(app.Kind, app.Contents, held.Id, allowEvent(session)) then
					ServerUtil.notify(player, { "Kitchen_NoRecipe", held.Id, app.Kind }, "error")
					return
				end
				S.ToolService:SetHeld(player, nil)
				table.insert(app.Contents, held.Id)
				local recipe = RecipeMatch.find(app.Kind, app.Contents, allowEvent(session))
				if recipe then
					app.State = "Cooking"
					app.Dish = recipe.Dish
					app.Progress = 0
					app.Time = cookTime(session, app, recipe)
					app.FireStarted = false
					app.Model:SetAttribute("Progress", 0)
					session:Effect("Cooking", { Model = app.Model, Kind = app.Kind })
				end
				publish(app)
				session:AddAction(player)
				session:Sound("Drop", app.Slot.Position)
				S.TutorialService:OnEvent(session, "Added:" .. app.Kind, player)
				return
			end
		end
	end)

	Interact.on("TakeDish", function(player, prompt, session)
		if not session or not S.ToolService:IsEmpty(player) then
			return
		end
		for _, app in session.Appliances do
			if app.TakePrompt == prompt and (app.State == "Ready" or app.State == "Burnt") then
				local dish = app.Dish or "Burnt"
				app.State = "Idle"
				app.Contents = {}
				app.Dish = nil
				app.Model:SetAttribute("Progress", 0)
				publish(app)
				S.ToolService:SetHeld(player, { Kind = "Dish", Id = dish })
				if dish ~= "Burnt" then
					session:AddAction(player)
					S.QuestService:Track(player, "Cooked", 1)
					S.DataService:Update(player, function(d)
						d.Stats.DishesCooked += 1
					end)
				end
				S.TutorialService:OnEvent(session, "Dish:" .. dish, player)
				return
			end
		end
	end)

	Interact.on("AutoFeeder", function(player, _, session)
		if not session then
			return
		end
		if session.AutoFeederUsed then
			ServerUtil.notify(player, "Feeder_Used", "error")
			return
		end
		session.AutoFeederUsed = true
		for _, b in session.BabyList do
			if b.Needs.Hunger then
				BabyBase.change(b, "Hunger", 30)
			end
		end
		session:Notify("Toast_AutoFeeder", "good")
		session:AddAction(player)
	end)
end

return KitchenService
