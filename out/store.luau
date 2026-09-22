-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- store.ts — Minimal reactive store fed by server Changed event
local ReplicatedStorage = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services").ReplicatedStorage
local listeners = {}
local currentState = {
	compute = 0,
	totalEarned = 0,
	jobs = 0,
	owned = {},
	research = {},
	claimed = {},
	achievements = {},
	energy = 100,
	data = 0,
	prestigeTokens = 0,
	boostUntil = 0,
	boostReady = 0,
	callsign = "Operator",
}
local function getState()
	return currentState
end
local function setState(nextState)
	currentState = nextState
	for _, l in listeners do
		task.spawn(function()
			return l(nextState)
		end)
	end
end
local function subscribe(listener)
	local _listener = listener
	table.insert(listeners, _listener)
	return function()
		local _listener_1 = listener
		local idx = (table.find(listeners, _listener_1) or 0) - 1
		if idx ~= -1 then
			table.remove(listeners, idx + 1)
		end
	end
end
--* Format large numbers: 1.23M, 456.7k, etc. 
local function fmt(val)
	if val < 0 then
		return "-" .. fmt(-val)
	end
	if val < 1000 then
		return tostring(math.floor(val + 0.5))
	end
	local suffixes = { "k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
	local exp = math.min(math.floor(math.log(val) / math.log(1000)), #suffixes)
	local scaled = val / math.pow(1000, exp)
	if scaled < 10 then
		return `{string.format("%.2f", scaled)}{suffixes[exp]}`
	end
	if scaled < 100 then
		return `{string.format("%.1f", scaled)}{suffixes[exp]}`
	end
	return `{string.format("%.0f", scaled)}{suffixes[exp]}`
end
--* Fire an action to the server and return the result. 
local function act(actionName, payload)
	local Action = ReplicatedStorage:WaitForChild("DeckGame"):WaitForChild("Action")
	return Action:InvokeServer(actionName, payload)
end
return {
	getState = getState,
	setState = setState,
	subscribe = subscribe,
	fmt = fmt,
	act = act,
}
