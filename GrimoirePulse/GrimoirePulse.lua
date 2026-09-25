local ADDON, GP = ...
local L = GP.L
local PREFIX = "Interface\\AddOns\\GrimoirePulse\\"
local ICON = PREFIX .. "Media\\grimoire-pulse"
local LUST_IDS = { 2825, 32182, 80353, 264667, 390386, 381301, 146555, 178207 }
local PI_ID = 10060
local defaults = { enabled=true, minimap=true, channel="Master", lustSound="Grimoire Pulse", piSound="Grimoire Pulse", lang="auto", positions={}, moving=false }
local db, active = nil, { lust=false, pi=false }

local function aura(id) return C_UnitAuras.GetPlayerAuraBySpellID(id) end
local function lustAura() for _, id in ipairs(LUST_IDS) do local a = aura(id); if a then return a end end end
local function soundList()
  local t = { { name=L.NONE, file=nil } }
  for _, s in ipairs(GP.UserSounds or {}) do
    if type(s.name)=="string" and type(s.file)=="string" then t[#t+1] = { name=s.name, file=PREFIX..s.file } end
  end
  return t
end
local function play(name)
  if not db.enabled or name == "None" then return end
  for _, s in ipairs(soundList()) do if s.name == name and s.file then PlaySoundFile(s.file, db.channel) return end end
end
local function savePosition(frame, key)
  local _, _, _, x, y = frame:GetPoint(1); db.positions[key] = { x=x, y=y }
end

local function makeTracker(key, label, color)
  local f = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
  f:SetSize(242, 42); f:SetPoint("CENTER", 0, key=="lust" and 170 or 112); f:SetMovable(true); f:EnableMouse(false)
  f:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1 })
  f:SetBackdropColor(.025,.018,.055,.93); f:SetBackdropBorderColor(color[1],color[2],color[3],.9)
  local icon=f:CreateTexture(nil,"ARTWORK"); icon:SetSize(30,30); icon:SetPoint("LEFT",6,0); icon:SetTexture(key=="lust" and 136012 or 135939)
  local name=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); name:SetPoint("TOPLEFT",42,-7); name:SetText(label); name:SetTextColor(color[1],color[2],color[3])
  local time=f:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge"); time:SetPoint("BOTTOMLEFT",42,6)
  local bar=CreateFrame("StatusBar",nil,f); bar:SetPoint("TOPLEFT",105,-10); bar:SetPoint("BOTTOMRIGHT",-8,9); bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8"); bar:SetStatusBarColor(color[1],color[2],color[3]); bar:SetMinMaxValues(0,1)
  f.time, f.bar, f.key = time, bar, key; f:Hide()
  f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); savePosition(self,key) end)
  return f
end
local tracks = { lust=makeTracker("lust",L.LUST,{.95,.22,.25}), pi=makeTracker("pi",L.PI,{.55,.25,1}) }
local function restore(frame, key)
  local p=db.positions[key]; if p then frame:ClearAllPoints(); frame:SetPoint("CENTER",UIParent,"CENTER",p.x,p.y) end
end
local function updateTrack(key, a)
  local f=tracks[key]
  if not a then
    active[key]=false
    if db.moving then
      f.time:SetText(L.PREVIEW); f.bar:SetValue(1); f:Show()
    else
      f:Hide()
    end
    return
  end
  local remain = math.max(0,(a.expirationTime or GetTime())-GetTime()); local total=a.duration or 1
  f.time:SetFormattedText("%.1fs",remain); f.bar:SetValue(remain/total); f:Show()
  if not active[key] then active[key]=true; play(key=="lust" and db.lustSound or db.piSound) end
end

local options
local function button(parent,text,x,y,w,fn)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate"); b:SetSize(w or 100,27); b:SetPoint("TOPLEFT",x,y)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  b:SetBackdropColor(.10,.045,.17,.96); b:SetBackdropBorderColor(.54,.28,.78,1)
  b.text=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); b.text:SetAllPoints(); b.text:SetText(text); b.text:SetTextColor(.92,.78,1)
  b:SetScript("OnEnter",function(self) self:SetBackdropColor(.22,.07,.31,1); self.text:SetTextColor(1,.9,.45) end)
  b:SetScript("OnLeave",function(self) self:SetBackdropColor(.10,.045,.17,.96); self.text:SetTextColor(.92,.78,1) end)
  b:SetScript("OnClick",fn); b.SetText=function(self,value) self.text:SetText(value) end; return b
end
local function toggleButton(parent, key, label, x, y, refresh)
  local b=button(parent,"",x,y,210,function() end)
  local function update() b:SetText(label..": "..(db[key] and L.ENABLED or L.DISABLED)) end
  b:SetScript("OnClick",function()
    db[key]=not db[key]
    if key=="enabled" and not db.enabled then tracks.lust:Hide(); tracks.pi:Hide() end
    if key=="minimap" and _G.GrimoirePulseMinimap then _G.GrimoirePulseMinimap:SetShown(db.minimap) end
    update()
  end)
  return b, update
end
local function cycleSound(key)
  local list=soundList(); local at=1; for i,s in ipairs(list) do if s.name==db[key] then at=i end end; at=at%#list+1; db[key]=list[at].name; play(db[key])
end
StaticPopupDialogs["GRIMOIREPULSE_SOUND_FOLDER"] = {
  text = L.FOLDER_HELP,
  button1 = OKAY,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}
local function buildOptions()
  if options then return end
  options=CreateFrame("Frame","GrimoirePulseOptions",UIParent,"BackdropTemplate"); options:SetSize(465,460); options:SetPoint("CENTER"); options:SetFrameStrata("DIALOG"); options:SetMovable(true); options:EnableMouse(true); options:RegisterForDrag("LeftButton"); options:SetScript("OnDragStart",options.StartMoving); options:SetScript("OnDragStop",options.StopMovingOrSizing); options:Hide()
  options:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Gold-Border",edgeSize=18,insets={left=10,right=10,top=10,bottom=10}}); options:SetBackdropColor(.09,.035,.12,.98)
  local cover=options:CreateTexture(nil,"BACKGROUND"); cover:SetTexture(ICON); cover:SetSize(170,170); cover:SetPoint("TOPRIGHT",-18,-22); cover:SetAlpha(.16)
  local rule=options:CreateTexture(nil,"ARTWORK"); rule:SetColorTexture(.66,.38,.9,.72); rule:SetSize(410,1); rule:SetPoint("TOP",0,-70)
  local title=options:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOPLEFT",28,-24); title:SetText("|T"..ICON..":30|t  "..L.TITLE); title:SetTextColor(.92,.72,1)
  local subtitle=options:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); subtitle:SetPoint("TOPLEFT",32,-52); subtitle:SetText("✦  "..L.GENERAL.."  ✦"); subtitle:SetTextColor(.72,.45,.94)
  local function heading(text, y)
    local h=options:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); h:SetPoint("TOPLEFT",32,y); h:SetText(text); h:SetTextColor(1,.79,.38); return h
  end
  heading(L.ALERTS,-92)
  local enabled, refreshEnabled=toggleButton(options,"enabled",L.TRACKERS,32,-116)
  local mini, refreshMini=toggleButton(options,"minimap",L.MINIMAP,252,-116)
  heading(L.SOUNDS,-164)
  local lust=button(options,"",32,-188,280,function() cycleSound("lustSound"); options.lustButton:SetText(L.LUST_SOUND..": "..db.lustSound) end)
  local pi=button(options,"",32,-223,280,function() cycleSound("piSound"); options.piButton:SetText(L.PI_SOUND..": "..db.piSound) end)
  options.lustButton, options.piButton = lust, pi
  button(options,L.TEST,322,-188,108,function() play(db.lustSound) end)
  button(options,L.TEST,322,-223,108,function() play(db.piSound) end)
  button(options,L.FOLDER,32,-258,398,function() StaticPopup_Show("GRIMOIREPULSE_SOUND_FOLDER") end)
  heading(L.TRACKERS,-305)
  local move=button(options,"",32,-329,280,function()
    db.moving=not db.moving
    for _,f in pairs(tracks) do f:EnableMouse(db.moving); if db.moving then f:Show() end end
    options.moveButton:SetText(db.moving and L.LOCK or L.UNLOCK)
  end)
  options.moveButton = move
  button(options,L.CLOSE,322,-412,108,function() options:Hide() end)
  local desc=options:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); desc:SetPoint("TOPLEFT",32,-377); desc:SetPoint("TOPRIGHT",-28,-377); desc:SetJustifyH("LEFT"); desc:SetText(L.CUSTOM_HELP)
  refreshEnabled(); refreshMini(); lust:SetText(L.LUST_SOUND..": "..db.lustSound); pi:SetText(L.PI_SOUND..": "..db.piSound)
  move:SetText(db.moving and L.LOCK or L.UNLOCK)
end
local function openOptions() buildOptions(); options:SetShown(not options:IsShown()) end

local minimap=CreateFrame("Button","GrimoirePulseMinimap",Minimap); minimap:SetSize(32,32); minimap:SetFrameStrata("MEDIUM"); minimap:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local mt=minimap:CreateTexture(nil,"BACKGROUND"); mt:SetTexture(ICON); mt:SetAllPoints(); minimap:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-5,5); minimap:SetScript("OnClick",openOptions); minimap:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:AddLine(L.TITLE, .8,.5,1); GameTooltip:AddLine("/gp",1,1,1); GameTooltip:Show() end); minimap:SetScript("OnLeave",GameTooltip_Hide)

local elapsed=0
local e=CreateFrame("Frame"); e:RegisterEvent("ADDON_LOADED"); e:RegisterEvent("PLAYER_ENTERING_WORLD"); e:RegisterEvent("UNIT_AURA")
e:SetScript("OnEvent",function(_,event,arg)
  if event=="ADDON_LOADED" then if arg~=ADDON then return end; GrimoirePulseDB=GrimoirePulseDB or {}; db=GrimoirePulseDB; for k,v in pairs(defaults) do if db[k]==nil then db[k]=v end end; restore(tracks.lust,"lust"); restore(tracks.pi,"pi"); for _,f in pairs(tracks) do f:EnableMouse(db.moving) end; minimap:SetShown(db.minimap)
  elseif event=="UNIT_AURA" and arg~="player" then return end
  if db and db.enabled then updateTrack("lust",lustAura()); updateTrack("pi",aura(PI_ID)) elseif db then tracks.lust:Hide(); tracks.pi:Hide() end
end)
e:SetScript("OnUpdate",function(_,dt) elapsed=elapsed+dt; if elapsed>.05 and db then elapsed=0; if db.enabled then updateTrack("lust",lustAura()); updateTrack("pi",aura(PI_ID)) else tracks.lust:Hide(); tracks.pi:Hide() end; minimap:SetShown(db.minimap) end end)
SLASH_GRIMOIREPULSE1="/gp"; SLASH_GRIMOIREPULSE2="/grimoirepulse"; SlashCmdList.GRIMOIREPULSE=function(msg) if msg=="test" then play(db.lustSound); play(db.piSound) else openOptions() end end
