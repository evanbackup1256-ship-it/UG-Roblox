local ServerScriptService = game:GetService("ServerScriptService")

local Trove = require(ServerScriptService.DeckPackages.Trove)

local Framework = {}
Framework.__index = Framework

local function safeCall(service, method, ...)
	local callback = service[method]
	if type(callback) ~= "function" then
		return true
	end

	local arguments = table.pack(...)
	return xpcall(function()
		callback(service, table.unpack(arguments, 1, arguments.n))
	end, debug.traceback)
end

function Framework.new(name)
	assert(type(name) == "string" and #name > 0, "Framework requires a name")

	return setmetatable({
		name = name,
		state = "created",
		services = {},
		definitions = {},
		order = {},
		initialized = {},
		started = {},
		trove = Trove.new(),
	}, Framework)
end

function Framework:Register(name, service, dependencies)
	assert(self.state == "created", "Services must be registered before startup")
	assert(type(name) == "string" and #name > 0, "Service name is required")
	assert(type(service) == "table", "Service must be a table")
	assert(self.definitions[name] == nil, "Duplicate service: " .. name)

	self.definitions[name] = {
		service = service,
		dependencies = dependencies or {},
	}

	return service
end

function Framework:Get(name)
	local service = self.services[name]
	assert(service ~= nil, "Unknown service: " .. name)
	return service
end

function Framework:TryGet(name)
	return self.services[name]
end

function Framework:Track(item, cleanupMethod)
	return self.trove:Add(item, cleanupMethod)
end

function Framework:Connect(signal, callback)
	return self.trove:Connect(signal, callback)
end

function Framework:Spawn(callback, ...)
	local thread = task.spawn(callback, ...)
	self.trove:Add(thread)
	return thread
end

function Framework:_resolve(name, visiting)
	if self.initialized[name] then
		return
	end

	local definition = self.definitions[name]
	assert(definition ~= nil, "Unknown dependency: " .. name)
	assert(not visiting[name], "Circular service dependency: " .. name)

	visiting[name] = true
	for _, dependency in ipairs(definition.dependencies) do
		self:_resolve(dependency, visiting)
	end
	visiting[name] = nil

	self.services[name] = definition.service
	local ok, err = safeCall(definition.service, "Init", self)
	if not ok then
		self.services[name] = nil
		error(string.format("%s failed to initialize: %s", name, err), 0)
	end

	self.initialized[name] = true
	table.insert(self.order, name)
end

function Framework:Start()
	assert(self.state == "created", "Framework can only start once")
	self.state = "starting"

	local ok, err = xpcall(function()
		for name in self.definitions do
			self:_resolve(name, {})
		end

		for _, name in ipairs(self.order) do
			local service = self.services[name]
			local started, startError = safeCall(service, "Start")
			if not started then
				error(string.format("%s failed to start: %s", name, startError), 0)
			end
			self.started[name] = true
		end
	end, debug.traceback)

	if not ok then
		self:Destroy()
		error(err, 0)
	end

	self.state = "running"
	return self
end

function Framework:Destroy()
	if self.state == "destroyed" or self.state == "stopping" then
		return
	end

	self.state = "stopping"

	for index = #self.order, 1, -1 do
		local name = self.order[index]
		local service = self.services[name]
		if service then
			if self.started[name] then
				safeCall(service, "Stop")
			end
			safeCall(service, "Destroy")
		end
	end

	self.trove:Destroy()
	table.clear(self.services)
	table.clear(self.definitions)
	table.clear(self.order)
	table.clear(self.initialized)
	table.clear(self.started)
	self.state = "destroyed"
end

return Framework
