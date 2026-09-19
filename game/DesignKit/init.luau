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

-- Kit.sound / Kit.motion: both need every WRITE (not just the first) to
-- propagate into the module that actually owns the real value —
-- ButtonModule.sound (read by Button.luau/Controls.luau's effects) and
-- Motion.motion (read by every M.animate-based effect's reduced-motion
-- check). A plain __newindex metamethod only fires the FIRST time a key
-- is assigned (Lua only consults __newindex when the key is absent from
-- the table — once rawset makes it present, every later assignment
-- bypasses the metamethod entirely and just overwrites the table field).
-- Since InterfaceController.luau reassigns Kit.motion on every settings
-- change (refreshPresentation), that would silently stop propagating
-- after the very first assignment. __index + __newindex together make
-- these two keys live entirely in the backing modules, with no table
-- field of their own to go stale.
setmetatable(Kit, {
	__index = function(_, key)
		if key == "sound" then
			return ButtonModule.sound
		elseif key == "motion" then
			return Motion.motion
		end
		return nil
	end,
	__newindex = function(_, key, value)
		if key == "sound" then
			ButtonModule.sound = value
		elseif key == "motion" then
			Motion.motion = value
		else
			rawset(Kit, key, value)
		end
	end,
})

return Kit
