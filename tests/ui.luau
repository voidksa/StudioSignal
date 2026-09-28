-- Run after the generated bundle library in a Studio plugin context.
-- This creates an isolated preview with in-memory settings and never signs in.
local App = requireModule("App")
local UI = requireModule("UI")
local Config = requireModule("Config")
local Modes = requireModule("Modes")
local previewPlugin = PluginManager():CreatePlugin()
local app
local host
local ok, result = pcall(function()
    app = App.start(previewPlugin, { preview = true })
    assert(app.toolbar == nil and app.button == nil, "Previews must not register ribbon buttons")
    local function widgetCount()
        local count = 0
        for _, widget in game:GetService("PluginGuiService"):GetChildren() do
            if widget.Name == "StudioSignalWidget" then
                count += 1
            end
        end
        return count
    end
    local countBeforeFailure = widgetCount()
    local newUI = UI.new
    UI.new = function(...)
        newUI(...)
        error("Simulated UI construction failure")
    end
    local failedPlugin = PluginManager():CreatePlugin()
    local started, startError = pcall(App.start, failedPlugin, { preview = true })
    UI.new = newUI
    failedPlugin:Destroy()
    assert(not started and tostring(startError):find("Simulated UI construction failure"))
    assert(widgetCount() == countBeforeFailure, "Failed startup left an orphan window")
    local editor = app.ui.profileEditor
    local before = app.preview()
    editor:newDraft()
    editor.fields.name.Text = "Test profile"
    editor.fields.stateText.Text = "Testing profiles"
    editor.fields.detailsText.Text = "Test appearance"
    editor.draft.private = false
    editor:review()
    assert(editor.reviewCard.Visible and editor.previewDetails.Text == "Test appearance")
    assert(app.preview().details == before.details)
    editor:save()
    assert(#app.profiles.items == 1 and app.preview().state == before.state)
    assert(app.callbacks.applyProfile(editor:collect(), editor.selectedId))
    assert(app.preview().state == "Testing profiles" and not app.controller.enabled)
    assert(not app.controller.accessToken)
    assert(app.callbacks.deleteProfile(editor.selectedId))
    assert(app.preview().state == "Testing profiles")
    app.callbacks.applyProfile({ private = true, mode = "Auto" })

    local checks = 0
    local function visible(object, root)
        local current = object
        while current and current ~= root do
            if current:IsA("GuiObject") and not current.Visible then
                return false
            end
            current = current.Parent
        end
        return current == root
    end
    local function checkBounds(root, width)
        task.wait(0.1)
        for _, object in root:GetDescendants() do
            if
                visible(object, root)
                and (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox"))
            then
                local x = object.AbsolutePosition.X - root.AbsolutePosition.X
                assert(
                    x >= -1 and x + object.AbsoluteSize.X <= width + 1,
                    object.Name .. " outside horizontal bounds"
                )
                if not object:IsA("TextBox") then
                    assert(
                        object.TextBounds.Y <= object.AbsoluteSize.Y + 2,
                        object.Name .. " clips text vertically"
                    )
                end
            end
        end
        checks += 1
    end
    for _, size in { Vector2.new(340, 420), Vector2.new(418, 696), Vector2.new(600, 800) } do
        host = Instance.new("Frame")
        host.Name = "StudioSignalLayoutTest"
        host.Size = UDim2.fromOffset(size.X, size.Y)
        host.ZIndex = 20
        host.Parent = app.widget
        local ui = UI.new(host, app.settings, app.callbacks)
        assert(host.StudioSignalUI.Header.VersionBadge.Text == Config.Version)
        for _, object in host:GetDescendants() do
            if object:IsA("TextButton") then
                assert(
                    not object:FindFirstChildWhichIsA("UIStroke"),
                    "Button outlines must not overlap"
                )
            end
        end
        ui:render(
            app.controller:snapshot(),
            app.settings,
            app.preview(),
            0,
            true,
            app.session,
            "Building"
        )
        local firstIcon = ui.modeIcon.ImageRectOffset
        ui:render(
            app.controller:snapshot(),
            app.settings,
            app.preview(),
            0,
            true,
            app.session,
            "Testing"
        )
        assert(ui.modeLabel.Text == Modes.Auto.label and ui.modeIcon.ImageRectOffset ~= firstIcon)
        assert(ui.modeHint.Text == "Now: " .. Modes.Testing.label)
        for _, tab in { "Presence", "Profiles", "Settings", "More tools" } do
            ui:selectTab(tab)
            local visiblePages, selectedTabs = 0, 0
            for _, page in ui.pages do
                if page.Visible then
                    visiblePages += 1
                end
            end
            for _, item in ui.tabs do
                if item.SelectedIndicator.Visible then
                    selectedTabs += 1
                end
            end
            assert(visiblePages == 1 and selectedTabs == 1, "Pages or tab indicators overlap")
            checkBounds(host, size.X)
        end
        ui:selectTab("Profiles")
        ui.profileEditor:newDraft()
        checkBounds(host, size.X)
        ui.profileEditor:review()
        checkBounds(host, size.X)
        ui:selectTab("Presence")
        ui:render({
            phase = "awaiting",
            detail = "Test sign-in",
            verificationUrl = "https://discord.com/activate",
            userCode = "TEST-CODE",
            expiresAt = os.time() + 60,
        }, app.settings, app.preview(), 0, true, app.session, "Building")
        assert(ui.qr.Visible and #ui.qr:GetChildren() > 0 and ui.codeBox.Text == "TEST-CODE")
        assert(ui.qrUrl == "https://discord.com/activate?user_code=TEST-CODE")
        assert(ui.linkBox.Text == ui.qrUrl)
        checkBounds(host, size.X)
        ui:render(
            app.controller:snapshot(),
            app.settings,
            app.preview(),
            0,
            true,
            app.session,
            "Building"
        )
        assert(not ui.codePanel.Visible and ui.codeBox.Text == "" and #ui.qr:GetChildren() == 0)
        ui:showModes("Auto", function() end, true)
        checkBounds(ui.linkModal, size.X)
        ui:showReport(app.callbacks.supportReport())
        checkBounds(ui.linkModal, size.X)
        local reportArea = ui.linkModal.ReportScroll
        local reportFrame = reportArea.ReportFrame
        local reportField = reportFrame.ReportText
        assert(reportFrame.BackgroundColor3 == reportField.BackgroundColor3)
        ui:selectReportText()
        task.wait(0.15)
        assert(not reportField:FindFirstChildWhichIsA("UIStroke"))
        assert(not reportField.TextEditable and reportField:IsFocused())
        assert(reportFrame.BackgroundColor3 ~= reportField.BackgroundColor3)
        assert(
            reportField.SelectionStart == 1 and reportField.CursorPosition == #reportField.Text + 1
        )
        assert(reportField.AbsolutePosition.X > reportFrame.AbsolutePosition.X)
        assert(reportField.AbsolutePosition.Y > reportFrame.AbsolutePosition.Y)
        assert(
            reportArea.CopyReport.AbsolutePosition.Y
                >= reportFrame.AbsolutePosition.Y + reportFrame.AbsoluteSize.Y + 10
        )
        assert(reportField.AbsolutePosition.X > reportArea.AbsolutePosition.X)
        assert(reportField.AbsolutePosition.Y > reportArea.AbsolutePosition.Y)
        reportField:ReleaseFocus()
        task.wait()
        assert(reportFrame.BackgroundColor3 == reportField.BackgroundColor3)
        host:Destroy()
        host = nil
    end
    return {
        layoutChecks = checks,
        profileWorkflow = true,
        qrDisplayAndCleanup = true,
        noSignIn = true,
        noPreviewToolbar = true,
        versionBadge = true,
        automaticIconUpdates = true,
        noButtonStrokes = true,
        prefilledSignInLink = true,
        failedStartupCleaned = true,
        singleVisiblePage = true,
        reportFocusUnclipped = true,
        reportSelectAll = true,
        reportOutlineOnlyOnFocus = true,
    }
end)
if host then
    host:Destroy()
end
if app then
    app.cleanup()
end
previewPlugin:Destroy()
assert(ok, result)
return result
