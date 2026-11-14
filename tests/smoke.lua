table.unpack = table.unpack or unpack
local clock, frames, engineCalls, messages = 100, {}, {}, {}
local cvars = { Sound_EnableAllSound = true, Sound_EnableMusic = true }
local musicAccepted, musicThrows = true, false
local timers = {}
C_Timer = {}
function C_Timer.NewTimer(delay, callback)
    local timer = { due=clock+delay, callback=callback, canceled=false, fired=false }
    function timer:Cancel() self.canceled=true end
    timers[#timers+1]=timer
    return timer
end
local function Advance(seconds)
    clock=clock+seconds
    for _,timer in ipairs(timers) do
        if not timer.canceled and not timer.fired and timer.due<=clock then
            timer.fired=true
            timer.callback()
        end
    end
end
local function PendingTimers()
    local count=0
    for _,timer in ipairs(timers) do
        if not timer.canceled and not timer.fired then count=count+1 end
    end
    return count
end
local M = {}
local function noop() end
for _, name in ipairs({
    "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetFont",
    "SetTextColor", "SetJustifyH", "SetColorTexture", "SetTexture", "SetTexCoord",
    "SetNormalTexture", "SetPushedTexture", "SetFrameStrata", "SetToplevel", "SetMovable", "SetClampedToScreen",
    "EnableMouse", "RegisterForClicks", "RegisterForDrag", "SetHighlightTexture",
    "SetTextInsets", "SetAutoFocus", "SetMaxLetters", "SetWordWrap", "SetStatusBarTexture",
    "SetStatusBarColor", "SetScrollChild", "SetOwner", "AddLine",
}) do M[name] = noop end
function M:SetOwner(owner, anchor) self.owner, self.ownerAnchor = owner, anchor end
function M:SetClampedToScreen(value) self.clampedToScreen = value end
function M:SetAtlas(atlas) self.atlas=atlas end
function M:SetAlpha(value) self.alpha=value end
function M:SetVertexColor(r,g,b) self.vertexColor={r,g,b} end
function M:SetTextColor(r,g,b) self.textColor = {r,g,b} end
function M:AddLine(text) self.tooltipLines = self.tooltipLines or {}; table.insert(self.tooltipLines,text) end
function M:SetScript(event, fn) self.scripts[event] = fn end
function M:HookScript(event, fn)
    local old = self.scripts[event]
    self.scripts[event] = function(...) if old then old(...) end; fn(...) end
end
function M:RegisterEvent(event) self.events[event] = true end
function M:UnregisterEvent(event) self.events[event] = nil end
function M:SetSize(w,h)
    local changed = self.width ~= w or self.height ~= h
    self.width, self.height = w,h
    if changed and self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,w,h) end
end
function M:SetResizable(value) self.resizable = value end
function M:SetResizeBounds(...) self.resizeBounds = {...} end
function M:StartSizing(point)
    assert(self.resizable, "frame must enable resizing")
    self.sizing = point
end
function M:SetWidth(w) self.width = w end
function M:SetHeight(h) self.height = h end
function M:GetWidth() return self.width or 100 end
function M:GetHeight() return self.height or 150 end
function M:SetPoint(point, a,b,c,d)
    self.anchors = self.anchors or {}
    self.anchors[point] = {point,a,b,c,d}
    if type(a) == "number" then self.point = {point, self.parent, point, a,b}
    else self.point = {point, a or self.parent, b or point, c or 0,d or 0} end
end
function M:GetPoint() return table.unpack(self.point or {"CENTER", UIParent, "CENTER", 0,0}) end
function M:ClearAllPoints() self.point = nil; self.anchors = {} end
function M:SetAllPoints() end
function M:SetFrameLevel(n) self.level = n end
function M:GetFrameLevel() return self.level or 1 end
function M:GetEffectiveScale() return 1 end
function M:GetCenter() return 500,500 end
function M:IsMouseOver() return self.mouseOver == true end
function M:IsShown() return self.shown end
function M:SetShown(value)
    value = not not value
    if self.shown == value then return end
    self.shown = value
    local fn = self.scripts[value and "OnShow" or "OnHide"]
    if fn then fn(self) end
end
function M:Show() self:SetShown(true) end
function M:Hide() self:SetShown(false) end
function M:SetEnabled(value)
    value = not not value
    if self.enabled == value then return end
    self.enabled = value
    local fn = self.scripts[value and "OnEnable" or "OnDisable"]
    if fn then fn(self) end
end
function M:IsEnabled() return self.enabled end
function M:Disable() self:SetEnabled(false) end
function M:SetChecked(v) self.checked = v end
function M:GetChecked() return self.checked end
function M:SetText(t)
    self.textValue = t
    self.tooltipLines = {}
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function M:GetText() return self.textValue or "" end
function M:ClearFocus() self.focus = false end
function M:StartMoving() self.moving = true end
function M:StopMovingOrSizing() self.moving = false; self.sizing = nil end
function M:SetVerticalScroll(value)
    local changed = self.vertical ~= value
    self.vertical = value
    if changed and self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self,value) end
end
function M:GetVerticalScroll() return self.vertical or 0 end
function M:SetMinMaxValues(a,b) self.min, self.max = a,b end
function M:SetValue(v) self.value = v end
function M:CreateTexture() return CreateFrame("Texture", nil, self) end
function M:CreateFontString() return CreateFrame("FontString", nil, self) end
function CreateFrame(kind, name, parent, template)
    local f = setmetatable({kind=kind, name=name, parent=parent, template=template,
        scripts={}, events={}, shown=true, enabled=true}, {__index=M})
    frames[#frames+1] = f
    if name then _G[name] = f end
    return f
end
UIParent = CreateFrame("Frame", "UIParent")
UIParent:SetSize(1920,1080)
Minimap = CreateFrame("Frame", "Minimap", UIParent)
Minimap:SetSize(140,140)
GameTooltip = CreateFrame("Tooltip")
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
RAID_CLASS_COLORS = {MONK={r=0,g=1,b=152/255}}
UISpecialFrames, SlashCmdList = {}, {}
C_CVar = {GetCVarBool=function(name) return cvars[name] end}
local clockReads = 0
GetTime = function() clockReads = clockReads + 1; return clock end
GetCursorPosition = function() return 600,500 end
math.atan2 = function(y,x) return math.atan(y,x) end -- WoW Lua 5.1 extension
PlayMusic = function(id) engineCalls[#engineCalls+1] = {"play",id}; if musicThrows then error("Audio unavailable") end; return musicAccepted end
StopMusic = function() engineCalls[#engineCalls+1] = {"stop"} end
print = function(s) messages[#messages+1] = s end

function M:HasScript(name) return name=="OnWindowFocusChanged" end
local now, timers, tickers, sounds, calls = 0, {}, {}, {}, {}
local eventFrame
local sequence, accepted, returnHandle, queryError = 0, true, true, false
local soundEnabled, musicEnabled = true, true
local backgroundEnabled = true
local volume, failSet = "0.63", false
local messages = {}
GetTime=function() return now end
print=function(text) messages[#messages+1]=text end
C_CVar={GetCVarBool=function(name) if name=="Sound_EnableSoundWhenGameIsInBG" then return backgroundEnabled end; return name=="Sound_EnableAllSound" and soundEnabled or name=="Sound_EnableMusic" and musicEnabled end}
C_CVar.GetCVar=function(name) assert(name=="Sound_MusicVolume");return volume end
C_CVar.SetCVar=function(name,value) if failSet then error("set failed") end;if name=="Sound_EnableSoundWhenGameIsInBG" then backgroundEnabled=tostring(value)=="1";return end;assert(name=="Sound_MusicVolume");volume=tostring(value) end
C_Timer={}
local function Timer(callback)
    local timer={callback=callback,canceled=false}
    function timer:Cancel() self.canceled=true end
    return timer
end
function C_Timer.NewTicker(interval,callback)
    local timer=Timer(callback);tickers[#tickers+1]=timer;return timer
end
function C_Timer.NewTimer(delay,callback)
    local timer=Timer(callback);timer.due=now+delay;timers[#timers+1]=timer;return timer
end
local function Tick(seconds)
    now=now+(seconds or .2)
    local limit=#tickers
    for i=1,limit do if not tickers[i].canceled then tickers[i].callback() end end
    limit=#timers
    for i=1,limit do
        local timer=timers[i]
        if not timer.canceled and not timer.fired and timer.due<=now then timer.fired=true;timer.callback() end
    end
end
function PlaySoundFile(id,channel)
    sequence=sequence+1
    calls[#calls+1]={id=id,channel=channel,handle=sequence}
    sounds[sequence]=accepted==true
    return accepted,returnHandle and sequence or nil
end
C_Sound={IsPlaying=function(handle) if queryError then error("query failed") end;return sounds[handle]==true end}
PlayMusic=function() error("silent carrier must not be used") end
StopMusic=function() end
StopSound=function(handle)
    sounds[handle]=false
    -- Exercise synchronous completion during StopSound.
    if eventFrame then eventFrame.scripts.OnEvent(eventFrame,"SOUNDKIT_FINISHED",handle) end
end
SlashCmdList={}

unpack=unpack or table.unpack
MusicSCANDB={selectedTrack="bfa-boralus-intro",favorites={[2175189]=true,[3930252]=true,[999999999]=true},
 window={width=640,height=600,point="TOPLEFT",relativePoint="TOPLEFT",x=35,y=-60,visible=true},
 minimap={angle=42},collapsedExpansions={Shadowlands=true}}
local ns={}
for _,file in ipairs({"Database.lua","Themes.lua","MusicSCAN.lua","Playback.lua","UI.lua"}) do
    assert(loadfile("MusicSCAN/"..file))("MusicSCAN",ns)
end
for _,frame in ipairs(frames) do if frame.events.ADDON_LOADED then eventFrame=frame;break end end
assert(eventFrame)
eventFrame.scripts.OnEvent(eventFrame,"ADDON_LOADED","MusicSCAN")
assert(ns.VERSION=="0.8.0 BETA1 HOTFIX1" and #ns.Catalog==5493 and not ns.State.playing)
assert(ns.DB.selectedTrack=="bfa-boralus-intro" and ns.DB.window.width==640 and ns.DB.minimap.angle==42)
assert(ns.DB.favorites[999999999] and #ns.GetFavoriteTracks("")==2)
assert(ns.UI.sourceRows and #ns.UI.sourceRows==20)
local counts={Cities=174,Forests=376,Taverns=54,PvP=40,Dungeons=213,Raids=396}
for source,count in pairs(counts) do
    assert(ns.SetLibrarySource(source));local tracks=ns.GetBrowseTracks("");assert(#tracks==count)
    local ids={};for _,track in ipairs(tracks) do assert(not ids[track.fileDataID]);ids[track.fileDataID]=true end
    assert(#ns.UI.rows<60 and ns.DB.collapsedExpansions.Shadowlands==true)
end
assert(ns.SetLibrarySource("Cities"));ns.SelectTrack("bfa-boralus-intro")
assert(ns.Play() and ns.State.activeTrack=="bfa-boralus-intro" and tonumber(volume)==0)
local queue=ns.Engine.Tracks;local index=ns.Engine.State.index;assert(#queue==174)
ns.SetLibrarySource("Forests");ns.SelectTrack("sl-ardenweald-the-dreamer-a")
assert(ns.Engine.Tracks==queue and ns.State.activeTrack=="bfa-boralus-intro")
Tick();local h=ns.Engine.State.handle;ns.ToggleRepeat();sounds[h]=false;Tick(3)
assert(ns.State.activeTrack=="bfa-boralus-intro" and ns.Engine.Tracks==queue)
assert(ns.DB.selectedTrack=="sl-ardenweald-the-dreamer-a", "Repeat must preserve an independently highlighted row")
ns.Next();assert(ns.State.activeTrack==queue[index%#queue+1].key)
ns.Stop();assert(volume=="0.63" and not ns.State.playing and ns.DB.restoreMusicVolume==nil)

-- Captured Favorites follow displayed title order and remain stable after editing them.
ns.SetLibrarySource("favorites");ns.SelectTrack("bfa-boralus-intro");ns.ToggleRepeat()
assert(ns.Play() and #ns.Engine.Tracks==2)
queue=ns.Engine.Tracks
ns.ToggleFavorite("sl-ardenweald-the-dreamer-a");assert(#queue==2 and #ns.GetFavoriteTracks("")==1)
Tick();h=ns.Engine.State.handle;sounds[h]=false;Tick(3)
assert(ns.State.activeTrack=="sl-ardenweald-the-dreamer-a")
ns.Next();assert(ns.State.activeTrack=="bfa-boralus-intro")
ns.SelectTrack("sl-ardenweald-the-dreamer-a")

-- Stops, loading/recovery, failures and reload cleanup operate through the production bridge.
local function Event(name,a,b) eventFrame.scripts.OnEvent(eventFrame,name,a,b) end
Event("LOADING_SCREEN_ENABLED");Event("PLAYER_LEAVING_WORLD")
assert(ns.State.suspended and volume=="0.63")
local before=#calls;Tick(10);assert(#calls==before)
Event("PLAYER_ENTERING_WORLD",false,false);Event("LOADING_SCREEN_DISABLED");Tick(1)
assert(#calls==before+1 and ns.State.activeTrack=="bfa-boralus-intro" and tonumber(volume)==0)
assert(ns.DB.selectedTrack=="sl-ardenweald-the-dreamer-a", "Recovery must preserve selected B while restoring active A")
Event("LOADING_SCREEN_ENABLED");Event("PLAYER_ENTERING_WORLD",false,false);Event("LOADING_SCREEN_DISABLED")
local stale=timers[#timers];ns.Stop();before=#calls;stale.callback();Tick(5);assert(#calls==before and not ns.State.playing)
assert(ns.Play());Event("PLAYER_ENTERING_WORLD",false,true);assert(not ns.State.playing and volume=="0.63")
musicEnabled=false;assert(not ns.Play());musicEnabled=true
accepted=false;assert(not ns.Play() and volume=="0.63");accepted=true
assert(ns.Play());volume="0.4";ns.Stop();assert(volume=="0.4")
volume="0";ns.DB.restoreMusicVolume="0.71";ns.Initialize();assert(volume=="0.71" and not ns.State.playing)
assert(ns.DB.favorites[999999999])
ns.SetLibrarySource("all");ns.UI.search:SetText("[x%");assert(#ns.GetBrowseTracks("[x%") == 0)
ns.UI.search:SetText("");ns.UI.frame:SetSize(620,460);ns.UI:LayoutLibrary();assert(#ns.UI.rows<60)
for _,track in ipairs(ns.Catalog) do assert(ns.TracksByKey[track.key]==track) end
io.write("PASS: integrated full catalog, theme membership, split native UI, frozen queues, Favorites, Next/Repeat, recovery and volume restoration.\n")



-- Starting with the preference OFF needs no manual menu changes.
ns.Stop();ns.UI.search:SetText("");ns.SetLibrarySource("all")
backgroundEnabled=false
local oldVolume=volume
assert(ns.Play() and backgroundEnabled==true and ns.DB.restoreBackgroundAudio=="0")
Tick(3);local handle=ns.Engine.State.handle;sounds[handle]=false;Tick(3)
assert(ns.State.playing and backgroundEnabled and ns.DB.restoreBackgroundAudio=="0")
ns.Stop();assert(not backgroundEnabled and volume==oldVolume and ns.DB.restoreBackgroundAudio==nil)
-- An already-enabled preference is preserved.
backgroundEnabled=true;assert(ns.Play());ns.Stop();assert(backgroundEnabled)
-- Failed playback rolls both settings back.
backgroundEnabled=false;accepted=false;assert(not ns.Play());accepted=true
assert(not backgroundEnabled and volume==oldVolume and ns.DB.restoreBackgroundAudio==nil)
-- Failure to enable leaves no sound request or false completion.
failSet=true;local count=#calls;assert(not ns.Play() and #calls==count)
failSet=false;ns.Stop();assert(not backgroundEnabled)
-- Pending restoration survives a failed SetCVar and /msc restore retries it.
assert(ns.Play());failSet=true;ns.Stop()
assert(ns.DB.restoreBackgroundAudio=="0")
failSet=false;ns.HandleCommand("restore")
assert(not backgroundEnabled and ns.DB.restoreBackgroundAudio==nil and volume==oldVolume)
-- Reload recovery restores even a background-only saved marker.
backgroundEnabled=true;ns.DB.restoreBackgroundAudio="0";ns.Initialize()
assert(not backgroundEnabled and ns.DB.restoreBackgroundAudio==nil and not ns.State.playing)
-- Loading temporarily releases settings; recovery reacquires; logout restores.
assert(ns.Play());Event("LOADING_SCREEN_ENABLED");assert(not backgroundEnabled)
Event("PLAYER_ENTERING_WORLD",false,false);Event("LOADING_SCREEN_DISABLED");Tick(1)
assert(backgroundEnabled and ns.State.playing)
Event("PLAYER_LOGOUT");assert(not backgroundEnabled and volume==oldVolume)
-- Explicitly turning background audio OFF while active is respected, not fought.
assert(ns.Play());backgroundEnabled=false;Tick(.2)
assert(not ns.State.playing and not backgroundEnabled and volume==oldVolume)
io.write("PASS: automatic background audio ownership, queue continuity, failures, reload, loading/logout and player changes.\n")

-- Debug logging is opt-in; event/error diagnostics remain internally accessible.
ns.Stop();ns.DB.debugMode=nil;ns.Initialize()
assert(ns.DB.debugMode==false)
local quietCount=#messages
assert(ns.Play());Tick(3)
local handle=ns.Engine.State.handle;sounds[handle]=false;Tick(3)
ns.ToggleRepeat();ns.Next()
Event("LOADING_SCREEN_ENABLED");Event("PLAYER_ENTERING_WORLD",false,false)
Event("LOADING_SCREEN_DISABLED");Tick(1);ns.Stop()
assert(#messages==quietCount and ns.Engine.LastMessage)
accepted=false;assert(not ns.Play());accepted=true
assert(#messages==quietCount)
ns.HandleCommand("status");assert(#messages>quietCount)
quietCount=#messages;ns.HandleCommand("debug on")
assert(ns.DB.debugMode==true and #messages==quietCount+1)
assert(ns.Play());assert(#messages>quietCount+1);ns.Stop()
ns.Initialize();assert(ns.DB.debugMode==true)
ns.HandleCommand("debug off");quietCount=#messages
assert(ns.DB.debugMode==false);ns.Initialize()
assert(#messages==quietCount and ns.DB.debugMode==false)
assert(ns.Play());ns.Stop();assert(#messages==quietCount)
ns.HandleCommand("help");assert(#messages>quietCount)
io.write("PASS: quiet default, silent events/errors, opt-in persistent debug and explicit status/help.\n")
