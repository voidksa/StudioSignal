-- Discord Headless Sessions is experimental and may change.
local Config = require(script.Parent.Config)
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
