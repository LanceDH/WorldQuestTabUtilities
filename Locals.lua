local addonName, addon = ...

local L = {}
local locale = GetLocale();

L["IS_AZIAN_CLIENT"]	= false

L["TALLIES"] = "Tallies"
L["UTILITY_SETTINGS"] = "Utility Settings"
L["DIRECTION_LINE"] = "Direction line"
L["DIRECTION_LINE_TT"] = "Add a line to the map showing the direction your charater is facing."
L["WHATS_NEW"] = "What's New (Utils)";
L["WHATS_NEW_TT"] = "View World Quest Tab Utilities patch notes."
L["REWARD_GRAPH"] = "Reward Graph"
L["REWARD_GRAPH_TT"] = "View a 14 day graph of rewards obrainted through world quests."

L["BOTH_FACTIONS"] = "Both Factions"
L["ACCOUNT"] = "Account"
L["REALM"] = "Realm"

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