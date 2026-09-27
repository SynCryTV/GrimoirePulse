local ANIM_DURATION = 0.35
local LUST_DURATION  = 40
local isActive       = false
local hideTimer      = nil
local animTimer      = nil
local lustStartTime  = nil
local previewHandle  = nil
local previewingRow  = nil
local moveMode       = false
local lustSoundHandle = nil

local HORDE_SOUND_PATH     = "Interface\\AddOns\\GrimoirePulse\\Sounds\\Horde.ogg"
local HORDE_SOUND_DURATION = 12.264

-- Alle Sound-Auswahlmöglichkeiten verwenden denselben Horde-Sound.
-- Die korrekte Laufzeit verhindert, dass die Vorschau vorzeitig beendet wird.
local SOUNDS = {
    { name = "Standard",   isFaction = true },
}

local FACTION_SOUNDS = {
    Horde    = { path = HORDE_SOUND_PATH, duration = HORDE_SOUND_DURATION },
    Alliance = { path = HORDE_SOUND_PATH, duration = HORDE_SOUND_DURATION },
}

local CHANNELS = {
    { name = "Gesamtlautstärke", key = "Master"   },
    { name = "Soundeffekte",     key = "SFX"      },
    { name = "Umgebung",         key = "Ambience" },
    { name = "Dialog",           key = "Dialog"   },
}

local LUST_BUFF_IDS = {
    [2825]    = "Bloodlust",
    [32182]   = "Heroism",
    [80353]   = "Time Warp",
    [264667]  = "Primal Rage",
    [390386]  = "Fury of the Aspects",
    [466904]  = "Harrier's Cry",
    [1243972] = "Void-touched Drums",
}

local SATED_IDS = {
    [57724]  = true,
    [57723]  = true,
    [80354]  = true,
    [390435] = true,
    [264689] = true,
}

local FACTION_TEXTURES = {
    Horde    = "Interface\\AddOns\\GrimoirePulse\\textures\\horde.png",
    Alliance = "Interface\\AddOns\\GrimoirePulse\\textures\\alliance.png",
}

local ANIM_LIST = {
    { name = "dancing", path = "Interface\\AddOns\\GrimoirePulse\\textures\\dancing.png" },
    { name = "ani01",   path = "Interface\\GrimoirePulse\\ani01.png" },
    { name = "ani02",   path = "Interface\\GrimoirePulse\\ani02.png" },
    { name = "ani03",   path = "Interface\\GrimoirePulse\\ani03.png" },
}
local FROG_ICON_W     = 50
local FROG_FRAMES     = 32
local FROG_COLS       = 8
local FROG_ROWS       = 8
local FROG_FRAME_DUR  = 0.04
local frogAnimTimer   = nil
local frogFrame       = 0

local FACTION_COLORS = {
    Horde    = { 1, 0.2, 0.2 },
    Alliance = { 0.3, 0.6, 1 },
}

local FACTION_ICON_W = {
    Horde    = 55,
    Alliance = 63,
}

local BAR_TEXTURES = {
    { name = "Blizzard",          path = "Interface\\TargetingFrame\\UI-StatusBar" },
    { name = "Blizzard (Skills)", path = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar" },
    { name = "Blizzard (XP)",     path = "Interface\\TargetingFrame\\UI-StatusBar2" },
    { name = "Blizzard (Cast)",   path = "Interface\\FrameXML\\UI-StatusBar" },
}

GrimoirePulseLustDB = GrimoirePulseLustDB or {}
GrimoirePulseLustDB.minimap = GrimoirePulseLustDB.minimap or {}

local ApplyBarSettings
local UpdateToggle
local UpdateTexToggle
local UpdateTextToggle
local UpdateFrogToggle
local UpdateBarSettingsUI
local UpdateRows
local UpdateBarToggle
local UpdateDirBtns
local UpdateAnimBtn
local UpdateMinimapToggle
local mm = {}

local ICON_SIZE = 90

local function SetMinimapButtonShown(shown)
    GrimoirePulseLustDB.minimap.hide = not shown
    local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LibDBIcon and LibDBIcon:IsRegistered("GrimoirePulse") then
        if shown then
            LibDBIcon:Show("GrimoirePulse")
        else
            LibDBIcon:Hide("GrimoirePulse")
        end
    end
    if UpdateMinimapToggle then UpdateMinimapToggle() end
end

local display = CreateFrame("Frame", nil, UIParent)
display:SetSize(ICON_SIZE, ICON_SIZE)
display:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
display:SetScale(1.0)

local iconClip = CreateFrame("Frame", nil, display)
iconClip:SetWidth(ICON_SIZE)
iconClip:SetHeight(ICON_SIZE)
iconClip:SetPoint("BOTTOM", display, "BOTTOM", 0, 0)
iconClip:SetClipsChildren(true)

local factionIcon = iconClip:CreateTexture(nil, "ARTWORK")
factionIcon:SetSize(ICON_SIZE, ICON_SIZE)
factionIcon:SetPoint("BOTTOM", iconClip, "BOTTOM", 0, 0)

local timerFrame = CreateFrame("Frame", nil, UIParent)
timerFrame:SetSize(120, 44)
timerFrame:SetPoint("TOP", display, "BOTTOM", 0, -2)
local lustLabel = timerFrame:CreateFontString(nil, "OVERLAY")
lustLabel:SetPoint("TOP", timerFrame, "TOP", 0, 0)
lustLabel:SetFont("Fonts\\2002.TTF", 11, "OUTLINE")
lustLabel:SetText("Lust")
lustLabel:SetTextColor(1, 1, 1)
local timerText = timerFrame:CreateFontString(nil, "OVERLAY")
timerText:SetPoint("TOP", lustLabel, "BOTTOM", 0, -1)
timerText:SetFont("Fonts\\2002.TTF", 20, "OUTLINE")
timerText:SetTextColor(1, 1, 1)

display:Hide()
timerFrame:Hide()

local lustBar = CreateFrame("Frame", nil, UIParent)
lustBar:SetSize(GrimoirePulseLustDB.barWidth or 260, GrimoirePulseLustDB.barHeight or 16)
lustBar:SetPoint("TOP", timerFrame, "BOTTOM", 0, -6)

local lustBarBg = lustBar:CreateTexture(nil, "BACKGROUND")
lustBarBg:SetAllPoints()
lustBarBg:SetColorTexture(0.04, 0.04, 0.08, 1)

local lustBarBorder = CreateFrame("Frame", nil, lustBar, "BackdropTemplate")
lustBarBorder:SetAllPoints()
lustBarBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})
lustBarBorder:SetBackdropBorderColor(0.17, 0.67, 0.67, 1)

local lustBarFill = CreateFrame("StatusBar", nil, lustBar)
lustBarFill:SetPoint("TOPLEFT",     lustBar, "TOPLEFT",     1, -1)
lustBarFill:SetPoint("BOTTOMRIGHT", lustBar, "BOTTOMRIGHT", -1, 1)
lustBarFill:SetMinMaxValues(0, 1)
lustBarFill:SetValue(1)
lustBarFill:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
lustBarFill:SetStatusBarColor(0.0, 0.8, 0.8, 1)

local lustBarTimerFrame = CreateFrame("Frame", nil, lustBar)
lustBarTimerFrame:SetAllPoints(lustBar)
lustBarTimerFrame:SetFrameLevel(lustBar:GetFrameLevel() + 10)
local lustBarTimer = lustBarTimerFrame:CreateFontString(nil, "OVERLAY")
lustBarTimer:SetPoint("CENTER", lustBarTimerFrame, "CENTER", 0, 0)
lustBarTimer:SetFont("Fonts\\2002.TTF", 12, "OUTLINE")
lustBarTimer:SetTextColor(1, 1, 1)
lustBarTimer:SetText("")

ApplyBarSettings = function()
    local bw  = GrimoirePulseLustDB.barWidth     or 260
    local bh  = GrimoirePulseLustDB.barHeight    or 16
    local dir = GrimoirePulseLustDB.barDirection or "LEFT"
    local isVertical = dir == "UP" or dir == "DOWN"
    if isVertical then
        lustBar:SetSize(bh, bw)
        lustBarFill:SetOrientation("VERTICAL")
        lustBarFill:SetReverseFill(dir == "UP")
    else
        lustBar:SetSize(bw, bh)
        lustBarFill:SetOrientation("HORIZONTAL")
        lustBarFill:SetReverseFill(dir == "RIGHT")
    end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local texPath
    if LSM then
        texPath = LSM:Fetch("statusbar", GrimoirePulseLustDB.barTexture or "Blizzard")
    end
    if not texPath then
        for _, t in ipairs(BAR_TEXTURES) do
            if t.name == (GrimoirePulseLustDB.barTexture or "Blizzard") then texPath = t.path break end
        end
    end
    if not texPath then texPath = BAR_TEXTURES[1].path end
    lustBarFill:SetStatusBarTexture(texPath)
    local c = GrimoirePulseLustDB.barColor or { 0.0, 0.8, 0.8 }
    lustBarFill:SetStatusBarColor(c[1], c[2], c[3], 1)
    local fontSize = math.max(8, math.floor((GrimoirePulseLustDB.barHeight or 16) * 0.75))
    lustBarTimer:SetFont("Fonts\\2002.TTF", fontSize, "OUTLINE")
end

lustBar:Hide()

local function StopFrogAnim()
    if frogAnimTimer then frogAnimTimer:Cancel() frogAnimTimer = nil end
end

local function StartFrogAnim()
    StopFrogAnim()
    frogFrame = 0
    local cw = 1 / FROG_COLS
    local ch = 1 / FROG_ROWS
    frogAnimTimer = C_Timer.NewTicker(FROG_FRAME_DUR, function()
        local col = frogFrame % FROG_COLS
        local row = math.floor(frogFrame / FROG_COLS)
        factionIcon:SetTexCoord(col * cw, (col + 1) * cw, row * ch, (row + 1) * ch)
        frogFrame = (frogFrame + 1) % FROG_FRAMES
    end)
end

local function HideAlert()
    if lustSoundHandle then StopSound(lustSoundHandle) lustSoundHandle = nil end
    if hideTimer then hideTimer:Cancel() hideTimer = nil end
    if animTimer then animTimer:Cancel() animTimer = nil end
    StopFrogAnim()
    lustStartTime = nil
    lustBarTimer:SetText("")
    if not moveMode then
        display:Hide()
        timerFrame:Hide()
        lustBar:Hide()
    end
end

local function StartZoomAnim()
    display:Show()
    if GrimoirePulseLustDB.timerTextEnabled then
        timerFrame:Show()
    else
        timerFrame:Hide()
    end
    local targetScale = GrimoirePulseLustDB.iconScale
    display:SetScale(targetScale * 0.1)
    factionIcon:SetAlpha(0)
    timerText:SetAlpha(0)
    local start = GetTime()
    if animTimer then animTimer:Cancel() end
    animTimer = C_Timer.NewTicker(0.016, function(t)
        local prog = math.min((GetTime() - start) / ANIM_DURATION, 1)
        local ease = 1 - (1 - prog) * (1 - prog)
        display:SetScale(targetScale * (0.1 + ease * 0.9))
        factionIcon:SetAlpha(ease)
        timerText:SetAlpha(ease)
        if prog >= 1 then
            display:SetScale(targetScale)
            factionIcon:SetAlpha(1)
            timerText:SetAlpha(1)
            t:Cancel()
        end
    end)
end

local function GetFactionSound()
    local faction = UnitFactionGroup("player")
    return FACTION_SOUNDS[faction] or FACTION_SOUNDS["Horde"]
end

local function GetSoundPath(name)
    if name == "Standard" then
        return GetFactionSound().path
    end
    for _, s in ipairs(SOUNDS) do
        if s.name == name then return s.path end
    end
end

local function GetSoundDuration(name)
    if name == "Standard" then
        return GetFactionSound().duration
    end
    for _, s in ipairs(SOUNDS) do
        if s.name == name then return s.duration end
    end
    return 5.0
end

local function ShowBloodlustAlert(playSound)
    lustStartTime = GetTime()
    if not GrimoirePulseLustDB.frogMode then
        iconClip:SetHeight(ICON_SIZE)
    end

    local faction = UnitFactionGroup("player")
    local col = FACTION_COLORS[faction]   or FACTION_COLORS["Horde"]

    local useFrog = GrimoirePulseLustDB.frogMode
    local animIdx = GrimoirePulseLustDB.animIndex or 1
    local tex = useFrog and ANIM_LIST[animIdx].path or (FACTION_TEXTURES[faction] or FACTION_TEXTURES["Horde"])
    local iw  = useFrog and math.floor(FROG_ICON_W * (GrimoirePulseLustDB.frogScale or 2.5)) or (FACTION_ICON_W[faction] or ICON_SIZE)
    local ih  = useFrog and (FROG_ICON_W * (GrimoirePulseLustDB.frogScale or 2.5)) or ICON_SIZE
    factionIcon:SetSize(iw, ih)
    iconClip:SetWidth(iw)
    iconClip:SetHeight(ih)
    display:SetWidth(iw)
    display:SetHeight(ih)
    if GrimoirePulseLustDB.textureEnabled then
        factionIcon:SetTexture(tex)
        if useFrog then
            factionIcon:SetTexCoord(0, 1/FROG_COLS, 0, 1/FROG_ROWS)
            StartFrogAnim()
        else
            factionIcon:SetTexCoord(0, 1, 0, 1)
            StopFrogAnim()
        end
        factionIcon:SetAlpha(1)
        display:SetWidth(iw)
        display:Show()
    else
        factionIcon:SetTexture(nil)
        StopFrogAnim()
        display:SetWidth(1)
    end
    timerText:SetTextColor(col[1], col[2], col[3])
    lustLabel:SetTextColor(col[1], col[2], col[3])
    timerText:SetText(string.format("%.1f", LUST_DURATION + 0.0))

    if hideTimer then hideTimer:Cancel() end
    StartZoomAnim()

    if GrimoirePulseLustDB.barEnabled then
        lustBarFill:SetValue(1)
        lustBar:Show()
    end

    if playSound ~= false then
        local path = GetSoundPath(GrimoirePulseLustDB.sound)
        if path then
            local _, handle = PlaySoundFile(path, GrimoirePulseLustDB.channel)
            lustSoundHandle = handle
        end
    end

    hideTimer = C_Timer.NewTimer(LUST_DURATION, function()
        HideAlert()
    end)
end

local CHECK_INTERVAL = 0.2
local elapsed        = 0
local justZoned      = false
local stableCount    = 0
local STABLE_NEEDED  = 10

local function CheckSated()
    for id in pairs(SATED_IDS) do
        if C_UnitAuras.GetPlayerAuraBySpellID(id) then return true end
    end
    return false
end

local pollFrame = CreateFrame("Frame", "GrimoirePulseFrame")
pollFrame:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed < CHECK_INTERVAL then return end
    elapsed = 0

    local active = CheckSated()

    if justZoned then
        isActive    = active
        stableCount = stableCount + 1
        if stableCount >= STABLE_NEEDED then
            justZoned = false
        end
        return
    end

    if active and not isActive then
        if GrimoirePulseLustDB.enabled then ShowBloodlustAlert() end
    end
    isActive = active

    if lustStartTime then
        local passed    = GetTime() - lustStartTime
        local remaining = math.max(LUST_DURATION - passed, 0)
        if not GrimoirePulseLustDB.frogMode then
            local clipH = math.max(math.floor((remaining / LUST_DURATION) * ICON_SIZE), 1)
            iconClip:SetHeight(clipH)
        end
        timerText:SetText(string.format("%.1f", remaining))
        if GrimoirePulseLustDB.barEnabled then
            lustBarFill:SetValue(remaining / LUST_DURATION)
            lustBarTimer:SetText(string.format("%.1f", remaining))
        end
        if remaining <= 0 then
            HideAlert()
        end
    end
end)

local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneFrame:RegisterEvent("ADDON_LOADED")
zoneFrame:RegisterEvent("PLAYER_DEAD")
zoneFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "GrimoirePulse" then
        -- Older releases stored additional selections; the combined build keeps one standard sound.
        GrimoirePulseLustDB.sound             = "Standard"
        GrimoirePulseLustDB.channel           = GrimoirePulseLustDB.channel           or "Master"
        if GrimoirePulseLustDB.enabled     == nil then GrimoirePulseLustDB.enabled     = true  end
        GrimoirePulseLustDB.posX              = GrimoirePulseLustDB.posX              or 0
        GrimoirePulseLustDB.posY              = GrimoirePulseLustDB.posY              or 200
        GrimoirePulseLustDB.iconScale         = GrimoirePulseLustDB.iconScale         or 1.0
        if GrimoirePulseLustDB.textureEnabled == nil then GrimoirePulseLustDB.textureEnabled = true  end
        if GrimoirePulseLustDB.timerTextEnabled == nil then GrimoirePulseLustDB.timerTextEnabled = true  end
        if GrimoirePulseLustDB.frogMode      == nil then GrimoirePulseLustDB.frogMode      = false end
        if GrimoirePulseLustDB.frogScale     == nil then GrimoirePulseLustDB.frogScale     = 2.5  end
        if GrimoirePulseLustDB.animIndex     == nil then GrimoirePulseLustDB.animIndex     = 1    end
        if GrimoirePulseLustDB.animSpeed     == nil then GrimoirePulseLustDB.animSpeed     = 1.0  end
        if GrimoirePulseLustDB.barEnabled  == nil then GrimoirePulseLustDB.barEnabled  = false end
        GrimoirePulseLustDB.barHeight         = GrimoirePulseLustDB.barHeight         or 16
        GrimoirePulseLustDB.barWidth          = GrimoirePulseLustDB.barWidth          or 260
        GrimoirePulseLustDB.barDirection      = GrimoirePulseLustDB.barDirection      or "LEFT"
        GrimoirePulseLustDB.barTexture        = GrimoirePulseLustDB.barTexture        or "Blizzard"
        GrimoirePulseLustDB.barColor          = GrimoirePulseLustDB.barColor          or { 0.0, 0.8, 0.8 }

        display:ClearAllPoints()
        if GrimoirePulseLustDB.posAnchor == "BOTTOMLEFT" then
            display:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", GrimoirePulseLustDB.posX, GrimoirePulseLustDB.posY)
        else
            display:SetPoint("CENTER", UIParent, "CENTER", GrimoirePulseLustDB.posX, GrimoirePulseLustDB.posY)
        end
        display:SetScale(GrimoirePulseLustDB.iconScale)
        if GrimoirePulseLustDB.barPosAnchor == "BOTTOMLEFT" then
            lustBar:ClearAllPoints()
            lustBar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", GrimoirePulseLustDB.barPosX, GrimoirePulseLustDB.barPosY)
        end

        ApplyBarSettings()
        UpdateRows()
        UpdateToggle()
        UpdateTexToggle()
        UpdateTextToggle()
        UpdateFrogToggle()
        UpdateBarToggle()
        UpdateDirBtns()
        UpdateBarSettingsUI()
        if UpdateMinimapToggle then UpdateMinimapToggle() end
        local iw = math.floor(FROG_ICON_W * (GrimoirePulseLustDB.frogScale or 2.5))
        factionIcon:SetSize(iw, iw)
        iconClip:SetWidth(iw)
        iconClip:SetHeight(iw)
        display:SetSize(iw, iw)
        return
    end
    if event == "PLAYER_DEAD" then
        HideAlert()
        isActive = CheckSated()
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        justZoned   = true
        stableCount = 0
        ApplyBarSettings()
        if UpdateAnimBtn then UpdateAnimBtn() end
        if SetAnimSpeed then SetAnimSpeed(GrimoirePulseLustDB.animSpeed or 1.0) end

        local inInstance = IsInInstance()
        if not inInstance then
            HideAlert()
            isActive = CheckSated()
        end
    end
end)

local W, H = 300, 930
local sf = CreateFrame("Frame", "GrimoirePulseSettings", UIParent)
sf:SetSize(W, H)
sf:SetPoint("CENTER")
sf:SetFrameStrata("DIALOG")
sf:SetMovable(true)
sf:EnableMouse(true)
sf:RegisterForDrag("LeftButton")
sf:SetScript("OnDragStart", sf.StartMoving)
sf:SetScript("OnDragStop", sf.StopMovingOrSizing)
sf:Hide()

local bg = sf:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0.05, 0.05, 0.08, 0.97)

local border = CreateFrame("Frame", nil, sf, "BackdropTemplate")
border:SetAllPoints()
border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})
border:SetBackdropBorderColor(0.2, 0.2, 0.35, 1)

local titleBg = sf:CreateTexture(nil, "ARTWORK")
titleBg:SetSize(W, 28)
titleBg:SetPoint("TOPLEFT", 0, 0)
titleBg:SetColorTexture(0.08, 0.08, 0.16, 1)

local titleLine = sf:CreateTexture(nil, "ARTWORK")
titleLine:SetSize(W, 1)
titleLine:SetPoint("TOPLEFT", 0, -28)
titleLine:SetColorTexture(0.2, 0.2, 0.35, 1)

local titleText = sf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOP", 0, -8)
titleText:SetText("GrimoirePulse · Kampfrausch")
titleText:SetTextColor(0.4, 0.78, 1)

local closeBtn = CreateFrame("Button", nil, sf)
closeBtn:SetSize(18, 18)
closeBtn:SetPoint("TOPRIGHT", -6, -5)
local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
closeBg:SetAllPoints()
closeBg:SetColorTexture(0.15, 0.15, 0.25, 1)
local closeBorder = CreateFrame("Frame", nil, closeBtn, "BackdropTemplate")
closeBorder:SetAllPoints()
closeBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})
closeBorder:SetBackdropBorderColor(0.3, 0.3, 0.5, 1)
local closeIcon = closeBtn:CreateTexture(nil, "ARTWORK")
closeIcon:SetSize(10, 10)
closeIcon:SetPoint("CENTER")
closeIcon:SetTexture("Interface\\Buttons\\UI-StopButton")
closeBtn:SetScript("OnEnter", function() closeBg:SetColorTexture(0.3, 0.1, 0.1, 1) end)
closeBtn:SetScript("OnLeave", function() closeBg:SetColorTexture(0.15, 0.15, 0.25, 1) end)
closeBtn:SetScript("OnClick", function()
    if previewHandle then StopSound(previewHandle) previewHandle = nil previewingRow = nil end
    sf:Hide()
end)

mm.hdrBtn = CreateFrame("Button", nil, sf)
mm.hdrBtn:SetSize(90, 18)
mm.hdrBtn:SetPoint("TOPLEFT", 6, -6)

mm.hdrTxt = mm.hdrBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mm.hdrTxt:SetAllPoints()
mm.hdrTxt:SetJustifyH("LEFT")

mm.hdrBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Minimap-Symbol")
    GameTooltip:AddLine(GrimoirePulseLustDB.minimap.hide and "Klicken zum Anzeigen" or "Klicken zum Ausblenden", 0.7, 0.7, 0.9)
    GameTooltip:Show()
end)
mm.hdrBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
mm.hdrBtn:SetScript("OnClick", function()
    SetMinimapButtonShown(GrimoirePulseLustDB.minimap.hide == true)
end)

local toggleBg = sf:CreateTexture(nil, "BACKGROUND")
toggleBg:SetSize(W, 28)
toggleBg:SetPoint("TOPLEFT", 0, -29)
toggleBg:SetColorTexture(0.07, 0.07, 0.12, 1)

local toggleLine = sf:CreateTexture(nil, "ARTWORK")
toggleLine:SetSize(W, 1)
toggleLine:SetPoint("TOPLEFT", 0, -57)
toggleLine:SetColorTexture(0.2, 0.2, 0.35, 1)

local toggleLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
toggleLabel:SetPoint("TOPLEFT", 16, -43)
toggleLabel:SetText("Aktivieren")
toggleLabel:SetTextColor(0.4, 0.78, 1)

local toggleStatusTxt = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
toggleStatusTxt:SetPoint("TOPRIGHT", -50, -43)

local toggleBtn = CreateFrame("Button", nil, sf)
toggleBtn:SetSize(36, 18)
toggleBtn:SetPoint("TOPRIGHT", -10, -39)

local toggleTrack = toggleBtn:CreateTexture(nil, "BACKGROUND")
toggleTrack:SetAllPoints()
toggleTrack:SetColorTexture(0.15, 0.15, 0.25, 1)

local toggleTrackBorder = CreateFrame("Frame", nil, toggleBtn, "BackdropTemplate")
toggleTrackBorder:SetAllPoints()
toggleTrackBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})

local toggleKnob = toggleBtn:CreateTexture(nil, "OVERLAY")
toggleKnob:SetSize(14, 14)

UpdateToggle = function()
    local on = GrimoirePulseLustDB.enabled
    toggleTrack:SetColorTexture(on and 0.1 or 0.15, on and 0.3 or 0.15, on and 0.1 or 0.25, 1)
    toggleTrackBorder:SetBackdropBorderColor(on and 0.3 or 0.2, on and 0.7 or 0.2, on and 0.3 or 0.35, 1)
    toggleKnob:SetColorTexture(on and 0.3 or 0.4, on and 0.8 or 0.4, on and 0.3 or 0.5, 1)
    toggleKnob:ClearAllPoints()
    if on then
        toggleKnob:SetPoint("RIGHT", toggleBtn, "RIGHT", -2, 0)
    else
        toggleKnob:SetPoint("LEFT", toggleBtn, "LEFT", 2, 0)
    end
    toggleStatusTxt:SetText(on and "|cff44cc44ON|r" or "|cffff4444OFF|r")
end

toggleBtn:SetScript("OnClick", function()
    GrimoirePulseLustDB.enabled = not GrimoirePulseLustDB.enabled
    UpdateToggle()
end)

local hdrSound = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hdrSound:SetPoint("TOPLEFT", 16, -66)
hdrSound:SetText("Sound")
hdrSound:SetTextColor(0.4, 0.78, 1)

local hdrPreview = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hdrPreview:SetPoint("TOPRIGHT", -16, -66)
hdrPreview:SetText("Vorschau")
hdrPreview:SetTextColor(0.4, 0.78, 1)

local hdrLine = sf:CreateTexture(nil, "ARTWORK")
hdrLine:SetSize(W - 20, 1)
hdrLine:SetPoint("TOPLEFT", 10, -80)
hdrLine:SetColorTexture(0.2, 0.2, 0.35, 1)

local rows   = {}
local chRows = {}

local function StopPreview()
    if previewHandle then StopSound(previewHandle) previewHandle = nil end
    previewingRow = nil
    HideAlert()
end

UpdateRows = function()
    for _, row in ipairs(rows) do
        local sel = row.soundName == GrimoirePulseLustDB.sound
        row.rowBg:SetColorTexture(sel and 0.05 or 0, sel and 0.18 or 0, sel and 0.05 or 0, sel and 0.6 or 0)
        row.cbBorder:SetBackdropBorderColor(sel and 0.3 or 0.3, sel and 0.8 or 0.3, sel and 0.3 or 0.3, 1)
        row.cbCheck:SetShown(sel)
        local isPlaying = previewingRow == row
        row.prevBg:SetColorTexture(isPlaying and 0.2 or 0.1, isPlaying and 0.05 or 0.1, isPlaying and 0.05 or 0.18, 1)
        row.prevBorder:SetColorTexture(isPlaying and 0.6 or 0.2, isPlaying and 0.2 or 0.2, isPlaying and 0.2 or 0.35, 1)
        row.prevTxt:SetText(isPlaying and "stop" or "play")
        row.prevTxt:SetTextColor(isPlaying and 1 or 0.4, isPlaying and 0.4 or 0.78, isPlaying and 0.4 or 1)
    end
    for _, cr in ipairs(chRows) do
        local sel = cr.key == GrimoirePulseLustDB.channel
        cr.rowBg:SetColorTexture(sel and 0.05 or 0, sel and 0.18 or 0, sel and 0.05 or 0, sel and 0.6 or 0)
        cr.cbBorder:SetBackdropBorderColor(sel and 0.3 or 0.3, sel and 0.8 or 0.3, sel and 0.3 or 0.3, 1)
        cr.cbCheck:SetShown(sel)
    end
end

for i, sound in ipairs(SOUNDS) do
    local row = CreateFrame("Frame", nil, sf)
    row:SetSize(W - 20, 26)
    row:SetPoint("TOPLEFT", 10, -80 - (i * 28))
    row.soundName = sound.name

    local rowBg = row:CreateTexture(nil, "BACKGROUND")
    rowBg:SetAllPoints()
    rowBg:SetColorTexture(0, 0, 0, 0)
    row.rowBg = rowBg

    if i > 1 then
        local sep = row:CreateTexture(nil, "ARTWORK")
        sep:SetSize(W - 20, 1)
        sep:SetPoint("TOPLEFT", 0, 0)
        sep:SetColorTexture(0.12, 0.12, 0.22, 1)
    end

    local cbFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    cbFrame:SetSize(14, 14)
    cbFrame:SetPoint("LEFT", 6, 0)
    cbFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left=1, right=1, top=1, bottom=1 },
    })
    cbFrame:SetBackdropColor(0.08, 0.08, 0.12, 1)
    cbFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    row.cbBorder = cbFrame

    local cbCheck = cbFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbCheck:SetPoint("CENTER", 0, 1)
    cbCheck:SetText("|cff44cc44v|r")
    cbCheck:Hide()
    row.cbCheck = cbCheck

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", 26, 0)
    label:SetText(sound.name)
    label:SetTextColor(1, 1, 1)

    local prevBtn = CreateFrame("Button", nil, row)
    prevBtn:SetSize(60, 18)
    prevBtn:SetPoint("RIGHT", 0, 0)

    local prevBg = prevBtn:CreateTexture(nil, "BACKGROUND")
    prevBg:SetAllPoints()
    prevBg:SetColorTexture(0.1, 0.1, 0.18, 1)
    row.prevBg = prevBg

    local prevBorderTex = prevBtn:CreateTexture(nil, "ARTWORK")
    prevBorderTex:SetAllPoints()
    prevBorderTex:SetColorTexture(0.2, 0.2, 0.35, 1)
    row.prevBorder = prevBorderTex

    local prevInner = prevBtn:CreateTexture(nil, "OVERLAY")
    prevInner:SetPoint("TOPLEFT", 1, -1)
    prevInner:SetPoint("BOTTOMRIGHT", -1, 1)
    prevInner:SetColorTexture(0.1, 0.1, 0.18, 1)

    local prevTxt = prevBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevTxt:SetAllPoints()
    prevTxt:SetText("play")
    prevTxt:SetTextColor(0.4, 0.78, 1)
    row.prevTxt = prevTxt

    prevBtn:SetScript("OnClick", function()
        if previewingRow == row then
            StopPreview()
            UpdateRows()
        else
            if previewHandle then StopSound(previewHandle) previewHandle = nil end
            HideAlert()
            local playPath, playDur
            if sound.isFaction then
                playPath = GetFactionSound().path
                playDur  = GetFactionSound().duration
            elseif sound.isCustomRandom then
                playPath = CUSTOM_RANDOM_PATHS[math.random(1, #CUSTOM_RANDOM_PATHS)]
                playDur  = sound.duration
            else
                playPath = sound.path
                playDur  = sound.duration
            end
            local _, handle = PlaySoundFile(playPath, GrimoirePulseLustDB.channel)
            previewHandle = handle
            previewingRow = row
            ShowBloodlustAlert(false)
            local savedHandle = handle
            C_Timer.NewTimer(playDur + 0.3, function()
                if previewingRow == row then
                    if savedHandle then StopSound(savedHandle) end
                    previewHandle = nil
                    previewingRow = nil
                    HideAlert()
                    UpdateRows()
                end
            end)
            UpdateRows()
        end
    end)

    local clickFrame = CreateFrame("Button", nil, row)
    clickFrame:SetSize(W - 20 - 70, 26)
    clickFrame:SetPoint("LEFT", 0, 0)
    clickFrame:SetScript("OnClick", function()
        GrimoirePulseLustDB.sound = sound.name
        UpdateRows()
    end)

    rows[i] = row
end

local soundSectionBottom = -80 - (#SOUNDS * 28) - 26

local customNoticeBg = sf:CreateTexture(nil, "BACKGROUND")
customNoticeBg:SetSize(W - 20, 36)
customNoticeBg:SetPoint("TOPLEFT", 10, soundSectionBottom)
customNoticeBg:SetColorTexture(0.06, 0.06, 0.10, 1)

local customNoticeAccent = sf:CreateTexture(nil, "ARTWORK")
customNoticeAccent:SetSize(2, 36)
customNoticeAccent:SetPoint("TOPLEFT", 10, soundSectionBottom)
customNoticeAccent:SetColorTexture(0.53, 0.47, 0.19, 1)

local customNoticeLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
customNoticeLabel:SetPoint("TOPLEFT", 18, soundSectionBottom - 6)
customNoticeLabel:SetText("Eigene Sounds")
customNoticeLabel:SetTextColor(0.75, 0.56, 0.19)

local customNoticePath = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
customNoticePath:SetPoint("TOPLEFT", 18, soundSectionBottom - 20)
customNoticePath:SetText("Sounds\\Custom\\ (nach /reload)")
customNoticePath:SetTextColor(0.54, 0.60, 0.48)

local customNoticeBorder = sf:CreateTexture(nil, "ARTWORK")
customNoticeBorder:SetSize(W - 20, 1)
customNoticeBorder:SetPoint("TOPLEFT", 10, soundSectionBottom - 36)
customNoticeBorder:SetColorTexture(0.2, 0.2, 0.35, 1)

local chanStart = soundSectionBottom - 50

local hdrChanLine = sf:CreateTexture(nil, "ARTWORK")
hdrChanLine:SetSize(W - 20, 1)
hdrChanLine:SetPoint("TOPLEFT", 10, chanStart)
hdrChanLine:SetColorTexture(0.2, 0.2, 0.35, 1)

local hdrChan = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hdrChan:SetPoint("TOPLEFT", 16, chanStart - 10)
hdrChan:SetText("Audio-Kanal")
hdrChan:SetTextColor(0.4, 0.78, 1)

local chanLineBot = sf:CreateTexture(nil, "ARTWORK")
chanLineBot:SetSize(W - 20, 1)
chanLineBot:SetPoint("TOPLEFT", 10, chanStart - 24)
chanLineBot:SetColorTexture(0.2, 0.2, 0.35, 1)

local colW = (W - 20) / 2

local chanMidLine = sf:CreateTexture(nil, "ARTWORK")
chanMidLine:SetSize(1, 54)
chanMidLine:SetPoint("TOPLEFT", 10 + colW, chanStart - 52)
chanMidLine:SetColorTexture(0.2, 0.2, 0.35, 1)

for i, ch in ipairs(CHANNELS) do
    local col    = (i - 1) % 2
    local rowIdx = math.floor((i - 1) / 2)
    local cr     = CreateFrame("Button", nil, sf)
    cr:SetSize(colW, 26)
    cr:SetPoint("TOPLEFT", 10 + col * colW, chanStart - 52 - (rowIdx * 27))
    cr.key = ch.key

    local rowBg = cr:CreateTexture(nil, "BACKGROUND")
    rowBg:SetAllPoints()
    rowBg:SetColorTexture(0, 0, 0, 0)
    cr.rowBg = rowBg

    local sep = cr:CreateTexture(nil, "ARTWORK")
    sep:SetSize(colW, 1)
    sep:SetPoint("TOPLEFT", 0, 0)
    sep:SetColorTexture(0.2, 0.2, 0.35, 1)

    local cbFrame = CreateFrame("Frame", nil, cr, "BackdropTemplate")
    cbFrame:SetSize(14, 14)
    cbFrame:SetPoint("LEFT", 6, 0)
    cbFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left=1, right=1, top=1, bottom=1 },
    })
    cbFrame:SetBackdropColor(0.08, 0.08, 0.12, 1)
    cbFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    cr.cbBorder = cbFrame

    local cbCheck = cbFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbCheck:SetPoint("CENTER", 0, 1)
    cbCheck:SetText("|cff44cc44v|r")
    cbCheck:Hide()
    cr.cbCheck = cbCheck

    local label = cr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", 26, 0)
    label:SetText(ch.name)
    label:SetTextColor(1, 1, 1)

    cr:SetScript("OnClick", function()
        GrimoirePulseLustDB.channel = ch.key
        UpdateRows()
    end)

    chRows[i] = cr
end

local moveSectionY   = chanStart - 52 - 54 - 20
local texToggleSectY = moveSectionY - 40

local moveDivLine = sf:CreateTexture(nil, "ARTWORK")
moveDivLine:SetSize(W, 1)
moveDivLine:SetPoint("TOPLEFT", 0, moveSectionY)
moveDivLine:SetColorTexture(0.2, 0.2, 0.35, 1)

local moveLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
moveLabel:SetPoint("TOPLEFT", 16, moveSectionY - 14)
moveLabel:SetText("Textur verschieben")
moveLabel:SetTextColor(0.4, 0.78, 1)

local moveHint = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
moveHint:SetPoint("LEFT", moveLabel, "RIGHT", 8, 0)
moveHint:SetText("Ziehen = bewegen, Mausrad = Größe")
moveHint:SetTextColor(0.75, 0.56, 0.19)

local moveBtn = CreateFrame("Button", nil, sf)
moveBtn:SetSize(80, 20)
moveBtn:SetPoint("TOPRIGHT", -10, moveSectionY - 8)

local moveBtnBg = moveBtn:CreateTexture(nil, "BACKGROUND")
moveBtnBg:SetAllPoints()
moveBtnBg:SetColorTexture(0.1, 0.1, 0.18, 1)

local moveBtnBorder = CreateFrame("Frame", nil, moveBtn, "BackdropTemplate")
moveBtnBorder:SetAllPoints()
moveBtnBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})
moveBtnBorder:SetBackdropBorderColor(0.2, 0.2, 0.35, 1)

local moveBtnInner = moveBtn:CreateTexture(nil, "ARTWORK")
moveBtnInner:SetPoint("TOPLEFT", 1, -1)
moveBtnInner:SetPoint("BOTTOMRIGHT", -1, 1)
moveBtnInner:SetColorTexture(0.1, 0.1, 0.18, 1)

local moveBtnTxt = moveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
moveBtnTxt:SetAllPoints()
moveBtnTxt:SetText("OFF")
moveBtnTxt:SetTextColor(0.5, 0.5, 0.7)

local function UpdateMoveBtn()
    if moveMode then
        moveBtnBg:SetColorTexture(0.15, 0.1, 0.0, 1)
        moveBtnBorder:SetBackdropBorderColor(0.6, 0.4, 0.0, 1)
        moveBtnInner:SetColorTexture(0.15, 0.1, 0.0, 1)
        moveBtnTxt:SetText("ON")
        moveBtnTxt:SetTextColor(1, 0.7, 0.1)
    else
        moveBtnBg:SetColorTexture(0.1, 0.1, 0.18, 1)
        moveBtnBorder:SetBackdropBorderColor(0.2, 0.2, 0.35, 1)
        moveBtnInner:SetColorTexture(0.1, 0.1, 0.18, 1)
        moveBtnTxt:SetText("OFF")
        moveBtnTxt:SetTextColor(0.5, 0.5, 0.7)
    end
end

local function ShowStaticIcon()
    local faction = UnitFactionGroup("player")
    local col = FACTION_COLORS[faction]   or FACTION_COLORS["Horde"]
    local useFrog = GrimoirePulseLustDB.frogMode
    local animIdx = GrimoirePulseLustDB.animIndex or 1
    local tex = useFrog and ANIM_LIST[animIdx].path or (FACTION_TEXTURES[faction] or FACTION_TEXTURES["Horde"])
    local iw  = useFrog and math.floor(FROG_ICON_W * (GrimoirePulseLustDB.frogScale or 2.5)) or (FACTION_ICON_W[faction] or ICON_SIZE)
    local ih  = useFrog and (FROG_ICON_W * (GrimoirePulseLustDB.frogScale or 2.5)) or ICON_SIZE
    factionIcon:SetSize(iw, ih)
    iconClip:SetWidth(iw)
    iconClip:SetHeight(ih)
    display:SetWidth(iw)
    display:SetHeight(ih)
    factionIcon:SetTexture(tex)
    if useFrog then
        factionIcon:SetTexCoord(0, 1/FROG_COLS, 0, 1/FROG_ROWS)
        StartFrogAnim()
    else
        factionIcon:SetTexCoord(0, 1, 0, 1)
        StopFrogAnim()
    end
    factionIcon:SetAlpha(1)
    timerText:SetAlpha(1)
    timerText:SetTextColor(col[1], col[2], col[3])
    lustLabel:SetTextColor(col[1], col[2], col[3])
    timerText:SetText("")
    display:Show()
    timerFrame:Show()
end

moveBtn:SetScript("OnClick", function()
    moveMode = not moveMode
    if moveMode then
        if not lustStartTime then
            ShowStaticIcon()
        end
        display:SetMovable(true)
        display:EnableMouse(true)
        display:RegisterForDrag("LeftButton")
        display:SetScript("OnDragStart", display.StartMoving)
        display:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            GrimoirePulseLustDB.posX      = self:GetLeft()
            GrimoirePulseLustDB.posY      = self:GetBottom()
            GrimoirePulseLustDB.posAnchor = "BOTTOMLEFT"
        end)
        display:EnableMouseWheel(true)
        display:SetScript("OnMouseWheel", function(self, delta)
            if GrimoirePulseLustDB.frogMode then
                local newScale = math.max(0.3, math.min(5.0, (GrimoirePulseLustDB.frogScale or 2.5) + delta * 0.1))
                GrimoirePulseLustDB.frogScale = newScale
                local iw = math.floor(FROG_ICON_W * newScale)
                local ih = iw
                factionIcon:SetSize(iw, ih)
                iconClip:SetWidth(iw)
                iconClip:SetHeight(ih)
                display:SetWidth(iw)
                display:SetHeight(ih)
            else
                local newScale = math.max(0.3, math.min(3.0, self:GetScale() + delta * 0.1))
                self:SetScale(newScale)
                GrimoirePulseLustDB.iconScale = newScale
            end
        end)
        if GrimoirePulseLustDB.barEnabled then
            lustBar:Show()
            lustBar:SetMovable(true)
            lustBar:EnableMouse(true)
            lustBar:RegisterForDrag("LeftButton")
            lustBar:SetScript("OnDragStart", lustBar.StartMoving)
            lustBar:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                GrimoirePulseLustDB.barPosX      = self:GetLeft()
                GrimoirePulseLustDB.barPosY      = self:GetBottom()
                GrimoirePulseLustDB.barPosAnchor = "BOTTOMLEFT"
            end)
        end
    else
        display:SetMovable(false)
        display:EnableMouse(false)
        display:SetScript("OnDragStart", nil)
        display:SetScript("OnDragStop", nil)
        display:EnableMouseWheel(false)
        display:SetScript("OnMouseWheel", nil)
        lustBar:SetMovable(false)
        lustBar:EnableMouse(false)
        lustBar:SetScript("OnDragStart", nil)
        lustBar:SetScript("OnDragStop", nil)
        if not lustStartTime then
            display:Hide()
            timerFrame:Hide()
            if GrimoirePulseLustDB.barEnabled then lustBar:Hide() end
        end
    end
    UpdateMoveBtn()
end)

UpdateMoveBtn()

local texToggleDivLine = sf:CreateTexture(nil, "ARTWORK")
texToggleDivLine:SetSize(W, 1)
texToggleDivLine:SetPoint("TOPLEFT", 0, texToggleSectY)
texToggleDivLine:SetColorTexture(0.2, 0.2, 0.35, 1)

local texToggleLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
texToggleLabel:SetPoint("TOPLEFT", 16, texToggleSectY - 14)
texToggleLabel:SetText("Textur anzeigen")
texToggleLabel:SetTextColor(0.4, 0.78, 1)

local texStatusTxt = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
texStatusTxt:SetPoint("TOPRIGHT", -50, texToggleSectY - 14)

local texToggleBtn = CreateFrame("Button", nil, sf)
texToggleBtn:SetSize(36, 18)
texToggleBtn:SetPoint("TOPRIGHT", -10, texToggleSectY - 10)

local texTrack = texToggleBtn:CreateTexture(nil, "BACKGROUND")
texTrack:SetAllPoints()

local texTrackBorder = CreateFrame("Frame", nil, texToggleBtn, "BackdropTemplate")
texTrackBorder:SetAllPoints()
texTrackBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})

local texKnob = texToggleBtn:CreateTexture(nil, "OVERLAY")
texKnob:SetSize(14, 14)

UpdateTexToggle = function()
    local on = GrimoirePulseLustDB.textureEnabled
    texTrack:SetColorTexture(on and 0.1 or 0.15, on and 0.3 or 0.15, on and 0.1 or 0.25, 1)
    texTrackBorder:SetBackdropBorderColor(on and 0.3 or 0.2, on and 0.7 or 0.2, on and 0.3 or 0.35, 1)
    texKnob:SetColorTexture(on and 0.3 or 0.4, on and 0.8 or 0.4, on and 0.3 or 0.5, 1)
    texKnob:ClearAllPoints()
    if on then
        texKnob:SetPoint("RIGHT", texToggleBtn, "RIGHT", -2, 0)
    else
        texKnob:SetPoint("LEFT", texToggleBtn, "LEFT", 2, 0)
    end
    texStatusTxt:SetText(on and "|cff44cc44ON|r" or "|cffff4444OFF|r")
end

texToggleBtn:SetScript("OnClick", function()
    GrimoirePulseLustDB.textureEnabled = not GrimoirePulseLustDB.textureEnabled
    UpdateTexToggle()
end)

;(function()
    local sectY = texToggleSectY - 40
    local textUI = {}

    textUI.divLine = sf:CreateTexture(nil, "ARTWORK")
    textUI.divLine:SetSize(W, 1)
    textUI.divLine:SetPoint("TOPLEFT", 0, sectY)
    textUI.divLine:SetColorTexture(0.2, 0.2, 0.35, 1)

    textUI.label = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    textUI.label:SetPoint("TOPLEFT", 16, sectY - 14)
    textUI.label:SetText("Text anzeigen")
    textUI.label:SetTextColor(0.4, 0.78, 1)

    textUI.statusTxt = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    textUI.statusTxt:SetPoint("TOPRIGHT", -50, sectY - 14)

    textUI.btn = CreateFrame("Button", nil, sf)
    textUI.btn:SetSize(36, 18)
    textUI.btn:SetPoint("TOPRIGHT", -10, sectY - 10)

    textUI.track = textUI.btn:CreateTexture(nil, "BACKGROUND")
    textUI.track:SetAllPoints()

    textUI.trackBorder = CreateFrame("Frame", nil, textUI.btn, "BackdropTemplate")
    textUI.trackBorder:SetAllPoints()
    textUI.trackBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left=1, right=1, top=1, bottom=1 },
    })

    textUI.knob = textUI.btn:CreateTexture(nil, "OVERLAY")
    textUI.knob:SetSize(14, 14)

    UpdateTextToggle = function()
        local on = GrimoirePulseLustDB.timerTextEnabled
        textUI.track:SetColorTexture(on and 0.1 or 0.15, on and 0.3 or 0.15, on and 0.1 or 0.25, 1)
        textUI.trackBorder:SetBackdropBorderColor(on and 0.3 or 0.2, on and 0.7 or 0.2, on and 0.3 or 0.35, 1)
        textUI.knob:SetColorTexture(on and 0.3 or 0.4, on and 0.8 or 0.4, on and 0.3 or 0.5, 1)
        textUI.knob:ClearAllPoints()
        if on then
            textUI.knob:SetPoint("RIGHT", textUI.btn, "RIGHT", -2, 0)
        else
            textUI.knob:SetPoint("LEFT", textUI.btn, "LEFT", 2, 0)
        end
        textUI.statusTxt:SetText(on and "|cff44cc44ON|r" or "|cffff4444OFF|r")
    end

    textUI.btn:SetScript("OnClick", function()
        GrimoirePulseLustDB.timerTextEnabled = not GrimoirePulseLustDB.timerTextEnabled
        UpdateTextToggle()
        if GrimoirePulseLustDB.timerTextEnabled then
            if lustStartTime then timerFrame:Show() end
        else
            timerFrame:Hide()
        end
    end)
end)()

local frogSectY = texToggleSectY - 80

local frogDivLine = sf:CreateTexture(nil, "ARTWORK")
frogDivLine:SetSize(W, 1)
frogDivLine:SetPoint("TOPLEFT", 0, frogSectY)
frogDivLine:SetColorTexture(0.2, 0.2, 0.35, 1)

local frogToggleLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frogToggleLabel:SetPoint("TOPLEFT", 16, frogSectY - 14)
frogToggleLabel:SetText("Animationsmodus")
frogToggleLabel:SetTextColor(0.4, 0.78, 1)

local frogStatusTxt = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frogStatusTxt:SetPoint("TOPRIGHT", -50, frogSectY - 14)

local frogToggleBtn = CreateFrame("Button", nil, sf)
frogToggleBtn:SetSize(36, 18)
frogToggleBtn:SetPoint("TOPRIGHT", -10, frogSectY - 10)

local frogTrack = frogToggleBtn:CreateTexture(nil, "BACKGROUND")
frogTrack:SetAllPoints()

local frogTrackBorder = CreateFrame("Frame", nil, frogToggleBtn, "BackdropTemplate")
frogTrackBorder:SetAllPoints()
frogTrackBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})

local frogKnob = frogToggleBtn:CreateTexture(nil, "OVERLAY")
frogKnob:SetSize(14, 14)

UpdateFrogToggle = function()
    local on = GrimoirePulseLustDB.frogMode
    frogTrack:SetColorTexture(on and 0.1 or 0.15, on and 0.3 or 0.15, on and 0.1 or 0.25, 1)
    frogTrackBorder:SetBackdropBorderColor(on and 0.3 or 0.2, on and 0.7 or 0.2, on and 0.3 or 0.35, 1)
    frogKnob:SetColorTexture(on and 0.3 or 0.4, on and 0.8 or 0.4, on and 0.3 or 0.5, 1)
    frogKnob:ClearAllPoints()
    if on then
        frogKnob:SetPoint("RIGHT", frogToggleBtn, "RIGHT", -2, 0)
    else
        frogKnob:SetPoint("LEFT", frogToggleBtn, "LEFT", 2, 0)
    end
    frogStatusTxt:SetText(on and "|cff44cc44ON|r" or "|cffff4444OFF|r")
end

frogToggleBtn:SetScript("OnClick", function()
    GrimoirePulseLustDB.frogMode = not GrimoirePulseLustDB.frogMode
    UpdateFrogToggle()
end)

local animLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
animLabel:SetPoint("TOPLEFT", 16, frogSectY - 34)
animLabel:SetText("Animation")
animLabel:SetTextColor(0.6, 0.6, 0.8)

local animBtn = CreateFrame("Button", nil, sf)
animBtn:SetSize(130, 20)
animBtn:SetPoint("TOPLEFT", 70, frogSectY - 30)
local animBtnBg = animBtn:CreateTexture(nil, "BACKGROUND")
animBtnBg:SetAllPoints()
animBtnBg:SetColorTexture(0.1, 0.1, 0.18, 1)
local animBtnBorder = CreateFrame("Frame", nil, animBtn, "BackdropTemplate")
animBtnBorder:SetAllPoints()
animBtnBorder:SetBackdrop({ edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })
animBtnBorder:SetBackdropBorderColor(0.2, 0.2, 0.35, 1)
local animBtnTxt = animBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
animBtnTxt:SetPoint("LEFT", 6, 0)
animBtnTxt:SetTextColor(0.8, 0.8, 1)
local animBtnArrow = animBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
animBtnArrow:SetPoint("RIGHT", -4, 0)
animBtnArrow:SetText("v")
animBtnArrow:SetTextColor(0.4, 0.4, 0.6)

local animSpeedLabel2 = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
animSpeedLabel2:SetPoint("TOPLEFT", 16, frogSectY - 74)
animSpeedLabel2:SetText("Geschwindigkeit")
animSpeedLabel2:SetTextColor(0.6, 0.6, 0.8)

local animSpeedBg = sf:CreateTexture(nil, "BACKGROUND")
animSpeedBg:SetPoint("TOPLEFT", 55, frogSectY - 70)
animSpeedBg:SetSize(160, 4)
animSpeedBg:SetColorTexture(0.1, 0.15, 0.25, 1)

local animSpeedFill = sf:CreateTexture(nil, "ARTWORK")
animSpeedFill:SetPoint("TOPLEFT", 55, frogSectY - 70)
animSpeedFill:SetSize(64, 4)
animSpeedFill:SetColorTexture(0.16, 0.48, 0.8, 1)

local animSpeedSlowTxt = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
animSpeedSlowTxt:SetPoint("TOPLEFT", 55, frogSectY - 76)
animSpeedSlowTxt:SetText("Langsam")
animSpeedSlowTxt:SetTextColor(0.35, 0.35, 0.5)

local animSpeedFastTxt = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
animSpeedFastTxt:SetPoint("TOPRIGHT", -(W - 215 - 10), frogSectY - 76)
animSpeedFastTxt:SetText("Schnell")
animSpeedFastTxt:SetTextColor(0.35, 0.35, 0.5)

local animSpeedValTxt = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
animSpeedValTxt:SetPoint("TOPLEFT", 222, frogSectY - 74)
animSpeedValTxt:SetTextColor(0.47, 0.62, 0.94)

local animSpeedThumb = sf:CreateTexture(nil, "OVERLAY")
animSpeedThumb:SetSize(12, 12)
animSpeedThumb:SetColorTexture(0.29, 0.61, 0.87, 1)

local animSpeedSlider = CreateFrame("Button", nil, sf)
animSpeedSlider:SetPoint("TOPLEFT", 55, frogSectY - 64)
animSpeedSlider:SetSize(160, 16)

local function SetAnimSpeed(v)
    v = math.max(0.25, math.min(4.0, math.floor(v * 10 + 0.5) / 10))
    GrimoirePulseLustDB.animSpeed = v
    FROG_FRAME_DUR = 0.04 / v
    local pct = (v - 0.25) / 3.75
    animSpeedFill:SetWidth(math.max(1, pct * 160))
    animSpeedThumb:SetPoint("CENTER", sf, "TOPLEFT", 55 + pct * 160, frogSectY - 68)
    animSpeedValTxt:SetText(string.format("%.2fx", v))
end

animSpeedSlider:SetScript("OnMouseDown", function(self, btn)
    if btn ~= "LeftButton" then return end
    local x = GetCursorPosition() / self:GetEffectiveScale()
    local left = self:GetLeft()
    local pct = math.max(0, math.min(1, (x - left) / 160))
    SetAnimSpeed(0.25 + pct * 3.75)
    self:SetScript("OnUpdate", function()
        local cx = GetCursorPosition() / self:GetEffectiveScale()
        local p = math.max(0, math.min(1, (cx - left) / 160))
        SetAnimSpeed(0.25 + p * 3.75)
    end)
end)
animSpeedSlider:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
end)

SetAnimSpeed(1.0)

local function UpdateAnimBtn()
    animBtnTxt:SetText(ANIM_LIST[GrimoirePulseLustDB.animIndex or 1].name)
end

local animList = CreateFrame("Frame", nil, sf, "BackdropTemplate")
animList:SetSize(130, #ANIM_LIST * 22 + 4)
animList:SetFrameStrata("TOOLTIP")
animList:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })
animList:SetBackdropColor(0.08, 0.08, 0.15, 1)
animList:SetBackdropBorderColor(0.3, 0.3, 0.5, 1)
animList:Hide()

local animListBtns = {}
for i, anim in ipairs(ANIM_LIST) do
    local btn = CreateFrame("Button", nil, animList)
    btn:SetSize(128, 20)
    btn:SetPoint("TOPLEFT", 1, -2 - (i-1)*22)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", 6, 0)
    txt:SetText(anim.name)
    txt:SetTextColor(0.8, 0.8, 1)
    btn:SetScript("OnEnter", function() bg:SetColorTexture(0.2, 0.2, 0.4, 1) end)
    btn:SetScript("OnLeave", function() bg:SetColorTexture(0, 0, 0, 0) end)
    btn:SetScript("OnClick", function()
        GrimoirePulseLustDB.animIndex = i
        UpdateAnimBtn()
        animList:Hide()
    end)
    animListBtns[i] = btn
end

animBtn:SetScript("OnClick", function()
    if animList:IsShown() then
        animList:Hide()
    else
        animList:SetPoint("TOPLEFT", animBtn, "BOTTOMLEFT", 0, 0)
        animList:Show()
    end
end)

UpdateAnimBtn()

local barSectY = frogSectY - 100

local barDivLine = sf:CreateTexture(nil, "ARTWORK")
barDivLine:SetSize(W, 1)
barDivLine:SetPoint("TOPLEFT", 0, barSectY)
barDivLine:SetColorTexture(0.2, 0.2, 0.35, 1)

local barSectLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barSectLabel:SetPoint("TOPLEFT", 16, barSectY - 14)
barSectLabel:SetText("Fortschrittsbalken")
barSectLabel:SetTextColor(0.4, 0.78, 1)

local barStatusTxt = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barStatusTxt:SetPoint("TOPRIGHT", -50, barSectY - 14)

local barToggleBtn = CreateFrame("Button", nil, sf)
barToggleBtn:SetSize(36, 18)
barToggleBtn:SetPoint("TOPRIGHT", -10, barSectY - 10)

local barTrack = barToggleBtn:CreateTexture(nil, "BACKGROUND")
barTrack:SetAllPoints()

local barTrackBorder = CreateFrame("Frame", nil, barToggleBtn, "BackdropTemplate")
barTrackBorder:SetAllPoints()
barTrackBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})

local barKnob = barToggleBtn:CreateTexture(nil, "OVERLAY")
barKnob:SetSize(14, 14)

UpdateBarToggle = function()
    local on = GrimoirePulseLustDB.barEnabled
    barTrack:SetColorTexture(on and 0.1 or 0.15, on and 0.3 or 0.15, on and 0.1 or 0.25, 1)
    barTrackBorder:SetBackdropBorderColor(on and 0.3 or 0.2, on and 0.7 or 0.2, on and 0.3 or 0.35, 1)
    barKnob:SetColorTexture(on and 0.3 or 0.4, on and 0.8 or 0.4, on and 0.3 or 0.5, 1)
    barKnob:ClearAllPoints()
    if on then
        barKnob:SetPoint("RIGHT", barToggleBtn, "RIGHT", -2, 0)
    else
        barKnob:SetPoint("LEFT", barToggleBtn, "LEFT", 2, 0)
    end
    barStatusTxt:SetText(on and "|cff44cc44ON|r" or "|cffff4444OFF|r")
end

barToggleBtn:SetScript("OnClick", function()
    GrimoirePulseLustDB.barEnabled = not GrimoirePulseLustDB.barEnabled
    UpdateBarToggle()
    if not GrimoirePulseLustDB.barEnabled then lustBar:Hide() end
end)

local barHdrLine = sf:CreateTexture(nil, "ARTWORK")
barHdrLine:SetSize(W - 20, 1)
barHdrLine:SetPoint("TOPLEFT", 10, barSectY - 30)
barHdrLine:SetColorTexture(0.15, 0.15, 0.28, 1)

local barTexLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barTexLabel:SetPoint("TOPLEFT", 16, barSectY - 44)
barTexLabel:SetText("Textur")
barTexLabel:SetTextColor(0.7, 0.7, 0.9)

local barTexBtn = CreateFrame("Button", nil, sf)
barTexBtn:SetSize(180, 20)
barTexBtn:SetPoint("TOPLEFT", 60, barSectY - 40)

local barTexBtnBg = barTexBtn:CreateTexture(nil, "BACKGROUND")
barTexBtnBg:SetAllPoints()
barTexBtnBg:SetColorTexture(0.1, 0.1, 0.18, 1)

local barTexBtnBorder = CreateFrame("Frame", nil, barTexBtn, "BackdropTemplate")
barTexBtnBorder:SetAllPoints()
barTexBtnBorder:SetBackdrop({ edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })
barTexBtnBorder:SetBackdropBorderColor(0.2, 0.2, 0.35, 1)

local barTexBtnInner = barTexBtn:CreateTexture(nil, "ARTWORK")
barTexBtnInner:SetPoint("TOPLEFT", 1, -1)
barTexBtnInner:SetPoint("BOTTOMRIGHT", -1, 1)
barTexBtnInner:SetColorTexture(0.1, 0.1, 0.18, 1)

local barTexBtnTxt = barTexBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barTexBtnTxt:SetPoint("LEFT", 6, 0)
barTexBtnTxt:SetText(GrimoirePulseLustDB.barTexture or "Blizzard")
barTexBtnTxt:SetTextColor(0.8, 0.8, 1)

local barTexArrow = barTexBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barTexArrow:SetPoint("RIGHT", -4, 0)
barTexArrow:SetText("v")
barTexArrow:SetTextColor(0.4, 0.4, 0.6)

local barTexList = CreateFrame("Frame", nil, sf, "BackdropTemplate")
barTexList:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })
barTexList:SetBackdropColor(0.06, 0.06, 0.10, 1)
barTexList:SetBackdropBorderColor(0.25, 0.25, 0.45, 1)
barTexList:SetFrameStrata("TOOLTIP")
barTexList:Hide()

local barTexScrollFrame = CreateFrame("ScrollFrame", nil, barTexList)
barTexScrollFrame:SetPoint("TOPLEFT", 1, -1)
barTexScrollFrame:SetPoint("BOTTOMRIGHT", -1, 1)

local barTexScrollChild = CreateFrame("Frame", nil, barTexScrollFrame)
barTexScrollFrame:SetScrollChild(barTexScrollChild)

local barTexListRows = {}

local function BuildBarTexList()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local entries = {}
    if LSM then
        for _, name in ipairs(LSM:List("statusbar")) do
            entries[#entries+1] = { name=name, path=LSM:Fetch("statusbar", name) }
        end
    else
        for _, t in ipairs(BAR_TEXTURES) do entries[#entries+1] = t end
    end
    local rowH = 22
    local maxVisible = 7
    local listH = math.min(#entries, maxVisible) * rowH
    barTexList:SetSize(180, listH + 2)
    barTexList:SetPoint("TOPLEFT", barTexBtn, "BOTTOMLEFT", 0, -2)
    barTexScrollChild:SetSize(176, #entries * rowH)
    barTexScrollFrame:SetVerticalScroll(0)
    for _, r in ipairs(barTexListRows) do r:Hide() r:SetParent(nil) end
    wipe(barTexListRows)
    for i, entry in ipairs(entries) do
        local row = CreateFrame("Button", nil, barTexScrollChild)
        row:SetSize(176, rowH)
        row:SetPoint("TOPLEFT", 0, -(i-1)*rowH)
        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        local isSel = entry.name == GrimoirePulseLustDB.barTexture
        rowBg:SetColorTexture(isSel and 0.1 or 0, isSel and 0.2 or 0, isSel and 0.1 or 0, isSel and 0.8 or 0)
        local rowTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rowTxt:SetPoint("LEFT", 8, 0)
        rowTxt:SetText(entry.name)
        rowTxt:SetTextColor(isSel and 0.4 or 0.8, isSel and 0.9 or 0.8, isSel and 0.4 or 1)
        row:SetScript("OnEnter", function() rowBg:SetColorTexture(0.08, 0.08, 0.18, 1) end)
        row:SetScript("OnLeave", function()
            local sel = entry.name == GrimoirePulseLustDB.barTexture
            rowBg:SetColorTexture(sel and 0.1 or 0, sel and 0.2 or 0, sel and 0.1 or 0, sel and 0.8 or 0)
        end)
        row:SetScript("OnClick", function()
            GrimoirePulseLustDB.barTexture = entry.name
            barTexBtnTxt:SetText(entry.name)
            ApplyBarSettings()
            barTexList:Hide()
        end)
        barTexListRows[i] = row
    end
    barTexList:EnableMouseWheel(true)
    barTexList:SetScript("OnMouseWheel", function(self, delta)
        local cur = barTexScrollFrame:GetVerticalScroll()
        local max = barTexScrollFrame:GetVerticalScrollRange()
        barTexScrollFrame:SetVerticalScroll(math.max(0, math.min(max, cur - delta * rowH)))
    end)
end

barTexBtn:SetScript("OnClick", function()
    if barTexList:IsShown() then
        barTexList:Hide()
    else
        BuildBarTexList()
        barTexList:Show()
    end
end)

local barHeightLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barHeightLabel:SetPoint("TOPLEFT", 16, barSectY - 70)
barHeightLabel:SetText("Höhe")
barHeightLabel:SetTextColor(0.7, 0.7, 0.9)

local barHeightSlider = CreateFrame("Slider", nil, sf)
barHeightSlider:SetOrientation("HORIZONTAL")
barHeightSlider:SetMinMaxValues(8, 700)
barHeightSlider:SetValue(GrimoirePulseLustDB.barHeight or 16)
barHeightSlider:SetValueStep(1)
barHeightSlider:SetSize(130, 14)
barHeightSlider:SetPoint("LEFT", sf, "LEFT", 60, 0)
barHeightSlider:SetPoint("TOP",  sf, "TOP",  0, -(math.abs(barSectY) + 67))
barHeightSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
local bht = barHeightSlider:CreateTexture(nil, "BACKGROUND")
bht:SetAllPoints()
bht:SetColorTexture(0.15, 0.15, 0.25, 1)

local barHeightEdit = CreateFrame("EditBox", nil, sf, "BackdropTemplate")
barHeightEdit:SetSize(46, 18)
barHeightEdit:SetPoint("LEFT", barHeightSlider, "RIGHT", 6, 0)
barHeightEdit:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=2,right=2,top=2,bottom=2} })
barHeightEdit:SetBackdropColor(0.08, 0.08, 0.14, 1)
barHeightEdit:SetBackdropBorderColor(0.25, 0.25, 0.45, 1)
barHeightEdit:SetFont("Fonts\\2002.TTF", 11, "OUTLINE")
barHeightEdit:SetTextColor(0.8, 0.8, 1)
barHeightEdit:SetText((GrimoirePulseLustDB.barHeight or 16) .. "px")
barHeightEdit:SetAutoFocus(false)
barHeightEdit:SetNumeric(false)
barHeightEdit:SetMaxLetters(6)
barHeightEdit:SetScript("OnEditFocusGained", function(self)
    self:SetText(tostring(GrimoirePulseLustDB.barHeight or 16))
    self:HighlightText()
end)
barHeightEdit:SetScript("OnEditFocusLost", function(self)
    local v = tonumber(self:GetText())
    if v then
        v = math.max(8, math.min(700, math.floor(v)))
        GrimoirePulseLustDB.barHeight = v
        barHeightSlider:SetValue(v)
        ApplyBarSettings()
    end
    self:SetText((GrimoirePulseLustDB.barHeight or 16) .. "px")
end)
barHeightEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
barHeightEdit:SetScript("OnEscapePressed", function(self)
    self:SetText((GrimoirePulseLustDB.barHeight or 16) .. "px")
    self:ClearFocus()
end)

barHeightSlider:SetScript("OnValueChanged", function(self, val)
    local v = math.floor(val)
    GrimoirePulseLustDB.barHeight = v
    if not barHeightEdit:HasFocus() then
        barHeightEdit:SetText(v .. "px")
    end
    ApplyBarSettings()
end)

local barWidthLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barWidthLabel:SetPoint("TOPLEFT", 16, barSectY - 88)
barWidthLabel:SetText("Breite")
barWidthLabel:SetTextColor(0.7, 0.7, 0.9)

local barWidthSlider = CreateFrame("Slider", nil, sf)
barWidthSlider:SetOrientation("HORIZONTAL")
barWidthSlider:SetMinMaxValues(8, 700)
barWidthSlider:SetValue(GrimoirePulseLustDB.barWidth or 260)
barWidthSlider:SetValueStep(1)
barWidthSlider:SetSize(130, 14)
barWidthSlider:SetPoint("LEFT", sf, "LEFT", 60, 0)
barWidthSlider:SetPoint("TOP",  sf, "TOP",  0, -(math.abs(barSectY) + 85))
barWidthSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
local bwt = barWidthSlider:CreateTexture(nil, "BACKGROUND")
bwt:SetAllPoints()
bwt:SetColorTexture(0.15, 0.15, 0.25, 1)

local barWidthEdit = CreateFrame("EditBox", nil, sf, "BackdropTemplate")
barWidthEdit:SetSize(46, 18)
barWidthEdit:SetPoint("LEFT", barWidthSlider, "RIGHT", 6, 0)
barWidthEdit:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=2,right=2,top=2,bottom=2} })
barWidthEdit:SetBackdropColor(0.08, 0.08, 0.14, 1)
barWidthEdit:SetBackdropBorderColor(0.25, 0.25, 0.45, 1)
barWidthEdit:SetFont("Fonts\\2002.TTF", 11, "OUTLINE")
barWidthEdit:SetTextColor(0.8, 0.8, 1)
barWidthEdit:SetText((GrimoirePulseLustDB.barWidth or 260) .. "px")
barWidthEdit:SetAutoFocus(false)
barWidthEdit:SetNumeric(false)
barWidthEdit:SetMaxLetters(6)
barWidthEdit:SetScript("OnEditFocusGained", function(self)
    self:SetText(tostring(GrimoirePulseLustDB.barWidth or 260))
    self:HighlightText()
end)
barWidthEdit:SetScript("OnEditFocusLost", function(self)
    local v = tonumber(self:GetText())
    if v then
        v = math.max(8, math.min(700, math.floor(v)))
        GrimoirePulseLustDB.barWidth = v
        barWidthSlider:SetValue(v)
        ApplyBarSettings()
    end
    self:SetText((GrimoirePulseLustDB.barWidth or 260) .. "px")
end)
barWidthEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
barWidthEdit:SetScript("OnEscapePressed", function(self)
    self:SetText((GrimoirePulseLustDB.barWidth or 260) .. "px")
    self:ClearFocus()
end)

barWidthSlider:SetScript("OnValueChanged", function(self, val)
    local v = math.floor(val)
    GrimoirePulseLustDB.barWidth = v
    if not barWidthEdit:HasFocus() then
        barWidthEdit:SetText(v .. "px")
    end
    ApplyBarSettings()
end)

local barDirLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barDirLabel:SetPoint("TOPLEFT", 16, barSectY - 106)
barDirLabel:SetText("Richtung")
barDirLabel:SetTextColor(0.7, 0.7, 0.9)

local barDirL = CreateFrame("Button", nil, sf, "BackdropTemplate")
barDirL:SetSize(62, 20)
barDirL:SetPoint("TOPLEFT", 60, barSectY - 102)
barDirL:SetBackdrop({ edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })

local barDirR = CreateFrame("Button", nil, sf, "BackdropTemplate")
barDirR:SetSize(62, 20)
barDirR:SetPoint("TOPLEFT", 126, barSectY - 102)
barDirR:SetBackdrop({ edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })

local barDirU = CreateFrame("Button", nil, sf, "BackdropTemplate")
barDirU:SetSize(62, 20)
barDirU:SetPoint("TOPLEFT", 60, barSectY - 125)
barDirU:SetBackdrop({ edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })

local barDirD = CreateFrame("Button", nil, sf, "BackdropTemplate")
barDirD:SetSize(62, 20)
barDirD:SetPoint("TOPLEFT", 126, barSectY - 125)
barDirD:SetBackdrop({ edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })

local barDirLTxt = barDirL:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barDirLTxt:SetAllPoints()
barDirLTxt:SetText("← Links")

local barDirRTxt = barDirR:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barDirRTxt:SetAllPoints()
barDirRTxt:SetText("Rechts →")

local barDirUTxt = barDirU:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barDirUTxt:SetAllPoints()
barDirUTxt:SetText("↑ Oben")

local barDirDTxt = barDirD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barDirDTxt:SetAllPoints()
barDirDTxt:SetText("↓ Unten")

UpdateDirBtns = function()
    local dir = GrimoirePulseLustDB.barDirection or "LEFT"
    local btns = {
        { btn=barDirL, txt=barDirLTxt, key="LEFT"  },
        { btn=barDirR, txt=barDirRTxt, key="RIGHT" },
        { btn=barDirU, txt=barDirUTxt, key="UP"    },
        { btn=barDirD, txt=barDirDTxt, key="DOWN"  },
    }
    for _, t in ipairs(btns) do
        local on = dir == t.key
        t.btn:SetBackdropColor(on and 0.1 or 0.07, on and 0.2 or 0.07, on and 0.35 or 0.12, 1)
        t.btn:SetBackdropBorderColor(on and 0.3 or 0.2, on and 0.5 or 0.2, on and 0.8 or 0.35, 1)
        t.txt:SetTextColor(on and 0.5 or 0.35, on and 0.78 or 0.35, on and 1 or 0.6)
    end
end

barDirL:SetScript("OnClick", function() GrimoirePulseLustDB.barDirection = "LEFT"  ApplyBarSettings() UpdateDirBtns() end)
barDirR:SetScript("OnClick", function() GrimoirePulseLustDB.barDirection = "RIGHT" ApplyBarSettings() UpdateDirBtns() end)
barDirU:SetScript("OnClick", function() GrimoirePulseLustDB.barDirection = "UP"    ApplyBarSettings() UpdateDirBtns() end)
barDirD:SetScript("OnClick", function() GrimoirePulseLustDB.barDirection = "DOWN"  ApplyBarSettings() UpdateDirBtns() end)

UpdateDirBtns()

local barColorLabel = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
barColorLabel:SetPoint("TOPLEFT", 16, barSectY - 153)
barColorLabel:SetText("Farbe")
barColorLabel:SetTextColor(0.7, 0.7, 0.9)

local barColorBtn = CreateFrame("Button", nil, sf, "BackdropTemplate")
barColorBtn:SetSize(60, 20)
barColorBtn:SetPoint("TOPLEFT", 60, barSectY - 149)
barColorBtn:SetBackdrop({ edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })
barColorBtn:SetBackdropBorderColor(0.25, 0.25, 0.45, 1)

local barColorSwatch = barColorBtn:CreateTexture(nil, "BACKGROUND")
barColorSwatch:SetPoint("TOPLEFT", 1, -1)
barColorSwatch:SetPoint("BOTTOMRIGHT", -1, 1)
local c = GrimoirePulseLustDB.barColor or { 0.0, 0.8, 0.8 }
barColorSwatch:SetColorTexture(c[1], c[2], c[3], 1)

barColorBtn:SetScript("OnClick", function()
    local prev = { r=GrimoirePulseLustDB.barColor[1], g=GrimoirePulseLustDB.barColor[2], b=GrimoirePulseLustDB.barColor[3] }
    local function onColorChange()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        GrimoirePulseLustDB.barColor = { r, g, b }
        barColorSwatch:SetColorTexture(r, g, b, 1)
        ApplyBarSettings()
    end
    local function onCancel()
        GrimoirePulseLustDB.barColor = { prev.r, prev.g, prev.b }
        barColorSwatch:SetColorTexture(prev.r, prev.g, prev.b, 1)
        ApplyBarSettings()
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            hasOpacity = false,
            r = prev.r, g = prev.g, b = prev.b,
            swatchFunc = onColorChange,
            cancelFunc = onCancel,
        })
    else
        ColorPickerFrame.func         = onColorChange
        ColorPickerFrame.cancelFunc   = onCancel
        ColorPickerFrame.hasOpacity   = false
        ColorPickerFrame:SetColorRGB(prev.r, prev.g, prev.b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end)

UpdateRows()

UpdateBarSettingsUI = function()
    barTexBtnTxt:SetText(GrimoirePulseLustDB.barTexture or "Blizzard")
    barHeightSlider:SetValue(GrimoirePulseLustDB.barHeight or 16)
    barHeightEdit:SetText((GrimoirePulseLustDB.barHeight or 16) .. "px")
    barWidthSlider:SetValue(GrimoirePulseLustDB.barWidth or 260)
    barWidthEdit:SetText((GrimoirePulseLustDB.barWidth or 260) .. "px")
    local c = GrimoirePulseLustDB.barColor or { 0.0, 0.8, 0.8 }
    barColorSwatch:SetColorTexture(c[1], c[2], c[3], 1)
    UpdateBarToggle()
    UpdateDirBtns()
end

-- Machtinfusion lives in the same settings window as the Lust tracker.
local piSectY = barSectY - 185
local piLine = sf:CreateTexture(nil, "ARTWORK")
piLine:SetSize(W, 1)
piLine:SetPoint("TOPLEFT", 0, piSectY)
piLine:SetColorTexture(0.45, 0.22, 0.68, 1)

local piTitle = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
piTitle:SetPoint("TOPLEFT", 16, piSectY - 14)
piTitle:SetText("Machtinfusion")
piTitle:SetTextColor(0.72, 0.45, 1)

local function CreatePIButton(y)
    local button = CreateFrame("Button", nil, sf, "BackdropTemplate")
    button:SetSize(W - 32, 22)
    button:SetPoint("TOPLEFT", 16, y)
    button:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })
    button:SetBackdropColor(0.08, 0.04, 0.12, 1)
    button:SetBackdropBorderColor(0.34, 0.18, 0.52, 1)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetAllPoints()
    button.label:SetTextColor(0.85, 0.72, 1)
    return button
end

local piEnabledBtn = CreatePIButton(piSectY - 30)
local piAlertBtn   = CreatePIButton(piSectY - 55)
local piChannelBtn = CreatePIButton(piSectY - 80)
local piTestBtn    = CreatePIButton(piSectY - 105)
piTestBtn.label:SetText("Machtinfusion testen")

local function UpdatePIControls()
    local api = _G.GrimoirePulsePI
    local db = api and api.GetDB()
    if not db then
        piEnabledBtn.label:SetText("Machtinfusion wird geladen …")
        piAlertBtn:Hide(); piChannelBtn:Hide(); piTestBtn:Hide()
        return
    end
    piAlertBtn:Show(); piChannelBtn:Show(); piTestBtn:Show()
    piEnabledBtn.label:SetText("Machtinfusion: " .. (db.enabled and "|cff44cc44AN|r" or "|cffff4444AUS|r"))
    piAlertBtn.label:SetText("Bildschirmalarm: " .. (db.alert and "|cff44cc44AN|r" or "|cffff4444AUS|r"))
    piChannelBtn.label:SetText("Audio-Kanal: " .. (db.channel or "Master"))
end

piEnabledBtn:SetScript("OnClick", function()
    local api = _G.GrimoirePulsePI
    if api then api.ToggleEnabled(); UpdatePIControls() end
end)
piAlertBtn:SetScript("OnClick", function()
    local api = _G.GrimoirePulsePI
    if api then api.ToggleAlert(); UpdatePIControls() end
end)
piChannelBtn:SetScript("OnClick", function()
    local api = _G.GrimoirePulsePI
    local db = api and api.GetDB()
    if not db then return end
    local at = 1
    for i, channel in ipairs(CHANNELS) do if channel.key == db.channel then at = i break end end
    at = at % #CHANNELS + 1
    api.SetChannel(CHANNELS[at].key)
    UpdatePIControls()
end)
piTestBtn:SetScript("OnClick", function()
    local api = _G.GrimoirePulsePI
    if api then api.Test() end
end)

local function ResetDisplayPosition()
    GrimoirePulseLustDB.posX      = 0
    GrimoirePulseLustDB.posY      = 200
    GrimoirePulseLustDB.posAnchor = nil
    GrimoirePulseLustDB.iconScale = 1.0
    GrimoirePulseLustDB.frogScale = 2.5
    GrimoirePulseLustDB.frogMode  = false
    display:ClearAllPoints()
    display:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    display:SetScale(1.0)
    local iw = math.floor(FROG_ICON_W * 2.5)
    factionIcon:SetSize(iw, iw)
    iconClip:SetWidth(iw)
    iconClip:SetHeight(iw)
    display:SetSize(iw, iw)
    UpdateFrogToggle()
    print("|cffff4444GrimoirePulse|r  Position und Größe zurückgesetzt")
end

SLASH_LUSTALERT1 = "/lust"
SlashCmdList["LUSTALERT"] = function(msg)
    if msg == "test" then
        ShowBloodlustAlert()
        return
    end
    if msg == "reset" then
        ResetDisplayPosition()
        return
    end
    if sf:IsShown() then
        sf:Hide()
    else
        UpdateRows()
        UpdateBarSettingsUI()
        UpdateAnimBtn()
        UpdatePIControls()
        sf:Show()
    end
end

local version = C_AddOns.GetAddOnMetadata("GrimoirePulse", "Version")
print("|cffff4444GrimoirePulse|r  v" .. (version or "?") .. "  command: /lust")

mm.menu = CreateFrame("Frame", "GrimoirePulseMinimapMenu", UIParent, "BackdropTemplate")
mm.menu:SetSize(170, 62)
mm.menu:SetFrameStrata("DIALOG")
mm.menu:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})
mm.menu:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
mm.menu:SetBackdropBorderColor(0.2, 0.2, 0.35, 1)
mm.menu:Hide()

mm.catcher = CreateFrame("Button", nil, UIParent)
mm.catcher:SetAllPoints(UIParent)
mm.catcher:SetFrameStrata("DIALOG")
mm.catcher:Hide()
mm.catcher:SetScript("OnClick", function() mm.menu:Hide() end)

mm.menu:SetFrameLevel(mm.catcher:GetFrameLevel() + 1)
mm.menu:SetScript("OnShow", function() mm.catcher:Show() end)
mm.menu:SetScript("OnHide", function() mm.catcher:Hide() end)

mm.label = mm.menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mm.label:SetPoint("TOPLEFT", 12, -12)
mm.label:SetText("Minimap-Symbol")
mm.label:SetTextColor(0.4, 0.78, 1)

mm.statusTxt = mm.menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mm.statusTxt:SetPoint("TOPRIGHT", -50, -12)

mm.toggle = CreateFrame("Button", nil, mm.menu)
mm.toggle:SetSize(36, 18)
mm.toggle:SetPoint("TOPRIGHT", -10, -10)

mm.track = mm.toggle:CreateTexture(nil, "BACKGROUND")
mm.track:SetAllPoints()

mm.trackBorder = CreateFrame("Frame", nil, mm.toggle, "BackdropTemplate")
mm.trackBorder:SetAllPoints()
mm.trackBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left=1, right=1, top=1, bottom=1 },
})

mm.knob = mm.toggle:CreateTexture(nil, "OVERLAY")
mm.knob:SetSize(14, 14)

mm.line = mm.menu:CreateTexture(nil, "ARTWORK")
mm.line:SetSize(170 - 20, 1)
mm.line:SetPoint("TOPLEFT", 10, -34)
mm.line:SetColorTexture(0.2, 0.2, 0.35, 1)

mm.hint = mm.menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mm.hint:SetPoint("TOPLEFT", 12, -44)
mm.hint:SetText("/lust öffnet die Einstellungen")
mm.hint:SetTextColor(0.5, 0.5, 0.6)

UpdateMinimapToggle = function()
    local shown = not GrimoirePulseLustDB.minimap.hide
    mm.track:SetColorTexture(shown and 0.1 or 0.15, shown and 0.3 or 0.15, shown and 0.1 or 0.25, 1)
    mm.trackBorder:SetBackdropBorderColor(shown and 0.3 or 0.2, shown and 0.7 or 0.2, shown and 0.3 or 0.35, 1)
    mm.knob:SetColorTexture(shown and 0.3 or 0.4, shown and 0.8 or 0.4, shown and 0.3 or 0.5, 1)
    mm.knob:ClearAllPoints()
    if shown then
        mm.knob:SetPoint("RIGHT", mm.toggle, "RIGHT", -2, 0)
    else
        mm.knob:SetPoint("LEFT", mm.toggle, "LEFT", 2, 0)
    end
    mm.statusTxt:SetText(shown and "|cff44cc44ON|r" or "|cffff4444OFF|r")
    mm.hdrTxt:SetText(shown and "Minimap |cff44cc44AN|r" or "Minimap |cffff4444AUS|r")
end

mm.toggle:SetScript("OnClick", function()
    SetMinimapButtonShown(GrimoirePulseLustDB.minimap.hide == true)
end)

GrimoirePulse_MinimapButton = GrimoirePulse_MinimapButton or nil
GrimoirePulse_MinimapInitFrame = CreateFrame("Frame")
GrimoirePulse_MinimapInitFrame:RegisterEvent("ADDON_LOADED")
GrimoirePulse_MinimapInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
GrimoirePulse_MinimapInitFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "GrimoirePulse" then
        self:UnregisterEvent("ADDON_LOADED")
        GrimoirePulseLustDB = GrimoirePulseLustDB or {}
    elseif event == "PLAYER_ENTERING_WORLD" then
        local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
        if LibDBIcon and GrimoirePulse_MinimapButton then
            GrimoirePulseLustDB.minimap = GrimoirePulseLustDB.minimap or {}
            if not LibDBIcon:IsRegistered("GrimoirePulse") then
                LibDBIcon:Register("GrimoirePulse", GrimoirePulse_MinimapButton, GrimoirePulseLustDB.minimap)
                LibDBIcon:RemoveButtonBorder("GrimoirePulse")
            end
        end
        SetAnimSpeed(GrimoirePulseLustDB.animSpeed or 1.0)
        UpdateAnimBtn()
        if UpdateMinimapToggle then UpdateMinimapToggle() end
    end
end)

GrimoirePulse_LDB = LibStub and LibStub("LibDataBroker-1.1", true)
if GrimoirePulse_LDB then
    GrimoirePulse_MinimapButton = GrimoirePulse_LDB:NewDataObject("GrimoirePulse", {
        type="launcher", label="GrimoirePulse",
        tocname="GrimoirePulse",
        icon="Interface\\AddOns\\GrimoirePulse\\icon\\LUSTicon",
        OnClick = function(self, btn)
            if btn=="LeftButton" then
                if sf:IsShown() then sf:Hide()
                else UpdateRows(); UpdateBarSettingsUI(); UpdateAnimBtn(); sf:Show() end
            elseif btn=="RightButton" then
                if mm.menu:IsShown() then
                    mm.menu:Hide()
                else
                    mm.menu:ClearAllPoints()
                    mm.menu:SetPoint("TOP", self, "BOTTOM", 0, -6)
                    UpdateMinimapToggle()
                    mm.menu:Show()
                end
            end
        end,
        OnTooltipShow = function(tip)
            tip:AddLine("GrimoirePulse", 1, 0.27, 0.27)
            tip:AddLine("|cFFFFFFFFLinksklick|r   Einstellungen öffnen / schließen")
            tip:AddLine("|cFFFFFFFFRechtsklick|r   Minimap-Menü")
        end,
    })
end
