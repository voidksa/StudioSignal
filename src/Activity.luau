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
