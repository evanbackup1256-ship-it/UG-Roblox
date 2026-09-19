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
	-- Parented into the button's own clip-mask wrapper (see M.button),
	-- never into `button` directly — a UIStroke straddles its object's own
	-- border (half in, half out), so if the button itself clipped its
	-- descendants, its own edge glow and focus ring would get their outer
	-- half cut off wherever a ScrollingFrame ancestor scrolled them near
	-- an edge. The ripple still needs *something* clipping it to the pill
	-- shape so it doesn't spill past the button's rounded corners, hence
	-- the separate wrapper that clips only this.
	local pulse = Primitives.create("Frame", button:FindFirstChild("ClipMask"), {
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
	-- Named explicitly: a button also gets a FocusRing UIStroke (from
	-- Motion.focusRing below), and FindFirstChildOfClass("UIStroke") with
	-- two UIStroke children returns whichever one happens to be first in
	-- Roblox's internal child order — not necessarily this one. Kit.enable
	-- was hitting that ambiguity and occasionally animating the wrong
	-- stroke (the focus ring instead of the hover-glow edge), leaving the
	-- real edge stroke stuck at whatever transparency it last had.
	edge.Name = "Edge"
	Scheduler.Theme.paint(edge, "Color", "accent")
	Motion.focusRing(button)
	local scale = Primitives.create("UIScale", button, { Scale = 1 })

	-- Clips only the click-ripple (clickRipple parents into this, not into
	-- `button` directly) — the button itself never clips its descendants,
	-- so its own edge glow / focus ring strokes (which straddle the
	-- button's border, half in/half out, per how UIStroke renders) never
	-- get their outer half cut off by a ScrollingFrame ancestor scrolling
	-- them near its edge.
	local clipMask = Primitives.create("Frame", button, {
		Name = "ClipMask",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	})
	Primitives.corner(clipMask, Tokens.radius.pill)

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
	local scale = button:FindFirstChildOfClass("UIScale")
	-- Looked up by the explicit name Kit.button gives this stroke — a
	-- button also has a FocusRing UIStroke, and FindFirstChildOfClass
	-- doesn't disambiguate between the two.
	local stroke = button:FindFirstChild("Edge")
	if not enabled then
		if scale then Motion.animate(scale, { Scale = 1 }, 0.16) end
		if stroke then Motion.animate(stroke, { Transparency = 1, Thickness = Tokens.glow.thickness }, 0.16) end
	else
		-- Restore the stroke's rest state on re-enable — previously only
		-- the disable path touched it at all, so a button disabled then
		-- re-enabled before its next real hover (e.g. Leaderboard's
		-- Refresh button, disabled during its own auto-fetch on page
		-- load) stayed stuck fully transparent until something else
		-- happened to hover it.
		if stroke then Motion.animate(stroke, { Transparency = Tokens.glow.restTransparency, Thickness = Tokens.glow.thickness }, 0.16) end
	end
end

return M
