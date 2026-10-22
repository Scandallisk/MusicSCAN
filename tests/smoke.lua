-- Native-frame mock smoke test; not a replacement for a Retail client test.
local root = "MusicSCAN/"
for _, name in ipairs({"Database.lua", "MusicSCAN.lua", "UI.lua"}) do
    assert(loadfile(root .. name), "parse failed: " .. name)
end

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

MusicSCANDB = {
    selectedTrack="wod-frostfire-magnificent-desolation-h",loopMusic=false,
    window={width=640,height=600,point="TOPLEFT",relativePoint="TOPLEFT",x=35,y=-60,visible=true},
    minimap={angle=42},collapsedExpansions={Shadowlands=true},
}
local ns={}
for _,name in ipairs({"Database.lua","MusicSCAN.lua","UI.lua"}) do
    assert(loadfile(root..name))("MusicSCAN",ns)
end
local events
for _,f in ipairs(frames) do if f.events.ADDON_LOADED then events=f;break end end
assert(events)
events.scripts.OnEvent(events,"ADDON_LOADED","OtherAddon");assert(ns.DB==nil)
events.scripts.OnEvent(events,"ADDON_LOADED","MusicSCAN")
assert(ns.VERSION=="0.7.1 BETA" and #ns.Catalog>2000)
assert(ns.DB.selectedTrack=="wod-frostfire-magnificent-desolation-h")
assert(ns.DB.window.width==640 and ns.DB.window.x==35 and ns.DB.minimap.angle==42)
assert(ns.DB.collapsedExpansions.Shadowlands==true and ns.DB.loopMusic==nil)
assert(not ns.State.playing and #engineCalls==0)
assert(ns.GetTiming==nil and ns.UI.progress==nil and ns.UI.time==nil and ns.UI.frame.scripts.OnUpdate==nil)
for _,f in ipairs(frames) do assert(f.kind~="StatusBar" and f.kind~="CheckButton") end

local ids,keys,zoneTitles={}, {}, {}
for _,t in ipairs(ns.Catalog) do
    assert(type(t.fileDataID)=="number" and t.fileDataID>0 and not ids[t.fileDataID])
    assert(type(t.key)=="string" and not keys[t.key])
    assert(t.title~="" and t.zone~="" and ns.ExpansionOrder[t.expansion])
    assert(t.sourceFilename:lower():find("sound/music/",1,true)==1)
    assert(t.sourceFilename:lower():match("%.mp3$") or t.sourceFilename:lower():match("%.ogg$"))
    assert(t.durationSeconds==nil)
    ids[t.fileDataID],keys[t.key]=true,true
    local identity=t.expansion.."|"..t.zone.."|"..t.title:lower()
    assert(not zoneTitles[identity],"duplicate friendly label: "..identity)
    zoneTitles[identity]=true
end
assert(ns.GetTrack("wod-frostfire-magnificent-desolation-h").fileDataID==936340)
assert(ns.GetTrack("wrath-grizzly-hills-intro-1").fileDataID==229834)
assert(ns.GetTrack("legion-suramar-part-1").fileDataID==1477339)
local groups=ns.GetExpansionGroups("")
assert(#groups==12 and groups[1].name=="Original World of Warcraft" and groups[12].name=="Midnight")
assert(ns.GetExpansionGroups("")==groups,"unchanged query should reuse grouped metadata")
local total=0
for i,g in ipairs(groups) do
    if i>1 then assert(ns.ExpansionOrder[groups[i-1].name]<ns.ExpansionOrder[g.name]) end
    total=total+#g.tracks
    for j,t in ipairs(g.tracks) do
        assert(t.expansion==g.name)
        if j>1 then
            local previous=g.tracks[j-1]
            assert(previous.zone:lower()<=t.zone:lower())
            if previous.zone==t.zone then assert(previous.title:lower()<=t.title:lower()) end
        end
    end
end
assert(total==#ns.Catalog and #ns.GetFilteredCatalog("[x%") == 0)

ns.UI.scroll:SetSize(574,360)
ns.DB.collapsedExpansions={}
ns.UI:RenderLibrary()
assert(#ns.UI.libraryItems>#ns.Catalog)
local function visible(kind)
    local n=0
    for _,f in ipairs(kind) do if f:IsShown() then n=n+1 end end
    return n
end
local function assertViewport()
    local top=ns.UI.scroll:GetVerticalScroll()
    local bottom=top+ns.UI.scroll:GetHeight()
    local n=visible(ns.UI.rows)+visible(ns.UI.headers)+visible(ns.UI.expansionHeaders)
    assert(n<=math.ceil(ns.UI.scroll:GetHeight()/28)+2,"viewport pool bound")
    for _,row in ipairs(ns.UI.rows) do
        if row:IsShown() then
            assert(row:GetWidth()==ns.UI.content:GetWidth()-12)
            local y=-select(5,row:GetPoint())
            assert(y<bottom and y+32>top,"offscreen row should not be rendered")
            assert(row.playing:GetText()=="Playing")
            assert(row.playing:IsShown()==(ns.State.playing and ns.State.activeTrack==row.trackKey))
        end
    end
end
local maxScroll=ns.UI.content:GetHeight()-ns.UI.scroll:GetHeight()
for i=0,100 do
    ns.UI.scroll:SetVerticalScroll(maxScroll*i/100)
    assertViewport()
end
assert(#ns.UI.rows<40 and #ns.UI.headers<40 and #ns.UI.expansionHeaders<=12)
assert(#frames<500,"full catalog must not create thousands of frames")
local last
for i=#ns.UI.libraryItems,1,-1 do
    if ns.UI.libraryItems[i].kind=="track" then last=ns.UI.libraryItems[i];break end
end
assert(last and last.kind=="track")
local lastVisible=false
for _,row in ipairs(ns.UI.rows) do if row:IsShown() and row.trackKey==last.track.key then lastVisible=true end end
assert(lastVisible,"bottom of full library is reachable")

-- Searching must reveal folded matches, without changing normal preferences.
ns.DB.collapsedExpansions.Shadowlands=true
ns.UI.search:SetText("The Dreamer")
assert(#ns.GetFilteredCatalog("The Dreamer")>=1)
local shadowHeader
for _,h in ipairs(ns.UI.expansionHeaders) do if h:IsShown() and h.expansion=="Shadowlands" then shadowHeader=h end end
assert(shadowHeader and shadowHeader.toggle:GetText()=="-")
assert(ns.DB.collapsedExpansions.Shadowlands==true)
assert(tonumber(shadowHeader.count:GetText())>0)
local beforeSearchCalls=#engineCalls
shadowHeader.scripts.OnClick(shadowHeader)
assert(visible(ns.UI.rows)==0 and not ns.UI.empty:IsShown())
shadowHeader.scripts.OnClick(shadowHeader)
assert(visible(ns.UI.rows)>0 and #engineCalls==beforeSearchCalls)
ns.UI.search:SetText("does not exist [x%")
assert(ns.UI.empty:IsShown() and visible(ns.UI.rows)==0)
ns.UI.search:SetText("")
assert(ns.DB.collapsedExpansions.Shadowlands==true)

-- Audio controls and category/layout actions remain independent.
ns.SelectTrack("wod-frostfire-magnificent-desolation-h")
local reads=clockReads
assert(ns.Play())
assert(engineCalls[#engineCalls][2]==936340 and ns.State.startedAt==nil and clockReads==reads)
assert(ns.UI.nowLabel:GetText()=="NOW PLAYING" and ns.UI.nowLabel.textColor[2]==1)
local calls=#engineCalls
assert(ns.ToggleExpansion("Warlords of Draenor"))
assert(ns.State.playing and #engineCalls==calls)
ns.UI.frame:Hide();clock=clock+10000;ns.UI.frame:Show()
assert(ns.State.playing and #engineCalls==calls)
for _,g in ipairs(groups) do
    ns.SelectTrack(g.tracks[1].key)
    assert(#engineCalls==calls)
    assert(ns.Play());calls=calls+2
    assert(#engineCalls==calls and engineCalls[calls][2]==g.tracks[1].fileDataID)
end
cvars.Sound_EnableMusic=false
assert(not ns.Play() and ns.State.playing and #engineCalls==calls)
cvars.Sound_EnableMusic=true
musicAccepted=false
assert(not ns.Play() and not ns.State.playing)
musicAccepted=true
musicThrows=true
assert(not ns.Play() and not ns.State.playing, "unavailable-file errors must not escape the player")
assert(messages[#messages]:find("FileDataID",1,true))
musicThrows=false
assert(ns.Play())
assert(ns.Stop() and not ns.UI.stop:IsEnabled() and ns.UI.nowLabel:GetText()=="SELECTED TRACK")
local stoppedCalls=#engineCalls;assert(not ns.Stop() and #engineCalls==stoppedCalls)

ns.UI.search:SetText("Magnificent Desolation")
for _,row in ipairs(ns.UI.rows) do
    if row:IsShown() then
        assert(not row.playing:IsShown())
        row.scripts.OnEnter(row)
        assert(not table.concat(GameTooltip.tooltipLines,"|"):lower():find("test",1,true))
        row.scripts.OnClick(row)
        assert(ns.DB.selectedTrack==row.trackKey and not ns.State.playing)
        row.scripts.OnLeave(row)
    end
end
ns.UI.about.scripts.OnEnter(ns.UI.about)
assert(GameTooltip.ownerAnchor=="ANCHOR_RIGHT" and GameTooltip.clampedToScreen)
assert(table.concat(GameTooltip.tooltipLines,"|"):find("Version: 0.7.1 BETA",1,true))
assert(table.concat(GameTooltip.tooltipLines,"|"):find("www.kilobytes.dev",1,true))
assert(ns.UI.tagline:GetText()=="Listen your way with MusicSCAN v0.7.1 BETA")

-- Favorites target the highlighted selection, independently of active playback.
ns.UI.search:SetText("")
assert(type(ns.DB.favorites)=="table" and #ns.GetFavoriteTracks("")==0)
assert(ns.DB.favoritesCollapsed==false)
assert(ns.UI.favorite:GetHeight()==ns.UI.play:GetHeight())
assert(select(5,ns.UI.favorite:GetPoint())==select(5,ns.UI.play:GetPoint()))
assert(ns.UI.favorite.icon.atlas=="auctionhouse-icon-favorite-off")
assert(not ns.ToggleFavorite("not-a-track"))
ns.SelectTrack("wod-frostfire-magnificent-desolation-h");assert(ns.Play())
local favoriteCalls=#engineCalls
ns.UI.favorite.scripts.OnClick(ns.UI.favorite)
assert(ns.IsFavorite("wod-frostfire-magnificent-desolation-h") and ns.DB.favorites[936340]==true)
assert(ns.UI.favorite.icon.atlas=="auctionhouse-icon-favorite")
assert(GameTooltip:GetText()=="Remove from Favorites")
assert(#ns.GetFavoriteTracks("")==1 and #ns.Catalog==5493)
ns.SelectTrack("bfa-boralus-intro")
assert(ns.UI.favorite.icon.atlas=="auctionhouse-icon-favorite-off")
ns.UI.favorite.scripts.OnEnter(ns.UI.favorite)
assert(GameTooltip:GetText()=="Add to Favorites")
assert(table.concat(GameTooltip.tooltipLines,"|"):find("Boralus",1,true))
ns.UI.favorite.scripts.OnClick(ns.UI.favorite)
assert(ns.IsFavorite("bfa-boralus-intro"))
assert(ns.State.activeTrack=="wod-frostfire-magnificent-desolation-h" and #engineCalls==favoriteCalls)
assert(ns.UI.nowTitle:GetText()=="Magnificent Desolation")
ns.ToggleFavorite("legion-suramar-part-1")
local favorites=ns.GetFavoriteTracks("")
assert(#favorites==3 and favorites[1].fileDataID==2175189 and favorites[2].fileDataID==936340)
assert(ns.GetFavoriteTracks("")==favorites,"favorites cache")
local favoriteHeaderIndex,lastExpansionIndex
for i,item in ipairs(ns.UI.libraryItems) do
    if item.kind=="expansion" then
        if item.isFavorites then favoriteHeaderIndex=i else lastExpansionIndex=i end
    end
end
assert(favoriteHeaderIndex>lastExpansionIndex and ns.UI.libraryItems[favoriteHeaderIndex].count==3)
ns.UI.search:SetText("Favorites")
assert(not ns.UI.empty:IsShown() and visible(ns.UI.rows)==3)
local favoritesHeader
for _,h in ipairs(ns.UI.expansionHeaders) do if h:IsShown() and h.isFavorites then favoritesHeader=h end end
assert(favoritesHeader and favoritesHeader.title:GetText()=="Favorites" and favoritesHeader.count:GetText()=="3")
assert(favoritesHeader.toggle:GetText()=="-")
favoritesHeader.scripts.OnClick(favoritesHeader)
assert(visible(ns.UI.rows)==0 and ns.DB.favoritesCollapsed==false,"search fold stays temporary")
favoritesHeader.scripts.OnClick(favoritesHeader)
assert(visible(ns.UI.rows)==3)
local favoriteRow
for _,r in ipairs(ns.UI.rows) do if r:IsShown() and r.trackKey=="bfa-boralus-intro" then favoriteRow=r end end
assert(favoriteRow)
favoriteRow.scripts.OnClick(favoriteRow)
assert(ns.DB.selectedTrack=="bfa-boralus-intro" and #engineCalls==favoriteCalls)
ns.UI.favorite.scripts.OnClick(ns.UI.favorite)
assert(not ns.IsFavorite("bfa-boralus-intro") and #ns.GetFavoriteTracks("")==2)
assert(ns.UI.favorite.icon.atlas=="auctionhouse-icon-favorite-off")
assert(ns.TracksByFileID[2175189] and #ns.Catalog==5493,"removing a favorite keeps expansion entry")
assert(ns.Play() and ns.State.activeTrack=="bfa-boralus-intro")
ns.Stop()
ns.ToggleFavoritesCategory()
assert(ns.DB.favoritesCollapsed==true)
ns.UI.search:SetText("Grizzly Hills")
assert(#ns.GetFavoriteTracks("Grizzly Hills")==0)
ns.UI.search:SetText("Magnificent Desolation")
local searchFavoriteHeader
for _,h in ipairs(ns.UI.expansionHeaders) do if h:IsShown() and h.isFavorites then searchFavoriteHeader=h end end
assert(searchFavoriteHeader and searchFavoriteHeader.toggle:GetText()=="-")
assert(ns.DB.favoritesCollapsed==true)
ns.UI.search:SetText("")
ns.DB.favorites[999999999]=true -- Keep unavailable IDs for a future restored catalog.
ns.DB.favorites.bad=true;ns.DB.favorites[-1]=true;ns.DB.favorites[0]=true;ns.DB.favorites[1.5]=true;ns.DB.favorites[53211]="bad"
local persistedSelected=ns.DB.selectedTrack
ns.Initialize()
assert(ns.DB.selectedTrack==persistedSelected and ns.DB.window.width==640 and ns.DB.minimap.angle==42)
assert(ns.DB.favorites[936340] and ns.DB.favorites[1477339] and ns.DB.favorites[999999999])
assert(ns.DB.favorites.bad==nil and ns.DB.favorites[-1]==nil and ns.DB.favorites[0]==nil and ns.DB.favorites[1.5]==nil and ns.DB.favorites[53211]==nil)
assert(#ns.GetFavoriteTracks("")==2 and ns.DB.favoritesCollapsed==true and not ns.State.playing)
ns.ToggleFavorite("wod-frostfire-magnificent-desolation-h");ns.ToggleFavorite("legion-suramar-part-1")
ns.UI.search:SetText("favorites")
assert(ns.UI.empty:IsShown() and #ns.GetFavoriteTracks("")==0 and visible(ns.UI.rows)==0)
ns.UI.search:SetText("")

-- Maximum-size favorites use the same bounded viewport pool.
for _,track in ipairs(ns.Catalog) do ns.DB.favorites[track.fileDataID]=true end
ns.FavoriteQuery,ns.FavoriteCache=nil,nil
ns.DB.favoritesCollapsed=false
ns.UI.search:SetText("favorites")
assert(#ns.GetFavoriteTracks("")==5493)
local favoriteMax=ns.UI.content:GetHeight()-ns.UI.scroll:GetHeight()
for i=0,100 do ns.UI.scroll:SetVerticalScroll(favoriteMax*i/100);assertViewport() end
assert(#ns.UI.rows<40 and #ns.UI.headers<40)
local lastFavorite=ns.GetFavoriteTracks("")[5493]
local reached=false
for _,r in ipairs(ns.UI.rows) do if r:IsShown() and r.trackKey==lastFavorite.key then reached=true end end
assert(reached,"last saved favorite is reachable")
ns.SelectTrack(lastFavorite.key)
assert(ns.Play())
local removeCalls=#engineCalls
ns.UI.favorite.scripts.OnClick(ns.UI.favorite)
assert(#ns.GetFavoriteTracks("")==5492 and #engineCalls==removeCalls and ns.State.activeTrack==lastFavorite.key)
ns.Stop()
assert(ns.UI.scroll:GetVerticalScroll()<=ns.UI.content:GetHeight()-ns.UI.scroll:GetHeight())
ns.DB.favorites={};ns.FavoriteQuery,ns.FavoriteCache=nil,nil
ns.UI.search:SetText("");ns.UI:Refresh()

ns.UI.resize.scripts.OnMouseDown(ns.UI.resize,"LeftButton")
assert(ns.UI.frame.sizing=="BOTTOMRIGHT")
ns.UI.frame:SetSize(520,420);ns.UI.scroll:SetSize(454,178)
ns.UI.resize.scripts.OnMouseUp(ns.UI.resize,"LeftButton")
assert(ns.DB.window.width==520 and ns.DB.window.height==420 and not ns.UI.frame.sizing)
assertViewport()
ns.SetMinimapAngle(-10);assert(ns.DB.minimap.angle==350)
ns.UI.minimap.scripts.OnDragStart(ns.UI.minimap)
ns.UI.minimap.scripts.OnUpdate(ns.UI.minimap,0.1)
ns.UI.minimap.scripts.OnDragStop(ns.UI.minimap)
assert(ns.DB.minimap.angle==0 and ns.UI.minimap.scripts.OnUpdate==nil)
ns.DB.collapsedExpansions.Shadowlands=true
local selected=ns.DB.selectedTrack
ns.Initialize()
assert(ns.DB.selectedTrack==selected and ns.DB.collapsedExpansions.Shadowlands==true)
assert(ns.DB.window.width==520 and ns.DB.window.height==420 and not ns.State.playing)
ns.HandleCommand("reset")
assert(ns.DB.window.width==440 and ns.DB.window.height==480 and ns.DB.minimap.angle==225)
MusicSCANDB={window={point="BAD",x=0/0},minimap={angle=math.huge},collapsedExpansions="bad"}
ns.Initialize()
assert(ns.DB.window.point=="CENTER" and ns.DB.minimap.angle==225 and ns.GetSelectedTrack())
assert(ns.DB.collapsedExpansions.Shadowlands==true and ns.DB.collapsedExpansions[ns.GetSelectedTrack().expansion]==nil)
-- Dispatch real registered lifecycle events; time and the audio engine are mocked.
local function Event(name, ...)
    assert(events.events[name], "event must be registered: "..name)
    events.scripts.OnEvent(events,name,...)
end
local A,B="wod-frostfire-magnificent-desolation-h","bfa-boralus-intro"
local function StartA()
    ns.SelectTrack(A)
    assert(ns.Play())
end
local function Transition()
    Event("PLAYER_LEAVING_WORLD")
    Event("LOADING_SCREEN_ENABLED")
    Event("PLAYER_ENTERING_WORLD",false,false)
    Event("LOADING_SCREEN_DISABLED")
end

-- Idle, initial-login and reload events never autoplay saved selections.
local baseline=#engineCalls
Event("LOADING_SCREEN_ENABLED")
Event("PLAYER_ENTERING_WORLD",true,false)
Event("LOADING_SCREEN_DISABLED")
Advance(10)
Event("PLAYER_ENTERING_WORLD",false,true)
Event("LOADING_SCREEN_DISABLED")
Transition();Advance(10)
assert(#engineCalls==baseline and PendingTimers()==0 and not ns.State.playing)

-- A slow load must finish before the one-second delay starts. Restore active A,
-- even though the user highlighted B, and even if the player window is hidden.
StartA();ns.SelectTrack(B);ns.UI.frame:Hide()
baseline=#engineCalls
Event("PLAYER_LEAVING_WORLD");Event("LOADING_SCREEN_ENABLED")
Event("PLAYER_ENTERING_WORLD",false,false)
Advance(30)
assert(#engineCalls==baseline and PendingTimers()==0)
Event("LOADING_SCREEN_DISABLED")
assert(PendingTimers()==1)
Advance(.9);assert(#engineCalls==baseline)
Advance(.2)
assert(#engineCalls==baseline+2 and engineCalls[#engineCalls][2]==936340)
assert(ns.State.activeTrack==A and ns.DB.selectedTrack==B and not ns.UI.frame:IsShown())
ns.UI.frame:Show();assert(ns.UI.nowTitle:GetText()=="Magnificent Desolation")
assert(PendingTimers()==0)
Advance(10000);assert(#engineCalls==baseline+2, "recovery must not poll or repeat")

-- Stop wins during loading, during the delay, and against an already queued callback.
Transition()
local stale=timers[#timers]
assert(ns.Stop());baseline=#engineCalls
stale.callback();Advance(2)
assert(#engineCalls==baseline and not ns.State.playing)
StartA();Event("LOADING_SCREEN_ENABLED");ns.Stop();baseline=#engineCalls
Event("PLAYER_ENTERING_WORLD",false,false);Event("LOADING_SCREEN_DISABLED");Advance(2)
assert(#engineCalls==baseline and PendingTimers()==0)

-- Explicit Play cancels restoration, including replaying the very same file.
StartA();Transition();stale=timers[#timers]
ns.SelectTrack(B);assert(ns.Play());baseline=#engineCalls
stale.callback();Advance(2)
assert(#engineCalls==baseline and ns.State.activeTrack==B)
Transition();stale=timers[#timers]
assert(ns.Play());baseline=#engineCalls
stale.callback();Advance(2)
assert(#engineCalls==baseline and ns.State.activeTrack==B)

-- Consecutive loads and reversed finish/entry ordering still restore only once.
StartA();Transition();stale=timers[#timers];baseline=#engineCalls
Event("LOADING_SCREEN_ENABLED");Advance(2)
assert(#engineCalls==baseline and PendingTimers()==0)
Event("PLAYER_LEAVING_WORLD");Event("LOADING_SCREEN_DISABLED")
assert(PendingTimers()==0)
Event("PLAYER_ENTERING_WORLD",false,false)
stale.callback();assert(PendingTimers()==1)
Event("PLAYER_ENTERING_WORLD",false,false);Event("LOADING_SCREEN_DISABLED")
assert(PendingTimers()==1)
Advance(1);assert(#engineCalls==baseline+2 and ns.State.activeTrack==A)
Event("LOADING_SCREEN_DISABLED");Advance(2)
assert(#engineCalls==baseline+2 and PendingTimers()==0)

-- Disabled audio and rejected/throwing requests clear the stale Playing display.
for _,cvar in ipairs({"Sound_EnableMusic","Sound_EnableAllSound"}) do
    StartA();Transition();baseline=#engineCalls
    cvars[cvar]=false;Advance(1)
    assert(not ns.State.playing and #engineCalls==baseline)
    assert(ns.UI.nowLabel:GetText()=="SELECTED TRACK" and not ns.UI.stop:IsEnabled())
    cvars[cvar]=true
end
StartA();Transition();musicAccepted=false;Advance(1)
assert(not ns.State.playing and ns.UI.nowLabel:GetText()=="SELECTED TRACK")
musicAccepted=true
StartA();Transition();musicThrows=true;Advance(1)
assert(not ns.State.playing)
musicThrows=false

-- Nil success returns remain accepted, matching explicit Play behavior.
StartA();Transition();musicAccepted=nil;Advance(1)
assert(ns.State.playing and ns.State.activeTrack==A)
musicAccepted=true

-- Logout and reinitialization invalidate delayed callbacks without changing favorites.
Transition();stale=timers[#timers];baseline=#engineCalls
Event("PLAYER_LOGOUT");stale.callback();Advance(2)
assert(#engineCalls==baseline and PendingTimers()==0)
ns.ToggleFavorite(A)
Transition();stale=timers[#timers]
ns.Initialize();baseline=#engineCalls
Event("PLAYER_ENTERING_WORLD",false,true);Event("LOADING_SCREEN_DISABLED")
stale.callback();Advance(2)
assert(#engineCalls==baseline and not ns.State.playing and ns.IsFavorite(A))
assert(PendingTimers()==0 and ns.UI.frame.scripts.OnUpdate==nil)
assert(not events.events.ZONE_CHANGED_NEW_AREA and not events.events.PLAYER_REGEN_DISABLED)
io.write("PASS: 5,493-track catalog, Favorites, viewport and playback regression; loading recovery handles slow/reordered/repeated transitions, active versus selected tracks, Stop/Play cancellation, stale callbacks, muted/failed playback, logout, and no autoplay after login or reload.\n")

