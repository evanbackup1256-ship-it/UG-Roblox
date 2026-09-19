local RunService = game:GetService("RunService")

local Motion = require(script.Parent.Parent.MotionService)

-- Shared spring-driven animation engine: one lazily-created RenderStepped
-- connection steps every active animation across the whole UI, rather than
-- each caller managing its own per-frame loop (the same centralize-instead-
-- of-per-object-loop discipline Kit.Scheduler already uses for cleanup, and
-- the deleted Kit.smush primitive used for its one property — this
-- generalizes that same pattern to arbitrary property types instead of
-- just UIScale.Scale).
local SpringDriver = {}

local EPSILON = 0.001
local EPSILON_VELOCITY = 0.001

-- object -> { [key] = entry }
-- entry = { springs = {propName -> {kind, spring OR springX/springY/springZ}},
--           targets = {propName -> value}, onStep, onSettle, cancelled }
local entries = setmetatable({}, { __mode = "k" })
local connection = nil

local function settledNumber(spring, target)
	return math.abs(spring.value - target) < EPSILON and math.abs(spring.velocity) < EPSILON_VELOCITY
end

-- UDim2 has 4 numeric components; driven as two independent scalar-pairs
-- (Scale.X/Scale.Y, Offset.X/Offset.Y) via raw Spring instances rather than
-- MotionService.vectorSpring, since vectorSpring's closure doesn't expose
-- .value/.velocity for the settle check below.
local function newUDim2Springs(current, frequency, damping)
	return {
		scaleX = Motion.Spring.new(current.X.Scale, frequency, damping),
		scaleY = Motion.Spring.new(current.Y.Scale, frequency, damping),
		offsetX = Motion.Spring.new(current.X.Offset, frequency, damping),
		offsetY = Motion.Spring.new(current.Y.Offset, frequency, damping),
	}
end

local function stepUDim2(springs, target, dt)
	local scaleX = springs.scaleX:Step(target.X.Scale, dt)
	local scaleY = springs.scaleY:Step(target.Y.Scale, dt)
	local offsetX = springs.offsetX:Step(target.X.Offset, dt)
	local offsetY = springs.offsetY:Step(target.Y.Offset, dt)
	return UDim2.new(scaleX, offsetX, scaleY, offsetY)
end

local function settledUDim2(springs, target)
	return settledNumber(springs.scaleX, target.X.Scale)
		and settledNumber(springs.scaleY, target.Y.Scale)
		and settledNumber(springs.offsetX, target.X.Offset)
		and settledNumber(springs.offsetY, target.Y.Offset)
end

-- Color3 driven as three independent scalar springs over R/G/B — linear-RGB
-- interpolation, matching Roblox's own default TweenService Color3
-- behavior, not a regression from switching to springs.
local function newColor3Springs(current, frequency, damping)
	return {
		r = Motion.Spring.new(current.R, frequency, damping),
		g = Motion.Spring.new(current.G, frequency, damping),
		b = Motion.Spring.new(current.B, frequency, damping),
	}
end

local function stepColor3(springs, target, dt)
	local r = math.clamp(springs.r:Step(target.R, dt), 0, 1)
	local g = math.clamp(springs.g:Step(target.G, dt), 0, 1)
	local b = math.clamp(springs.b:Step(target.B, dt), 0, 1)
	return Color3.new(r, g, b)
end

local function settledColor3(springs, target)
	return settledNumber(springs.r, target.R)
		and settledNumber(springs.g, target.G)
		and settledNumber(springs.b, target.B)
end

local function bucket(object)
	local keyed = entries[object]
	if not keyed then
		keyed = {}
		entries[object] = keyed
	end
	return keyed
end

local function ensureConnection()
	if not connection then
		connection = RunService.RenderStepped:Connect(function(dt)
			SpringDriver._step(dt)
		end)
	end
end

local function stopConnectionIfIdle()
	if connection and next(entries) == nil then
		connection:Disconnect()
		connection = nil
	end
end

function SpringDriver._step(dt)
	for object, keyed in entries do
		for key, entry in pairs(keyed) do
			local settled = true

			for propName, kind in pairs(entry.kind) do
				local target = entry.targets[propName]
				local spring = entry.springs[propName]

				if kind == "number" then
					local value = spring:Step(target, dt)
					if entry.onStep then
						entry.onStep(propName, value)
					elseif object then
						object[propName] = value
					end
					if not settledNumber(spring, target) then
						settled = false
					end
				elseif kind == "UDim2" then
					local value = stepUDim2(spring, target, dt)
					if object then
						object[propName] = value
					end
					if not settledUDim2(spring, target) then
						settled = false
					end
				elseif kind == "Color3" then
					local value = stepColor3(spring, target, dt)
					if object then
						object[propName] = value
					end
					if not settledColor3(spring, target) then
						settled = false
					end
				end
			end

			if settled then
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

	stopConnectionIfIdle()
end

-- Cancels whatever's tracked under (object, key), if anything.
function SpringDriver.cancel(object, key)
	local keyed = entries[object]
	if keyed then
		keyed[key] = nil
		if next(keyed) == nil then
			entries[object] = nil
		end
	end
end

-- Starts (or replaces) a spring-driven animation toward `properties` on
-- `object`, tracked under `key` (so a second call with the same key
-- replaces the first, same one-in-flight-per-key discipline Kit.Scheduler
-- already enforces for tweens). `presetName` indexes MotionService.Presets.
-- Returns a handle with :Cancel() for Kit.Scheduler.track to hold.
function SpringDriver.animate(object, key, properties, presetName, onSettle)
	local preset = Motion.Presets[presetName] or Motion.Presets.snappy
	local keyed = bucket(object)

	local kind = {}
	local targets = {}
	local springs = {}

	for propName, target in pairs(properties) do
		targets[propName] = target
		local current = object[propName]
		local valueType = typeof(current)

		if valueType == "number" then
			kind[propName] = "number"
			springs[propName] = Motion.Spring.new(current, preset.frequency, preset.damping)
		elseif valueType == "UDim2" then
			kind[propName] = "UDim2"
			springs[propName] = newUDim2Springs(current, preset.frequency, preset.damping)
		elseif valueType == "Color3" then
			kind[propName] = "Color3"
			springs[propName] = newColor3Springs(current, preset.frequency, preset.damping)
		else
			warn(("SpringDriver.animate: unsupported property type %s for %s"):format(valueType, propName))
		end
	end

	keyed[key] = {
		kind = kind,
		targets = targets,
		springs = springs,
		onSettle = onSettle,
	}

	ensureConnection()

	return {
		Cancel = function()
			SpringDriver.cancel(object, key)
		end,
	}
end

-- Variant of SpringDriver.animate for driving a derived value (e.g. a
-- displayed number ticking toward a target) via a callback each frame,
-- rather than assigning directly to a Roblox Instance property. Reuses the
-- same registry/connection — Kit.tickValue's number-ticking rides this,
-- not a second RenderStepped connection. `currentValue` seeds a fresh
-- spring the first time this (object, key) pair animates; every
-- subsequent call while still in flight reuses the same spring instance
-- (so its current position/velocity carry over — a mid-tick retarget
-- continues smoothly rather than jumping back to `currentValue`).
function SpringDriver.animateNumber(object, key, currentValue, target, presetName, onStep, onSettle)
	local preset = Motion.Presets[presetName] or Motion.Presets.smooth
	local keyed = bucket(object)

	local existing = keyed[key]
	local spring
	if existing and existing.kind.value == "number" then
		spring = existing.springs.value
	else
		spring = Motion.Spring.new(currentValue, preset.frequency, preset.damping)
	end

	keyed[key] = {
		kind = { value = "number" },
		targets = { value = target },
		springs = { value = spring },
		onStep = function(_, value)
			onStep(value)
		end,
		onSettle = onSettle,
	}

	ensureConnection()

	return {
		Cancel = function()
			SpringDriver.cancel(object, key)
		end,
	}
end

return SpringDriver
