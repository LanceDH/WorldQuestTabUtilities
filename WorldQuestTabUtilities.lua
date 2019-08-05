
local _addonName, _addon = ...;

local WQTU = LibStub("AceAddon-3.0"):NewAddon("WorldQuestTabUtilities");
local ADD = LibStub("AddonDropDown-1.0");
local _L = _addon.L;
local WQT_V;
local WQT_Utils;

local DISTANCE_FORMAT = GetLocale() == "enUS" and "%syd" or "%sm"
local SORT_DISTANCE = 50;
local MAX_NUM_TALLIES = 16;

local _playerContinent = 0;
local _playerWorldPos;
local _currentSort;
local _currentContinent = 0;
local _currentMapPlayerPos;
local _nullVector = CreateVector2D(0, 0);
local _playerFaction = GetPlayerFactionGroup();
local _playerName = UnitName("player");
local _playerRealm = GetRealmName();

local _priorities = {
	["azerite"] = 1;
	["gold"] = 2;
	["tokens"] = 3;
	["reagents"] = 4;
	["consumables"] = 5;
	["misc"] = 6;
	["currencies"] = 7;
	["reputation"] = 8;
	["honor"] = 9;
}

local _warmodeTypes = {
		["azerite"] = true;
		["gold"] = true;
		["currencies"] = true;
	}

local _tallyLabels = {
			["gold"] = WORLD_QUEST_REWARD_FILTERS_GOLD;
			["azerite"] = ITEM_QUALITY6_DESC;
			["honor"] = HONOR;
			["currencies"] = WORLD_QUEST_REWARD_FILTERS_RESOURCES;
			["reputation"] = REPUTATION;
			["reagents"] = MINIMAP_TRACKING_VENDOR_REAGENT;
			["consumables"] = BAG_FILTER_CONSUMABLES;
			["tokens"] = TOKENS;
			["misc"] = BINDING_HEADER_COMMENTATORMISC;
		}

local WQTU_DEFAULTS = {
	global = {	
		["directionLine"] = true;
		["tallies"] = {
				["gold"] = true;
				["azerite"] = true;
				["honor"] = true;
				["currencies"] = true;
				["reputation"] = true;
				["reagents"] = true;
				["consumables"] = true;
				["tokens"] = true;
				["misc"] = true;
			};
		["history"] = {};
	}
}

_rewardInfoCache = {
		["gold"] = {
			["texture"] = 133784
			,["name"] = WORLD_QUEST_REWARD_FILTERS_GOLD
			,["quality"] = 1
		}
		,["honor"] = {
			["texture"] = 1455894
			,["name"] = HONOR
			,["quality"] = 1
		}
		,["azerite"] = {
			["texture"] = 2032607
			,["name"] = "Azerite"
			,["quality"] = 1
		}
		,["currency"] = {}
		,["item"] = {}
	};
	

local _azuriteID = C_CurrencyInfo.GetAzeriteCurrencyID();
local _cachedRewards = {}

local WQTU_Utilities = {};

function WQTU_Utilities:GetRewardInfo(index)
	local category, rewardId = index:match("(%a+);?(%d*)");
	if (rewardId == "") then
		return _rewardInfoCache[category];
	end
	if (not _rewardInfoCache[category]) then return; end
	
	if (_rewardInfoCache[category][rewardId]) then
		return _rewardInfoCache[category][rewardId];
	end
	if (category == "currency") then
		local name, _, texture, _, _, _, _, quality = GetCurrencyInfo(rewardId);
		name, texture, _, quality = CurrencyContainerUtil.GetCurrencyContainerInfo(rewardId, 1, name, texture, quality); 
		_rewardInfoCache[category][rewardId] = { ["texture"] = texture, ["name"] = name, ["quality"] = quality};
	elseif (category == "item") then
		local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(rewardId);
		_rewardInfoCache[category][rewardId] = { ["texture"] = texture, ["name"] = name, ["quality"] = quality};
	end
	
	return _rewardInfoCache[category][rewardId];
end

function WQTU_Utilities:AddRewardToList(list, questId, category, rewardType, rewardId, amount, warmodeBonus)
	-- Cache the data while we're at it
	if (not _cachedRewards[questId]) then
		_cachedRewards[questId] = {};
	end
	local index = rewardId and category ..";"..rewardId or category;
	_cachedRewards[questId][index] = amount;
	
	local rewardInfo = self:GetRewardInfo(index)
	if (not rewardInfo) then return end
	
	-- Combine for tallies
	if (warmodeBonus and _warmodeTypes[rewardType]) then
		amount = amount + floor(amount * C_PvP.GetWarModeRewardBonus() / 100);
	end
	if (not list[index]) then
		list[index] = {};
		list[index].rewardType = rewardType;
		list[index].name = rewardInfo.name;
		list[index].texture = rewardInfo.texture;
		list[index].quality = rewardInfo.quality;
		list[index].amount = 0;
		list[index].quests = {};
	end
	list[index].amount = list[index].amount + amount;
	list[index].quests[questId] = true
end

function WQTU_Utilities:AddQuestRewardsToList(list, questId, includeWarMode)
	local addWardmodeBonus = includeWarMode and C_PvP.IsWarModeDesired() and C_QuestLog.QuestHasWarModeBonus(questId);
	local settings = WQTU.settings;
	if (settings.tallies.gold) then
		local gold = GetQuestLogRewardMoney(questId)
		if (gold > 0) then
			WQTU_Utilities:AddRewardToList(list, questId, "gold", "gold", nil, gold, addWardmodeBonus);
		end
	end
	if (settings.tallies.honor) then
		local honor = GetQuestLogRewardHonor(questId);
		if (honor > 0) then
			WQTU_Utilities:AddRewardToList(list, questId,"honor","honor", nil, honor, addWardmodeBonus);
		end
	end
	local numCurrency = GetNumQuestLogRewardCurrencies(questId);
	for i=1, numCurrency do
		local _, texture, numItems, currencyId = GetQuestLogRewardCurrencyInfo(i, questId);
		if (currencyId) then
			if (currencyId == _azuriteID) then
				if (settings.tallies.azerite) then
					WQTU_Utilities:AddRewardToList(list, questId, "azerite", "azerite", nil, numItems, addWardmodeBonus);
				end 
			elseif (C_CurrencyInfo.GetFactionGrantedByCurrency(currencyId)) then
				if (settings.tallies.reputation) then
					WQTU_Utilities:AddRewardToList(list, questId, "currency","reputation", currencyId, numItems, addWardmodeBonus);
				end
			elseif (settings.tallies.currencies) then
				WQTU_Utilities:AddRewardToList(list, questId, "currency", "currencies", currencyId, numItems,addWardmodeBonus);
			end
		end
	end
	for i=1, GetNumQuestLogRewards(questId) do
		local _, _, numItems, _, _, itemID = GetQuestLogRewardInfo(i, questId);
		if(itemID) then
			local name, _, rarity, ilvl, _, _, _, _, _, texture, price, itemClassID, itemSubClassID = GetItemInfo(itemID);
			if (itemClassID == 0) then
				if (itemSubClassID == 8 and price == 0 and ilvl > 100) then 
					if (settings.tallies.tokens) then
						WQTU_Utilities:AddRewardToList(list, questId, "item", "tokens", itemID, numItems, addWardmodeBonus);
					end
				elseif (settings.tallies.consumables) then
					WQTU_Utilities:AddRewardToList(list, questId, "item","consumables", itemID, numItems, addWardmodeBonus);
				end
			elseif (settings.tallies.reagents and itemClassID == 7) then
				WQTU_Utilities:AddRewardToList(list, questId, "item", "reagents", itemID, numItems, addWardmodeBonus);
			elseif (settings.tallies.misc and itemClassID == 15 and itemSubClassID == LE_ITEM_MISCELLANEOUS_OTHER) then
				WQTU_Utilities:AddRewardToList(list, questId, "item", "misc", itemID, numItems, addWardmodeBonus);
			end
		end
	end
end

function WQTU_Utilities:AddQuestRewardsToHistory(questId) 
	local rewards = _cachedRewards[questId];
	if (not rewards) then return; end

	local history = WQTU.settings.history;
	local t = date("*t", time());
	local timestamp = time({["year"] = t.year, ["month"] = t.month, ["day"] = t.day});
	local historyToday = history[timestamp];
	if (not historyToday) then
		historyToday = {};
		history[timestamp] = historyToday;
	end
	local realm = GetRealmName();
	local historyRealm = historyToday[realm];
	if (not historyRealm) then
		historyRealm = {};
		historyToday[realm] = historyRealm;
	end
	local playerName = UnitName("player");
	local historyCharacter = historyRealm[playerName];
	if (not historyCharacter) then
		historyCharacter = {["rewards"] = {}};
		historyRealm[playerName] = historyCharacter;
	end
	historyCharacter.faction = GetPlayerFactionGroup(); -- In case a panda grows up to pick a side
	
	for index, amount in pairs(rewards) do
		local storedAmount = historyCharacter.rewards[index] or 0;
		storedAmount = storedAmount + amount;
		historyCharacter.rewards[index] = storedAmount;
	end
	
	-- No longer need the cached info
	_cachedRewards[questId] = nil;
	
	for index, amount in pairs(historyCharacter.rewards) do
		print(index, amount);
	end
end

local function TallyAreaBlocked()
	return GetUIPanel("center") and GetUIPanel("center"):GetName() ~= "FlightMapFrame";
end

local function UpdateQuestDistances()
	for k, questInfo in ipairs(WQT_QuestScrollFrame.questList) do
		local continent = questInfo.mapInfo.continent; 
		local distance = math.huge;
		if (continent == _playerContinent) then 
			distance =  math.sqrt(C_TaskQuest.GetDistanceSqToQuest(questInfo.questId));
		end
		questInfo.mapInfo.distance = distance;
	end
end

WQTU_CoreMixin = {};

function WQTU_CoreMixin:OnLoad()
	local mapChild = WorldMapFrame.ScrollContainer.Child;
	self:SetParent(mapChild);
	self:SetFrameLevel(3000);
	self:ClearAllPoints();
	self:SetAllPoints();

	self:RegisterEvent("PLAYER_STOPPED_MOVING");
	self:RegisterEvent("PLAYER_STARTED_MOVING");
	self:RegisterEvent("PLAYER_CONTROL_LOST");
	self:RegisterEvent("PLAYER_CONTROL_GAINED");
	self:RegisterEvent("QUEST_TURNED_IN");
end

function WQTU_CoreMixin:OnEvent(event, ...)
	if (event == "PLAYER_STARTED_MOVING" or event == "PLAYER_STOPPED_MOVING" or event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED") then
		if (WorldMapFrame:IsShown()) then
			WQTU:UpdatePlayerPosition();
			if (not InCombatLockdown()) then
				UpdateQuestDistances();
				WQT_QuestScrollFrame:ApplySort();
				WQT_QuestScrollFrame:DisplayQuestList();
			end
		end
	
		if (not self.updateTicker and (event == "PLAYER_STARTED_MOVING" or event == "PLAYER_CONTROL_LOST")) then
			self.updateTicker = C_Timer.NewTicker(0.5, function() 
					if (WorldMapFrame:IsShown()) then
						WQTU:UpdatePlayerPosition();
						if (not InCombatLockdown()) then
							UpdateQuestDistances();
							WQT_QuestScrollFrame:ApplySort();
							WQT_QuestScrollFrame:DisplayQuestList();
						end
					end
				end);
		elseif (event == "PLAYER_STOPPED_MOVING" or event == "PLAYER_CONTROL_GAINED") then
			self.updateTicker:Cancel();
			self.updateTicker = nil;
		end
	elseif (event == "QUEST_TURNED_IN") then
		local questId = ...;
		WQTU_Utilities:AddQuestRewardsToHistory(questId)
	end
end

WQTU_TallyListMixin = {};

function WQTU_TallyListMixin:OnLoad()
	self.rewards = {};
	self.sortedRewards = {};
	
	self.framePool = CreateFramePool("FRAME", self, "WQTU_TallyTemplate");
	self.previousEntry = nil;
	self.displayIndex = 1;
end

function WQTU_TallyListMixin:ChangeIndex(delta)
	self.displayIndex = self.displayIndex + delta;
	
	self:ShowRewards();
end

function WQTU_TallyListMixin:Collapse(value)
	for frame, v in pairs(self.framePool.activeObjects) do
		local collapse = (value or frame.amount == "")
		frame:SetWidth(collapse and 26 or 75);
		frame.Amount:SetAlpha(collapse and 0 or 1);
	end
end

function WQTU_TallyListMixin:TallyRewards()
	wipe(self.sortedRewards);
	-- Reset rewards
	for k, reward in pairs(self.rewards) do
		reward.amount = 0;
		wipe(reward.quests)
	end

	-- Calculate everything
	for k, questInfo in ipairs(WQT_QuestScrollFrame.questListDisplay) do
		WQTU_Utilities:AddQuestRewardsToList(self.rewards, questInfo.questId, true)
	end

	-- Transfer relevant to sortable list
	for k, reward in pairs(self.rewards) do
		if(reward.amount > 0) then
			tinsert(self.sortedRewards, reward);
		end
	end
	
	table.sort(self.sortedRewards, function(a, b)
			local priorityA = _priorities[a.rewardType];
			local priorityB = _priorities[b.rewardType];
			if (priorityA ~= priorityB) then
				return priorityA < priorityB;
			end
			return a.name < b.name;
		end)
end

function WQTU_TallyListMixin:AddEntry(name, texture, amount, quests, quality, delta, disable)
	local entry = self.framePool:Acquire();
	local color = ITEM_QUALITY_COLORS[quality or 1].color;
	delta = delta or 0;
	
	entry.delta = delta;
	entry.name = name;
	entry.amount = amount;
	entry.quests = quests;
	entry.color = color;
	entry.Icon:SetTexture(texture);
	entry.Icon:SetDesaturated(disable);
	entry.Amount:SetText(amount);
	
	entry.BG:SetVertexColor(color:GetRGB());
	entry.BGCap:SetVertexColor(color:GetRGB());
	entry.Ring:SetVertexColor(color:GetRGB());
	
	
	if (self.previousEntry) then
		entry:SetPoint("TOPLEFT", self.previousEntry, "BOTTOMLEFT", 0, -1);
	else
		local offset = 0;
		if delta < 0 then
			offset = entry:GetHeight() + 1;
		end
		entry:SetPoint("TOPLEFT", 0, offset);
	end
	entry:Show();

	self.previousEntry = entry;
end

function WQTU_TallyListMixin:ShowRewards()
	self.framePool:ReleaseAll();
	self.previousEntry = nil;

	if (#self.sortedRewards == 0) then return; end
	
	self.displayIndex = max(self.displayIndex , 1);
	local maxIndex = max(#self.sortedRewards - MAX_NUM_TALLIES+1, 1);
	self.displayIndex = min(self.displayIndex , maxIndex);
	
	if (#self.sortedRewards  > MAX_NUM_TALLIES) then
		local numPrev = self.displayIndex - 1
		self:AddEntry("", 450907, numPrev == 0 and "" or "+"..numPrev, 1, nil, -1, self.displayIndex == 1);
	end
	
	local displayCount = 0;
	local earlyExit = false;
	local numShown = 0;
	for i = self.displayIndex, #self.sortedRewards do
		if (numShown == MAX_NUM_TALLIES) then
			earlyExit = true;
			break; 
		end
		local reward = self.sortedRewards[i];
		local amount = reward.name == WORLD_QUEST_REWARD_FILTERS_GOLD and floor(reward.amount/10000) or reward.amount;
		self:AddEntry(reward.name, reward.texture, amount, reward.quests, reward.quality);
		numShown = numShown + 1;
	end
	
	if (#self.sortedRewards  > MAX_NUM_TALLIES) then
		local numNext = #self.sortedRewards + 1 - numShown - self.displayIndex;
		self:AddEntry("", 450905,  numNext == 0 and "" or "+"..numNext, nil, 1, 1, not earlyExit);
	end
	
	self:Collapse(TallyAreaBlocked());
end

function WQTU_TallyListMixin:UpdateList()
	self:TallyRewards();
	self:ShowRewards();
end

function WQTU_TallyListMixin:HighlightQuests(quests)
	for i=1, #WQT_QuestScrollFrame.buttons do
		local button = WQT_QuestScrollFrame.buttons[i];
		button.Highlight:SetShown(quests and quests[button.questId]);
	end
end

local function AddToFilters(self, level)
	local info = ADD:CreateInfo();
	info.keepShownOnClick = true;	
	info.tooltipWhileDisabled = true;
	info.tooltipOnButton = true;
	info.motionScriptsWhileDisabled = true;
	info.disabled = nil;
	info.isNotRadio = true;
	
	local settings = WQTU.settings;
		
	if level == 2 then
		if ADD.MENU_VALUE == 0 then 
		
			info.text = _L["DIRECTION_LINE"];
			info.tooltipTitle = _L["DIRECTION_LINE"];
			info.tooltipText =  _L["DIRECTION_LINE_TT"]
			info.func = function(_, _, _, value)
					settings.directionLine = value;
					WQTY_TallyList:UpdateList();
				end
			info.checked = function() return settings.directionLine end;
			ADD:AddButton(info, level);
		
			info.tooltipTitle = nil;
			info.tooltipText = nil;
			info.hasArrow = true;
			info.notCheckable = true;
			info.text = _L["TALLIES"];
			info.value = 350;
			info.func = nil;
			ADD:AddButton(info, level)
		end
	elseif level == 3 then
		if ADD.MENU_VALUE == 350 then 
			info.notCheckable = true;
			info.text = CHECK_ALL;
			
			info.func = function()
							for k, v in pairs(settings.tallies) do
								settings.tallies[k] = true;
							end
							ADD:Refresh(self, 1, 3);
							WQTY_TallyList:UpdateList();
						end
			ADD:AddButton(info, level)
			
			info.text = UNCHECK_ALL
			info.func = function()
							for k, v in pairs(settings.tallies) do
								settings.tallies[k] = false;
							end
							ADD:Refresh(self, 1, 3);
							WQTY_TallyList:UpdateList();
						end
			ADD:AddButton(info, level)
		
			info.notCheckable = false;
		
			info.tooltipTitle = nil;
			info.tooltipText =  nil;
		
			for name, value in pairs(settings.tallies) do
				local label = _tallyLabels[name] or name;
				info.text = label;
				info.func = function(_, _, _, value)
						settings.tallies[name] = value;
						WQTY_TallyList:UpdateList();
					end
				info.checked = function() return settings.tallies[name] end;
				ADD:AddButton(info, level);
			end
		end
	end
end

local function UpdateQuestsContinent()
	for k, questInfo in ipairs(WQT_QuestScrollFrame.questList) do
		if (questInfo.questId) then
			local mapInfo = WQT_Utils:GetMapInfoForQuest(questInfo.questId);
			local mapPos = CreateVector2D(questInfo.mapInfo.mapX, questInfo.mapInfo.mapY);
			questInfo.mapInfo.continent = C_Map.GetWorldPosFromMapPos(mapInfo.mapID, mapPos);
		end
	end
	WQT_QuestScrollFrame:UpdateQuestList();
end

function WQTU:UpdatePlayerPosition()
	local map = C_Map.GetBestMapForUnit("player");
	local position = C_Map.GetPlayerMapPosition(map, "player");
	_playerContinent, _playerWorldPos = C_Map.GetWorldPosFromMapPos(map, position);
	_currentMapPlayerPos = select(2, C_Map.GetMapPosFromWorldPos(_playerContinent, _playerWorldPos, WorldMapFrame.mapID));
end

function WQTU:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("WQTUDB", WQTU_DEFAULTS, true);
	self.settings = self.db.global;

	WQT_V = WQT_WorldQuestFrame.variables;
	WQT_V["WQT_SORT_OPTIONS"][SORT_DISTANCE] = "Distance";
	WQT_V["SORT_OPTION_ORDER"][SORT_DISTANCE] = { "distance", "rewardType", "rewardQuality", "rewardAmount", "canUpgrade", "rewardId", "seconds", "title" };
	WQT_V["SORT_FUNCTIONS"]["distance"] = function(a, b)
			if (a.mapInfo.distance ~= b.mapInfo.distance) then
				return a.mapInfo.distance < b.mapInfo.distance;
			end
		end
	
	WQT_Utils = WQT_WorldQuestFrame.WQT_Utils;
	_currentSort = WQT_Utils:GetSetting("sortBy");
	
	if (LDHDebug) then
		LDHDebug:Monitor(_addonName);
	end
end

function WQTU:OnEnable()
	local map = C_Map.GetBestMapForUnit("player")
	local position = C_Map.GetPlayerMapPosition(map, "player")
	_playerContinent, _playerWorldPos = C_Map.GetWorldPosFromMapPos(map, position);
	
	WQT_WorldQuestFrame:RegisterCallback("InitFilter", AddToFilters);
	WQT_WorldQuestFrame:RegisterCallback("FilterQuestList", function() WQTY_TallyList:UpdateList() end);
	WQT_WorldQuestFrame:RegisterCallback("ListButtonUpdate", function(button) 
			if (WQT_Utils:GetSetting("sortBy") == SORT_DISTANCE and WQT_Utils:GetSetting("list", "zone")) then
				local text = UNKNOWN;
				local distance = button.info.mapInfo.distance;
				WQT_Utils:GetSetting("list", "zone")
				if (distance and distance < math.huge) then
					text =  DISTANCE_FORMAT:format(floor(distance));
				end
				
				local showFactionIcon = WQT_Utils:GetSetting("list", "factionIcon");
				local showTypeIcon = WQT_Utils:GetSetting("list", "typeIcon");
				local fullTime = WQT_Utils:GetSetting("list", "fullTime");
				local extraSpace = showFactionIcon and 0 or 14;
				extraSpace = extraSpace + (showTypeIcon and 0 or 14);
				local timeWidth = extraSpace + (fullTime and 70 or 60);
				local zoneWidth = extraSpace + (fullTime and 80 or 90);
				button.Time:SetWidth(timeWidth)
				button.Extra:SetWidth(zoneWidth)
				
				button.Extra:SetText(text);
			end
		end);
	WQT_WorldQuestFrame:RegisterCallback("SortChanged", function(category) 
			_currentSort = category; 
			if (_currentSort == SORT_DISTANCE) then
				UpdateQuestsContinent();
				UpdateQuestDistances();
				WQT_QuestScrollFrame:ApplySort();
				WQT_QuestScrollFrame:DisplayQuestList();
			end
		end);
	WQT_WorldQuestFrame:RegisterCallback("QuestsLoaded", function() 
			if (_currentSort == SORT_DISTANCE) then
				UpdateQuestsContinent();
				UpdateQuestDistances();
				WQT_QuestScrollFrame:ApplySort();
				WQT_QuestScrollFrame:DisplayQuestList();
			end
		end);

	hooksecurefunc("ShowUIPanel", function(frame) 
			if (not WorldMapFrame:IsShown()) then return end
			WQTY_TallyList:Collapse(TallyAreaBlocked());
		end);

	hooksecurefunc("HideUIPanel", function(frame) 
			if (not WorldMapFrame:IsShown()) then return end
			WQTY_TallyList:Collapse(TallyAreaBlocked());
		end);

	hooksecurefunc(WorldMapFrame, "OnMapChanged", function() 
			_currentContinent = C_Map.GetWorldPosFromMapPos(WorldMapFrame.mapID, _nullVector);
			WQTU:UpdatePlayerPosition();
		end)
		
	WorldMapFrame:HookScript("OnUpdate", function(self) 
			WQTU_DirectionLine:SetAlpha(0);
			if (not WQTU.settings.directionLine) then return; end
			
			if (_currentContinent == _playerContinent and _currentMapPlayerPos) then
				WQTU_DirectionLine:SetAlpha(1);
				local mapScale = WQTU_CoreFrame:GetEffectiveScale();
				local facing = GetPlayerFacing();
				local scale = 0.5/mapScale;
				local degr = deg(facing)+90;
				local mapChild = WorldMapFrame.ScrollContainer.Child;
				local w, h = mapChild:GetSize();
				local startX = _currentMapPlayerPos.x * w;
				local startY = (1-_currentMapPlayerPos.y )* h;
				
				WQTU_DirectionLine:ClearAllPoints();
				WQTU_DirectionLine:SetStartPoint("BOTTOMLEFT", startX, startY);
				WQTU_DirectionLine:SetEndPoint("BOTTOMLEFT", mapChild, startX + cos(degr)*12000*scale, startY + sin(degr)*12000*scale);
				WQTU_DirectionLine:SetThickness(scale * 2);
			end
		end)
end

SLASH_WQTU1 = '/wqtu';
local function slashcmd(msg, editbox)
	local totals = {};

	for timeStamp, dateInfo in pairs(WQTU.settings.history) do
		print(date("%x", timeStamp));
		for realm, realmInfo in pairs(dateInfo) do
			print("", realm)
			for character, charInfo in pairs(realmInfo) do
				print("", "", character, charInfo.faction)
				for index, amount in pairs(charInfo.rewards) do
					local rewardInfo = WQTU_Utilities:GetRewardInfo(index);
					local total = totals[index] or 0;
					totals[index] = total + amount;
					if (index == "gold") then
						amount = floor(amount / 10000);
					end
					print("", "", "|T"..rewardInfo.texture..":0|t", rewardInfo.name, amount);
				end
			end
		end
	end
	
	print("Totals:")
	for index, amount in pairs(totals) do
		local rewardInfo = WQTU_Utilities:GetRewardInfo(index);
		if (index == "gold") then
			amount = floor(amount / 10000);
		end
		print("|T"..rewardInfo.texture..":0|t", rewardInfo.name, amount);
	end
end
SlashCmdList["WQTU"] = slashcmd

