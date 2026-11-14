--!strict
-- Level / unlock math. Pure.
local Progression = require(script.Parent.Parent.Config.Progression)

local P = {}

function P.daycareLevel(totalStars: number): number
	local lvl = 1
	for _, l in Progression.DaycareLevels do
		if totalStars >= l.Stars then
			lvl = l.Level
		end
	end
	return lvl
end

-- Progress to next daycare level: (current stars into level, stars needed for next level span) or nil at max.
function P.daycareProgress(totalStars: number): (number, number?)
	local lvl = P.daycareLevel(totalStars)
	local cur = Progression.DaycareLevels[lvl]
	local nxt = Progression.DaycareLevels[lvl + 1]
	if not nxt then
		return 1, nil
	end
	return totalStars - cur.Stars, nxt.Stars - cur.Stars
end

function P.isUnlocked(totalStars: number, unlockId: string): boolean
	local lvl = P.daycareLevel(totalStars)
	for _, l in Progression.DaycareLevels do
		if l.Level <= lvl and table.find(l.Unlocks, unlockId) then
			return true
		end
	end
	-- Not listed anywhere = always unlocked (e.g. base tools).
	for _, l in Progression.DaycareLevels do
		if table.find(l.Unlocks, unlockId) then
			return false
		end
	end
	return true
end

function P.unlocksAt(level: number): { string }
	local l = Progression.DaycareLevels[level]
	return if l then l.Unlocks else {}
end

function P.xpForLevel(level: number): number
	return math.floor(Progression.XPBase * level ^ Progression.XPExponent)
end

-- Apply XP; returns new level, remaining xp, and list of levels gained.
function P.applyXP(level: number, xp: number, gained: number): (number, number, { number })
	local gainedLevels = {}
	xp += gained
	while xp >= P.xpForLevel(level) do
		xp -= P.xpForLevel(level)
		level += 1
		table.insert(gainedLevels, level)
	end
	return level, xp, gainedLevels
end

function P.titleKey(nannyLevel: number): string
	local key = Progression.NannyTitles[1].Key
	for _, t in Progression.NannyTitles do
		if nannyLevel >= t.Level then
			key = t.Key
		end
	end
	return key
end

-- Daily reward: given last claim day index and streak, compute claimable + next streak.
function P.dailyReward(lastDay: number, streak: number, today: number): (boolean, number, number)
	if today <= lastDay then
		return false, streak, 0
	end
	local newStreak = if today == lastDay + 1 then streak + 1 else 1
	local cycle = Progression.DailyRewards
	local idx = ((newStreak - 1) % #cycle) + 1
	return true, newStreak, cycle[idx]
end

return P
