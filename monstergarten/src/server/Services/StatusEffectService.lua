-- StatusEffectService: timed statuses on babies (Burning, Frozen, Wet, Inked, Scared, Asleep, Dark, Slimed, Angry)
-- and the automatic interactions between them (GDD 3.4).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)

local StatusEffectService = {}
local S

local unfreeze: (any, any) -> ()

local ALL = { "Burning", "Frozen", "Wet", "Inked", "Scared", "Asleep", "Dark", "Slimed", "Angry" }

local function publish(baby)
	local list = {}
	local now = os.clock()
	for _, name in ALL do
		local t = baby.Statuses[name]
		if t and t > now then
			table.insert(list, name)
		end
	end
	local s = table.concat(list, ",")
	if baby.Model:GetAttribute("Statuses") ~= s then
		baby.Model:SetAttribute("Statuses", s)
	end
end
StatusEffectService.publish = publish

function StatusEffectService:Has(baby, name: string): boolean
	return BabyBase.hasStatus(baby, name)
end

function StatusEffectService:Apply(session, baby, name: string, duration: number)
	if baby.State == "Leaving" then
		return
	end
	-- Interactions on apply.
	if name == "Burning" then
		if baby.Def.Id == "Dragling" then
			return -- fireproof
		end
		if baby.Def.Id == "Yeti" then
			BabyBase.change(baby, "Cold", -50)
			session:Effect("Steam", { Position = BabyBase.position(baby) + Vector3.new(0, 1.5, 0) })
			return -- the yeti puts the fire out
		end
		if self:Has(baby, "Wet") then
			return
		end
		if self:Has(baby, "Frozen") then
			baby.Statuses.Frozen = nil -- melts
			unfreeze(session, baby)
			S.HazardService:SpawnPuddle(session, BabyBase.position(baby), "Water", 4)
			publish(baby)
			return
		end
		if not baby.Def.Flammable then
			-- non-flammable babies just get scared by flames
			self:Apply(session, baby, "Scared", 3)
			BabyBase.change(baby, "Fun", -15)
			return
		end
		if not self:Has(baby, "Burning") then
			BabyBase.changeAll(baby, -40) -- GDD: Sprout / Mummy lose 40 on all needs
			session:Sound("Env_Fire", BabyBase.position(baby))
			session:Notify({ "Toast_BabyBurning", baby.Id }, "bad")
		end
	elseif name == "Frozen" then
		if self:Has(baby, "Burning") then
			baby.Statuses.Burning = nil
			publish(baby)
			return
		end
		if baby.Def.Id == "Yeti" then
			return
		end
		if baby.CarriedBy == nil then
			baby.Path = nil
		end
		session:Sound("Env_Freeze", BabyBase.position(baby))
		if not self:Has(baby, "Frozen") then
			session:Notify({ "Toast_BabyFrozen", baby.Id }, "bad")
		end
	elseif name == "Wet" then
		baby.Statuses.Burning = nil
	end
	local untilT = os.clock() + duration
	baby.Statuses[name] = math.max(baby.Statuses[name] or 0, untilT)
	publish(baby)
	if S.BabyService.RefreshPrompts then
		S.BabyService:RefreshPrompts(baby)
	end
end

unfreeze = function(session, baby)
	session:Effect("IceShatter", { Position = BabyBase.position(baby) })
	if S and S.BabyService then
		S.BabyService:RefreshPrompts(baby)
	end
end

function StatusEffectService:Remove(session, baby, name: string)
	if baby.Statuses[name] then
		baby.Statuses[name] = nil
		if name == "Frozen" then
			unfreeze(session, baby)
		end
		publish(baby)
	end
end

function StatusEffectService:Tick(session, dt)
	local now = os.clock()
	for _, baby in session.BabyList do
		local changed = false
		for name, t in baby.Statuses do
			if t <= now then
				baby.Statuses[name] = nil
				changed = true
				if name == "Frozen" then
					unfreeze(session, baby)
				end
			end
		end
		-- Burning drains needs and can spread (HazardService handles spreading from burning babies).
		if self:Has(baby, "Burning") then
			BabyBase.changeAll(baby, -2 * dt)
			-- burning never ends by itself for flammable babies: re-arm
			baby.Statuses.Burning = now + 5
		end
		if changed then
			publish(baby)
		end
	end
end

function StatusEffectService:Init(services)
	S = services
end

local _ = Shared

return StatusEffectService
