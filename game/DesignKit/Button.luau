local Tokens = require(script.Parent.Tokens)
local Scheduler = require(script.Parent.Scheduler)
local Primitives = require(script.Parent.Primitives)
local Motion = require(script.Parent.Motion)

local colors = Tokens.colors

local M = {}
M.sound = function() end

-- Playground Button Mechanics:
-- Bouncy, exaggerated spring feedback on every interaction — bounce is now
-- the default character (MotionService.Presets), not reserved for
-- celebration. VARIANT_EFFECTS' closed-table shape (same 8 variant keys,
-- same effect-slot names, same nil-means-no-effect pattern) is UNCHANGED
-- from Sleek Obsidian — this is the deliberate fix for a prior bug class
-- where an effect silently reached every button; only the bodies below and
-- the values inside the table changed for this rewrite.

local function pressBounce(scale)
	Motion.animate(scale, { Scale = 0.88 }, "snappy")
end

local function pressGlow(button, variant)
	local targetColor
	if variant == "primary" then
		targetColor = colors.accent:Lerp(Color3.new(1, 1, 1), 0.15)
	elseif variant == "danger" then
		targetColor = colors.error:Lerp(Color3.new(1, 1, 1), 0.15)
	elseif variant == "secondary" then
		targetColor = colors.panel:Lerp(colors.accent, 0.2)
	elseif variant == "amber" then
		targetColor = colors.energy:Lerp(Color3.new(1, 1, 1), 0.15)
	else
		targetColor = colors.raised:Lerp(colors.accent, 0.2)
	end
	Motion.animate(button, { BackgroundColor3 = targetColor }, "snappy")
end

local function restoreGlow(button, variant)
	local baseColor
	if variant == "primary" then
		baseColor = colors.accent
	elseif variant == "danger" then
		baseColor = colors.error
	elseif variant == "secondary" then
		baseColor = colors.panel
	elseif variant == "amber" then
		baseColor = colors.energy
	elseif variant == "ghost" then
		baseColor = colors.background
	else
		baseColor = colors.raised
	end
	Motion.animate(button, { BackgroundColor3 = baseColor }, "smooth")
end

local function releaseBounce(scale, edge)
	Motion.animate(scale, { Scale = 1.10 }, "bouncy")
	if edge then
		Motion.animate(edge, { Transparency = Tokens.glow.hoverTransparency }, "snappy")
	end
end

local function hoverGlow(scale, edge)
	if edge then
		Motion.animate(edge, { Transparency = Tokens.glow.hoverTransparency, Color = colors.lineGlow }, "smooth")
	end
	Motion.animate(scale, { Scale = 1.08 }, "bouncy")
end

local function hoverLeave(scale, edge)
	if edge then
		Motion.animate(edge, { Transparency = Tokens.glow.restTransparency, Color = colors.line }, "smooth")
	end
	Motion.animate(scale, { Scale = 1 }, "smooth")
end

local function clickRipple(button, primary)
	local clip = button:FindFirstChild("ClipMask")
	if not clip then return end
	local pulse = Primitives.create("Frame", clip, {
		Name = "Pulse",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = primary and colors.ink or colors.accent,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 1,
	})
	Primitives.corner(pulse, Tokens.radius.pill)
	Motion.animate(pulse, { Size = UDim2.fromScale(1.6, 3), BackgroundTransparency = 1 }, "bouncy")
	Scheduler.Scheduler.after(pulse, "destroy", 0.4, function()
		if pulse.Parent then
			pulse:Destroy()
		end
	end)
end

local VARIANT_EFFECTS = {
	action = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = releaseBounce, activate = clickRipple, pressGlow = pressGlow },
	primary = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = releaseBounce, activate = clickRipple, pressGlow = pressGlow },
	secondary = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = releaseBounce, activate = clickRipple, pressGlow = pressGlow },
	amber = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = releaseBounce, activate = clickRipple, pressGlow = pressGlow },
	danger = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = releaseBounce, activate = clickRipple, pressGlow = pressGlow },
	ghost = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = releaseBounce, activate = nil, pressGlow = nil },
	icon = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = nil, activate = nil },
	nav = { hover = nil, leave = nil, press = nil, release = nil, activate = nil },
}

-- variant: "action" (default) | "primary" | "secondary" | "amber" | "danger" | "ghost" | "icon" | "nav".
function M.button(parent, name, copy, callback, variant)
	variant = variant or "action"
	local effects = VARIANT_EFFECTS[variant] or VARIANT_EFFECTS.action
	local primary = variant == "primary"

	local textColor, bgColor, strokeColor, bgTransparency
	if variant == "primary" then
		textColor, bgColor, strokeColor = colors.ink, colors.accent, colors.lineGlow
	elseif variant == "amber" then
		textColor, bgColor, strokeColor = colors.ink, colors.energy, colors.energy
	elseif variant == "danger" then
		textColor, bgColor, strokeColor = colors.text, colors.error, colors.error
	elseif variant == "secondary" then
		textColor, bgColor, strokeColor = colors.text, colors.panel, colors.line
	elseif variant == "ghost" then
		textColor, bgColor, strokeColor, bgTransparency = colors.muted, colors.background, colors.line, 1
	else
		textColor, bgColor, strokeColor = colors.text, colors.raised, colors.line
	end

	local button = Primitives.create("TextButton", parent, {
		Name = name,
		Text = copy,
		Font = Tokens.font.bold,
		TextSize = Tokens.type.body,
		TextColor3 = textColor,
		BackgroundColor3 = bgColor,
		BackgroundTransparency = bgTransparency or 0,
		Size = UDim2.fromOffset(150, 40),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Selectable = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	Scheduler.Theme.paint(button, "TextColor3", primary and "ink" or "text")
	Scheduler.Theme.paint(button, "BackgroundColor3", primary and "accent" or (if variant == "danger" then "error" else "raised"))
	Primitives.corner(button, Tokens.radius.control)
	local edge = Primitives.stroke(button, strokeColor, 0.65, false)
	edge.Name = "Edge"
	Scheduler.Theme.paint(edge, "Color", if variant == "danger" then "error" else "accent")
	Motion.focusRing(button)
	local scale = Primitives.create("UIScale", button, { Scale = 1 })

	local clipMask = Primitives.create("Frame", button, {
		Name = "ClipMask",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	})
	Primitives.corner(clipMask, Tokens.radius.control)

	button.MouseEnter:Connect(function()
		if button:GetAttribute("Disabled") then return end
		if effects.hover then effects.hover(scale, edge) end
		M.sound("hover")
	end)
	button.MouseLeave:Connect(function()
		if effects.leave then effects.leave(scale, edge) end
		if effects.pressGlow then restoreGlow(button, variant) end
	end)
	button.SelectionGained:Connect(function()
		if button:GetAttribute("Disabled") then return end
		if effects.hover then effects.hover(scale, edge) end
		M.sound("hover")
	end)
	button.SelectionLost:Connect(function()
		if effects.leave then effects.leave(scale, edge) end
		if effects.pressGlow then restoreGlow(button, variant) end
	end)
	button.MouseButton1Down:Connect(function()
		if button:GetAttribute("Disabled") then return end
		M.sound("press")
		if effects.press then effects.press(scale) end
		if effects.pressGlow then effects.pressGlow(button, variant) end
	end)
	button.MouseButton1Up:Connect(function()
		if button:GetAttribute("Disabled") then return end
		M.sound("release")
		if effects.release then effects.release(scale, edge) end
		if effects.pressGlow then restoreGlow(button, variant) end
	end)
	button.Activated:Connect(function()
		if button:GetAttribute("Disabled") then
			M.sound(if button:GetAttribute("Locked") then "lock" else "denied")
			Motion.shake(button)
			return
		end
		M.sound(if primary then "confirm" else "click")
		if effects.activate then effects.activate(button, primary) end
		callback()
	end)

	return button
end

function M.enable(button, enabled, copy, primary)
	button:SetAttribute("Disabled", not enabled)
	if copy then
		button.Text = copy
	end

	local textColor, backgroundColor
	if enabled and primary then
		textColor, backgroundColor = "ink", "accent"
	elseif enabled then
		textColor, backgroundColor = "text", "raised"
	else
		textColor, backgroundColor = "muted", "raised"
	end
	button.TextColor3 = colors[textColor]
	button.BackgroundColor3 = colors[backgroundColor]

	button.Active = enabled
	local scale = button:FindFirstChildOfClass("UIScale")
	local stroke = button:FindFirstChild("Edge")
	if not enabled then
		if scale then Motion.animate(scale, { Scale = 1 }, 0.14) end
		if stroke then Motion.animate(stroke, { Transparency = 0.9 }, 0.14) end
	else
		if stroke then Motion.animate(stroke, { Transparency = 0.65 }, 0.14) end
	end
end

return M
