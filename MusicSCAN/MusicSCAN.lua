-- Core: initialization, catalog access, playback, preferences and slash commands.
local addonName, ns = ...

ns.VERSION = "0.7.1 BETA"
ns.AUTHOR = "SCAN | Kilobytes Development"
ns.WEBSITE = "www.kilobytes.dev"
ns.ICON = "Interface\\Icons\\inv_holiday_brewfestbuff_01"
ns.State = { playing = false }
ns.WindowDefaults = { width = 440, height = 480, minWidth = 380, minHeight = 360 }

local DEFAULT_ANGLE = 225
local RECOVERY_DELAY = 1
local recoveryTimer, recoveryGeneration = nil, 0
local loadingScreen, worldEntered = false, false

-- Generation checks also reject callbacks that were already queued when canceled.
local function CancelRecovery()
    recoveryGeneration = recoveryGeneration + 1
    if recoveryTimer then
        recoveryTimer:Cancel()
        recoveryTimer = nil
    end
end

local function IsFinite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function ns.Print(message)
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
    if ns.GroupQuery == query then return ns.GroupCache end
    local groups, byName = {}, {}
    for _, track in ipairs(ns.GetFilteredCatalog(query)) do
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
    ns.GroupQuery, ns.GroupCache = query, groups
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

-- Both explicit Play and post-loading recovery use the same audio checks.
local function PlayTrack(track)
    if not track then return false, "Select a track first." end
    if not C_CVar.GetCVarBool("Sound_EnableAllSound") then
        ns.Print("Enable Sound in WoW's Audio settings, then press Play.")
        return false
    end
    if not C_CVar.GetCVarBool("Sound_EnableMusic") then
        ns.Print("Enable Music in WoW's Audio settings, then press Play.")
        return false
    end

    -- Explicit stop ensures that pressing Play restarts even the same file.
    -- No global audio settings are changed.
    StopMusic()
    ns.State = { playing = false }
    local accepted, willPlay = pcall(PlayMusic, track.fileDataID)
    if not accepted or willPlay == false then
        ns.Print("Unable to play " .. track.title .. " (FileDataID " .. track.fileDataID .. "). Check your Audio settings or try another track.")
        ns.Notify()
        return false
    end
    -- PlayMusic does not return an audio-position handle. This state records
    -- the accepted request; it cannot detect engine interruptions or silence.
    ns.State = { playing = true, activeTrack = track.key }
    ns.Notify()
    return true
end

function ns.Play()
    CancelRecovery()
    worldEntered = false
    return PlayTrack(ns.GetSelectedTrack())
end

function ns.Stop()
    CancelRecovery()
    worldEntered = false
    if not ns.State.playing then return false end
    StopMusic()
    ns.State = { playing = false }
    ns.Notify()
    return true
end

-- Restore the active request once after a transition. Never poll the audio engine.
local function QueueRecovery()
    CancelRecovery()
    if not worldEntered or loadingScreen or not ns.State.playing then return end
    local intent = ns.State
    local track = ns.GetActiveTrack()
    if not track then return end
    local generation = recoveryGeneration
    recoveryTimer = C_Timer.NewTimer(RECOVERY_DELAY, function()
        if generation ~= recoveryGeneration then return end
        recoveryTimer = nil
        if loadingScreen or not worldEntered or ns.State ~= intent or not intent.playing then return end
        worldEntered = false
        -- Selection may have changed while loading; keep the track that was playing.
        -- PlayMusic cannot seek, so restoring starts the file from its beginning.
        if not PlayTrack(track) then
            ns.State = { playing = false }
            ns.Notify()
        end
    end)
end

local function OnWorldTransition(event, isInitialLogin, isReloadingUi)
    if event == "PLAYER_LEAVING_WORLD" or event == "LOADING_SCREEN_ENABLED" then
        CancelRecovery()
        worldEntered = false
        if event == "LOADING_SCREEN_ENABLED" then loadingScreen = true end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CancelRecovery()
        -- Initial login and reload stay idle, regardless of saved selection.
        worldEntered = not isInitialLogin and not isReloadingUi
        if worldEntered then QueueRecovery() end
    elseif event == "LOADING_SCREEN_DISABLED" then
        loadingScreen = false
        -- If world entry arrives later, that event will schedule the same recovery.
        QueueRecovery()
    end
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
    elseif command == "play" then ns.Play()
    elseif command == "stop" then ns.Stop()
    elseif command == "reset" then ns.ResetPosition()
    else
        ns.Print("/musicscan or /msc - open/close; play - restart selection; stop - restore zone music; reset - reset window layout and minimap position.")
    end
end

local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

-- Validate saved preferences without discarding existing selections or favorites.
function ns.Initialize()
    CancelRecovery()
    loadingScreen, worldEntered = false, false
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
    ns.BuildUI()
    ns.Print("v" .. ns.VERSION .. " loaded. Click the minimap button or type /musicscan.")
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("LOADING_SCREEN_ENABLED")
events:RegisterEvent("LOADING_SCREEN_DISABLED")
events:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        ns.Initialize()
    elseif event == "PLAYER_LOGOUT" then
        CancelRecovery()
        worldEntered = false
        if ns.UI then
            ns.UI.frame:StopMovingOrSizing()
            ns.SaveWindowPosition(ns.UI.frame)
        end
    elseif ns.DB then
        OnWorldTransition(event, arg1, arg2)
    end
end)
