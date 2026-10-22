-- Presentation only: frames, controls, library rows and minimap launcher.
-- Playback and commands are owned by MusicSCAN.lua; catalog by Database.lua.
local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 214 / 255, 198 / 255, 164 / 255 }
local MONK = RAID_CLASS_COLORS.MONK
local UI = {}

local function Backdrop(frame, r, g, b, border)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(r, g, b, 1)
    frame:SetBackdropBorderColor(border or 0.25, border or 0.25, border or 0.25, 1)
end

local function Label(parent, size, r, g, b)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, size, "")
    text:SetTextColor(r or 0.96, g or 0.96, b or 0.96)
    text:SetJustifyH("LEFT")
    return text
end

local function Divider(parent, anchor, x, y, gold)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint(anchor, parent, anchor, x, y)
    local opposite = anchor:gsub("LEFT", "RIGHT")
    line:SetPoint(opposite, parent, opposite, -x, y)
    line:SetHeight(1)
    if gold then line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.32)
    else line:SetColorTexture(1, 1, 1, 0.14) end
    return line
end

local function Button(parent, title, action)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(76, 30)
    Backdrop(button, 0.055, 0.055, 0.06)
    button.text = Label(button, 13)
    button.text:SetPoint("CENTER")
    button.text:SetText(title)
    button:SetScript("OnClick", action)
    button:SetScript("OnEnter", function(self)
        if self:IsEnabled() then self:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.8) end
    end)
    button:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1) end)
    button:SetScript("OnEnable", function(self) self.text:SetTextColor(0.96, 0.96, 0.96) end)
    button:SetScript("OnDisable", function(self) self.text:SetTextColor(0.4, 0.4, 0.4) end)
    return button
end

local function AboutTooltip(owner)
    -- Open toward the window interior; clamp at other screen edges.
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetClampedToScreen(true)
    GameTooltip:SetText("MusicSCAN", 1, 1, 1)
    GameTooltip:AddLine("Author: " .. ns.AUTHOR, 0.85, 0.85, 0.85)
    GameTooltip:AddLine("Website: " .. ns.WEBSITE, GOLD[1], GOLD[2], GOLD[3])
    GameTooltip:AddLine("Version: " .. ns.VERSION, 0.85, 0.85, 0.85)
    GameTooltip:Show()
end

local function FavoriteTooltip(owner)
    local track = ns.GetSelectedTrack()
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetClampedToScreen(true)
    if track then
        GameTooltip:SetText(ns.IsFavorite(track.key) and "Remove from Favorites" or "Add to Favorites", GOLD[1], GOLD[2], GOLD[3])
        GameTooltip:AddLine(track.title, 1, 1, 1, true)
        GameTooltip:AddLine(track.zone .. " | " .. track.expansion, 0.7, 0.7, 0.7, true)
    else
        GameTooltip:SetText("Select a track to add a favorite", GOLD[1], GOLD[2], GOLD[3])
    end
    GameTooltip:Show()
end

function UI:RestoreWindowPosition()
    local p = ns.DB.window
    self.frame:SetResizeBounds(ns.GetWindowBounds())
    self.frame:SetSize(p.width, p.height)
    self.frame:ClearAllPoints()
    self.frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
end

function UI:LayoutLibrary()
    if not self.content then return end
    self.content:SetWidth(math.max(1, self.scroll:GetWidth()))
    self:RenderLibrary()
end

function UI:UpdateMinimapPosition()
    local radians = math.rad(ns.DB.minimap.angle)
    local radiusX = Minimap:GetWidth() / 2 + 6
    local radiusY = Minimap:GetHeight() / 2 + 6
    self.minimap:ClearAllPoints()
    self.minimap:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radiusX, math.sin(radians) * radiusY)
end

function UI:PaintTrackRow(row)
    local selected = ns.DB.selectedTrack == row.trackKey
    local hovered = row:IsMouseOver()
    row:SetBackdropColor(selected and 0.16 or (hovered and 0.12 or 0.075),
        selected and 0.145 or (hovered and 0.12 or 0.075),
        selected and 0.115 or (hovered and 0.13 or 0.08), 1)
    if selected then row:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.38)
    else row:SetBackdropBorderColor(0, 0, 0, 0) end
end

function UI:GetRow(index)
    if self.rows[index] then return self.rows[index] end
    local row = CreateFrame("Button", nil, self.content, "BackdropTemplate")
    Backdrop(row, 0.075, 0.075, 0.08)
    row.title = Label(row, 12)
    row.title:SetPoint("LEFT", 10, 0)
    row.title:SetPoint("RIGHT", -56, 0)
    row.title:SetWordWrap(false)
    row.playing = Label(row, 10, GOLD[1], GOLD[2], GOLD[3])
    row.playing:SetPoint("RIGHT", -8, 0)
    row.playing:SetText("Playing")
    row:SetScript("OnClick", function(self) ns.SelectTrack(self.trackKey) end)
    row:SetScript("OnEnter", function(self)
        UI:PaintTrackRow(self)
        local track = ns.GetTrack(self.trackKey)
        if not track then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(track.title, 1, 1, 1)
        GameTooltip:AddLine(track.zone, GOLD[1], GOLD[2], GOLD[3])
        GameTooltip:AddLine(track.expansion, 0.7, 0.7, 0.7)
        GameTooltip:AddLine("FileDataID: " .. track.fileDataID, 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Select this track, then click Play.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self) UI:PaintTrackRow(self); GameTooltip:Hide() end)
    self.rows[index] = row
    return row
end

-- Logical items describe the full library. Only viewport items receive frames.
function UI:RenderLibrary()
    if self.rendering then return end
    self.rendering = true
    local query = self.search:GetText()
    local searching = query:find("%S") ~= nil
    local groups = ns.GetExpansionGroups(query)
    local favorites = ns.GetFavoriteTracks(query)
    local items, y = {}, 0
    local function Add(item, height)
        item.y, item.height = y, height
        items[#items + 1] = item
        y = y + height
    end
    for _, group in ipairs(groups) do
        local collapsed
        if searching then collapsed = self.searchCollapsed[group.name] == true
        else collapsed = ns.DB.collapsedExpansions[group.name] == true end
        Add({kind="expansion", name=group.name, collapsed=collapsed,
             searching=searching, count=#group.tracks}, 32)
        if not collapsed then
            local lastZone
            for _, track in ipairs(group.tracks) do
                if track.zone ~= lastZone then
                    Add({kind="zone", name=track.zone}, 28)
                    lastZone = track.zone
                end
                Add({kind="track", track=track}, 32)
            end
        end
    end
    if #groups == 0 and #favorites == 0 then y = y + 32 end -- Reserve the no-results label.
    local favoritesCollapsed
    if searching then favoritesCollapsed = self.searchFavoritesCollapsed
    else favoritesCollapsed = ns.DB.favoritesCollapsed end
    Add({kind="expansion", name="Favorites", isFavorites=true, collapsed=favoritesCollapsed,
         searching=searching, count=#favorites}, 32)
    if not favoritesCollapsed then
        if #favorites == 0 then
            Add({kind="message", name=searching and "No matching favorites." or "Select a track and click the star."}, 28)
        else
            for _, track in ipairs(favorites) do Add({kind="track", track=track}, 32) end
        end
    end
    self.libraryItems = items
    self.empty:SetShown(#groups == 0 and #favorites == 0)
    self.content:SetHeight(math.max(y, self.scroll:GetHeight()))
    local maxScroll = math.max(0, y - self.scroll:GetHeight())
    self.scroll:SetVerticalScroll(math.min(self.scroll:GetVerticalScroll(), maxScroll))
    self.rendering = false
    self:RenderVisibleLibrary()
end

function UI:RenderVisibleLibrary()
    if self.rendering or not self.libraryItems then return end
    for _, row in ipairs(self.rows) do row:Hide() end
    for _, header in ipairs(self.headers) do header:Hide() end
    for _, header in ipairs(self.expansionHeaders) do header:Hide() end
    local items = self.libraryItems
    local top = self.scroll:GetVerticalScroll()
    local bottom = top + self.scroll:GetHeight()
    local low, high = 1, #items
    -- Locate the first visible item without scanning thousands of hidden rows.
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if items[mid].y + items[mid].height <= top then low = mid + 1
        else high = mid - 1 end
    end
    local rowIndex, zoneIndex, expansionIndex = 0, 0, 0
    for i = low, #items do
        local item = items[i]
        if item.y >= bottom then break end
        if item.kind == "expansion" then
            expansionIndex = expansionIndex + 1
            local header = self:GetExpansionHeader(expansionIndex)
            header.expansion, header.searching, header.isFavorites = item.name, item.searching, item.isFavorites
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", 0, -item.y)
            header:SetSize(self.content:GetWidth(), 28)
            header.toggle:SetText(item.collapsed and "+" or "-")
            header.title:SetText(item.name)
            header.count:SetText(tostring(item.count))
            header:Show()
        elseif item.kind == "zone" or item.kind == "message" then
            zoneIndex = zoneIndex + 1
            local zone = self.headers[zoneIndex]
            if not zone then
                zone = Label(self.content, 12, GOLD[1], GOLD[2], GOLD[3])
                self.headers[zoneIndex] = zone
            end
            zone:ClearAllPoints()
            zone:SetPoint("TOPLEFT", 18, -item.y - 6)
            zone:SetWidth(math.max(1, self.content:GetWidth() - 26))
            zone:SetText(item.name)
            if item.kind == "zone" then zone:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
            else zone:SetTextColor(0.6, 0.6, 0.6) end
            zone:Show()
        else
            rowIndex = rowIndex + 1
            local row = self:GetRow(rowIndex)
            local track = item.track
            row.trackKey = track.key
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 12, -item.y)
            row:SetSize(math.max(1, self.content:GetWidth() - 12), 30)
            row.title:SetText(track.title)
            row.playing:SetText("Playing")
            row.playing:SetShown(ns.State.playing and ns.State.activeTrack == track.key)
            self:PaintTrackRow(row)
            row:Show()
        end
    end
end

function UI:GetExpansionHeader(index)
    if self.expansionHeaders[index] then return self.expansionHeaders[index] end
    local header = CreateFrame("Button", nil, self.content, "BackdropTemplate")
    Backdrop(header, 0.035, 0.035, 0.04, 0.18)
    header.toggle = Label(header, 15, GOLD[1], GOLD[2], GOLD[3])
    header.toggle:SetPoint("LEFT", 8, 0)
    header.toggle:SetWidth(14)
    header.title = Label(header, 12)
    header.title:SetPoint("LEFT", 28, 0)
    header.title:SetPoint("RIGHT", -54, 0)
    header.count = Label(header, 10, 0.65, 0.65, 0.65)
    header.count:SetPoint("RIGHT", -8, 0)
    header.title:SetWordWrap(false)
    header:SetScript("OnClick", function(self)
        if self.isFavorites then
            if self.searching then
                UI.searchFavoritesCollapsed = not UI.searchFavoritesCollapsed
                UI:RenderLibrary()
            else
                ns.ToggleFavoritesCategory()
            end
        elseif self.searching then
            -- Search temporarily reveals matches without changing saved groups.
            UI.searchCollapsed[self.expansion] = not UI.searchCollapsed[self.expansion] or nil
            UI:RenderLibrary()
        else
            ns.ToggleExpansion(self.expansion)
        end
    end)
    header:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.6) end)
    header:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.18, 0.18, 0.18, 1) end)
    self.expansionHeaders[index] = header
    return header
end

-- The active-track summary and selected-track star intentionally have separate targets.
function UI:RefreshPlayback()
    local playing = ns.State.playing
    local track = playing and ns.GetActiveTrack() or ns.GetSelectedTrack()
    self.nowLabel:SetText(playing and "NOW PLAYING" or "SELECTED TRACK")
    if playing then self.nowLabel:SetTextColor(MONK.r, MONK.g, MONK.b)
    else self.nowLabel:SetTextColor(0.65, 0.65, 0.65) end
    self.nowTitle:SetText(track and track.title or "Select a track")
    self.location:SetText(track and (track.zone .. "  |  " .. track.expansion) or "")
    self.stop:SetEnabled(playing)
    self.play:SetEnabled(ns.GetSelectedTrack() ~= nil)
    self:RefreshFavorite()
end

function UI:RefreshFavorite()
    local track = ns.GetSelectedTrack()
    self.favorite:SetEnabled(track ~= nil)
    self.favorite.icon:SetAtlas(track and ns.IsFavorite(track.key) and "auctionhouse-icon-favorite" or "auctionhouse-icon-favorite-off")
    self.favorite.icon:SetAlpha(track and 1 or 0.35)
end

function UI:Refresh()
    self:RenderLibrary()
    self:RefreshPlayback()
end

-- Cursor tracking runs only during a minimap drag, never during music playback.
function UI:BuildMinimap()
    local button = CreateFrame("Button", "MusicSCANMinimapButton", Minimap)
    self.minimap = button
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(24, 24)
    background:SetPoint("TOPLEFT", 2, -2)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ns.ICON)
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(self)
        if not self.dragEndedAt or GetTime() - self.dragEndedAt > 0.2 then ns.ToggleWindow() end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("MusicSCAN", 1, 1, 1)
        GameTooltip:AddLine("Version " .. ns.VERSION, GOLD[1], GOLD[2], GOLD[3])
        GameTooltip:AddLine("Author: " .. ns.AUTHOR, 0.8, 0.8, 0.8)
        GameTooltip:AddLine(ns.WEBSITE, 0.7, 0.7, 0.7)
        local track = ns.GetActiveTrack()
        if ns.State.playing and track then GameTooltip:AddLine("Playing: " .. track.title, GOLD[1], GOLD[2], GOLD[3], true) end
        GameTooltip:AddLine("Click: open or close player", 1, 1, 1)
        GameTooltip:AddLine("Drag: move around minimap", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            if not centerX or not centerY then return end
            local scale = Minimap:GetEffectiveScale()
            local dx, dy = x / scale - centerX, y / scale - centerY
            ns.SetMinimapAngle(math.deg(math.atan2(dy, dx)))
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self.dragEndedAt = GetTime()
    end)
    Minimap:HookScript("OnSizeChanged", function() UI:UpdateMinimapPosition() end)
    self:UpdateMinimapPosition()
end

-- Native frames only; no external libraries or addon dependencies are required.
function ns.BuildUI()
    ns.UI = UI
    UI.rows, UI.headers, UI.expansionHeaders, UI.searchCollapsed = {}, {}, {}, {}
    UI.libraryItems, UI.rendering = {}, false
    UI.searchFavoritesCollapsed = false
    local frame = CreateFrame("Frame", "MusicSCANPlayer", UIParent, "BackdropTemplate")
    UI.frame = frame
    frame:Hide()
    frame:SetResizable(true)
    frame:SetResizeBounds(ns.GetWindowBounds())
    frame:SetSize(ns.DB.window.width, ns.DB.window.height)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    Backdrop(frame, 0.10, 0.10, 0.11, 0.36)
    UI:RestoreWindowPosition()
    UISpecialFrames[#UISpecialFrames + 1] = "MusicSCANPlayer"

    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(35)
    Backdrop(titleBar, 0, 0, 0, 0)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        ns.SaveWindowPosition(frame)
    end)
    local about = CreateFrame("Button", "MusicSCANAboutButton", titleBar)
    UI.about = about
    about:SetSize(24, 24)
    about:SetPoint("LEFT", 8, 0)
    about:RegisterForClicks("LeftButtonUp")
    about:SetScript("OnEnter", AboutTooltip)
    about:SetScript("OnClick", AboutTooltip)
    about:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local icon = about:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(ns.ICON)
    local title = Label(titleBar, 16)
    title:SetPoint("LEFT", about, "RIGHT", 8, 0)
    title:SetText("MusicSCAN")
    local close = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    close:SetSize(28, 28)
    close:SetPoint("TOPRIGHT", 0, -2)
    close:SetScript("OnClick", function() frame:Hide() end)
    Divider(frame, "TOPLEFT", 1, -36)

    local search = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    UI.search = search
    search:SetHeight(26)
    search:SetPoint("TOPLEFT", 16, -53)
    search:SetPoint("TOPRIGHT", -16, -53)
    Backdrop(search, 0.045, 0.045, 0.05)
    search:SetFont(STANDARD_TEXT_FONT, 12, "")
    search:SetTextColor(1, 1, 1)
    search:SetTextInsets(8, 8, 0, 0)
    search:SetAutoFocus(false)
    search:SetMaxLetters(100)
    local hint = Label(search, 12, 0.55, 0.55, 0.55)
    hint:SetPoint("LEFT", 8, 0)
    hint:SetText("Search zones or tracks...")
    search:SetScript("OnTextChanged", function(self)
        UI.searchCollapsed = {}
        UI.searchFavoritesCollapsed = false
        hint:SetShown(self:GetText() == "")
        UI.scroll:SetVerticalScroll(0)
        UI:RenderLibrary()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local list = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    list:SetPoint("TOPLEFT", 16, -94)
    list:SetPoint("BOTTOMRIGHT", -16, 136)
    Backdrop(list, 0.065, 0.065, 0.07, 0.18)
    local scroll = CreateFrame("ScrollFrame", "MusicSCANLibraryScroll", list, "UIPanelScrollFrameTemplate")
    UI.scroll = scroll
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -28, 6)
    local content = CreateFrame("Frame", nil, scroll)
    UI.content = content
    content:SetSize(math.max(1, scroll:GetWidth()), 1)
    scroll:SetScrollChild(content)
    UI.empty = Label(content, 12, 0.65, 0.65, 0.65)
    UI.empty:SetPoint("TOPLEFT", 8, -12)
    UI.empty:SetText("No matching music.")
    UI.empty:Hide()

    Divider(frame, "BOTTOMLEFT", 16, 124, true)
    UI.nowLabel = Label(frame, 10, 0.65, 0.65, 0.65)
    UI.nowLabel:SetPoint("BOTTOMLEFT", 16, 107)
    UI.nowTitle = Label(frame, 15)
    UI.nowTitle:SetPoint("BOTTOMLEFT", 16, 86)
    UI.nowTitle:SetPoint("BOTTOMRIGHT", -16, 86)
    UI.nowTitle:SetWordWrap(false)
    UI.location = Label(frame, 10, GOLD[1], GOLD[2], GOLD[3])
    UI.location:SetPoint("BOTTOMLEFT", 16, 70)
    UI.location:SetPoint("BOTTOMRIGHT", -16, 70)
    UI.location:SetWordWrap(false)

    UI.play = Button(frame, "Play", ns.Play)
    UI.play:SetPoint("BOTTOMLEFT", 16, 27)
    UI.stop = Button(frame, "Stop", ns.Stop)
    UI.stop:SetPoint("LEFT", UI.play, "RIGHT", 8, 0)
    local favorite = CreateFrame("Button", "MusicSCANFavoriteButton", frame)
    UI.favorite = favorite
    favorite:SetSize(30, 30)
    favorite:SetPoint("BOTTOMRIGHT", -16, 27)
    favorite:RegisterForClicks("LeftButtonUp")
    favorite.icon = favorite:CreateTexture(nil, "ARTWORK")
    favorite.icon:SetSize(22, 20)
    favorite.icon:SetPoint("CENTER")
    favorite.icon:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
    favorite:SetScript("OnClick", function(self)
        local track = ns.GetSelectedTrack()
        if track then ns.ToggleFavorite(track.key); FavoriteTooltip(self) end
    end)
    favorite:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(1, 1, 1)
        FavoriteTooltip(self)
    end)
    favorite:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
        GameTooltip:Hide()
    end)
    local tagline = Label(frame, 10, 0.52, 0.52, 0.52)
    UI.tagline = tagline
    tagline:SetPoint("BOTTOM", 0, 9)
    tagline:SetText("Listen your way with MusicSCAN v" .. ns.VERSION)

    local resize = CreateFrame("Button", "MusicSCANResizeGrip", frame)
    UI.resize = resize
    resize:SetSize(18, 18)
    resize:SetPoint("BOTTOMRIGHT", -2, 2)
    resize:SetFrameLevel(frame:GetFrameLevel() + 10)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            GameTooltip:Hide()
            ns.BeginWindowResize(frame)
        end
    end)
    resize:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then ns.EndWindowResize(frame) end
    end)
    resize:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Resize MusicSCAN", GOLD[1], GOLD[2], GOLD[3])
        GameTooltip:AddLine("Drag this corner to change the window size.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    resize:SetScript("OnLeave", function() GameTooltip:Hide() end)

    scroll:HookScript("OnVerticalScroll", function() UI:RenderVisibleLibrary() end)
    scroll:HookScript("OnSizeChanged", function() UI:LayoutLibrary() end)
    UI:LayoutLibrary()

    frame:SetScript("OnShow", function()
        ns.DB.window.visible = true
        UI:Refresh()
    end)
    frame:SetScript("OnHide", function()
        frame:StopMovingOrSizing()
        ns.SaveWindowPosition(frame)
        ns.DB.window.visible = false
        search:ClearFocus()
        GameTooltip:Hide()
    end)
    UI:BuildMinimap()
    UI:Refresh()
    if ns.DB.window.visible then frame:Show() end
end
