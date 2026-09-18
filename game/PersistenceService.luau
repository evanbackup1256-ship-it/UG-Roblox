local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.DeckPackages.ProfileStore)

local PersistenceService = {}
PersistenceService.__index = PersistenceService

function PersistenceService.new(hydrate, onLost)
    local self = setmetatable({}, PersistenceService)
    self.profiles = {}
    self.closing = false
    self.hydrate = hydrate
    self.onLost = onLost
    self.isStudio = RunService:IsStudio()
    self.store = ProfileStore.New("DeckEmpire_Profiles_v1", {
        migrated = false,
        state = {},
    })

    if self.isStudio then
        self.store = self.store.Mock
    end

    return self
end

function PersistenceService:Load(player)
    local profile = self.store:StartSessionAsync("player_" .. player.UserId, {
        Cancel = function()
            return self.closing or player.Parent ~= Players
        end,
    })

    if not profile then
        return nil, "Your save is unavailable. Please rejoin."
    end

    profile:AddUserId(player.UserId)
    profile:Reconcile()

    if not profile.Data.migrated then
        local legacy
        if not self.isStudio then
            for _, name in ipairs({ "DeckEmpire_v3", "DeckEmpire_v2" }) do
                local ok, result = pcall(function()
                    return DataStoreService:GetDataStore(name):GetAsync("player_" .. player.UserId)
                end)

                if not ok then
                    profile:EndSession()
                    return nil, "Your previous save could not be loaded. Please rejoin."
                end

                if result ~= nil then
                    if type(result) ~= "table" then
                        profile:EndSession()
                        return nil, "Your previous save needs recovery."
                    end
                    legacy = result
                    break
                end
            end
        end

        profile.Data.state = legacy or {}
        profile.Data.migrated = true
    end

    if self.closing or player.Parent ~= Players or not profile:IsActive() then
        profile:EndSession()
        return nil, "Session closed."
    end

    local ok, state = pcall(self.hydrate, profile.Data.state)
    if not ok then
        profile:EndSession()
        return nil, "Your save needs recovery. Please rejoin later."
    end

    state.saveStatus = self.isStudio and "Studio session" or "Session protected"
    profile.Data.state = state
    self.profiles[player] = profile

    profile.OnSessionEnd:Connect(function()
        if self.profiles[player] ~= profile then
            return
        end
        self.profiles[player] = nil
        self.onLost(player)
        if player.Parent == Players and not self.closing then
            player:Kick("Your save session ended. Please rejoin to continue safely.")
        end
    end)

    return state
end

function PersistenceService:IsActive(player)
    local profile = self.profiles[player]
    return profile ~= nil and profile:IsActive()
end

function PersistenceService:Release(player)
    local profile = self.profiles[player]
    self.profiles[player] = nil
    if profile then
        profile:EndSession()
    end
end

function PersistenceService:Close()
    self.closing = true
    local players = {}
    for player in pairs(self.profiles) do
        table.insert(players, player)
    end
    for _, player in ipairs(players) do
        self:Release(player)
    end
end

return PersistenceService
