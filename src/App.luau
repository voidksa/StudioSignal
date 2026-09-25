local Config = require(script.Parent.Config)
local Api = require(script.Parent.Api)
local Activity = require(script.Parent.Activity)
local Controller = require(script.Parent.Controller)
local UI = require(script.Parent.UI)
local Modes = require(script.Parent.Modes)
local Session = require(script.Parent.Session)
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
    }
    local projectKey = game.PlaceId > 0 and ("StudioSignal.project." .. game.PlaceId) or nil
    local function read(key)
        if options.preview then
            return nil
        end
        local ok, v = pcall(function()
            return pluginObject:GetSetting(key)
        end)
        return ok and v or nil
    end
    local function write(key, value)
        if options.preview then
            return
        end
        pcall(function()
            pluginObject:SetSetting(key, value)
        end)
    end
    local saved = projectKey and read(projectKey)
    if type(saved) == "table" then
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
    local toolbar = pluginObject:CreateToolbar("StudioSignal")
    local toggle = toolbar:CreateButton(
        "StudioSignal.Open",
        "Discord Presence",
        "rbxassetid://126794649591682",
        "StudioSignal"
    )
    toggle.ClickableWhenViewportHidden = true
    local widget = pluginObject:CreateDockWidgetPluginGuiAsync(
        "StudioSignal.Presence.v01" .. (options.preview and ".Dev" or ""),
        DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 420, 720, 340, 420)
    )
    widget.Title = "StudioSignal | Discord Presence"
    widget.Name = "StudioSignalWidget"
    widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local started = options.startedAt or os.time()
    local session = Session.new(started)
    local selectionMode, selectionUntil = nil, 0
    local focused = true
    local stopped = false
    local links = {}
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
    local callbacks = {
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
    ui = UI.new(widget, settings, callbacks)
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
        toggle:Destroy()
        toolbar:Destroy()
        -- Best effort only during application exit; normal Pause gets a confirmed removal.
    end
    table.insert(links, pluginObject.Unloading:Connect(cleanup))
    render()
    toggle:SetActive(widget.Enabled)
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
        version = Config.Version,
    }
end

return App
