local Config = require(script.Parent.Config)
local Activity = require(script.Parent.Activity)
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
