local ADDON_NAME, NS = ...

local DEFAULTS = {
    enabled = true,
    notifyChat = true,
    notifyPopup = true,
    scanDelay = 2,
    checkEnchants = true,
    checkGems = true,
    onlyInInstance = true,
}

local PREFIX = "|cffff7eb3[MissingEnchants]|r "

local ENCHANTABLE_SLOTS = {
    [INVSLOT_CHEST]   = "Chest",
    [INVSLOT_WRIST]   = "Wrist",
    [INVSLOT_LEGS]    = "Legs",
    [INVSLOT_FEET]    = "Feet",
    [INVSLOT_HAND]    = "Hands",
    [INVSLOT_FINGER1] = "Ring 1",
    [INVSLOT_FINGER2] = "Ring 2",
    [INVSLOT_BACK]    = "Cloak",
    [INVSLOT_MAINHAND] = "Main Hand",
    [INVSLOT_OFFHAND]  = "Off Hand",
}

local ALL_GEM_SLOTS = {
    INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_CHEST,
    INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET, INVSLOT_WRIST,
    INVSLOT_HAND, INVSLOT_FINGER1, INVSLOT_FINGER2,
    INVSLOT_TRINKET1, INVSLOT_TRINKET2,
    INVSLOT_BACK, INVSLOT_MAINHAND, INVSLOT_OFFHAND,
}

local SLOT_DISPLAY = {
    [INVSLOT_HEAD]     = "Head",
    [INVSLOT_NECK]     = "Neck",
    [INVSLOT_SHOULDER] = "Shoulder",
    [INVSLOT_CHEST]    = "Chest",
    [INVSLOT_WAIST]    = "Waist",
    [INVSLOT_LEGS]     = "Legs",
    [INVSLOT_FEET]     = "Feet",
    [INVSLOT_WRIST]    = "Wrist",
    [INVSLOT_HAND]     = "Hands",
    [INVSLOT_FINGER1]  = "Ring 1",
    [INVSLOT_FINGER2]  = "Ring 2",
    [INVSLOT_TRINKET1] = "Trinket 1",
    [INVSLOT_TRINKET2] = "Trinket 2",
    [INVSLOT_BACK]     = "Cloak",
    [INVSLOT_MAINHAND] = "Main Hand",
    [INVSLOT_OFFHAND]  = "Off Hand",
}

NS.db = nil
NS.readyHandlers = {}

local function ParseItemLink(link)
    if not link then return nil end
    local payload = link:match("|H(.-)|h")
    if not payload then return nil end
    local parts = { strsplit(":", payload) }
    if parts[1] ~= "item" then return nil end
    return {
        itemID    = tonumber(parts[2]) or 0,
        enchantID = tonumber(parts[3]) or 0,
        gems = {
            tonumber(parts[4]) or 0,
            tonumber(parts[5]) or 0,
            tonumber(parts[6]) or 0,
            tonumber(parts[7]) or 0,
        },
    }
end

local function GetSocketCount(itemLink)
    local stats = (C_Item and C_Item.GetItemStats and C_Item.GetItemStats(itemLink))
        or (GetItemStats and GetItemStats(itemLink))
    if not stats then return 0 end
    local total = 0
    for k, v in pairs(stats) do
        if type(k) == "string" and k:find("^EMPTY_SOCKET_") then
            total = total + v
        end
    end
    return total
end

local function ScanEquipment()
    local missing = {}

    if NS.db.checkEnchants then
        for slotID, slotName in pairs(ENCHANTABLE_SLOTS) do
            local link = GetInventoryItemLink("player", slotID)
            if link then
                local parsed = ParseItemLink(link)
                if parsed and parsed.enchantID == 0 then
                    missing[#missing + 1] = {
                        kind = "enchant",
                        slot = slotID,
                        slotName = slotName,
                        link = link,
                    }
                end
            end
        end
    end

    if NS.db.checkGems then
        for _, slotID in ipairs(ALL_GEM_SLOTS) do
            local link = GetInventoryItemLink("player", slotID)
            if link then
                local total = GetSocketCount(link)
                if total > 0 then
                    local parsed = ParseItemLink(link)
                    local filled = 0
                    if parsed then
                        for _, gemID in ipairs(parsed.gems) do
                            if gemID ~= 0 then filled = filled + 1 end
                        end
                    end
                    if filled < total then
                        missing[#missing + 1] = {
                            kind = "gem",
                            slot = slotID,
                            slotName = SLOT_DISPLAY[slotID] or ("Slot " .. slotID),
                            link = link,
                            empty = total - filled,
                        }
                    end
                end
            end
        end
    end

    return missing
end

local function FormatLine(entry)
    if entry.kind == "enchant" then
        return string.format("  |cffff5555Missing enchant|r on |cffffd100%s|r %s",
            entry.slotName, entry.link or "")
    else
        return string.format("  |cffffaa00Empty socket x%d|r on |cffffd100%s|r %s",
            entry.empty, entry.slotName, entry.link or "")
    end
end

local function BuildReport(missing)
    local lines = {}
    for _, entry in ipairs(missing) do
        lines[#lines + 1] = FormatLine(entry)
    end
    return table.concat(lines, "\n")
end

local function Report(missing, source)
    if #missing == 0 then
        if source == "manual" then
            print(PREFIX .. "all good - no missing enchants or gems.")
        end
        return
    end

    if NS.db.notifyChat or source == "manual" then
        print(PREFIX .. string.format("%d issue(s) found:", #missing))
        print(BuildReport(missing))
    end

    if NS.db.notifyPopup and NS.ShowReport then
        NS:ShowReport(missing)
    end
end

local function RunScan(source)
    if not NS.db or not NS.db.enabled then return end
    local missing = ScanEquipment()
    Report(missing, source)
end

function NS:ScanNow(source)
    RunScan(source or "manual")
end

function NS:OnReady(fn)
    if self.db then fn() else table.insert(self.readyHandlers, fn) end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        MissingEnchantsDB = MissingEnchantsDB or {}
        for k, v in pairs(DEFAULTS) do
            if MissingEnchantsDB[k] == nil then MissingEnchantsDB[k] = v end
        end
        NS.db = MissingEnchantsDB
        for _, fn in ipairs(NS.readyHandlers) do pcall(fn) end
        NS.readyHandlers = nil
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not NS.db or not NS.db.enabled then return end
        local isInstance = IsInInstance()
        if NS.db.onlyInInstance and not isInstance then return end
        C_Timer.After(NS.db.scanDelay or 2, function()
            RunScan("auto")
        end)
    end
end)
