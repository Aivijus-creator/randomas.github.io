--[[
	RateLimit – ne daugiau N užklausų per sekundę vienam žaidėjui.
	Naudojimas:
	  local limiter = RateLimit.new(5)
	  if not limiter:Check(player) then return end
]]

local Players = game:GetService("Players")

local RateLimit = {}
RateLimit.__index = RateLimit

local all = {}

function RateLimit.new(perSecond)
	local self = setmetatable({ PerSecond = perSecond, Records = {} }, RateLimit)
	table.insert(all, self)
	return self
end

function RateLimit:Check(player)
	local now = os.clock()
	local record = self.Records[player]
	if not record or now - record.Start >= 1 then
		self.Records[player] = { Start = now, Count = 1 }
		return true
	end
	if record.Count >= self.PerSecond then
		return false
	end
	record.Count = record.Count + 1
	return true
end

-- Debounce: ar praėjo bent `seconds` nuo paskutinio leisto veiksmo
local Debounce = {}
Debounce.__index = Debounce

function RateLimit.debounce(seconds)
	local self = setmetatable({ Seconds = seconds, Records = {} }, Debounce)
	table.insert(all, self)
	return self
end

function Debounce:Check(player)
	local now = os.clock()
	local last = self.Records[player]
	if last and now - last < self.Seconds then
		return false
	end
	self.Records[player] = now
	return true
end

Players.PlayerRemoving:Connect(function(player)
	for _, limiter in ipairs(all) do
		limiter.Records[player] = nil
	end
end)

return RateLimit
