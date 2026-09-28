local Activity = requireModule("Activity")
local Controller = requireModule("Controller")
local Api = requireModule("Api")
local Modes = requireModule("Modes")
local Session = requireModule("Session")
local http = game:GetService("HttpService")
local passed = {}
local function check(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        error(name .. ": " .. tostring(err))
    end
    table.insert(passed, name)
end
local settings = {
    private = true,
    showTimer = true,
    showLink = true,
    mode = "Auto",
    projectAlias = "Secret alias",
}
local context = {
    projectName = "Secret Project",
    placeId = 123456,
    scripting = false,
    testing = false,
    startedAt = 1700000000,
}
local payload = Activity.build(settings, context, "123456789012345678")
check("private payload omits title alias id and link", function()
    local s = http:JSONEncode(payload)
    assert(not s:find("Secret") and not s:find("/games/") and payload.details_url == nil)
end)
check("private payload has no arbitrary metadata", function()
    assert(payload.source == nil and payload.script == nil and payload.buttons == nil)
    assert(
        payload.assets.large_image == Modes.Building.asset
            and payload.assets.large_text == "Building"
    )
end)
check("public project link only when published and explicitly enabled", function()
    local s = table.clone(settings)
    s.private = false
    assert(Activity.build(s, context, "1").details_url == "https://www.roblox.com/games/123456")
    s.showLink = false
    assert(Activity.build(s, context, "1").details_url == nil)
    s.showLink = true
    local c = table.clone(context)
    c.placeId = 0
    assert(Activity.build(s, c, "1").details_url == nil)
end)
check("automatic activity priority", function()
    local c = table.clone(context)
    c.scripting = true
    assert(Activity.build(settings, c, "1").state == "Writing Luau")
    c.testing = true
    assert(Activity.build(settings, c, "1").state == "Playtesting in Roblox Studio")
end)
check("manual mode and timer omission", function()
    local s = table.clone(settings)
    s.mode = "Terrain"
    s.showTimer = false
    local a = Activity.build(s, context, "1")
    assert(a.state == "Creating terrain" and a.timestamps == nil)
end)
check("UTF8 truncation and control cleanup", function()
    local s = Activity.text(string.rep("ع", 100), 90)
    assert(utf8.len(s) == 90)
    assert(Activity.text("  Hello\nWorld\t ", 90) == "Hello World")
end)
check("respects provider retry delay", function()
    assert(Activity.retryDelay(1, 135) == 135)
end)

local function fixture()
    local now = 1000
    local calls = { publish = 0, clear = 0, revoke = 0, poll = 0, refresh = 0 }
    local api = {}
    function api:beginLink()
        return {
            ok = true,
            data = {
                device_code = "device-secret",
                user_code = "ABCD-EFGH",
                verification_uri = "https://discord.com/activate",
                expires_in = 60,
                interval = 5,
            },
        }
    end
    function api:pollLink()
        calls.poll += 1
        return {
            ok = true,
            data = {
                access_token = "access-secret",
                refresh_token = "refresh-secret",
                expires_in = 3600,
            },
        }
    end
    function api:publish(access, session, a)
        calls.publish += 1
        return { ok = true, data = { token = "session-" .. calls.publish } }
    end
    function api:clear()
        calls.clear += 1
        return { ok = true }
    end
    function api:revoke()
        calls.revoke += 1
        return { ok = true }
    end
    function api:refresh()
        calls.refresh += 1
        return {
            ok = true,
            data = { access_token = "refreshed", refresh_token = "refresh-new", expires_in = 3600 },
        }
    end
    local c = Controller.new(api, function()
        return now
    end, function(a)
        return http:JSONEncode(a)
    end)
    local function advance(n)
        now += n
    end
    local function link()
        c:connect()
        c:step(payload, false)
        advance(5)
        c:step(payload, false)
    end
    return c, api, calls, advance, link
end
check("linking does not publish automatically", function()
    local c, _, calls, _, link = fixture()
    link()
    assert(c.phase == "paused" and not c.enabled and calls.publish == 0)
    local s = http:JSONEncode(c:snapshot())
    assert(not s:find("secret"))
end)
check("publishing, heartbeat, session token rotation", function()
    local c, _, calls, advance, link = fixture()
    link()
    c:setEnabled(true)
    c:step(payload, false)
    assert(c.phase == "sharing" and c.sessionToken == "session-1")
    advance(16)
    c:step(payload, false)
    assert(calls.publish == 1)
    advance(121)
    c:step(payload, false)
    assert(calls.publish == 2 and c.sessionToken == "session-2")
end)
check("pause removes previous activity", function()
    local c, _, calls, _, link = fixture()
    link()
    c:setEnabled(true)
    c:step(payload, false)
    c:setEnabled(false)
    c:step(payload, false)
    assert(calls.clear == 1 and c.sessionToken == nil and c.phase == "paused")
end)
check("disconnect removes then revokes and forgets credentials", function()
    local c, _, calls, _, link = fixture()
    link()
    c:setEnabled(true)
    c:step(payload, false)
    c:disconnect()
    c:step(payload, false)
    assert(
        calls.clear == 1
            and calls.revoke == 1
            and c.accessToken == nil
            and c.refreshToken == nil
            and c.phase == "disconnected"
    )
end)
check("rate limiting is respected even after toggle", function()
    local c, api, calls, advance, link = fixture()
    link()
    c:setEnabled(true)
    function api:publish()
        calls.publish += 1
        return { ok = false, kind = "rate_limit", delay = 30 }
    end
    c:step(payload, false)
    advance(5)
    c:setEnabled(false)
    c:step(payload, false)
    assert(calls.publish == 1 and c.phase == "retrying")
end)
check("network recovery retries without duplicate accepted update", function()
    local c, api, calls, advance, link = fixture()
    link()
    c:setEnabled(true)
    local original = api.publish
    function api:publish()
        return { ok = false, kind = "network" }
    end
    c:step(payload, false)
    assert(c.phase == "retrying" and not c.lastSuccess)
    api.publish = original
    advance(3)
    c:step(payload, false)
    assert(c.phase == "sharing" and calls.publish == 1)
end)
check("cancelled in-flight OAuth result is revoked", function()
    local c, api, calls, advance = fixture()
    local original = api.pollLink
    function api:pollLink()
        c:disconnect()
        return original(self)
    end
    c:connect()
    c:step(payload, false)
    advance(5)
    c:step(payload, false)
    c:step(payload, false)
    assert(calls.revoke == 1 and c.accessToken == nil and calls.publish == 0)
end)
check("background pause clears then foreground can resume", function()
    local c, _, calls, advance, link = fixture()
    link()
    c:setEnabled(true)
    c:step(payload, false)
    advance(16)
    c:step(payload, true)
    assert(calls.clear == 1 and c.enabled)
    advance(2)
    c:step(payload, false)
    assert(calls.publish == 2)
end)
check("device polling slowdown and expiry", function()
    local c, api, calls, advance = fixture()
    function api:pollLink()
        calls.poll += 1
        return { ok = false, kind = "slow_down" }
    end
    c:connect()
    c:step(payload, false)
    advance(5)
    c:step(payload, false)
    advance(6)
    c:step(payload, false)
    assert(calls.poll == 1)
    advance(60)
    c:step(payload, false)
    assert(c.phase == "error" and c.deviceCode == nil)
end)
check("refresh replaces tokens without publishing while paused", function()
    local c, _, calls, advance, link = fixture()
    link()
    advance(3550)
    c:step(payload, false)
    assert(calls.refresh == 1 and c.accessToken == "refreshed" and calls.publish == 0)
end)
check("failed removal retains session for retry", function()
    local c, api, calls, advance, link = fixture()
    link()
    c:setEnabled(true)
    c:step(payload, false)
    local original = api.clear
    function api:clear()
        return { ok = false, kind = "network" }
    end
    c:setEnabled(false)
    c:step(payload, false)
    assert(c.sessionToken ~= nil and c.phase == "retrying")
    api.clear = original
    advance(3)
    c:step(payload, false)
    assert(c.sessionToken == nil and calls.clear == 1)
end)
check("API network error never exposes raw exception", function()
    local fake = {
        JSONEncode = function(_, b)
            return http:JSONEncode(b)
        end,
        RequestAsync = function()
            error("secret-token")
        end,
    }
    local r = Api.new(fake, "1"):publish("access-secret", nil, payload)
    assert(not r.ok and not http:JSONEncode(r):find("secret"))
end)
check("API rejects a foreign verification URL", function()
    local fake = {
        UrlEncode = function(_, v)
            return http:UrlEncode(v)
        end,
        JSONDecode = function(_, s)
            return http:JSONDecode(s)
        end,
        RequestAsync = function()
            return {
                Success = true,
                StatusCode = 200,
                Body = http:JSONEncode({
                    device_code = "d",
                    user_code = "u",
                    verification_uri = "https://evil.example/",
                    expires_in = 60,
                    interval = 5,
                }),
            }
        end,
    }
    assert(Api.new(fake, "1"):beginLink().kind == "invalid_response")
end)
check("privacy removes public state immediately before private replacement", function()
    local c, _, calls, advance, link = fixture()
    link()
    c:setEnabled(true)
    c:step(payload, false)
    c:hidePreviousActivity()
    c:step(payload, false)
    assert(calls.clear == 1 and c.sessionToken == nil)
    advance(2)
    c:step(payload, false)
    assert(calls.publish == 2 and c.sessionToken ~= nil)
end)
check("script classes select distinct artwork without exposing script metadata", function()
    for _, kind in ipairs({ "ServerScript", "LocalScript", "ModuleScript" }) do
        local c = table.clone(context)
        c.scripting = true
        c.scriptKind = kind
        c.scriptName = "SecretScript"
        local a = Activity.build(settings, c, "1")
        assert(
            a.assets.large_image == Modes[kind].asset
                and not http:JSONEncode(a):find("SecretScript")
        )
    end
end)
check("selection hints never override testing scripting or a manual choice", function()
    local s = table.clone(settings)
    s.smartSelection = true
    local c = table.clone(context)
    c.selectionMode = "Lighting"
    assert(Activity.resolve(s, c) == "Lighting")
    c.scripting = true
    assert(Activity.resolve(s, c) == "Scripting")
    c.testing = true
    assert(Activity.resolve(s, c) == "Testing")
    s.mode = "Audio"
    assert(Activity.resolve(s, c) == "Audio")
    s.mode = "Auto"
    s.smartSelection = false
    c.scripting = false
    c.testing = false
    assert(Activity.resolve(s, c) == "Building")
end)
check("every manual mode has distinctive image and bounded activity text", function()
    local seen = {}
    for _, mode in ipairs(Modes.Order) do
        if mode ~= "Auto" then
            local s = table.clone(settings)
            s.mode = mode
            local a = Activity.build(s, context, "1")
            assert(not seen[a.assets.large_image])
            seen[a.assets.large_image] = true
            assert(#a.state < 128 and a.assets.small_image == Modes.BrandAsset)
        end
    end
end)
check("focus countdown expires and does not trigger idle during focus", function()
    local s = Session.new(100)
    s:startFocus(25, 100)
    assert(not s:isIdle(5, 700))
    local c = table.clone(context)
    c.now = 700
    c.focusStarted = s.focusStarted
    c.focusEnds = s.focusEnds
    local a = Activity.build(settings, c, "1")
    assert(a.state == Modes.Focus.state and a.timestamps["end"] == 1600000)
    s:tick(1600, "Focus", true)
    assert(s.focusComplete and s.focusEnds == nil)
    assert(not s:isIdle(5, 1600))
end)
check("idle activity omits an ongoing work timer and pause resumes after input", function()
    local s = Session.new(100)
    assert(s:isIdle(5, 400))
    s:touch(401)
    assert(not s:isIdle(5, 402))
    assert(not s:isIdle(0, 9000))
    local c = table.clone(context)
    c.idle = true
    assert(
        Activity.build(settings, c, "1").timestamps == nil
            and Activity.resolve(settings, c) == "Idle"
    )
    local ctrl, _, calls, advance, link = fixture()
    link()
    ctrl:setEnabled(true)
    ctrl:step(payload, false)
    advance(16)
    ctrl:step(payload, "idle")
    assert(calls.clear == 1 and ctrl.detail:find("away"))
    advance(2)
    ctrl:step(payload, false)
    assert(calls.publish == 2)
end)
check("local session counts focused active time and caps sleep gaps", function()
    local s = Session.new(100)
    s:tick(101, "Building", true)
    s:tick(102, "Idle", false)
    s:tick(999, "Scripting", true)
    assert(
        s.activeSeconds == 6
            and s.totals.Building == 1
            and s.totals.Scripting == 5
            and s.totals.Idle == nil
    )
end)
local Panel = requireModule("Panel")
local function panelFixture(saved, restoredEnabled)
    local callbacks, writes = {}, {}
    local signal = {}
    function signal:Connect(callback)
        local connection = { connected = true }
        function connection:Disconnect()
            self.connected = false
        end
        table.insert(callbacks, { callback = callback, connection = connection })
        return connection
    end
    local widget = { Enabled = restoredEnabled }
    function widget:GetPropertyChangedSignal()
        return signal
    end
    local p = { values = saved or {}, writes = writes }
    function p:GetSetting(key)
        return self.values[key]
    end
    function p:SetSetting(key, value)
        self.values[key] = value
        table.insert(writes, key)
    end
    function p:CreateDockWidgetPluginGuiAsync(id, info)
        -- Studio's constructor accepts these flags but exposes no readable fields.
        local description = tostring(info)
        self.id = id
        self.overrideRestore = description:match("InitialEnabledShouldOverrideRestore:(%d)") == "1"
        local initialEnabled = description:match("InitialEnabled:(%d)") == "1"
        if restoredEnabled == nil or self.overrideRestore then
            widget.Enabled = initialEnabled
        end
        return widget
    end
    local function setEnabled(value)
        widget.Enabled = value
        for _, item in callbacks do
            if item.connection.connected then
                item.callback()
            end
        end
    end
    return p, widget, setEnabled
end
check("first play does not reopen an old automatically opened panel", function()
    local p, w = panelFixture({}, true)
    Panel.create(p, false, true)
    assert(not w.Enabled and p.values["StudioSignal.panelVisible.play"] == false)
end)
check("existing edit layout is respected on migration", function()
    local p, w = panelFixture({}, true)
    Panel.create(p, false, false)
    assert(w.Enabled and not p.overrideRestore)
    assert(p.id == "StudioSignal.Presence.v01")
end)
check("fresh installation stays closed until opened", function()
    local p, w = panelFixture()
    Panel.create(p, false, false)
    assert(w.Enabled == false)
end)
check("closed panel stays closed across reload even with stale native state", function()
    local p, w = panelFixture({ ["StudioSignal.panelVisible.edit"] = false }, true)
    Panel.create(p, false, false)
    assert(w.Enabled == false)
end)
check("manual play visibility persists without changing edit preference", function()
    local values = { ["StudioSignal.panelVisible.edit"] = false }
    local p, _, setEnabled = panelFixture(values, true)
    local _, connection = Panel.create(p, false, true)
    setEnabled(true)
    local reopened, w = panelFixture(values, false)
    Panel.create(reopened, false, true)
    assert(w.Enabled and values["StudioSignal.panelVisible.edit"] == false)
    connection:Disconnect()
    setEnabled(false)
    assert(values["StudioSignal.panelVisible.play"] == true)
end)
check("development preview never writes production panel settings", function()
    local p, w, setEnabled = panelFixture({}, false)
    function p:GetSetting()
        error("Preview must not read settings")
    end
    Panel.create(p, true, false)
    assert(w.Enabled and p.id == "StudioSignal.Presence.v01.Dev")
    setEnabled(false)
    assert(#p.writes == 0)
end)
local Profiles = requireModule("Profiles")
local Diagnostics = requireModule("Diagnostics")
local QRCode = requireModule("QRCode")
local function profileFixture(store)
    store = store or {}
    local n = 0
    local function read(key)
        return store[key]
    end
    local function write(key, value)
        store[key] = value
        return true
    end
    local function id()
        n += 1
        return "test-" .. n
    end
    return Profiles.new(read, write, id), store
end
check("custom profile text and icon build the reviewed payload", function()
    local s = Profiles.clean({
        private = false,
        detailsText = "  Designing a city  ",
        stateText = "Roads today",
        iconMode = "Terrain",
        mode = "Auto",
        showLink = true,
        gameUrl = "https://roblox.com/games/987/Public-Game",
    })
    local a = Activity.build(s, context, "1")
    assert(a.details == "Designing a city" and a.state == "Roads today")
    assert(
        a.assets.large_image == Modes.Terrain.asset
            and a.details_url == "https://www.roblox.com/games/987"
    )
end)
check(
    "private profiles suppress first line alias and link but keep explicit activity text",
    function()
        local s = Profiles.clean({
            detailsText = "Secret title",
            projectAlias = "Secret name",
            stateText = "Writing tools",
            gameUrl = "https://www.roblox.com/games/987",
            showLink = true,
        })
        local a = Activity.build(s, context, "1")
        local encoded = http:JSONEncode(a)
        assert(not encoded:find("Secret") and not encoded:find("/games/"))
        assert(a.state == "Writing tools")
    end
)
check("focus and away override custom icons and activity text", function()
    local s = Profiles.clean({ stateText = "Custom", iconMode = "Terrain", mode = "Building" })
    local c = table.clone(context)
    c.now = 100
    c.focusStarted = 90
    c.focusEnds = 200
    local a = Activity.build(s, c, "1")
    assert(a.assets.large_image == Modes.Focus.asset and a.state == Modes.Focus.state)
    c.focusEnds = nil
    c.idle = true
    a = Activity.build(s, c, "1")
    assert(
        a.assets.large_image == Modes.Idle.asset
            and a.state == Modes.Idle.state
            and not a.timestamps
    )
end)
check("profile normalization bounds UTF8 and omits credentials and unknown fields", function()
    local p = Profiles.clean({
        name = string.rep("ع", 60),
        detailsText = string.rep("ع", 120),
        token = "secret",
        enabled = true,
        mode = "bad",
        iconMode = "bad",
        showTimer = false,
    })
    assert(utf8.len(p.name) == 40 and utf8.len(p.detailsText) == 110)
    assert(
        not p.token
            and not p.enabled
            and p.mode == "Auto"
            and p.iconMode == "Auto"
            and not p.showTimer
    )
end)
check("profile game links reject external hosts and private server credentials", function()
    for _, url in
        {
            "http://www.roblox.com/games/1",
            "https://www.roblox.com.evil/games/1",
            "https://www.roblox.com/games/1?privateServerLinkCode=secret",
            "https://www.roblox.com/games/0",
            "https://www.roblox.com/games/1#secret",
        }
    do
        assert(not Activity.gameLink(url) and not Profiles.clean({ gameUrl = url }))
    end
end)
check(
    "profile library saves without mutating current activity and applies only appearance",
    function()
        local library = profileFixture()
        local active = Profiles.clean({ name = "Current", stateText = "Before" })
        active.pauseBackground = false
        active.enabled = false
        local draft = table.clone(active)
        draft.name = "Work"
        draft.stateText = "After"
        local p = assert(library:save(nil, draft))
        assert(active.stateText == "Before")
        Profiles.apply(active, p)
        assert(
            active.stateText == "After"
                and active.pauseBackground == false
                and active.enabled == false
        )
    end
)
check("library update and delete preserve independent profile identities", function()
    local lib = profileFixture()
    local a = assert(lib:save(nil, { name = "One" }))
    local b = assert(lib:save(nil, { name = "Two" }))
    assert(lib:save(a.id, { name = "Renamed" }))
    assert(#lib.items == 2 and lib:find(b.id).name == "Two")
    assert(lib:delete(a.id) and #lib.items == 1 and not lib:find(a.id))
    assert(not lib:save(a.id, { name = "Stale edit" }))
end)
check("library limit and empty names do not silently overwrite saved profiles", function()
    local lib = profileFixture()
    assert(not lib:save(nil, { name = "  " }))
    for i = 1, 20 do
        assert(lib:save(nil, { name = "Profile " .. i }))
    end
    assert(not lib:save(nil, { name = "Overflow" }) and #lib.items == 20)
    assert(lib:save(lib.items[1].id, { name = "Still editable" }))
end)
check("profile storage failures leave the previous data intact", function()
    local lib, store = profileFixture()
    local p = assert(lib:save(nil, { name = "Original" }))
    lib.write = function()
        return false
    end
    assert(not lib:save(p.id, { name = "Lost" }) and lib:find(p.id).name == "Original")
    assert(not lib:delete(p.id) and #store[Profiles.Key].items == 1)
end)
check("sequential writers refresh the library before saving", function()
    local first, store = profileFixture()
    local second = Profiles.new(function(k)
        return store[k]
    end, function(k, v)
        store[k] = v
        return true
    end, function()
        return "other-id"
    end)
    local a = assert(first:save(nil, { name = "First window" }))
    local b = assert(second:save(nil, { name = "Second window" }))
    first:refresh()
    assert(first:find(a.id) and first:find(b.id) and #first.items == 2)
end)
check("pins are scoped by published place and local files cannot be pinned", function()
    local lib = profileFixture()
    local a = assert(lib:save(nil, { name = "A" }))
    local b = assert(lib:save(nil, { name = "B" }))
    assert(lib:pin(123, a.id) and lib:pin(456, b.id))
    assert(lib:pinned(123).id == a.id and lib:pinned(456).id == b.id)
    assert(not lib:pin(0, a.id) and not lib:pinned(0))
    assert(lib:pin(123, nil) and not lib:pinned(123) and lib:pinned(456).id == b.id)
    lib:delete(b.id)
    assert(not lib:pinned(456))
end)
check("corrupted profile entries are ignored without loading private metadata", function()
    local lib = profileFixture({
        [Profiles.Key] = {
            schema = 1,
            items = {
                false,
                { id = "ok", name = "One" },
                { id = "ok", name = "Duplicate" },
                { id = "bad/key", name = "Wrong" },
                { id = "empty", name = "" },
                { id = "url", name = "Bad URL", gameUrl = "https://evil.example" },
            },
        },
    })
    assert(#lib.items == 1 and lib.items[1].name == "One")
end)
check("safe support report excludes all uncontrolled text and credentials", function()
    local report = Diagnostics.report({
        phase = "secret",
        detail = "SECRET_DETAIL",
        linked = true,
        enabled = true,
        userCode = "SECRET_CODE",
        verificationUrl = "SECRET_URL",
        token = "SECRET_TOKEN",
        lastOperation = "SECRET_OP",
        lastErrorKind = "SECRET_KIND",
        lastHttpStatus = "SECRET_HTTP",
        lastSuccess = "SECRET_TIME",
        retryAt = 0,
    }, 100, false)
    assert(
        not report:find("SECRET")
            and report:find("Phase: unknown")
            and report:find("Account linked: true")
    )
end)
check("connection diagnostics expose bounded status and retry guidance", function()
    local c, api, _, advance, link = fixture()
    link()
    c:setEnabled(true)
    function api:publish()
        return { ok = false, kind = "rate_limit", status = 429, delay = 30 }
    end
    c:step(payload, false)
    local state = c:snapshot()
    assert(
        state.lastOperation == "publish"
            and state.lastHttpStatus == 429
            and state.lastErrorKind == "rate_limit"
    )
    assert(Diagnostics.summary(state, 1005):find("30 seconds"))
    assert(Diagnostics.report(state, 1005, false):find("HTTP status: 429"))
end)
check("sign-in rate limits survive reconnect and cancel actions", function()
    local c, api, _, advance = fixture()
    local calls = 0
    function api:beginLink()
        calls += 1
        return { ok = false, kind = "rate_limit", status = 429, delay = 60 }
    end
    c:connect()
    c:step(payload, false)
    c:connect()
    c:step(payload, false)
    c:disconnect()
    c:step(payload, false)
    c:connect()
    c:step(payload, false)
    assert(calls == 1)
    advance(61)
    c:connect()
    c:step(payload, false)
    assert(calls == 2)
end)
check("expired and malformed sign-in responses have actionable diagnostic kinds", function()
    local c, api, _, advance = fixture()
    c:connect()
    c:step(payload, false)
    advance(61)
    c:step(payload, false)
    assert(c:snapshot().lastErrorKind == "expired_token")
    local other, otherApi, _, nextTime = fixture()
    function otherApi:pollLink()
        return { ok = true, data = {} }
    end
    other:connect()
    other:step(payload, false)
    nextTime(5)
    other:step(payload, false)
    assert(other:snapshot().lastErrorKind == "invalid_response" and not other.accessToken)
end)
check("QR encoder accepts byte capacity and rejects oversized input", function()
    assert(
        not QRCode.encode(123) and not QRCode.encode("") and not QRCode.encode(string.rep("a", 107))
    )
    local cells = QRCode.encode("https://discord.com/activate")
    assert(#cells == 37 and #cells[1] == 37 and cells[1][1] and not cells[8][1])
    assert(QRCode.encode(string.rep("a", 106)))
end)
check("profile changes do not accelerate sign-in polling", function()
    local c, _, calls, advance = fixture()
    c:connect()
    c:step(payload, false)
    advance(1)
    c:hidePreviousActivity()
    c:setEnabled(false)
    c:step(payload, false)
    assert(calls.poll == 0)
    advance(4)
    c:step(payload, false)
    assert(calls.poll == 1)
end)
check("transient sign-in failures retry after the provider delay", function()
    local c, api, _, advance = fixture()
    local original = api.beginLink
    local count = 0
    function api:beginLink()
        count += 1
        if count == 1 then
            return { ok = false, kind = "rate_limit", delay = 30, status = 429 }
        end
        return original(self)
    end
    c:connect()
    c:step(payload, false)
    advance(29)
    c:step(payload, false)
    assert(count == 1)
    advance(1)
    c:step(payload, false)
    assert(count == 2 and c.phase == "awaiting")
end)
check("QR verification link prefills only the official Discord short code", function()
    local expected = "https://discord.com/activate?user_code=ABCD-EFGH"
    assert(Api.verificationLink("https://discord.com/activate", "ABCD-EFGH", expected) == expected)
    assert(Api.verificationLink("https://discord.com/activate", "ABCD-EFGH") == expected)
    for _, complete in
        {
            "https://evil.example/activate",
            expected .. "&redirect_uri=https://evil.example",
            "https://discord.com/activate?user_code=DIFFERENT",
        }
    do
        assert(not Api.verificationLink("https://discord.com/activate", "ABCD-EFGH", complete))
    end
    for _, code in { "", "CODE&redirect=evil", string.rep("A", 33) } do
        assert(not Api.verificationLink("https://discord.com/activate", code))
    end
end)
check("device authorization preserves a validated complete verification URI", function()
    local api = Api.new({}, "1")
    function api:request()
        return {
            ok = true,
            data = {
                device_code = "device-secret",
                user_code = "TEST-CODE",
                verification_uri = "https://discord.com/activate",
                verification_uri_complete = "https://discord.com/activate?user_code=TEST-CODE",
                expires_in = 60,
                interval = 5,
            },
        }
    end
    assert(
        api:beginLink().data.verification_uri_complete
            == "https://discord.com/activate?user_code=TEST-CODE"
    )
end)
check("prefilled verification links clear on cancellation expiry and successful sign-in", function()
    for _, ending in { "cancel", "expire", "success" } do
        local c, api, _, advance = fixture()
        local original = api.beginLink
        function api:beginLink()
            local r = original(self)
            r.data.verification_uri_complete = "https://discord.com/activate?user_code=ABCD-EFGH"
            return r
        end
        c:connect()
        c:step(payload, false)
        assert(c:snapshot().verificationComplete)
        assert(not Diagnostics.report(c:snapshot(), 1000, false):find("ABCD"))
        if ending == "cancel" then
            c:disconnect()
        else
            advance(ending == "expire" and 61 or 5)
            c:step(payload, false)
        end
        assert(not c:snapshot().verificationComplete and not c:snapshot().userCode)
    end
end)
return { passed = #passed, tests = passed }
