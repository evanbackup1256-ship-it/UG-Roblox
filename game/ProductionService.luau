local RunService = game:GetService("RunService")

local ProductionService = {}
ProductionService.__index = ProductionService
ProductionService.ServiceName = "ProductionService"

-- See SessionService.luau's Configure for why dependencies (including Maid)
-- are injected explicitly rather than resolved via require/GetService here.
function ProductionService:Configure(config, stateService, sessions, Maid)
	self.config = config
	self.stateService = stateService
	self.sessions = sessions
	self.Maid = Maid
end

function ProductionService:Init(_serviceBag)
	self.maid = self.Maid.new()
	self.accumulator = 0
	self.interval = 0.5
end

function ProductionService:Start()
	self.maid:GiveTask(RunService.Heartbeat:Connect(function(delta)
		self.accumulator += delta
		if self.accumulator < self.interval then
			return
		end

		local elapsed = math.min(self.accumulator, 5)
		self.accumulator = 0
		self:Step(elapsed)
	end))
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
	if self.maid then
		self.maid:DoCleaning()
	end
end

return ProductionService
