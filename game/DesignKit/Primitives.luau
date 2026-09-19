local Icons = require(script.Parent.Parent.Icons)
local Tokens = require(script.Parent.Tokens)
local Scheduler = require(script.Parent.Scheduler)

local count = Scheduler._count
local colors = Tokens.colors

local M = {}

function M.create(class, parent, properties)
	local object = Instance.new(class)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	object.Parent = parent
	count("instancesCreated")
	return object
end

function M.corner(object, radius)
	local existing = object:FindFirstChildOfClass("UICorner")
	if existing then
		existing.CornerRadius = UDim.new(0, radius or Tokens.radius.control)
		return existing
	end
	return M.create("UICorner", object, { CornerRadius = UDim.new(0, radius or Tokens.radius.control) })
end

-- Soft glow stroke: thicker and more transparent at rest than a hairline
-- border, so it reads as ambient edge-light rather than a hard outline.
-- `glow = false` opts back into a thin, mostly-opaque hairline for the
-- rare case that actually wants a crisp line (e.g. a divider).
function M.stroke(object, color, transparency, glow)
	if glow == false then
		return M.create("UIStroke", object, {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Color = color or colors.line,
			Transparency = transparency or 0,
		})
	end
	return M.create("UIStroke", object, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = Tokens.glow.thickness,
		Color = color or colors.accent,
		Transparency = transparency or Tokens.glow.restTransparency,
	})
end

function M.text(parent, name, copy, size, color, bold)
	local label = M.create("TextLabel", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Text = copy,
		Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
		TextSize = size or Tokens.type.body,
		TextColor3 = color or colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, (size or Tokens.type.body) + 10),
	})
	return label
end

function M.place(object, x, y, width, height)
	local anchor = object.AnchorPoint
	object.Position = UDim2.fromOffset(x + width * anchor.X, y + height * anchor.Y)
	object.Size = UDim2.fromOffset(width, height)
	if object:GetAttribute("ShakeHome") ~= nil then
		object:SetAttribute("ShakeHome", nil)
	end
	return object
end

function M.card(parent, name, height, color)
	local card = M.create("Frame", parent, {
		Name = name,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = color or colors.panel,
		BorderSizePixel = 0,
	})
	M.corner(card, Tokens.radius.surface)
	M.stroke(card, colors.line, 0.88)
	return card
end

function M.icon(parent, name, key, color)
	local image = M.create("ImageLabel", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Image = Icons.asset(key),
		ImageColor3 = color or colors.muted,
		Size = UDim2.fromOffset(22, 22),
		ScaleType = Enum.ScaleType.Fit,
	})
	return image
end

-- A small rocket glyph built entirely from Frames/UICorner rather than an
-- image asset — no external asset to go missing or render wrong, and it
-- always follows `color` exactly like the rest of the kit.
function M.rocketIcon(parent, name, color)
	local root = M.create("Frame", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(22, 22),
	})
	root:SetAttribute("ShapeIcon", true)

	local tint = color or colors.muted

	local body = M.create("Frame", root, {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromOffset(10, 15),
		BackgroundColor3 = tint,
		BorderSizePixel = 0,
	})
	M.create("UICorner", body, { CornerRadius = UDim.new(1, 0) })

	local nose = M.create("Frame", root, {
		Name = "Nose",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromOffset(7, 7),
		Rotation = 45,
		BackgroundColor3 = tint,
		BorderSizePixel = 0,
	})
	M.create("UICorner", nose, { CornerRadius = UDim.new(0.2, 0) })

	for _, side in ipairs({ -1, 1 }) do
		local fin = M.create("Frame", root, {
			Name = if side < 0 then "FinLeft" else "FinRight",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + side * 0.27, 0.72),
			Size = UDim2.fromOffset(7, 7),
			Rotation = side * 45,
			BackgroundColor3 = tint,
			BorderSizePixel = 0,
		})
		M.create("UICorner", fin, { CornerRadius = UDim.new(0.15, 0) })
	end

	local flame = M.create("Frame", root, {
		Name = "Flame",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.86),
		Size = UDim2.fromOffset(5, 6),
		BackgroundColor3 = tint,
		BorderSizePixel = 0,
	})
	M.create("UICorner", flame, { CornerRadius = UDim.new(0.5, 0) })

	return root
end

-- Recolors an icon regardless of whether it's an ImageLabel from Kit.icon
-- (sets ImageColor3) or a shape-built icon from Kit.rocketIcon (recolors
-- every UIStroke and every Frame with a solid fill among its descendants).
function M.tintIcon(icon, color)
	if icon:IsA("ImageLabel") then
		icon.ImageColor3 = color
		return
	end

	if icon:GetAttribute("ShapeIcon") then
		for _, descendant in ipairs(icon:GetDescendants()) do
			if descendant:IsA("UIStroke") then
				descendant.Color = color
			elseif descendant:IsA("Frame")
				and descendant.BackgroundTransparency < 1
				and not descendant:GetAttribute("IconCutout")
			then
				descendant.BackgroundColor3 = color
			end
		end
	end
end

return M
