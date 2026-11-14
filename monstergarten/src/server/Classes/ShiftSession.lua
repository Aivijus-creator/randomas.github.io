-- ShiftSession: all state for one running shift (one daycare copy). Several run in parallel.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.Config.GameSettings)
local Maid = require(Shared.Util.Maid)
local Signal = require(Shared.Util.Signal)
local NeedMath = require(Shared.Logic.NeedMath)
local ServerUtil = require(script.Parent.Parent.ServerUtil)

local ShiftSession = {}
ShiftSession.__index = ShiftSession

local nextId = 0

export type Options = {
	Difficulty: any,
	Solo: boolean?,
	Tutorial: boolean?,
	PreferredBabies: { string }?,
	DoorId: string?,
}

function ShiftSession.new(slot: number, model: Model, players: { Player }, opts: Options)
	nextId += 1
	local self = setmetatable({}, ShiftSession)
	self.Id = nextId
	self.Slot = slot
	self.Model = model
	self.Dynamic = model:FindFirstChild("Dynamic") or Instance.new("Folder", model)
	self.Floors = model:FindFirstChild("Floors")
	self.Players = table.clone(players)
	self.StartPlayers = #players
	self.Host = players[1]
	self.Difficulty = opts.Difficulty
	self.Solo = opts.Solo == true
	self.Tutorial = opts.Tutorial == true
	self.PreferredBabies = opts.PreferredBabies
	self.DoorId = opts.DoorId
	self.Phase = "Setup" -- Setup | Intro | Playing | Outro | Results | Ended
	self.Time = 0
	self.Duration = GameSettings.ShiftDuration
	self.TimeScale = 1
	self.Paused = false -- tutorial pauses the clock
	self.Babies = {} :: { [string]: any }
	self.BabyList = {} :: { any }
	self.Held = {} :: { [Player]: any }
	self.PowerOn = true
	self.CurtainsClosed = false
	self.Fires = {} :: { any }
	self.Puddles = {} :: { any }
	self.Trash = {} :: { any }
	self.Roots = {} :: { any }
	self.Trails = {} :: { any }
	self.Items = {} :: { any }
	self.Appliances = {} :: { [Model]: any }
	self.Furniture = {} :: { [Model]: any }
	self.Stations = {} :: { any }
	self.Actions = {} :: { [Player]: number }
	self.ActiveEvent = nil :: any
	self.EventCoins = 0
	self.EventBonus = 0
	self.EventSchedule = {} :: { any }
	self.FullMoon = false
	self.Storm = false
	self.AutoFeederUsed = false
	self.TeamUpgrades = {} :: { [string]: number }
	self.Upgrades = {} :: { [string]: boolean }
	self.Maid = Maid.new()
	self.Ended = Signal.new()
	self.Uid = 0
	self.Results = nil :: any
	self.SkipVotes = {} :: { [Player]: boolean }
	self.Choices = {} :: { [Player]: string }
	self.WarningSent = false
	return self
end

function ShiftSession:NextUid(prefix: string?): string
	self.Uid += 1
	return (prefix or "e") .. self.Id .. "_" .. self.Uid
end

function ShiftSession:HasPlayer(player: Player): boolean
	return table.find(self.Players, player) ~= nil
end

function ShiftSession:RemovePlayer(player: Player)
	local i = table.find(self.Players, player)
	if i then
		table.remove(self.Players, i)
	end
	self.Held[player] = nil
end

function ShiftSession:PlayerCount(): number
	return math.max(1, #self.Players)
end

function ShiftSession:Origin(): Vector3
	return self.Model:GetPivot().Position
end

-- In-game clock hour (7..19).
function ShiftSession:ClockHour(): number
	local t = math.clamp(self.Time / self.Duration, 0, 1)
	return GameSettings.ClockStart + (GameSettings.ClockEnd - GameSettings.ClockStart) * t
end

function ShiftSession:NeedMultiplier(): number
	return self.Difficulty.NeedDecay * NeedMath.playerScale(self:PlayerCount())
end

function ShiftSession:ChaosStrength(): number
	local s = self.Difficulty.ChaosStrength
	if self.FullMoon then
		s *= 2
	end
	return s
end

function ShiftSession:SatisfyMultiplier(): number
	return if self.FullMoon then 1.5 else 1
end

function ShiftSession:Tagged(tag: string): { Instance }
	local out = {}
	for _, inst in CollectionService:GetTagged(tag) do
		if inst:IsDescendantOf(self.Model) then
			table.insert(out, inst)
		end
	end
	return out
end

function ShiftSession:AddAction(player: Player?, amount: number?)
	if player then
		self.Actions[player] = (self.Actions[player] or 0) + (amount or 1)
	end
end

function ShiftSession:Effect(name: string, payload: any)
	ServerUtil.effect(self.Players, name, payload)
end

function ShiftSession:Sound(name: string, pos: Vector3?)
	ServerUtil.sound(self.Players, name, pos)
end

function ShiftSession:Notify(msg: any, kind: string?)
	ServerUtil.notifyAll(self.Players, msg, kind)
end

function ShiftSession:Shake(intensity: number, pos: Vector3?, radius: number?)
	ServerUtil.shake(self.Players, intensity, pos, radius)
end

function ShiftSession:RoomAt(pos: Vector3): string?
	local vols = self.Model:FindFirstChild("RoomVolumes")
	if not vols then
		return nil
	end
	for _, v in vols:GetChildren() do
		if v:IsA("BasePart") then
			local rel = v.CFrame:PointToObjectSpace(pos)
			local half = v.Size / 2
			if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z then
				return v:GetAttribute("RoomName")
			end
		end
	end
	return nil
end

function ShiftSession:IsIndoor(pos: Vector3): boolean
	local r = self:RoomAt(pos)
	return r ~= nil and r ~= "Yard" and r ~= "Outside" and r ~= "Front"
end

-- Is the daycare playing (needs decay, chaos runs)?
function ShiftSession:IsLive(): boolean
	return self.Phase == "Playing" and not self.Paused
end

function ShiftSession:Destroy()
	self.Maid:Clean()
	self.Ended:DisconnectAll()
end

return ShiftSession
