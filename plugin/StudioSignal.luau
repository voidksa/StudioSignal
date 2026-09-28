-- StudioSignal v1.1. Generated from src/.
local factories,cache={},{}
local function requireModule(name)
 if cache[name]==nil then cache[name]=factories[name]() end
 return cache[name]
end
factories["Config"]=function()
return {
    Name = "StudioSignal",
    Version = "v1.1",
    Copyright = "© 2026 VOIDKSA",
    ApplicationId = "",
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
    animation = "ANIMATION_ASSET_ID",
    audio = "AUDIO_ASSET_ID",
    brand = "BRAND_ASSET_ID",
    building = "BUILDING_ASSET_ID",
    client = "CLIENT_ASSET_ID",
    debugging = "DEBUGGING_ASSET_ID",
    focus = "FOCUS_ASSET_ID",
    idle = "IDLE_ASSET_ID",
    lighting = "LIGHTING_ASSET_ID",
    modeling = "MODELING_ASSET_ID",
    module = "MODULE_ASSET_ID",
    scripting = "SCRIPTING_ASSET_ID",
    server = "SERVER_ASSET_ID",
    terrain = "TERRAIN_ASSET_ID",
    testing = "TESTING_ASSET_ID",
    ui = "UI_ASSET_ID",
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
    local iconMode = Activity.iconMode(settings, context)
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
            large_image = Modes[iconMode].asset,
            large_text = Modes[iconMode].label,
            small_image = Modes.BrandAsset,
            small_text = "StudioSignal | Discord Presence",
        },
    }
    local details = Activity.text(settings.detailsText, 110)
    local state = Activity.text(settings.stateText, 110)
    if not settings.private and details ~= "" then
        activity.details = details
    end
    if state ~= "" and mode ~= "Idle" and mode ~= "Focus" then
        activity.state = state
    end
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
    if not settings.private and settings.showLink then
        activity.details_url = Activity.gameLink(settings.gameUrl)
        if not activity.details_url and context.placeId > 0 then
            activity.details_url = "https://www.roblox.com/games/" .. tostring(context.placeId)
        end
    end
    return activity
end

function Activity.iconMode(settings, context)
    local mode = Activity.resolve(settings, context)
    if mode == "Focus" or mode == "Idle" then
        return mode
    end
    local custom = settings.iconMode
    return custom ~= "Auto" and table.find(Modes.Order, custom) and custom or mode
end

function Activity.gameLink(value)
    if type(value) ~= "string" then
        return nil
    end
    local url = value:match("^%s*(.-)%s*$") or ""
    local id, rest = url:match("^https://www%.roblox%.com/games/(%d+)(.*)$")
    if not id then
        id, rest = url:match("^https://roblox%.com/games/(%d+)(.*)$")
    end
    if not id or #id > 20 or not id:find("[1-9]") then
        return nil
    end
    if rest ~= "" and not rest:match("^/[%w%-_]*$") then
        return nil
    end
    return "https://www.roblox.com/games/" .. id
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

function Api.verificationLink(uri, code, complete)
    if
        uri ~= "https://discord.com/activate"
        or type(code) ~= "string"
        or #code < 1
        or #code > 32
        or not code:match("^[%w%-]+$")
    then
        return nil
    end
    local expected = uri .. "?user_code=" .. code
    if complete ~= nil and complete ~= expected then
        return nil
    end
    return expected
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
        local complete =
            Api.verificationLink(d.verification_uri, d.user_code, d.verification_uri_complete)
        if not complete then
            return { ok = false, kind = "invalid_response" }
        end
        -- Only the short verification code goes in this link, never the device
        -- code or bearer token. The QR is rendered locally.
        d.verification_uri_complete = complete
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
factories["Diagnostics"]=function()
local Config = requireModule("Config")
local Diagnostics = {}
local phases = {
    disconnected = true,
    requesting = true,
    awaiting = true,
    paused = true,
    sending = true,
    sharing = true,
    retrying = true,
    error = true,
    disconnecting = true,
    updating = true,
}
local operations =
    { authorize = true, poll = true, refresh = true, publish = true, clear = true, revoke = true }
local advice = {
    network = "Check your connection and StudioSignal's HTTP permission, then wait for the retry.",
    rate_limit = "Discord is limiting requests. Wait for the countdown; do not create another sign-in link.",
    app_pending = "Discord is preparing this application. Wait for the retry.",
    invalid_client = "Contact StudioSignal support with a support report. This is an application setup issue.",
    invalid_scope = "Contact StudioSignal support with a support report. This is an application permission issue.",
    forbidden = "Discord declined this request. Contact support if reconnecting does not help.",
    unauthorized = "Disconnect and connect again if automatic renewal does not recover.",
    invalid_grant = "The account grant expired or was revoked. Disconnect and connect again.",
    access_denied = "Sign-in was declined. Connect again only if you want to grant access.",
    expired_token = "The sign-in code expired. Choose Connect Discord for a new code.",
    invalid_response = "Discord returned an unexpected result. Share a support report with StudioSignal support.",
    http = "Discord rejected the request. Include the HTTP status in your support report.",
    authorization_pending = "Finish the Discord verification step in your browser.",
    slow_down = "Discord requested slower sign-in polling. Keep this window open and wait.",
}
function Diagnostics.errorKind(kind)
    return advice[kind] and kind or "http"
end
local function number(value)
    return type(value) == "number" and value == value and math.abs(value) < 1e12 and value or nil
end
function Diagnostics.summary(state, now)
    local lines = {
        state.lastSuccess and ("Last accepted update: " .. os.date("%H:%M:%S", state.lastSuccess))
            or "No accepted activity update yet.",
    }
    if state.lastHttpStatus then
        table.insert(lines, "Last HTTP status: " .. state.lastHttpStatus)
    end
    if state.lastErrorKind then
        table.insert(lines, advice[state.lastErrorKind] or advice.http)
        if (state.retryAt or 0) > now then
            table.insert(lines, "Next attempt in " .. math.ceil(state.retryAt - now) .. " seconds.")
        end
    elseif state.phase == "sharing" then
        table.insert(
            lines,
            "Discord accepted the activity. If it is hidden, check Discord's Activity Privacy settings."
        )
    elseif state.phase == "disconnected" then
        table.insert(lines, "Connect Discord, review your preview, then choose Start sharing.")
    elseif state.phase == "paused" then
        table.insert(
            lines,
            "Check Pause in background and idle behavior if sharing paused unexpectedly."
        )
    end
    return table.concat(lines, "\n")
end

function Diagnostics.report(state, now, isPlaying)
    -- Export only fixed labels, booleans and bounded numbers. Never include a
    -- payload, user-entered text, auth code, URL, account or project identifier.
    local status = number(state.lastHttpStatus)
    local last = number(state.lastSuccess)
    local retryAt = number(state.retryAt)
    return table.concat({
        "StudioSignal support report",
        "Version: " .. Config.Version,
        "Studio mode: " .. (isPlaying and "Play" or "Edit"),
        "Phase: " .. (phases[state.phase] and state.phase or "unknown"),
        "Account linked: " .. tostring(state.linked == true),
        "Sharing requested: " .. tostring(state.enabled == true),
        "Last operation: " .. (operations[state.lastOperation] and state.lastOperation or "none"),
        "Last result: "
            .. (state.lastErrorKind and Diagnostics.errorKind(state.lastErrorKind) or "none"),
        "HTTP status: " .. (status and string.format("%.0f", status) or "none"),
        "Last accepted update (seconds ago): "
            .. (last and tostring(math.max(0, math.floor(now - last))) or "none"),
        "Retry in seconds: " .. tostring(retryAt and math.max(0, math.ceil(retryAt - now)) or 0),
        "Transport: direct Discord HTTP (experimental)",
        "No account, project, profile, activity text or credentials included.",
    }, "\n")
end
return Diagnostics

end
factories["Controller"]=function()
local Config = requireModule("Config")
local Activity = requireModule("Activity")
local Diagnostics = requireModule("Diagnostics")
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
    invalid_response = "Discord returned an unexpected response. Open Settings for a support report.",
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
        verificationComplete = self.verificationComplete,
        expiresAt = self.deviceExpires,
        lastSuccess = self.lastSuccess,
        retryAt = self.nextAt,
        httpStatus = self.httpStatus,
        disconnecting = self.disconnecting,
        lastOperation = self.lastOperation,
        lastErrorKind = self.lastErrorKind,
        lastHttpStatus = self.lastHttpStatus,
    }
end

function Controller:connect()
    if
        self.accessToken
        or self.disconnecting
        or self.phase == "requesting"
        or self.phase == "awaiting"
    then
        return
    end
    if self.clock() < (self.linkRetryAt or 0) then
        self.nextAt = self.linkRetryAt
        self.lastErrorKind = self.linkRetryKind
        self:notify("error", "Discord asked us to wait before creating another sign-in code.")
        return
    end
    self.disconnecting = false
    self.stopped = false
    self.nextAt = 0
    self:notify("requesting", "Requesting a secure sign-in code from Discord...")
end

function Controller:observe(operation, result)
    self.lastOperation = operation
    self.lastHttpStatus = type(result.status) == "number" and result.status or nil
    self.lastErrorKind = not result.ok and Diagnostics.errorKind(result.kind) or nil
end

function Controller:setEnabled(value)
    if self.disconnecting then
        return
    end
    self.enabled = value and self.accessToken ~= nil
    self.revision += 1
    -- Respect an existing server backoff, including while clearing.
    if self.failures == 0 and self.accessToken then
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
    if self.failures == 0 and self.accessToken then
        self.nextAt = 0
    end
end

function Controller:disconnect()
    self.enabled = false
    self.disconnecting = true
    self.revision += 1
    self.deviceCode, self.userCode, self.verificationUrl, self.deviceExpires, self.verificationComplete =
        nil, nil, nil, nil, nil
    if self.failures == 0 or not self.accessToken then
        self.nextAt = 0
    end
    self:notify("disconnecting", "Removing your activity and disconnecting...")
end

function Controller:failure(r)
    self.lastErrorKind = Diagnostics.errorKind(r.kind)
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
            self:observe("clear", r)
            if not r.ok and r.kind ~= "unauthorized" then
                self:failure(r)
                return
            end
            self.sessionToken = nil
        end
        if self.accessToken then
            local r = self.api:revoke(self.accessToken)
            self:observe("revoke", r)
            if not r.ok and r.kind ~= "unauthorized" and r.kind ~= "invalid_grant" then
                self:failure(r)
                return
            end
        end
        self.accessToken, self.refreshToken, self.tokenExpires = nil, nil, nil
        self.deviceCode, self.userCode, self.verificationUrl, self.verificationComplete =
            nil, nil, nil, nil
        self.disconnecting, self.enabled = false, false
        self.failures, self.nextAt, self.httpStatus = 0, 0, nil
        self:notify("disconnected", "Disconnected. No new activity will be sent.")
        return
    end
    if self.phase == "requesting" then
        local r = self.api:beginLink()
        self:observe("authorize", r)
        if self.disconnecting then
            return
        end
        if not r.ok then
            self.failures += 1
            self.nextAt = self.clock() + Activity.retryDelay(self.failures, r.delay)
            if r.kind == "rate_limit" or r.kind == "app_pending" then
                self.linkRetryAt, self.linkRetryKind = self.nextAt, r.kind
            end
            local transient = r.kind == "network"
                or r.kind == "rate_limit"
                or r.kind == "app_pending"
            self:notify(transient and "requesting" or "error", messages[r.kind] or messages.http)
            self.httpStatus = r.status
            return
        end
        local d = r.data
        self.deviceCode, self.userCode, self.verificationUrl =
            d.device_code, d.user_code, d.verification_uri
        self.verificationComplete = d.verification_uri_complete
        self.deviceExpires = now + tonumber(d.expires_in)
        self.pollSeconds = math.max(5, tonumber(d.interval))
        self.nextAt = self.clock() + self.pollSeconds
        self:notify(
            "awaiting",
            "Scan the QR code or open the sign-in link, then review the permissions on Discord."
        )
        return
    end
    if self.deviceCode then
        if now >= self.deviceExpires then
            self.lastErrorKind = "expired_token"
            self.deviceCode, self.userCode, self.verificationUrl, self.verificationComplete =
                nil, nil, nil, nil
            self:notify("error", messages.expired_token)
            return
        end
        local r = self.api:pollLink(self.deviceCode)
        self:observe("poll", r)
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
            self.deviceCode, self.userCode, self.verificationUrl, self.verificationComplete =
                nil, nil, nil, nil
            self:notify("error", messages[r.kind] or messages.http)
            return
        end
        self.deviceCode, self.userCode, self.verificationUrl, self.verificationComplete =
            nil, nil, nil, nil
        if not self:acceptToken(r.data) then
            self.lastErrorKind = "invalid_response"
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
            self.lastErrorKind = "unauthorized"
            self.enabled = false
            self:notify("error", messages.unauthorized)
            return
        end
        local r = self.api:refresh(self.refreshToken)
        self:observe("refresh", r)
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
            self:observe("clear", r)
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
    self:observe("publish", r)
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
factories["QRCode"]=function()
-- Byte-mode QR version 5-L: one data block, 108 data and 26 parity bytes.
-- A fixed size keeps the sign-in renderer small and avoids image permissions.
local QRCode = {}
local SIZE, DATA, PARITY = 37, 108, 26
local function multiply(a, b)
    local result = 0
    for _ = 1, 8 do
        if bit32.band(b, 1) ~= 0 then
            result = bit32.bxor(result, a)
        end
        b = bit32.rshift(b, 1)
        a = bit32.lshift(a, 1)
        if a >= 256 then
            a = bit32.bxor(a, 0x11D)
        end
    end
    return result
end

local function codewords(text)
    local bits = {}
    local function append(value, count)
        for i = count - 1, 0, -1 do
            table.insert(bits, bit32.band(bit32.rshift(value, i), 1))
        end
    end
    append(4, 4)
    append(#text, 8)
    for i = 1, #text do
        append(string.byte(text, i), 8)
    end
    append(0, math.min(4, DATA * 8 - #bits))
    while #bits % 8 ~= 0 do
        table.insert(bits, 0)
    end
    local words = {}
    for i = 1, #bits, 8 do
        local value = 0
        for j = 0, 7 do
            value = value * 2 + bits[i + j]
        end
        table.insert(words, value)
    end
    local pad = 236
    while #words < DATA do
        table.insert(words, pad)
        pad = pad == 236 and 17 or 236
    end
    local generator, root = { 1 }, 1
    for _ = 1, PARITY do
        local nextPoly = table.create(#generator + 1, 0)
        for i, value in generator do
            nextPoly[i] = bit32.bxor(nextPoly[i], value)
            nextPoly[i + 1] = bit32.bxor(nextPoly[i + 1], multiply(value, root))
        end
        generator, root = nextPoly, multiply(root, 2)
    end
    local divided = table.clone(words)
    for _ = 1, PARITY do
        table.insert(divided, 0)
    end
    for i = 1, DATA do
        local factor = divided[i]
        for j, coefficient in generator do
            divided[i + j - 1] = bit32.bxor(divided[i + j - 1], multiply(coefficient, factor))
        end
    end
    for i = DATA + 1, DATA + PARITY do
        table.insert(words, divided[i])
    end
    return words
end

function QRCode.encode(text)
    if type(text) ~= "string" or #text == 0 or #text > 106 then
        return nil
    end
    local cells, reserved = {}, {}
    for y = 1, SIZE do
        cells[y], reserved[y] = table.create(SIZE, false), table.create(SIZE, false)
    end
    local function set(x, y, dark)
        if x >= 0 and y >= 0 and x < SIZE and y < SIZE then
            cells[y + 1][x + 1], reserved[y + 1][x + 1] = dark, true
        end
    end
    local function finder(cx, cy)
        for dy = -4, 4 do
            for dx = -4, 4 do
                local distance = math.max(math.abs(dx), math.abs(dy))
                set(cx + dx, cy + dy, distance ~= 2 and distance ~= 4)
            end
        end
    end
    finder(3, 3)
    finder(SIZE - 4, 3)
    finder(3, SIZE - 4)
    for i = 8, SIZE - 9 do
        set(i, 6, i % 2 == 0)
        set(6, i, i % 2 == 0)
    end
    for dy = -2, 2 do
        for dx = -2, 2 do
            set(30 + dx, 30 + dy, math.max(math.abs(dx), math.abs(dy)) ~= 1)
        end
    end
    -- Level L, mask 0. BCH format information, including the fixed XOR mask.
    local data, remainder = 8, 8
    for _ = 1, 10 do
        remainder = bit32.bxor(bit32.lshift(remainder, 1), bit32.rshift(remainder, 9) * 0x537)
    end
    local format = bit32.bxor(bit32.bor(bit32.lshift(data, 10), remainder), 0x5412)
    local function bit(i)
        return bit32.band(bit32.rshift(format, i), 1) ~= 0
    end
    for i = 0, 5 do
        set(8, i, bit(i))
    end
    set(8, 7, bit(6))
    set(8, 8, bit(7))
    set(7, 8, bit(8))
    for i = 9, 14 do
        set(14 - i, 8, bit(i))
    end
    for i = 0, 7 do
        set(SIZE - 1 - i, 8, bit(i))
    end
    for i = 8, 14 do
        set(8, SIZE - 15 + i, bit(i))
    end
    set(8, SIZE - 8, true)
    local words = codewords(text)
    local cursor, right, upward = 0, SIZE - 1, true
    while right >= 1 do
        if right == 6 then
            right = 5
        end
        for row = 0, SIZE - 1 do
            local y = upward and SIZE - 1 - row or row
            for dx = 0, 1 do
                local x = right - dx
                if not reserved[y + 1][x + 1] then
                    local word = words[math.floor(cursor / 8) + 1] or 0
                    local dark = bit32.band(bit32.rshift(word, 7 - cursor % 8), 1) ~= 0
                    cells[y + 1][x + 1] = dark ~= ((x + y) % 2 == 0)
                    cursor += 1
                end
            end
        end
        right, upward = right - 2, not upward
    end
    return cells
end

function QRCode.draw(parent, text)
    parent:ClearAllChildren()
    local cells = QRCode.encode(text)
    if not cells then
        return false
    end
    local scale, quiet = 5, 4
    parent.Size = UDim2.fromOffset((SIZE + quiet * 2) * scale, (SIZE + quiet * 2) * scale)
    parent.BackgroundColor3 = Color3.new(1, 1, 1)
    for y, row in cells do
        local x = 1
        while x <= SIZE do
            if row[x] then
                local start = x
                while x <= SIZE and row[x] do
                    x += 1
                end
                local run = Instance.new("Frame")
                run.BorderSizePixel = 0
                run.BackgroundColor3 = Color3.new(0, 0, 0)
                run.Position =
                    UDim2.fromOffset((start - 1 + quiet) * scale, (y - 1 + quiet) * scale)
                run.Size = UDim2.fromOffset((x - start) * scale, scale)
                run.Parent = parent
            else
                x += 1
            end
        end
    end
    return true
end
return QRCode

end
factories["Profiles"]=function()
local Activity = requireModule("Activity")
local Modes = requireModule("Modes")
local Profiles = {}
Profiles.__index = Profiles
Profiles.Key = "StudioSignal.profiles.v1"
Profiles.Limit = 20
Profiles.Fields = {
    "private",
    "showTimer",
    "showLink",
    "mode",
    "projectAlias",
    "detailsText",
    "stateText",
    "iconMode",
    "gameUrl",
}

local function text(value, limit)
    return type(value) == "string" and Activity.text(value, limit) or ""
end

function Profiles.clean(raw)
    raw = type(raw) == "table" and raw or {}
    local url = text(raw.gameUrl, 300)
    local normalized = Activity.gameLink(url)
    if url ~= "" and not normalized then
        return nil, "Use a Roblox game link: https://www.roblox.com/games/123456789"
    end
    return {
        name = text(raw.name, 40),
        private = raw.private ~= false,
        showTimer = raw.showTimer ~= false,
        showLink = raw.showLink == true,
        mode = table.find(Modes.Order, raw.mode) and raw.mode or "Auto",
        iconMode = table.find(Modes.Order, raw.iconMode) and raw.iconMode or "Auto",
        projectAlias = text(raw.projectAlias, 90),
        detailsText = text(raw.detailsText, 110),
        stateText = text(raw.stateText, 110),
        gameUrl = normalized or "",
    }
end

function Profiles.apply(settings, profile)
    for _, key in Profiles.Fields do
        settings[key] = profile[key]
    end
end

function Profiles.new(read, write, newId)
    local self = setmetatable({ read = read, write = write, newId = newId, items = {} }, Profiles)
    self:refresh()
    return self
end

function Profiles:refresh()
    self.items = {}
    local stored = self.read(Profiles.Key)
    if type(stored) ~= "table" or stored.schema ~= 1 or type(stored.items) ~= "table" then
        return
    end
    local seen = {}
    for _, raw in ipairs(stored.items) do
        if #self.items >= Profiles.Limit then
            break
        end
        if
            type(raw) == "table"
            and type(raw.id) == "string"
            and #raw.id <= 64
            and raw.id:match("^[%w%-]+$")
            and not seen[raw.id]
        then
            local profile = Profiles.clean(raw)
            if profile and profile.name ~= "" then
                profile.id = raw.id
                seen[raw.id] = true
                table.insert(self.items, profile)
            end
        end
    end
end

function Profiles:find(id)
    for _, profile in self.items do
        if profile.id == id then
            return profile
        end
    end
    return nil
end

function Profiles:save(id, raw)
    local profile, err = Profiles.clean(raw)
    if not profile then
        return nil, err
    end
    if profile.name == "" then
        return nil, "Give this profile a name."
    end
    self:refresh()
    if id and not self:find(id) then
        return nil, "This profile was removed. Save it as a new profile."
    end
    if not id and #self.items >= Profiles.Limit then
        return nil, "You can save up to 20 profiles."
    end
    profile.id = id or self.newId()
    local items, replaced = table.clone(self.items), false
    for i, item in items do
        if item.id == profile.id then
            items[i], replaced = profile, true
        end
    end
    if not replaced then
        table.insert(items, profile)
    end
    if not self.write(Profiles.Key, { schema = 1, items = items }) then
        return nil, "Studio could not save this profile. Try again."
    end
    self.items = items
    return profile
end

function Profiles:delete(id)
    self:refresh()
    local items = {}
    for _, profile in self.items do
        if profile.id ~= id then
            table.insert(items, profile)
        end
    end
    if not self.write(Profiles.Key, { schema = 1, items = items }) then
        return false
    end
    self.items = items
    return true
end

function Profiles.pinKey(placeId)
    if type(placeId) ~= "number" or placeId <= 0 then
        return nil
    end
    return "StudioSignal.profilePin." .. string.format("%.0f", placeId)
end

function Profiles:pinned(placeId)
    local key = Profiles.pinKey(placeId)
    return key and self:find(self.read(key)) or nil
end

function Profiles:pin(placeId, id)
    local key = Profiles.pinKey(placeId)
    if not key then
        return false,
            "Publish this place to Roblox before pinning. Saved profiles still work in local files."
    end
    self:refresh()
    if id and not self:find(id) then
        return false, "Save the profile before pinning it."
    end
    if not self.write(key, id or "") then
        return false, "Studio could not save the project pin."
    end
    return true
end

return Profiles

end
factories["ProfileEditor"]=function()
local Modes = requireModule("Modes")
local ProfileEditor = {}
ProfileEditor.__index = ProfileEditor

function ProfileEditor.new(page, callbacks, kit)
    local self =
        setmetatable({ callbacks = callbacks, kit = kit, fields = {}, page = page }, ProfileEditor)
    local make, label, button, box, card = kit.make, kit.label, kit.button, kit.box, kit.card
    local C = kit.colors
    self.library = card(page, "SavedProfiles", 0)
    label(self.library, "Title", "Your profiles", 20)
    label(
        self.library,
        "Hint",
        "Save a look, review it, then apply it. Editing never changes your live activity.",
        13,
        C.muted
    )
    self.pinStatus = label(self.library, "PinStatus", "", 12, C.accent)
    button(self.library, "NewProfile", "New from current appearance", true, function()
        self:newDraft()
    end)
    self.list = make("ScrollingFrame", {
        Name = "ProfileList",
        Size = UDim2.new(1, 0, 0, 144),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.border,
    }, self.library)
    kit.layout(self.list, 8)
    self.unpin = button(self.library, "Unpin", "Unpin from this project", false, function()
        local _, message = callbacks.unpinProfile()
        self.message.Text = message
        self:refresh()
    end)

    self.editor = card(page, "ProfileEditor", 1)
    label(self.editor, "Title", "Edit appearance", 18)
    button(self.editor, "Library", "Back to profiles", false, function()
        self.library.Visible, self.editor.Visible, self.reviewCard.Visible = true, false, false
        self.page.CanvasPosition = Vector2.zero
    end)
    local definitions = {
        { "name", "Profile name (only visible to you)", "e.g. Client work" },
        { "detailsText", "First line", "Blank uses the project display name" },
        { "stateText", "Activity text", "Blank follows your selected activity" },
        { "projectAlias", "Project display name", "Blank uses the current project name" },
        { "gameUrl", "Public game link", "https://www.roblox.com/games/123456789" },
    }
    for _, field in definitions do
        label(self.editor, field[1] .. "Label", field[2], 12, C.muted)
        self.fields[field[1]] = box(self.editor, field[1], field[3], "")
        self.fields[field[1]]:GetPropertyChangedSignal("Text"):Connect(function()
            self.deleteArmed = false
            if self.delete then
                self.delete.Text = "Delete saved profile"
            end
        end)
    end
    label(
        self.editor,
        "LinkHelp",
        "Use your published game's link even while editing a development copy. Links with private-server codes are not accepted.",
        12,
        C.muted
    )
    self.mode = button(self.editor, "Mode", "", false, function()
        kit.pick(self.draft.mode, function(mode)
            self.draft.mode = mode
            self:refreshControls()
        end, false)
    end)
    self.icon = button(self.editor, "Icon", "", false, function()
        kit.pick(self.draft.iconMode, function(mode)
            self.draft.iconMode = mode
            self:refreshControls()
        end, true)
    end)
    self.private = button(self.editor, "Private", "", false, function()
        self.draft.private = not self.draft.private
        self:refreshControls()
    end)
    label(
        self.editor,
        "PrivacyHelp",
        "Private mode hides the first line, project name and game link. Your custom activity text is still shared, so keep sensitive information out of it.",
        12,
        C.muted
    )
    self.timer = button(self.editor, "Timer", "", false, function()
        self.draft.showTimer = not self.draft.showTimer
        self:refreshControls()
    end)
    self.link = button(self.editor, "Link", "", false, function()
        self.draft.showLink = not self.draft.showLink
        self:refreshControls()
    end)
    button(self.editor, "Review", "Preview & apply", true, function()
        self:review()
    end)
    button(self.editor, "Save", "Save profile without applying", false, function()
        self:save()
    end)
    self.delete = button(self.editor, "Delete", "Delete saved profile", false, function()
        if not self.selectedId then
            return
        end
        if not self.deleteArmed then
            self.deleteArmed = true
            self.delete.Text = "Confirm delete"
            self.message.Text = "Click Confirm delete to remove this saved profile."
            return
        end
        local ok, message = callbacks.deleteProfile(self.selectedId)
        if ok then
            self:newDraft()
        end
        self.message.Text = message
        self:refresh()
    end)
    button(self.editor, "Discard", "Discard edits", false, function()
        self:newDraft()
    end)

    self.reviewCard = card(page, "ProfilePreview", 2)
    self.reviewCard.Visible = false
    label(self.reviewCard, "Title", "What others can see", 18)
    self.previewIcon = kit.icon(self.reviewCard, "Icon", "Building", 64)
    label(self.reviewCard, "AppName", "StudioSignal", 17)
    self.previewDetails = label(self.reviewCard, "Details", "", 14)
    self.previewState = label(self.reviewCard, "State", "", 14)
    self.previewTimer = label(self.reviewCard, "Timer", "", 12, C.accent)
    self.previewLink = label(self.reviewCard, "Link", "", 12, C.accent)
    self.previewBadge = label(self.reviewCard, "Badge", "Small badge: StudioSignal", 12, C.muted)
    label(
        self.reviewCard,
        "Note",
        "Preview of the data sent to Discord; Discord controls its final layout. Focus and Away temporarily override activity text and icons. Applying updates your activity only if sharing is already on.",
        12,
        C.muted
    )
    button(self.reviewCard, "Apply", "Apply to this session", true, function()
        local _, message = callbacks.applyProfile(self:collect(), self.selectedId)
        self.message.Text = message
    end)
    self.pin = button(self.reviewCard, "Pin", "Save, apply & pin to this project", false, function()
        local ok, message, profile = callbacks.pinProfile(self.selectedId, self:collect())
        if ok then
            self.selectedId, self.draft = profile.id, table.clone(profile)
        end
        self.message.Text = message
        self:refresh()
    end)
    self.pinHint = label(self.reviewCard, "PinHint", "", 12, C.muted)
    button(self.reviewCard, "Back", "Back to editor", false, function()
        self.library.Visible, self.editor.Visible, self.reviewCard.Visible = false, true, false
        self.page.CanvasPosition = Vector2.zero
    end)
    local feedback = card(page, "ProfileFeedback", -1)
    self.message = label(
        feedback,
        "Message",
        "Profiles stay on this device. Nothing changes until you apply.",
        13,
        C.accent
    )
    self:newDraft()
    self.library.Visible, self.editor.Visible = true, false
    return self
end

function ProfileEditor:collect()
    local draft = table.clone(self.draft)
    for key, field in self.fields do
        draft[key] = field.Text
    end
    return draft
end

function ProfileEditor:load(profile)
    self.page.CanvasPosition = Vector2.zero
    self.selectedId, self.draft = profile.id, table.clone(profile)
    self.deleteArmed = false
    for key, field in self.fields do
        field.Text = profile[key] or ""
    end
    self.library.Visible, self.editor.Visible, self.reviewCard.Visible = false, true, false
    self.message.Text = "Draft only. Review your changes before applying."
    self:refreshControls()
end

function ProfileEditor:newDraft()
    self:load(self.callbacks.profileDraft())
    self:refresh()
end

function ProfileEditor:refreshControls()
    self.mode.Text = "Activity: " .. Modes[self.draft.mode].label
    self.icon.Text = "Icon: "
        .. (self.draft.iconMode == "Auto" and "Follow activity" or Modes[self.draft.iconMode].label)
    self.private.Text = "Private project: " .. (self.draft.private and "ON" or "OFF")
    self.kit.setAction(self.private, self.draft.private and "lock" or "unlock")
    self.timer.Text = "Session timer: " .. (self.draft.showTimer and "ON" or "OFF")
    self.link.Text = "Game link: " .. (self.draft.showLink and "ON" or "OFF")
    self.delete.Visible = self.selectedId ~= nil
    self.delete.Text = "Delete saved profile"
    self.deleteArmed = false
end

function ProfileEditor:refresh()
    local items, pinnedId, canPin = self.callbacks.profiles()
    for _, child in self.list:GetChildren() do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    local pinnedName
    for i, profile in items do
        if profile.id == pinnedId then
            pinnedName = profile.name
        end
        local b = self.kit.button(
            self.list,
            "Profile" .. i,
            profile.name .. (profile.id == pinnedId and "  /  Pinned" or ""),
            false,
            function()
                self:load(profile)
            end
        )
        b.LayoutOrder = i
        b.Size = UDim2.new(1, -8, 0, 38)
        b.TextTruncate = Enum.TextTruncate.AtEnd
    end
    if #items == 0 then
        self.kit.label(self.list, "Empty", "No saved profiles yet.", 13, self.kit.colors.muted)
    end
    self.pinStatus.Text = pinnedName and "Pinned here: " .. pinnedName
        or "No profile pinned to this project."
    self.unpin.Visible = pinnedId ~= nil
    self.pin.Visible = canPin
    self.pinHint.Text = canPin
            and "Pinning loads this saved profile when the place opens. Sharing still requires your account connection and Start sharing."
        or "Pinning needs a published Roblox place. You can still save and apply profiles in local files."
end

function ProfileEditor:updatePreview()
    if not self.reviewCard.Visible then
        return
    end
    local activity, iconMode = self.callbacks.previewProfile(self:collect())
    if not activity then
        self.message.Text = iconMode
        return
    end
    self.kit.setIcon(self.previewIcon, iconMode)
    self.previewDetails.Text = activity.details
    self.previewState.Text = activity.state
    self.previewTimer.Text = activity.timestamps
            and (activity.timestamps["end"] and "Timer: focus countdown" or "Timer: session elapsed time")
        or "Timer: hidden"
    self.previewLink.Text = activity.details_url and ("Game link: " .. activity.details_url)
        or "Game link: hidden"
end

function ProfileEditor:review()
    self.page.CanvasPosition = Vector2.zero
    local activity, err = self.callbacks.previewProfile(self:collect())
    if not activity then
        self.message.Text = err
        return
    end
    self.library.Visible, self.editor.Visible, self.reviewCard.Visible = false, false, true
    self.message.Text = "Review this preview. Nothing has been applied yet."
    self:updatePreview()
end

function ProfileEditor:save()
    self.page.CanvasPosition = Vector2.zero
    local profile, err = self.callbacks.saveProfile(self.selectedId, self:collect())
    if not profile then
        self.message.Text = err
        return
    end
    self:load(profile)
    self.message.Text = "Saved on this device. Your current activity has not changed."
    self:refresh()
end

return ProfileEditor

end
factories["ActionIcons"]=function()
-- Antialiased action artwork. Editable SVGs and the source atlas are in assets/action-icons/.
local ActionIcons = {}
local ATLAS = "rbxassetid://75975102590667"
local indices = {
    activity = 0,
    back = 1,
    eye = 2,
    focus = 3,
    help = 4,
    image = 5,
    link = 6,
    lock = 7,
    moon = 8,
    more = 9,
    pause = 10,
    pin = 11,
    play = 12,
    plus = 13,
    profile = 14,
    refresh = 15,
    report = 16,
    save = 17,
    settings = 18,
    stop = 19,
    timer = 20,
    trash = 21,
    unlink = 22,
    unlock = 23,
}
local buttons = {
    Presence = "activity",
    Profiles = "profile",
    Settings = "settings",
    ["More tools"] = "more",
    Connect = "link",
    Share = "play",
    Disconnect = "unlink",
    CancelLink = "back",
    Customize = "settings",
    Mode = "activity",
    Icon = "image",
    Private = "lock",
    Timer = "timer",
    Link = "link",
    Background = "pause",
    SmartSelection = "focus",
    IdleMinutes = "timer",
    IdleBehavior = "moon",
    SupportReport = "report",
    SaveApplication = "save",
    DiscordSupport = "help",
    ContourLink = "link",
    Back = "back",
    CloseLink = "back",
    NewProfile = "plus",
    Unpin = "unlink",
    Library = "back",
    Review = "eye",
    Save = "save",
    Delete = "trash",
    Discard = "refresh",
    Apply = "play",
    Pin = "pin",
    StopFocus = "stop",
}
function ActionIcons.forButton(name)
    return buttons[name]
        or (name:match("^Focus%d") and "focus")
        or (name:match("^Profile%d") and "profile")
end
function ActionIcons.set(image, key)
    local index = indices[key]
    if index == nil then
        return
    end
    image.Image = ATLAS
    image.ImageRectOffset = Vector2.new(index % 6 * 128, math.floor(index / 6) * 128)
    image.ImageRectSize = Vector2.new(128, 128)
    image:SetAttribute("Action", key)
end
function ActionIcons.draw(parent, name, key, color, size)
    if indices[key] == nil then
        return nil
    end
    local image = Instance.new("ImageLabel")
    image.Name = name
    image.BackgroundTransparency = 1
    image.Size = UDim2.fromOffset(size, size)
    image.ImageColor3 = color
    image.ResampleMode = Enum.ResamplerMode.Default
    ActionIcons.set(image, key)
    image.Parent = parent
    return image
end
function ActionIcons.tint(image, color)
    image.ImageColor3 = color
end
return ActionIcons

end
factories["UI"]=function()
local Config = requireModule("Config")
local Modes = requireModule("Modes")
local Diagnostics = requireModule("Diagnostics")
local ProfileEditor = requireModule("ProfileEditor")
local QRCode = requireModule("QRCode")
local Api = requireModule("Api")
local ActionIcons = requireModule("ActionIcons")
local TweenService = game:GetService("TweenService")
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
    input = Color3.fromRGB(45, 46, 41),
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
local function button(parent, name, text, primary, callback, iconKey)
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
        TextWrapped = true,
    }, parent)
    corner(b, 10)
    b.AutoButtonColor = false
    b:SetAttribute("BaseColor", b.BackgroundColor3)
    local hoverTween, hovering
    local function refreshColor()
        if hoverTween then
            hoverTween:Cancel()
        end
        local base = b:GetAttribute("BaseColor")
        hoverTween = TweenService:Create(b, TweenInfo.new(0.14), {
            BackgroundColor3 = hovering and base:Lerp(C.text, 0.07) or base,
        })
        hoverTween:Play()
    end
    b.MouseEnter:Connect(function()
        hovering = true
        refreshColor()
    end)
    b.MouseLeave:Connect(function()
        hovering = false
        refreshColor()
    end)
    b:GetAttributeChangedSignal("BaseColor"):Connect(refreshColor)
    local actionKey = iconKey ~= false and (iconKey or ActionIcons.forButton(name))
    if actionKey then
        local compact = parent.Name == "FocusButtons"
        local glyph =
            ActionIcons.draw(b, "ActionIcon", actionKey, b.TextColor3, compact and 16 or 20)
        glyph.AnchorPoint = Vector2.new(0, 0.5)
        glyph.Position = UDim2.new(0, compact and 7 or 12, 0.5, 0)
        local inset = make("UIPadding", {
            PaddingLeft = UDim.new(0, compact and 29 or 42),
            PaddingRight = UDim.new(0, compact and 4 or 12),
        }, b)
        -- Padding would also offset child icons; anchor the glyph outside it.
        glyph.Position = UDim2.new(0, (compact and 7 or 12) - inset.PaddingLeft.Offset, 0.5, 0)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextSize = compact and 12 or 13
        b:GetPropertyChangedSignal("TextColor3"):Connect(function()
            ActionIcons.tint(glyph, b.TextColor3)
            local tabLabel = b:FindFirstChild("TabLabel")
            if tabLabel then
                tabLabel.TextColor3 = b.TextColor3
            end
        end)
    end
    b.Activated:Connect(callback)
    return b
end
local function box(parent, name, placeholder, value, readOnly)
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
    if readOnly then
        b.TextEditable = false
        return b
    end
    local focusStroke = make("UIStroke", {
        Color = C.accent,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, b)
    local focusTween
    local function highlight(transparency)
        if focusTween then
            focusTween:Cancel()
        end
        focusTween =
            TweenService:Create(focusStroke, TweenInfo.new(0.12), { Transparency = transparency })
        focusTween:Play()
    end
    b.Focused:Connect(function()
        highlight(0.15)
    end)
    b.FocusLost:Connect(function()
        highlight(1)
    end)
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
    corner(f, 12)
    padding(f, 16)
    layout(f, 12)
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
    local root = make("Frame", {
        Name = "StudioSignalUI",
        Visible = false,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
    }, widget)
    local header = make(
        "Frame",
        { Name = "Header", Size = UDim2.new(1, 0, 0, 77), BackgroundTransparency = 1 },
        root
    )
    local mark = icon(header, "SignalMark", "Auto", 40)
    mark.Position = UDim2.fromOffset(18, 16)
    local title = label(header, "Title", "StudioSignal", 23)
    title.Position = UDim2.fromOffset(66, 16)
    title.Size = UDim2.new(1, -152, 0, 28)
    title.Font = Enum.Font.BuilderSansBold
    local version = make("TextLabel", {
        Name = "VersionBadge",
        Text = Config.Version,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 13,
        TextColor3 = C.accent,
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -68, 0, 20),
        Size = UDim2.fromOffset(50, 24),
    }, header)
    corner(version, 7)
    local sub = label(header, "Subtitle", "Discord Presence", 12, C.muted)
    sub.Position = UDim2.fromOffset(67, 46)
    sub.Size = UDim2.new(1, -84, 0, 16)
    local tabs = make("Frame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(18, 77),
        Size = UDim2.new(1, -36, 0, 50),
        BackgroundTransparency = 1,
    }, root)
    local pages = make("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(0, 139),
        Size = UDim2.new(1, 0, 1, -167),
        BackgroundTransparency = 1,
    }, root)
    local footer = label(root, "Footer", Config.Version .. "  /  " .. Config.Copyright, 10, C.muted)
    footer.Position = UDim2.new(0, 18, 1, -22)
    footer.Size = UDim2.new(1, -36, 0, 18)
    self.pages = {}
    self.tabs = {}
    for i, name in ipairs({ "Presence", "Profiles", "Settings", "More tools" }) do
        local b = button(tabs, name, name == "More tools" and "More" or name, false, function()
            self:selectTab(name)
        end)
        b.Position = UDim2.new((i - 1) / 4, 2, 0, 0)
        b.Size = UDim2.new(1 / 4, -4, 1, 0)
        b.TextSize = 12
        b.Text = ""
        local inset = b:FindFirstChildWhichIsA("UIPadding")
        if inset then
            inset:Destroy()
        end
        b.ActionIcon.AnchorPoint = Vector2.new(0.5, 0)
        b.ActionIcon.Position = UDim2.new(0.5, 0, 0, 5)
        local tabLabel = label(b, "TabLabel", name == "More tools" and "More" or name, 11)
        tabLabel.Position = UDim2.fromOffset(0, 29)
        tabLabel.Size = UDim2.new(1, 0, 0, 16)
        tabLabel.TextXAlignment = Enum.TextXAlignment.Center
        tabLabel.Font = Enum.Font.BuilderSansBold
        make("Frame", {
            Name = "SelectedIndicator",
            Size = UDim2.new(1, -24, 0, 2),
            Position = UDim2.new(0, 12, 1, -2),
            BackgroundColor3 = C.accent,
            BorderSizePixel = 0,
        }, b)
        self.tabs[name] = b
        local p = make("ScrollingFrame", {
            Name = name,
            Visible = false,
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
    self.profileEditor = ProfileEditor.new(self.pages.Profiles, callbacks, {
        make = make,
        label = label,
        button = button,
        box = box,
        card = card,
        layout = layout,
        icon = icon,
        setIcon = setIcon,
        setAction = function(button, key)
            ActionIcons.set(button.ActionIcon, key)
        end,
        colors = C,
        pick = function(selected, onSelect, iconsOnly)
            self:showModes(selected, onSelect, iconsOnly)
        end,
    })
    local state = card(presence, "Connection", 2)
    self.connectionCard = state
    self.status = label(state, "Status", "NOT CONNECTED", 12, C.muted)
    self.status.Font = Enum.Font.BuilderSansBold
    self.detail = label(state, "Detail", "Connect to share your Studio activity.", 13, C.muted)
    self.permissionNotice = label(
        state,
        "PermissionNotice",
        "Discord also grants access to view/manage friends and blocked users, and send invites. StudioSignal uses only sign-in and activity updates.",
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
    label(self.codePanel, "Hint", "1. Scan with your phone, or copy the link below.", 13, C.muted)
    self.qr = make(
        "Frame",
        { Name = "SignInQR", Size = UDim2.fromOffset(225, 225), BorderSizePixel = 0 },
        self.codePanel
    )
    label(
        self.codePanel,
        "QRHint",
        "Scan to open Discord with your code filled in. Review and approve there.",
        12,
        C.muted
    )
    self.linkBox = box(self.codePanel, "VerificationLink", "", "")
    self.linkBox.TextEditable = false
    label(self.codePanel, "CodeHint", "Your code (for manual entry if needed):", 13, C.muted)
    self.codeBox = box(self.codePanel, "UserCode", "", "")
    self.codeBox.TextEditable = false
    self.codeBox.Font = Enum.Font.BuilderSansBold
    self.codeExpiry = label(self.codePanel, "CodeExpiry", "", 12, C.accent)
    button(self.codePanel, "CancelLink", "Cancel sign-in", false, callbacks.disconnect)
    local preview = card(presence, "Preview", 1)
    label(preview, "PreviewHeading", "Activity preview", 16, C.text).Font =
        Enum.Font.BuilderSansBold
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
    make("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, preview)
    local activity = preview
    self.mode = button(activity, "Mode", "", false, function()
        self:showModes(settings.mode)
    end, false)
    self.mode.Size = UDim2.new(1, 0, 0, 62)
    self.modeIcon = icon(self.mode, "ModeIcon", "Building", 38)
    self.modeIcon.Position = UDim2.fromOffset(10, 12)
    self.modeLabel = label(self.mode, "ModeLabel", "Automatic", 14)
    self.modeLabel.Font = Enum.Font.BuilderSansBold
    self.modeLabel.Position = UDim2.fromOffset(60, 11)
    self.modeLabel.Size = UDim2.new(1, -88, 0, 20)
    self.modeHint = label(self.mode, "ModeHint", "Now: Building", 12, C.muted)
    self.modeHint.Position = UDim2.fromOffset(60, 34)
    self.modeHint.Size = UDim2.new(1, -88, 0, 18)
    for _, text in { self.modeLabel, self.modeHint } do
        text.AutomaticSize = Enum.AutomaticSize.None
        text.TextWrapped = false
        text.TextTruncate = Enum.TextTruncate.AtEnd
    end
    local arrow = label(self.mode, "Arrow", ">", 18, C.muted)
    arrow.Position = UDim2.new(1, -24, 0, 19)
    arrow.Size = UDim2.fromOffset(14, 24)
    self.private =
        button(activity, "Private", "Private project: ON", false, callbacks.togglePrivate)
    button(preview, "Customize", "Edit appearance", false, function()
        self.profileEditor:newDraft()
        self:selectTab("Profiles")
    end)
    label(preview, "PreviewNote", "Preview only. Discord controls the final layout.", 11, C.muted)
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
        "Credentials stay in memory. Reconnect after restarting Studio. No telemetry or project source is collected.",
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
    button(diagnostics, "SupportReport", "View safe support report", false, function()
        self:showReport(callbacks.supportReport())
    end)
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
    local updates = card(more, "WhatsNew", -1)
    label(updates, "UpdatesTitle", "What's new", 20)
    label(updates, "UpdatesVersion", Config.Version .. " / Custom profiles", 13, C.accent)
    label(
        updates,
        "UpdatesText",
        "Save custom text, icons, privacy and public game links in Profiles. Preview before applying, or pin a profile to a published place.\n\nScan the sign-in QR code with your phone. Connection guidance and a safe support report are available in Settings.\n\nIncludes the v1.0.1 panel fixes for Edit and Play.",
        13,
        C.muted
    )
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
    root.Visible = true
    return self
end

function UI:showModes(selected, onSelect, iconsOnly)
    if self.linkModal then
        self.linkModal:Destroy()
    end
    local f = make(
        "Frame",
        { Name = "ModePicker", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, ZIndex = 10 },
        self.widget
    )
    self.linkModal = f
    local heading =
        label(f, "Heading", iconsOnly and "Choose your icon" or "Choose your activity", 21)
    heading.Position = UDim2.fromOffset(18, 18)
    heading.Size = UDim2.new(1, -36, 0, 30)
    local hint = label(
        f,
        "Hint",
        iconsOnly
                and "Follow activity switches icons automatically. Focus and Away keep their own icons."
            or "Automatic adapts as you work. A manual choice stays selected.",
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
            if onSelect then
                onSelect(mode)
            else
                self.callbacks.selectMode(mode)
            end
            f:Destroy()
            self.linkModal = nil
        end)
        b.LayoutOrder = i
        b:SetAttribute("BaseColor", selected == mode and C.border or C.panel)
        local img = icon(b, "Icon", mode, 32)
        img.Position = UDim2.fromOffset(8, 12)
        local text =
            label(b, "Label", iconsOnly and mode == "Auto" and "Follow activity" or data.label, 12)
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
        self.tabs[n]:SetAttribute("BaseColor", n == name and C.panel or C.bg)
        self.tabs[n].TextColor3 = n == name and C.accent or C.muted
        self.tabs[n].SelectedIndicator.Visible = n == name
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
    self.permissionNotice.Visible = not state.linked
        and not state.disconnecting
        and state.phase ~= "awaiting"
    self.connectionCard.LayoutOrder = state.phase == "awaiting" and 0 or 2
    self.connect.Text = configured and "Connect Discord" or "Set up Discord application"
    self.share.Visible = state.linked and not state.disconnecting
    self.share.Text = state.enabled and "Pause sharing" or "Start sharing"
    ActionIcons.set(self.share.ActionIcon, state.enabled and "pause" or "play")
    self.disconnect.Visible = (state.linked or state.phase == "requesting")
        and not state.disconnecting
    self.disconnect.Text = state.linked and "Disconnect account" or "Cancel sign-in"
    self.codePanel.Visible = state.phase == "awaiting"
    if self.codePanel.Visible then
        local qrUrl =
            Api.verificationLink(state.verificationUrl, state.userCode, state.verificationComplete)
        if self.qrUrl ~= qrUrl then
            self.qrUrl = qrUrl
            self.qr.Visible = qrUrl ~= nil and QRCode.draw(self.qr, qrUrl)
        end
        self.codeExpiry.Text = "Code expires in "
            .. math.max(0, math.ceil((state.expiresAt or 0) - os.time()))
            .. " seconds"
    elseif self.qrUrl then
        self.qr:ClearAllChildren()
        self.qrUrl = nil
    end
    self.codeBox.Text = state.userCode or ""
    self.linkBox.Text = self.codePanel.Visible and (self.qrUrl or state.verificationUrl or "") or ""
    self.previewDetails.Text = activity.details
    self.previewState.Text = activity.state
    local previewMode = settings.iconMode ~= "Auto"
            and table.find(Modes.Order, settings.iconMode)
            and settings.iconMode
        or resolvedMode
    if resolvedMode == "Focus" or resolvedMode == "Idle" then
        previewMode = resolvedMode
    end
    setIcon(self.previewIcon, previewMode or "Building")
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
    self.previewLink.Text = activity.details_url or ""
    self.modeLabel.Text = (Modes[settings.mode] or Modes.Auto).label
    setIcon(
        self.modeIcon,
        settings.mode == "Auto" and (resolvedMode or "Building") or settings.mode
    )
    self.modeHint.Text = settings.mode == "Auto"
            and ("Now: " .. (Modes[resolvedMode] or Modes.Building).label)
        or "Manual activity"
    self.private.Text = "Private project: " .. (settings.private and "ON" or "OFF")
    self.private.TextColor3 = settings.private and C.green or C.text
    ActionIcons.set(self.private.ActionIcon, settings.private and "lock" or "unlock")
    self.timer.Text = "Session timer: " .. (settings.showTimer and "ON" or "OFF")
    self.placeLink.Text = "Project link: " .. (settings.showLink and "ON" or "OFF")
    self.background.Text = "Pause in background: " .. (settings.pauseBackground and "ON" or "OFF")
    self.smartSelection.Text = "Selection hints: " .. (settings.smartSelection and "ON" or "OFF")
    self.idle.Text = "Idle after: "
        .. (settings.idleMinutes == 0 and "OFF" or tostring(settings.idleMinutes or 5) .. " min")
    self.idleBehavior.Text = "When idle: "
        .. (settings.idleBehavior == "Away" and "show Away activity" or "pause sharing")
    if session then
        self.sessionText.Text = math.floor(session.activeSeconds / 60) .. " min active this session"
        local remaining = session.focusEnds and math.max(0, session.focusEnds - os.time())
        self.focusText.Text = remaining
                and string.format(
                    "Focus  %02d:%02d remaining",
                    math.floor(remaining / 60),
                    remaining % 60
                )
            or (
                session.focusComplete and "Focus complete. Take a break when you are ready."
                or "Choose a timer. Works offline too."
            )
        if remaining and settings.showTimer then
            self.previewTime.Text =
                string.format("%02d:%02d remaining", math.floor(remaining / 60), remaining % 60)
        end
        if remaining then
            self.modeHint.Text = "Focus timer active"
        end
    end
    if resolvedMode == "Idle" then
        self.previewTime.Visible = false
    end
    self.diagnostics.Text = Diagnostics.summary(state, os.time())
        .. "\nTransport: direct Discord HTTP (experimental)."
    if not self.alias:IsFocused() then
        self.alias.Text = settings.projectAlias
    end
    self.profileEditor:updatePreview()
end

function UI:refreshProfiles()
    self.profileEditor:refresh()
end

function UI:selectReportText()
    local modal = self.linkModal
    if not modal or modal.Name ~= "SupportReport" then
        return
    end
    local field = modal.ReportScroll.ReportFrame.ReportText
    field:CaptureFocus()
    field.CursorPosition = #field.Text + 1
    field.SelectionStart = 1
    modal.Hint.Text =
        "Report selected. Press Ctrl+C (Cmd+C on Mac), then paste it into your support message. Nothing is sent automatically."
end

function UI:showReport(report)
    if self.linkModal then
        self.linkModal:Destroy()
    end
    local f = make("Frame", {
        Name = "SupportReport",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, self.widget)
    self.linkModal = f
    padding(f, 18)
    label(f, "Title", "Support report", 21).Size = UDim2.new(1, 0, 0, 30)
    local hint = label(
        f,
        "Hint",
        "A diagnostic snapshot for support, without your private details. Use Copy report below, then press Ctrl+C (Cmd+C on Mac). Nothing is sent automatically.",
        13,
        C.muted
    )
    hint.Position = UDim2.fromOffset(0, 42)
    hint.Size = UDim2.new(1, 0, 0, 62)
    local area = make("ScrollingFrame", {
        Name = "ReportScroll",
        Position = UDim2.fromOffset(0, 110),
        Size = UDim2.new(1, 0, 1, -164),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
    }, f)
    padding(area, 2)
    layout(area, 12)
    local frame = make("Frame", {
        Name = "ReportFrame",
        LayoutOrder = 1,
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.input,
        BorderSizePixel = 0,
    }, area)
    corner(frame, 9)
    padding(frame, 1)
    local field = box(frame, "ReportText", "", report, true)
    field.Size = UDim2.new(1, 0, 0, 0)
    field.AutomaticSize = Enum.AutomaticSize.Y
    field.MultiLine = true
    field.TextWrapped = true
    field.TextTruncate = Enum.TextTruncate.None
    field.TextYAlignment = Enum.TextYAlignment.Top
    field.Focused:Connect(function()
        frame.BackgroundColor3 = C.accent
    end)
    field.FocusLost:Connect(function()
        frame.BackgroundColor3 = C.input
    end)
    local copy = button(area, "CopyReport", "Copy report", true, function()
        self:selectReportText()
    end, "report")
    copy.LayoutOrder = 2
    copy.Size = UDim2.new(1, -8, 0, 38)
    local close = button(f, "Back", "Back", false, function()
        f:Destroy()
        self.linkModal = nil
    end)
    close.Position = UDim2.new(0, 0, 1, -38)
end

return UI

end
factories["Panel"]=function()
local Panel = {}

function Panel.create(pluginObject, preview, isPlaying)
    local key = "StudioSignal.panelVisible." .. (isPlaying and "play" or "edit")
    local saved
    if not preview then
        local ok, value = pcall(function()
            return pluginObject:GetSetting(key)
        end)
        if ok and type(value) == "boolean" then
            saved = value
        end
    end

    -- Studio keeps separate layouts for edit and play. Old play layouts may
    -- contain a window opened by the previous default, not by the user.
    local overrideRestore = preview or saved ~= nil or isPlaying
    local widget = pluginObject:CreateDockWidgetPluginGuiAsync(
        "StudioSignal.Presence.v01" .. (preview and ".Dev" or ""),
        DockWidgetPluginGuiInfo.new(
            Enum.InitialDockState.Float,
            preview or saved == true,
            overrideRestore,
            420, 720, 340, 420
        )
    )
    local function remember()
        if not preview then
            pcall(function()
                pluginObject:SetSetting(key, widget.Enabled)
            end)
        end
    end
    remember()
    local connection = widget:GetPropertyChangedSignal("Enabled"):Connect(remember)
    return widget, connection
end

return Panel

end
factories["App"]=function()
local Config = requireModule("Config")
local Api = requireModule("Api")
local Activity = requireModule("Activity")
local Controller = requireModule("Controller")
local UI = requireModule("UI")
local Modes = requireModule("Modes")
local Session = requireModule("Session")
local Panel = requireModule("Panel")
local Profiles = requireModule("Profiles")
local Diagnostics = requireModule("Diagnostics")
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

end

requireModule("App").start(plugin)
