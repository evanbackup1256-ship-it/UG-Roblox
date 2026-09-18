local Players = game:GetService("Players")

local SessionService = {}
SessionService.__index = SessionService
SessionService.ServiceName = "SessionService"

-- ServiceBag registers this module by identity and constructs instances by
-- copying a blank table with __index = SessionService (see ServiceBag.lua
-- _addServiceType) — there is no custom .new(...) constructor call, so
-- anything this service needs beyond what Init(serviceBag) can resolve via
-- GetService must be injected explicitly before serviceBag:Init() runs.
-- ServerController.luau calls this once, right after GetService(SessionService).
-- Maid is passed in rather than required directly: this module lives
-- outside the Nevermore package tree, so it has no "loader" sibling link
-- (that link is only created within the packages root itself — see
-- Server.server.luau), and the package folder's own location is not fixed
-- (Studio's bootstrap fast path relocates it) — passing the already
-- required module sidesteps needing a reliable path to it at all.
function SessionService:Configure(persistence, stateService, config, throttle, Maid)
	self.persistence = persistence
	self.stateService = stateService
	self.config = config
	self.throttle = throttle
	self.Maid = Maid
end

function SessionService:Init(_serviceBag)
	self.maid = self.Maid.new()
	self.sessions = {}
	self.loading = {}
	self.publisher = nil
end

function SessionService:Start()
	self.maid:GiveTask(Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			self:Load(player)
		end)
	end))

	self.maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
		self:Release(player)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:Load(player)
		end)
	end
end

function SessionService:SetPublisher(callback)
	self.publisher = callback
end

function SessionService:Load(player)
	local current = self.sessions[player]
	if current then
		return current
	end

	if self.loading[player] then
		local deadline = os.clock() + 20
		while self.loading[player] and player.Parent == Players and os.clock() < deadline do
			task.wait(0.05)
		end
		return self.sessions[player]
	end

	self.loading[player] = true
	local ok, state, message = pcall(self.persistence.Load, self.persistence, player)
	self.loading[player] = nil

	if not ok then
		warn("Deck session load failed:", state)
		message = "Your save is unavailable. Please rejoin."
		state = nil
	end

	if state and player.Parent == Players then
		self.sessions[player] = state
		return state
	end

	if player.Parent == Players and message then
		task.defer(function()
			if player.Parent == Players then
				player:Kick(message)
			end
		end)
	end

	return nil
end

function SessionService:Get(player)
	return self.sessions[player] or self:Load(player)
end

function SessionService:Snapshot(state, now)
	return self.stateService.public(state, self.config, now or workspace:GetServerTimeNow())
end

function SessionService:Publish(player, state, now)
	if self.publisher and self.sessions[player] == state then
		self.publisher(player, self:Snapshot(state, now))
	end
end

function SessionService:Touch(player, state, now)
	self.stateService.touch(state)
	self:Publish(player, state, now)
end

function SessionService:Each(callback)
	for player, state in self.sessions do
		if player.Parent == Players then
			callback(player, state)
		else
			self:Release(player)
		end
	end
end

function SessionService:Drop(player)
	self.sessions[player] = nil
	self.loading[player] = nil
	if self.throttle then
		self.throttle:Forget(player)
	end
end

function SessionService:Release(player)
	self:Drop(player)
	self.persistence:Release(player)
end

function SessionService:Stop()
	local players = {}
	for player in self.sessions do
		table.insert(players, player)
	end

	for _, player in ipairs(players) do
		self:Release(player)
	end
end

function SessionService:Destroy()
	self.persistence:Close()
	if self.maid then
		self.maid:DoCleaning()
	end
	table.clear(self.sessions)
	table.clear(self.loading)
	self.publisher = nil
end

return SessionService
