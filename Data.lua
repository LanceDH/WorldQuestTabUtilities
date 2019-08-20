local addonName, addon = ...


--addon.WQT = LibStub("AceAddon-3.0"):NewAddon("WorldQuestTab");
addon.variables = {};
addon.debug = true;
local WQT_Utils = WQT_WorldQuestFrame.WQT_Utils;
local _L = addon.L;
local _V = addon.variables;

_V["HISTORY_SORT_FACTION"] = {
	[1] = _L["BOTH_FACTIONS"]
	,[2] = FACTION_ALLIANCE
	,[3] = FACTION_HORDE
}

_V["HISTORY_FILTER_SCOPE"] = {
	[1] = _L["ACCOUNT"]
	,[2] = _L["REALM"]
	,[3] = CHARACTER
}

-- This is just easier to maintain than changing the entire string every time
local _patchNotes = {
		{["version"] = "8.2.01"
			,["new"] = {
				"A line on the map indicates the direction your character is currently facing."
				,"A 'Distance' sort, which sorts the quests by distance from the player, if possible."
				,"Tallies on the side of the quest list will give an overview the total amounts of certain rewards, based on the quests currently in the list."
				,"An history of the past 14 days to keep track of the total amount of rewards you obtained."
			}
		}
	}

_V["LATEST_UPDATE"] = WQT_Utils:FormatPatchNotes(_patchNotes, "WQT Utilities");
WQT_Utils:DeepWipeTable(_patchNotes);


