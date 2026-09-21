--!strict
-- AppController: Master orchestrator and client presentation kernel
-- Manages responsive viewport layouts, physical spring kinetics, screen transitions,
-- telemetry capsules, and server synchronization with zero AI clutter.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Package = ReplicatedStorage:WaitForChild("DeckGame")
local Config = require(Package:WaitForChild("Config"))
local Shop = require(Package:WaitForChild("ShopService"))
local Icons = require(Package:WaitForChild("Icons"))
local PreviewDirector = require(Package:WaitForChild("PreviewDirector"))
local SearchIndex = require(Package:WaitForChild("SearchIndex"))

local Theme = require(script.Parent.Theme)
local Springs = require(script.Parent.Springs)
local Elements = require(script.Parent.Elements)
local Buttons = require(script.Parent.Buttons)
local Inputs = require(script.Parent.Inputs)
local Feedback = require(script.Parent.Feedback)
local Acoustics = require(script.Parent.Acoustics)
local Odometer = require(script.Parent.Odometer)
local ToastManager = require(script.Parent.ToastManager)
local TourGuide = require(script.Parent.TourGuide)
local SearchPalette = require(script.Parent.SearchPalette)
local AppContext = require(script.Parent.AppContext)

-- Screen Modules
local ScreenCommand = require(script.Parent.Screens.ScreenCommand)
local ScreenOperations = require(script.Parent.Screens.ScreenOperations)
local ScreenHardware = require(script.Parent.Screens.ScreenHardware)
local ScreenResearch = require(script.Parent.Screens.ScreenResearch)
local ScreenSubsystems = require(script.Parent.Screens.ScreenSubsystems)
local ScreenContracts = require(script.Parent.Screens.ScreenContracts)
local ScreenAllocations = require(script.Parent.Screens.ScreenAllocations)
local ScreenMarket = require(script.Parent.Screens.ScreenMarket)
local ScreenSingularity = require(script.Parent.Screens.ScreenSingularity)
local ScreenTerminal = require(script.Parent.Screens.ScreenTerminal)
local ScreenStandings = require(script.Parent.Screens.ScreenStandings)
local ScreenPreferences = require(script.Parent.Screens.ScreenPreferences)

local C = Theme.colors
local player = Players.LocalPlayer

-- Connect acoustics to button and input kits
Inputs.setAcoustics(Acoustics)
Buttons.setAcoustics(Acoustics)

-- Remote references
local GetState = Package:WaitForChild("GetState") :: RemoteFunction
local Action = Package:WaitForChild("Action") :: RemoteFunction
local Changed = Package:WaitForChild("Changed") :: RemoteEvent
local PreferencesRemote = Package:WaitForChild("Preferences") :: RemoteEvent
local Ping = Package:WaitForChild("Ping") :: RemoteFunction
local Leaderboard = Package:WaitForChild("Leaderboard") :: RemoteFunction

local alive = true
local disposables: { any } = {}

local function own(item: any): any
	table.insert(disposables, item)
	return item
end

local function release(item: any)
	local idx = table.find(disposables, item)
	if idx then table.remove(disposables, idx) end
	if typeof(item) == "RBXScriptConnection" then
		item:Disconnect()
	elseif type(item) == "thread" then
		pcall(task.cancel, item)
	elseif typeof(item) == "Instance" then
		item:Destroy()
	elseif type(item) == "table" and type(item.Destroy) == "function" then
		pcall(item.Destroy, item)
	elseif type(item) == "function" then
		pcall(item)
	end
end

local function dispose()
	alive = false
	for _, item in ipairs(disposables) do
		if typeof(item) == "RBXScriptConnection" then
			item:Disconnect()
		elseif type(item) == "thread" then
			pcall(task.cancel, item)
		elseif typeof(item) == "Instance" then
			item:Destroy()
		elseif type(item) == "table" and type(item.Destroy) == "function" then
			pcall(item.Destroy, item)
		elseif type(item) == "function" then
			pcall(item)
		end
	end
	table.clear(disposables)
end

local function connect(sig: RBXScriptSignal, cb: (...any) -> ()): RBXScriptConnection
	local conn = sig:Connect(cb)
	table.insert(disposables, conn)
	return conn
end

local function defer(delaySeconds: number, fn: (...any) -> ()): thread
	local t = task.delay(delaySeconds, fn)
	table.insert(disposables, t)
	return t
end

local function cancel(t: thread)
	release(t)
end

local function fmt(val: number): string
	if val == nil then return "0" end
	if val < 0 then return "-" .. fmt(-val) end
	if val < 1000 then return tostring(math.floor(val + 0.5)) end

	local suffixes = { "k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
	local exp = math.floor(math.log(val, 10) / 3)
	if exp > #suffixes then exp = #suffixes end

	local scaled = val / (10 ^ (exp * 3))
	local formatted = if scaled < 10 then string.format("%.2f", scaled)
		elseif scaled < 100 then string.format("%.1f", scaled)
		else string.format("%.0f", scaled)

	return formatted .. suffixes[exp]
end

-- =============================================================================
-- ROOT GUI & SCAFFOLDING
-- =============================================================================
local playerGui = player:WaitForChild("PlayerGui")
local gui = Elements.create("ScreenGui", playerGui, {
	Name = "DeckApp",
	ResetOnSpawn = false,
	DisplayOrder = 10,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
own(gui)

local root = Elements.create("Frame", gui, {
	Name = "Root",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.canvas,
	BorderSizePixel = 0,
	ZIndex = 1,
})

-- Persistent Preferences Table
local preferences = {
	music = true,
	sfx = true,
	hover = true,
	masterVolume = 0.8,
	sfxVolume = 0.9,
	musicVolume = 0.5,
	motion = true,
	notifications = true,
	previews = true,
	autoOrbit = true,
	orbitSpeed = 0.5,
	particles = true,
	accentTheme = "azure",
}

-- Initialize acoustic audio system with live preferences
local acousticsSystem = own(Acoustics.new(preferences, function() return alive end))

-- 3D Preview Director
local director = own(PreviewDirector.new(gui, preferences))

-- Toast Alert System
local toasts = own(ToastManager.new(root, Acoustics))

-- =============================================================================
-- NAVIGATION & SCREEN DEFINITIONS
-- =============================================================================
type ScreenDef = {
	key: string,
	shortTitle: string,
	breadcrumb: string,
	icon: string,
	order: number,
}

local screenDefs: { ScreenDef } = {
	{ key = "overview", shortTitle = "Command", breadcrumb = "FLEET // COMMAND", icon = "overview", order = 1 },
	{ key = "operations", shortTitle = "Dispatch", breadcrumb = "FLEET // DISPATCH", icon = "operations", order = 2 },
	{ key = "infrastructure", shortTitle = "Hardware", breadcrumb = "FLEET // HARDWARE", icon = "infrastructure", order = 3 },
	{ key = "research", shortTitle = "Research", breadcrumb = "LAB // RESEARCH", icon = "research", order = 4 },
	{ key = "modules", shortTitle = "Subsystems", breadcrumb = "LAB // SUBSYSTEMS", icon = "modules", order = 5 },
	{ key = "contracts", shortTitle = "Contracts", breadcrumb = "ENTERPRISE // WORK ORDERS", icon = "contracts", order = 6 },
	{ key = "rewards", shortTitle = "Allocations", breadcrumb = "FLEET // ALLOCATIONS", icon = "rewards", order = 7 },
	{ key = "shop", shortTitle = "Procurement", breadcrumb = "SUPPLY // PROCUREMENT", icon = "shop", order = 8 },
	{ key = "prestige", shortTitle = "Singularity", breadcrumb = "QUANTUM // RELAUNCH", icon = "prestige", order = 9 },
	{ key = "events", shortTitle = "Terminal", breadcrumb = "NETWORK // TERMINAL", icon = "events", order = 10 },
	{ key = "leaderboard", shortTitle = "Standings", breadcrumb = "FLEET // STANDINGS", icon = "leaderboard", order = 11 },
	{ key = "settings", shortTitle = "Preferences", breadcrumb = "SYSTEM // PREFERENCES", icon = "settings", order = 12 },
}

local screens: { [string]: ScrollingFrame } = {}
local wrappers: { [string]: CanvasGroup } = {}
local screenUpdates: { [string]: { (any) -> () } } = {}
local screenLayouts: { [string]: (number) -> number } = {}
local navButtons: { [string]: { button: TextButton, icon: any, label: TextLabel } } = {}
local selectedScreen = "overview"

-- =============================================================================
-- TOPBAR TELEMETRY CAPSULE
-- =============================================================================
local topbar = Elements.create("Frame", root, {
	Name = "Topbar",
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
	ZIndex = 2,
})
Elements.stroke(topbar, C.hairline, 1, 0.70)

-- Operator Identity Pill (Left)
local operatorPill = Elements.create("Frame", topbar, {
	Name = "OperatorPill",
	Position = UDim2.new(0, 16, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	Size = UDim2.fromOffset(220, 38),
	BackgroundColor3 = C.recessed,
	BorderSizePixel = 0,
	ZIndex = 2,
})
Elements.corner(operatorPill, Theme.radii.pill)
Elements.stroke(operatorPill, C.hairline, 1, 0.70)

local avatar = Elements.create("ImageLabel", operatorPill, {
	Name = "Avatar",
	Size = UDim2.fromOffset(28, 28),
	Position = UDim2.new(0, 5, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = C.elevated,
	BorderSizePixel = 0,
})
Elements.corner(avatar, 14)

task.spawn(function()
	local ok, img = pcall(
		Players.GetUserThumbnailAsync,
		Players,
		player.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size100x100
	)
	if ok and alive then
		avatar.Image = img
	end
end)

local opCallsign = Elements.text(operatorPill, "Callsign", player.DisplayName, 13, C.textPrimary, true)
opCallsign.Position = UDim2.new(0, 40, 0, 4)
opCallsign.Size = UDim2.new(1, -46, 0, 16)

local opBreadcrumb = Elements.text(operatorPill, "Breadcrumb", "FLEET // COMMAND", 10, C.textMuted, true)
opBreadcrumb.Font = Theme.typography.fontMono
opBreadcrumb.Position = UDim2.new(0, 40, 0, 20)
opBreadcrumb.Size = UDim2.new(1, -46, 0, 14)

-- Telemetry Container (Right)
local telemetryRow = Elements.create("Frame", topbar, {
	Name = "TelemetryRow",
	Position = UDim2.new(1, -16, 0.5, 0),
	AnchorPoint = Vector2.new(1, 0.5),
	Size = UDim2.fromOffset(0, 38),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	ZIndex = 2,
})

local telemetryLayout = Elements.create("UIListLayout", telemetryRow, {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- 1. Compute Rolling Ticker Capsule
local computePill = Elements.recessedWell(telemetryRow, "ComputePill", 36)
computePill.Size = UDim2.fromOffset(200, 36)
computePill.LayoutOrder = 1

local computeIcon = Elements.icon(computePill, "Icon", "overview", C.compute)
Elements.place(computeIcon, 10, 8, 20, 20)

local computeOdometer = Odometer.new(computePill, 14, C.compute)
computeOdometer.container.Position = UDim2.new(0, 36, 0, 8)
computeOdometer.container.Size = UDim2.new(0, 95, 0, 20)
computeOdometer:setFormat(function(val)
	return fmt(val)
end)

local computeRate = Elements.text(computePill, "Rate", "+0/s", 11, C.textSecondary, true)
computeRate.Font = Theme.typography.fontMono
computeRate.TextXAlignment = Enum.TextXAlignment.Right
Elements.place(computeRate, 134, 8, 56, 20)

local bumpComputeIcon = Feedback.bump(computeIcon, 1.2)

-- 2. Energy Battery Capsule with Mini Battery Gauge
local energyPill = Elements.recessedWell(telemetryRow, "EnergyPill", 36)
energyPill.Size = UDim2.fromOffset(120, 36)
energyPill.LayoutOrder = 2

local energyIcon = Elements.icon(energyPill, "Icon", "operations", C.energy)
Elements.place(energyIcon, 10, 8, 20, 20)

local energyLabel = Elements.text(energyPill, "Label", "100 / 100", 11, C.energy, true)
energyLabel.Font = Theme.typography.fontMono
Elements.place(energyLabel, 34, 6, 76, 18)

-- Miniature battery progress meter inside the pill
local energyBarTrack = Elements.create("Frame", energyPill, {
	Name = "BatteryTrack",
	Position = UDim2.new(0, 10, 1, -6),
	Size = UDim2.new(1, -20, 0, 3),
	BackgroundColor3 = Color3.fromRGB(24, 24, 28),
	BorderSizePixel = 0,
})
Elements.corner(energyBarTrack, 2)

local energyBarFill = Elements.create("Frame", energyBarTrack, {
	Name = "BatteryFill",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.energy,
	BorderSizePixel = 0,
})
Elements.corner(energyBarFill, 2)

local bumpEnergyIcon = Feedback.bump(energyIcon, 1.2)

-- 3. Data Cache Capsule
local dataPill = Elements.recessedWell(telemetryRow, "DataPill", 36)
dataPill.Size = UDim2.fromOffset(90, 36)
dataPill.LayoutOrder = 3

local dataIcon = Elements.icon(dataPill, "Icon", "research", C.data)
Elements.place(dataIcon, 10, 8, 20, 20)

local dataLabel = Elements.text(dataPill, "Label", "0", 12, C.data, true)
dataLabel.Font = Theme.typography.fontMono
Elements.place(dataLabel, 34, 8, 48, 20)

local bumpDataIcon = Feedback.bump(dataIcon, 1.2)

-- 4. Hardware FPS / Ping Pill
local perfPill = Elements.recessedWell(telemetryRow, "PerfPill", 36)
perfPill.Size = UDim2.fromOffset(130, 36)
perfPill.LayoutOrder = 4

local perfDot = Elements.statusDot(perfPill, "Dot", C.compute)
Elements.place(perfDot, 12, 14, 8, 8)

local perfLabel = Elements.text(perfPill, "Label", "60 FPS · --ms", 10, C.textMuted, true)
perfLabel.Font = Theme.typography.fontMono
Elements.place(perfLabel, 26, 8, 96, 20)

-- 5. Search Palette Trigger Button
local searchTrigger = Elements.create("TextButton", telemetryRow, {
	Name = "SearchTrigger",
	Size = UDim2.fromOffset(36, 36),
	BackgroundColor3 = C.recessed,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	LayoutOrder = 5,
})
Elements.corner(searchTrigger, Theme.radii.pill)
Elements.stroke(searchTrigger, C.hairline, 1, 0.70)
local searchIco = Elements.icon(searchTrigger, "Icon", "search", C.textSecondary)
Elements.place(searchIco, 8, 8, 20, 20)

searchTrigger.MouseEnter:Connect(function()
	Springs.target(searchTrigger, { BackgroundColor3 = C.elevated }, "smooth")
	Elements.tintIcon(searchIco, C.accent)
end)
searchTrigger.MouseLeave:Connect(function()
	Springs.target(searchTrigger, { BackgroundColor3 = C.recessed }, "smooth")
	Elements.tintIcon(searchIco, C.textSecondary)
end)

-- =============================================================================
-- OVERCLOCK ACTIVE STATUS BANNER
-- =============================================================================
local overclockBanner = Elements.create("Frame", root, {
	Name = "OverclockBanner",
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundColor3 = C.energy:Lerp(C.panel, 0.75),
	BorderSizePixel = 0,
	Visible = false,
	ClipsDescendants = true,
	ZIndex = 3,
})
Elements.stroke(overclockBanner, C.energy, 1, 0.40)


local ocIcon = Elements.icon(overclockBanner, "Icon", "operations", C.energy)
Elements.place(ocIcon, 16, 6, 20, 20)

local ocText = Elements.text(
	overclockBanner,
	"Label",
	"⚡ HIGH-VOLTAGE OVERCLOCK ENGAGED — COMPUTE RATE MULTIPLIED BY 2.0×",
	11,
	C.energy,
	true
)
ocText.Font = Theme.typography.fontMono
ocText.Position = UDim2.new(0, 44, 0.5, 0)
ocText.AnchorPoint = Vector2.new(0, 0.5)
ocText.Size = UDim2.new(1, -54, 0, 20)
ocText.TextTruncate = Enum.TextTruncate.AtEnd

-- =============================================================================
-- NAVIGATION DOCK RAIL
-- =============================================================================
local dock = Elements.create("Frame", root, {
	Name = "NavigationDock",
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
	ZIndex = 2,
})
Elements.stroke(dock, C.hairline, 1, 0.70)

local dockScroll = Elements.create("ScrollingFrame", dock, {
	Name = "NavScroll",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.fromOffset(0, 0),
	ZIndex = 2,
})

-- Physical sliding active pill indicator
local activePill = Elements.create("Frame", dockScroll, {
	Name = "ActiveIndicator",
	BackgroundColor3 = C.elevated,
	BorderSizePixel = 0,
	ZIndex = 1,
})
Elements.corner(activePill, Theme.radii.control)
Elements.stroke(activePill, C.hairlineGlow, 1, 0.40)

-- =============================================================================
-- BODY CONTENT CONTAINER & PAGES
-- =============================================================================
local body = Elements.create("Frame", root, {
	Name = "BodyContainer",
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 1,
})

for _, def in ipairs(screenDefs) do
	local wrapper = Elements.create("CanvasGroup", body, {
		Name = "Wrapper_" .. def.key,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = (def.key == selectedScreen) and 0 or 1,
		Visible = (def.key == selectedScreen),
	})

	local page = Elements.create("ScrollingFrame", wrapper, {
		Name = "Screen_" .. def.key,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.hairline,
		CanvasSize = UDim2.fromOffset(0, 0),
	})

	screens[def.key] = page
	wrappers[def.key] = wrapper
	screenUpdates[def.key] = {}
end

-- =============================================================================
-- STATE BINDING & SCREEN REGISTRATION HELPERS
-- =============================================================================
local function bind(screenKey: string, onUpdate: (state: any) -> ())
	if screenUpdates[screenKey] then
		table.insert(screenUpdates[screenKey], onUpdate)
	end
end

local function layoutScreen(screenKey: string, layoutFn: (viewportWidth: number) -> number)
	screenLayouts[screenKey] = function(width: number)
		local totalHeight = 0
		local page = screens[screenKey]
		if page then
			totalHeight = layoutFn(width)
			page.CanvasSize = UDim2.fromOffset(0, totalHeight + 36)
		end
		return totalHeight
	end
end

local function relayout(screenKey: string)
	local fn = screenLayouts[screenKey]
	if fn and body.AbsoluteSize.X > 0 then
		fn(body.AbsoluteSize.X - 12)
	end
end

-- =============================================================================
-- ACTION SYSTEM & REMOTE DISPATCH
-- =============================================================================
local requestSerial = 0
local pending = false
local liveState: any = nil
local hydrated = false
local quantity = 1
local appContext: any = nil
local fit: (() -> ())? = nil
local lastCompute: number? = nil
local lastEnergy: number? = nil
local lastData: number? = nil
local wasOverclocked: boolean = false
local lastBoostUntil: number = 0

local function notify(message: string, isError: boolean?, title: string?)
	toasts:notify(message, isError, title)
end

local function apply(s: any)
	if not alive or type(s) ~= "table" then return end
	if liveState and s.updatedAt and liveState.updatedAt and s.updatedAt < liveState.updatedAt then
		return
	end

	liveState = s
	if appContext then
		appContext.state = s
	end

	if not hydrated then
		hydrated = true
		print(string.format("[Deck/UI] kernel online: state synchronized (compute=%s, rate=%s, energy=%s)", fmt(s.compute or 0), fmt(s.rate or 0), tostring(s.energy or 0)))
		for k, v in pairs(s.settings or {}) do
			if preferences[k] ~= nil and type(preferences[k]) == type(v) then
				preferences[k] = v
			end
		end
		if type(s.accentTheme) == "string" then
			preferences.accentTheme = s.accentTheme
			Theme.applyPreset(s.accentTheme)
		end
	end

	-- Update telemetry capsules
	local newCompute = s.compute or 0
	if lastCompute and math.abs(newCompute - lastCompute) >= 1 then
		bumpComputeIcon()
		if newCompute > lastCompute then
			Feedback.pulse(computePill, 1.03)
		end
	end
	lastCompute = newCompute
	computeOdometer:setValue(newCompute, true)
	computeRate.Text = string.format("+%s/s", fmt(s.rate or 0))

	local currentEnergy = math.floor(s.energy or 0)
	local maxEnergy = math.max(1, math.floor(s.energyCapacity or 100))
	energyLabel.Text = string.format("%d / %d", currentEnergy, maxEnergy)
	local energyRatio = math.clamp(currentEnergy / maxEnergy, 0, 1)
	Springs.target(energyBarFill, { Size = UDim2.fromScale(energyRatio, 1) }, "smooth")
	if energyRatio < 0.20 then
		energyBarFill.BackgroundColor3 = C.danger
		energyLabel.TextColor3 = C.danger
		Feedback.pulse(energyPill, 1.04)
	else
		energyBarFill.BackgroundColor3 = C.energy
		energyLabel.TextColor3 = C.energy
	end
	if lastEnergy and currentEnergy > lastEnergy then
		bumpEnergyIcon()
	end
	lastEnergy = currentEnergy

	local newData = s.data or 0
	if lastData and newData > lastData then
		bumpDataIcon()
		Feedback.pulse(dataPill, 1.05)
	end
	lastData = newData
	dataLabel.Text = fmt(newData)

	local nameToShow = if s.callsign and s.callsign ~= "" then s.callsign else player.DisplayName
	opCallsign.Text = nameToShow

	local now = workspace:GetServerTimeNow()
	local boostUntil = s.boostUntil or 0
	local isOverclocked = boostUntil > now
	lastBoostUntil = if isOverclocked then boostUntil else 0

	if isOverclocked then
		local rem = math.max(0, math.floor(boostUntil - now + 0.5))
		ocText.Text = string.format("⚡ HIGH-VOLTAGE OVERCLOCK ENGAGED — COMPUTE RATE MULTIPLIED BY 2.0× (%ds)", rem)
	end

	if isOverclocked ~= wasOverclocked then
		wasOverclocked = isOverclocked
		overclockBanner.Visible = isOverclocked
		if isOverclocked then
			Feedback.pulse(ocIcon, 1.3)
		end
		if fit then fit() end
	else
		overclockBanner.Visible = isOverclocked
	end

	-- Notify active screen listeners
	local callbacks = screenUpdates[selectedScreen]
	if callbacks then
		for _, cb in ipairs(callbacks) do
			cb(s)
		end
	end
end

local function act(kind: string, key: string?, amount: any?, silent: boolean?)
	if not liveState or not alive then
		print(string.format("[Deck/UI] action dropped: unhydrated or inactive (kind=%s, key=%s)", tostring(kind), tostring(key)))
		return
	end

	local arg = if amount ~= nil then amount elseif kind == "buy" then quantity else nil
	requestSerial += 1
	local serial = requestSerial
	pending = true
	print(string.format("[Deck/UI] action dispatch: #%d kind=%s key=%s arg=%s", serial, tostring(kind), tostring(key), tostring(arg)))

	local watchdog = defer(12, function()
		if requestSerial == serial and pending then
			pending = false
			print(string.format("[Deck/UI] action timeout: #%d kind=%s", serial, tostring(kind)))
			notify("Server request timed out. Please retry.", true, "TRANSMISSION TIMEOUT")
		end
	end)

	task.spawn(function()
		local ok, result = pcall(Action.InvokeServer, Action, kind, key, arg)
		cancel(watchdog)
		if requestSerial == serial then pending = false end
		if not alive then return end

		if ok and type(result) == "table" then
			print(string.format("[Deck/UI] action result: #%d ok=%s message=%s", serial, tostring(result.ok), tostring(result.message or "ok")))
			apply(result.state)
			if not silent and (kind ~= "job" or not result.ok) then
				notify(result.message or "Action completed", not result.ok, if result.ok then "SUCCESS" else "DIRECTIVE HALTED")
			end
		else
			print(string.format("[Deck/UI] action comms error: #%d ok=%s", serial, tostring(ok)))
			notify("Network connection interrupted.", true, "COMMS FAILURE")
		end
	end)
end

-- =============================================================================
-- SCREEN SWITCHER & TRANSITIONS
-- =============================================================================
local isWideLayout = true

local function updateActivePillPosition(screenKey: string, animate: boolean?)
	local btnEntry = navButtons[screenKey]
	if not btnEntry then return end

	local btn = btnEntry.button
	local targetPos = btn.Position
	local targetSize = btn.Size

	if animate ~= false then
		Springs.target(activePill, { Position = targetPos, Size = targetSize }, "smooth")
	else
		activePill.Position = targetPos
		activePill.Size = targetSize
	end

	-- Auto-scroll horizontal mobile dock to keep active tab centered
	if not isWideLayout and dockScroll.AbsoluteSize.X > 0 then
		local btnX = targetPos.X.Offset
		local btnW = targetSize.X.Offset
		local visibleW = dockScroll.AbsoluteSize.X
		local maxScroll = math.max(0, dockScroll.CanvasSize.X.Offset - visibleW)
		local targetScrollX = math.clamp(btnX - (visibleW - btnW) / 2, 0, maxScroll)
		if animate ~= false then
			Springs.target(dockScroll, { CanvasPosition = Vector2.new(targetScrollX, 0) }, "smooth")
		else
			dockScroll.CanvasPosition = Vector2.new(targetScrollX, 0)
		end
	end

	for k, entry in pairs(navButtons) do
		local isSel = (k == screenKey)
		local textColor = if isSel then C.textPrimary else C.textMuted
		local iconColor = if isSel then C.accent else C.textMuted
		if animate ~= false then
			Springs.target(entry.label, { TextColor3 = textColor }, "smooth")
			Elements.tintIcon(entry.icon, iconColor)
		else
			entry.label.TextColor3 = textColor
			Elements.tintIcon(entry.icon, iconColor)
		end
	end
end

local function switchScreen(targetKey: string)
	if targetKey == selectedScreen and wrappers[targetKey] and wrappers[targetKey].Visible then return end

	local prevKey = selectedScreen
	local prevPage = screens[prevKey]
	local prevWrapper = wrappers[prevKey]
	local newPage = screens[targetKey]
	local newWrapper = wrappers[targetKey]
	if not newPage or not newWrapper then return end

	local prevOrder = 1
	local newOrder = 1
	for _, def in ipairs(screenDefs) do
		if def.key == prevKey then prevOrder = def.order end
		if def.key == targetKey then newOrder = def.order end
	end

	selectedScreen = targetKey
	Acoustics.play("tab", 0.04)

	-- Update breadcrumb
	for _, def in ipairs(screenDefs) do
		if def.key == targetKey then
			opBreadcrumb.Text = def.breadcrumb
			break
		end
	end

	-- Update active pill
	updateActivePillPosition(targetKey, true)

	-- Seamless physical spring fade transition
	local slideDir = if newOrder >= prevOrder then 1 else -1
	local slideDist = 40
	local enterOffset = slideDir * slideDist
	local exitOffset = -slideDir * slideDist

	if prevWrapper and prevWrapper ~= newWrapper then
		-- Sync UIStrokes fading out
		for _, stroke in ipairs(prevWrapper:GetDescendants()) do
			if stroke:IsA("UIStroke") then
				if not stroke:GetAttribute("OrigTransparency") then
					stroke:SetAttribute("OrigTransparency", stroke.Transparency)
				end
				Springs.target(stroke, { Transparency = 1 }, "smooth")
			end
		end

		Springs.target(prevWrapper, { Position = UDim2.fromOffset(exitOffset, 0), GroupTransparency = 1 }, "smooth", function()
			if selectedScreen ~= prevKey then
				prevWrapper.Visible = false
				prevWrapper.Position = UDim2.fromOffset(0, 0)
			end
		end)
	end

	local pageScale = newPage:FindFirstChildOfClass("UIScale")
	if not pageScale then
		pageScale = Elements.create("UIScale", newPage, { Name = "ScreenScale", Scale = 1 })
	end

	newWrapper.Position = UDim2.fromOffset(enterOffset, 0)
	newWrapper.GroupTransparency = 1
	newWrapper.Visible = true
	newPage.CanvasPosition = Vector2.zero
	pageScale.Scale = 0.95

	-- Sync UIStrokes fading in
	for _, stroke in ipairs(newWrapper:GetDescendants()) do
		if stroke:IsA("UIStroke") then
			local orig = stroke:GetAttribute("OrigTransparency")
			if not orig then orig = Theme.hairlines.restTransparency end
			stroke.Transparency = 1
			Springs.target(stroke, { Transparency = orig }, "smooth")
		end
	end

	Springs.target(newWrapper, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, "smooth")
	Springs.target(pageScale, { Scale = 1.0 }, "smooth")

	-- Fire screen binding update
	if liveState and screenUpdates[targetKey] then
		for _, cb in ipairs(screenUpdates[targetKey]) do
			cb(liveState)
		end
	end

	-- Re-run layout on target screen
	relayout(targetKey)

	-- Premium staggered flow-in effect
	local children = {}
	for _, child in ipairs(newPage:GetChildren()) do
		if child:IsA("GuiObject") then table.insert(children, child) end
	end
	-- Sort by Y position to cascade downwards
	table.sort(children, function(a, b) return a.Position.Y.Offset < b.Position.Y.Offset end)

	for i, child in ipairs(children) do
		local finalPos = child.Position
		child.Position = finalPos + UDim2.fromOffset(0, 16 + (i * 2))
		if child:IsA("CanvasGroup") then
			child.GroupTransparency = 1
			task.delay((i - 1) * 0.02, function()
				Springs.target(child, { Position = finalPos, GroupTransparency = 0 }, "smooth")
			end)
		else
			task.delay((i - 1) * 0.02, function()
				Springs.target(child, { Position = finalPos }, "smooth")
			end)
		end
	end
end

-- =============================================================================
-- BUILD NAVIGATION BUTTONS
-- =============================================================================
for _, def in ipairs(screenDefs) do
	local btn = Elements.create("TextButton", dockScroll, {
		Name = "Nav_" .. def.key,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
	})

	local icon = Elements.icon(btn, "Icon", def.icon, if def.key == selectedScreen then C.accent else C.textMuted)
	icon.ZIndex = 3

	local label = Elements.text(btn, "Label", def.shortTitle, 12, if def.key == selectedScreen then C.textPrimary else C.textMuted, true)
	label.ZIndex = 3

	btn.MouseEnter:Connect(function()
		if selectedScreen ~= def.key then
			Acoustics.play("hover", 0.04)
			Springs.target(label, { TextColor3 = C.textPrimary }, "smooth")
			Elements.tintIcon(icon, C.textPrimary)
		end
	end)

	btn.MouseLeave:Connect(function()
		if selectedScreen ~= def.key then
			Springs.target(label, { TextColor3 = C.textMuted }, "smooth")
			Elements.tintIcon(icon, C.textMuted)
		end
	end)

	btn.Activated:Connect(function()
		switchScreen(def.key)
	end)

	navButtons[def.key] = { button = btn, icon = icon, label = label }
end

-- Keyboard page stepping (L1/R1 or bracket keys)
connect(UserInputService.InputBegan, function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.ButtonL1 or input.KeyCode == Enum.KeyCode.LeftBracket then
		local orderList = {}
		for _, d in ipairs(screenDefs) do table.insert(orderList, d.key) end
		local curIdx = table.find(orderList, selectedScreen) or 1
		local nextIdx = ((curIdx - 2 + #orderList) % #orderList) + 1
		switchScreen(orderList[nextIdx])
	elseif input.KeyCode == Enum.KeyCode.ButtonR1 or input.KeyCode == Enum.KeyCode.RightBracket then
		local orderList = {}
		for _, d in ipairs(screenDefs) do table.insert(orderList, d.key) end
		local curIdx = table.find(orderList, selectedScreen) or 1
		local nextIdx = (curIdx % #orderList) + 1
		switchScreen(orderList[nextIdx])
	end
end)

-- =============================================================================
-- CONTEXT OBJECT PASSED TO ALL SCREENS
-- =============================================================================
local settingRefreshList: { () -> () } = {}

appContext = {
	Theme = Theme,
	Springs = Springs,
	Elements = Elements,
	Buttons = Buttons,
	Inputs = Inputs,
	Feedback = Feedback,
	Acoustics = Acoustics,
	Odometer = Odometer,
	C = C,

	Config = Config,
	Icons = Icons,
	player = player,
	Shop = Shop,
	director = director,

	state = liveState,
	preferences = preferences,
	selectedScreen = selectedScreen,
	quantity = quantity,

	screens = screens,
	bind = bind,
	layoutScreen = layoutScreen,
	relayout = relayout,

	act = act,
	switchScreen = switchScreen,
	notify = notify,
	showTour = function(step) end, -- Wired after TourGuide creation
	settingRefresh = settingRefreshList,
	savePreferences = function(prefsToSave)
		PreferencesRemote:FireServer(prefsToSave)
	end,
	getLeaderboard = function(category)
		local ok, res = pcall(Leaderboard.InvokeServer, Leaderboard, category)
		return if ok then res else nil
	end,

	fmt = fmt,
	connect = connect,
	defer = defer,
	cancel = cancel,
	own = own,
}

-- Build all 12 screen modules
ScreenCommand.build(appContext)
ScreenOperations.build(appContext)
ScreenHardware.build(appContext)
ScreenResearch.build(appContext)
ScreenSubsystems.build(appContext)
ScreenContracts.build(appContext)
ScreenAllocations.build(appContext)
ScreenMarket.build(appContext)
ScreenSingularity.build(appContext)
ScreenTerminal.build(appContext)
ScreenStandings.build(appContext)
ScreenPreferences.build(appContext)

-- =============================================================================
-- SEARCH PALETTE & TOUR GUIDE INTEGRATION
-- =============================================================================
local searchEntries = SearchIndex.build(screenDefs, Config)
local searchModal = own(SearchPalette.new(gui, searchEntries, function(key)
	switchScreen(key)
end))

searchTrigger.Activated:Connect(function()
	Acoustics.play("input", 0.02)
	searchModal:toggle()
end)

-- Shortcut: Ctrl+K or / toggles SearchPalette
connect(UserInputService.InputBegan, function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Slash then
		searchModal:toggle()
	elseif input.KeyCode == Enum.KeyCode.K and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
		searchModal:toggle()
	end
end)

local tourGuide = own(TourGuide.new(root, Config, act, switchScreen))
appContext.showTour = function(step)
	tourGuide:show(step or 1)
end

-- =============================================================================
-- LOADING OVERLAY (Minimalist Obsidian Boot Screen)
-- =============================================================================
local loading = Elements.create("Frame", root, {
	Name = "LoadingOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.canvas,
	BorderSizePixel = 0,
	ZIndex = 90,
})

local bootCard = Elements.card(loading, "BootCard", 180, C.panel)
bootCard.Size = UDim2.new(0.88, 0, 0, 180)
bootCard.AnchorPoint = Vector2.new(0.5, 0.5)
bootCard.Position = UDim2.fromScale(0.5, 0.5)

Elements.create("UISizeConstraint", bootCard, {
	MaxSize = Vector2.new(420, 180),
	MinSize = Vector2.new(280, 180),
})

local bootBadge = Elements.badge(bootCard, "KERNEL BOOT // INITIALIZING", "azure", true)
Elements.place(bootBadge, 24, 22, 210, 22)

local bootTitle = Elements.text(bootCard, "Title", "DECK INDUSTRIAL SYSTEM", 18, C.textPrimary, true)
bootTitle.Position = UDim2.new(0, 24, 0, 52)
bootTitle.Size = UDim2.new(1, -48, 0, 24)

local bootStatus = Elements.text(bootCard, "Status", "Synchronizing telemetry with host cluster…", 12, C.textSecondary)
bootStatus.Position = UDim2.new(0, 24, 0, 82)
bootStatus.Size = UDim2.new(1, -48, 0, 20)

local bootProgressBar = Inputs.progressBar(bootCard, "ProgressBar", 6, C.accent)
bootProgressBar.instance.Position = UDim2.new(0, 24, 0, 118)
bootProgressBar.instance.Size = UDim2.new(1, -48, 0, 6)

local function dismissLoading()
	bootProgressBar.setProgress(1)
	bootStatus.Text = "System verified. Kernel online."
	task.delay(0.35, function()
		if alive and loading.Parent then
			Springs.target(loading, { BackgroundTransparency = 1 }, "smooth")
			Springs.target(bootCard, { Size = UDim2.new(0.88, 0, 0, 160) }, "smooth")
			task.delay(0.4, function()
				if loading.Parent then loading:Destroy() end
			end)
		end
	end)
end

-- =============================================================================
-- RESPONSIVE VIEWPORT FIT & DOCK LAYOUT
-- =============================================================================
local lastWidth = 0

fit = function()
	if not alive then return end
	local vp = root.AbsoluteSize
	if vp.X <= 0 or vp.Y <= 0 then return end

	local topInset = GuiService:GetGuiInset().Y
	isWideLayout = vp.X >= 900

	-- Topbar layout: seamlessly fills from Y = 0 through topInset + 56
	topbar.Position = UDim2.fromOffset(0, 0)
	topbar.Size = UDim2.new(1, 0, 0, topInset + 56)

	local barCenterY = topInset + 28
	operatorPill.Position = UDim2.new(0, 16, 0, barCenterY)
	telemetryRow.Position = UDim2.new(1, -16, 0, barCenterY)

	if vp.X >= 1100 then
		operatorPill.Visible = true
		operatorPill.Size = UDim2.fromOffset(220, 38)
		opCallsign.Visible = true
		opBreadcrumb.Visible = true
		telemetryRow.Visible = true
		computePill.Size = UDim2.fromOffset(200, 36)
		computeRate.Visible = true
		energyPill.Visible = true
		dataPill.Visible = true
		perfPill.Visible = true
	elseif vp.X >= 880 then
		operatorPill.Visible = true
		operatorPill.Size = UDim2.fromOffset(180, 38)
		opCallsign.Visible = true
		opBreadcrumb.Visible = false
		telemetryRow.Visible = true
		computePill.Size = UDim2.fromOffset(200, 36)
		computeRate.Visible = true
		energyPill.Visible = true
		dataPill.Visible = true
		perfPill.Visible = false
	elseif vp.X >= 640 then
		operatorPill.Visible = true
		operatorPill.Size = UDim2.fromOffset(140, 38)
		opCallsign.Visible = true
		opBreadcrumb.Visible = false
		telemetryRow.Visible = true
		computePill.Size = UDim2.fromOffset(190, 36)
		computeRate.Visible = true
		energyPill.Visible = true
		dataPill.Visible = false
		perfPill.Visible = false
	elseif vp.X >= 480 then
		operatorPill.Visible = true
		operatorPill.Size = UDim2.fromOffset(38, 38)
		opCallsign.Visible = false
		opBreadcrumb.Visible = false
		telemetryRow.Visible = true
		computePill.Size = UDim2.fromOffset(180, 36)
		computeRate.Visible = true
		energyPill.Visible = false
		dataPill.Visible = false
		perfPill.Visible = false
	else
		-- Mobile / tight viewport (<480px)
		operatorPill.Visible = true
		operatorPill.Size = UDim2.fromOffset(38, 38)
		opCallsign.Visible = false
		opBreadcrumb.Visible = false
		telemetryRow.Visible = true
		computePill.Size = UDim2.fromOffset(140, 36)
		computeRate.Visible = false
		energyPill.Visible = false
		dataPill.Visible = false
		perfPill.Visible = false
	end

	-- Overclock banner position
	local ocBannerHeight = if overclockBanner.Visible then 32 else 0
	if overclockBanner.Visible then
		overclockBanner.Position = UDim2.fromOffset(0, topInset + 56)
	end

	local contentStartY = topInset + 56 + ocBannerHeight

	if isWideLayout then
		-- Desktop mode: Left vertical dock rail
		local dockWidth = 190
		dock.Position = UDim2.fromOffset(0, contentStartY)
		dock.Size = UDim2.new(0, dockWidth, 1, -contentStartY)

		local totalNavHeight = #screenDefs * 44 + 20
		dockScroll.CanvasSize = UDim2.new(0, 0, 0, totalNavHeight)

		for i, def in ipairs(screenDefs) do
			local entry = navButtons[def.key]
			if entry then
				entry.button.Size = UDim2.new(0, dockWidth - 20, 0, 38)
				entry.button.Position = UDim2.new(0, 10, 0, 8 + (i - 1) * 42)
				Elements.place(entry.icon, 12, 9, 20, 20)
				entry.label.Position = UDim2.new(0, 40, 0, 0)
				entry.label.Size = UDim2.new(0, dockWidth - 65, 1, 0)
				entry.label.TextXAlignment = Enum.TextXAlignment.Left
			end
		end

		-- Body container
		body.Position = UDim2.fromOffset(dockWidth + 14, contentStartY + 10)
		body.Size = UDim2.new(1, -dockWidth - 28, 1, -contentStartY - 16)

		toasts.container.Position = UDim2.new(1, -20, 1, -20)
		toasts.container.Size = UDim2.fromOffset(340, 300)
	else
		-- Mobile/Compact mode: Bottom horizontal dock bar
		local dockHeight = 62
		dock.Position = UDim2.new(0, 0, 1, -dockHeight)
		dock.Size = UDim2.new(1, 0, 0, dockHeight)

		local navItemWidth = 64
		local totalNavWidth = #screenDefs * (navItemWidth + 6) + 12
		dockScroll.CanvasSize = UDim2.new(0, totalNavWidth, 0, 0)

		for i, def in ipairs(screenDefs) do
			local entry = navButtons[def.key]
			if entry then
				entry.button.Size = UDim2.fromOffset(navItemWidth, 50)
				entry.button.Position = UDim2.new(0, 6 + (i - 1) * (navItemWidth + 6), 0, 6)
				Elements.place(entry.icon, (navItemWidth - 20) / 2, 6, 20, 20)
				entry.label.Position = UDim2.new(0, 0, 0, 28)
				entry.label.Size = UDim2.new(1, 0, 0, 18)
				entry.label.TextXAlignment = Enum.TextXAlignment.Center
			end
		end

		-- Body container
		local bodyHeight = vp.Y - contentStartY - dockHeight - 16
		body.Position = UDim2.fromOffset(12, contentStartY + 8)
		body.Size = UDim2.new(1, -24, 0, math.max(1, bodyHeight))

		toasts.container.Position = UDim2.new(1, -16, 1, -74)
		toasts.container.Size = UDim2.new(0, math.min(340, vp.X - 32), 0, 300)
	end

	updateActivePillPosition(selectedScreen, false)

	local currentBodyWidth = body.AbsoluteSize.X
	if lastWidth ~= currentBodyWidth and currentBodyWidth > 0 then
		lastWidth = currentBodyWidth
		for key, layoutFn in pairs(screenLayouts) do
			layoutFn(currentBodyWidth - 12)
		end
	end
end

connect(root:GetPropertyChangedSignal("AbsoluteSize"), fit)
connect(GuiService:GetPropertyChangedSignal("TopbarInset"), fit)
fit()

-- Initial Navigation State
updateActivePillPosition(selectedScreen, false)

-- Remote Event Listeners
connect(Changed.OnClientEvent, function(s)
	apply(s)
	dismissLoading()
end)

connect(gui.Destroying, dispose)
connect(script.Destroying, dispose)

-- =============================================================================
-- INITIAL STATE HYDRATION & TELEMETRY LOOPS
-- =============================================================================
task.spawn(function()
	bootProgressBar.setProgress(0.2)
	bootStatus.Text = "Querying state snapshot..."

	for attempt = 1, 5 do
		bootProgressBar.setProgress(0.2 + attempt * 0.15)
		local ok, result = pcall(GetState.InvokeServer, GetState)
		if ok and type(result) == "table" then
			apply(result)
			dismissLoading()
			return
		end
		task.wait(1)
	end

	if alive and not hydrated then
		bootStatus.Text = "Connection attempt exhausted. Retrying in background…"
		notify("Fleet record unavailable. Rejoining may be required.", true, "NETWORK OFFLINE")
	end
end)

-- Performance Telemetry Loop (FPS calculation + Roundtrip Ping)
do
	local frameCount = 0
	local elapsed = 0
	local livePing: number? = nil

	connect(RunService.RenderStepped, function(dt)
		frameCount += 1
		elapsed += dt
		if elapsed >= 1 then
			local fps = math.floor(frameCount / elapsed + 0.5)
			perfLabel.Text = string.format("%d FPS · %s", fps, if livePing then tostring(livePing) .. "ms" else "--")
			frameCount = 0
			elapsed = 0

			-- Live overclock countdown tick
			if wasOverclocked and lastBoostUntil > 0 then
				local now = workspace:GetServerTimeNow()
				local rem = math.max(0, math.floor(lastBoostUntil - now + 0.5))
				if rem > 0 then
					ocText.Text = string.format("⚡ HIGH-VOLTAGE OVERCLOCK ENGAGED — COMPUTE RATE MULTIPLIED BY 2.0× (%ds)", rem)
				else
					wasOverclocked = false
					lastBoostUntil = 0
					overclockBanner.Visible = false
					if fit then fit() end
				end
			end
		end
	end)

	task.spawn(function()
		while alive do
			local start = os.clock()
			local ok = pcall(Ping.InvokeServer, Ping)
			if ok then
				livePing = math.floor((os.clock() - start) * 1000)
			end
			task.wait(6)
		end
	end)
end

return true
