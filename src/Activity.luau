-- Public activity is constructed here. Never pass source, paths or selection data.
local Activity = {}
local Modes = require(script.Parent.Modes)
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
