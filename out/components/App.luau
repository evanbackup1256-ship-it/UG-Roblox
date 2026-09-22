-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- App.tsx — Root React component: screen router, nav state, transitions
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local C = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme").C
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local TopBar = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "components", "TopBar").default
local NavDock = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "components", "NavDock").default
local Toast = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "components", "Toast").default
local SearchPalette = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "components", "SearchPalette").default
-- Lazy-import screens (all resolved at require time, not lazy in Lua sense)
local ScreenCommand = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenCommand").default
local ScreenOperations = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenOperations").default
local ScreenHardware = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenHardware").default
local ScreenResearch = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenResearch").default
local ScreenSubsystems = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenSubsystems").default
local ScreenContracts = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenContracts").default
local ScreenAllocations = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenAllocations").default
local ScreenMarket = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenMarket").default
local ScreenSingularity = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenSingularity").default
local ScreenTerminal = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenTerminal").default
local ScreenStandings = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenStandings").default
local ScreenPreferences = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "screens", "ScreenPreferences").default
local SCREENS = {
	overview = ScreenCommand,
	operations = ScreenOperations,
	infrastructure = ScreenHardware,
	research = ScreenResearch,
	modules = ScreenSubsystems,
	contracts = ScreenContracts,
	rewards = ScreenAllocations,
	shop = ScreenMarket,
	prestige = ScreenSingularity,
	events = ScreenTerminal,
	leaderboard = ScreenStandings,
	settings = ScreenPreferences,
}
local SCREEN_BREADCRUMBS = {
	overview = "FLEET // COMMAND",
	operations = "FLEET // DISPATCH",
	infrastructure = "FLEET // HARDWARE",
	research = "LAB // RESEARCH",
	modules = "LAB // SUBSYSTEMS",
	contracts = "ENTERPRISE // WORK ORDERS",
	rewards = "FLEET // ALLOCATIONS",
	shop = "SUPPLY // PROCUREMENT",
	prestige = "QUANTUM // RELAUNCH",
	events = "NETWORK // TERMINAL",
	leaderboard = "FLEET // STANDINGS",
	settings = "SYSTEM // PREFERENCES",
}
local TRANS_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local function App()
	local state = useGameState()
	local activeScreen, setActiveScreen = React.useState("overview")
	local searchOpen, setSearchOpen = React.useState(false)
	local contentRef = React.createRef()
	local prevScreen = React.useRef("overview")
	local navigate = function(screen)
		if screen == activeScreen then
			return nil
		end
		-- Slide-out current screen
		local content = contentRef.current
		if content then
			game:GetService("TweenService"):Create(content, TRANS_INFO, {
				Position = UDim2.new(-0.08, 0, 0, 0),
				BackgroundTransparency = 1,
			}):Play()
		end
		task.delay(0.18, function()
			prevScreen.current = activeScreen
			setActiveScreen(screen)
			-- Slide in new screen from right
			task.defer(function()
				local c = contentRef.current
				if not c then
					return nil
				end
				c.Position = UDim2.new(0.08, 0, 0, 0)
				c.BackgroundTransparency = 0
				game:GetService("TweenService"):Create(c, TRANS_INFO, {
					Position = UDim2.new(0, 0, 0, 0),
				}):Play()
			end)
		end)
	end
	local ScreenComponent = SCREENS[activeScreen] or ScreenCommand
	local _condition = SCREEN_BREADCRUMBS[activeScreen]
	if _condition == nil then
		_condition = "FLEET // COMMAND"
	end
	local breadcrumb = _condition
	local energyCap = 100
	local _condition_1 = state.energy
	if _condition_1 == nil then
		_condition_1 = 100
	end
	local energy = math.clamp(_condition_1, 0, energyCap)
	local _attributes = {
		activeScreen = activeScreen,
	}
	local _condition_2 = state.callsign
	if _condition_2 == nil then
		_condition_2 = player.DisplayName
	end
	_attributes.callsign = _condition_2
	local _condition_3 = state.compute
	if _condition_3 == nil then
		_condition_3 = 0
	end
	_attributes.compute = _condition_3
	_attributes.computeRate = 0
	_attributes.energy = energy
	_attributes.energyCap = energyCap
	local _condition_4 = state.data
	if _condition_4 == nil then
		_condition_4 = 0
	end
	_attributes.data = _condition_4
	_attributes.onSearchOpen = function()
		return setSearchOpen(true)
	end
	return React.createElement("frame", {
		key = "AppRoot",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = C.canvas,
		BorderSizePixel = 0,
	}, React.createElement(TopBar, _attributes), React.createElement(NavDock, {
		activeScreen = activeScreen,
		onNavigate = navigate,
	}), React.createElement("frame", {
		ref = contentRef,
		key = "ContentArea",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -72, 1, -56),
		Position = UDim2.new(0, 72, 0, 56),
		ClipsDescendants = true,
	}, React.createElement(ScreenComponent)), React.createElement(Toast), React.createElement(SearchPalette, {
		visible = searchOpen,
		onClose = function()
			return setSearchOpen(false)
		end,
		onNavigate = function(s)
			navigate(s)
			setSearchOpen(false)
		end,
	}))
end
return {
	App = App,
}
