local TweenService = game:GetService("TweenService")
local Icons = require(script.Parent.Icons)

local Kit = {}

Kit.colors = {
	background = Color3.fromRGB(10, 15, 19),
	navigation = Color3.fromRGB(14, 21, 26),
	panel = Color3.fromRGB(20, 29, 35),
	raised = Color3.fromRGB(30, 42, 50),
	line = Color3.fromRGB(49, 65, 75),
	text = Color3.fromRGB(241, 246, 247),
	muted = Color3.fromRGB(145, 162, 171),
	accent = Color3.fromRGB(92, 231, 186),
	accent2 = Color3.fromRGB(112, 183, 255),
	warning = Color3.fromRGB(255, 200, 112),
	ink = Color3.fromRGB(7, 35, 29),
	paper = Color3.fromRGB(224, 241, 235),
	error = Color3.fromRGB(255, 177, 154),
}

Kit.motion = true
Kit.sound = function() end

--======================================================================--
-- Scheduler: unified lifecycle registry
--
-- Every tween and every delayed follow-up (task.delay) the kit creates on
-- behalf of an instance is registered here, keyed by that instance. The
-- moment the instance is destroyed, everything still in flight for it is
-- cancelled automatically. This is the one piece of infrastructure the
-- original module was missing: Kit.animate already cancelled a prior
-- tween on the same object, but nothing tracked or cancelled the
-- task.delay follow-ups that Kit.bump and the button ripple relied on,
-- so a destroyed instance could still have stale delayed work reference
-- it after the fact (harmless only because every call site happened to
-- re-check .Parent by hand). The scheduler makes that safety automatic
-- and uniform instead of something each call site has to remember.
--======================================================================--

Kit.Scheduler = {}

local owners = setmetatable({}, { __mode = "k" }) -- instance -> { [key] = {tween=, thread=} }
local watched = setmetatable({}, { __mode = "k" }) -- instance -> Destroying connection

local function bucket(object)
	local entries = owners[object]
	if not entries then
		entries = {}
		owners[object] = entries
	end
	return entries
end

local function releaseEntry(entry)
	if entry.tween then
		entry.tween:Cancel()
	end
	if entry.thread then
		task.cancel(entry.thread)
	end
end

local function watch(object)
	if watched[object] or typeof(object) ~= "Instance" then
		return
	end
	watched[object] = object.Destroying:Connect(function()
		Kit.Scheduler.clear(object)
		local connection = watched[object]
		watched[object] = nil
		if connection then
			connection:Disconnect()
		end
	end)
end

-- Registers a tween against (object, key), cancelling and replacing
-- whatever was previously registered under that same key.
function Kit.Scheduler.track(object, key, tween)
	watch(object)
	local entries = bucket(object)
	local previous = entries[key]
	if previous then
		releaseEntry(previous)
	end
	entries[key] = { tween = tween }
	return tween
end

-- Schedules callback after `seconds`, cancellable via the same (object,
-- key) pair a tween would use, and automatically cancelled if `object`
-- is destroyed before it fires.
function Kit.Scheduler.after(object, key, seconds, callback)
	watch(object)
	local entries = bucket(object)
	local previous = entries[key]
	if previous then
		releaseEntry(previous)
	end

	local slot = {}
	slot.thread = task.delay(seconds, function(...)
		if entries[key] == slot then
			entries[key] = nil
		end
		callback(...)
	end)
	entries[key] = slot
	return slot.thread
end

-- Cancels everything registered for `object` (all tweens and pending
-- delays), or just one `key` if given.
function Kit.Scheduler.clear(object, key)
	local entries = owners[object]
	if not entries then
		return
	end
	if key ~= nil then
		local entry = entries[key]
		if entry then
			releaseEntry(entry)
			entries[key] = nil
		end
		return
	end
	for _, entry in entries do
		releaseEntry(entry)
	end
	owners[object] = nil
end

--======================================================================--
-- Diagnostics: lightweight, off-by-default instrumentation for catching
-- leaks and runaway animation counts during development. Every counter
-- is purely additive bookkeeping — nothing here changes behavior when
-- Kit.Diagnostics.enabled is left false (the default).
--======================================================================--

Kit.Diagnostics = {
	enabled = false,
	counts = {
		instancesCreated = 0,
		tweensStarted = 0,
		delaysScheduled = 0,
	},
}

local function count(field)
	if Kit.Diagnostics.enabled then
		Kit.Diagnostics.counts[field] += 1
	end
end

function Kit.Diagnostics.snapshot()
	local out = {}
	for field, value in Kit.Diagnostics.counts do
		out[field] = value
	end
	return out
end

function Kit.Diagnostics.reset()
	for field in Kit.Diagnostics.counts do
		Kit.Diagnostics.counts[field] = 0
	end
end

--======================================================================--
-- Theme: live retinting.
--
-- Kit.colors is a flat table captured by value at the moment each label,
-- card, or button is built, so changing Kit.colors.accent later has no
-- effect on anything already on screen. Kit.Theme closes that gap: every
-- helper below that paints a semantic color also registers the instance,
-- property, and semantic name it used, so Kit.Theme.set can push a
-- palette change out to every live instance immediately. Kit.colors
-- itself is left completely untouched as a table, so any code reading
-- Kit.colors.accent directly keeps working exactly as before — this is
-- an additional capability, not a replacement for it.
--======================================================================--

Kit.Theme = { swatches = {} }

local painted = setmetatable({}, { __mode = "k" }) -- instance -> { [property] = swatchName }

-- Registers that `object[property]` should track semantic color
-- `swatchName` from now on. Also applies it immediately.
function Kit.Theme.paint(object, property, swatchName)
	if not Kit.colors[swatchName] then
		return
	end
	watch(object)
	local entries = painted[object]
	if not entries then
		entries = {}
		painted[object] = entries
	end
	entries[property] = swatchName
	object[property] = Kit.colors[swatchName]
end

-- Updates a named color both in Kit.colors (so future instances pick it
-- up the same way they always have) and across every live instance
-- previously painted with Kit.Theme.paint.
function Kit.Theme.set(swatchName, color3)
	Kit.colors[swatchName] = color3
	for object, entries in painted do
		for property, name in entries do
			if name == swatchName and object.Parent then
				object[property] = color3
			end
		end
	end
end

--======================================================================--
-- State: a minimal observable value, for the bind-a-list-of-callbacks
-- pattern that shows up throughout code built on this kit. Entirely
-- optional — nothing below requires it — but it gives callers a real
-- primitive instead of hand-rolling an array of refresh functions.
--======================================================================--

Kit.State = {}
local StateMeta = { __index = Kit.State }

function Kit.State.new(initial)
	return setmetatable({
		_value = initial,
		_subscribers = {},
	}, StateMeta)
end

function Kit.State:get()
	return self._value
end

function Kit.State:set(value)
	if value == self._value then
		return
	end
	self._value = value
	for _, subscriber in ipairs(self._subscribers) do
		subscriber(value)
	end
end

-- Returns an unsubscribe function.
function Kit.State:subscribe(callback, fireImmediately)
	table.insert(self._subscribers, callback)
	if fireImmediately then
		callback(self._value)
	end
	local subscribers = self._subscribers
	return function()
		local index = table.find(subscribers, callback)
		if index then
			table.remove(subscribers, index)
		end
	end
end

--======================================================================--
-- Primitive builders (unchanged public behavior)
--======================================================================--

function Kit.create(class, parent, properties)
	local object = Instance.new(class)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	object.Parent = parent
	count("instancesCreated")
	return object
end

function Kit.corner(object, radius)
	local existing = object:FindFirstChildOfClass("UICorner")
	if existing then
		existing.CornerRadius = UDim.new(0, radius or 12)
		return existing
	end
	return Kit.create("UICorner", object, {CornerRadius = UDim.new(0, radius or 12)})
end

function Kit.stroke(object, color, transparency)
	local stroke = Kit.create("UIStroke", object, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Color = color or Kit.colors.line,
		Transparency = transparency or 0,
	})
	return stroke
end

function Kit.text(parent, name, copy, size, color, bold)
	local label = Kit.create("TextLabel", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Text = copy,
		Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
		TextSize = size or 14,
		TextColor3 = color or Kit.colors.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, (size or 14) + 10),
	})
	return label
end

function Kit.place(object, x, y, width, height)
	local anchor = object.AnchorPoint
	object.Position = UDim2.fromOffset(x + width * anchor.X, y + height * anchor.Y)
	object.Size = UDim2.fromOffset(width, height)
	-- Invalidate any cached Kit.shake() anchor: this is a new true resting
	-- position, so a later shake must re-cache from here rather than
	-- animate back to wherever the object was before this layout pass.
	if object:GetAttribute("ShakeHome") ~= nil then
		object:SetAttribute("ShakeHome", nil)
	end
	return object
end

function Kit.card(parent, name, height, color)
	local card = Kit.create("Frame", parent, {
		Name = name,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = color or Kit.colors.panel,
		BorderSizePixel = 0,
	})
	Kit.corner(card, 8)
	local edge = Kit.stroke(card, Kit.colors.line, 0.58)
	local lift = Kit.create("UIScale", card, {Name = "CardLift", Scale = 1})
	card.Active = true
	card.MouseEnter:Connect(function()
		Kit.animate(lift, {Scale = 1.006}, 0.2, Enum.EasingStyle.Back)
		Kit.animate(edge, {Transparency = 0.36}, 0.2)
	end)
	card.MouseLeave:Connect(function()
		Kit.animate(lift, {Scale = 1}, 0.24, Enum.EasingStyle.Back)
		Kit.animate(edge, {Transparency = 0.58}, 0.24)
	end)
	return card
end

function Kit.icon(parent, name, key, color)
	local image = Kit.create("ImageLabel", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Image = Icons.asset(key),
		ImageColor3 = color or Kit.colors.muted,
		Size = UDim2.fromOffset(22, 22),
		ScaleType = Enum.ScaleType.Fit,
	})
	return image
end

-- A small rocket glyph built entirely from Frames/UICorner/UIStroke rather
-- than an image asset. Several Creator Store "rocket icon" decals were
-- tried for the Relaunch page and every one either didn't match the app's
-- thin-line style or turned out to have an opaque background that renders
-- as a solid block in-game (confirmed live in Studio) — this sidesteps
-- that entirely: no external asset to go missing, moderate, or render
-- wrong, and it always follows `color` exactly like the rest of the kit.
function Kit.rocketIcon(parent, name, color)
	local root = Kit.create("Frame", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(22, 22),
	})
	root:SetAttribute("ShapeIcon", true)

	local tint = color or Kit.colors.muted

	-- Every piece below is solid-filled (not outlined) so the glyph reads
	-- with the same bold, chunky weight as the rest of the icon set at
	-- this size — a 1px outline all but disappears at 22px next to solid
	-- shapes like the server-rack or chip icons.

	-- Body: a wide rounded capsule.
	local body = Kit.create("Frame", root, {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromOffset(10, 15),
		BackgroundColor3 = tint,
		BorderSizePixel = 0,
	})
	Kit.create("UICorner", body, { CornerRadius = UDim.new(1, 0) })

	-- Nose cap: a rotated square filling in a pointed tip above the body.
	local nose = Kit.create("Frame", root, {
		Name = "Nose",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromOffset(7, 7),
		Rotation = 45,
		BackgroundColor3 = tint,
		BorderSizePixel = 0,
	})
	Kit.create("UICorner", nose, { CornerRadius = UDim.new(0.2, 0) })

	-- Fins: two bold triangular wedges flaring out from the base, each
	-- built from a rotated square so it fills solid rather than outlining.
	for _, side in ipairs({ -1, 1 }) do
		local fin = Kit.create("Frame", root, {
			Name = if side < 0 then "FinLeft" else "FinRight",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + side * 0.27, 0.72),
			Size = UDim2.fromOffset(7, 7),
			Rotation = side * 45,
			BackgroundColor3 = tint,
			BorderSizePixel = 0,
		})
		Kit.create("UICorner", fin, { CornerRadius = UDim.new(0.15, 0) })
	end

	-- Exhaust: a short, wide flame tapering below the body.
	local flame = Kit.create("Frame", root, {
		Name = "Flame",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.86),
		Size = UDim2.fromOffset(5, 6),
		BackgroundColor3 = tint,
		BorderSizePixel = 0,
	})
	Kit.create("UICorner", flame, { CornerRadius = UDim.new(0.5, 0) })

	return root
end

-- Recolors an icon regardless of whether it's an ImageLabel from Kit.icon
-- (sets ImageColor3, same as every call site already did directly) or a
-- shape-built icon from Kit.rocketIcon (recolors every UIStroke and every
-- Frame with a solid fill among its descendants). Lets call sites like the
-- nav rail's active/inactive tint switch treat both kinds of icon the same
-- way without needing to know which one they were handed.
function Kit.tintIcon(icon, color)
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

--======================================================================--
-- Motion
--======================================================================--

function Kit.animate(object, properties, duration, style, direction)
	if not Kit.motion then
		Kit.Scheduler.clear(object, "animate")
		for key, value in pairs(properties) do
			object[key] = value
		end
		return
	end
	local tween = TweenService:Create(
		object,
		TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		properties
	)
	Kit.Scheduler.track(object, "animate", tween)
	tween:Play()
	count("tweensStarted")
	return tween
end

-- A small sequencing layer over Kit.animate: runs a list of
-- {object, properties, duration, style, direction} steps one after
-- another (each step waits for the previous tween's duration to
-- elapse), fully cancellable as a unit and automatically cleaned up if
-- `owner` is destroyed mid-sequence. Reduced motion collapses every
-- step to its final values instantly, same as Kit.animate does alone.
Kit.Motion = {}

function Kit.Motion.sequence(owner, key, steps)
	Kit.Scheduler.clear(owner, key)

	if not Kit.motion then
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

		local tween = Kit.animate(step.object, step.properties, step.duration, step.style, step.direction)
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

function Kit.bump(object, peak)
	if not object or not object.Parent then return end
	local scale = object:FindFirstChild("ValueBump")
	if not scale then
		scale = Kit.create("UIScale", object, {Name = "ValueBump", Scale = 1})
	end
	Kit.Motion.sequence(object, "bump", {
		{ object = scale, properties = {Scale = peak or 1.045}, duration = 0.12, style = Enum.EasingStyle.Back },
		{ object = scale, properties = {Scale = 1}, duration = 0.22, style = Enum.EasingStyle.Quint },
	})
end

-- peak = false updates the text without the pop animation, for values that
-- change on their own (e.g. an idle production tick) rather than because of
-- something the player just did.
function Kit.setValue(label, value, peak)
	if label.Text ~= value then
		label.Text = value
		if peak ~= false then
			Kit.bump(label, peak)
		end
	end
end

-- Card-level "locked" treatment: dims the whole card and shows a padlock
-- badge, layered on top of whatever Kit.enable already did to the action
-- button inside it. Distinct from "can't afford it right now" (which only
-- dims the button) — locked means the card is gated behind a requirement
-- the player hasn't met yet. Kit.card's hover handlers only ever touch
-- lift.Scale / edge.Transparency, never BackgroundTransparency, so this
-- doesn't fight hover. If the card's action button is passed as `button`,
-- it's tagged so clicking it while disabled plays the deeper "lock" denial
-- cue instead of the generic "denied" one.
function Kit.lock(card, locked, button)
	local badge = card:FindFirstChild("LockBadge")

	if button then
		button:SetAttribute("Locked", locked)
	end

	if not locked then
		if badge then
			Kit.animate(badge, { ImageTransparency = 1 }, 0.18)
		end
		Kit.animate(card, { BackgroundTransparency = 0 }, 0.18)
		return
	end

	if not badge then
		badge = Kit.create("ImageLabel", card, {
			Name = "LockBadge",
			Image = Icons.asset("lock"),
			ImageColor3 = Kit.colors.muted,
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			Size = UDim2.fromOffset(16, 16),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 14),
			ZIndex = 5,
		})
		Kit.Theme.paint(badge, "ImageColor3", "muted")
	end

	Kit.animate(badge, { ImageTransparency = 0 }, 0.18)
	Kit.animate(card, { BackgroundTransparency = 0.35 }, 0.18)
end

-- Short horizontal shake + red stroke flash, the visual companion to the
-- "denied" sound cue that already played on a disabled button click with
-- nothing to look at. Home position is cached on first use via an
-- attribute and every step targets that fixed anchor (never object.Position
-- read at call time), so overlapping or cancelled shakes can't leave the
-- button permanently offset.
function Kit.shake(object)
	if not Kit.motion then
		return
	end

	-- Cached on first shake so rapid re-clicks (each cancelling the last
	-- shake mid-tween) keep animating relative to the button's true rest
	-- position instead of drifting from wherever the cancelled tween left
	-- it. Kit.place() clears this attribute whenever it repositions the
	-- object (e.g. a window resize), so a stale home can't persist across
	-- a layout change either.
	local home = object:GetAttribute("ShakeHome")
	if not home then
		home = object.Position
		object:SetAttribute("ShakeHome", home)
	end

	Kit.Motion.sequence(object, "shake", {
		{ object = object, properties = { Position = home + UDim2.fromOffset(4, 0) }, duration = 0.05 },
		{ object = object, properties = { Position = home + UDim2.fromOffset(-3, 0) }, duration = 0.07 },
		{ object = object, properties = { Position = home }, duration = 0.06 },
	})

	local stroke = object:FindFirstChildOfClass("UIStroke")
	if stroke then
		Kit.animate(stroke, { Color = Kit.colors.error, Transparency = 0.2 }, 0.08)
		Kit.Scheduler.after(object, "shakeFlash", 0.16, function()
			if stroke.Parent then
				Kit.animate(stroke, { Color = Kit.colors.accent, Transparency = 1 }, 0.18)
			end
		end)
	end
end

-- Thin animated highlight sweep across a Kit.progress fill bar. Opt-in and
-- purely additive: Kit.progress's track/fill return values are unchanged,
-- so call sites that don't opt in are unaffected.
function Kit.progressShimmer(fill)
	local gradient = fill:FindFirstChildOfClass("UIGradient")
	if not gradient then
		gradient = Kit.create("UIGradient", fill, {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.45, 0.65),
				NumberSequenceKeypoint.new(0.55, 0.65),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
	end

	if not Kit.motion then
		return
	end

	gradient.Offset = Vector2.new(-1, 0)
	local tween = TweenService:Create(
		gradient,
		TweenInfo.new(1.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false),
		{ Offset = Vector2.new(1, 0) }
	)
	Kit.Scheduler.track(fill, "shimmer", tween)
	tween:Play()
end

-- One-shot celebratory glow on a Kit.progress track, for the moment a bar
-- crosses into full. Call only on the crossing (call sites track their own
-- "was full" flag), not on every update.
function Kit.progressFull(track)
	local glow = track:FindFirstChild("FullGlow")
	if not glow then
		glow = Kit.create("UIStroke", track, {
			Name = "FullGlow",
			Color = Kit.colors.accent,
			Thickness = 0,
			Transparency = 0.3,
		})
		Kit.Theme.paint(glow, "Color", "accent")
	end

	Kit.animate(glow, { Thickness = 2 }, 0.16, Enum.EasingStyle.Back)
	Kit.Scheduler.after(track, "glowFade", 0.5, function()
		if glow.Parent then
			Kit.animate(glow, { Thickness = 0 }, 0.3)
		end
	end)
end

-- A visible ring distinguishing true gamepad SELECTION from mouse HOVER.
-- Kit.button's SelectionGained handler reuses the same edge-glow as
-- MouseEnter, which reads ambiguous once a gamepad is in play — "is the
-- mouse here, or is this where my gamepad focus actually is?". This uses
-- its own UIStroke instance rather than reusing `edge`, since
-- Kit.animate/Kit.Scheduler track one in-flight tween per (object, key)
-- pair — sharing the stroke would make the hover glow and the focus ring
-- fight over the same "animate" slot instead of coexisting.
function Kit.focusRing(object)
	local ring = Kit.create("UIStroke", object, {
		Name = "FocusRing",
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Kit.colors.accent2,
		Thickness = 2,
		Transparency = 1,
	})
	Kit.Theme.paint(ring, "Color", "accent2")

	object.SelectionGained:Connect(function()
		Kit.animate(ring, { Transparency = 0.15, Thickness = 2.5 }, 0.16)
	end)
	object.SelectionLost:Connect(function()
		Kit.animate(ring, { Transparency = 1, Thickness = 2 }, 0.2)
	end)

	return ring
end

--======================================================================--
-- Controls
--======================================================================--

function Kit.button(parent, name, copy, callback, primary)
	local button = Kit.create("TextButton", parent, {
		Name = name,
		Text = copy,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = primary and Kit.colors.ink or Kit.colors.text,
		BackgroundColor3 = primary and Kit.colors.accent or Kit.colors.raised,
		Size = UDim2.fromOffset(160, 44),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Selectable = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	Kit.Theme.paint(button, "TextColor3", primary and "ink" or "text")
	Kit.Theme.paint(button, "BackgroundColor3", primary and "accent" or "raised")
	Kit.corner(button, 6)
	local edge = Kit.stroke(button, Kit.colors.accent, 1)
	Kit.Theme.paint(edge, "Color", "accent")
	Kit.focusRing(button)
	local scale = Kit.create("UIScale", button, {Scale = 1})
	button.ClipsDescendants = true
	local function hover()
		if button:GetAttribute("Disabled") then return end
		Kit.animate(edge, {Transparency = 0.18, Thickness = 1.5}, 0.2)
		Kit.animate(scale, {Scale = 1.024}, 0.24, Enum.EasingStyle.Back)
		Kit.sound("hover")
	end
	local function leave()
		Kit.animate(edge, {Transparency = 1, Thickness = 1}, 0.24)
		Kit.animate(scale, {Scale = 1}, 0.28, Enum.EasingStyle.Back)
	end
	button.MouseEnter:Connect(hover)
	button.MouseLeave:Connect(leave)
	button.SelectionGained:Connect(hover)
	button.SelectionLost:Connect(leave)
	button.MouseButton1Down:Connect(function()
		if button:GetAttribute("Disabled") then return end
		Kit.sound("press")
		Kit.animate(scale, {Scale = 0.955}, 0.09)
	end)
	button.MouseButton1Up:Connect(function()
		if button:GetAttribute("Disabled") then return end
		Kit.sound("release")
		Kit.animate(scale, {Scale = 1.024}, 0.18, Enum.EasingStyle.Back)
		Kit.animate(edge, {Transparency = 0.18}, 0.14)
	end)
	button.Activated:Connect(function()
		if button:GetAttribute("Disabled") then
			Kit.sound(if button:GetAttribute("Locked") then "lock" else "denied")
			Kit.shake(button)
			return
		end
		Kit.sound(if primary then "confirm" else "click")
		local pulse = Kit.create("Frame", button, {
			Name = "Pulse",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = primary and Kit.colors.ink or Kit.colors.accent,
			BackgroundTransparency = 0.72,
			BorderSizePixel = 0,
			ZIndex = button.ZIndex + 1,
		})
		Kit.Theme.paint(pulse, "BackgroundColor3", primary and "ink" or "accent")
		Kit.corner(pulse, 999)
		Kit.animate(pulse, {Size = UDim2.fromScale(1.35, 2.4), BackgroundTransparency = 1}, 0.42)
		Kit.Scheduler.after(pulse, "destroy", 0.44, function()
			if pulse.Parent then
				pulse:Destroy()
			end
		end)
		callback()
	end)
	return button
end

function Kit.enable(button, enabled, copy, primary)
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
	button.TextColor3 = Kit.colors[textColor]
	button.BackgroundColor3 = Kit.colors[backgroundColor]

	button.Active = enabled
	if not enabled then
		local scale = button:FindFirstChildOfClass("UIScale")
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if scale then Kit.animate(scale, {Scale = 1}, 0.16) end
		if stroke then Kit.animate(stroke, {Transparency = 1, Thickness = 1}, 0.16) end
	end
end

function Kit.progress(parent, name)
	local track = Kit.create("Frame", parent, {
		Name = name,
		BorderSizePixel = 0,
		BackgroundColor3 = Kit.colors.raised,
		Size = UDim2.new(1, 0, 0, 4),
	})
	Kit.Theme.paint(track, "BackgroundColor3", "raised")
	Kit.corner(track, 2)
	local fill = Kit.create("Frame", track, {
		Name = "Fill",
		BackgroundColor3 = Kit.colors.accent,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	})
	Kit.Theme.paint(fill, "BackgroundColor3", "accent")
	Kit.corner(fill, 2)
	return track, fill
end

function Kit.input(parent, name, placeholder)
	local field = Kit.create("TextBox", parent, {
		Name = name,
		Text = "",
		PlaceholderText = placeholder,
		PlaceholderColor3 = Kit.colors.muted,
		TextColor3 = Kit.colors.text,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		BackgroundColor3 = Kit.colors.background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
	})
	Kit.Theme.paint(field, "PlaceholderColor3", "muted")
	Kit.Theme.paint(field, "TextColor3", "text")
	Kit.Theme.paint(field, "BackgroundColor3", "background")
	Kit.corner(field, 6)
	local edge = Kit.stroke(field, Kit.colors.line, 0.4)
	Kit.Theme.paint(edge, "Color", "line")
	Kit.create("UIPadding", field, {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)})
	field.Focused:Connect(function()
		Kit.animate(edge, {Color = Kit.colors.accent, Transparency = 0.15, Thickness = 1.25}, 0.16)
		Kit.sound("input")
	end)
	field.FocusLost:Connect(function()
		Kit.animate(edge, {Color = Kit.colors.line, Transparency = 0.4, Thickness = 1}, 0.18)
		Kit.sound("release")
	end)
	return field
end

return Kit
