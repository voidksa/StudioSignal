local Activity = require(script.Parent.Activity)
local Modes = require(script.Parent.Modes)
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
