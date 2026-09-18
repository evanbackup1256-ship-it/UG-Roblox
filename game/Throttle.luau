local Throttle = {}
Throttle.__index = Throttle

function Throttle.new()
	return setmetatable({
		buckets = {},
	}, Throttle)
end

function Throttle:Consume(bucket, subject, capacity, refillPerSecond, cost)
	assert(capacity > 0 and refillPerSecond > 0, "Throttle capacity and refill must be positive")

	local group = self.buckets[bucket]
	if not group then
		group = {}
		self.buckets[bucket] = group
	end

	local now = os.clock()
	local entry = group[subject]
	if not entry then
		entry = {tokens = capacity, at = now}
		group[subject] = entry
	end

	entry.tokens = math.min(capacity, entry.tokens + (now - entry.at) * refillPerSecond)
	entry.at = now

	local required = cost or 1
	if entry.tokens < required then
		return false
	end

	entry.tokens -= required
	return true
end

function Throttle:Forget(subject)
	for _, group in self.buckets do
		group[subject] = nil
	end
end

return Throttle
