-- Core: initialization, catalog access, playback, preferences and slash commands.
local addonName, ns = ...

ns.VERSION = "0.8.0 BETA1 HOTFIX1"
ns.AUTHOR = "SCAN | Kilobytes Development"
ns.WEBSITE = "www.kilobytes.dev"
ns.ICON = "Interface\\Icons\\inv_holiday_brewfestbuff_01"
ns.State = { playing = false }
ns.WindowDefaults = { width = 760, height = 560, minWidth = 620, minHeight = 460 }

local DEFAULT_ANGLE = 225

local function IsFinite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function ns.Print(message, force)
    if not force and not (ns.DB and ns.DB.debugMode) then return end
    print("|cffd6c6a4MusicSCAN|r: " .. message)
end

function ns.Notify()
    if ns.UI then ns.UI:Refresh() end
end

function ns.GetTrack(key)
    return ns.TracksByKey and ns.TracksByKey[key]
end

function ns.GetSelectedTrack()
    return ns.GetTrack(ns.DB.selectedTrack)
end

function ns.GetActiveTrack()
    return ns.GetTrack(ns.State.activeTrack)
end

-- Catalog queries use literal matching; source text is normalized once at login.
function ns.GetFilteredCatalog(query)
    query = (query or ""):lower():match("^%s*(.-)%s*$")
    local result = {}
    for _, track in ipairs(ns.SortedCatalog) do
        local searchable = ns.SearchTextByKey[track.key]
        if query == "" or searchable:find(query, 1, true) then
            result[#result + 1] = track
        end
    end
    return result
end

function ns.SelectTrack(key)
    if not ns.GetTrack(key) then return false end
    ns.DB.selectedTrack = key
    ns.Notify()
    return true
end

function ns.GetExpansionGroups(query)
    query = (query or ""):lower():match("^%s*(.-)%s*$")
    local cacheKey = ns.DB.librarySource .. "|" .. query
    if ns.GroupQuery == cacheKey then return ns.GroupCache end
    local groups, byName = {}, {}
    for _, track in ipairs(ns.GetBrowseTracks(query)) do
        local group = byName[track.expansion]
        if not group then
            group = { name = track.expansion, tracks = {} }
            byName[track.expansion] = group
            groups[#groups + 1] = group
        end
        group.tracks[#group.tracks + 1] = track
    end
    table.sort(groups, function(a, b)
        local ar = ns.ExpansionOrder[a.name] or math.huge
        local br = ns.ExpansionOrder[b.name] or math.huge
        if ar ~= br then return ar < br end
        return a.name:lower() < b.name:lower()
    end)
    ns.GroupQuery, ns.GroupCache = cacheKey, groups
    return groups
end

function ns.ToggleExpansion(expansion)
    if not ns.Expansions[expansion] then return false end
    ns.DB.collapsedExpansions[expansion] = not ns.DB.collapsedExpansions[expansion] or nil
    ns.Notify()
    return true
end

-- Favorites follow audio IDs so friendly-name updates do not lose saved tracks.
function ns.IsFavorite(key)
    local track = ns.GetTrack(key)
    return track ~= nil and ns.DB.favorites[track.fileDataID] == true
end

function ns.ToggleFavorite(key)
    local track = ns.GetTrack(key)
    if not track then return false end
    ns.DB.favorites[track.fileDataID] = not ns.IsFavorite(key) or nil
    ns.FavoriteQuery, ns.FavoriteCache = nil, nil
    ns.Notify()
    return true
end

function ns.GetFavoriteTracks(query)
    query = (query or ""):lower():match("^%s*(.-)%s*$")
    if query == "favorites" then query = "" end
    if ns.FavoriteQuery == query then return ns.FavoriteCache end
    local tracks = {}
    for fileID in pairs(ns.DB.favorites) do
        local track = ns.TracksByFileID[fileID]
        if track and (query == "" or ns.SearchTextByKey[track.key]:find(query, 1, true)) then
            tracks[#tracks + 1] = track
        end
    end
    table.sort(tracks, function(a, b)
        local at, bt = a.title:lower(), b.title:lower()
        if at ~= bt then return at < bt end
        local az, bz = a.zone:lower(), b.zone:lower()
        if az ~= bz then return az < bz end
        local ar, br = ns.ExpansionOrder[a.expansion] or math.huge, ns.ExpansionOrder[b.expansion] or math.huge
        if ar ~= br then return ar < br end
        return a.fileDataID < b.fileDataID
    end)
    ns.FavoriteQuery, ns.FavoriteCache = query, tracks
    return tracks
end

function ns.ToggleFavoritesCategory()
    ns.DB.favoritesCollapsed = not ns.DB.favoritesCollapsed
    ns.Notify()
end

-- Playback lives in Playback.lua; queues snapshot the current ordered view on Play.
function ns.GetBrowseTracks(query)
    local source = ns.DB.librarySource
    if source == "favorites" then return ns.GetFavoriteTracks(query) end
    local result = {}
    for _, track in ipairs(ns.GetFilteredCatalog(query)) do
        if source == "all" or (source:sub(1,10)=="expansion:" and track.expansion==source:sub(11))
            or (ns.ThemeKeys[source] and ns.ThemeKeys[source][track.key]) then
            result[#result+1] = track
        end
    end
    return result
end

function ns.SetLibrarySource(source)
    if type(source)~="string" then return false end
    if source~="all" and source~="favorites" and not ns.ThemeKeys[source]
        and not (source:sub(1,10)=="expansion:" and ns.Expansions[source:sub(11)]) then return false end
    ns.DB.librarySource=source
    ns.GroupQuery,ns.GroupCache=nil,nil
    if ns.UI then
        ns.UI.searchCollapsed={}; ns.UI.searchFavoritesCollapsed=false
        ns.UI.scroll:SetVerticalScroll(0)
    end
    ns.Notify()
    return true
end

local function CaptureQueue()
    local query = ns.UI and ns.UI.search:GetText() or ""
    local queue = {}
    if ns.DB.librarySource=="favorites" then
        queue=ns.GetFavoriteTracks(query)
    else
        for _,group in ipairs(ns.GetExpansionGroups(query)) do
            for _,track in ipairs(group.tracks) do queue[#queue+1]=track end
        end
    end
    local selected=ns.GetSelectedTrack()
    if not selected then return nil end
    local index
    for i,track in ipairs(queue) do if track.key==selected.key then index=i;break end end
    if not index then queue={selected};index=1 end
    ns.Engine.Tracks=queue
    ns.Engine.Selected=index
    ns.ActiveQueueSource=ns.DB.librarySource
    return index
end

function ns.Play()
    local index=CaptureQueue()
    return index and ns.Engine.Start(index,"Play") or false
end
function ns.Next()
    if not ns.Engine.State.playing then if not CaptureQueue() then return false end end
    return ns.Engine.Next()
end
function ns.Stop()
    ns.Engine.Stop()
    return true
end
function ns.ToggleRepeat()
    ns.Engine.SetRepeat(not ns.DB.repeatTrack)
end

-- Clamp saved geometry to the current UI dimensions before restoring it.
function ns.GetWindowBounds()
    local defaults = ns.WindowDefaults
    return defaults.minWidth, defaults.minHeight,
        math.max(defaults.minWidth, UIParent:GetWidth() - 20),
        math.max(defaults.minHeight, UIParent:GetHeight() - 20)
end

function ns.NormalizeWindowSize(width, height)
    local minWidth, minHeight, maxWidth, maxHeight = ns.GetWindowBounds()
    if not IsFinite(width) then width = ns.WindowDefaults.width end
    if not IsFinite(height) then height = ns.WindowDefaults.height end
    return math.min(maxWidth, math.max(minWidth, width)),
        math.min(maxHeight, math.max(minHeight, height))
end

function ns.SaveWindowSize(frame)
    ns.DB.window.width, ns.DB.window.height = ns.NormalizeWindowSize(frame:GetWidth(), frame:GetHeight())
end

function ns.SaveWindowPosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    ns.DB.window.point = point
    ns.DB.window.relativePoint = relativePoint
    ns.DB.window.x = x
    ns.DB.window.y = y
    ns.SaveWindowSize(frame)
end

function ns.BeginWindowResize(frame)
    frame:SetResizeBounds(ns.GetWindowBounds())
    frame:StartSizing("BOTTOMRIGHT")
end

function ns.EndWindowResize(frame)
    frame:StopMovingOrSizing()
    ns.SaveWindowPosition(frame)
end

function ns.SetMinimapAngle(angle)
    if not IsFinite(angle) then return end
    ns.DB.minimap.angle = angle % 360
    if ns.UI then ns.UI:UpdateMinimapPosition() end
end

function ns.ToggleWindow()
    if not ns.UI then return end
    local frame = ns.UI.frame
    frame:SetShown(not frame:IsShown())
end

function ns.ResetPosition()
    ns.DB.window.point, ns.DB.window.relativePoint = "CENTER", "CENTER"
    ns.DB.window.x, ns.DB.window.y = 0, 0
    ns.DB.window.width, ns.DB.window.height = ns.NormalizeWindowSize(nil, nil)
    ns.DB.minimap.angle = DEFAULT_ANGLE
    if ns.UI then
        ns.UI:RestoreWindowPosition()
        ns.UI:UpdateMinimapPosition()
        ns.UI.frame:Show()
    end
    ns.Print("Player size and position, and minimap button position reset.")
end

-- Both slash aliases share this dispatcher; unknown input also shows help.
function ns.HandleCommand(message)
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "" then ns.ToggleWindow()
    elseif command == "debug on" then
        ns.DB.debugMode = true
        ns.Print("Debug logging ON.", true)
    elseif command == "debug off" then
        ns.DB.debugMode = false
        ns.Print("Debug logging OFF.", true)
    elseif command == "debug" or command == "debug status" then
        ns.Print("Debug logging " .. (ns.DB.debugMode and "ON" or "OFF") .. ". Use /msc debug on or /msc debug off.", true)
    elseif command == "play" then ns.Play()
    elseif command == "stop" or command == "restore" then ns.Stop()
    elseif command == "next" then ns.Next()
    elseif command == "repeat" then ns.ToggleRepeat()
    elseif command == "status" then
        ns.Engine.Status()
        ns.Print("Queue: " .. (ns.ActiveQueueSource or "none") .. " | " .. #ns.Engine.Tracks .. " tracks", true)
    elseif command == "reset" then ns.ResetPosition()
    else
        ns.Print("/musicscan or /msc - open/close; play - restart selection; stop/restore - restore zone music; next; repeat; status; reset - reset window/minimap; debug on/off - logging.", true)
    end
end

local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

-- Validate saved preferences without discarding existing selections or favorites.
function ns.Initialize()
    ns.TracksByKey, ns.TracksByFileID, ns.SortedCatalog, ns.Expansions, ns.SearchTextByKey = {}, {}, {}, {}, {}
    ns.GroupQuery, ns.GroupCache = nil, nil
    ns.FavoriteQuery, ns.FavoriteCache = nil, nil
    for _, track in ipairs(ns.Catalog) do
        ns.TracksByKey[track.key] = track
        ns.TracksByFileID[track.fileDataID] = track
        ns.SortedCatalog[#ns.SortedCatalog + 1] = track
        ns.Expansions[track.expansion] = true
        ns.SearchTextByKey[track.key] = (track.zone .. " " .. track.title .. " " .. track.expansion):lower()
    end
    table.sort(ns.SortedCatalog, function(a, b)
        local az, bz = a.zone:lower(), b.zone:lower()
        if az ~= bz then return az < bz end
        local at, bt = a.title:lower(), b.title:lower()
        if at ~= bt then return at < bt end
        return a.key < b.key
    end)

    if type(MusicSCANDB) ~= "table" then MusicSCANDB = {} end
    ns.DB = MusicSCANDB
    ns.DB.schemaVersion = 1
    ns.DB.debugMode = ns.DB.debugMode == true
    ns.DB.repeatTrack = ns.DB.repeatTrack == true
    local source = ns.DB.librarySource
    if type(source)~="string" or (source~="all" and source~="favorites" and not ns.ThemeKeys[source]
        and not (source:sub(1,10)=="expansion:" and ns.Expansions[source:sub(11)])) then
        ns.DB.librarySource="all"
    end
    -- Retire the old nonfunctional loop preference without changing WoW audio settings.
    ns.DB.loopMusic = nil
    if type(ns.DB.favorites) ~= "table" then ns.DB.favorites = {} end
    for fileID, saved in pairs(ns.DB.favorites) do
        -- Keep valid IDs even if a later catalog temporarily omits the track.
        if not IsFinite(fileID) or fileID <= 0 or fileID % 1 ~= 0 or saved ~= true then
            ns.DB.favorites[fileID] = nil
        end
    end
    ns.DB.favoritesCollapsed = ns.DB.favoritesCollapsed == true
    if not ns.GetTrack(ns.DB.selectedTrack) then
        ns.DB.selectedTrack = ns.GetTrack(ns.DEFAULT_TRACK_KEY) and ns.DEFAULT_TRACK_KEY
            or (ns.SortedCatalog[1] and ns.SortedCatalog[1].key)
    end
    if type(ns.DB.collapsedExpansions) ~= "table" then
        ns.DB.collapsedExpansions = {}
        local selected = ns.GetSelectedTrack()
        for expansion in pairs(ns.Expansions) do
            if not selected or expansion ~= selected.expansion then
                ns.DB.collapsedExpansions[expansion] = true
            end
        end
    else
        for expansion, collapsed in pairs(ns.DB.collapsedExpansions) do
            if not ns.Expansions[expansion] or collapsed ~= true then
                ns.DB.collapsedExpansions[expansion] = nil
            end
        end
    end
    if type(ns.DB.window) ~= "table" then ns.DB.window = {} end
    local window = ns.DB.window
    window.width, window.height = ns.NormalizeWindowSize(window.width, window.height)
    if not VALID_POINTS[window.point] or not VALID_POINTS[window.relativePoint]
        or not IsFinite(window.x) or not IsFinite(window.y) then
        window.point, window.relativePoint, window.x, window.y = "CENTER", "CENTER", 0, 0
    end
    window.visible = window.visible == true
    if type(ns.DB.minimap) ~= "table" then ns.DB.minimap = {} end
    if not IsFinite(ns.DB.minimap.angle) then ns.DB.minimap.angle = DEFAULT_ANGLE end
    ns.DB.minimap.angle = ns.DB.minimap.angle % 360

    ns.State = { playing = false } -- Remember selection, never autoplay at login/reload.
    SLASH_MUSICSCAN1, SLASH_MUSICSCAN2 = "/musicscan", "/msc"
    SlashCmdList.MUSICSCAN = ns.HandleCommand
    ns.InitializePlayback()
    ns.BuildUI()
    ns.Print("v" .. ns.VERSION .. " loaded. Click the minimap button or type /musicscan.")
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("SOUNDKIT_FINISHED")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("LOADING_SCREEN_ENABLED")
events:RegisterEvent("LOADING_SCREEN_DISABLED")
events:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        ns.Initialize()
    elseif event == "PLAYER_LOGOUT" then
        if ns.Engine then ns.Engine.OnEvent("PLAYER_LOGOUT") end
        if ns.UI then
            ns.UI.frame:StopMovingOrSizing()
            ns.SaveWindowPosition(ns.UI.frame)
        end
    elseif ns.DB then
        ns.Engine.OnEvent(event, arg1, arg2)
    end
end)
