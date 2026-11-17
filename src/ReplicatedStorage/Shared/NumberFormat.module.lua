--[[
	NumberFormat – skaičių trumpinimas.
	1 234 → "1,2K", 3 500 000 → "3,5M", 1 100 000 000 → "1,1B".
	Dešimtainis skyriklis – kablelis (lietuviškai).
]]

local NumberFormat = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- Viena dešimtainė, nukerpama (ne apvalinama), kad 999 999 nevirstų "1000K".
local function oneDecimal(value)
	local truncated = math.floor(value * 10 + 1e-9) / 10
	local text
	if truncated == math.floor(truncated) then
		text = string.format("%d", truncated)
	else
		text = string.format("%.1f", truncated)
	end
	return (string.gsub(text, "%.", ","))
end

function NumberFormat.Format(n)
	n = tonumber(n) or 0
	if n ~= n then
		return "0"
	end
	local sign = ""
	if n < 0 then
		sign = "-"
		n = -n
	end
	if n < 1000 then
		return sign .. oneDecimal(n)
	end
	local index = 0
	while n >= 1000 and index < #SUFFIXES do
		n = n / 1000
		index = index + 1
	end
	return sign .. oneDecimal(n) .. SUFFIXES[index]
end

-- Litai su valiuta: "1,2K Lt"
function NumberFormat.Money(n)
	return NumberFormat.Format(n) .. " Lt"
end

-- Laikas: 75 → "1:15", 3725 → "1:02:05"
function NumberFormat.Time(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

return NumberFormat
