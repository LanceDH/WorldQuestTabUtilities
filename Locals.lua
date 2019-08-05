local addonName, addon = ...

local L = {}
local locale = GetLocale();

L["IS_AZIAN_CLIENT"]	= false

L["TALLIES"] = "Tallies"
L["UTILITY_SETTINGS"] = "Utility Settings"
L["DIRECTION_LINE"] = "Direction line"
L["DIRECTION_LINE_TT"] = "Add a line to the map showing the direction your charater is facing."

if locale == "deDE" then
end

if locale == "esES" or locale == "esMX" then
end

if locale == "ptBR" then
end

if locale == "frFR" then
end

if locale == "itIT" then
end

if locale == "ruRU" then
end

if locale == "zhCN" then
L["IS_AZIAN_CLIENT"]	= true
end

if locale == "zhTW" then
L["IS_AZIAN_CLIENT"]	= true
end

if locale == "koKR" then
L["IS_AZIAN_CLIENT"]	= true
end

addon.L = L;