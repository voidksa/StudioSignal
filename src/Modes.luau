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
