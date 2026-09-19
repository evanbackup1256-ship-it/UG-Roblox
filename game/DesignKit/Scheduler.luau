local Tokens = require(script.Parent.Tokens)

local M = {}

--======================================================================--
-- Scheduler: unified lifecycle registry
--
-- Every tween and every delayed follow-up (task.delay) the kit creates on
-- behalf of an instance is registered here, keyed by that instance. The
-- moment the instance is destroyed, everything still in flight for it is
-- cancelled automatically.
--======================================================================--

M.Scheduler = {}

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
	if entry.cancel then
		entry.cancel()
	end
	if entry.thread then
		task.cancel(entry.thread)
	end
end

-- Registers `object`'s Destroying connection once (idempotent), so any
-- module in the kit can call this to get automatic cleanup without
-- juggling its own per-object connection bookkeeping.
local function watch(object)
	if watched[object] or typeof(object) ~= "Instance" then
		return
	end
	watched[object] = object.Destroying:Connect(function()
		M.Scheduler.clear(object)
		local connection = watched[object]
		watched[object] = nil
		if connection then
			connection:Disconnect()
		end
	end)
end

-- Registers a cancellable animation against (object, key), cancelling and
-- replacing whatever was previously registered under that same key.
-- `cancellable` is either a real Tween instance (still used by the
-- infinite-loop TweenService effects — gradientAnimate's sheen/rainbow/
-- pulse, progressShimmer) or any table exposing a :Cancel() method (a
-- SpringDriver.animate handle). Either way this file only ever needs to
-- know "can I cancel this", never which kind it is — so every existing
-- caller of Scheduler.track(object, key, tween) keeps working unchanged
-- regardless of which animation engine produced what it's passing in.
function M.Scheduler.track(object, key, cancellable)
	watch(object)
	local entries = bucket(object)
	local previous = entries[key]
	if previous then
		releaseEntry(previous)
	end

	local cancel
	if typeof(cancellable) == "Instance" then
		cancel = function()
			cancellable:Cancel()
		end
	elseif type(cancellable) == "table" and type(cancellable.Cancel) == "function" then
		cancel = function()
			cancellable:Cancel()
		end
	end

	entries[key] = { cancel = cancel }
	return cancellable
end

-- Schedules callback after `seconds`, cancellable via the same (object,
-- key) pair a tween would use, and automatically cancelled if `object`
-- is destroyed before it fires.
function M.Scheduler.after(object, key, seconds, callback)
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
function M.Scheduler.clear(object, key)
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
-- leaks and runaway animation counts during development.
--======================================================================--

M.Diagnostics = {
	enabled = false,
	counts = {
		instancesCreated = 0,
		tweensStarted = 0,
		delaysScheduled = 0,
	},
}

local function count(field)
	if M.Diagnostics.enabled then
		M.Diagnostics.counts[field] += 1
	end
end

function M.Diagnostics.snapshot()
	local out = {}
	for field, value in M.Diagnostics.counts do
		out[field] = value
	end
	return out
end

function M.Diagnostics.reset()
	for field in M.Diagnostics.counts do
		M.Diagnostics.counts[field] = 0
	end
end

--======================================================================--
-- Theme: live retinting.
--
-- Kit.colors is a flat table captured by value at the moment each label,
-- card, or button is built, so changing Kit.colors.accent later has no
-- effect on anything already on screen. Kit.Theme closes that gap: every
-- helper that paints a semantic color also registers the instance,
-- property, and semantic name it used, so Kit.Theme.set can push a
-- palette change out to every live instance immediately.
--======================================================================--

M.Theme = { swatches = {} }

local painted = setmetatable({}, { __mode = "k" }) -- instance -> { [property] = swatchName }

function M.Theme.paint(object, property, swatchName)
	if not Tokens.colors[swatchName] then
		return
	end
	watch(object)
	local entries = painted[object]
	if not entries then
		entries = {}
		painted[object] = entries
	end
	entries[property] = swatchName
	object[property] = Tokens.colors[swatchName]
end

function M.Theme.set(swatchName, color3)
	Tokens.colors[swatchName] = color3
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
-- pattern used throughout code built on this kit.
--======================================================================--

M.State = {}
local StateMeta = { __index = M.State }

function M.State.new(initial)
	return setmetatable({
		_value = initial,
		_subscribers = {},
	}, StateMeta)
end

function M.State:get()
	return self._value
end

function M.State:set(value)
	if value == self._value then
		return
	end
	self._value = value
	for _, subscriber in ipairs(self._subscribers) do
		subscriber(value)
	end
end

function M.State:subscribe(callback, fireImmediately)
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

-- Internal helpers other DesignKit modules need directly.
M._bucket = bucket
M._watch = watch
M._count = count

return M
