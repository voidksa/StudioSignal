local Modes = require(script.Parent.Modes)
local ProfileEditor = {}
ProfileEditor.__index = ProfileEditor

function ProfileEditor.new(page, callbacks, kit)
    local self =
        setmetatable({ callbacks = callbacks, kit = kit, fields = {}, page = page }, ProfileEditor)
    local make, label, button, box, card = kit.make, kit.label, kit.button, kit.box, kit.card
    local C = kit.colors
    self.library = card(page, "SavedProfiles", 0)
    label(self.library, "Title", "Your profiles", 20)
    label(
        self.library,
        "Hint",
        "Save a look, review it, then apply it. Editing never changes your live activity.",
        13,
        C.muted
    )
    self.pinStatus = label(self.library, "PinStatus", "", 12, C.accent)
    button(self.library, "NewProfile", "New from current appearance", true, function()
        self:newDraft()
    end)
    self.list = make("ScrollingFrame", {
        Name = "ProfileList",
        Size = UDim2.new(1, 0, 0, 144),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.border,
    }, self.library)
    kit.layout(self.list, 8)
    self.unpin = button(self.library, "Unpin", "Unpin from this project", false, function()
        local _, message = callbacks.unpinProfile()
        self.message.Text = message
        self:refresh()
    end)

    self.editor = card(page, "ProfileEditor", 1)
    label(self.editor, "Title", "Edit appearance", 18)
    button(self.editor, "Library", "Back to profiles", false, function()
        self.library.Visible, self.editor.Visible, self.reviewCard.Visible = true, false, false
        self.page.CanvasPosition = Vector2.zero
    end)
    local definitions = {
        { "name", "Profile name (only visible to you)", "e.g. Client work" },
        { "detailsText", "First line", "Blank uses the project display name" },
        { "stateText", "Activity text", "Blank follows your selected activity" },
        { "projectAlias", "Project display name", "Blank uses the current project name" },
        { "gameUrl", "Public game link", "https://www.roblox.com/games/123456789" },
    }
    for _, field in definitions do
        label(self.editor, field[1] .. "Label", field[2], 12, C.muted)
        self.fields[field[1]] = box(self.editor, field[1], field[3], "")
        self.fields[field[1]]:GetPropertyChangedSignal("Text"):Connect(function()
            self.deleteArmed = false
            if self.delete then
                self.delete.Text = "Delete saved profile"
            end
        end)
    end
    label(
        self.editor,
        "LinkHelp",
        "Use your published game's link even while editing a development copy. Links with private-server codes are not accepted.",
        12,
        C.muted
    )
    self.mode = button(self.editor, "Mode", "", false, function()
        kit.pick(self.draft.mode, function(mode)
            self.draft.mode = mode
            self:refreshControls()
        end, false)
    end)
    self.icon = button(self.editor, "Icon", "", false, function()
        kit.pick(self.draft.iconMode, function(mode)
            self.draft.iconMode = mode
            self:refreshControls()
        end, true)
    end)
    self.private = button(self.editor, "Private", "", false, function()
        self.draft.private = not self.draft.private
        self:refreshControls()
    end)
    label(
        self.editor,
        "PrivacyHelp",
        "Private mode hides the first line, project name and game link. Your custom activity text is still shared, so keep sensitive information out of it.",
        12,
        C.muted
    )
    self.timer = button(self.editor, "Timer", "", false, function()
        self.draft.showTimer = not self.draft.showTimer
        self:refreshControls()
    end)
    self.link = button(self.editor, "Link", "", false, function()
        self.draft.showLink = not self.draft.showLink
        self:refreshControls()
    end)
    button(self.editor, "Review", "Preview & apply", true, function()
        self:review()
    end)
    button(self.editor, "Save", "Save profile without applying", false, function()
        self:save()
    end)
    self.delete = button(self.editor, "Delete", "Delete saved profile", false, function()
        if not self.selectedId then
            return
        end
        if not self.deleteArmed then
            self.deleteArmed = true
            self.delete.Text = "Confirm delete"
            self.message.Text = "Click Confirm delete to remove this saved profile."
            return
        end
        local ok, message = callbacks.deleteProfile(self.selectedId)
        if ok then
            self:newDraft()
        end
        self.message.Text = message
        self:refresh()
    end)
    button(self.editor, "Discard", "Discard edits", false, function()
        self:newDraft()
    end)

    self.reviewCard = card(page, "ProfilePreview", 2)
    self.reviewCard.Visible = false
    label(self.reviewCard, "Title", "What others can see", 18)
    self.previewIcon = kit.icon(self.reviewCard, "Icon", "Building", 64)
    label(self.reviewCard, "AppName", "StudioSignal", 17)
    self.previewDetails = label(self.reviewCard, "Details", "", 14)
    self.previewState = label(self.reviewCard, "State", "", 14)
    self.previewTimer = label(self.reviewCard, "Timer", "", 12, C.accent)
    self.previewLink = label(self.reviewCard, "Link", "", 12, C.accent)
    self.previewBadge = label(self.reviewCard, "Badge", "Small badge: StudioSignal", 12, C.muted)
    label(
        self.reviewCard,
        "Note",
        "Preview of the data sent to Discord; Discord controls its final layout. Focus and Away temporarily override activity text and icons. Applying updates your activity only if sharing is already on.",
        12,
        C.muted
    )
    button(self.reviewCard, "Apply", "Apply to this session", true, function()
        local _, message = callbacks.applyProfile(self:collect(), self.selectedId)
        self.message.Text = message
    end)
    self.pin = button(self.reviewCard, "Pin", "Save, apply & pin to this project", false, function()
        local ok, message, profile = callbacks.pinProfile(self.selectedId, self:collect())
        if ok then
            self.selectedId, self.draft = profile.id, table.clone(profile)
        end
        self.message.Text = message
        self:refresh()
    end)
    self.pinHint = label(self.reviewCard, "PinHint", "", 12, C.muted)
    button(self.reviewCard, "Back", "Back to editor", false, function()
        self.library.Visible, self.editor.Visible, self.reviewCard.Visible = false, true, false
        self.page.CanvasPosition = Vector2.zero
    end)
    local feedback = card(page, "ProfileFeedback", -1)
    self.message = label(
        feedback,
        "Message",
        "Profiles stay on this device. Nothing changes until you apply.",
        13,
        C.accent
    )
    self:newDraft()
    self.library.Visible, self.editor.Visible = true, false
    return self
end

function ProfileEditor:collect()
    local draft = table.clone(self.draft)
    for key, field in self.fields do
        draft[key] = field.Text
    end
    return draft
end

function ProfileEditor:load(profile)
    self.page.CanvasPosition = Vector2.zero
    self.selectedId, self.draft = profile.id, table.clone(profile)
    self.deleteArmed = false
    for key, field in self.fields do
        field.Text = profile[key] or ""
    end
    self.library.Visible, self.editor.Visible, self.reviewCard.Visible = false, true, false
    self.message.Text = "Draft only. Review your changes before applying."
    self:refreshControls()
end

function ProfileEditor:newDraft()
    self:load(self.callbacks.profileDraft())
    self:refresh()
end

function ProfileEditor:refreshControls()
    self.mode.Text = "Activity: " .. Modes[self.draft.mode].label
    self.icon.Text = "Icon: "
        .. (self.draft.iconMode == "Auto" and "Follow activity" or Modes[self.draft.iconMode].label)
    self.private.Text = "Private project: " .. (self.draft.private and "ON" or "OFF")
    self.kit.setAction(self.private, self.draft.private and "lock" or "unlock")
    self.timer.Text = "Session timer: " .. (self.draft.showTimer and "ON" or "OFF")
    self.link.Text = "Game link: " .. (self.draft.showLink and "ON" or "OFF")
    self.delete.Visible = self.selectedId ~= nil
    self.delete.Text = "Delete saved profile"
    self.deleteArmed = false
end

function ProfileEditor:refresh()
    local items, pinnedId, canPin = self.callbacks.profiles()
    for _, child in self.list:GetChildren() do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    local pinnedName
    for i, profile in items do
        if profile.id == pinnedId then
            pinnedName = profile.name
        end
        local b = self.kit.button(
            self.list,
            "Profile" .. i,
            profile.name .. (profile.id == pinnedId and "  /  Pinned" or ""),
            false,
            function()
                self:load(profile)
            end
        )
        b.LayoutOrder = i
        b.Size = UDim2.new(1, -8, 0, 38)
        b.TextTruncate = Enum.TextTruncate.AtEnd
    end
    if #items == 0 then
        self.kit.label(self.list, "Empty", "No saved profiles yet.", 13, self.kit.colors.muted)
    end
    self.pinStatus.Text = pinnedName and "Pinned here: " .. pinnedName
        or "No profile pinned to this project."
    self.unpin.Visible = pinnedId ~= nil
    self.pin.Visible = canPin
    self.pinHint.Text = canPin
            and "Pinning loads this saved profile when the place opens. Sharing still requires your account connection and Start sharing."
        or "Pinning needs a published Roblox place. You can still save and apply profiles in local files."
end

function ProfileEditor:updatePreview()
    if not self.reviewCard.Visible then
        return
    end
    local activity, iconMode = self.callbacks.previewProfile(self:collect())
    if not activity then
        self.message.Text = iconMode
        return
    end
    self.kit.setIcon(self.previewIcon, iconMode)
    self.previewDetails.Text = activity.details
    self.previewState.Text = activity.state
    self.previewTimer.Text = activity.timestamps
            and (activity.timestamps["end"] and "Timer: focus countdown" or "Timer: session elapsed time")
        or "Timer: hidden"
    self.previewLink.Text = activity.details_url and ("Game link: " .. activity.details_url)
        or "Game link: hidden"
end

function ProfileEditor:review()
    self.page.CanvasPosition = Vector2.zero
    local activity, err = self.callbacks.previewProfile(self:collect())
    if not activity then
        self.message.Text = err
        return
    end
    self.library.Visible, self.editor.Visible, self.reviewCard.Visible = false, false, true
    self.message.Text = "Review this preview. Nothing has been applied yet."
    self:updatePreview()
end

function ProfileEditor:save()
    self.page.CanvasPosition = Vector2.zero
    local profile, err = self.callbacks.saveProfile(self.selectedId, self:collect())
    if not profile then
        self.message.Text = err
        return
    end
    self:load(profile)
    self.message.Text = "Saved on this device. Your current activity has not changed."
    self:refresh()
end

return ProfileEditor
