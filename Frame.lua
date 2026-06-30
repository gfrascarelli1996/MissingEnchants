local ADDON_NAME, NS = ...

local FRAME_WIDTH       = 380
local TITLE_BAR_HEIGHT  = 38
local SUBTITLE_HEIGHT   = 20
local ROW_HEIGHT        = 34
local ICON_SIZE         = 26
local FOOTER_HEIGHT     = 46
local PADDING_X         = 14
local MAX_VISIBLE_ROWS  = 10

local ICON_ENCHANT = "Interface\\Icons\\Trade_Engraving"
local ICON_SOCKET  = "Interface\\Icons\\INV_Misc_Gem_Variety_02"

local COLOR_ENCHANT = { r = 1.00, g = 0.36, b = 0.36 }
local COLOR_SOCKET  = { r = 0.40, g = 0.78, b = 1.00 }
local COLOR_GOLD    = { r = 1.00, g = 0.82, b = 0.30 }

local function CreateBackdropFrame(parent)
    local f = CreateFrame("Frame", "MissingEnchantsReportFrame", parent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.05, 0.03, 0.10, 0.96)
    f:SetBackdropBorderColor(0.85, 0.70, 0.30, 1)

    return f
end

local function CreateTitleBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetPoint("TOPLEFT", PADDING_X, -10)
    bar:SetPoint("TOPRIGHT", -PADDING_X, -10)
    bar:SetHeight(TITLE_BAR_HEIGHT)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.22, 0.15, 0.05, 0.85)

    local sheen = bar:CreateTexture(nil, "ARTWORK")
    sheen:SetPoint("TOPLEFT", 0, 0)
    sheen:SetPoint("TOPRIGHT", 0, 0)
    sheen:SetHeight(TITLE_BAR_HEIGHT / 2)
    sheen:SetColorTexture(1, 0.78, 0.30, 0.10)
    sheen:SetBlendMode("ADD")

    local underline = bar:CreateTexture(nil, "OVERLAY")
    underline:SetPoint("BOTTOMLEFT", 0, 0)
    underline:SetPoint("BOTTOMRIGHT", 0, 0)
    underline:SetHeight(2)
    underline:SetColorTexture(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 1)

    local edgeL = bar:CreateTexture(nil, "OVERLAY")
    edgeL:SetPoint("TOPLEFT", 0, 0)
    edgeL:SetPoint("BOTTOMLEFT", 0, 0)
    edgeL:SetWidth(2)
    edgeL:SetColorTexture(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.85)

    local edgeR = bar:CreateTexture(nil, "OVERLAY")
    edgeR:SetPoint("TOPRIGHT", 0, 0)
    edgeR:SetPoint("BOTTOMRIGHT", 0, 0)
    edgeR:SetWidth(2)
    edgeR:SetColorTexture(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.85)

    local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("CENTER", bar, "CENTER", 0, 1)
    title:SetText("Missing Enchant")
    title:SetTextColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b)
    title:SetShadowColor(0, 0, 0, 1)
    title:SetShadowOffset(1, -1)

    return bar
end

local function CreateRow(parent, width)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, ROW_HEIGHT)

    local hi = row:CreateTexture(nil, "BACKGROUND")
    hi:SetAllPoints()
    hi:SetColorTexture(1, 0.85, 0.4, 0.08)
    hi:Hide()
    row.hi = hi

    local divider = row:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("BOTTOMLEFT", 4, 0)
    divider:SetPoint("BOTTOMRIGHT", -4, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(1, 1, 1, 0.04)

    local iconBg = row:CreateTexture(nil, "BACKGROUND")
    iconBg:SetSize(ICON_SIZE + 4, ICON_SIZE + 4)
    iconBg:SetPoint("LEFT", 4, 0)
    iconBg:SetColorTexture(0, 0, 0, 0.6)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("CENTER", iconBg)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("LEFT", iconBg, "RIGHT", 10, 0)
    label:SetJustifyH("LEFT")
    row.label = label

    local tag = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tag:SetPoint("RIGHT", -8, 0)
    tag:SetJustifyH("RIGHT")
    row.tag = tag

    row:SetScript("OnEnter", function(self)
        hi:Show()
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        hi:Hide()
        GameTooltip:Hide()
    end)

    return row
end

local function EnsureFrame()
    if NS.reportFrame then return NS.reportFrame end

    local f = CreateBackdropFrame(UIParent)
    f:SetWidth(FRAME_WIDTH)
    f:SetPoint("CENTER")

    f.titleBar = CreateTitleBar(f)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function() f:Hide() end)

    f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.subtitle:SetPoint("TOP", f.titleBar, "BOTTOM", 0, -6)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", PADDING_X, -(TITLE_BAR_HEIGHT + SUBTITLE_HEIGHT + 18))
    scroll:SetPoint("BOTTOMRIGHT", -(PADDING_X + 22), FOOTER_HEIGHT)
    f.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(FRAME_WIDTH - PADDING_X * 2 - 22, 1)
    scroll:SetScrollChild(content)
    f.content = content
    f.rowPool = {}

    local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    ok:SetSize(120, 26)
    ok:SetPoint("BOTTOM", 0, 14)
    ok:SetText("OK")
    ok:SetScript("OnClick", function() f:Hide() end)
    f.okButton = ok

    NS.reportFrame = f
    return f
end

local function PopulateRows(f, missing)
    local rowWidth = FRAME_WIDTH - PADDING_X * 2 - 22

    for _, row in ipairs(f.rowPool) do row:Hide() end

    local enchantCount, socketCount = 0, 0
    for _, entry in ipairs(missing) do
        if entry.kind == "enchant" then
            enchantCount = enchantCount + 1
        else
            socketCount = socketCount + (entry.empty or 1)
        end
    end

    local sub = ""
    if enchantCount > 0 then
        sub = sub .. string.format("|cffff5e5e%d enchant%s|r",
            enchantCount, enchantCount == 1 and "" or "s")
    end
    if socketCount > 0 then
        if sub ~= "" then sub = sub .. "  |cff666666·|r  " end
        sub = sub .. string.format("|cff66c8ff%d socket%s|r",
            socketCount, socketCount == 1 and "" or "s")
    end
    if sub == "" then sub = "|cff66ff66all clear|r" end
    f.subtitle:SetText(sub .. " |cffaaaaaamissing|r")

    for i, entry in ipairs(missing) do
        local row = f.rowPool[i]
        if not row then
            row = CreateRow(f.content, rowWidth)
            f.rowPool[i] = row
        end
        row:SetWidth(rowWidth)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:Show()

        if entry.kind == "enchant" then
            row.icon:SetTexture(ICON_ENCHANT)
            row.label:SetText(entry.slotName)
            row.label:SetTextColor(1, 1, 1)
            row.tag:SetText("ENCHANT")
            row.tag:SetTextColor(COLOR_ENCHANT.r, COLOR_ENCHANT.g, COLOR_ENCHANT.b)
        else
            row.icon:SetTexture(ICON_SOCKET)
            row.label:SetText(entry.slotName)
            row.label:SetTextColor(1, 1, 1)
            local n = entry.empty or 1
            row.tag:SetText(n > 1 and string.format("SOCKET ×%d", n) or "SOCKET")
            row.tag:SetTextColor(COLOR_SOCKET.r, COLOR_SOCKET.g, COLOR_SOCKET.b)
        end

        row.itemLink = entry.link
    end

    f.content:SetHeight(math.max(1, #missing * ROW_HEIGHT))

    local rowsShown = math.min(#missing, MAX_VISIBLE_ROWS)
    local listHeight = rowsShown * ROW_HEIGHT
    local totalHeight = 10 + TITLE_BAR_HEIGHT + SUBTITLE_HEIGHT + 8 + listHeight + FOOTER_HEIGHT
    f:SetHeight(totalHeight)
end

function NS:ShowReport(missing)
    if not missing or #missing == 0 then return end
    local f = EnsureFrame()
    PopulateRows(f, missing)
    f:Show()
    f:Raise()
end

function NS:HideReport()
    if NS.reportFrame then NS.reportFrame:Hide() end
end
