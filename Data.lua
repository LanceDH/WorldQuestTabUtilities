local addonName, addon = ...

addon.WQTU = LibStub("AceAddon-3.0"):NewAddon("WorldQuestTabUtilities");
addon.variables = {};
addon.debug = false;
local WQT_Utils = WQT_WorldQuestFrame.WQT_Utils;
local _L = addon.L;
local _V = addon.variables;
local WQTU = addon.WQTU;
local WQT_V = WQT_WorldQuestFrame.variables;

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

_V["WQTU_SETTING_LIST"] = {
	{["type"] = WQT_V["SETTING_TYPES"].checkBox, ["categoryID"] = "WQTU", ["label"] = _L["DIRECTION_LINE"], ["tooltip"] = _L["DIRECTION_LINE_TT"]
			, ["valueChangedFunc"] = function(value) 
				WQTU.settings.directionLine = value;
				WQTU_DirectLineFrame:UpdatePlayerPosition();
			end
			,["getValueFunc"] = function() return WQTU.settings.directionLine end;
			}
	,{["type"] = WQT_V["SETTING_TYPES"].subTitle, ["categoryID"] = "WQTU", ["label"] = _L["TALLIES"]}
	,{["type"] = WQT_V["SETTING_TYPES"].button, ["categoryID"] = "WQTU", ["label"] = CHECK_ALL
			, ["valueChangedFunc"] = function(value) 
				for k, v in pairs(WQTU.settings.tallies) do
					WQTU.settings.tallies[k] = true;
				end
				WQTU_TallyList:UpdateList();
			end
			}
	,{["type"] = WQT_V["SETTING_TYPES"].button, ["categoryID"] = "WQTU", ["label"] = UNCHECK_ALL
			, ["valueChangedFunc"] = function(value) 
				for k, v in pairs(WQTU.settings.tallies) do
					WQTU.settings.tallies[k] = false;
				end
				WQTU_TallyList:UpdateList();
			end
			}
}


-- This is just easier to maintain than changing the entire string every time
local _patchNotes = {
		{["version"] = "8.3.01"
			,["minor"] = 2
			,["changes"] = {
				"Tally settings are now alphabetically sorted."
				,"Clicking on the arrow tallies will now scroll through the overflow."
			}
			,["fixes"] = {
				"Fixed distances not showing when quests are sorted by distance."
				,"Fixed issues with WQTU settings."
				,"Any possibility of map possitions causing errors should be gone."
			}
		}
		,{["version"] = "8.3.01"
			,["changes"] = {
				"Compatibility with new World Quest Tab settings."
			}
		}
		,{["version"] = "8.2.02"
			,["fixes"] = {
				"Fixed more errors related to unavailable player postition data."
				,"Fixed text printed in chat when completing a world quest."
			}
		}
		,{["version"] = "8.2.01"
			,["minor"] = 2
			,["fixes"] = {
				"Fixed an error while inside instances. Because Blizzard doesn't allow position tracking inside instances, the direction line will not work while inside."
			}
		}
		,{["version"] = "8.2.01"
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


