local TweenService = game:GetService("TweenService")

local Icons = require(script.Parent.Parent.Icons)
local Tokens = require(script.Parent.Tokens)
local Motion = require(script.Parent.Parent.MotionService)
local SpringDriver = require(script.Parent.SpringDriver)
local ValueTicker = require(script.Parent.ValueTicker)
local Scheduler = require(script.Parent.Scheduler)
local Primitives = require(script.Parent.Primitives)

local colors = Tokens.colors
local bucket = Scheduler._bucket
local watch = Scheduler._watch
local count = Scheduler._count

local M = {}
M.motion = true

-- Translates Kit.animate's 3rd/4th/5th arguments — either a new preset
-- name string ("snappy"/"smooth"/"bouncy") or the legacy TweenInfo-style
-- (duration, EasingStyle, EasingDirection) triple every existing call
-- site still passes — into one of MotionService.Presets. This is what
-- lets every one of the 27+ existing Kit.animate call sites keep working
-- unchanged at this checkpoint: nothing needs to be rewritten to a preset
-- name for the spring engine to already be live underneath it. Enum
-- .EasingDirection is accepted but ignored (springs have no In/Out/InOut
-- concept) — every real call site's EasingDirection is either the default
-- Out or the one Controls.luau checkbox-uncheck In, which reads fine as a
-- plain snappy settle in practice.
local function resolvePreset(presetOrDuration, style)
	if type(presetOrDuration) == "string" and Motion.Presets[presetOrDuration] then
		return presetOrDuration
	end
	if style == Enum.EasingStyle.Back then
		return "bouncy"
	end
	local duration = presetOrDuration
	if type(duration) == "number" and duration <= 0.15 then
		return "snappy"
	end
	return "smooth"
end

-- Spring-driven: `duration`'s old role (this argument's 3rd position) now
-- doubles as a preset-name string ("snappy"/"smooth"/"bouncy") OR keeps
-- working as a legacy (duration, style, direction) triple, translated via
-- resolvePreset above. Infinite-loop effects (gradientAnimate's sheen/
-- rainbow/pulse, progressShimmer) deliberately stay on raw TweenService
-- below, not on this — a spring settles toward a target and stops, it has
-- no native "loop forever" concept, and building one for 4 call sites
-- that have never needed tuning isn't worth the surface area. Do not
-- "helpfully" convert those to Kit.animate.
function M.animate(object, properties, duration, style, direction)
	if not M.motion then
		SpringDriver.cancel(object, "animate")
		Scheduler.Scheduler.clear(object, "animate")
		for key, value in pairs(properties) do
			object[key] = value
		end
		return
	end

	local preset = resolvePreset(duration, style)
	-- Scheduler.track must release whatever was PREVIOUSLY tracked under
	-- this (object, key) BEFORE the new spring starts, not after — spr has
	-- no per-call identity, so a stale handle's Cancel() calls
	-- spr.stop(object) unconditionally. If that ran after SpringDriver
	-- .animate below had already called spr.target, it would immediately
	-- wipe the animation this very call just started, on every single call
	-- after the first one for a given object (which is nearly every
	-- hover/press/leave/release pair in the game, since they all animate
	-- the same button's UIScale/UIStroke repeatedly).
	Scheduler.Scheduler.clear(object, "animate")
	local handle = SpringDriver.animate(object, "animate", properties, preset)
	Scheduler.Scheduler.track(object, "animate", handle)
	count("tweensStarted")
	return handle
end

-- A small sequencing layer over M.animate: runs a list of
-- {object, properties, duration, style, direction} steps one after
-- another, fully cancellable as a unit and automatically cleaned up if
-- `owner` is destroyed mid-sequence. Reduced motion collapses every step
-- to its final values instantly, same as M.animate does alone.
M.Motion = {}

function M.Motion.sequence(owner, key, steps)
	Scheduler.Scheduler.clear(owner, key)

	if not M.motion then
		for _, step in ipairs(steps) do
			for property, value in pairs(step.properties) do
				step.object[property] = value
			end
		end
		return
	end

	local entries = bucket(owner)
	local slot = {}

	local function runFrom(index)
		local step = steps[index]
		if not step then
			if entries[key] == slot then
				entries[key] = nil
			end
			return
		end

		local tween = M.animate(step.object, step.properties, step.duration, step.style, step.direction)
		slot.tween = tween

		if index == #steps then
			if entries[key] == slot then
				entries[key] = nil
			end
			return
		end

		slot.thread = task.delay(step.duration or 0.2, function()
			runFrom(index + 1)
		end)
		count("delaysScheduled")
	end

	watch(owner)
	entries[key] = slot
	runFrom(1)
end

-- UIScale always scales its object around that object's own AnchorPoint —
-- for a button (AnchorPoint 0.5,0.5) that's the visual center, correct by
-- construction, but M.bump is called on plain labels built via Kit.text,
-- which default to AnchorPoint (0,0) (top-left) like every other label in
-- this kit, since changing that default would break every Kit.place call
-- site's positioning math game-wide. Scaling a (0,0)-anchored object grows
-- it down-and-right from its top-left corner instead of its visual center
-- — correct fix here (not touching AnchorPoint) is to counter-shift
-- Position by half the anchor-relative size delta every frame the scale
-- changes, so the label's on-screen center stays fixed while it pops.
local function anchorAwareScaleFollow(object, scale)
	local anchor = object.AnchorPoint
	if anchor.X == 0.5 and anchor.Y == 0.5 then
		-- Already centered (e.g. Kit.button) — UIScale is correct as-is,
		-- no compensation needed.
		return
	end

	local baseSize = object.Size
	local basePosition = object.Position

	local connection = scale:GetPropertyChangedSignal("Scale"):Connect(function()
		local delta = scale.Scale - 1
		local offsetX = -baseSize.X.Offset * delta * anchor.X
		local offsetY = -baseSize.Y.Offset * delta * anchor.Y
		local scaleX = -baseSize.X.Scale * delta * anchor.X
		local scaleY = -baseSize.Y.Scale * delta * anchor.Y
		object.Position = UDim2.new(
			basePosition.X.Scale + scaleX, basePosition.X.Offset + offsetX,
			basePosition.Y.Scale + scaleY, basePosition.Y.Offset + offsetY
		)
	end)

	-- watch() registers object's Destroying signal once and routes it
	-- through Scheduler.clear — piggyback the same hook to also disconnect
	-- this connection, rather than polling object.Parent on every Scale
	-- change (which only cancels the connection on its NEXT fire, not
	-- immediately at destroy time).
	watch(object)
	object.Destroying:Once(function()
		connection:Disconnect()
	end)
end

function M.bump(object, peak)
	if not object or not object.Parent then return end
	local scale = object:FindFirstChild("ValueBump")
	if not scale then
		scale = Primitives.create("UIScale", object, { Name = "ValueBump", Scale = 1 })
		anchorAwareScaleFollow(object, scale)
	end
	M.Motion.sequence(object, "bump", {
		{ object = scale, properties = { Scale = peak or 1.045 }, duration = 0.12, style = Enum.EasingStyle.Back },
		{ object = scale, properties = { Scale = 1 }, duration = 0.22, style = Enum.EasingStyle.Quint },
	})
end

-- peak = false updates the text without the pop animation, for values that
-- change on their own rather than because of something the player just did.
function M.setValue(label, value, peak)
	if label.Text ~= value then
		label.Text = value
		if peak ~= false then
			M.bump(label, peak)
		end
	end
end

-- Ticks label.Text smoothly from its last-known raw number toward `raw`,
-- reformatting on every intermediate frame via `format` — for a steady
-- server-push value (a live balance, a live rate) where a tick reads as
-- motion, not noise. Distinct from Kit.setValue: that one is for
-- pre-formatted strings with no underlying number to interpolate (most
-- existing call sites), this one is for genuinely numeric values. `peak`,
-- like Kit.bump, fires the pop-scale once the tick settles rather than
-- every frame — pass false to skip it.
local lastTicked = setmetatable({}, { __mode = "k" }) -- label -> last raw number

function M.tickValue(label, raw, format, presetName, peak)
	if not M.motion then
		ValueTicker.cancel(label, "tick")
		lastTicked[label] = raw
		label.Text = format(raw)
		return
	end

	local current = lastTicked[label]
	if current == nil then
		current = raw
	end
	lastTicked[label] = raw

	local handle = ValueTicker.animate(label, "tick", current, raw, presetName or "smooth", function(value)
		label.Text = format(value)
	end, function()
		if peak ~= false then
			M.bump(label, peak)
		end
	end)
	Scheduler.Scheduler.track(label, "tick", handle)
	count("tweensStarted")
end

-- Card-level "locked" treatment: dims the whole card and shows a padlock
-- badge. If the card's action button is passed as `button`, it's tagged so
-- clicking it while disabled plays the "lock" denial cue instead of the
-- generic "denied" one.
function M.lock(card, locked, button)
	local badge = card:FindFirstChild("LockBadge")

	if button then
		button:SetAttribute("Locked", locked)
	end

	if not locked then
		if badge then
			M.animate(badge, { ImageTransparency = 1 }, 0.18)
		end
		M.animate(card, { BackgroundTransparency = 0 }, 0.18)
		return
	end

	if not badge then
		badge = Primitives.create("ImageLabel", card, {
			Name = "LockBadge",
			Image = Icons.asset("lock"),
			ImageColor3 = colors.muted,
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			Size = UDim2.fromOffset(16, 16),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 14),
			ZIndex = 5,
		})
		Scheduler.Theme.paint(badge, "ImageColor3", "muted")
	end

	M.animate(badge, { ImageTransparency = 0 }, 0.18)
	M.animate(card, { BackgroundTransparency = 0.35 }, 0.18)
end

-- Short horizontal shake + red stroke flash, the visual companion to the
-- "denied" sound cue. Home position is cached on first use via an
-- attribute so overlapping or cancelled shakes can't leave the object
-- permanently offset.
function M.shake(object)
	if not M.motion then
		return
	end

	local home = object:GetAttribute("ShakeHome")
	if not home then
		home = object.Position
		object:SetAttribute("ShakeHome", home)
	end

	M.Motion.sequence(object, "shake", {
		{ object = object, properties = { Position = home + UDim2.fromOffset(4, 0) }, duration = 0.05 },
		{ object = object, properties = { Position = home + UDim2.fromOffset(-3, 0) }, duration = 0.07 },
		{ object = object, properties = { Position = home }, duration = 0.06 },
	})

	local stroke = object:FindFirstChildOfClass("UIStroke")
	if stroke then
		M.animate(stroke, { Color = colors.error, Transparency = 0.2 }, 0.08)
		Scheduler.Scheduler.after(object, "shakeFlash", 0.16, function()
			if stroke.Parent then
				M.animate(stroke, { Color = colors.accent, Transparency = Tokens.glow.restTransparency }, 0.18)
			end
		end)
	end
end

-- Thin animated highlight sweep across a Kit.progress fill bar.
function M.progressShimmer(fill)
	local gradient = fill:FindFirstChildOfClass("UIGradient")
	if not gradient then
		gradient = Primitives.create("UIGradient", fill, {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.45, 0.65),
				NumberSequenceKeypoint.new(0.55, 0.65),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
	end

	if not M.motion then
		return
	end

	gradient.Offset = Vector2.new(-1, 0)
	local tween = TweenService:Create(
		gradient,
		TweenInfo.new(1.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false),
		{ Offset = Vector2.new(1, 0) }
	)
	Scheduler.Scheduler.track(fill, "shimmer", tween)
	tween:Play()
end

-- One-shot celebratory glow on a Kit.progress track, for the moment a bar
-- crosses into full.
function M.progressFull(track)
	local glow = track:FindFirstChild("FullGlow")
	if not glow then
		glow = Primitives.create("UIStroke", track, {
			Name = "FullGlow",
			Color = colors.accent,
			Thickness = 0,
			Transparency = 0.3,
		})
		Scheduler.Theme.paint(glow, "Color", "accent")
	end

	M.animate(glow, { Thickness = 2 }, 0.16, Enum.EasingStyle.Back)
	Scheduler.Scheduler.after(track, "glowFade", 0.5, function()
		if glow.Parent then
			M.animate(glow, { Thickness = 0 }, 0.3)
		end
	end)
end

-- Continuous UIGradient animation for high-tier titles/headers: a moving
-- highlight sweep ("sheen"), a hue-cycling rotation ("rainbow"), or a
-- breathing glow-stroke pulse ("pulse").
function M.gradientAnimate(object, mode, options)
	options = options or {}
	local color = options.color or colors.accent

	Scheduler.Scheduler.clear(object, "gradient")

	if mode == "sheen" then
		local gradient = object:FindFirstChildOfClass("UIGradient")
		if not gradient then
			gradient = Primitives.create("UIGradient", object, {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.45, 0.65),
					NumberSequenceKeypoint.new(0.55, 0.65),
					NumberSequenceKeypoint.new(1, 1),
				}),
			})
		end
		gradient.Color = ColorSequence.new(color)

		if not M.motion then
			gradient.Offset = Vector2.new(0, 0)
			return gradient
		end

		gradient.Offset = Vector2.new(-1, 0)
		local tween = TweenService:Create(
			gradient,
			TweenInfo.new(1.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false),
			{ Offset = Vector2.new(1, 0) }
		)
		Scheduler.Scheduler.track(object, "gradient", tween)
		tween:Play()
		return gradient
	elseif mode == "rainbow" then
		local gradient = object:FindFirstChildOfClass("UIGradient")
		if not gradient then
			gradient = Primitives.create("UIGradient", object, {})
		end
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0.85, 1)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 0.85, 1)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 0.85, 1)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 0.85, 1)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 0.85, 1)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 0.85, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 0.85, 1)),
		})

		if not M.motion then
			gradient.Rotation = 0
			return gradient
		end

		local tween = TweenService:Create(
			gradient,
			TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false),
			{ Rotation = 360 }
		)
		Scheduler.Scheduler.track(object, "gradient", tween)
		tween:Play()
		return gradient
	elseif mode == "pulse" then
		local stroke = object:FindFirstChild("PulseGlow")
		if not stroke then
			stroke = Primitives.create("UIStroke", object, {
				Name = "PulseGlow",
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 2,
				Color = color,
			})
		end
		stroke.Color = color

		if not M.motion then
			stroke.Transparency = 1
			return stroke
		end

		stroke.Transparency = 0.2
		local tween = TweenService:Create(
			stroke,
			TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.85 }
		)
		Scheduler.Scheduler.track(object, "gradient", tween)
		tween:Play()
		return stroke
	end

	warn("Kit.gradientAnimate: unknown mode " .. tostring(mode))
	return nil
end

-- Small pooled burst of Frame-based particle dots (ParticleEmitter doesn't
-- render inside a ScreenGui) fired outward from the center of `card` and
-- fading out, for a one-shot celebratory accent on a milestone moment.
local confettiPools = setmetatable({}, { __mode = "k" }) -- card -> {dots}
local CONFETTI_COUNT = 6

function M.confetti(card, color)
	if not M.motion then
		return
	end

	color = color or colors.accent
	local pool = confettiPools[card]
	if not pool then
		pool = {}
		for index = 1, CONFETTI_COUNT do
			local dot = Primitives.create("Frame", card, {
				Name = "Confetti" .. index,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(5, 5),
				BackgroundColor3 = color,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = card.ZIndex + 2,
				Visible = false,
			})
			Primitives.corner(dot, 999)
			pool[index] = dot
		end
		confettiPools[card] = pool
		watch(card)
		card.Destroying:Connect(function()
			confettiPools[card] = nil
		end)
	end

	for index, dot in ipairs(pool) do
		local angle = (index - 1) / #pool * math.pi * 2 + math.random() * 0.6
		local distance = 26 + math.random() * 14
		local offset = Vector2.new(math.cos(angle), math.sin(angle)) * distance

		dot.BackgroundColor3 = color
		dot.BackgroundTransparency = 0
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.Visible = true

		M.animate(dot, {
			Position = UDim2.new(0.5, offset.X, 0.5, offset.Y),
			BackgroundTransparency = 1,
		}, 0.5 + math.random() * 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		Scheduler.Scheduler.after(dot, "confettiHide", 0.75, function()
			if dot.Parent then
				dot.Visible = false
			end
		end)
	end
end

-- A visible ring distinguishing true gamepad SELECTION from mouse HOVER.
-- Uses its own UIStroke instance rather than reusing an edge-glow stroke,
-- since M.animate/Scheduler track one in-flight tween per (object, key)
-- pair — sharing would make hover glow and focus ring fight over the same
-- slot instead of coexisting.
function M.focusRing(object)
	local ring = Primitives.create("UIStroke", object, {
		Name = "FocusRing",
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = colors.accent2,
		Thickness = 2,
		Transparency = 1,
	})
	Scheduler.Theme.paint(ring, "Color", "accent2")

	object.SelectionGained:Connect(function()
		M.animate(ring, { Transparency = 0.15, Thickness = 2.5 }, 0.16)
	end)
	object.SelectionLost:Connect(function()
		M.animate(ring, { Transparency = 1, Thickness = 2 }, 0.2)
	end)

	return ring
end

-- Continuous low-amplitude breathing glow on a card's edge, gated on
-- preferences.motion (glow ambience, not particles). Modeled on pulse()'s
-- lifecycle discipline: RepeatCount = -1, Reverses = true, returning a
-- handle with a stop() method and automatically cleaned up if `card` is
-- destroyed.
function M.ambientGlow(card, options)
	options = options or {}
	local color = options.color or colors.accent

	local stroke = card:FindFirstChild("AmbientGlow")
	if not stroke then
		stroke = Primitives.create("UIStroke", card, {
			Name = "AmbientGlow",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = options.thickness or 2,
			Color = color,
			Transparency = 1,
		})
	end
	stroke.Color = color

	local active = true
	local function stop()
		if not active then
			return
		end
		active = false
		Scheduler.Scheduler.clear(card, "ambientGlow")
		if stroke.Parent then
			stroke.Transparency = 1
		end
	end

	if not M.motion then
		stroke.Transparency = 1
		return { stop = stop }
	end

	stroke.Transparency = 0.92
	local tween = TweenService:Create(
		stroke,
		TweenInfo.new(options.period or 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = options.peak or 0.52 }
	)
	Scheduler.Scheduler.track(card, "ambientGlow", tween)
	tween:Play()

	watch(card)
	card.Destroying:Connect(stop)

	return { stop = stop }
end

-- Staggered cascade entrance for lists, cards, and grid items
function M.stagger(items, delayPerItem, preset)
	delayPerItem = delayPerItem or 0.035
	preset = preset or "smooth"

	for index, item in ipairs(items) do
		local scale = item:FindFirstChild("StaggerScale") or item:FindFirstChild("CardScale") or item:FindFirstChildOfClass("UIScale")
		if not scale then
			scale = Primitives.create("UIScale", item, { Name = "StaggerScale", Scale = 1 })
		end

		if not M.motion then
			scale.Scale = 1
			item.Visible = true
		else
			scale.Scale = 0.94
			item.Visible = true
			Scheduler.Scheduler.after(item, "stagger", (index - 1) * delayPerItem, function()
				if item.Parent then
					SpringDriver.animate(scale, "stagger", { Scale = 1 }, preset)
				end
			end)
		end
	end
end

-- Drifting floating text on user action / reward (e.g. "+1.2K COMPUTE", "DEPLOYED!")
function M.floatText(parent, text, color, startPos)
	if not M.motion then
		return
	end

	color = color or colors.accent
	startPos = startPos or UDim2.fromScale(0.5, 0.4)

	local label = Primitives.create("TextLabel", parent, {
		Name = "FloatText",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = startPos,
		Size = UDim2.fromOffset(200, 24),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.RobotoMono,
		TextSize = 15,
		TextColor3 = color,
		TextStrokeColor3 = colors.background,
		TextStrokeTransparency = 0.4,
		ZIndex = parent.ZIndex + 10,
	})

	local scale = Primitives.create("UIScale", label, { Scale = 0.85 })
	SpringDriver.animate(scale, "pop", { Scale = 1.08 }, "bouncy")

	local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset - 28)
	local tween = TweenService:Create(label, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = targetPos,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()

	Scheduler.Scheduler.after(label, "floatDestroy", 0.7, function()
		if label.Parent then
			label:Destroy()
		end
	end)
end

-- Epic celebratory fanfare with expanding shockwave ring and confetti burst
function M.fanfare(card, color)
	color = color or colors.accent

	if M.motion then
		local shockwave = Primitives.create("Frame", card, {
			Name = "Shockwave",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			ZIndex = card.ZIndex + 3,
		})
		Primitives.corner(shockwave, 999)
		local ring = Primitives.create("UIStroke", shockwave, {
			Color = color,
			Thickness = 3,
			Transparency = 0.1,
		})

		SpringDriver.animate(shockwave, "expand", { Size = UDim2.fromScale(1.4, 2.2) }, "bouncy")
		local fade = TweenService:Create(ring, TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Thickness = 0.5,
		})
		fade:Play()

		Scheduler.Scheduler.after(shockwave, "shockDestroy", 0.52, function()
			if shockwave.Parent then
				shockwave:Destroy()
			end
		end)
	end

	M.confetti(card, color)
end

-- Continuous rhythmic pulse on a border or highlight
function M.glowPulse(object, color, period)
	color = color or colors.accent
	local stroke = object:FindFirstChild("GlowPulse")
	if not stroke then
		stroke = Primitives.create("UIStroke", object, {
			Name = "GlowPulse",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 2.5,
			Color = color,
			Transparency = 0.9,
		})
	end
	stroke.Color = color

	if not M.motion then
		stroke.Transparency = 1
		return
	end

	local tween = TweenService:Create(
		stroke,
		TweenInfo.new(period or 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.35 }
	)
	Scheduler.Scheduler.track(object, "glowPulse", tween)
	tween:Play()
end

return M
