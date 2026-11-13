-- POC3-derived sound-handle engine. Selected audio follows Master Volume.
local addonName, host = ...
local ns = {Tracks={}}
host.Engine = ns
ns.Selected = 1
ns.State = {playing=false}
ns.History = {}
ns.Completed = 0
local ticker, recoveryTimer
local generation = 0
local loadingScreen, worldEntered, transitioning = false, false, false
local POLL_INTERVAL, START_TIMEOUT, RECOVERY_DELAY = 0.2, 30, 1
local overrideOwned = false

local function ReleaseOverride()
    local previous = ns.DB and ns.DB.restoreMusicVolume
    if previous ~= nil then
        local ok, current = pcall(C_CVar.GetCVar, "Sound_MusicVolume")
        if not ok or tonumber(current) == nil then return false end
        -- Respect a player adjustment made during the test instead of overwriting it.
        if tonumber(current) == 0 then
            local restored = pcall(C_CVar.SetCVar, "Sound_MusicVolume", previous)
            local verified, value = pcall(C_CVar.GetCVar, "Sound_MusicVolume")
            if not restored or not verified or tonumber(value) ~= tonumber(previous) then return false end
        end
        ns.DB.restoreMusicVolume = nil
    end
    overrideOwned = false
    return true
end

local lastHandle
function ns.Notify()
    local state=ns.State
    local track=state.index and ns.Tracks[state.index]
    host.State={playing=state.playing,activeTrack=track and track.key,suspended=state.suspended}
    if state.handle and state.handle~=lastHandle and track
        and state.reason~="Loading recovery" and state.reason~="Repeat" then
        host.DB.selectedTrack=track.key
    end
    lastHandle=state.handle
    host.Notify()
end
function ns.Log(message)
    ns.LastMessage=message
    ns.History[#ns.History+1]=message
    if #ns.History>40 then table.remove(ns.History,1) end
    host.Print(message)
    ns.Notify()
end

local function Invalidate()
    generation = generation + 1
    if ticker then ticker:Cancel(); ticker=nil end
    if recoveryTimer then recoveryTimer:Cancel(); recoveryTimer=nil end
end

-- Clear our identity BEFORE StopSound: its callback may fire synchronously.
local function RetireSound()
    local handle = ns.State.handle
    ns.State.handle = nil
    if handle ~= nil then
        local ok = pcall(StopSound, handle)
        if not ok then ns.Log("The client rejected StopSound for the previous handle.") end
    end
end

function ns.Stop(reason)
    Invalidate()
    local previous = ns.State
    ns.State = {playing=false}
    if previous.handle ~= nil then pcall(StopSound, previous.handle) end
    local restored = ReleaseOverride()
    if not restored then ns.Log("Music volume restoration is pending. Use /msc restore or restore it in Audio settings.") end
    if reason then ns.Log(reason) else ns.Log("Stopped. Automatic Next is canceled.") end
end

local function AudioReady()
    if type(PlaySoundFile) ~= "function" or type(StopSound) ~= "function"
        or type(C_Sound) ~= "table" or type(C_Sound.IsPlaying) ~= "function"
        or type(C_Timer) ~= "table" or type(C_Timer.NewTicker) ~= "function"
        or type(C_Timer.NewTimer) ~= "function" then
        return false, "This client does not expose the required sound-handle APIs."
    end
    if not C_CVar or type(C_CVar.GetCVarBool) ~= "function"
        or type(C_CVar.GetCVar) ~= "function" or type(C_CVar.SetCVar) ~= "function" then
        return false, "This client does not expose the required audio-setting checks."
    end
    if not C_CVar.GetCVarBool("Sound_EnableAllSound") or not C_CVar.GetCVarBool("Sound_EnableMusic") then
        return false, "Enable Sound and Music in WoW Audio settings, then press Play."
    end
    return true
end

function ns.Start(index, reason)
    if not ns.Tracks[index] then return false end
    Invalidate()
    RetireSound()
    ns.State = {playing=false}
    local ready, errorMessage = AudioReady()
    if not ready then ReleaseOverride(); ns.Log(errorMessage); return false end
    if transitioning then
        ReleaseOverride()
        ns.Log("Wait for the loading transition to finish, then press Play.")
        return false
    end
    local track = ns.Tracks[index]
    -- The Music-channel file path mixed with zone music on the test client.
    -- Temporarily mute ONLY Music volume, and route our handled file through Master.
    -- Preserve the original value across the queue and save a reload recovery marker.
    if not overrideOwned then
        if not ReleaseOverride() then ns.Log("Restore the pending Music volume before starting another test."); return false end
        local readOK, previous = pcall(C_CVar.GetCVar, "Sound_MusicVolume")
        local volume = tonumber(previous)
        if not readOK or not volume or volume < 0 or volume > 1 then
            ns.Log("Could not read Music volume safely; test not started.")
            return false
        end
        ns.DB.restoreMusicVolume = previous
        local muteOK = pcall(C_CVar.SetCVar, "Sound_MusicVolume", 0)
        local verifyOK, current = pcall(C_CVar.GetCVar, "Sound_MusicVolume")
        if not muteOK or not verifyOK or tonumber(current) ~= 0 then
            ReleaseOverride(); ns.Log("Could not mute zone music; test not started."); return false
        end
        overrideOwned = true
    end
    local ok, accepted, handle = pcall(PlaySoundFile, track.fileDataID, "Master")
    if not ok or accepted ~= true or handle == nil then
        if ok and handle ~= nil then pcall(StopSound, handle) end
        ReleaseOverride()
        ns.Log("Unable to start " .. track.title .. ". No next-track retry was scheduled.")
        return false
    end
    ns.Selected = index
    local state = {playing=true, index=index, handle=handle, observedPlaying=false, startedAt=GetTime(), reason=reason}
    ns.State = state
    local token = generation
    ticker = C_Timer.NewTicker(POLL_INTERVAL, function()
        if generation ~= token or ns.State ~= state or not state.playing or state.handle ~= handle then return end
        local queryOK, isPlaying = pcall(C_Sound.IsPlaying, handle)
        if not queryOK or type(isPlaying) ~= "boolean" then
            ns.Stop("Sound-handle status failed; playback stopped safely.")
        elseif isPlaying then
            if not state.observedPlaying then
                state.observedPlaying = true
                ns.Notify()
            end
        elseif state.observedPlaying then
            ns.Finish(handle, "handle stopped")
        elseif GetTime() - state.startedAt >= START_TIMEOUT then
            ns.Stop("The handle never reported playing within 30 seconds. No automatic advance.")
        end
    end)
    ns.Log((reason or "Play") .. ": " .. track.title .. " | FileDataID " .. track.fileDataID .. " | handle " .. tostring(handle))
    return true
end

function ns.Play()
    return ns.Start(ns.Selected, "Play")
end

function ns.Next()
    local index = ns.State.playing and ns.State.index or ns.Selected
    return ns.Start(index % #ns.Tracks + 1, "Next")
end

function ns.SetRepeat(enabled)
    ns.DB.repeatTrack = enabled == true
    ns.Log(ns.DB.repeatTrack and "Repeat ON: repeat the active track when its handle ends."
        or "Repeat OFF: advance to the next track when its handle ends.")
end

function ns.Finish(handle, source)
    local state = ns.State
    if not state.playing or state.suspended or state.handle ~= handle or transitioning then return end
    -- IsPlaying does not reveal WHY a handle stopped. In-game listening must confirm
    -- natural endings rather than interruption/voice stealing. This is a POC.
    local nextIndex = ns.DB.repeatTrack and state.index or (state.index % #ns.Tracks + 1)
    local repeatTrack = ns.DB.repeatTrack
    ns.Completed = ns.Completed + 1
    Invalidate()
    state.handle = nil -- The completed handle is already stopped.
    ns.State = {playing=false}
    ns.Log("Completion #" .. ns.Completed .. " (" .. source .. ") -> " .. (repeatTrack and "repeat" or "next"))
    ns.Start(nextIndex, repeatTrack and "Repeat" or "Automatic Next")
end

local function QueueRecovery()
    if not ns.State.playing or not ns.State.suspended or not worldEntered or loadingScreen then return end
    Invalidate()
    local token, intent = generation, ns.State
    recoveryTimer = C_Timer.NewTimer(RECOVERY_DELAY, function()
        if generation ~= token or ns.State ~= intent or loadingScreen or not worldEntered then return end
        recoveryTimer = nil
        transitioning = false
        ns.Start(intent.index, "Loading recovery")
    end)
end

function ns.OnEvent(event, arg1, arg2)
    if event == "SOUNDKIT_FINISHED" then
        local state = ns.State
        if state.playing and not state.suspended and state.handle == arg1 then
            local ok, isPlaying = pcall(C_Sound.IsPlaying, arg1)
            if ok and isPlaying == false then ns.Finish(arg1, "SOUNDKIT_FINISHED") end
        end
    elseif event == "PLAYER_LEAVING_WORLD" or event == "LOADING_SCREEN_ENABLED" then
        Invalidate()
        transitioning, worldEntered = true, false
        if event == "LOADING_SCREEN_ENABLED" then loadingScreen=true end
        if ns.State.playing then
            ns.State.suspended=true
            RetireSound()
            ReleaseOverride()
            ns.Log("Loading: suspend active track without advancing the queue.")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if arg1 or arg2 then
            loadingScreen, transitioning, worldEntered = false, false, false
            ns.Stop("Login/reload: playback stays idle.")
        else
            worldEntered=true
            if not loadingScreen then transitioning=false end
            QueueRecovery()
        end
    elseif event == "LOADING_SCREEN_DISABLED" then
        loadingScreen=false
        if worldEntered then transitioning=false end
        QueueRecovery()
    elseif event == "PLAYER_LOGOUT" then
        ns.Stop("Logout: canceled the test playback.")
    end
end

function ns.Status()
    local state = ns.State
    ns.Log("Status: " .. (state.suspended and "loading" or state.playing and "active" or "idle")
        .. "; selected=" .. ns.Selected .. "; active=" .. tostring(state.index)
        .. "; handle=" .. tostring(state.handle) .. "; observed=" .. tostring(state.observedPlaying)
        .. "; repeat=" .. tostring(ns.DB.repeatTrack) .. "; completions=" .. ns.Completed)
end

function host.InitializePlayback()
    if ns.DB then ns.Stop("Reinitialization: playback stays idle.") end
    ns.DB=host.DB
    ns.State={playing=false}
    ns.Tracks={}
    if ns.DB.restoreMusicVolume~=nil then
        local value=tonumber(ns.DB.restoreMusicVolume)
        if value and value>=0 and value<=1 then
            if not ReleaseOverride() then ns.Log("Music volume restoration is pending. Use /msc restore.") end
        else ns.DB.restoreMusicVolume=nil end
    end
end
