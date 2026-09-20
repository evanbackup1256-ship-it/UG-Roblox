local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Package = script.Parent
local Changed = Package:WaitForChild("Changed")
local Action = Package:WaitForChild("Action")
local GetState = Package:WaitForChild("GetState")
local Preferences = Package:WaitForChild("Preferences")
local Ping = Package:WaitForChild("Ping")
local Leaderboard = Package:WaitForChild("Leaderboard")

local Config = require(Package.Config)
local Kit = require(Package.DesignKit)
local Icons = require(Package.Icons)
local PreviewDirector = require(Package.PreviewDirector)
local Shop = require(Package.ShopService)
local InterfaceShared = require(Package.InterfaceShared)
local MusicManager = require(Package.MusicManager)
local Toast = require(Package.Interface.Toast)
local Audio = require(Package.Interface.Audio)
local Tutorial = require(Package.Interface.Tutorial)
local GlobalSearch = require(Package.Interface.GlobalSearch)
local SearchIndex = require(Package.SearchIndex)
local ThemePresets = require(Package.DesignKit.ThemePresets)
local Tokens = require(Package.DesignKit.Tokens)
local SpringDriver = require(Package.DesignKit.SpringDriver)

local C = Kit.colors
local player = Players.LocalPlayer
local studioDiagnostics = RunService:IsStudio()

local function trace(message, ...)
	if not studioDiagnostics then
		return
	end

	if select("#", ...) == 0 then
		print("[Deck/UI] " .. message)
	else
		print(string.format("[Deck/UI] " .. message, ...))
	end
end

local function traceWarn(message, ...)
	if not studioDiagnostics then
		return
	end

	if select("#", ...) == 0 then
		warn("[Deck/UI] " .. message)
	else
		warn(string.format("[Deck/UI] " .. message, ...))
	end
end

local ACTION_CUES = {
	operation = "operation",
	module = "upgrade",
	research = "upgrade",
	buy = "purchase",
	buyPackage = "purchase",
	daily = "reward",
	claim = "reward",
	achievement = "milestone",
	code = "reward",
	prestige = "milestone",
}

local UNITS = {
	{ 1e15, "Q" },
	{ 1e12, "T" },
	{ 1e9, "B" },
	{ 1e6, "M" },
	{ 1e3, "K" },
}

local alive = true
local owned = {}
local transient = {}

local function own(item)
	owned[#owned + 1] = item
	return item
end

local function connect(signal, callback)
	return own(signal:Connect(callback))
end

local function release(item)
	local kind = typeof(item)
	if kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "thread" then
		if coroutine.status(item) == "suspended" then
			task.cancel(item)
		end
	elseif kind == "Instance" then
		item:Destroy()
	elseif kind == "function" then
		item()
	elseif kind == "table" then
		local method = item.Destroy or item.destroy or item.Disconnect
		if type(method) == "function" then
			method(item)
		end
	end
end

local function dispose()
	if not alive then
		return
	end
	trace("shutdown: releasing interface resources")
	alive = false

	for thread in transient do
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end
	table.clear(transient)

	for index = #owned, 1, -1 do
		local item = owned[index]
		owned[index] = nil
		local ok, err = pcall(release, item)
		if not ok then
			warn("DeckInterface cleanup failed:", err)
		end
	end
end

local function run(callback, ...)
	local thread = task.spawn(function(...)
		callback(...)
		transient[coroutine.running()] = nil
	end, ...)

	if coroutine.status(thread) ~= "dead" then
		transient[thread] = true
	end
	return thread
end

local function defer(seconds, callback, ...)
	local thread = task.delay(seconds, function(...)
		transient[coroutine.running()] = nil
		if alive then
			callback(...)
		end
	end, ...)
	transient[thread] = true
	return thread
end

local function cancel(thread)
	if thread and transient[thread] then
		transient[thread] = nil
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end
end

local function deepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	local existing = seen[value]
	if existing then
		return existing
	end

	local copy = table.clone(value)
	seen[value] = copy

	for key, item in copy do
		if type(item) == "table" then
			copy[key] = deepCopy(item, seen)
		end
	end

	return copy
end

local function deepFreeze(value)
	if type(value) == "table" and not table.isfrozen(value) then
		table.freeze(value)
		for _, item in value do
			deepFreeze(item)
		end
	end
	return value
end

local function fmt(value)
	value = tonumber(value) or 0
	for _, unit in UNITS do
		if value >= unit[1] then
			return string.format("%.1f%s", value / unit[1], unit[2])
		end
	end
	return if value % 1 == 0 then tostring(value) else string.format("%.1f", value)
end

local preferences = deepCopy(Config.Settings)
preferences.accentTheme = Config.DefaultAccentTheme
local state
local pending = false
local requestSerial = 0
local selected = "overview"
local hydrated = false

-- Kit.setValue pops a number with a little scale-bump whenever its text
-- changes. That reads great for something the player just caused (buying
-- hardware, clearing a job, claiming a reward) but turns into constant
-- background jitter for numbers that change every idle production tick
-- (balance, rate) while nobody touched anything. This flag is true only
-- while `apply` is handling the direct response to the player's own
-- action, so passive server pushes update text without popping it.
local userCaused = false
local function bumpPeak(peak)
	return if userCaused then peak else false
end

local pages, layouts, updates, nav = {}, {}, {}, {}
local switchPage, apply, act, notify, showTutorial, revealPageChange

-- Forward-declared here (rather than only built once every dependency
-- exists) because act/notify are defined before most of the rest of this
-- file runs, and both need to keep Shared.pending/Shared.userCaused in
-- sync as they mutate their own local upvalues of the same name. Shared.fn
-- is pre-populated with no-op placeholders for the six mutually-recursive
-- functions so a page module calling Shared.fn.switchPage(...) before
-- switchPage is actually assigned (impossible in practice, since that can
-- only happen from a button click after the whole file has loaded, but
-- kept safe regardless) never hits a nil call.
local Shared: InterfaceShared.Shared = {
	quantity = 1,
	fn = {
		switchPage = function(...) end,
		apply = function(...) end,
		act = function(...) end,
		notify = function(...) end,
		showTutorial = function(...) end,
		revealPageChange = function(...) end,
		settingRefresh = {},
		stopDrag = function() end,
	},
} :: any

own(function()
	state = nil
	table.clear(pages)
	table.clear(layouts)
	table.clear(updates)
	table.clear(nav)
end)

local previousSound = Kit.sound
own(function()
	Kit.sound = previousSound
end)

local audioSystem = Audio.new(Kit, preferences, function() return alive end, defer, trace, own)
local audio = audioSystem.audioFolder
local musicManager = own(MusicManager.new(Kit, audio))
local musicMix = musicManager:GetSoundGroup()

Kit.sound = function(name)
	audioSystem.playCue(name, musicMix)
end

local pulses = {}

local function pulse(object, period, goal, rest, gated, page)
	local entry = {
		tween = own(TweenService:Create(
			object,
			TweenInfo.new(period, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			goal
			)),
		object = object,
		rest = rest,
		gated = gated,
		page = page,
		enabled = true,
	}
	table.insert(pulses, entry)
	return entry
end

local function syncPulses()
	for _, entry in pulses do
		local wanted = entry.enabled
			and (not entry.gated or preferences.motion)
			and (entry.page == nil or entry.page == selected)
		local playing = entry.tween.PlaybackState == Enum.PlaybackState.Playing

		if wanted and not playing then
			entry.tween:Play()
		elseif not wanted and playing then
			entry.tween:Cancel()
			for property, value in entry.rest do
				entry.object[property] = value
			end
		end
	end
end

own(function()
	table.clear(pulses)
end)

-- Kit.button already drives its own hover/press UIScale tween, so this used
-- to attach a second, independent hover/press animation on that same scale
-- property — the two tweens raced each other on every hover and click,
-- which read as the button jittering instead of responding cleanly. Kept as
-- a passthrough so call sites don't need to change.
local function liven(button)
	return button
end

local function bump(label)
	local scale = Kit.create("UIScale", label, { Name = "BumpScale", Scale = 1 })
	return function()
		if not preferences.motion then
			return
		end
		scale.Scale = 1.28
		Kit.animate(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	end
end

local appliedAccentTheme = nil

local function refreshPresentation()
	Kit.motion = preferences.motion

	local pageMix = if selected == "operations" then 1.08 elseif selected == "settings" then 0.72 else 0.9

	musicManager:RefreshVolume(preferences.masterVolume, preferences.musicVolume, pageMix)
	musicManager:SetPlaying(preferences.music)

	if preferences.accentTheme ~= appliedAccentTheme then
		local preset = ThemePresets.presets[preferences.accentTheme] or ThemePresets.presets[ThemePresets.default]
		appliedAccentTheme = preferences.accentTheme
		for swatch, color in preset do
			Kit.Theme.set(swatch, color)
		end
	end

	syncPulses()
end

local gui = own(Kit.create("ScreenGui", player:WaitForChild("PlayerGui"), {
	Name = "DeckEmpire",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}))

local function setCoreBars(enabled)
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, enabled)
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.PlayerList, enabled)
end

setCoreBars(false)
own(function()
	setCoreBars(true)
end)

local root = Kit.create("Frame", gui, {
	Name = "Workspace",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.background,
	BorderSizePixel = 0,
})

local loading = Kit.create("CanvasGroup", root, {
	Name = "LoadingScreen",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.background,
	BorderSizePixel = 0,
	GroupTransparency = 0,
	ZIndex = 100,
})

local loadingBrand = Kit.text(loading, "Brand", "DECK//OPS", 30, C.text, true)
loadingBrand.Font = Enum.Font.RobotoMono
loadingBrand.AnchorPoint = Vector2.new(0.5, 0.5)
loadingBrand.Position = UDim2.new(0.5, 0, 0.42, 0)
loadingBrand.Size = UDim2.fromOffset(220, 54)
loadingBrand.TextXAlignment = Enum.TextXAlignment.Center
loadingBrand.ZIndex = 101

local loadingStatus = Kit.text(loading, "Status", "OPENING CONTROL ROOM", 11, C.muted, true)
loadingStatus.Font = Enum.Font.RobotoMono
loadingStatus.AnchorPoint = Vector2.new(0.5, 0.5)
loadingStatus.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingStatus.Size = UDim2.fromOffset(320, 24)
loadingStatus.TextXAlignment = Enum.TextXAlignment.Center
loadingStatus.ZIndex = 101

local loadingTrack, loadingFill = Kit.progress(loading, "Progress")
loadingTrack.AnchorPoint = Vector2.new(0.5, 0.5)
loadingTrack.Position = UDim2.new(0.5, 0, 0.55, 0)
loadingTrack.Size = UDim2.fromOffset(280, 4)
loadingTrack.ZIndex = 101
loadingFill.ZIndex = 102

local loadingTip = Kit.text(loading, "Tip", "Syncing your last known fleet state.", 12, C.muted)
loadingTip.AnchorPoint = Vector2.new(0.5, 0.5)
loadingTip.Position = UDim2.new(0.5, 0, 0.62, 0)
loadingTip.Size = UDim2.fromOffset(520, 32)
loadingTip.TextXAlignment = Enum.TextXAlignment.Center
loadingTip.TextWrapped = true
loadingTip.ZIndex = 101

local loadingStarted = os.clock()
local loadingPulse = pulse(loadingBrand, 0.62, { TextTransparency = 0.2 }, { TextTransparency = 0 }, false, nil)

local function loadingSet(progress, message)
	if not loading.Parent then
		return
	end
	trace("loading: %d%% %s", math.floor(progress * 100 + 0.5), message)
	loadingStatus.Text = string.upper(message)
	Kit.animate(loadingFill, { Size = UDim2.fromScale(progress, 1) }, 0.35)
end

loadingSet(0.18, "Mapping controls")
Kit.sound("boot")

-- Bottom tab bar (was a left sidebar rail — Name kept as "Navigation" for
-- continuity, only its geometry/orientation changed).
local rail = Kit.create("Frame", root, {
	Name = "Navigation",
	BackgroundColor3 = C.navigation,
	BorderSizePixel = 0,
})
Kit.stroke(rail, C.line, 0.7, false)

Kit.create("Frame", rail, {
	Name = "Edge",
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = C.line,
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
})

local wordmark = Kit.text(rail, "Wordmark", "DECK EMPIRE", 18, C.text, true)
wordmark.Font = Tokens.font.bold

local railLed = Kit.statusDot(rail, C.compute, "Online", 6)

local edition = Kit.text(rail, "Edition", "FLEET OPERATIONS", 9, C.textSub, true)
edition.Font = Tokens.font.mono

local navScroll = Kit.create("ScrollingFrame", rail, {
	Name = "Destinations",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.fromOffset(0, 400),
})

local navIndicator = Kit.create("Frame", navScroll, {
	Name = "NavActiveIndicator",
	BackgroundColor3 = C.accent,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(172, 46),
	Position = UDim2.fromOffset(4, 0),
	ZIndex = 1,
})
Kit.corner(navIndicator, Kit.radius.control)
Kit.Theme.paint(navIndicator, "BackgroundColor3", "accent")

local avatar = Kit.create("ImageLabel", rail, {
	Name = "Avatar",
	BackgroundColor3 = C.raised,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(34, 34),
})
Kit.corner(avatar, 17)

run(function()
	local ok, image = pcall(
		Players.GetUserThumbnailAsync,
		Players,
		player.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size100x100
	)
	if ok and alive then
		avatar.Image = image
	end
end)

local username = Kit.text(rail, "Player", player.DisplayName, 13, C.text, true)
local role = Kit.text(rail, "Role", "shift operator", 11, C.muted)

local header = Kit.create("Frame", root, {
	Name = "Topbar",
	BackgroundTransparency = 1,
})

local crumb = Kit.text(header, "Location", "WORKSPACE  /  OVERVIEW", 11, C.muted, true)
crumb.Font = Enum.Font.RobotoMono

local capsulesRack = Kit.create("Frame", header, {
	Name = "CapsulesRack",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})

local computeCapsule = Kit.create("Frame", capsulesRack, {
	Name = "ComputeCapsule",
	BackgroundColor3 = C.raised,
	BorderSizePixel = 0,
})
Kit.corner(computeCapsule, Kit.radius.pill)
local computeStroke = Kit.stroke(computeCapsule, C.line, 0.4)
Kit.Theme.paint(computeCapsule, "BackgroundColor3", "raised")
Kit.Theme.paint(computeStroke, "Color", "line")

local computeIcon = Kit.icon(computeCapsule, "Icon", "overview", C.compute)
Kit.place(computeIcon, 10, 8, 18, 18)

local balance = Kit.text(computeCapsule, "Balance", "— compute", 13, C.text, true)
balance.Font = Enum.Font.RobotoMono
Kit.place(balance, 32, 2, 78, 30)

local rateBadge = Kit.text(computeCapsule, "RateBadge", "+0/s", 11, C.compute, true)
rateBadge.Font = Enum.Font.RobotoMono
rateBadge.TextXAlignment = Enum.TextXAlignment.Right
Kit.place(rateBadge, 110, 2, 62, 30)

local energyCapsule = Kit.create("Frame", capsulesRack, {
	Name = "EnergyCapsule",
	BackgroundColor3 = C.raised,
	BorderSizePixel = 0,
})
Kit.corner(energyCapsule, Kit.radius.pill)
local energyStroke = Kit.stroke(energyCapsule, C.line, 0.4)
Kit.Theme.paint(energyCapsule, "BackgroundColor3", "raised")
Kit.Theme.paint(energyStroke, "Color", "line")

local energyIcon = Kit.icon(energyCapsule, "Icon", "energy", C.energy)
Kit.place(energyIcon, 8, 8, 18, 18)

local energyVal = Kit.text(energyCapsule, "EnergyVal", "—", 12, C.energy, true)
energyVal.Font = Enum.Font.RobotoMono
Kit.place(energyVal, 28, 2, 58, 30)

local dataCapsule = Kit.create("Frame", capsulesRack, {
	Name = "DataCapsule",
	BackgroundColor3 = C.raised,
	BorderSizePixel = 0,
})
Kit.corner(dataCapsule, Kit.radius.pill)
local dataStroke = Kit.stroke(dataCapsule, C.line, 0.4)
Kit.Theme.paint(dataCapsule, "BackgroundColor3", "raised")
Kit.Theme.paint(dataStroke, "Color", "line")

local dataIcon = Kit.icon(dataCapsule, "Icon", "data", C.data)
Kit.place(dataIcon, 8, 8, 18, 18)

local dataVal = Kit.text(dataCapsule, "DataVal", "—", 12, C.data, true)
dataVal.Font = Enum.Font.RobotoMono
Kit.place(dataVal, 28, 2, 48, 30)

local telemetryCapsule = Kit.create("Frame", capsulesRack, {
	Name = "TelemetryCapsule",
	BackgroundColor3 = C.raised,
	BorderSizePixel = 0,
})
Kit.corner(telemetryCapsule, Kit.radius.pill)
local telemetryStroke = Kit.stroke(telemetryCapsule, C.line, 0.4)
Kit.Theme.paint(telemetryCapsule, "BackgroundColor3", "raised")
Kit.Theme.paint(telemetryStroke, "Color", "line")

local teleDot = Kit.statusDot(telemetryCapsule, C.accent, "Live", 8)
Kit.place(teleDot, 10, 13, 8, 8)

local telemetry = Kit.text(telemetryCapsule, "Telemetry", "FPS — · PING —", 11, C.muted, true)
telemetry.Font = Enum.Font.RobotoMono
Kit.place(telemetry, 24, 2, 100, 30)

Kit.create("Frame", header, {
	Name = "Divider",
	Position = UDim2.new(0, 0, 1, -1),
	Size = UDim2.new(1, 0, 0, 1),
	BorderSizePixel = 0,
	BackgroundColor3 = C.line,
})

local overclockBanner = Kit.create("Frame", root, {
	Name = "OverclockBanner",
	BackgroundColor3 = C.overclock,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Visible = false,
	ZIndex = 50,
})
Kit.corner(overclockBanner, Tokens.radius.control)
Kit.stroke(overclockBanner, Color3.fromRGB(255, 255, 255), 0.7, false)
local bannerLabel = Kit.text(overclockBanner, "Text", "⚡ Overclock Active — Fleet Output 2.0x", 12, Color3.fromRGB(255, 255, 255), true)
bannerLabel.TextXAlignment = Enum.TextXAlignment.Center
bannerLabel.Size = UDim2.fromScale(1, 1)

local body = Kit.create("Frame", root, {
	Name = "Pages",
	BackgroundTransparency = 1,
	ClipsDescendants = true,
})

local director = own(PreviewDirector.new(gui, preferences))

-- Toast.new registers its own cleanup via the `own` callback it's given
-- internally, so its return value doesn't need wrapping in own() itself.
local toast = Toast.new(root, Kit, C, Icons, preferences, function() return alive end, connect, own)
local fitToasts = toast.fit
notify = toast.notify

Shared.fn.notify = notify

act = function(kind, key, amount, silent)
	if pending or not state or not alive then
		traceWarn("action blocked: kind=%s pending=%s hydrated=%s", tostring(kind), tostring(pending), tostring(state ~= nil))
		return
	end

	-- Shared.quantity is the Infrastructure page's buy-quantity selector,
	-- read here (rather than a local) since act() is defined before that
	-- page module builds — this only ever runs later, at click time, by
	-- which point Shared.quantity reflects whatever the player selected.
	local argument = if amount ~= nil then amount elseif kind == "buy" then Shared.quantity else nil

	requestSerial += 1
	local serial = requestSerial
	local expired = false
	pending = true
	Shared.pending = true
	trace("action request: #%d kind=%s key=%s amount=%s", serial, tostring(kind), tostring(key), tostring(argument))

	local watchdog = defer(12, function()
		if requestSerial == serial and pending then
			expired = true
			pending = false
			Shared.pending = false
			traceWarn("action timeout: #%d kind=%s", serial, tostring(kind))
			notify("Server did not respond. Try again.", false)
		end
	end)

	run(function()
		local ok, result = pcall(Action.InvokeServer, Action, kind, key, argument)

		cancel(watchdog)
		if requestSerial == serial then
			pending = false
			Shared.pending = false
		end

		if not alive then
			return
		end

		if ok and type(result) == "table" then
			userCaused = true
			Shared.userCaused = true
			apply(result.state)
			userCaused = false
			Shared.userCaused = false
			trace(
				"action response: #%d kind=%s ok=%s message=%s",
				serial,
				tostring(kind),
				tostring(result.ok),
				tostring(result.message)
			)
			if not silent and (kind ~= "job" or not result.ok) then
				notify(result.message, result.ok, ACTION_CUES[kind])
			end
		elseif not expired then
			traceWarn("action transport failed: #%d kind=%s", serial, tostring(kind))
			notify("Connection interrupted. Try again.", false)
		end
	end)
end

Shared.fn.act = act

local definitions = {
	{ "overview", "Control", "Network status", "Capacity, cash flow, and the next job in queue." },
	{ "operations", "Dispatch", "Dispatch board", "Spend energy on live work. Failed runs still return field data." },
	{ "infrastructure", "Hardware", "Hardware inventory", "Purchase capacity. New units begin producing immediately." },
	{ "research", "Lab", "Systems lab", "Fund changes that alter costs, throughput, and response time." },
	{ "modules", "Firmware", "Firmware rack", "Install permanent behavior changes using compute and field data." },
	{ "contracts", "Work orders", "Open work orders", "Hit the stated target, close the ticket, collect payment." },
	{ "rewards", "Claims", "Claims desk", "Daily allocation and completed account milestones." },
	{ "shop", "Procurement", "Procurement desk", "Preconfigured lots priced below individual deployment cost." },
	{ "prestige", "Relaunch", "Fleet relaunch", "Reset production for prestige tokens that permanently boost throughput." },
	{ "events", "Bulletins", "Operator bulletins", "Release notes, active codes, and service notices." },
	{ "leaderboard", "Standings", "Fleet standings", "See how your operation compares. Rankings update periodically, not live." },
	{ "settings", "Console", "Console setup", "Sound, motion, rendering, and notification behavior." },
}

local function positionText(parent, name, copy, x, y, width, height, size, color, bold)
	return Kit.place(Kit.text(parent, name, copy, size, color, bold), x, y, width, height)
end

local searchEntries = SearchIndex.build(definitions, Config)
local globalSearch = GlobalSearch.new(header, root, Kit, C, searchEntries, function(key) switchPage(key) end, connect)

-- Reuses `definitions`'s existing order as the single source of page order
-- rather than a second hardcoded list (LB/RB page-cycling below).
local pageOrder = {}
for index, definition in ipairs(definitions) do
	pageOrder[index] = definition[1]
end

connect(UserInputService.InputBegan, function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.ButtonL1 or input.KeyCode == Enum.KeyCode.ButtonR1 then
		local index = table.find(pageOrder, selected) or 1
		local delta = if input.KeyCode == Enum.KeyCode.ButtonR1 then 1 else -1
		switchPage(pageOrder[((index - 1 + delta) % #pageOrder) + 1])
	end
end)

for index, definition in ipairs(definitions) do
	local key, title = definition[1], definition[2]

	local button = Kit.button(navScroll, "Nav_" .. key, "", function()
		switchPage(key)
	end, "nav")
	Kit.place(button, 0, (index - 1) * 54, 180, 46)
	button.BackgroundTransparency = 1
	button.ZIndex = 2
	Kit.corner(button, Kit.radius.control)

	local icon = Kit.place(
		if key == "prestige" then Kit.rocketIcon(button, "Icon", C.muted) else Kit.icon(button, "Icon", key),
		16, 12, 22, 22
	)
	icon.ZIndex = 3
	local caption = positionText(button, "Caption", title, 50, 0, 140, 46, 13, C.muted, true)
	caption.ZIndex = 3

	button.MouseEnter:Connect(function()
		if selected ~= key then
			Kit.animate(caption, { TextColor3 = C.text }, 0.15)
			Kit.tintIcon(icon, C.text)
		end
	end)
	button.MouseLeave:Connect(function()
		if selected ~= key then
			Kit.animate(caption, { TextColor3 = C.muted }, 0.18)
			Kit.tintIcon(icon, C.muted)
		end
	end)

	nav[key] = {
		button = button,
		icon = icon,
		caption = caption,
		scale = button:FindFirstChildOfClass("UIScale"),
	}

	local page = Kit.create("ScrollingFrame", body, {
		Name = key,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.line,
		CanvasSize = UDim2.fromOffset(0, 0),
		Visible = key == selected,
	})

	pages[key] = page
	updates[key] = {}

	local titleLabel = positionText(page, "Heading", definition[3], 0, 22, 800, 50, 32, C.text, true)
	titleLabel.TextWrapped = true
	titleLabel.TextTruncate = Enum.TextTruncate.None

	local detail = positionText(page, "Description", definition[4], 0, 77, 800, 36, 13, C.muted)
	detail.TextWrapped = true

	layouts[key] = function(width)
		local tight = width < 450
		titleLabel.Size = UDim2.fromOffset(width, if tight then 62 else 50)
		titleLabel.TextSize = if tight then 25 else 32
		detail.Position = UDim2.fromOffset(0, if tight then 87 else 77)
		detail.Size = UDim2.fromOffset(width, 36)
	end
end

local function bind(page, callback)
	table.insert(updates[page], callback)
end

local function layoutPage(key, callback)
	local heading = layouts[key]
	layouts[key] = function(width)
		heading(width)
		pages[key].CanvasSize = UDim2.fromOffset(0, callback(width) + 28)
	end
end

local function relayout(key)
	local layout = layouts[key]
	if layout then
		layout(body.AbsoluteSize.X - 8)
	end
end

-- Fill in the context every InterfacePage* module receives as its single
-- argument (forward-declared near the top of this file, alongside
-- switchPage/apply/act/etc., since act/notify are defined before this
-- point and need Shared to already exist as a local so they can keep it in
-- sync — see the `Shared.pending = pending` etc. lines at each mutation
-- site below and inside act/apply/switchPage).
--
-- Mutable fields (state/preferences/selected/pending/hydrated/userCaused)
-- are reassigned in place by this file and read fresh by page modules on
-- every access, never cached — this is how the split reproduces today's
-- upvalue-reassignment semantics without every page needing its own copy.
-- Shared.fn holds the six mutually-forward-declared functions: page
-- modules must always call Shared.fn.X(...) inline at the callback site
-- (never `local x = Shared.fn.X` cached at build time), since several of
-- these are only assigned their real value further down this file, after
-- every page module's build() has already run and captured Shared by
-- reference.
Shared.Kit = Kit
Shared.Config = Config
Shared.Icons = Icons
Shared.C = C
Shared.Tokens = Tokens
Shared.SpringDriver = SpringDriver
Shared.director = director
Shared.player = player
Shared.Shop = Shop

Shared.state = state
Shared.preferences = preferences
Shared.selected = selected
Shared.pending = pending
Shared.hydrated = hydrated
Shared.userCaused = userCaused

Shared.own = own
Shared.connect = connect
Shared.release = release
Shared.run = run
Shared.defer = defer
Shared.cancel = cancel

Shared.pages = pages
Shared.layouts = layouts
Shared.updates = updates
Shared.nav = nav
Shared.bind = bind
Shared.layoutPage = layoutPage
Shared.relayout = relayout
Shared.positionText = positionText

Shared.liven = liven
Shared.bump = bump
Shared.fmt = fmt
Shared.bumpPeak = bumpPeak
Shared.trace = trace
Shared.traceWarn = traceWarn
Shared.refreshPresentation = refreshPresentation
Shared.Preferences = Preferences
Shared.Leaderboard = Leaderboard

require(Package.InterfacePageOverview).build(Shared)

require(Package.InterfacePageOperations).build(Shared)

local function pager(page, onPrevious, onNext)
	local previous = Kit.button(page, "PreviousPage", "Previous", onPrevious)
	local label = Kit.text(page, "Page", "PAGE 1 / 1", 11, C.muted, true)
	label.TextXAlignment = Enum.TextXAlignment.Center
	local following = Kit.button(page, "NextPage", "Next", onNext)

	return function(w, y, current, total, count, noun)
		local side = math.min(120, (w - 12) / 3)
		local labelX = side + 6
		local labelWidth = math.max(1, w - (side + 6) * 2)

		label.Text = if w < 450
			then string.format("%d / %d", current, total)
			else string.format("PAGE %d / %d  ·  %d %s", current, total, count, noun)

		Kit.place(previous, 0, y, side, 42)
		Kit.place(label, labelX, y, labelWidth, 42)
		Kit.place(following, w - side, y, side, 42)

		Kit.enable(previous, current > 1, "Previous", false)
		Kit.enable(following, current < total, "Next", false)
	end
end

Shared.pager = pager

require(Package.InterfacePageInfrastructure).build(Shared)

require(Package.InterfacePageResearch).build(Shared)

require(Package.InterfacePageModules).build(Shared)

require(Package.InterfacePageContracts).build(Shared)

require(Package.InterfacePageRewards).build(Shared)

require(Package.InterfacePageShop).build(Shared)

require(Package.InterfacePagePrestige).build(Shared)

require(Package.InterfacePageEvents).build(Shared)

require(Package.InterfacePageLeaderboard).build(Shared)

-- Same table as Shared.fn.settingRefresh (not a copy): both this file's own
-- startup sequence/apply() below and InterfacePageSettings' table.insert
-- calls append to one shared list.
local settingRefresh = Shared.fn.settingRefresh

require(Package.InterfacePageSettings).build(Shared)

do
	local pageTargets = {}
	for key, page in pages do
		local targets = {}
		for _, object in page:GetChildren() do
			if object:IsA("Frame") then
				table.insert(targets, object)
			end
		end
		pageTargets[key] = targets
	end

	-- Pagination (pager()'s onPrevious/onNext) swaps which cards in
	-- pageTargets[key] are Visible via relayout(), but that's an instant
	-- jump-cut on its own. This gives it the same light fade+pop switchPage
	-- already uses for a full page entrance, scoped to just the cards that
	-- are visible after the swap, with its own small TweenInfo tables
	-- (reusing pageTargets directly rather than duplicating the child-scan).
	local PAGE_FADE, PAGE_POP = {}, {}
	for step = 0, 5 do
		PAGE_FADE[step] = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, step * 0.02)
		PAGE_POP[step] = TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, step * 0.02)
	end

	revealPageChange = function(key)
		Kit.sound("flip")
		if not preferences.motion then
			return
		end

		local step = 0
		for _, object in ipairs(pageTargets[key] or {}) do
			if object.Visible and step <= 5 then
				-- Reuses the same "RevealScale" child switchPage's stagger
				-- creates on this object (rather than a second, separately
				-- named UIScale) — Roblox only honors one UIScale per
				-- object, so two competing siblings here would silently
				-- break one of the two animation systems, the same class
				-- of bug liven() used to cause on buttons.
				local scale = object:FindFirstChild("RevealScale")
				if not scale then
					scale = Kit.create("UIScale", object, { Name = "RevealScale", Scale = 1 })
				end

				object.BackgroundTransparency = 0.5
				scale.Scale = 0.985

				local fadeTween = TweenService:Create(object, PAGE_FADE[step], { BackgroundTransparency = 0 })
				Kit.Scheduler.track(object, "reveal", fadeTween)
				fadeTween:Play()

				local popTween = TweenService:Create(scale, PAGE_POP[step], { Scale = 1 })
				Kit.Scheduler.track(scale, "reveal", popTween)
				popTween:Play()

				step += 1
			end
		end
	end

	Shared.fn.revealPageChange = revealPageChange

	local revealScales = {}
	local REVEAL_FADE, REVEAL_POP = {}, {}
	for step = 0, 5 do
		REVEAL_FADE[step] = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, step * 0.035)
		REVEAL_POP[step] = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, step * 0.035)
	end

	own(function()
		table.clear(pageTargets)
		table.clear(revealScales)
	end)

	switchPage = function(key)
		if not alive or not pages[key] then
			return
		end

		Shared.fn.stopDrag()

		local previous = selected
		local motion = preferences.motion
		selected = key
		Shared.selected = key

		for name, page in pages do
			page.Visible = name == key
		end

		local index = table.find(pageOrder, key) or 1
		local compact = root.AbsoluteSize.X < 1000
		local barHeight = 72
		local navStep = if compact then 68 else 84
		local navHeight = barHeight - 12
		local targetPos = UDim2.fromOffset((index - 1) * navStep + 4, 2)
		local targetSize = UDim2.fromOffset(navStep - 8, navHeight - 4)
		navIndicator.Size = targetSize

		if motion then
			SpringDriver.animate(navIndicator, "slide", { Position = targetPos }, "snappy")
		else
			navIndicator.Position = targetPos
		end

		for name, item in nav do
			local active = name == key
			item.button.BackgroundTransparency = 1

			if item.scale then
				-- Bottom-tab-bar active-state mechanic: bounce-up + scale-up
				-- on the icon itself, replacing the old subtle 1.03x nudge —
				-- bounce is now the default interaction character.
				Kit.animate(item.scale, { Scale = if active then 1.25 else 1 }, "bouncy")
			end
			if item.icon then
				local restY = if compact then 6 else 6
				Kit.animate(item.icon, { Position = UDim2.new(0.5, -11, 0, if active then restY - 4 else restY) }, "bouncy")
			end

			item.caption.TextColor3 = if active then C.ink else C.muted
			Kit.tintIcon(item.icon, if active then C.ink else C.muted)
		end

		crumb.Text = "Workspace  /  " .. nav[key].caption.Text
		crumb.TextTransparency = if motion then 0.55 else 0
		Kit.animate(crumb, { TextTransparency = 0 }, 0.32)

		refreshPresentation()

		if state then
			for _, callback in ipairs(updates[key]) do
				callback(state)
			end
		end

		local page = pages[key]
		page.CanvasPosition = Vector2.zero
		page.Position = UDim2.fromOffset(if motion then 36 else 0, 0)
		if motion then
			SpringDriver.animate(page, "pageSlide", { Position = UDim2.fromOffset(0, 0) }, "snappy")
		else
			page.Position = UDim2.fromOffset(0, 0)
		end

		if previous ~= key then
			Kit.sound("page")
			trace("navigation: %s -> %s", previous, key)
		end

		local viewport = body.AbsoluteSize.Y
		local order = 0

		for _, object in pageTargets[key] do
			if object.Visible then
				local top = object.Position.Y.Offset
				local onScreen = top + object.Size.Y.Offset > 0 and top < viewport
				local scale = revealScales[object]

				if motion and onScreen then
					if not scale then
						scale = Kit.create("UIScale", object, { Name = "RevealScale", Scale = 1 })
						revealScales[object] = scale
					end

					local step = math.min(order, 5)
					order += 1

					object.BackgroundTransparency = 0.5
					scale.Scale = 0.965

					-- Routed through the scheduler (not Kit.animate, since
					-- the stagger needs TweenInfo's delay parameter) so a
					-- second quick page switch cancels any cascade tween
					-- still running on a reused object instead of letting
					-- it race the new one.
					local fadeTween = TweenService:Create(object, REVEAL_FADE[step], { BackgroundTransparency = 0 })
					Kit.Scheduler.track(object, "reveal", fadeTween)
					fadeTween:Play()

					local popTween = TweenService:Create(scale, REVEAL_POP[step], { Scale = 1 })
					Kit.Scheduler.track(scale, "reveal", popTween)
					popTween:Play()
				else
					object.BackgroundTransparency = 0
					if scale then
						scale.Scale = 1
					end
				end
			end
		end
	end

	Shared.fn.switchPage = switchPage
end

local tutorial = Tutorial.new(root, Kit, C, Icons, Config, positionText, act, switchPage, preferences, liven)
showTutorial = tutorial.show
local fitTutorial = tutorial.fit

Shared.fn.showTutorial = showTutorial

local fit

do
	local compactNames = {
		overview = "Control",
		operations = "Dispatch",
		infrastructure = "Hardware",
		research = "Lab",
		modules = "Firmware",
		contracts = "Orders",
		rewards = "Claims",
		shop = "Supply",
		prestige = "Relaunch",
		events = "Bulletins",
		leaderboard = "Standings",
		settings = "Console",
	}

	local lastWidth = 0

	fit = function()
		if not alive then
			return
		end

		local size = root.AbsoluteSize
		fitTutorial(size)

		-- The ScreenGui is built with IgnoreGuiInset = true (deliberately,
		-- for a full-bleed layout), so nothing reserves space under the
		-- Roblox topbar or a device notch unless this function does it.
		-- Computed once and threaded through every top-anchored placement
		-- below as a single additive offset — never given its own inset
		-- math per element, which is the exact "two divergent formulas for
		-- one position" bug class already fixed elsewhere in this file.
		local topInset = GuiService:GetGuiInset().Y

		if loading.Parent then
			loadingBrand.Size = UDim2.fromOffset(math.min(220, size.X - 24), 54)
			loadingStatus.Size = UDim2.fromOffset(math.min(320, size.X - 24), 24)
			loadingTrack.Size = UDim2.fromOffset(math.min(280, size.X - 48), 4)
			loadingTip.Size = UDim2.fromOffset(math.min(520, size.X - 40), 52)
		end

		local compact = size.X < 1000
		local short = size.Y < 820
		-- Bottom tab bar replaces the old left sidebar rail — `rail` is the
		-- same Frame/instances as before (sliding navIndicator, nav[key]
		-- bookkeeping, switchPage's active-state tinting all untouched),
		-- just laid out horizontally along the bottom edge instead of
		-- vertically along the left edge. barHeight is the one new term
		-- subtracted from body's height below; no page file needs to know
		-- the bar exists, since pages just fill body's Size as before.
		local barHeight = 72
		local gutter = if size.X < 550 then 12 else 28
		local width = math.max(220, size.X - gutter * 2)
		-- Identity block (avatar/username/role) doesn't fit a compact
		-- horizontal bar — hidden entirely rather than squeezed in.
		local showIdentity = false

		Kit.place(rail, 0, size.Y - barHeight, size.X, barHeight)
		wordmark.Visible = false
		edition.Visible = false
		railLed.Visible = false

		local navStep = if compact then 68 else 84
		local navHeight = barHeight - 12
		Kit.place(
			navScroll,
			0, 6,
			size.X,
			navHeight
		)
		navScroll.CanvasSize = UDim2.fromOffset(#definitions * navStep, 0)

		local activeIndex = table.find(pageOrder, selected) or 1
		navIndicator.Size = UDim2.fromOffset(navStep - 8, navHeight - 4)
		navIndicator.Position = UDim2.fromOffset((activeIndex - 1) * navStep + 4, 2)

		for index, definition in ipairs(definitions) do
			local key = definition[1]
			local item = nav[key]

			Kit.place(item.button, (index - 1) * navStep + 4, 2, navStep - 8, navHeight - 4)

			item.caption.Text = compactNames[key] or definition[2]
			item.caption.TextSize = 9
			item.caption.TextXAlignment = Enum.TextXAlignment.Center
			item.caption.Position = UDim2.fromOffset(0, navHeight - 22)
			item.caption.Size = UDim2.new(1, 0, 0, 16)
			item.icon.Position = UDim2.new(0.5, -11, 0, 6)
		end

		avatar.Visible = showIdentity
		username.Visible = showIdentity
		role.Visible = showIdentity

		Kit.place(header, gutter, 24 + topInset, width, 68)

		local showCrumb = width > 580
		crumb.Visible = showCrumb
		local crumbWidth = if width > 750 then 220 else 140
		if showCrumb then
			Kit.place(crumb, 0, 22, crumbWidth, 22)
		end

		-- Capsules fitting
		local showAllCapsules = width >= 860
		local showMidCapsules = width >= 660

		dataCapsule.Visible = showAllCapsules
		energyCapsule.Visible = showAllCapsules
		telemetryCapsule.Visible = showMidCapsules

		local curX = width
		if showMidCapsules then
			curX -= 130
			Kit.place(telemetryCapsule, curX, 16, 130, 34)
			curX -= 8
		end
		if showAllCapsules then
			curX -= 80
			Kit.place(dataCapsule, curX, 16, 80, 34)
			curX -= 8

			curX -= 90
			Kit.place(energyCapsule, curX, 16, 90, 34)
			curX -= 8
		end
		local computeW = math.clamp(curX - (if showCrumb then crumbWidth + 50 else 44), 110, 180)
		curX -= computeW
		Kit.place(computeCapsule, curX, 16, computeW, 34)
		rateBadge.Visible = computeW > 140

		-- Search placement between crumb and computeCapsule
		local searchLeft = if showCrumb then crumbWidth + 12 else 0
		local searchAvail = curX - searchLeft - 10
		local searchWide = searchAvail > 140
		local searchWidth = if searchWide then math.min(180, searchAvail) else 36
		if searchAvail > 36 then
			globalSearch.fit(searchLeft, 16, searchWidth, searchWide)
		else
			globalSearch.fit(0, 16, 0, false)
		end

		local bannerHeight = if overclockBanner.Visible then 34 else 0
		if overclockBanner.Visible then
			Kit.place(overclockBanner, gutter, 93 + topInset, width, 28)
		end

		-- barHeight subtracted here (the one new term the bottom bar adds)
		-- so page content never sits under the bar — pages themselves fill
		-- body's Size exactly as before and need no bar-awareness of their
		-- own.
		Kit.place(body, gutter, 93 + topInset, width, math.max(1, size.Y - 93 - topInset - bannerHeight - barHeight))

		fitToasts(size, topInset, barHeight)

		if lastWidth ~= width then
			lastWidth = width
			for _, layout in layouts do
				layout(width - 8)
			end
		end
	end
end

connect(root:GetPropertyChangedSignal("AbsoluteSize"), fit)

local function finishLoading()
	loadingPulse.enabled = false
	syncPulses()

	local index = table.find(pulses, loadingPulse)
	if index then
		table.remove(pulses, index)
	end

	Kit.animate(loading, { GroupTransparency = 1 }, 0.45)
	Kit.sound("ready")
	trace("loading: complete")

	defer(0.46, function()
		loading:Destroy()

		if not tutorial.started and state and not state.tutorialComplete then
			showTutorial(state.tutorialStep or 1)
		end
	end)
end

apply = function(s)
	if not alive or type(s) ~= "table" then
		return
	end

	if state and s.updatedAt and state.updatedAt and s.updatedAt < state.updatedAt then
		return
	end

	state = deepFreeze(s)
	Shared.state = state

	if not hydrated then
		hydrated = true
		Shared.hydrated = true
		trace("state: initial snapshot received compute=%s level=%s", fmt(s.compute), tostring(s.level))

		for key, value in s.settings or {} do
			local current = preferences[key]
			if current ~= nil and type(current) == type(value) then
				preferences[key] = deepCopy(value)
			end
		end
		-- accentTheme lives on s.accentTheme directly (not s.settings),
		-- matching how state.accentTheme is validated separately in
		-- StateService.luau from the generic boolean/number settings loop.
		if type(s.accentTheme) == "string" then
			preferences.accentTheme = s.accentTheme
		end

		refreshPresentation()
		for _, callback in ipairs(settingRefresh) do
			callback()
		end

		loadingSet(1, "State synchronized")
		defer(math.max(0, 1.1 - (os.clock() - loadingStarted)), finishLoading)
	end

	Kit.tickValue(balance, s.compute, fmt, "smooth", bumpPeak(1.035))
	rateBadge.Text = "+" .. fmt(s.rate or 0) .. "/s"
	energyVal.Text = string.format("%d/%d", math.floor(s.energy or 0), math.floor(s.energyCapacity or 100))
	dataVal.Text = fmt(s.data or 0)

	local now = workspace:GetServerTimeNow()
	local boostActive = (s.boostUntil or 0) > now
	if boostActive then
		local rem = math.ceil((s.boostUntil or 0) - now)
		bannerLabel.Text = string.format("⚡ Overclock Active — Fleet Output 2.0x (%ds)", rem)
		if not overclockBanner.Visible then
			overclockBanner.Visible = true
			Kit.glowPulse(overclockBanner, C.overclock, 1.2)
			fit()
		end
	elseif overclockBanner.Visible then
		overclockBanner.Visible = false
		fit()
	end

	local displayName = if s.callsign and s.callsign ~= "" then s.callsign else player.DisplayName
	if username.Text ~= displayName then
		username.Text = displayName
	end

	for _, callback in ipairs(updates[selected]) do
		callback(s)
	end
end

Shared.fn.apply = apply

do
	local elapsed, frames, ping = 0, 0, nil
	local telemetryText = ""

	connect(RunService.RenderStepped, function(dt)
		frames += 1
		elapsed += dt

		if elapsed < 0.5 then
			return
		end

		local text = string.format(
			"%d FPS · %s",
			math.floor(frames / elapsed + 0.5),
			if ping then ping .. "ms" else "—"
		)
		elapsed, frames = 0, 0

		if text ~= telemetryText then
			telemetryText = text
			telemetry.Text = text
			local pingNum = ping or 999
			local dotColor = if pingNum < 80 then (C.accent or Color3.fromRGB(56, 139, 253))
				elseif pingNum < 200 then (C.warning or Color3.fromRGB(245, 158, 11))
				else (C.danger or C.error or Color3.fromRGB(239, 68, 68))
			local dotChild = teleDot:FindFirstChild("Dot")
			if dotChild then
				dotChild.BackgroundColor3 = dotColor
			else
				teleDot.BackgroundColor3 = dotColor
			end
		end
	end)

	run(function()
		loadingSet(0.62, "Requesting fleet record")
		local lastPingFailure = false

		while alive do
			local start = os.clock()
			local ok, result = pcall(Ping.InvokeServer, Ping, start)
			ping = if ok and result then math.floor((os.clock() - start) * 1000 + 0.5) else nil
			if ping == nil and not lastPingFailure then
				traceWarn("network: ping request failed")
			elseif ping and lastPingFailure then
				trace("network: ping recovered %dms", ping)
			end
			lastPingFailure = ping == nil
			task.wait(3)
		end
	end)
end

connect(Changed.OnClientEvent, apply)
connect(gui.Destroying, dispose)
connect(script.Destroying, dispose)

fit()
refreshPresentation()

for _, callback in ipairs(settingRefresh) do
	callback()
end

switchPage("overview")

-- NOTE: explicitly setting GuiService.SelectedObject was tried here (and
-- on page switch) to seed gamepad focus, but was removed — Roblox has a
-- confirmed engine bug where assigning SelectedObject can hard-crash the
-- client (see https://devforum.roblox.com/t/35732), and it's not worth
-- that risk. Gamepad users can still select UI manually (every button is
-- Selectable = true and reachable via Roblox's own automatic gamepad
-- traversal); they just don't get a pre-seeded starting selection.

run(function()
	for attempt = 1, 4 do
		trace("state: request attempt %d", attempt)
		local ok, result = pcall(GetState.InvokeServer, GetState)
		if not alive then
			return
		end

		if ok and type(result) == "table" then
			apply(result)
			return
		end

		traceWarn("state: request attempt %d failed", attempt)

		task.wait(attempt)
	end

	notify("Your save could not be loaded. Rejoin to reconnect.", false)
	traceWarn("state: exhausted all recovery attempts")
end)

return true
