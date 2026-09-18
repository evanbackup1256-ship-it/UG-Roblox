local UI = {}

function UI.create(className, parent, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

function UI.round(object, radius)
    local corner = object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = object
    return corner
end

function UI.label(parent, text, x, y, width, height, size, color, bold)
    return UI.create("TextLabel", parent, {
        Text = text,
        Position = UDim2.fromOffset(math.round(x), math.round(y)),
        Size = UDim2.fromOffset(math.max(1, math.round(width)), math.max(1, math.round(height))),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = math.max(12, size or 14),
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

return UI
