--!strict
-- Localized strings. Usage: Strings.get(lang, key, ...) or (client) Strings.t(key, ...)
-- Placeholders use {1}, {2}, ... Missing keys fall back to English, then to the key itself.

local en = require(script.en)
local lt = require(script.lt)

local Strings = {}
Strings.Languages = { "en", "lt" }
local tables: { [string]: { [string]: string } } = { en = en, lt = lt }
local current = "en"

local function format(s: string, args: { any }): string
	return (s:gsub("{(%d+)}", function(i)
		local v = args[tonumber(i) :: number]
		if v == nil then
			return ""
		end
		return tostring(v)
	end))
end

function Strings.get(lang: string, key: string, ...: any): string
	local t = tables[lang] or en
	local s = t[key] or en[key] or key
	if select("#", ...) > 0 then
		return format(s, { ... })
	end
	return s
end

function Strings.has(key: string): boolean
	return en[key] ~= nil
end

-- Resolve "auto" from a LocaleId like "lt-lt" or "en-us".
function Strings.resolve(setting: string?, localeId: string?): string
	if setting and setting ~= "auto" and tables[setting] then
		return setting
	end
	local loc = string.lower(localeId or "en")
	if loc:sub(1, 2) == "lt" then
		return "lt"
	end
	return "en"
end

function Strings.setLanguage(lang: string)
	if tables[lang] then
		current = lang
	end
end

function Strings.language(): string
	return current
end

function Strings.t(key: string, ...: any): string
	return Strings.get(current, key, ...)
end

-- Localized display name from a { en = ..., lt = ... } table.
function Strings.name(n: { en: string, lt: string }?): string
	if not n then
		return "?"
	end
	return (n :: any)[current] or n.en
end

-- A server message is sent as { key, args } so each client localizes it.
function Strings.msg(m: any): string
	if type(m) == "string" then
		return Strings.t(m)
	elseif type(m) == "table" then
		return Strings.t(m[1], table.unpack(m, 2))
	end
	return ""
end

return Strings
