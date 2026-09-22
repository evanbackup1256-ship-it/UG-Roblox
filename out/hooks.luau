-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- hooks.ts — Custom React hooks
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _store = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store")
local getState = _store.getState
local subscribe = _store.subscribe
--* Subscribe to the global game state and re-render on changes. 
local function useGameState()
	local state, setReactState = React.useState(getState)
	React.useEffect(function()
		return subscribe(function(newState)
			return setReactState(newState)
		end)
	end, {})
	return state
end
--[[
	* Returns a TweenService-based spring value animator for a GuiObject ref.
	 *  Returns a callback: call it with target properties to tween. 
]]
local function useTween(ref, info)
	return function(props)
		local obj = ref.current
		if not obj then
			return nil
		end
		local TweenService = game:GetService("TweenService")
		TweenService:Create(obj, info, props):Play()
	end
end
return {
	useGameState = useGameState,
	useTween = useTween,
}
