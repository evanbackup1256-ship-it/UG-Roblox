--!strict
-- Springs: High-craft physical spring kinetics engine for the App framework
local spr = require(script.Parent.Vendor.spr)
local Theme = require(script.Parent.Theme)

local Springs = {}
Springs.motionEnabled = true

function Springs.setMotionEnabled(enabled: boolean)
	Springs.motionEnabled = enabled
end

local function getPreset(name: string?)
	if name and Theme.springs[name] then
		return Theme.springs[name]
	end
	return Theme.springs.snappy
end

-- Core spring animation driver
function Springs.target(instance: Instance, properties: { [string]: any }, presetName: string?, onComplete: (() -> ())?)
	if not Springs.motionEnabled then
		-- Instant apply if reduced motion is preferred
		for prop, val in properties do
			pcall(function()
				(instance :: any)[prop] = val
			end)
		end
		if onComplete then
			task.spawn(onComplete)
		end
		return
	end

	local preset = getPreset(presetName)
	spr.target(instance, preset.damping, preset.frequency, properties)

	if onComplete then
		spr.completed(instance, onComplete)
	end
end

-- Stop active spring
function Springs.stop(instance: Instance, property: string?)
	spr.stop(instance, property)
end

-- Tactile micro-compression feedback on press (Scale: 0.95)
function Springs.press(instance: Instance, scaleFactor: number?)
	local scale = instance:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "SpringScale"
		scale.Scale = 1
		scale.Parent = instance
	end
	Springs.target(scale, { Scale = scaleFactor or 0.96 }, "snappy")
end

-- Tactile overshoot restore on release (Scale: 1.00)
function Springs.release(instance: Instance)
	local scale = instance:FindFirstChildOfClass("UIScale")
	if scale then
		Springs.target(scale, { Scale = 1.0 }, "bouncy")
	end
end

-- Subtle hover elevation feedback
function Springs.hover(instance: Instance, isHovered: boolean, hoverScale: number?)
	local scale = instance:FindFirstChildOfClass("UIScale")
	if isHovered then
		if not scale then
			scale = Instance.new("UIScale")
			scale.Name = "SpringScale"
			scale.Scale = 1
			scale.Parent = instance
		end
		Springs.target(scale, { Scale = hoverScale or 1.02 }, "smooth")
	else
		if scale then
			Springs.target(scale, { Scale = 1.0 }, "smooth")
		end
	end
end

-- Exponential frame-rate-independent smoothing
function Springs.damped(current: number, target: number, delta: number, rate: number?): number
	local blend = 1 - math.exp(-(rate or 6) * delta)
	local value = current + (target - current) * blend
	if math.abs(target - value) < 0.0005 then
		return target
	end
	return value
end

return Springs
