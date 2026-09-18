local Settings = {}

function Settings.build(parent, api)
    local rows = {
        {"Motion", "Use interface transitions", "motion"},
        {"Sound effects", "Play feedback for actions", "sfx"},
        {"Background music", "Keep the control room soundtrack", "music"},
        {"3D previews", "Render interactive fleet scenes", "previews"},
        {"Automatic orbit", "Rotate preview scenes while idle", "autoOrbit"},
        {"Notifications", "Show action confirmations", "notifications"},
    }
    local cardHeight = 72
    for index, row in ipairs(rows) do
        local card = api.panel(parent, "Preference_" .. row[3], 0, (index - 1) * (cardHeight + 10), 984, cardHeight, api.colors.panel)
        api.label(card, row[1], 18, 12, 500, 22, 15, api.colors.text, true)
        api.label(card, row[2], 18, 38, 560, 20, 12, api.colors.muted, false)
        local toggle = api.button(card, "", 804, 16, 150, 40, function()
            api.change(row[3], not api.preferences[row[3]])
        end, false)
        local function refresh()
            local enabled = api.preferences[row[3]] == true
            toggle.Text = enabled and "Enabled" or "Disabled"
            toggle.BackgroundColor3 = enabled and api.colors.accent or api.colors.raised
            toggle.TextColor3 = enabled and api.colors.ink or api.colors.text
        end
        refresh()
        task.defer(refresh)
    end
    return function() end
end

return Settings
