-- DesignKit: assembles the shared UI toolkit (Kit.*) from its sibling
-- modules into the same flat table shape every page/controller consumes,
-- so `require(script.Parent.DesignKit)` behaves identically to before this
-- was split into a folder. See the sibling files for what moved where:
-- Tokens (palette/radius/glow/type), Scheduler (lifecycle + theme + state),
-- Primitives (create/corner/stroke/text/place/card/icon), Motion (animate/
-- sequence/bump/shake/gradientAnimate/confetti/focusRing), Button (the
-- variant-table Kit.button + Kit.enable), Controls (checkbox/progress/input).
local Tokens = require(script.Tokens)
local Scheduler = require(script.Scheduler)
local Primitives = require(script.Primitives)
local Motion = require(script.Motion)
local Controls = require(script.Controls)
local ButtonModule = require(script.Button)

local Kit = {}

-- Tokens
Kit.colors = Tokens.colors
Kit.radius = Tokens.radius
Kit.glow = Tokens.glow
Kit.type = Tokens.type

-- Scheduler / Theme / State / Diagnostics
Kit.Scheduler = Scheduler.Scheduler
Kit.Theme = Scheduler.Theme
Kit.State = Scheduler.State
Kit.Diagnostics = Scheduler.Diagnostics

-- Primitives
Kit.create = Primitives.create
Kit.corner = Primitives.corner
Kit.stroke = Primitives.stroke
Kit.text = Primitives.text
Kit.place = Primitives.place
Kit.card = Primitives.card
Kit.icon = Primitives.icon
Kit.rocketIcon = Primitives.rocketIcon
Kit.tintIcon = Primitives.tintIcon

-- Motion / effects
Kit.animate = Motion.animate
Kit.Motion = Motion.Motion
Kit.bump = Motion.bump
Kit.setValue = Motion.setValue
Kit.lock = Motion.lock
Kit.shake = Motion.shake
Kit.progressShimmer = Motion.progressShimmer
Kit.progressFull = Motion.progressFull
Kit.gradientAnimate = Motion.gradientAnimate
Kit.confetti = Motion.confetti
Kit.focusRing = Motion.focusRing

-- Controls
Kit.button = ButtonModule.button
Kit.enable = ButtonModule.enable
Kit.checkbox = Controls.checkbox
Kit.progress = Controls.progress
Kit.input = Controls.input

-- Kit.sound: a stub overwritten at runtime by InterfaceController's real
-- pooled/pitched cue system. Both Button and Controls read the sound hook
-- through ButtonModule.sound (Controls requires Button directly for this),
-- so assigning Kit.sound = fn must update ButtonModule.sound for the
-- override to actually reach both.
setmetatable(Kit, {
	__newindex = function(t, key, value)
		if key == "sound" then
			ButtonModule.sound = value
		elseif key == "motion" then
			Motion.motion = value
		end
		rawset(t, key, value)
	end,
})
Kit.sound = function() end
Kit.motion = true

return Kit
