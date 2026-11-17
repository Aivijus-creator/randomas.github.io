--[[
	Calc – visos ekonomikos formulės VIENOJE vietoje (naudoja serveris ir klientas).

	ctx (kontekstas) – laikini dalykai, kurių nėra išsaugotuose duomenyse:
	  ctx.eventDropMult  – eventų dropper'ių greičio daugiklis (Bulvių lietus = 2)
	  ctx.eventMoneyMult – eventų pinigų daugiklis (Joninės = 2)
	  ctx.doublePass, ctx.fastPass, ctx.grannyPass, ctx.vip – gamepass'ai
	  ctx.group – žaidėjas yra grupėje
	  ctx.boost – aktyvus ×3 boost'as
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Config")
local ProductLines = require(Config:WaitForChild("ProductLines"))
local Settings = require(Config:WaitForChild("Settings"))
local Monetization = require(Config:WaitForChild("Monetization"))

local Lines = ProductLines.Lines
local EMPTY = {}

local Calc = {}

----------------------------------------------------------------------
-- Linijos
----------------------------------------------------------------------
function Calc.IsLineUnlocked(data, lineId)
	local line = Lines[lineId]
	if not line then
		return false
	end
	if not line.UnlockedBy then
		return true
	end
	if data.purchases[line.UnlockedBy] then
		return true
	end
	for _, reward in ipairs(Settings.Rebirth.Rewards) do
		if reward.Type == "UnlockLine" and reward.Line == lineId and (data.rebirths or 0) >= reward.At then
			return true
		end
	end
	return false
end

-- Kitas pirkinys linijoje (griežta eilė). nil – viskas nupirkta arba linija užrakinta.
function Calc.GetNextPurchase(data, lineId)
	if not Calc.IsLineUnlocked(data, lineId) then
		return nil
	end
	for _, purchase in ipairs(Lines[lineId].Purchases) do
		if not data.purchases[purchase.Id] then
			local skip = purchase.Type == "Unlock" and Calc.IsLineUnlocked(data, purchase.Unlocks)
			if not skip then
				return purchase
			end
		end
	end
	return nil
end

-- Kas linijoje pastatyta
function Calc.GetLineState(data, lineId)
	local line = Lines[lineId]
	local state = { Unlocked = false, Droppers = 0, HasBase = false, Upgraders = {} }
	if not Calc.IsLineUnlocked(data, lineId) then
		return state
	end
	state.Unlocked = true
	state.Droppers = line.StartDroppers
	state.HasBase = line.StartsWithBase
	for _, purchase in ipairs(line.Purchases) do
		if data.purchases[purchase.Id] then
			if purchase.Type == "Dropper" then
				state.Droppers = state.Droppers + 1
				if purchase.IncludesBase then
					state.HasBase = true
				end
			elseif purchase.Type == "Base" then
				state.HasBase = true
			elseif purchase.Type == "Upgrader" then
				table.insert(state.Upgraders, purchase)
			end
		end
	end
	return state
end

function Calc.ApplyUpgrade(value, purchase)
	if purchase.Op == "Mul" then
		return value * purchase.Amount
	elseif purchase.Op == "Add" then
		return value + purchase.Amount
	end
	return value
end

-- Gatavo produkto vertė (be daugiklių) pagal nupirktus upgrader'ius
function Calc.GetFinalValue(data, lineId)
	local value = Lines[lineId].Item.Value
	for _, purchase in ipairs(Calc.GetLineState(data, lineId).Upgraders) do
		value = Calc.ApplyUpgrade(value, purchase)
	end
	return value
end

----------------------------------------------------------------------
-- Močiutės
----------------------------------------------------------------------
function Calc.GetGrannyLevel(data, lineId, ctx)
	if not Calc.IsLineUnlocked(data, lineId) then
		return 0
	end
	ctx = ctx or EMPTY
	local level = (data.grannies and data.grannies[lineId]) or 0
	if ctx.grannyPass and level < 1 then
		level = 1
	end
	for _, reward in ipairs(Settings.Rebirth.Rewards) do
		if reward.Type == "FreeGranny" and reward.Line == lineId and (data.rebirths or 0) >= reward.At and level < 1 then
			level = 1
		end
	end
	return math.min(level, #Settings.Grannies.Levels)
end

function Calc.GetGrannyPrice(lineId, level)
	local info = Settings.Grannies.Levels[level]
	if not info then
		return nil
	end
	return info.PriceFactor * Lines[lineId].BasePrice
end

-- Linijos vertės daugiklis: močiutės bonusas × linijos ValueMultiplier (vėlesnės linijos duoda daugiau)
function Calc.GetLineValueBonus(data, lineId, ctx)
	local level = Calc.GetGrannyLevel(data, lineId, ctx)
	local info = Settings.Grannies.Levels[level]
	return (1 + ((info and info.ValueBonus) or 0)) * (Lines[lineId].ValueMultiplier or 1)
end

----------------------------------------------------------------------
-- Dropper'ių intervalas (visi greičio daugikliai čia)
-- Grąžina: intervalas (s), vertės daugiklis (jei intervalas būtų < MinDropInterval)
----------------------------------------------------------------------
function Calc.GetDropInterval(data, lineId, ctx)
	ctx = ctx or EMPTY
	local multiplier = 1

	local speedLevel = (data.globalUpgrades and data.globalUpgrades.DropperSpeed) or 0
	multiplier = multiplier * (1 - Settings.GlobalUpgrades.DropperSpeedReduction) ^ speedLevel

	local grannyLevel = Calc.GetGrannyLevel(data, lineId, ctx)
	if grannyLevel > 0 then
		multiplier = multiplier * (1 - Settings.Grannies.Levels[grannyLevel].IntervalReduction)
	end

	if ctx.fastPass then
		multiplier = multiplier * (1 - Monetization.GamePasses.FastDroppers.IntervalReduction)
	end

	if ctx.eventDropMult and ctx.eventDropMult > 0 then
		multiplier = multiplier / ctx.eventDropMult
	end

	local interval = Lines[lineId].Item.Interval * multiplier
	local valueFactor = 1
	if interval < Settings.MinDropInterval then
		valueFactor = Settings.MinDropInterval / interval
		interval = Settings.MinDropInterval
	end
	return interval, valueFactor
end

----------------------------------------------------------------------
-- Pinigų daugikliai
-- Pardavimo kaina = vertė × rebirth × event × gamepass × kiti bonusai
----------------------------------------------------------------------
function Calc.GetRebirthMultiplier(rebirths)
	return 1 + Settings.Rebirth.MultiplierPerRebirth * (rebirths or 0)
end

function Calc.GetRebirthCost(rebirths)
	return Settings.Rebirth.FirstCost * Settings.Rebirth.CostMultiplier ^ (rebirths or 0)
end

function Calc.GetIncomeMultiplier(data, ctx)
	ctx = ctx or EMPTY
	local multiplier = (Settings.IncomeMultiplier or 1) * Calc.GetRebirthMultiplier(data.rebirths)
	multiplier = multiplier * (ctx.eventMoneyMult or 1)
	if ctx.doublePass then
		multiplier = multiplier * Monetization.GamePasses.DoubleMoney.Multiplier
	end
	if ctx.boost then
		multiplier = multiplier * Monetization.Products.Boost3.Multiplier
	end
	local bonus = 0
	if data.globalUpgrades then
		for _, decor in ipairs(Settings.GlobalUpgrades.Decor) do
			if data.globalUpgrades[decor.Id] then
				bonus = bonus + decor.Bonus
			end
		end
		for level = 1, (data.globalUpgrades.Gate or 0) do
			local gate = Settings.GlobalUpgrades.Gate[level]
			bonus = bonus + ((gate and gate.Bonus) or 0)
		end
	end
	if ctx.vip then
		bonus = bonus + Monetization.GamePasses.VIP.IncomeBonus
	end
	if ctx.group then
		bonus = bonus + Monetization.GroupBonus
	end
	return multiplier * (1 + bonus)
end

-- Apytikslės pajamos per sekundę (UI, offline pajamos, prizai)
function Calc.GetIncomePerSecond(data, ctx)
	local total = 0
	for _, lineId in ipairs(ProductLines.Order) do
		local state = Calc.GetLineState(data, lineId)
		if state.Unlocked and state.HasBase and state.Droppers > 0 then
			local interval, valueFactor = Calc.GetDropInterval(data, lineId, ctx)
			local value = Calc.GetFinalValue(data, lineId) * valueFactor * Calc.GetLineValueBonus(data, lineId, ctx)
			total = total + value * state.Droppers / interval
		end
	end
	return total * Calc.GetIncomeMultiplier(data, ctx)
end

----------------------------------------------------------------------
-- Titulai
----------------------------------------------------------------------
function Calc.GetTitleKey(rebirths)
	local key = Settings.Rebirth.Titles[1].Key
	for _, title in ipairs(Settings.Rebirth.Titles) do
		if (rebirths or 0) >= title.At then
			key = title.Key
		end
	end
	return key
end

function Calc.GetNextReward(rebirths)
	for _, reward in ipairs(Settings.Rebirth.Rewards) do
		if reward.At > (rebirths or 0) then
			return reward
		end
	end
	return nil
end

function Calc.GetSkin(rebirths)
	local skin = "Default"
	for _, reward in ipairs(Settings.Rebirth.Rewards) do
		if reward.Type == "Skin" and (rebirths or 0) >= reward.At then
			skin = reward.Skin
		end
	end
	return skin
end

----------------------------------------------------------------------
-- Bendri patobulinimai
----------------------------------------------------------------------
function Calc.IsShelfUnlocked(data)
	return Calc.IsLineUnlocked(data, Settings.GlobalUpgrades.UnlockLine)
end

-- Grąžina sąrašą { {Id=..., Price=..., Kind=...} } – ką dabar galima pirkti lentynoje
function Calc.GetAvailableGlobalUpgrades(data)
	local list = {}
	if not Calc.IsShelfUnlocked(data) then
		return list
	end
	local level = data.globalUpgrades.DropperSpeed or 0
	local nextSpeed = Settings.GlobalUpgrades.DropperSpeed[level + 1]
	if nextSpeed then
		table.insert(list, { Id = nextSpeed.Id, Price = nextSpeed.Price, Kind = "DropperSpeed", Level = level + 1, Slot = 1 })
	end
	-- Vartai – kitas lygis
	local gateLevel = data.globalUpgrades.Gate or 0
	local nextGate = Settings.GlobalUpgrades.Gate[gateLevel + 1]
	if nextGate then
		table.insert(list, { Id = nextGate.Id, Price = nextGate.Price, Kind = "Gate", Level = gateLevel + 1, Slot = 3 })
	end
	-- Puošmenos – po vieną: kita atsiranda nupirkus ankstesnę
	for _, decor in ipairs(Settings.GlobalUpgrades.Decor) do
		if not data.globalUpgrades[decor.Id] then
			table.insert(list, { Id = decor.Id, Price = decor.Price, Kind = "Decor", Slot = 2 })
			break
		end
	end
	return list
end

return Calc
