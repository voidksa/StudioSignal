local Panel = {}

function Panel.create(pluginObject, preview, isPlaying)
    local key = "StudioSignal.panelVisible." .. (isPlaying and "play" or "edit")
    local saved
    if not preview then
        local ok, value = pcall(function()
            return pluginObject:GetSetting(key)
        end)
        if ok and type(value) == "boolean" then
            saved = value
        end
    end

    -- Studio keeps separate layouts for edit and play. Old play layouts may
    -- contain a window opened by the previous default, not by the user.
    local overrideRestore = preview or saved ~= nil or isPlaying
    local widget = pluginObject:CreateDockWidgetPluginGuiAsync(
        "StudioSignal.Presence.v01" .. (preview and ".Dev" or ""),
        DockWidgetPluginGuiInfo.new(
            Enum.InitialDockState.Float,
            preview or saved == true,
            overrideRestore,
            420, 720, 340, 420
        )
    )
    local function remember()
        if not preview then
            pcall(function()
                pluginObject:SetSetting(key, widget.Enabled)
            end)
        end
    end
    remember()
    local connection = widget:GetPropertyChangedSignal("Enabled"):Connect(remember)
    return widget, connection
end

return Panel
