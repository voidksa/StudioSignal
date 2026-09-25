local Activity=requireModule("Activity")
local Controller=requireModule("Controller")
local Api=requireModule("Api")
local Modes=requireModule("Modes")
local Session=requireModule("Session")
local http=game:GetService("HttpService")
local passed={}
local function check(name,fn)
    local ok,err=pcall(fn)
    if not ok then error(name..": "..tostring(err)) end
    table.insert(passed,name)
end
local settings={private=true,showTimer=true,showLink=true,mode="Auto",projectAlias="Secret alias"}
local context={projectName="Secret Project",placeId=123456,scripting=false,testing=false,startedAt=1700000000}
local payload=Activity.build(settings,context,"123456789012345678")
check("private payload omits title alias id and link",function()
    local s=http:JSONEncode(payload)
    assert(not s:find("Secret") and not s:find("/games/") and payload.details_url==nil)
end)
check("private payload has no arbitrary metadata",function()
    assert(payload.source==nil and payload.script==nil and payload.buttons==nil)
    assert(payload.assets.large_image==Modes.Building.asset and payload.assets.large_text=="Building")
end)
check("public project link only when published and explicitly enabled",function()
    local s=table.clone(settings);s.private=false
    assert(Activity.build(s,context,"1").details_url=="https://www.roblox.com/games/123456")
    s.showLink=false;assert(Activity.build(s,context,"1").details_url==nil)
    s.showLink=true;local c=table.clone(context);c.placeId=0
    assert(Activity.build(s,c,"1").details_url==nil)
end)
check("automatic activity priority",function()
    local c=table.clone(context);c.scripting=true
    assert(Activity.build(settings,c,"1").state=="Writing Luau")
    c.testing=true;assert(Activity.build(settings,c,"1").state=="Playtesting in Roblox Studio")
end)
check("manual mode and timer omission",function()
    local s=table.clone(settings);s.mode="Terrain";s.showTimer=false
    local a=Activity.build(s,context,"1")
    assert(a.state=="Creating terrain" and a.timestamps==nil)
end)
check("UTF8 truncation and control cleanup",function()
    local s=Activity.text(string.rep("ع",100),90)
    assert(utf8.len(s)==90)
    assert(Activity.text("  Hello\nWorld\t ",90)=="Hello World")
end)
check("respects provider retry delay",function() assert(Activity.retryDelay(1,135)==135) end)

local function fixture()
    local now=1000
    local calls={publish=0,clear=0,revoke=0,poll=0,refresh=0}
    local api={}
    function api:beginLink() return {ok=true,data={device_code="device-secret",user_code="ABCD-EFGH",verification_uri="https://discord.com/activate",expires_in=60,interval=5}} end
    function api:pollLink() calls.poll+=1;return {ok=true,data={access_token="access-secret",refresh_token="refresh-secret",expires_in=3600}} end
    function api:publish(access,session,a) calls.publish+=1;return {ok=true,data={token="session-"..calls.publish}} end
    function api:clear() calls.clear+=1;return {ok=true} end
    function api:revoke() calls.revoke+=1;return {ok=true} end
    function api:refresh() calls.refresh+=1;return {ok=true,data={access_token="refreshed",refresh_token="refresh-new",expires_in=3600}} end
    local c=Controller.new(api,function() return now end,function(a)return http:JSONEncode(a)end)
    local function advance(n) now+=n end
    local function link() c:connect();c:step(payload,false);advance(5);c:step(payload,false) end
    return c,api,calls,advance,link
end
check("linking does not publish automatically",function()
    local c,_,calls,_,link=fixture();link()
    assert(c.phase=="paused" and not c.enabled and calls.publish==0)
    local s=http:JSONEncode(c:snapshot());assert(not s:find("secret"))
end)
check("publishing, heartbeat, session token rotation",function()
    local c,_,calls,advance,link=fixture();link();c:setEnabled(true);c:step(payload,false)
    assert(c.phase=="sharing" and c.sessionToken=="session-1")
    advance(16);c:step(payload,false);assert(calls.publish==1)
    advance(121);c:step(payload,false);assert(calls.publish==2 and c.sessionToken=="session-2")
end)
check("pause removes previous activity",function()
    local c,_,calls,_,link=fixture();link();c:setEnabled(true);c:step(payload,false)
    c:setEnabled(false);c:step(payload,false)
    assert(calls.clear==1 and c.sessionToken==nil and c.phase=="paused")
end)
check("disconnect removes then revokes and forgets credentials",function()
    local c,_,calls,_,link=fixture();link();c:setEnabled(true);c:step(payload,false)
    c:disconnect();c:step(payload,false)
    assert(calls.clear==1 and calls.revoke==1 and c.accessToken==nil and c.refreshToken==nil and c.phase=="disconnected")
end)
check("rate limiting is respected even after toggle",function()
    local c,api,calls,advance,link=fixture();link();c:setEnabled(true)
    function api:publish() calls.publish+=1;return {ok=false,kind="rate_limit",delay=30} end
    c:step(payload,false);advance(5);c:setEnabled(false);c:step(payload,false)
    assert(calls.publish==1 and c.phase=="retrying")
end)
check("network recovery retries without duplicate accepted update",function()
    local c,api,calls,advance,link=fixture();link();c:setEnabled(true)
    local original=api.publish
    function api:publish() return {ok=false,kind="network"} end
    c:step(payload,false);assert(c.phase=="retrying" and not c.lastSuccess)
    api.publish=original;advance(3);c:step(payload,false);assert(c.phase=="sharing" and calls.publish==1)
end)
check("cancelled in-flight OAuth result is revoked",function()
    local c,api,calls,advance=fixture()
    local original=api.pollLink
    function api:pollLink() c:disconnect();return original(self) end
    c:connect();c:step(payload,false);advance(5);c:step(payload,false);c:step(payload,false)
    assert(calls.revoke==1 and c.accessToken==nil and calls.publish==0)
end)
check("background pause clears then foreground can resume",function()
    local c,_,calls,advance,link=fixture();link();c:setEnabled(true);c:step(payload,false)
    advance(16);c:step(payload,true);assert(calls.clear==1 and c.enabled)
    advance(2);c:step(payload,false);assert(calls.publish==2)
end)
check("device polling slowdown and expiry",function()
    local c,api,calls,advance=fixture()
    function api:pollLink() calls.poll+=1;return {ok=false,kind="slow_down"} end
    c:connect();c:step(payload,false);advance(5);c:step(payload,false)
    advance(6);c:step(payload,false);assert(calls.poll==1)
    advance(60);c:step(payload,false);assert(c.phase=="error" and c.deviceCode==nil)
end)
check("refresh replaces tokens without publishing while paused",function()
    local c,_,calls,advance,link=fixture();link();advance(3550);c:step(payload,false)
    assert(calls.refresh==1 and c.accessToken=="refreshed" and calls.publish==0)
end)
check("failed removal retains session for retry",function()
    local c,api,calls,advance,link=fixture();link();c:setEnabled(true);c:step(payload,false)
    local original=api.clear
    function api:clear() return {ok=false,kind="network"} end
    c:setEnabled(false);c:step(payload,false)
    assert(c.sessionToken~=nil and c.phase=="retrying")
    api.clear=original;advance(3);c:step(payload,false)
    assert(c.sessionToken==nil and calls.clear==1)
end)
check("API network error never exposes raw exception",function()
    local fake={JSONEncode=function(_,b)return http:JSONEncode(b)end,RequestAsync=function()error("secret-token")end}
    local r=Api.new(fake,"1"):publish("access-secret",nil,payload)
    assert(not r.ok and not http:JSONEncode(r):find("secret"))
end)
check("API rejects a foreign verification URL",function()
    local fake={UrlEncode=function(_,v)return http:UrlEncode(v)end,JSONDecode=function(_,s)return http:JSONDecode(s)end,
        RequestAsync=function()return {Success=true,StatusCode=200,Body=http:JSONEncode({device_code="d",user_code="u",verification_uri="https://evil.example/",expires_in=60,interval=5})}end}
    assert(Api.new(fake,"1"):beginLink().kind=="invalid_response")
end)
check("privacy removes public state immediately before private replacement",function()
    local c,_,calls,advance,link=fixture();link();c:setEnabled(true);c:step(payload,false)
    c:hidePreviousActivity();c:step(payload,false)
    assert(calls.clear==1 and c.sessionToken==nil)
    advance(2);c:step(payload,false)
    assert(calls.publish==2 and c.sessionToken~=nil)
end)
check("script classes select distinct artwork without exposing script metadata",function()
    for _,kind in ipairs({"ServerScript","LocalScript","ModuleScript"}) do
        local c=table.clone(context);c.scripting=true;c.scriptKind=kind;c.scriptName="SecretScript"
        local a=Activity.build(settings,c,"1")
        assert(a.assets.large_image==Modes[kind].asset and not http:JSONEncode(a):find("SecretScript"))
    end
end)
check("selection hints never override testing scripting or a manual choice",function()
    local s=table.clone(settings);s.smartSelection=true
    local c=table.clone(context);c.selectionMode="Lighting"
    assert(Activity.resolve(s,c)=="Lighting")
    c.scripting=true;assert(Activity.resolve(s,c)=="Scripting")
    c.testing=true;assert(Activity.resolve(s,c)=="Testing")
    s.mode="Audio";assert(Activity.resolve(s,c)=="Audio")
    s.mode="Auto";s.smartSelection=false;c.scripting=false;c.testing=false
    assert(Activity.resolve(s,c)=="Building")
end)
check("every manual mode has distinctive image and bounded activity text",function()
    local seen={}
    for _,mode in ipairs(Modes.Order) do if mode~="Auto" then
        local s=table.clone(settings);s.mode=mode
        local a=Activity.build(s,context,"1")
        assert(not seen[a.assets.large_image]);seen[a.assets.large_image]=true
        assert(#a.state<128 and a.assets.small_image==Modes.BrandAsset)
    end end
end)
check("focus countdown expires and does not trigger idle during focus",function()
    local s=Session.new(100);s:startFocus(25,100)
    assert(not s:isIdle(5,700))
    local c=table.clone(context);c.now=700;c.focusStarted=s.focusStarted;c.focusEnds=s.focusEnds
    local a=Activity.build(settings,c,"1")
    assert(a.state==Modes.Focus.state and a.timestamps["end"]==1600000)
    s:tick(1600,"Focus",true);assert(s.focusComplete and s.focusEnds==nil)
    assert(not s:isIdle(5,1600))
end)
check("idle activity omits an ongoing work timer and pause resumes after input",function()
    local s=Session.new(100);assert(s:isIdle(5,400));s:touch(401);assert(not s:isIdle(5,402))
    assert(not s:isIdle(0,9000))
    local c=table.clone(context);c.idle=true
    assert(Activity.build(settings,c,"1").timestamps==nil and Activity.resolve(settings,c)=="Idle")
    local ctrl,_,calls,advance,link=fixture();link();ctrl:setEnabled(true);ctrl:step(payload,false)
    advance(16);ctrl:step(payload,"idle");assert(calls.clear==1 and ctrl.detail:find("away"))
    advance(2);ctrl:step(payload,false);assert(calls.publish==2)
end)
check("local session counts focused active time and caps sleep gaps",function()
    local s=Session.new(100);s:tick(101,"Building",true);s:tick(102,"Idle",false);s:tick(999,"Scripting",true)
    assert(s.activeSeconds==6 and s.totals.Building==1 and s.totals.Scripting==5 and s.totals.Idle==nil)
end)
return {passed=#passed,tests=passed}
