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
