-- StudioSignal v1.0. Generated from src/.
local factories,cache={},{}
local function requireModule(name)
 if cache[name]==nil then cache[name]=factories[name]() end
 return cache[name]
end
factories["Config"]=function()
return {
    Name = "StudioSignal",
    Version = "v1.0",
    Copyright = "© 2026 VOIDKSA",
    ApplicationId = "1553014903428620388",
    Scope = "sdk.social_layer_presence",
    ApiBase = "https://discord.com/api/v10",
    ContourUrl = "https://create.roblox.com/store/asset/94088881259293",
    SupportUrl = "https://discord.gg/sWszV6FQbW",
    DeveloperUrl = "https://discord.com/developers/applications",
    MinUpdateSeconds = 15,
    HeartbeatSeconds = 120,
}

end
factories["Modes"]=function()
local Modes = {}
local assetIds = {
    animation = "1553054056849874965",
    audio = "1553054057130631332",
    brand = "1553054262035091556",
    building = "1553053132781789194",
    client = "1553053132806815845",
    debugging = "1553054261800214658",
    focus = "1553054262093680681",
    idle = "1553054261796012134",
    lighting = "1553054057508380733",
    modeling = "1553054057151729664",
    module = "1553053515478474834",
    scripting = "1553053132718608446",
    server = "1553053132735516732",
    terrain = "1553053516249960469",
    testing = "1553053515965005864",
    ui = "1553053515901968496",
}
Modes.Atlas = "rbxassetid://134867454938451"
Modes.Order = {
    "Auto",
    "Building",
    "Scripting",
    "ServerScript",
    "LocalScript",
    "ModuleScript",
    "Testing",
    "Terrain",
    "UI",
    "Animation",
    "Lighting",
    "Audio",
    "Modeling",
    "Debugging",
    "Focus",
    "Idle",
}
local rows = {
    { "Building", "Building", "Building in Roblox Studio", "building", 0 },
    { "Scripting", "Luau", "Writing Luau", "scripting", 1 },
    { "ServerScript", "Server script", "Writing server code", "server", 2 },
    { "LocalScript", "Local script", "Writing client code", "client", 3 },
    { "ModuleScript", "Module script", "Writing a Luau module", "module", 4 },
    { "Testing", "Playtesting", "Playtesting in Roblox Studio", "testing", 5 },
    { "Terrain", "Terrain", "Creating terrain", "terrain", 6 },
    { "UI", "Interface", "Designing interfaces", "ui", 7 },
    { "Animation", "Animation", "Working on animation", "animation", 8 },
    { "Lighting", "Lighting", "Setting the lighting", "lighting", 9 },
    { "Audio", "Audio", "Working on audio", "audio", 10 },
    { "Modeling", "Modeling", "Modeling in Roblox Studio", "modeling", 11 },
    { "Debugging", "Debugging", "Debugging Luau", "debugging", 12 },
    { "Focus", "Focus", "Focused work in Roblox Studio", "focus", 13 },
    { "Idle", "Away", "Taking a break", "idle", 14 },
}
for _, r in ipairs(rows) do
    Modes[r[1]] = { label = r[2], state = r[3], asset = assetIds[r[4]], index = r[5] }
end
Modes.Auto = { label = "Automatic", index = 15, asset = assetIds.brand }
Modes.BrandAsset = assetIds.brand
return Modes

end
factories["Session"]=function()
local Session = {}
Session.__index = Session
function Session.new(now)
    return setmetatable(
        { startedAt = now, lastInput = now, lastTick = now, activeSeconds = 0, totals = {} },
        Session
    )
end
function Session:touch(now)
    self.lastInput = now
end
function Session:startFocus(minutes, now)
    if minutes ~= 25 and minutes ~= 50 then
        return
    end
    self.focusStarted = now
    self.focusEnds = now + minutes * 60
    self.focusComplete = false
    self:touch(now)
end
function Session:stopFocus()
    self.focusStarted = nil
    self.focusEnds = nil
end
function Session:isIdle(minutes, now)
    return (minutes or 0) > 0
        and now - self.lastInput >= minutes * 60
        and not (self.focusEnds and now < self.focusEnds)
end
function Session:tick(now, mode, active)
    local dt = math.clamp(now - self.lastTick, 0, 5)
    self.lastTick = now
    if active then
        self.activeSeconds += dt
        self.totals[mode] = (self.totals[mode] or 0) + dt
    end
    if self.focusEnds and now >= self.focusEnds then
        self:stopFocus()
        self.focusComplete = true
        self:touch(now)
    end
end
return Session

end
factories["Activity"]=function()
-- Public activity is constructed here. Never pass source, paths or selection data.
local Activity = {}
local Modes = requireModule("Modes")
function Activity.resolve(settings, context)
    if context.focusEnds and context.now and context.now < context.focusEnds then
        return "Focus"
    end
    if context.idle then
        return "Idle"
    end
    if settings.mode ~= "Auto" then
        return Modes[settings.mode] and settings.mode or "Building"
    end
    if context.testing then
        return "Testing"
    end
    if context.scripting then
        return Modes[context.scriptKind] and context.scriptKind or "Scripting"
    end
    if settings.smartSelection and Modes[context.selectionMode] then
        return context.selectionMode
    end
    return "Building"
end

function Activity.text(value, limit)
    local clean = tostring(value or ""):gsub("[%c]", " "):gsub("%s+", " ")
    clean = clean:match("^%s*(.-)%s*$") or ""
    local ok, cut = pcall(utf8.offset, clean, limit + 1)
    if not ok then
        return ""
    end
    return cut and clean:sub(1, cut - 1) or clean
end

function Activity.build(settings, context, appId)
    local mode = Activity.resolve(settings, context)
    local project = Activity.text(settings.projectAlias, 90)
    if project == "" then
        project = Activity.text(context.projectName, 90)
    end
    if project == "" then
        project = "Untitled project"
    end
    local activity = {
        type = 0,
        name = "StudioSignal",
        application_id = appId,
        platform = "desktop",
        details = settings.private and "Working on a private project" or ("Working on " .. project),
        state = Modes[mode].state,
        assets = {
            large_image = Modes[mode].asset,
            large_text = Modes[mode].label,
            small_image = Modes.BrandAsset,
            small_text = "StudioSignal | Discord Presence",
        },
    }
    if settings.showTimer then
        activity.timestamps = { start = context.startedAt * 1000 }
    end
    if settings.showTimer and mode == "Focus" and context.focusEnds then
        activity.timestamps =
            { start = context.focusStarted * 1000, ["end"] = context.focusEnds * 1000 }
    end
    if mode == "Idle" then
        activity.timestamps = nil
    end
    -- A private project never exposes its id, title or a place link in the payload.
    if not settings.private and settings.showLink and context.placeId > 0 then
        activity.details_url = "https://www.roblox.com/games/" .. tostring(context.placeId)
    end
    return activity
end

function Activity.retryDelay(failures, serverDelay)
    return math.max(tonumber(serverDelay) or 0, math.min(120, 2 ^ math.min(failures, 7)))
end

return Activity

end
factories["Api"]=function()
-- Discord Headless Sessions is experimental and may change.
local Config = requireModule("Config")
local Api = {}
Api.__index = Api

function Api.new(http, clientId)
    return setmetatable({ http = http, clientId = clientId }, Api)
end

function Api:request(path, body, bearer, form)
    local headers =
        { ["Content-Type"] = form and "application/x-www-form-urlencoded" or "application/json" }
    if bearer then
        headers.Authorization = "Bearer " .. bearer
    end
    local encoded
    if form then
        local fields = {}
        for key, value in pairs(body) do
            table.insert(
                fields,
                self.http:UrlEncode(key) .. "=" .. self.http:UrlEncode(tostring(value))
            )
        end
        encoded = table.concat(fields, "&")
    else
        encoded = self.http:JSONEncode(body)
    end
    local ok, response = pcall(function()
        return self.http:RequestAsync({
            Url = Config.ApiBase .. path,
            Method = "POST",
            Headers = headers,
            Body = encoded,
        })
    end)
    if not ok then
        return { ok = false, kind = "network" }
    end
    local data = {}
    if response.Body and #response.Body > 0 then
        local decoded, result = pcall(function()
            return self.http:JSONDecode(response.Body)
        end)
        if decoded and type(result) == "table" then
            data = result
        end
    end
    local status = response.StatusCode
    if status == 429 then
        return {
            ok = false,
            kind = "rate_limit",
            delay = tonumber(data.retry_after) or 30,
            status = status,
        }
    end
    if status == 202 then
        -- Use a conservative wait: do not guess undocumented units or hammer an app being registered.
        return {
            ok = false,
            kind = "app_pending",
            delay = math.max(30, tonumber(data.retry_after) or 30),
            status = status,
        }
    end
    if not response.Success then
        local kind = status == 401 and "unauthorized" or (status == 403 and "forbidden" or "http")
        local known = {
            authorization_pending = true,
            slow_down = true,
            expired_token = true,
            access_denied = true,
            invalid_grant = true,
            invalid_client = true,
            invalid_scope = true,
        }
        if known[data.error] then
            kind = data.error
        end
        return { ok = false, kind = kind, status = status }
    end
    return { ok = true, data = data, status = status }
end

function Api:beginLink()
    local r = self:request(
        "/oauth2/device/authorize",
        { client_id = self.clientId, scope = Config.Scope },
        nil,
        true
    )
    if r.ok then
        local d = r.data
        if
            type(d.device_code) ~= "string"
            or type(d.user_code) ~= "string"
            or type(d.verification_uri) ~= "string"
            or not tonumber(d.expires_in)
            or not tonumber(d.interval)
        then
            return { ok = false, kind = "invalid_response" }
        end
        -- Never display or navigate an arbitrary URL from a response.
        if not d.verification_uri:match("^https://discord%.com/") then
            return { ok = false, kind = "invalid_response" }
        end
    end
    return r
end

function Api:pollLink(code)
    return self:request("/oauth2/token", {
        client_id = self.clientId,
        grant_type = "urn:ietf:params:oauth:grant-type:device_code",
        device_code = code,
    }, nil, true)
end

function Api:refresh(token)
    return self:request(
        "/oauth2/token",
        { client_id = self.clientId, grant_type = "refresh_token", refresh_token = token },
        nil,
        true
    )
end

function Api:revoke(token)
    return self:request(
        "/oauth2/token/revoke",
        { client_id = self.clientId, token = token, token_type_hint = "access_token" },
        nil,
        true
    )
end

function Api:publish(accessToken, sessionToken, activity)
    local body = { activities = { activity } }
    if sessionToken then
        body.token = sessionToken
    end
    local r = self:request("/users/@me/headless-sessions", body, accessToken)
    if r.ok and (type(r.data.token) ~= "string" or #r.data.token == 0) then
        return { ok = false, kind = "invalid_response" }
    end
    return r
end

function Api:clear(accessToken, sessionToken)
    return self:request(
        "/users/@me/headless-sessions/delete",
        { token = sessionToken },
        accessToken
    )
end

return Api

end
factories["Controller"]=function()
local Config = requireModule("Config")
local Activity = requireModule("Activity")
local Controller = {}
Controller.__index = Controller

local messages = {
    network = "Cannot reach Discord. Check your connection and the plugin's HTTP permission.",
    invalid_client = "Discord application setup is incomplete. Check Social SDK and Public Client.",
    invalid_scope = "The Discord application has not enabled the required Social SDK permission.",
    forbidden = "Discord declined access. Check the application's Social SDK configuration.",
    unauthorized = "Discord authorization expired. Disconnect and link your account again.",
    invalid_grant = "Discord authorization was revoked or expired. Link your account again.",
    access_denied = "You declined the Discord request. Nothing is shared.",
    expired_token = "The sign-in code expired. Connect again to get a new code.",
    invalid_response = "Discord returned an unexpected response. This preview needs a compatibility check.",
    rate_limit = "Discord asked us to wait. Retrying automatically.",
    app_pending = "Discord is preparing the application. Retrying automatically.",
    http = "Discord rejected the request. Check the connection details below.",
}

function Controller.new(api, clock, encode)
    return setmetatable({
        api = api,
        clock = clock,
        encode = encode,
        phase = "disconnected",
        detail = "Connect to share your Studio activity.",
        enabled = false,
        focused = true,
        nextAt = 0,
        failures = 0,
        revision = 0,
        changed = function() end,
        stopped = false,
        disconnecting = false,
        pausedInBackground = false,
    }, Controller)
end

function Controller:notify(phase, message)
    self.phase = phase
    self.detail = message
    self.changed()
end

function Controller:snapshot()
    -- Deliberately omit all bearer, refresh, device and session credentials.
    return {
        phase = self.phase,
        detail = self.detail,
        enabled = self.enabled,
        linked = self.accessToken ~= nil,
        userCode = self.userCode,
        verificationUrl = self.verificationUrl,
        expiresAt = self.deviceExpires,
        lastSuccess = self.lastSuccess,
        retryAt = self.nextAt,
        httpStatus = self.httpStatus,
        disconnecting = self.disconnecting,
    }
end

function Controller:connect()
    if self.accessToken or self.phase == "requesting" or self.phase == "awaiting" then
        return
    end
    self.disconnecting = false
    self.stopped = false
    self.nextAt = 0
    self:notify("requesting", "Requesting a secure sign-in code from Discord...")
end

function Controller:setEnabled(value)
    if self.disconnecting then
        return
    end
    self.enabled = value and self.accessToken ~= nil
    self.revision += 1
    -- Respect an existing server backoff, including while clearing.
    if self.failures == 0 then
        self.nextAt = 0
    end
    self.changed()
end

function Controller:invalidate()
    self.revision += 1
end

function Controller:hidePreviousActivity()
    -- Privacy changes remove the previous public payload before publishing a new one.
    self.clearRequested = true
    self.revision += 1
    if self.failures == 0 then
        self.nextAt = 0
    end
end

function Controller:disconnect()
    self.enabled = false
    self.disconnecting = true
    self.revision += 1
    self.deviceCode, self.userCode, self.verificationUrl, self.deviceExpires = nil, nil, nil, nil
    if self.failures == 0 then
        self.nextAt = 0
    end
    self:notify("disconnecting", "Removing your activity and disconnecting...")
end

function Controller:failure(r)
    self.failures += 1
    self.httpStatus = r.status
    self.nextAt = self.clock() + Activity.retryDelay(self.failures, r.delay)
    self:notify("retrying", messages[r.kind] or messages.http)
end

function Controller:acceptToken(data)
    if
        type(data.access_token) ~= "string"
        or data.access_token == ""
        or not tonumber(data.expires_in)
    then
        return false
    end
    self.accessToken = data.access_token
    self.refreshToken = data.refresh_token or self.refreshToken
    self.tokenExpires = self.clock() + tonumber(data.expires_in)
    return true
end

function Controller:step(activity, backgroundPaused)
    local now = self.clock()
    if now < self.nextAt then
        return
    end
    if self.disconnecting then
        if self.sessionToken and self.accessToken then
            local r = self.api:clear(self.accessToken, self.sessionToken)
            if not r.ok and r.kind ~= "unauthorized" then
                self:failure(r)
                return
            end
            self.sessionToken = nil
        end
        if self.accessToken then
            local r = self.api:revoke(self.accessToken)
            if not r.ok and r.kind ~= "unauthorized" and r.kind ~= "invalid_grant" then
                self:failure(r)
                return
            end
        end
        self.accessToken, self.refreshToken, self.tokenExpires = nil, nil, nil
        self.deviceCode, self.userCode, self.verificationUrl = nil, nil, nil
        self.disconnecting, self.enabled = false, false
        self.failures, self.nextAt, self.httpStatus = 0, 0, nil
        self:notify("disconnected", "Disconnected. No new activity will be sent.")
        return
    end
    if self.phase == "requesting" then
        local r = self.api:beginLink()
        if self.disconnecting then
            return
        end
        if not r.ok then
            self:notify("error", messages[r.kind] or messages.http)
            self.httpStatus = r.status
            return
        end
        local d = r.data
        self.deviceCode, self.userCode, self.verificationUrl =
            d.device_code, d.user_code, d.verification_uri
        self.deviceExpires = now + tonumber(d.expires_in)
        self.pollSeconds = math.max(5, tonumber(d.interval))
        self.nextAt = self.clock() + self.pollSeconds
        self:notify(
            "awaiting",
            "Open Discord's sign-in page, enter this code, and review the permissions."
        )
        return
    end
    if self.deviceCode then
        if now >= self.deviceExpires then
            self.deviceCode, self.userCode, self.verificationUrl = nil, nil, nil
            self:notify("error", messages.expired_token)
            return
        end
        local r = self.api:pollLink(self.deviceCode)
        if self.disconnecting then
            -- A late successful response is still revoked by the disconnect path.
            if r.ok then
                self:acceptToken(r.data)
            end
            return
        end
        if not r.ok then
            if r.kind == "authorization_pending" or r.kind == "slow_down" then
                if r.kind == "slow_down" then
                    self.pollSeconds += 5
                end
                self.nextAt = self.clock() + self.pollSeconds
                return
            elseif r.kind == "network" or r.kind == "rate_limit" then
                self.nextAt = self.clock() + math.max(self.pollSeconds, r.delay or 15)
                return
            end
            self.deviceCode, self.userCode, self.verificationUrl = nil, nil, nil
            self:notify("error", messages[r.kind] or messages.http)
            return
        end
        self.deviceCode, self.userCode, self.verificationUrl = nil, nil, nil
        if not self:acceptToken(r.data) then
            self:notify("error", messages.invalid_response)
            return
        end
        self.enabled = false -- Linking is distinct from sharing: the user starts sharing explicitly.
        self.failures, self.nextAt = 0, 0
        self:notify("paused", "Account linked. Review the preview, then start sharing.")
        return
    end
    if not self.accessToken then
        return
    end
    if self.tokenExpires and now >= self.tokenExpires - 90 then
        if not self.refreshToken then
            self.enabled = false
            self:notify("error", messages.unauthorized)
            return
        end
        local r = self.api:refresh(self.refreshToken)
        if not r.ok then
            if r.kind == "invalid_grant" or r.kind == "unauthorized" then
                self.enabled = false
                self:notify("error", messages.invalid_grant)
                self.nextAt = self.clock() + 60
            else
                self:failure(r)
            end
            return
        end
        if not self:acceptToken(r.data) then
            self:failure({ kind = "invalid_response" })
            return
        end
        if self.disconnecting then
            return
        end
    end
    if not self.enabled or backgroundPaused or self.clearRequested then
        if self.sessionToken then
            local r = self.api:clear(self.accessToken, self.sessionToken)
            if not r.ok then
                self:failure(r)
                return
            end
            self.sessionToken, self.lastPayload = nil, nil
        end
        self.failures, self.httpStatus = 0, nil
        self.clearRequested = false
        self.nextAt = self.clock() + 1
        local reason = backgroundPaused == "idle"
                and "Sharing paused while you are away. It resumes when you return."
            or "Sharing pauses while this Studio window is in the background."
        self:notify(
            "paused",
            (backgroundPaused and self.enabled) and reason
                or "Sharing is paused. Your account stays linked for this session."
        )
        return
    end
    local payload = self.encode(activity)
    if
        payload == self.lastPayload
        and self.lastSuccess
        and now - self.lastSuccess < Config.HeartbeatSeconds
    then
        return
    end
    local revision = self.revision
    self:notify("sending", "Updating your Discord activity...")
    local r = self.api:publish(self.accessToken, self.sessionToken, activity)
    if not r.ok then
        if r.kind == "unauthorized" then
            self.tokenExpires = 0
        end
        self:failure(r)
        return
    end
    self.sessionToken = r.data.token
    self.lastPayload, self.lastSuccess = payload, self.clock()
    self.failures, self.httpStatus = 0, nil
    self.nextAt = self.clock() + Config.MinUpdateSeconds
    if self.disconnecting or not self.enabled or revision ~= self.revision then
        self.nextAt = self.clock()
        self:notify("updating", "Applying your latest sharing settings...")
    else
        self:notify(
            "sharing",
            "Discord accepted your activity. Visibility also follows your Discord privacy settings."
        )
    end
end

return Controller

end
factories["UI"]=function()
local Config = requireModule("Config")
local Modes = requireModule("Modes")
local UI = {}
UI.__index = UI
local C = {
    bg = Color3.fromRGB(24, 25, 23),
    panel = Color3.fromRGB(34, 35, 32),
    border = Color3.fromRGB(63, 64, 57),
    text = Color3.fromRGB(235, 230, 219),
    muted = Color3.fromRGB(171, 171, 157),
    accent = Color3.fromRGB(214, 166, 101),
    green = Color3.fromRGB(170, 193, 149),
    input = Color3.fromRGB(29, 30, 27),
}

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end
local function corner(obj, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, obj)
end
local function padding(obj, n)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, n),
        PaddingRight = UDim.new(0, n),
        PaddingTop = UDim.new(0, n),
        PaddingBottom = UDim.new(0, n),
    }, obj)
end
local function layout(obj, gap)
    make(
        "UIListLayout",
        { Padding = UDim.new(0, gap or 10), SortOrder = Enum.SortOrder.LayoutOrder },
        obj
    )
end
local function label(parent, name, text, size, color)
    return make("TextLabel", {
        Name = name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = text,
        TextSize = size or 14,
        Font = Enum.Font.BuilderSans,
        TextColor3 = color or C.text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, parent)
end
local function button(parent, name, text, primary, callback)
    local b = make("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 38),
        Text = text,
        TextSize = 14,
        Font = Enum.Font.BuilderSansBold,
        BackgroundColor3 = primary and C.accent or C.input,
        BorderSizePixel = 0,
        TextColor3 = primary and C.bg or C.text,
        AutoButtonColor = true,
    }, parent)
    corner(b, 6)
    if not primary then
        make(
            "UIStroke",
            { Color = C.border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
            b
        )
    end
    b.Activated:Connect(callback)
    return b
end
local function box(parent, name, placeholder, value)
    local b = make("TextBox", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = C.input,
        BorderSizePixel = 0,
        Text = value or "",
        PlaceholderText = placeholder,
        PlaceholderColor3 = C.muted,
        ClearTextOnFocus = false,
        TextSize = 14,
        TextColor3 = C.text,
        Font = Enum.Font.BuilderSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
    corner(b, 8)
    padding(b, 10)
    return b
end
local function card(parent, name, order)
    local f = make("Frame", {
        Name = name,
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, parent)
    corner(f, 8)
    padding(f, 14)
    layout(f, 10)
    return f
end

local function setIcon(image, mode)
    local i = (Modes[mode] or Modes.Auto).index
    image.Image = Modes.Atlas
    image.ImageRectOffset = Vector2.new(i % 4 * 256, math.floor(i / 4) * 256)
    image.ImageRectSize = Vector2.new(256, 256)
end
local function icon(parent, name, mode, size)
    local image = make(
        "ImageLabel",
        { Name = name, Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 },
        parent
    )
    setIcon(image, mode)
    return image
end

function UI.new(widget, settings, callbacks)
    local self = setmetatable({ widget = widget, tab = "Presence", callbacks = callbacks }, UI)
    local root = make(
        "Frame",
        {
            Name = "StudioSignalUI",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = C.bg,
            BorderSizePixel = 0,
        },
        widget
    )
    local header = make(
        "Frame",
        { Name = "Header", Size = UDim2.new(1, 0, 0, 77), BackgroundTransparency = 1 },
        root
    )
    local mark = icon(header, "SignalMark", "Auto", 40)
    mark.Position = UDim2.fromOffset(18, 16)
    local title = label(header, "Title", "StudioSignal", 23)
    title.Position = UDim2.fromOffset(66, 16)
    title.Size = UDim2.new(1, -84, 0, 28)
    title.Font = Enum.Font.BuilderSansBold
    local sub = label(header, "Subtitle", "DISCORD PRESENCE", 11, C.muted)
    sub.Position = UDim2.fromOffset(67, 46)
    sub.Size = UDim2.new(1, -84, 0, 16)
    local tabs = make("Frame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(18, 77),
        Size = UDim2.new(1, -36, 0, 36),
        BackgroundTransparency = 1,
    }, root)
    local pages = make("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(0, 125),
        Size = UDim2.new(1, 0, 1, -153),
        BackgroundTransparency = 1,
    }, root)
    local footer = label(root, "Footer", Config.Version .. "  /  " .. Config.Copyright, 10, C.muted)
    footer.Position = UDim2.new(0, 18, 1, -22)
    footer.Size = UDim2.new(1, -36, 0, 18)
    self.pages = {}
    self.tabs = {}
    for i, name in ipairs({ "Presence", "Settings", "More tools" }) do
        local b = button(tabs, name, name, false, function()
            self:selectTab(name)
        end)
        b.Position = UDim2.new((i - 1) / 3, 3, 0, 0)
        b.Size = UDim2.new(1 / 3, -6, 1, 0)
        self.tabs[name] = b
        local p = make("ScrollingFrame", {
            Name = name,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = C.border,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, pages)
        padding(p, 18)
        layout(p, 14)
        self.pages[name] = p
    end
    local presence = self.pages.Presence
    local state = card(presence, "Connection", 2)
    self.status = label(state, "Status", "NOT CONNECTED", 12, C.muted)
    self.status.Font = Enum.Font.BuilderSansBold
    self.detail = label(state, "Detail", "Connect to share your Studio activity.", 13, C.muted)
    self.permissionNotice = label(
        state,
        "PermissionNotice",
        "Before connecting: Discord bundles activity access with permission to view and manage friends, blocked users and game invites. StudioSignal does not read or change those lists; it only links your account and updates your activity.",
        13,
        C.muted
    )
    self.connect = button(state, "Connect", "Connect Discord", true, callbacks.connect)
    self.share = button(state, "Share", "Start sharing", true, callbacks.toggleSharing)
    self.share.Visible = false
    self.disconnect = button(state, "Disconnect", "Disconnect account", false, callbacks.disconnect)
    self.disconnect.Visible = false
    self.codePanel = make("Frame", {
        Name = "SignIn",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
    }, state)
    layout(self.codePanel, 8)
    label(self.codePanel, "Hint", "1. Copy this link and open it in your browser.", 13, C.muted)
    self.linkBox = box(self.codePanel, "VerificationLink", "", "")
    self.linkBox.TextEditable = false
    label(
        self.codePanel,
        "CodeHint",
        "2. Enter the code and review Discord's permissions.",
        13,
        C.muted
    )
    self.codeBox = box(self.codePanel, "UserCode", "", "")
    self.codeBox.TextEditable = false
    self.codeBox.Font = Enum.Font.BuilderSansBold
    button(self.codePanel, "CancelLink", "Cancel sign-in", false, callbacks.disconnect)
    local preview = card(presence, "Preview", 1)
    label(preview, "PreviewHeading", "YOUR DISCORD ACTIVITY", 11, C.muted)
    local hero = make("Frame", {
        Name = "ActivityHero",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, preview)
    self.previewIcon = icon(hero, "ActivityIcon", "Building", 64)
    local meta = make("Frame", {
        Name = "ActivityText",
        Position = UDim2.fromOffset(78, 0),
        Size = UDim2.new(1, -78, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, hero)
    layout(meta, 6)
    self.previewTitle = label(meta, "ApplicationName", "StudioSignal", 17)
    self.previewTitle.Font = Enum.Font.BuilderSansBold
    self.previewDetails = label(meta, "Project", "Working on a private project", 13)
    self.previewState = label(meta, "WorkState", "Building in Roblox Studio", 13, C.muted)
    self.previewTime = label(meta, "Elapsed", "00:00 elapsed", 12, C.accent)
    self.previewLink = label(preview, "PlaceLink", "Project link included", 12, C.accent)
    label(
        preview,
        "PreviewNote",
        "Only this activity is shared. Discord controls its final layout.",
        11,
        C.muted
    )
    local activity = card(presence, "ActivityControls", 3)
    label(activity, "ActivityTitle", "What are you working on?", 15)
    self.mode = button(activity, "Mode", "Automatic", false, function()
        self:showModes(settings.mode)
    end)
    self.modeHint = label(
        activity,
        "ModeHint",
        "Automatic follows play mode, script type and recent selection.",
        12,
        C.muted
    )
    self.private =
        button(activity, "Private", "Private project: ON", false, callbacks.togglePrivate)
    local session = card(presence, "Session", 4)
    label(session, "SessionHeading", "Focus & session", 16)
    self.sessionText = label(session, "SessionText", "0 min active this session", 13, C.muted)
    self.focusText = label(
        session,
        "FocusText",
        "Choose a focus timer. It works without connecting Discord.",
        12,
        C.muted
    )
    local focusRow = make(
        "Frame",
        { Name = "FocusButtons", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 },
        session
    )
    for i, minutes in ipairs({ 25, 50 }) do
        local b = button(focusRow, "Focus" .. minutes, minutes .. " min", false, function()
            callbacks.focus(minutes)
        end)
        b.Position = UDim2.new((i - 1) / 3, 0, 0, 0)
        b.Size = UDim2.new(1 / 3, -5, 1, 0)
    end
    local stop = button(focusRow, "StopFocus", "End focus", false, callbacks.stopFocus)
    stop.Position = UDim2.new(2 / 3, 0, 0, 0)
    stop.Size = UDim2.new(1 / 3, 0, 1, 0)
    local prefs = self.pages.Settings
    local project = card(prefs, "ProjectPreferences", 1)
    label(project, "PreferencesTitle", "Project appearance", 17)
    label(project, "AliasLabel", "Display name", 12, C.muted)
    self.alias = box(project, "ProjectAlias", "Use the project name", settings.projectAlias)
    self.alias.FocusLost:Connect(function()
        callbacks.alias(self.alias.Text)
    end)
    label(
        project,
        "PrivacyHint",
        "Private mode hides the project name and link. Script names and source are never included.",
        12,
        C.muted
    )
    self.timer = button(project, "Timer", "Session timer: ON", false, callbacks.toggleTimer)
    self.placeLink = button(project, "Link", "Project link: OFF", false, callbacks.toggleLink)
    self.background =
        button(project, "Background", "Pause in background: ON", false, callbacks.toggleBackground)
    self.smartSelection = button(
        project,
        "SmartSelection",
        "Selection hints: ON",
        false,
        callbacks.toggleSmartSelection
    )
    label(
        project,
        "SelectionHint",
        "Recent selection can suggest UI, terrain, lighting, audio, animation or modeling for 45 seconds. These are hints, not detection of another plugin's tools.",
        12,
        C.muted
    )
    self.idle = button(project, "IdleMinutes", "Idle after: 5 min", false, callbacks.cycleIdle)
    self.idleBehavior = button(
        project,
        "IdleBehavior",
        "When idle: pause sharing",
        false,
        callbacks.toggleIdleBehavior
    )
    local account = card(prefs, "AccountInfo", 2)
    label(account, "AccountHeading", "Your account, your control", 17)
    label(
        account,
        "ScopeNotice",
        "Discord grants activity, friends, blocked-user and game-invite permissions together. StudioSignal only uses sign-in and activity updates. It does not read or manage your friends or blocked users, or send invitations.",
        13,
        C.muted
    )
    label(
        account,
        "RevokeNotice",
        "Disconnect account removes the activity and revokes this app's authorization. You can also revoke access in Discord Settings > Authorized Apps.",
        13,
        C.muted
    )
    label(
        account,
        "StorageNotice",
        "In this local preview, credentials stay in memory. Reconnect after restarting Studio. No telemetry or project source is collected.",
        13,
        C.muted
    )
    label(
        account,
        "CloseNotice",
        "Pause before closing to confirm removal. If Studio crashes or goes offline, Discord may retain the last activity until its session expires.",
        12,
        C.muted
    )
    local diagnostics = card(prefs, "Diagnostics", 3)
    label(diagnostics, "DiagnosticsTitle", "Connection details", 15)
    self.diagnostics = label(diagnostics, "DiagnosticsText", "No request sent yet.", 12, C.muted)
    self.setup = card(prefs, "DeveloperSetup", 4)
    self.setup.Visible = Config.ApplicationId == ""
    label(self.setup, "SetupTitle", "Preview setup", 15)
    label(
        self.setup,
        "SetupHint",
        "Application ID is public. Never enter a bot token, user token or client secret.",
        12,
        C.muted
    )
    self.appId = box(self.setup, "ApplicationId", "Discord Application ID", Config.ApplicationId)
    button(self.setup, "SaveApplication", "Use application ID", false, function()
        callbacks.appId(self.appId.Text)
    end)
    local more = self.pages["More tools"]
    local support = card(more, "Support", 0)
    label(support, "SupportTitle", "Need a hand?", 17)
    label(
        support,
        "SupportHint",
        "Get StudioSignal help in VOID HUB. Joining is optional.",
        13,
        C.muted
    )
    button(support, "DiscordSupport", "Support & Discord", true, function()
        self:showLink("VOID HUB | StudioSignal support", Config.SupportUrl)
    end)
    local contour = card(more, "ContourTerrain", 1)
    label(contour, "Byline", "MORE FROM THE CREATOR", 11, C.muted)
    local thumb = make("ImageLabel", {
        Name = "ContourImage",
        Size = UDim2.new(1, 0, 0, 142),
        BackgroundColor3 = C.input,
        BorderSizePixel = 0,
        Image = "rbxthumb://type=Asset&id=94088881259293&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit,
    }, contour)
    corner(thumb, 8)
    label(contour, "ProductName", "Contour Terrain", 24).Font = Enum.Font.BuilderSansBold
    label(
        contour,
        "ProductDescription",
        "Shape terrain, build roads and bring meshes into your Roblox world.",
        14,
        C.muted
    )
    button(contour, "ContourLink", "View Contour Terrain", true, function()
        self:showLink("Contour Terrain", Config.ContourUrl)
    end)
    label(
        contour,
        "Optional",
        "Optional. StudioSignal is free and does not require another plugin.",
        12,
        C.muted
    )
    local about = card(more, "About", 2)
    label(about, "AboutTitle", "Made by VOIDKSA", 16)
    label(about, "Copyright", Config.Copyright .. ". StudioSignal is free to use.", 12, C.muted)
    label(
        about,
        "AboutText",
        "Your Studio activity, live on Discord. No ads are inserted into your activity.",
        13,
        C.muted
    )
    label(
        about,
        "Independent",
        "An independent Roblox Studio plugin. Not affiliated with Discord or Roblox.",
        12,
        C.muted
    )
    self:selectTab("Presence")
    return self
end

function UI:showModes(selected)
    if self.linkModal then
        self.linkModal:Destroy()
    end
    local f = make(
        "Frame",
        { Name = "ModePicker", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, ZIndex = 10 },
        self.widget
    )
    self.linkModal = f
    local heading = label(f, "Heading", "Choose your activity", 21)
    heading.Position = UDim2.fromOffset(18, 18)
    heading.Size = UDim2.new(1, -36, 0, 30)
    local hint = label(
        f,
        "Hint",
        "Automatic adapts as you work. A manual choice stays selected.",
        12,
        C.muted
    )
    hint.Position = UDim2.fromOffset(18, 54)
    hint.Size = UDim2.new(1, -36, 0, 36)
    local grid = make("ScrollingFrame", {
        Name = "Modes",
        Position = UDim2.fromOffset(18, 100),
        Size = UDim2.new(1, -36, 1, -163),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
    }, f)
    make("UIGridLayout", {
        CellSize = UDim2.new(0.5, -5, 0, 56),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)
    for i, mode in ipairs(Modes.Order) do
        local data = Modes[mode]
        local b = button(grid, mode, "", false, function()
            self.callbacks.selectMode(mode)
            f:Destroy()
            self.linkModal = nil
        end)
        b.LayoutOrder = i
        b.BackgroundColor3 = selected == mode and C.border or C.panel
        local img = icon(b, "Icon", mode, 32)
        img.Position = UDim2.fromOffset(8, 12)
        local text = label(b, "Label", data.label, 12)
        text.Position = UDim2.fromOffset(47, 18)
        text.Size = UDim2.new(1, -51, 0, 32)
    end
    local back = button(f, "Back", "Back", false, function()
        f:Destroy()
        self.linkModal = nil
    end)
    back.Position = UDim2.new(0, 18, 1, -50)
    back.Size = UDim2.new(1, -36, 0, 34)
end

function UI:selectTab(name)
    self.tab = name
    for n, p in pairs(self.pages) do
        p.Visible = n == name
        self.tabs[n].BackgroundColor3 = n == name and C.accent or C.panel
        self.tabs[n].TextColor3 = n == name and C.bg or C.text
    end
end

function UI:showLink(title, url)
    if self.linkModal then
        self.linkModal:Destroy()
    end
    local f = make(
        "Frame",
        { Name = "LinkDialog", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, ZIndex = 10 },
        self.widget
    )
    padding(f, 24)
    layout(f, 16)
    self.linkModal = f
    label(f, "LinkTitle", title, 22)
    label(
        f,
        "LinkInstructions",
        "Select the link, copy it with Ctrl+C, and open it in your browser.",
        14,
        C.muted
    )
    local b = box(f, "LinkUrl", "", url)
    b.TextEditable = false
    button(f, "CloseLink", "Back", false, function()
        f:Destroy()
        self.linkModal = nil
    end)
    b:CaptureFocus()
    b.CursorPosition = #url + 1
    b.SelectionStart = 1
end

function UI:render(state, settings, activity, elapsed, configured, session, resolvedMode)
    local titles = {
        disconnected = "NOT CONNECTED",
        requesting = "CONNECTING",
        awaiting = "WAITING FOR YOU",
        paused = "PAUSED",
        sending = "UPDATING",
        sharing = "SHARING",
        retrying = "RECONNECTING",
        error = "NEEDS ATTENTION",
        disconnecting = "DISCONNECTING",
        updating = "UPDATING",
    }
    self.status.Text = titles[state.phase] or state.phase:upper()
    self.status.TextColor3 = state.phase == "sharing" and C.green or C.muted
    self.detail.Text = not configured
            and "Discord application setup is needed before connecting. You can explore the preview."
        or state.detail
    if state.phase == "sharing" then
        self.detail.Text = "Sharing your activity with Discord."
    end
    self.connect.Visible = not state.linked
        and state.phase ~= "awaiting"
        and state.phase ~= "requesting"
        and not state.disconnecting
    self.permissionNotice.Visible = not state.linked and not state.disconnecting
    self.connect.Text = configured and "Connect Discord" or "Set up Discord application"
    self.share.Visible = state.linked and not state.disconnecting
    self.share.Text = state.enabled and "Pause sharing" or "Start sharing"
    self.disconnect.Visible = (state.linked or state.phase == "requesting")
        and not state.disconnecting
    self.disconnect.Text = state.linked and "Disconnect account" or "Cancel sign-in"
    self.codePanel.Visible = state.phase == "awaiting"
    self.codeBox.Text = state.userCode or ""
    self.linkBox.Text = state.verificationUrl or ""
    self.previewDetails.Text = activity.details
    self.previewState.Text = activity.state
    setIcon(self.previewIcon, resolvedMode or "Building")
    self.previewTime.Visible = settings.showTimer
    self.previewTime.Text = elapsed >= 3600
            and string.format(
                "%d:%02d:%02d elapsed",
                math.floor(elapsed / 3600),
                math.floor(elapsed / 60) % 60,
                elapsed % 60
            )
        or string.format("%02d:%02d elapsed", math.floor(elapsed / 60), elapsed % 60)
    self.previewLink.Visible = activity.details_url ~= nil
    self.mode.Text = (Modes[settings.mode] or Modes.Auto).label .. "   >"
    self.modeHint.Text = settings.mode == "Auto"
            and ("Now: " .. (Modes[resolvedMode] or Modes.Building).label .. ". Play mode and the script editor take priority.")
        or "Manual activity selected. Choose Automatic to follow Studio."
    self.private.Text = "Private project: " .. (settings.private and "ON" or "OFF")
    self.private.TextColor3 = settings.private and C.green or C.text
    self.timer.Text = "Session timer: " .. (settings.showTimer and "ON" or "OFF")
    self.placeLink.Text = "Project link: " .. (settings.showLink and "ON" or "OFF")
    self.background.Text = "Pause in background: " .. (settings.pauseBackground and "ON" or "OFF")
    self.smartSelection.Text = "Selection hints: " .. (settings.smartSelection and "ON" or "OFF")
    self.idle.Text = "Idle after: "
        .. (settings.idleMinutes == 0 and "OFF" or tostring(settings.idleMinutes or 5) .. " min")
    self.idleBehavior.Text = "When idle: "
        .. (settings.idleBehavior == "Away" and "show Away activity" or "pause sharing")
    if session then
        self.sessionText.Text = math.floor(session.activeSeconds / 60)
            .. " min active this session | stays on this device"
        local remaining = session.focusEnds and math.max(0, session.focusEnds - os.time())
        self.focusText.Text = remaining
                and string.format(
                    "Focus  %02d:%02d remaining",
                    math.floor(remaining / 60),
                    remaining % 60
                )
            or (
                session.focusComplete and "Focus complete. Take a break when you are ready."
                or "25 or 50 minutes of focused work. No Discord connection needed."
            )
        if remaining and settings.showTimer then
            self.previewTime.Text =
                string.format("%02d:%02d remaining", math.floor(remaining / 60), remaining % 60)
        end
        if remaining then
            self.modeHint.Text =
                "Focus is shown until the timer ends. Your selected activity then resumes."
        end
    end
    if resolvedMode == "Idle" then
        self.previewTime.Visible = false
    end
    self.diagnostics.Text = (
        state.lastSuccess and "Last accepted update: " .. os.date("%H:%M:%S", state.lastSuccess)
        or "No accepted activity update yet."
    )
        .. (state.httpStatus and ("\nHTTP status: " .. tostring(state.httpStatus)) or "")
        .. "\nTransport: direct Discord HTTP (experimental)."
end

return UI

end
factories["App"]=function()
local Config = requireModule("Config")
local Api = requireModule("Api")
local Activity = requireModule("Activity")
local Controller = requireModule("Controller")
local UI = requireModule("UI")
local Modes = requireModule("Modes")
local Session = requireModule("Session")
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

end

requireModule("App").start(plugin)
