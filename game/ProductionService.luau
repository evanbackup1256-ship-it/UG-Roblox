local RunService = game:GetService("RunService")

local ProductionService = {}
ProductionService.__index = ProductionService

function ProductionService.new(config, stateService, sessions)
	return setmetatable({
		config = config,
		stateService = stateService,
		sessions = sessions,
		app = nil,
		accumulator = 0,
		interval = 0.5,
	}, ProductionService)
end

function ProductionService:Init(app)
	self.app = app
end

function ProductionService:Start()
	self.app:Connect(RunService.Heartbeat, function(delta)
		self.accumulator += delta
		if self.accumulator < self.interval then
			return
		end

		local elapsed = math.min(self.accumulator, 5)
		self.accumulator = 0
		self:Step(elapsed)
	end)
end

function ProductionService:Step(elapsed)
	local now = workspace:GetServerTimeNow()

	self.sessions:Each(function(player, state)
		local boosted = math.clamp(state.boostUntil - (now - elapsed), 0, elapsed)
		local earned = self.config.rate(state) * (elapsed + boosted)
		local capacity = self.config.energyCapacity(state)
		local recovery = 0.75 * (1 + self.config.moduleEffect(state, "recovery"))

		state.compute = math.min(1e18, state.compute + earned)
		state.totalEarned = math.min(1e18, state.totalEarned + earned)
		state.energy = math.min(capacity, state.energy + recovery * elapsed)
		self.stateService.touch(state)
		self.sessions:Publish(player, state, now)
	end)
end

function ProductionService:Stop()
	self.accumulator = 0
end

function ProductionService:Destroy()
	self.app = nil
end

return ProductionService
