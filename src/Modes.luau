local Modes = {}
local assetIds = {
    animation = "1553054056849874965",
    audio = "1553054057130631332",
    brand = "1553054262035091556",
    building = "1553053132781789194",
    client = "1553053132806815845",
    debugging = "1553054261800214658",
    focus = "1553054262093680681",
    idle = "1553054261796012134",
    lighting = "1553054057508380733",
    modeling = "1553054057151729664",
    module = "1553053515478474834",
    scripting = "1553053132718608446",
    server = "1553053132735516732",
    terrain = "1553053516249960469",
    testing = "1553053515965005864",
    ui = "1553053515901968496",
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
