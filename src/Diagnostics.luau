local Config = require(script.Parent.Config)
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
