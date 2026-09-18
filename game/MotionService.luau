local MotionService = {}

----------------------------------------------------------------------
-- Spring (analytic semi-implicit integrator)
----------------------------------------------------------------------

local Spring = {}
Spring.__index = Spring

function Spring.new(value, frequency, damping)
	return setmetatable({
		value = value or 0,
		velocity = 0,
		frequency = frequency or 14,
		damping = damping or 1,
	}, Spring)
end

function Spring:Step(target, delta)
	if delta <= 0 then
		return self.value
	end

	local omega = self.frequency * math.pi * 2
	local ratio = math.max(0.01, self.damping) -- never allow zero or negative damping
	local offset = self.value - target
	local velocity = self.velocity

	-- Under-damped (oscillatory)
	if ratio < 0.999 then
		local dampedOmega = omega * math.sqrt(math.max(0, 1 - ratio * ratio))
		local decay = math.exp(-ratio * omega * delta)
		local cosine = math.cos(dampedOmega * delta)
		local sine = math.sin(dampedOmega * delta)
		local coefficient = ratio * omega / dampedOmega

		local displacement = decay * (
			offset * (cosine + coefficient * sine) +
				velocity * sine / dampedOmega
		)

		self.velocity = decay * (
			velocity * (cosine - coefficient * sine) -
				offset * (omega * omega / dampedOmega) * sine
		)

		self.value = target + displacement

		-- Critically damped (or extremely close)
	elseif ratio < 1.001 then
		local decay = math.exp(-omega * delta)
		local temporary = (velocity + omega * offset) * delta

		self.value = target + (offset + temporary) * decay
		self.velocity = (velocity - omega * temporary) * decay

		-- Over-damped
	else
		local root = math.sqrt(ratio * ratio - 1)
		local firstRate = -omega * (ratio - root)
		local secondRate = -omega * (ratio + root)

		local firstWeight = (velocity - secondRate * offset) / (firstRate - secondRate)
		local secondWeight = offset - firstWeight

		local first = firstWeight * math.exp(firstRate * delta)
		local second = secondWeight * math.exp(secondRate * delta)

		self.value = target + first + second
		self.velocity = first * firstRate + second * secondRate
	end

	return self.value
end

----------------------------------------------------------------------
-- Public helpers
----------------------------------------------------------------------

function MotionService.vectorSpring(frequency, damping)
	local x = Spring.new(0, frequency, damping)
	local y = Spring.new(0, frequency, damping)

	return {
		Step = function(_, target, delta)
			return Vector2.new(
				x:Step(target.X, delta),
				y:Step(target.Y, delta)
			)
		end,

		Reset = function(_, value)
			x.value = value.X
			y.value = value.Y
			x.velocity = 0
			y.velocity = 0
		end,
	}
end

-- Simple exponential decay (no overshoot)
function MotionService.damped(value, target, delta, speed)
	return value + (target - value) * (1 - math.exp(-(speed or 16) * delta))
end

return MotionService