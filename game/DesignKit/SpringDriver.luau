local Motion = require(script.Parent.Parent.MotionService)
local spr = require(script.Parent.Vendor.spr)

-- Thin adapter over the real spr library (github.com/Fraktality/spr,
-- vendored in Vendor/spr.luau) — spr owns its own PreSimulation/
-- PostSimulation RunService connections and steps every active spring
-- itself, so this file runs no RenderStepped loop or registry of its
-- own. It keeps the same public shape (SpringDriver.animate/cancel,
-- returning a {Cancel = fn} handle) so Kit.Scheduler.track's duck-typed
-- :Cancel() handling and every M.animate call site need zero changes.
--
-- spr has no per-key concept — it tracks state by (instance, property)
-- only. Every call site in this codebase funnels through Motion.luau's
-- M.animate using the single literal key "animate" per object, so
-- collapsing SpringDriver's (object, key) cancellation down to spr's
-- (object) cancellation is safe today. If a future call site ever needs
-- two independently-keyed animations running concurrently on the same
-- object, that assumption breaks — flag it then, not here.
--
-- Animating a derived value (e.g. Kit.tickValue's displayed number) is
-- NOT handled here — spr.target only ever sets real Instance properties.
-- See ValueTicker.luau for that one case.
local SpringDriver = {}

-- Starts (or replaces) a spring-driven animation toward `properties` on
-- `object`. `presetName` indexes MotionService.Presets for
-- {frequency, damping}, translated into spr.target's
-- (dampingRatio, undampedFrequency) argument order. Returns a handle
-- with :Cancel() for Kit.Scheduler.track to hold.
function SpringDriver.animate(object, key, properties, presetName, onSettle)
	local preset = Motion.Presets[presetName] or Motion.Presets.snappy

	spr.target(object, preset.damping, preset.frequency, properties)

	if onSettle then
		spr.completed(object, onSettle)
	end

	return {
		Cancel = function()
			spr.stop(object)
		end,
	}
end

-- Cancels whatever's animating on `object` via spr. `key` is accepted
-- for call-site compatibility (Kit.Scheduler still passes it) but spr
-- has no key concept of its own — see the file-level comment above.
function SpringDriver.cancel(object, key)
	spr.stop(object)
end

return SpringDriver
