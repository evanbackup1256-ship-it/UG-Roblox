local Icons = require(script.Parent.Parent.Icons)
local Tokens = require(script.Parent.Tokens)
local Scheduler = require(script.Parent.Scheduler)
local SpringDriver = require(script.Parent.SpringDriver)

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

-- Crisp, refined hairline stroke (1px border with customizable transparency)
function M.stroke(object, color, transparency, glow)
	local isGlow = glow == true
	return M.create("UIStroke", object, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = isGlow and Tokens.glow.thickness or 1,
		Color = color or colors.line,
		Transparency = transparency or (isGlow and Tokens.glow.restTransparency or 0.65),
	})
end

function M.text(parent, name, copy, size, color, bold)
	local label = M.create("TextLabel", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Text = copy,
		Font = bold and Tokens.font.bold or Tokens.font.regular,
		TextSize = size or Tokens.type.body,
		TextColor3 = color or colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, (size or Tokens.type.body) + 8),
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

-- Stacked-frame drop shadow (Tokens.shadow), no external asset dependency:
-- 2-3 decreasingly-opaque, increasingly-offset Frames parented as `card`'s
-- own children at ZIndex-1 (so they move/resize/destroy with the card
-- automatically, no separate lifecycle to manage). Named "Shadow" as a
-- single container Frame holding the layers, so callers that need to
-- reference it (e.g. M.interactiveCard's hover-lift) can do a plain
-- FindFirstChild("Shadow") rather than hunting for a UIStroke that no
-- longer exists on cards.
function M.shadow(card)
	local shadowConfig = Tokens.shadow
	local container = M.create("Frame", card, {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = card.ZIndex - 1,
	})

	local layers = {}
	for index, layer in ipairs(shadowConfig.layers) do
		local frame = M.create("Frame", container, {
			Name = "Layer" .. index,
			BackgroundColor3 = shadowConfig.color,
			BackgroundTransparency = layer.transparency,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, layer.offset),
			Size = UDim2.fromScale(1, 1),
			ZIndex = container.ZIndex,
		})
		M.corner(frame, Tokens.radius.card)
		layers[index] = { frame = frame, baseOffset = layer.offset, baseTransparency = layer.transparency }
	end

	return container, layers
end

-- Set the shadow's lift state: `lifted = true` pushes each layer further
-- down and darkens it slightly (Tokens.shadow.hoverOffsetBoost/
-- hoverTransparencyDelta), reinforcing a hover/press "lift off the page"
-- read. Pure property assignment here — callers (e.g. M.interactiveCard)
-- wrap this in SpringDriver.animate themselves for the bounce/settle feel,
-- this function just computes the target values.
function M.shadowLiftTargets(layers, lifted)
	local shadowConfig = Tokens.shadow
	local targets = {}
	for index, entry in ipairs(layers) do
		local offset = entry.baseOffset + (lifted and shadowConfig.hoverOffsetBoost or 0)
		local transparency = math.clamp(entry.baseTransparency + (lifted and shadowConfig.hoverTransparencyDelta or 0), 0, 1)
		targets[index] = { frame = entry.frame, offset = offset, transparency = transparency }
	end
	return targets
end

-- Bright white card, elevation communicated via M.shadow (a stacked-frame
-- drop shadow) rather than a hairline border — cards no longer carry a
-- UIStroke at all; the few elements still wanting a thin ring (e.g.
-- Kit.button's Edge, too small for a shadow to read well) build their own
-- via M.stroke directly.
function M.card(parent, name, height, color)
	local card = M.create("Frame", parent, {
		Name = name,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = color or colors.panel,
		BorderSizePixel = 0,
	})
	M.corner(card, Tokens.radius.card)
	M.shadow(card)
	return card
end

-- Recessed sunken track/well (for metrics, inputs, or progress containers)
function M.recessedWell(parent, name, height, color)
	local well = M.create("Frame", parent, {
		Name = name or "RecessedWell",
		Size = UDim2.new(1, 0, 0, height or 40),
		BackgroundColor3 = color or colors.bgDeep,
		BorderSizePixel = 0,
	})
	M.corner(well, Tokens.radius.control)
	M.stroke(well, colors.lineSubtle, 0.5, false)
	return well
end

-- Interactive card: bouncy scale-up + shadow lift on hover (replaces the
-- old border-color-illumination mechanic — cards have no UIStroke to
-- animate anymore, see M.card/M.shadow above). M.card already built the
-- Shadow container as this card's child; look it up by name (not by class,
-- since there's no longer a UIStroke to disambiguate against — but keeping
-- the explicit-name lookup discipline here anyway, consistent with this
-- kit's established fix for the Kit.enable ambiguous-stroke-lookup bug
-- class earlier this session).
function M.interactiveCard(parent, name, height, color, onClick)
	local card = M.card(parent, name, height, color)
	local scale = M.create("UIScale", card, { Name = "CardScale", Scale = 1 })
	local shadowContainer = card:FindFirstChild("Shadow")
	local shadowLayers = {}
	if shadowContainer then
		for _, layerFrame in ipairs(shadowContainer:GetChildren()) do
			if layerFrame:IsA("Frame") then
				local index = tonumber(string.match(layerFrame.Name, "%d+"))
				if index then
					shadowLayers[index] = {
						frame = layerFrame,
						baseOffset = layerFrame.Position.Y.Offset,
						baseTransparency = layerFrame.BackgroundTransparency,
					}
				end
			end
		end
	end

	local function applyShadowLift(lifted)
		if #shadowLayers == 0 then
			return
		end
		for _, target in ipairs(M.shadowLiftTargets(shadowLayers, lifted)) do
			SpringDriver.animate(target.frame, "lift", {
				Position = UDim2.new(0.5, 0, 0.5, target.offset),
				BackgroundTransparency = target.transparency,
			}, "smooth")
		end
	end

	card.MouseEnter:Connect(function()
		SpringDriver.animate(scale, "hover", { Scale = 1.05 }, "bouncy")
		applyShadowLift(true)
	end)

	card.MouseLeave:Connect(function()
		SpringDriver.animate(scale, "hover", { Scale = 1 }, "smooth")
		applyShadowLift(false)
	end)

	if onClick then
		local clickBtn = M.create("TextButton", card, {
			Name = "HitTarget",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			ZIndex = card.ZIndex + 2,
		})
		clickBtn.MouseButton1Down:Connect(function()
			SpringDriver.animate(scale, "hover", { Scale = 0.95 }, "snappy")
		end)
		clickBtn.MouseButton1Up:Connect(function()
			SpringDriver.animate(scale, "hover", { Scale = 1.05 }, "bouncy")
		end)
		clickBtn.Activated:Connect(function()
			onClick()
		end)
	end

	return card
end

-- Minimalist pill tag / badge
function M.badge(parent, text, variant, iconKey)
	variant = variant or "accent"
	local tint = colors[variant] or colors.accent
	local isGhost = variant == "ghost"

	local badge = M.create("Frame", parent, {
		Name = "Badge",
		BackgroundColor3 = if isGhost then colors.raised else tint,
		BackgroundTransparency = if isGhost then 0.6 else 0.88,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	M.corner(badge, Tokens.radius.pill)
	M.stroke(badge, tint, if isGhost then 0.7 else 0.55, false)

	M.create("UIPadding", badge, {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 0),
		PaddingBottom = UDim.new(0, 0),
	})

	M.create("TextLabel", badge, {
		Name = "Text",
		BackgroundTransparency = 1,
		Text = string.upper(text),
		Font = Tokens.font.mono,
		TextSize = Tokens.type.micro,
		TextColor3 = tint,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	return badge
end

-- Clean status indicator dot (e.g. for live telemetry, active operations)
function M.statusDot(parent, color, labelText, size)
	local dotSize = size or 6
	local container = M.create("Frame", parent, {
		Name = "StatusDot",
		Size = UDim2.fromOffset(dotSize, dotSize),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	local dot = M.create("Frame", container, {
		Name = "Dot",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color or colors.accent,
		BorderSizePixel = 0,
	})
	M.corner(dot, Tokens.radius.pill)
	local halo = M.create("UIStroke", dot, {
		Name = "Halo",
		Color = color or colors.accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	dot:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		halo.Color = dot.BackgroundColor3
	end)

	container:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		dot.BackgroundColor3 = container.BackgroundColor3
	end)

	if labelText and labelText ~= "" then
		M.create("TextLabel", container, {
			Name = "Label",
			Text = labelText,
			Font = Tokens.font.mono,
			TextSize = Tokens.type.micro,
			TextColor3 = colors.muted,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0, 60, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	return container
end

-- Sci-fi corner-bracket HUD framing has no place in the Playground visual
-- language (light/bright/playful mobile-game) — stubbed to a no-op empty
-- Frame rather than deleting the export, since Interface/Tutorial.luau
-- still calls this (return value unused there). Its one call site is
-- removed directly as pages are rewritten; this stub exists only so
-- nothing errors in the meantime.
function M.hudFrame(parent, _arg2, _arg3, _arg4)
	return M.create("Frame", parent, {
		Name = "HUDFrame",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
end

-- Minimalist icon badge with subtle background tint
function M.iconBadge(parent, name, key, iconColor, bgColor)
	local container = M.create("Frame", parent, {
		Name = name or "IconBadge",
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = bgColor or colors.raised,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
	})
	M.corner(container, Tokens.radius.control)
	M.stroke(container, iconColor or colors.line, 0.7, false)

	local icon = M.icon(container, "Icon", key, iconColor or colors.accent)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(18, 18)

	return container, icon
end

-- Sleek gradient hairline divider
function M.divider(parent, vertical, color)
	local div = M.create("Frame", parent, {
		Name = "Divider",
		Size = if vertical then UDim2.new(0, 1, 1, 0) else UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = color or colors.line,
		BorderSizePixel = 0,
	})
	M.create("UIGradient", div, {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = if vertical then 90 else 0,
	})
	return div
end

function M.icon(parent, name, key, color)
	local image = M.create("ImageLabel", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Image = Icons.asset(key),
		ImageColor3 = color or colors.muted,
		Size = UDim2.fromOffset(20, 20),
		ScaleType = Enum.ScaleType.Fit,
	})
	return image
end

function M.rocketIcon(parent, name, color)
	local root = M.create("Frame", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 20),
	})
	root:SetAttribute("ShapeIcon", true)

	local tint = color or colors.muted

	local body = M.create("Frame", root, {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromOffset(9, 14),
		BackgroundColor3 = tint,
		BorderSizePixel = 0,
	})
	M.create("UICorner", body, { CornerRadius = UDim.new(1, 0) })

	local nose = M.create("Frame", root, {
		Name = "Nose",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromOffset(6, 6),
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
			Size = UDim2.fromOffset(6, 6),
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
		Size = UDim2.fromOffset(4, 5),
		BackgroundColor3 = tint,
		BorderSizePixel = 0,
	})
	M.create("UICorner", flame, { CornerRadius = UDim.new(0.5, 0) })

	return root
end

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
