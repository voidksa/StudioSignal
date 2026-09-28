local Config = require(script.Parent.Config)
local Modes = require(script.Parent.Modes)
local Diagnostics = require(script.Parent.Diagnostics)
local ProfileEditor = require(script.Parent.ProfileEditor)
local QRCode = require(script.Parent.QRCode)
local Api = require(script.Parent.Api)
local ActionIcons = require(script.Parent.ActionIcons)
local TweenService = game:GetService("TweenService")
local UI = {}
UI.__index = UI
local C = {
    bg = Color3.fromRGB(24, 25, 23),
    panel = Color3.fromRGB(34, 35, 32),
    border = Color3.fromRGB(63, 64, 57),
    text = Color3.fromRGB(235, 230, 219),
    muted = Color3.fromRGB(171, 171, 157),
    accent = Color3.fromRGB(214, 166, 101),
    green = Color3.fromRGB(170, 193, 149),
    input = Color3.fromRGB(45, 46, 41),
}

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end
local function corner(obj, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, obj)
end
local function padding(obj, n)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, n),
        PaddingRight = UDim.new(0, n),
        PaddingTop = UDim.new(0, n),
        PaddingBottom = UDim.new(0, n),
    }, obj)
end
local function layout(obj, gap)
    make(
        "UIListLayout",
        { Padding = UDim.new(0, gap or 10), SortOrder = Enum.SortOrder.LayoutOrder },
        obj
    )
end
local function label(parent, name, text, size, color)
    return make("TextLabel", {
        Name = name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = text,
        TextSize = size or 14,
        Font = Enum.Font.BuilderSans,
        TextColor3 = color or C.text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, parent)
end
local function button(parent, name, text, primary, callback, iconKey)
    local b = make("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 38),
        Text = text,
        TextSize = 14,
        Font = Enum.Font.BuilderSansBold,
        BackgroundColor3 = primary and C.accent or C.input,
        BorderSizePixel = 0,
        TextColor3 = primary and C.bg or C.text,
        AutoButtonColor = true,
        TextWrapped = true,
    }, parent)
    corner(b, 10)
    b.AutoButtonColor = false
    b:SetAttribute("BaseColor", b.BackgroundColor3)
    local hoverTween, hovering
    local function refreshColor()
        if hoverTween then
            hoverTween:Cancel()
        end
        local base = b:GetAttribute("BaseColor")
        hoverTween = TweenService:Create(b, TweenInfo.new(0.14), {
            BackgroundColor3 = hovering and base:Lerp(C.text, 0.07) or base,
        })
        hoverTween:Play()
    end
    b.MouseEnter:Connect(function()
        hovering = true
        refreshColor()
    end)
    b.MouseLeave:Connect(function()
        hovering = false
        refreshColor()
    end)
    b:GetAttributeChangedSignal("BaseColor"):Connect(refreshColor)
    local actionKey = iconKey ~= false and (iconKey or ActionIcons.forButton(name))
    if actionKey then
        local compact = parent.Name == "FocusButtons"
        local glyph =
            ActionIcons.draw(b, "ActionIcon", actionKey, b.TextColor3, compact and 16 or 20)
        glyph.AnchorPoint = Vector2.new(0, 0.5)
        glyph.Position = UDim2.new(0, compact and 7 or 12, 0.5, 0)
        local inset = make("UIPadding", {
            PaddingLeft = UDim.new(0, compact and 29 or 42),
            PaddingRight = UDim.new(0, compact and 4 or 12),
        }, b)
        -- Padding would also offset child icons; anchor the glyph outside it.
        glyph.Position = UDim2.new(0, (compact and 7 or 12) - inset.PaddingLeft.Offset, 0.5, 0)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextSize = compact and 12 or 13
        b:GetPropertyChangedSignal("TextColor3"):Connect(function()
            ActionIcons.tint(glyph, b.TextColor3)
            local tabLabel = b:FindFirstChild("TabLabel")
            if tabLabel then
                tabLabel.TextColor3 = b.TextColor3
            end
        end)
    end
    b.Activated:Connect(callback)
    return b
end
local function box(parent, name, placeholder, value, readOnly)
    local b = make("TextBox", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = C.input,
        BorderSizePixel = 0,
        Text = value or "",
        PlaceholderText = placeholder,
        PlaceholderColor3 = C.muted,
        ClearTextOnFocus = false,
        TextSize = 14,
        TextColor3 = C.text,
        Font = Enum.Font.BuilderSans,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
    corner(b, 8)
    padding(b, 10)
    if readOnly then
        b.TextEditable = false
        return b
    end
    local focusStroke = make("UIStroke", {
        Color = C.accent,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, b)
    local focusTween
    local function highlight(transparency)
        if focusTween then
            focusTween:Cancel()
        end
        focusTween =
            TweenService:Create(focusStroke, TweenInfo.new(0.12), { Transparency = transparency })
        focusTween:Play()
    end
    b.Focused:Connect(function()
        highlight(0.15)
    end)
    b.FocusLost:Connect(function()
        highlight(1)
    end)
    return b
end
local function card(parent, name, order)
    local f = make("Frame", {
        Name = name,
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, parent)
    corner(f, 12)
    padding(f, 16)
    layout(f, 12)
    return f
end

local function setIcon(image, mode)
    local i = (Modes[mode] or Modes.Auto).index
    image.Image = Modes.Atlas
    image.ImageRectOffset = Vector2.new(i % 4 * 256, math.floor(i / 4) * 256)
    image.ImageRectSize = Vector2.new(256, 256)
end
local function icon(parent, name, mode, size)
    local image = make(
        "ImageLabel",
        { Name = name, Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 },
        parent
    )
    setIcon(image, mode)
    return image
end

function UI.new(widget, settings, callbacks)
    local self = setmetatable({ widget = widget, tab = "Presence", callbacks = callbacks }, UI)
    local root = make("Frame", {
        Name = "StudioSignalUI",
        Visible = false,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
    }, widget)
    local header = make(
        "Frame",
        { Name = "Header", Size = UDim2.new(1, 0, 0, 77), BackgroundTransparency = 1 },
        root
    )
    local mark = icon(header, "SignalMark", "Auto", 40)
    mark.Position = UDim2.fromOffset(18, 16)
    local title = label(header, "Title", "StudioSignal", 23)
    title.Position = UDim2.fromOffset(66, 16)
    title.Size = UDim2.new(1, -152, 0, 28)
    title.Font = Enum.Font.BuilderSansBold
    local version = make("TextLabel", {
        Name = "VersionBadge",
        Text = Config.Version,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 13,
        TextColor3 = C.accent,
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -68, 0, 20),
        Size = UDim2.fromOffset(50, 24),
    }, header)
    corner(version, 7)
    local sub = label(header, "Subtitle", "Discord Presence", 12, C.muted)
    sub.Position = UDim2.fromOffset(67, 46)
    sub.Size = UDim2.new(1, -84, 0, 16)
    local tabs = make("Frame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(18, 77),
        Size = UDim2.new(1, -36, 0, 50),
        BackgroundTransparency = 1,
    }, root)
    local pages = make("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(0, 139),
        Size = UDim2.new(1, 0, 1, -167),
        BackgroundTransparency = 1,
    }, root)
    local footer = label(root, "Footer", Config.Version .. "  /  " .. Config.Copyright, 10, C.muted)
    footer.Position = UDim2.new(0, 18, 1, -22)
    footer.Size = UDim2.new(1, -36, 0, 18)
    self.pages = {}
    self.tabs = {}
    for i, name in ipairs({ "Presence", "Profiles", "Settings", "More tools" }) do
        local b = button(tabs, name, name == "More tools" and "More" or name, false, function()
            self:selectTab(name)
        end)
        b.Position = UDim2.new((i - 1) / 4, 2, 0, 0)
        b.Size = UDim2.new(1 / 4, -4, 1, 0)
        b.TextSize = 12
        b.Text = ""
        local inset = b:FindFirstChildWhichIsA("UIPadding")
        if inset then
            inset:Destroy()
        end
        b.ActionIcon.AnchorPoint = Vector2.new(0.5, 0)
        b.ActionIcon.Position = UDim2.new(0.5, 0, 0, 5)
        local tabLabel = label(b, "TabLabel", name == "More tools" and "More" or name, 11)
        tabLabel.Position = UDim2.fromOffset(0, 29)
        tabLabel.Size = UDim2.new(1, 0, 0, 16)
        tabLabel.TextXAlignment = Enum.TextXAlignment.Center
        tabLabel.Font = Enum.Font.BuilderSansBold
        make("Frame", {
            Name = "SelectedIndicator",
            Size = UDim2.new(1, -24, 0, 2),
            Position = UDim2.new(0, 12, 1, -2),
            BackgroundColor3 = C.accent,
            BorderSizePixel = 0,
        }, b)
        self.tabs[name] = b
        local p = make("ScrollingFrame", {
            Name = name,
            Visible = false,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = C.border,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, pages)
        padding(p, 18)
        layout(p, 14)
        self.pages[name] = p
    end
    local presence = self.pages.Presence
    self.profileEditor = ProfileEditor.new(self.pages.Profiles, callbacks, {
        make = make,
        label = label,
        button = button,
        box = box,
        card = card,
        layout = layout,
        icon = icon,
        setIcon = setIcon,
        setAction = function(button, key)
            ActionIcons.set(button.ActionIcon, key)
        end,
        colors = C,
        pick = function(selected, onSelect, iconsOnly)
            self:showModes(selected, onSelect, iconsOnly)
        end,
    })
    local state = card(presence, "Connection", 2)
    self.connectionCard = state
    self.status = label(state, "Status", "NOT CONNECTED", 12, C.muted)
    self.status.Font = Enum.Font.BuilderSansBold
    self.detail = label(state, "Detail", "Connect to share your Studio activity.", 13, C.muted)
    self.permissionNotice = label(
        state,
        "PermissionNotice",
        "Discord also grants access to view/manage friends and blocked users, and send invites. StudioSignal uses only sign-in and activity updates.",
        13,
        C.muted
    )
    self.connect = button(state, "Connect", "Connect Discord", true, callbacks.connect)
    self.share = button(state, "Share", "Start sharing", true, callbacks.toggleSharing)
    self.share.Visible = false
    self.disconnect = button(state, "Disconnect", "Disconnect account", false, callbacks.disconnect)
    self.disconnect.Visible = false
    self.codePanel = make("Frame", {
        Name = "SignIn",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
    }, state)
    layout(self.codePanel, 8)
    label(self.codePanel, "Hint", "1. Scan with your phone, or copy the link below.", 13, C.muted)
    self.qr = make(
        "Frame",
        { Name = "SignInQR", Size = UDim2.fromOffset(225, 225), BorderSizePixel = 0 },
        self.codePanel
    )
    label(
        self.codePanel,
        "QRHint",
        "Scan to open Discord with your code filled in. Review and approve there.",
        12,
        C.muted
    )
    self.linkBox = box(self.codePanel, "VerificationLink", "", "")
    self.linkBox.TextEditable = false
    label(self.codePanel, "CodeHint", "Your code (for manual entry if needed):", 13, C.muted)
    self.codeBox = box(self.codePanel, "UserCode", "", "")
    self.codeBox.TextEditable = false
    self.codeBox.Font = Enum.Font.BuilderSansBold
    self.codeExpiry = label(self.codePanel, "CodeExpiry", "", 12, C.accent)
    button(self.codePanel, "CancelLink", "Cancel sign-in", false, callbacks.disconnect)
    local preview = card(presence, "Preview", 1)
    label(preview, "PreviewHeading", "Activity preview", 16, C.text).Font =
        Enum.Font.BuilderSansBold
    local hero = make("Frame", {
        Name = "ActivityHero",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, preview)
    self.previewIcon = icon(hero, "ActivityIcon", "Building", 64)
    local meta = make("Frame", {
        Name = "ActivityText",
        Position = UDim2.fromOffset(78, 0),
        Size = UDim2.new(1, -78, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, hero)
    layout(meta, 6)
    self.previewTitle = label(meta, "ApplicationName", "StudioSignal", 17)
    self.previewTitle.Font = Enum.Font.BuilderSansBold
    self.previewDetails = label(meta, "Project", "Working on a private project", 13)
    self.previewState = label(meta, "WorkState", "Building in Roblox Studio", 13, C.muted)
    self.previewTime = label(meta, "Elapsed", "00:00 elapsed", 12, C.accent)
    self.previewLink = label(preview, "PlaceLink", "Project link included", 12, C.accent)
    make("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, preview)
    local activity = preview
    self.mode = button(activity, "Mode", "", false, function()
        self:showModes(settings.mode)
    end, false)
    self.mode.Size = UDim2.new(1, 0, 0, 62)
    self.modeIcon = icon(self.mode, "ModeIcon", "Building", 38)
    self.modeIcon.Position = UDim2.fromOffset(10, 12)
    self.modeLabel = label(self.mode, "ModeLabel", "Automatic", 14)
    self.modeLabel.Font = Enum.Font.BuilderSansBold
    self.modeLabel.Position = UDim2.fromOffset(60, 11)
    self.modeLabel.Size = UDim2.new(1, -88, 0, 20)
    self.modeHint = label(self.mode, "ModeHint", "Now: Building", 12, C.muted)
    self.modeHint.Position = UDim2.fromOffset(60, 34)
    self.modeHint.Size = UDim2.new(1, -88, 0, 18)
    for _, text in { self.modeLabel, self.modeHint } do
        text.AutomaticSize = Enum.AutomaticSize.None
        text.TextWrapped = false
        text.TextTruncate = Enum.TextTruncate.AtEnd
    end
    local arrow = label(self.mode, "Arrow", ">", 18, C.muted)
    arrow.Position = UDim2.new(1, -24, 0, 19)
    arrow.Size = UDim2.fromOffset(14, 24)
    self.private =
        button(activity, "Private", "Private project: ON", false, callbacks.togglePrivate)
    button(preview, "Customize", "Edit appearance", false, function()
        self.profileEditor:newDraft()
        self:selectTab("Profiles")
    end)
    label(preview, "PreviewNote", "Preview only. Discord controls the final layout.", 11, C.muted)
    local session = card(presence, "Session", 4)
    label(session, "SessionHeading", "Focus & session", 16)
    self.sessionText = label(session, "SessionText", "0 min active this session", 13, C.muted)
    self.focusText = label(
        session,
        "FocusText",
        "Choose a focus timer. It works without connecting Discord.",
        12,
        C.muted
    )
    local focusRow = make(
        "Frame",
        { Name = "FocusButtons", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 },
        session
    )
    for i, minutes in ipairs({ 25, 50 }) do
        local b = button(focusRow, "Focus" .. minutes, minutes .. " min", false, function()
            callbacks.focus(minutes)
        end)
        b.Position = UDim2.new((i - 1) / 3, 0, 0, 0)
        b.Size = UDim2.new(1 / 3, -5, 1, 0)
    end
    local stop = button(focusRow, "StopFocus", "End focus", false, callbacks.stopFocus)
    stop.Position = UDim2.new(2 / 3, 0, 0, 0)
    stop.Size = UDim2.new(1 / 3, 0, 1, 0)
    local prefs = self.pages.Settings
    local project = card(prefs, "ProjectPreferences", 1)
    label(project, "PreferencesTitle", "Project appearance", 17)
    label(project, "AliasLabel", "Display name", 12, C.muted)
    self.alias = box(project, "ProjectAlias", "Use the project name", settings.projectAlias)
    self.alias.FocusLost:Connect(function()
        callbacks.alias(self.alias.Text)
    end)
    label(
        project,
        "PrivacyHint",
        "Private mode hides the project name and link. Script names and source are never included.",
        12,
        C.muted
    )
    self.timer = button(project, "Timer", "Session timer: ON", false, callbacks.toggleTimer)
    self.placeLink = button(project, "Link", "Project link: OFF", false, callbacks.toggleLink)
    self.background =
        button(project, "Background", "Pause in background: ON", false, callbacks.toggleBackground)
    self.smartSelection = button(
        project,
        "SmartSelection",
        "Selection hints: ON",
        false,
        callbacks.toggleSmartSelection
    )
    label(
        project,
        "SelectionHint",
        "Recent selection can suggest UI, terrain, lighting, audio, animation or modeling for 45 seconds. These are hints, not detection of another plugin's tools.",
        12,
        C.muted
    )
    self.idle = button(project, "IdleMinutes", "Idle after: 5 min", false, callbacks.cycleIdle)
    self.idleBehavior = button(
        project,
        "IdleBehavior",
        "When idle: pause sharing",
        false,
        callbacks.toggleIdleBehavior
    )
    local account = card(prefs, "AccountInfo", 2)
    label(account, "AccountHeading", "Your account, your control", 17)
    label(
        account,
        "ScopeNotice",
        "Discord grants activity, friends, blocked-user and game-invite permissions together. StudioSignal only uses sign-in and activity updates. It does not read or manage your friends or blocked users, or send invitations.",
        13,
        C.muted
    )
    label(
        account,
        "RevokeNotice",
        "Disconnect account removes the activity and revokes this app's authorization. You can also revoke access in Discord Settings > Authorized Apps.",
        13,
        C.muted
    )
    label(
        account,
        "StorageNotice",
        "Credentials stay in memory. Reconnect after restarting Studio. No telemetry or project source is collected.",
        13,
        C.muted
    )
    label(
        account,
        "CloseNotice",
        "Pause before closing to confirm removal. If Studio crashes or goes offline, Discord may retain the last activity until its session expires.",
        12,
        C.muted
    )
    local diagnostics = card(prefs, "Diagnostics", 3)
    label(diagnostics, "DiagnosticsTitle", "Connection details", 15)
    self.diagnostics = label(diagnostics, "DiagnosticsText", "No request sent yet.", 12, C.muted)
    button(diagnostics, "SupportReport", "View safe support report", false, function()
        self:showReport(callbacks.supportReport())
    end)
    self.setup = card(prefs, "DeveloperSetup", 4)
    self.setup.Visible = Config.ApplicationId == ""
    label(self.setup, "SetupTitle", "Preview setup", 15)
    label(
        self.setup,
        "SetupHint",
        "Application ID is public. Never enter a bot token, user token or client secret.",
        12,
        C.muted
    )
    self.appId = box(self.setup, "ApplicationId", "Discord Application ID", Config.ApplicationId)
    button(self.setup, "SaveApplication", "Use application ID", false, function()
        callbacks.appId(self.appId.Text)
    end)
    local more = self.pages["More tools"]
    local updates = card(more, "WhatsNew", -1)
    label(updates, "UpdatesTitle", "What's new", 20)
    label(updates, "UpdatesVersion", Config.Version .. " / Custom profiles", 13, C.accent)
    label(
        updates,
        "UpdatesText",
        "Save custom text, icons, privacy and public game links in Profiles. Preview before applying, or pin a profile to a published place.\n\nScan the sign-in QR code with your phone. Connection guidance and a safe support report are available in Settings.\n\nIncludes the v1.0.1 panel fixes for Edit and Play.",
        13,
        C.muted
    )
    local support = card(more, "Support", 0)
    label(support, "SupportTitle", "Need a hand?", 17)
    label(
        support,
        "SupportHint",
        "Get StudioSignal help in VOID HUB. Joining is optional.",
        13,
        C.muted
    )
    button(support, "DiscordSupport", "Support & Discord", true, function()
        self:showLink("VOID HUB | StudioSignal support", Config.SupportUrl)
    end)
    local contour = card(more, "ContourTerrain", 1)
    label(contour, "Byline", "MORE FROM THE CREATOR", 11, C.muted)
    local thumb = make("ImageLabel", {
        Name = "ContourImage",
        Size = UDim2.new(1, 0, 0, 142),
        BackgroundColor3 = C.input,
        BorderSizePixel = 0,
        Image = "rbxthumb://type=Asset&id=94088881259293&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit,
    }, contour)
    corner(thumb, 8)
    label(contour, "ProductName", "Contour Terrain", 24).Font = Enum.Font.BuilderSansBold
    label(
        contour,
        "ProductDescription",
        "Shape terrain, build roads and bring meshes into your Roblox world.",
        14,
        C.muted
    )
    button(contour, "ContourLink", "View Contour Terrain", true, function()
        self:showLink("Contour Terrain", Config.ContourUrl)
    end)
    label(
        contour,
        "Optional",
        "Optional. StudioSignal is free and does not require another plugin.",
        12,
        C.muted
    )
    local about = card(more, "About", 2)
    label(about, "AboutTitle", "Made by VOIDKSA", 16)
    label(about, "Copyright", Config.Copyright .. ". StudioSignal is free to use.", 12, C.muted)
    label(
        about,
        "AboutText",
        "Your Studio activity, live on Discord. No ads are inserted into your activity.",
        13,
        C.muted
    )
    label(
        about,
        "Independent",
        "An independent Roblox Studio plugin. Not affiliated with Discord or Roblox.",
        12,
        C.muted
    )
    self:selectTab("Presence")
    root.Visible = true
    return self
end

function UI:showModes(selected, onSelect, iconsOnly)
    if self.linkModal then
        self.linkModal:Destroy()
    end
    local f = make(
        "Frame",
        { Name = "ModePicker", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, ZIndex = 10 },
        self.widget
    )
    self.linkModal = f
    local heading =
        label(f, "Heading", iconsOnly and "Choose your icon" or "Choose your activity", 21)
    heading.Position = UDim2.fromOffset(18, 18)
    heading.Size = UDim2.new(1, -36, 0, 30)
    local hint = label(
        f,
        "Hint",
        iconsOnly
                and "Follow activity switches icons automatically. Focus and Away keep their own icons."
            or "Automatic adapts as you work. A manual choice stays selected.",
        12,
        C.muted
    )
    hint.Position = UDim2.fromOffset(18, 54)
    hint.Size = UDim2.new(1, -36, 0, 36)
    local grid = make("ScrollingFrame", {
        Name = "Modes",
        Position = UDim2.fromOffset(18, 100),
        Size = UDim2.new(1, -36, 1, -163),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
    }, f)
    make("UIGridLayout", {
        CellSize = UDim2.new(0.5, -5, 0, 56),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)
    for i, mode in ipairs(Modes.Order) do
        local data = Modes[mode]
        local b = button(grid, mode, "", false, function()
            if onSelect then
                onSelect(mode)
            else
                self.callbacks.selectMode(mode)
            end
            f:Destroy()
            self.linkModal = nil
        end)
        b.LayoutOrder = i
        b:SetAttribute("BaseColor", selected == mode and C.border or C.panel)
        local img = icon(b, "Icon", mode, 32)
        img.Position = UDim2.fromOffset(8, 12)
        local text =
            label(b, "Label", iconsOnly and mode == "Auto" and "Follow activity" or data.label, 12)
        text.Position = UDim2.fromOffset(47, 18)
        text.Size = UDim2.new(1, -51, 0, 32)
    end
    local back = button(f, "Back", "Back", false, function()
        f:Destroy()
        self.linkModal = nil
    end)
    back.Position = UDim2.new(0, 18, 1, -50)
    back.Size = UDim2.new(1, -36, 0, 34)
end

function UI:selectTab(name)
    self.tab = name
    for n, p in pairs(self.pages) do
        p.Visible = n == name
        self.tabs[n]:SetAttribute("BaseColor", n == name and C.panel or C.bg)
        self.tabs[n].TextColor3 = n == name and C.accent or C.muted
        self.tabs[n].SelectedIndicator.Visible = n == name
    end
end

function UI:showLink(title, url)
    if self.linkModal then
        self.linkModal:Destroy()
    end
    local f = make(
        "Frame",
        { Name = "LinkDialog", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, ZIndex = 10 },
        self.widget
    )
    padding(f, 24)
    layout(f, 16)
    self.linkModal = f
    label(f, "LinkTitle", title, 22)
    label(
        f,
        "LinkInstructions",
        "Select the link, copy it with Ctrl+C, and open it in your browser.",
        14,
        C.muted
    )
    local b = box(f, "LinkUrl", "", url)
    b.TextEditable = false
    button(f, "CloseLink", "Back", false, function()
        f:Destroy()
        self.linkModal = nil
    end)
    b:CaptureFocus()
    b.CursorPosition = #url + 1
    b.SelectionStart = 1
end

function UI:render(state, settings, activity, elapsed, configured, session, resolvedMode)
    local titles = {
        disconnected = "NOT CONNECTED",
        requesting = "CONNECTING",
        awaiting = "WAITING FOR YOU",
        paused = "PAUSED",
        sending = "UPDATING",
        sharing = "SHARING",
        retrying = "RECONNECTING",
        error = "NEEDS ATTENTION",
        disconnecting = "DISCONNECTING",
        updating = "UPDATING",
    }
    self.status.Text = titles[state.phase] or state.phase:upper()
    self.status.TextColor3 = state.phase == "sharing" and C.green or C.muted
    self.detail.Text = not configured
            and "Discord application setup is needed before connecting. You can explore the preview."
        or state.detail
    if state.phase == "sharing" then
        self.detail.Text = "Sharing your activity with Discord."
    end
    self.connect.Visible = not state.linked
        and state.phase ~= "awaiting"
        and state.phase ~= "requesting"
        and not state.disconnecting
    self.permissionNotice.Visible = not state.linked
        and not state.disconnecting
        and state.phase ~= "awaiting"
    self.connectionCard.LayoutOrder = state.phase == "awaiting" and 0 or 2
    self.connect.Text = configured and "Connect Discord" or "Set up Discord application"
    self.share.Visible = state.linked and not state.disconnecting
    self.share.Text = state.enabled and "Pause sharing" or "Start sharing"
    ActionIcons.set(self.share.ActionIcon, state.enabled and "pause" or "play")
    self.disconnect.Visible = (state.linked or state.phase == "requesting")
        and not state.disconnecting
    self.disconnect.Text = state.linked and "Disconnect account" or "Cancel sign-in"
    self.codePanel.Visible = state.phase == "awaiting"
    if self.codePanel.Visible then
        local qrUrl =
            Api.verificationLink(state.verificationUrl, state.userCode, state.verificationComplete)
        if self.qrUrl ~= qrUrl then
            self.qrUrl = qrUrl
            self.qr.Visible = qrUrl ~= nil and QRCode.draw(self.qr, qrUrl)
        end
        self.codeExpiry.Text = "Code expires in "
            .. math.max(0, math.ceil((state.expiresAt or 0) - os.time()))
            .. " seconds"
    elseif self.qrUrl then
        self.qr:ClearAllChildren()
        self.qrUrl = nil
    end
    self.codeBox.Text = state.userCode or ""
    self.linkBox.Text = self.codePanel.Visible and (self.qrUrl or state.verificationUrl or "") or ""
    self.previewDetails.Text = activity.details
    self.previewState.Text = activity.state
    local previewMode = settings.iconMode ~= "Auto"
            and table.find(Modes.Order, settings.iconMode)
            and settings.iconMode
        or resolvedMode
    if resolvedMode == "Focus" or resolvedMode == "Idle" then
        previewMode = resolvedMode
    end
    setIcon(self.previewIcon, previewMode or "Building")
    self.previewTime.Visible = settings.showTimer
    self.previewTime.Text = elapsed >= 3600
            and string.format(
                "%d:%02d:%02d elapsed",
                math.floor(elapsed / 3600),
                math.floor(elapsed / 60) % 60,
                elapsed % 60
            )
        or string.format("%02d:%02d elapsed", math.floor(elapsed / 60), elapsed % 60)
    self.previewLink.Visible = activity.details_url ~= nil
    self.previewLink.Text = activity.details_url or ""
    self.modeLabel.Text = (Modes[settings.mode] or Modes.Auto).label
    setIcon(
        self.modeIcon,
        settings.mode == "Auto" and (resolvedMode or "Building") or settings.mode
    )
    self.modeHint.Text = settings.mode == "Auto"
            and ("Now: " .. (Modes[resolvedMode] or Modes.Building).label)
        or "Manual activity"
    self.private.Text = "Private project: " .. (settings.private and "ON" or "OFF")
    self.private.TextColor3 = settings.private and C.green or C.text
    ActionIcons.set(self.private.ActionIcon, settings.private and "lock" or "unlock")
    self.timer.Text = "Session timer: " .. (settings.showTimer and "ON" or "OFF")
    self.placeLink.Text = "Project link: " .. (settings.showLink and "ON" or "OFF")
    self.background.Text = "Pause in background: " .. (settings.pauseBackground and "ON" or "OFF")
    self.smartSelection.Text = "Selection hints: " .. (settings.smartSelection and "ON" or "OFF")
    self.idle.Text = "Idle after: "
        .. (settings.idleMinutes == 0 and "OFF" or tostring(settings.idleMinutes or 5) .. " min")
    self.idleBehavior.Text = "When idle: "
        .. (settings.idleBehavior == "Away" and "show Away activity" or "pause sharing")
    if session then
        self.sessionText.Text = math.floor(session.activeSeconds / 60) .. " min active this session"
        local remaining = session.focusEnds and math.max(0, session.focusEnds - os.time())
        self.focusText.Text = remaining
                and string.format(
                    "Focus  %02d:%02d remaining",
                    math.floor(remaining / 60),
                    remaining % 60
                )
            or (
                session.focusComplete and "Focus complete. Take a break when you are ready."
                or "Choose a timer. Works offline too."
            )
        if remaining and settings.showTimer then
            self.previewTime.Text =
                string.format("%02d:%02d remaining", math.floor(remaining / 60), remaining % 60)
        end
        if remaining then
            self.modeHint.Text = "Focus timer active"
        end
    end
    if resolvedMode == "Idle" then
        self.previewTime.Visible = false
    end
    self.diagnostics.Text = Diagnostics.summary(state, os.time())
        .. "\nTransport: direct Discord HTTP (experimental)."
    if not self.alias:IsFocused() then
        self.alias.Text = settings.projectAlias
    end
    self.profileEditor:updatePreview()
end

function UI:refreshProfiles()
    self.profileEditor:refresh()
end

function UI:selectReportText()
    local modal = self.linkModal
    if not modal or modal.Name ~= "SupportReport" then
        return
    end
    local field = modal.ReportScroll.ReportFrame.ReportText
    field:CaptureFocus()
    field.CursorPosition = #field.Text + 1
    field.SelectionStart = 1
    modal.Hint.Text =
        "Report selected. Press Ctrl+C (Cmd+C on Mac), then paste it into your support message. Nothing is sent automatically."
end

function UI:showReport(report)
    if self.linkModal then
        self.linkModal:Destroy()
    end
    local f = make("Frame", {
        Name = "SupportReport",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, self.widget)
    self.linkModal = f
    padding(f, 18)
    label(f, "Title", "Support report", 21).Size = UDim2.new(1, 0, 0, 30)
    local hint = label(
        f,
        "Hint",
        "A diagnostic snapshot for support, without your private details. Use Copy report below, then press Ctrl+C (Cmd+C on Mac). Nothing is sent automatically.",
        13,
        C.muted
    )
    hint.Position = UDim2.fromOffset(0, 42)
    hint.Size = UDim2.new(1, 0, 0, 62)
    local area = make("ScrollingFrame", {
        Name = "ReportScroll",
        Position = UDim2.fromOffset(0, 110),
        Size = UDim2.new(1, 0, 1, -164),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
    }, f)
    padding(area, 2)
    layout(area, 12)
    local frame = make("Frame", {
        Name = "ReportFrame",
        LayoutOrder = 1,
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.input,
        BorderSizePixel = 0,
    }, area)
    corner(frame, 9)
    padding(frame, 1)
    local field = box(frame, "ReportText", "", report, true)
    field.Size = UDim2.new(1, 0, 0, 0)
    field.AutomaticSize = Enum.AutomaticSize.Y
    field.MultiLine = true
    field.TextWrapped = true
    field.TextTruncate = Enum.TextTruncate.None
    field.TextYAlignment = Enum.TextYAlignment.Top
    field.Focused:Connect(function()
        frame.BackgroundColor3 = C.accent
    end)
    field.FocusLost:Connect(function()
        frame.BackgroundColor3 = C.input
    end)
    local copy = button(area, "CopyReport", "Copy report", true, function()
        self:selectReportText()
    end, "report")
    copy.LayoutOrder = 2
    copy.Size = UDim2.new(1, -8, 0, 38)
    local close = button(f, "Back", "Back", false, function()
        f:Destroy()
        self.linkModal = nil
    end)
    close.Position = UDim2.new(0, 0, 1, -38)
end

return UI
