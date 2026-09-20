local RunService = game:GetService("RunService")

local Motion = require(script.Parent.Parent.MotionService)

-- Drives a derived display value (e.g. the number backing a formatted
-- TextLabel.Text) toward a target via a callback each frame, rather than
-- assigning directly to a real Instance property. This exists because spr
-- (Vendor/spr.luau, driving every other animation in DesignKit via
-- SpringDriver.luau) can only ever set actual Instance properties — it has
-- no concept of "animate this number and hand me each intermediate value."
-- A single shared RunService.Heartbeat connection steps every in-flight
-- ticker, the same centralize-instead-of-per-object-loop discipline
-- SpringDriver/Scheduler already use elsewhere in this kit.
local ValueTicker = {}

local EPSILON = 0.001
local EPSILON_VELOCITY = 0.001

-- object -> { [key] = { spring, target, onStep, onSettle } }
local entries = setmetatable({}, { __mode = "k" })
local connection = nil

local function settled(spring, target)
	return math.abs(spring.value - target) < EPSILON and math.abs(spring.velocity) < EPSILON_VELOCITY
end

local function bucket(object)
	local keyed = entries[object]
	if not keyed then
		keyed = {}
		entries[object] = keyed
	end
	return keyed
end

local function step(dt)
	for object, keyed in entries do
		for key, entry in pairs(keyed) do
			local value = entry.spring:Step(entry.target, dt)
			if entry.onStep then
				entry.onStep(value)
			end
			if settled(entry.spring, entry.target) then
				keyed[key] = nil
				if entry.onSettle then
					entry.onSettle()
				end
			end
		end
		if next(keyed) == nil then
			entries[object] = nil
		end
	end

	if connection and next(entries) == nil then
		connection:Disconnect()
		connection = nil
	end
end

local function ensureConnection()
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
end

-- Starts (or retargets, mid-flight) a tick toward `target` on (object, key).
-- `currentValue` seeds a fresh spring the first time this pair animates;
-- a retarget while already in flight reuses the same spring (position and
-- velocity carry over, so it continues smoothly rather than jumping back
-- to `currentValue`). `onStep(value)` fires every frame with the current
-- interpolated number; `onSettle()` fires once when it settles.
function ValueTicker.animate(object, key, currentValue, target, presetName, onStep, onSettle)
	local preset = Motion.Presets[presetName] or Motion.Presets.smooth
	local keyed = bucket(object)

	local existing = keyed[key]
	local spring
	if existing then
		spring = existing.spring
	else
		spring = Motion.Spring.new(currentValue, preset.frequency, preset.damping)
	end

	keyed[key] = {
		spring = spring,
		target = target,
		onStep = onStep,
		onSettle = onSettle,
	}

	ensureConnection()

	return {
		Cancel = function()
			local live = entries[object]
			if live then
				live[key] = nil
			end
		end,
	}
end

function ValueTicker.cancel(object, key)
	local keyed = entries[object]
	if keyed then
		keyed[key] = nil
	end
end

return ValueTicker
