local ADDON_NAME, NS = ...

local function BuildPanel()
    local category, layout = Settings.RegisterVerticalLayoutCategory(ADDON_NAME)
    NS.settingsCategory = category

    local function AddCheckbox(varKey, label, tooltip)
        local setting = Settings.RegisterAddOnSetting(
            category,
            ADDON_NAME .. "_" .. varKey,
            varKey,
            MissingEnchantsDB,
            Settings.VarType.Boolean,
            label,
            MissingEnchantsDB[varKey]
        )
        Settings.CreateCheckbox(category, setting, tooltip)
        return setting
    end

    local function AddSlider(varKey, label, tooltip, minV, maxV, step)
        local setting = Settings.RegisterAddOnSetting(
            category,
            ADDON_NAME .. "_" .. varKey,
            varKey,
            MissingEnchantsDB,
            Settings.VarType.Number,
            label,
            MissingEnchantsDB[varKey]
        )
        local options = Settings.CreateSliderOptions(minV, maxV, step)
        Settings.CreateSlider(category, setting, options, tooltip)
        return setting
    end

    AddCheckbox("enabled", "Enable MissingEnchants",
        "Master switch. Disables all scanning when off.")
    AddCheckbox("onlyInInstance", "Scan only on instance entry",
        "When on, the automatic scan runs only when you enter a dungeon, raid, or M+. When off, it also runs in the open world.")
    AddCheckbox("checkEnchants", "Check enchants",
        "Report items in enchantable slots that have no enchant.")
    AddCheckbox("checkGems", "Check gem sockets",
        "Report items that have one or more empty gem sockets.")
    AddCheckbox("notifyChat", "Report in chat",
        "Print the list of issues in the chat window.")
    AddCheckbox("notifyPopup", "Show popup",
        "Open a dismissable popup with the list of issues.")
    AddSlider("scanDelay", "Scan delay (seconds)",
        "Wait this long after entering a zone before scanning, so your equipment has fully loaded.", 0, 10, 1)

    Settings.RegisterAddOnCategory(category)
end

SLASH_MISSINGENCHANTS1 = "/missingench"
SLASH_MISSINGENCHANTS2 = "/menc"
SlashCmdList["MISSINGENCHANTS"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" or msg == "scan" or msg == "check" then
        NS:ScanNow("manual")
    elseif msg == "config" or msg == "options" or msg == "settings" then
        if NS.settingsCategory then
            Settings.OpenToCategory(NS.settingsCategory:GetID())
        end
    else
        print("|cffff7eb3[MissingEnchants]|r commands: /menc (scan now), /menc config (open settings)")
    end
end

NS:OnReady(function() BuildPanel() end)
