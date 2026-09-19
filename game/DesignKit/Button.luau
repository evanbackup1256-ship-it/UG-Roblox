local Tokens = require(script.Parent.Tokens)
local Scheduler = require(script.Parent.Scheduler)
local Primitives = require(script.Parent.Primitives)
local Motion = require(script.Parent.Motion)

local colors = Tokens.colors

-- Sound hook — overwritten at runtime by InterfaceController's real pooled
-- cue system. Kept here (not in Motion.luau) since only Button/Controls
-- primitives call it.
local M = {}
M.sound = function() end

--======================================================================--
-- Kit.button: a single shared skeleton (create instance, corner, glow
-- stroke, focus ring, Disabled/Locked attribute wiring) plus a CLOSED,
-- explicit table of per-variant effects. This is the direct fix for the
-- historical bug class: a new effect used to get added as one more line
-- inside this function's body, reachable by every caller regardless of
-- what kind of control they were actually building (a squash-and-stretch
-- effect meant for confirm buttons ended up firing on a settings toggle
-- built via Kit.button, fighting the toggle's own hand-tuned animation).
--
-- Toggle-shaped, persistent-state controls do NOT go through Kit.button
-- at all — see Kit.checkbox in Controls.luau. Everything that does go
-- through Kit.button is a momentary action, and every effect it can have
-- is a named function wired into exactly the variant rows that want it,
-- below. Adding a new effect means adding a new named function and
-- listing it in the specific rows that should get it — there is no path
-- left that reaches "every button" the way the old bug did.
--======================================================================--

local function pressBounce(scale)
	Motion.animate(scale, { Scale = 0.955 }, 0.09)
end

local function releaseBounce(scale, edge)
	Motion.animate(scale, { Scale = 1.024 }, 0.18, Enum.EasingStyle.Back)
	Motion.animate(edge, { Transparency = Tokens.glow.hoverTransparency }, 0.14)
end

local function hoverGlow(scale, edge)
	Motion.animate(edge, { Transparency = Tokens.glow.hoverTransparency, Thickness = Tokens.glow.thickness + 0.5 }, 0.2)
	Motion.animate(scale, { Scale = 1.024 }, 0.24, Enum.EasingStyle.Back)
end

local function hoverLeave(scale, edge)
	Motion.animate(edge, { Transparency = Tokens.glow.restTransparency, Thickness = Tokens.glow.thickness }, 0.24)
	Motion.animate(scale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back)
end

local function clickRipple(button, primary)
	local pulse = Primitives.create("Frame", button, {
		Name = "Pulse",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = primary and colors.ink or colors.accent,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 1,
	})
	Scheduler.Theme.paint(pulse, "BackgroundColor3", primary and "ink" or "accent")
	Primitives.corner(pulse, 999)
	Motion.animate(pulse, { Size = UDim2.fromScale(1.35, 2.4), BackgroundTransparency = 1 }, 0.42)
	Scheduler.Scheduler.after(pulse, "destroy", 0.44, function()
		if pulse.Parent then
			pulse:Destroy()
		end
	end)
end

-- Variant table: each row lists exactly which named effects that variant
-- gets. `hover`/`leave` run on MouseEnter/Leave + gamepad SelectionGained/
-- Lost; `press`/`release` run on MouseButton1Down/Up; `activate` runs
-- inside Activated, after the shared disabled-check has already passed.
local VARIANT_EFFECTS = {
	action = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = releaseBounce, activate = clickRipple },
	primary = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = releaseBounce, activate = clickRipple },
	icon = { hover = hoverGlow, leave = hoverLeave, press = pressBounce, release = nil, activate = nil },
	nav = { hover = nil, leave = nil, press = nil, release = nil, activate = nil },
}

-- variant: "action" (default) | "primary" | "icon" | "nav". Replaces the
-- old boolean `primary` 5th argument — pass "primary" where `true` used
-- to be passed, omit where `false`/omitted was used before.
function M.button(parent, name, copy, callback, variant)
	variant = variant or "action"
	local effects = VARIANT_EFFECTS[variant]
	assert(effects, ("Kit.button: unknown variant %q"):format(tostring(variant)))
	local primary = variant == "primary"

	local button = Primitives.create("TextButton", parent, {
		Name = name,
		Text = copy,
		Font = Enum.Font.GothamBold,
		TextSize = Tokens.type.body,
		TextColor3 = primary and colors.ink or colors.text,
		BackgroundColor3 = primary and colors.accent or colors.raised,
		Size = UDim2.fromOffset(160, 44),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Selectable = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	Scheduler.Theme.paint(button, "TextColor3", primary and "ink" or "text")
	Scheduler.Theme.paint(button, "BackgroundColor3", primary and "accent" or "raised")
	Primitives.corner(button, Tokens.radius.pill)
	local edge = Primitives.stroke(button, colors.accent, Tokens.glow.restTransparency)
	Scheduler.Theme.paint(edge, "Color", "accent")
	Motion.focusRing(button)
	local scale = Primitives.create("UIScale", button, { Scale = 1 })
	button.ClipsDescendants = true

	button.MouseEnter:Connect(function()
		if button:GetAttribute("Disabled") then return end
		if effects.hover then effects.hover(scale, edge) end
		M.sound("hover")
	end)
	button.MouseLeave:Connect(function()
		if effects.leave then effects.leave(scale, edge) end
	end)
	button.SelectionGained:Connect(function()
		if button:GetAttribute("Disabled") then return end
		if effects.hover then effects.hover(scale, edge) end
		M.sound("hover")
	end)
	button.SelectionLost:Connect(function()
		if effects.leave then effects.leave(scale, edge) end
	end)
	button.MouseButton1Down:Connect(function()
		if button:GetAttribute("Disabled") then return end
		M.sound("press")
		if effects.press then effects.press(scale) end
	end)
	button.MouseButton1Up:Connect(function()
		if button:GetAttribute("Disabled") then return end
		M.sound("release")
		if effects.release then effects.release(scale, edge) end
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
	button.Text = copy

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
	if not enabled then
		local scale = button:FindFirstChildOfClass("UIScale")
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if scale then Motion.animate(scale, { Scale = 1 }, 0.16) end
		if stroke then Motion.animate(stroke, { Transparency = 1, Thickness = Tokens.glow.thickness }, 0.16) end
	end
end

return M
