local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local package = ReplicatedStorage:WaitForChild("DeckGame")
local server = ServerScriptService:WaitForChild("DeckServer")

local PersistenceService = require(server:WaitForChild("PersistenceService"))
local LeaderboardService = require(server:WaitForChild("LeaderboardService"))
local Throttle = require(server:WaitForChild("Throttle"))
local SessionService = require(server:WaitForChild("SessionService"))
local ActionService = require(server:WaitForChild("ActionService"))
local ProductionService = require(server:WaitForChild("ProductionService"))

local Config = require(package:WaitForChild("Config"))
local Validation = require(package:WaitForChild("Validation"))
local StateService = require(package:WaitForChild("StateService"))
local EconomyService = require(package:WaitForChild("EconomyService"))
local RewardService = require(package:WaitForChild("RewardService"))
local ShopService = require(package:WaitForChild("ShopService"))
local NetworkService = require(package:WaitForChild("NetworkService"))

local ServerController = {}

-- Server.server.luau calls this once, right after Loader.bootstrapGame has
-- populated the Nevermore package tree, passing the two Nevermore modules
-- this file needs by reference (see Server.server.luau for why: a fresh
-- path lookup for them from here can't reliably find the packages folder,
-- since Studio's bootstrap fast path relocates it).
function ServerController.start(ServiceBag, Maid)
	local serviceBag = ServiceBag.new()
	local throttle = Throttle.new()
	local remotes = NetworkService.bind(package)
	local sessions
	local studioDiagnostics = RunService:IsStudio()

	local function trace(message, ...)
		if not studioDiagnostics then
			return
		end

		if select("#", ...) == 0 then
			print("[Deck/Server] " .. message)
		else
			print(string.format("[Deck/Server] " .. message, ...))
		end
	end

	local function hydrate(data)
		local state = StateService.new(Config, data)
		state.settings = table.clone(Config.Settings)

		if type(data) == "table" and type(data.settings) == "table" then
			for key, default in Config.Settings do
				local value = Validation.preference(default, data.settings[key])
				if value ~= nil then
					state.settings[key] = value
				end
			end
		end

		return state
	end

	local persistence = PersistenceService.new(hydrate, function(player)
		trace("session ended: user=%d", player.UserId)
		if sessions then
			sessions:Drop(player)
		end
	end)

	-- ServiceBag registers services by module identity and constructs
	-- instances internally (a blank table copy with __index = the module) —
	-- there is no custom .new(...) call, so SessionService/ProductionService
	-- receive their non-service dependencies (Config, StateService,
	-- persistence, throttle, Maid, sibling services) via an explicit
	-- Configure(...) call, made here before serviceBag:Init() runs.
	sessions = serviceBag:GetService(SessionService)
	sessions:Configure(persistence, StateService, Config, throttle, Maid)

	local actions = ActionService.new(
		Config,
		EconomyService,
		RewardService,
		ShopService,
		Validation
	)

	local production = serviceBag:GetService(ProductionService)
	production:Configure(Config, StateService, sessions, Maid)

	local leaderboard = LeaderboardService.new(sessions, throttle)

	sessions:SetPublisher(function(player, state)
		remotes.changed:FireClient(player, state)
	end)

	local function response(state, ok, message)
		return {
			ok = ok,
			message = message,
			state = state and sessions:Snapshot(state) or nil,
		}
	end

	remotes.getState.OnServerInvoke = function(player)
		if not throttle:Consume("state", player, 8, 6) then
			return nil
		end

		local state = sessions:Get(player)
		return state and sessions:Snapshot(state) or nil
	end

	remotes.ping.OnServerInvoke = function(player)
		if not throttle:Consume("ping", player, 10, 8) then
			return nil
		end

		return workspace:GetServerTimeNow()
	end

	remotes.leaderboard.OnServerInvoke = function(player, category)
		if not throttle:Consume("leaderboard", player, 3, 0.2) then
			return nil
		end

		local key = if type(category) == "string" then category else "earned"
		local top, cachedAt = leaderboard:GetTop(key)
		return {
			category = key,
			categories = leaderboard:Categories(),
			top = top,
			cachedAt = cachedAt,
			rank = leaderboard:GetRank(key, player.UserId),
		}
	end

	remotes.preferences.OnServerEvent:Connect(function(player, changes)
		if type(changes) ~= "table" or not throttle:Consume("preferences", player, 5, 5) then
			return
		end

		local state = sessions:Get(player)
		if not state then
			return
		end

		local changed = false
		for key, default in Config.Settings do
			local value = Validation.preference(default, changes[key])
			if value ~= nil and state.settings[key] ~= value then
				state.settings[key] = value
				changed = true
			end
		end

		if type(changes.accentTheme) == "string"
			and table.find(Config.AccentThemes, changes.accentTheme)
			and state.accentTheme ~= changes.accentTheme
		then
			state.accentTheme = changes.accentTheme
			changed = true
		end

		if changed then
			StateService.touch(state)
			trace("preferences saved: user=%d", player.UserId)
		end
	end)

	remotes.action.OnServerInvoke = function(player, kind, key, amount)
		trace("action request: user=%d kind=%s key=%s amount=%s", player.UserId, tostring(kind), tostring(key), tostring(amount))
		local state = sessions:Get(player)
		if not state then
			trace("action rejected: user=%d reason=session", player.UserId)
			return response(nil, false, "Your cloud is still connecting.")
		end

		if not throttle:Consume("action", player, 10, 6) then
			trace("action throttled: user=%d kind=%s", player.UserId, tostring(kind))
			return response(state, false, "One moment…")
		end

		-- Player-supplied display text (shown to other players via the
		-- header and leaderboard) must go through Roblox's chat filter
		-- before it ever reaches state — ActionService.Execute is
		-- deliberately player-agnostic (see its own comment), so this is
		-- the one call site with the Player instance FilterStringAsync
		-- needs, done here rather than threading `player` through every
		-- Execute branch for the sake of this one.
		if kind == "callsign" and type(key) == "string" and key ~= "" then
			local filterOk, filtered = pcall(function()
				local result = TextService:FilterStringAsync(key, player.UserId)
				return result:GetNonChatStringForBroadcastAsync()
			end)
			key = if filterOk then filtered else ""
		end

		local invoked, ok, message = xpcall(function()
			return actions:Execute(state, kind, key, amount, os.clock())
		end, debug.traceback)

		if not invoked then
			warn("Deck action failed:", message)
			trace("action fault: user=%d kind=%s", player.UserId, tostring(kind))
			return response(state, false, "The request could not be completed.")
		end

		local succeeded = ok
		local detail = message
		StateService.touch(state)

		if succeeded then
			sessions:Publish(player, state)
			leaderboard:Submit(player, state)
		end
		trace("action result: user=%d kind=%s ok=%s message=%s", player.UserId, tostring(kind), tostring(succeeded), tostring(detail))

		return response(state, succeeded, detail)
	end

	game:BindToClose(function()
		trace("shutdown: closing service kernel")
		leaderboard:StopLoop()
		serviceBag:Destroy()
	end)

	serviceBag:Init()
	serviceBag:Start()
	leaderboard:StartLoop()

	print("[Deck/Server] service kernel online")
	return serviceBag
end

return ServerController
