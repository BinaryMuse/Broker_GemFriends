local tablet = AceLibrary("Tablet-2.0")
local frame = CreateFrame("frame")

local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject("GemFriends", {
	type = "data source",
	icon = "Interface\\AddOns\\Broker_GemFriends\\icon"
})


-----------------------
--  Helper Routines  --
-----------------------

local function inGroup(name)
	if GetNumRaidMembers() > 0 and UnitInRaid(name) or GetNumPartyMembers() > 0 and UnitInParty(name) or nil then return true end
end

local function player_name_to_index(name)
	local lookupname
	for i = 1,GetNumFriends() do
		lookupname,_ = GetFriendInfo(i)
		if lookupname == name then return i end
	end
end

local function guild_name_to_index(name)
	local lookupname
	for i=1,GetNumGuildMembers() do
		lookupname,_ = GetGuildRosterInfo(i)
		if lookupname == name then return i end
	end
end

local function levelcolor(level)
	local color = GetQuestDifficultyColor(level)
	return string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255)
end

local colors = {}
for class,color in pairs(RAID_CLASS_COLORS) do colors[class] = string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) end


---------------------
--  Update button  --
---------------------

local function update_Broker()
	ShowFriends()

	local online = 0

	local NumFriends = GetNumFriends()
	local bnet_friends, bnet_onlineFriends = BNGetNumFriends()
	for i = 1,NumFriends do if select(5, GetFriendInfo(i)) then online = online + 1 end end
	local friendlies = string.format("%d/%d - %d/%d", online, NumFriends, bnet_onlineFriends, bnet_friends) or ""


	dataobj.text = friendlies
end



----------------------------
--  If names are clicked  --
----------------------------

local function click(name, type)
	if IsAltKeyDown() then
		InviteUnit(name)
	else
		SetItemRef("player:"..name, "|Hplayer:"..name.."|h["..name.."|h", "LeftButton")
	end
end


------------------------
--      Tooltip!      --
------------------------

function dataobj:updateTooltip()

	--------------
	--  Header  --
	--------------

	tablet:SetHint("|cffeda55fClick|r to open the friends panel. |cffeda55fClick|r a line to whisper a player. |cffeda55fAlt-Click|r a line to invite to a group.")

	tablet:SetTitle("GemFriends")


	--------------------------
	--  Begin friends list  --
	--------------------------

	local cat = tablet:AddCategory('id', 'friends', 'columns', 5, 'text', "")
	cat:AddLine(
		'text', "NAME",
		'text2', "LEVEL",
		'text3', "ZONE"
	)

	local online

	for i = 1,GetNumFriends() do
		local name, level, class, area, connected, status, note = GetFriendInfo(i)

		if connected then
			online = true
			cat:AddLine(
				'func', click,
				'arg1', name,
				'hasCheck',
				true,
				'checked',
				inGroup(name),
				'checkIcon',"Interface\Buttons\UI-CheckBox-Check",
				'text', status..string.format("|cff%s%s",colors[class:gsub(" ", ""):upper()] or "ffffff", name),
				'text2', "|cff"..levelcolor(level)..level.."|r",
				'text3', area
			)
		end
	end

	if GetNumFriends() == 0 then cat:AddLine('text',"No friends.")
	elseif not online then cat:AddLine('text',"No Friends Online") end

	cat:AddLine('text', ' ')

	cat:AddLine(
		'text', "NAME",
		'text2', "GAME",
		'text3', "CHARACTER",
		'text4', "LOCATION",
		'text5', "BROADCAST"
	)

  local bnet_numFriends, bnet_onlineFriends = BNGetNumFriends()
	for i = 1, bnet_numFriends, 1 do
        presence, givenName, surname, toonName, toonId, client, online, lastOnline, isAFK, isDND, broadcastText, noteText = BNGetFriendInfo(i)
        if online then
            hasFocus, toonName, client, realm, faction, race, class, guild, zoneName, level, gameText = BNGetToonInfo(toonId)
            if client == "WoW" then
                toonName = toonName .. " (" .. "|cff"..levelcolor(level)..level.."|r" .. " " .. race .. " " .. string.format("|cff%s%s",colors[class:gsub(" ", ""):upper()] or "ffffff", class) .. ")"
            end
            status = ""
            if isAFK then
                status = "<AFK> "
            end
            if isDND then
                status = "<DND> "
            end
            --playersOnline = playersOnline + 1
            --playersShown = playersShown + 1
            --table_insert(players, getplayertable(givenName .. surname, -1, toonName or UNKNOWN, UNKNOWN, UNKNOWN, status, broadcastText)
            cat:AddLine(
                'func', click,
                'arg1', givenName.." "..surname,
                'hasCheck',
                true,
                'checked',
                false,
                'checkIcon',"Interface\Buttons\UI-CheckBox-Check",
                'text', status..givenName.." "..surname,
                'text2', client,
                'text3', toonName or "???",
                'text4', gameText,
                'text5', broadcastText
            )
        end
	end




end


----------------------
--  Attach tooltip  --
----------------------

local function registertip(tip)
	if not tablet:IsRegistered(tip) then
		tablet:Register(tip,
			'children', function() dataobj:updateTooltip() end,
			'clickable', true,
			'point', function(frame)
					if frame:GetTop() > GetScreenHeight() / 2 then
						local x = frame:GetCenter()
						if x < GetScreenWidth() / 3 then
	                                                return "TOPLEFT", "BOTTOMLEFT"
                                        	elseif x < GetScreenWidth() * 2 / 3 then
	                                                return "TOP", "BOTTOM"
                                        	else
	                                                return "TOPRIGHT", "BOTTOMRIGHT"
                                        	end
                                	else
	                                        local x = frame:GetCenter()
                                        	if x < GetScreenWidth() / 3 then
	                                                return "BOTTOMLEFT", "TOPLEFT"
                                        	elseif x < GetScreenWidth() * 2 / 3 then
	                                                return "BOTTOM", "TOP"
                                        	else
	                                                return "BOTTOMRIGHT", "TOPRIGHT"
                                        	end
                                	end
				end,
			'dontHook', true
		)
	end
end


------------------------------------------
--  Click to open friend / guild panel  --
------------------------------------------

function dataobj.OnClick()
		ToggleFriendsFrame(1) --friends
end



---------------------
--  Event Section  --
---------------------

function dataobj.OnLeave() end
function dataobj.OnEnter(self)
	registertip(self)
	tablet:Open(self)
end

frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local DELAY = 15  --  Update every 15 seconds
local elapsed = DELAY-5

frame:SetScript("OnUpdate",
	function (self, el)
		elapsed = elapsed + el
		if elapsed >= DELAY then
			elapsed = 0
			update_Broker()
		end
	end
)
