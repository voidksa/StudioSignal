local Config = require(script.Parent.Config)
local Api = require(script.Parent.Api)
local Activity = require(script.Parent.Activity)
local Controller = require(script.Parent.Controller)
local UI = require(script.Parent.UI)
local Modes = require(script.Parent.Modes)
local Session = require(script.Parent.Session)
local Panel = require(script.Parent.Panel)
local Profiles = require(script.Parent.Profiles)
local Diagnostics = require(script.Parent.Diagnostics)
local App = {}

function App.start(pluginObject, options)
    options = options or {}
    local http = game:GetService("HttpService")
    local studio = game:GetService("StudioService")
    local run = game:GetService("RunService")
    local input = game:GetService("UserInputService")
    local selection = game:GetService("Selection")
    local configId = Config.ApplicationId
    local settings = {
        private = true,
        showTimer = true,
        showLink = false,
        pauseBackground = true,
        mode = "Auto",
        projectAlias = "",
        smartSelection = true,
        idleMinutes = 5,
        idleBehavior = "Pause",
        detailsText = "",
        stateText = "",
        iconMode = "Auto",
        gameUrl = "",
    }
    local projectKey = game.PlaceId > 0 and ("StudioSignal.project." .. game.PlaceId) or nil
    local previewStore = {}
    local function read(key)
        if options.preview then
            return previewStore[key]
        end
        local ok, v = pcall(function()
            return pluginObject:GetSetting(key)
        end)
        if ok then
            return v
        end
        return nil
    end
    local function write(key, value)
        if options.preview then
            previewStore[key] = value
            return true
        end
        return pcall(function()
            pluginObject:SetSetting(key, value)
        end)
    end
    local saved = projectKey and read(projectKey)
    if type(saved) == "table" then
        local appearance = Profiles.clean(saved)
        if appearance then
            Profiles.apply(settings, appearance)
        end
        for _, k in ipairs({
            "private",
            "showTimer",
            "showLink",
            "pauseBackground",
            "smartSelection",
        }) do
            if type(saved[k]) == "boolean" then
                settings[k] = saved[k]
            end
        end
        if type(saved.projectAlias) == "string" then
            settings.projectAlias = Activity.text(saved.projectAlias, 90)
        end
        if Modes[saved.mode] then
            settings.mode = saved.mode
        end
        if table.find({ 0, 5, 10, 15 }, saved.idleMinutes) then
            settings.idleMinutes = saved.idleMinutes
        end
        if saved.idleBehavior == "Away" then
            settings.idleBehavior = "Away"
        end
    end
    local profiles = Profiles.new(read, write, function()
        return http:GenerateGUID(false)
    end)
    local pinned = profiles:pinned(game.PlaceId)
    if pinned then
        Profiles.apply(settings, pinned)
        settings.activeProfileId = pinned.id
    end
    local savedId = read("StudioSignal.applicationId")
    if configId == "" and type(savedId) == "string" and savedId:match("^%d+$") then
        configId = savedId
    end
    local function configured()
        return #configId >= 17 and #configId <= 20 and configId:match("^%d+$") ~= nil
    end
    local controller = Controller.new(Api.new(http, configId), os.time, function(t)
        return http:JSONEncode(t)
    end)
    local toolbar, toggle
    local displayName = Config.Name .. " " .. Config.Version
    -- Development previews open their own widget without registering ribbon items.
    if not options.preview then
        toolbar = pluginObject:CreateToolbar("StudioSignal")
        toggle = toolbar:CreateButton(
            "StudioSignal.Open",
            displayName .. " | Discord Presence",
            "rbxassetid://126794649591682",
            displayName
        )
        toggle.ClickableWhenViewportHidden = true
    end
    local widget, panelConnection =
        Panel.create(pluginObject, options.preview == true, run:IsRunning())
    widget.Title = displayName .. " | Discord Presence"
    widget.Name = "StudioSignalWidget"
    widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local started = options.startedAt or os.time()
    local session = Session.new(started)
    local selectionMode, selectionUntil = nil, 0
    local focused = true
    local stopped = false
    local links = { panelConnection }
    local ui
    local function context()
        local active, scriptKind = false, nil
        pcall(function()
            local s = studio.ActiveScript
            active = s ~= nil
            if s then
                scriptKind = s.ClassName == "Script" and "ServerScript" or s.ClassName
                if s:IsA("Script") and s.RunContext == Enum.RunContext.Client then
                    scriptKind = "LocalScript"
                end
            end
        end)
        local now = os.time()
        return {
            projectName = game.Name:gsub("%.rbxlx?$", ""),
            placeId = game.PlaceId,
            scripting = active,
            scriptKind = scriptKind,
            testing = run:IsRunning(),
            startedAt = started,
            now = now,
            selectionMode = now < selectionUntil and selectionMode or nil,
            idle = session:isIdle(settings.idleMinutes, now),
            focusStarted = session.focusStarted,
            focusEnds = session.focusEnds,
        }
    end
    local function build()
        return Activity.build(settings, context(), configId)
    end
    local function render()
        if ui and widget.Parent then
            ui:render(
                controller:snapshot(),
                settings,
                build(),
                os.time() - started,
                configured(),
                session,
                Activity.resolve(settings, context())
            )
        end
    end
    local function save()
        if projectKey then
            write(projectKey, settings)
        end
        controller:invalidate()
        render()
    end
    local function applyProfile(raw, id)
        local profile, err = Profiles.clean(raw)
        if not profile then
            return false, err
        end
        controller:hidePreviousActivity()
        Profiles.apply(settings, profile)
        settings.activeProfileId = id
        save()
        return true, "Applied. If sharing is paused, choose Start sharing when ready."
    end
    local callbacks = {
        profiles = function()
            profiles:refresh()
            local currentPin = profiles:pinned(game.PlaceId)
            return profiles.items,
                currentPin and currentPin.id,
                Profiles.pinKey(game.PlaceId) ~= nil
        end,
        profileDraft = function()
            local draft = Profiles.clean(settings)
            draft.name = ""
            return draft
        end,
        previewProfile = function(raw)
            local draft, err = Profiles.clean(raw)
            if not draft then
                return nil, err
            end
            local candidate = table.clone(settings)
            Profiles.apply(candidate, draft)
            return Activity.build(candidate, context(), configId),
                Activity.iconMode(candidate, context())
        end,
        saveProfile = function(id, raw)
            return profiles:save(id, raw)
        end,
        applyProfile = applyProfile,
        pinProfile = function(id, raw)
            if not Profiles.pinKey(game.PlaceId) then
                return false, "Publish this place to Roblox before pinning."
            end
            local profile, err = profiles:save(id, raw)
            if not profile then
                return false, err
            end
            local ok, pinError = profiles:pin(game.PlaceId, profile.id)
            if not ok then
                return false, pinError
            end
            applyProfile(profile, profile.id)
            return true, "Saved, applied and pinned. It will load when this place opens.", profile
        end,
        unpinProfile = function()
            local ok, err = profiles:pin(game.PlaceId, nil)
            return ok, err or "Unpinned. Your current appearance stays in place."
        end,
        deleteProfile = function(id)
            local currentPin = profiles:pinned(game.PlaceId)
            if currentPin and currentPin.id == id then
                local ok = profiles:pin(game.PlaceId, nil)
                if not ok then
                    return false, "Could not remove the project pin. Try again."
                end
            end
            if not profiles:delete(id) then
                return false, "Studio could not remove this profile."
            end
            return true, "Profile deleted. Your current activity is unchanged."
        end,
        supportReport = function()
            return Diagnostics.report(controller:snapshot(), os.time(), run:IsRunning())
        end,
        connect = function()
            if not configured() then
                ui:selectTab("Settings")
                return
            end
            controller:connect()
        end,
        disconnect = function()
            controller:disconnect()
        end,
        toggleSharing = function()
            controller:setEnabled(not controller.enabled)
        end,
        togglePrivate = function()
            settings.private = not settings.private
            if settings.private then
                controller:hidePreviousActivity()
            end
            save()
        end,
        toggleTimer = function()
            settings.showTimer = not settings.showTimer
            save()
        end,
        toggleLink = function()
            settings.showLink = not settings.showLink
            if not settings.showLink then
                controller:hidePreviousActivity()
            end
            save()
        end,
        toggleBackground = function()
            settings.pauseBackground = not settings.pauseBackground
            save()
        end,
        toggleSmartSelection = function()
            settings.smartSelection = not settings.smartSelection
            save()
        end,
        cycleIdle = function()
            local values = { 0, 5, 10, 15 }
            local i = table.find(values, settings.idleMinutes) or 1
            settings.idleMinutes = values[i % #values + 1]
            session:touch(os.time())
            save()
        end,
        toggleIdleBehavior = function()
            settings.idleBehavior = settings.idleBehavior == "Pause" and "Away" or "Pause"
            save()
        end,
        selectMode = function(mode)
            if not Modes[mode] then
                return
            end
            session:stopFocus()
            session:touch(os.time())
            settings.mode = mode
            save()
        end,
        focus = function(minutes)
            session:startFocus(minutes, os.time())
            controller:invalidate()
            render()
        end,
        stopFocus = function()
            session:stopFocus()
            controller:invalidate()
            render()
        end,
        alias = function(value)
            settings.projectAlias = Activity.text(value, 90)
            save()
        end,
        cycleMode = function()
            local modes = Modes.Order
            local index = table.find(modes, settings.mode) or 1
            settings.mode = modes[index % #modes + 1]
            save()
        end,
        appId = function(value)
            if
                controller.accessToken
                or controller.phase == "requesting"
                or controller.deviceCode
            then
                controller.detail = "Disconnect before changing the application."
                render()
                return
            end
            value = tostring(value):match("^%s*(.-)%s*$") or ""
            if not value:match("^%d+$") or #value < 17 or #value > 20 then
                controller:notify(
                    "error",
                    "Enter the public numeric Application ID from Discord Developer Portal."
                )
                return
            end
            configId = value
            controller.api = Api.new(http, configId)
            write("StudioSignal.applicationId", value)
            controller:notify(
                "disconnected",
                "Application configured. Connect Discord to continue."
            )
            ui:selectTab("Presence")
        end,
    }
    local uiOk, createdUI = pcall(UI.new, widget, settings, callbacks)
    if not uiOk then
        panelConnection:Disconnect()
        widget:Destroy()
        if toggle then
            toggle:Destroy()
        end
        if toolbar then
            toolbar:Destroy()
        end
        error(createdUI, 0)
    end
    ui = createdUI
    ui.appId.Text = configId
    controller.changed = render
    local function touch()
        session:touch(os.time())
    end
    table.insert(links, input.InputBegan:Connect(touch))
    table.insert(links, input.InputChanged:Connect(touch))
    table.insert(
        links,
        selection.SelectionChanged:Connect(function()
            touch()
            selectionMode = nil
            local selected = selection:Get()
            local item = selected[1]
            if item then
                if
                    item:IsA("GuiObject")
                    or item:IsA("LayerCollector")
                    or item:IsA("UIComponent")
                then
                    selectionMode = "UI"
                elseif item:IsA("Terrain") then
                    selectionMode = "Terrain"
                elseif
                    item:IsA("Light")
                    or item:IsA("PostEffect")
                    or item:IsA("Atmosphere")
                    or item:IsA("Sky")
                    or item:IsA("Lighting")
                then
                    selectionMode = "Lighting"
                elseif item:IsA("Sound") or item:IsA("SoundGroup") or item:IsA("SoundEffect") then
                    selectionMode = "Audio"
                elseif
                    item:IsA("Animation")
                    or item:IsA("KeyframeSequence")
                    or item:IsA("Keyframe")
                then
                    selectionMode = "Animation"
                elseif item:IsA("MeshPart") or item:IsA("SpecialMesh") then
                    selectionMode = "Modeling"
                end
            end
            selectionUntil = os.time() + 45
            controller:invalidate()
            render()
        end)
    )
    if toggle then
        table.insert(
            links,
            toggle.Click:Connect(function()
                widget.Enabled = not widget.Enabled
            end)
        )
        table.insert(
            links,
            widget:GetPropertyChangedSignal("Enabled"):Connect(function()
                toggle:SetActive(widget.Enabled)
            end)
        )
    end
    table.insert(
        links,
        input.WindowFocused:Connect(function()
            focused = true
            touch()
            controller:invalidate()
        end)
    )
    table.insert(
        links,
        input.WindowFocusReleased:Connect(function()
            focused = false
            if settings.pauseBackground then
                controller:hidePreviousActivity()
            else
                controller:invalidate()
            end
        end)
    )
    table.insert(links, studio:GetPropertyChangedSignal("ActiveScript"):Connect(render))
    table.insert(links, game:GetPropertyChangedSignal("Name"):Connect(render))
    table.insert(
        links,
        game:GetPropertyChangedSignal("PlaceId"):Connect(function()
            projectKey = game.PlaceId > 0 and ("StudioSignal.project." .. game.PlaceId) or nil
            profiles:refresh()
            local profile = profiles:pinned(game.PlaceId)
            if profile then
                applyProfile(profile, profile.id)
            end
            ui:refreshProfiles()
        end)
    )
    local function cleanup()
        if stopped then
            return
        end
        stopped = true
        controller:disconnect()
        for _, connection in ipairs(links) do
            connection:Disconnect()
        end
        widget:Destroy()
        if toggle then
            toggle:Destroy()
        end
        if toolbar then
            toolbar:Destroy()
        end
        -- Best effort only during application exit; normal Pause gets a confirmed removal.
    end
    table.insert(links, pluginObject.Unloading:Connect(cleanup))
    render()
    if toggle then
        toggle:SetActive(widget.Enabled)
    end
    task.spawn(function()
        local shutdownTicks = 0
        while not stopped or (controller.disconnecting and shutdownTicks < 5) do
            if stopped then
                shutdownTicks += 1
            end
            local c = context()
            local idlePause = c.idle and settings.idleBehavior == "Pause"
            local pauseReason = (settings.pauseBackground and not focused) or (idlePause and "idle")
            session:tick(os.time(), Activity.resolve(settings, c), focused and not c.idle)
            local ok = pcall(function()
                controller:step(build(), pauseReason)
            end)
            if not ok then
                controller:notify(
                    "error",
                    "An internal error stopped this update. Pause and reconnect."
                )
            end
            if not stopped then
                render()
            end
            task.wait(1)
        end
    end)
    return {
        cleanup = cleanup,
        widget = widget,
        controller = controller,
        ui = ui,
        settings = settings,
        callbacks = callbacks,
        toolbar = toolbar,
        button = toggle,
        preview = build,
        render = render,
        session = session,
        context = context,
        profiles = profiles,
        version = Config.Version,
    }
end

return App
