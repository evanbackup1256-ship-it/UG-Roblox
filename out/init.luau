-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- index.client.ts — Roblox client entrypoint
-- Mounts the React app, wires state from the server.
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local createRoot = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react-roblox").createRoot
local _services = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services")
local ReplicatedStorage = _services.ReplicatedStorage
local Players = _services.Players
local setState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store").setState
local App = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "components", "App").App
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- Fetch initial state
local DeckGame = ReplicatedStorage:WaitForChild("DeckGame")
local GetState = DeckGame:WaitForChild("GetState")
local Changed = DeckGame:WaitForChild("Changed")
local initialState = GetState:InvokeServer()
if initialState then
	setState(initialState)
end
-- Subscribe to server-pushed state changes
Changed.OnClientEvent:Connect(function(newState)
	if newState ~= 0 and newState == newState and newState ~= "" and newState then
		setState(newState)
	end
end)
-- Create ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "DeckReactApp"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
-- Mount React tree
local root = createRoot(gui)
root:render(React.createElement(App, {}))
return nil
