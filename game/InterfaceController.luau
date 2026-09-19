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

local effectsMix = own(Kit.create("SoundGroup", SoundService, {
	Name = "DeckInterfaceEffects",
	Volume = 1,
}))

Kit.create("CompressorSoundEffect", effectsMix, {
	Name = "InterfaceLimiter",
	Threshold = -5,
	Ratio = 2.5,
	Attack = 0.02,
	Release = 0.12,
})

Kit.create("EqualizerSoundEffect", effectsMix, {
	Name = "Presence",
	LowGain = -1,
	MidGain = 1.5,
	HighGain = 2.5,
})

local audio = own(Kit.create("Folder", SoundService, { Name = "DeckInterfaceAudio" }))
local musicManager = own(MusicManager.new(Kit, audio))
local musicMix = musicManager:GetSoundGroup()

local cueDefinitions = {
	hover = { "139800881181209", 0.055, 1.10, 2, 0.09, true },
	press = { "88442833509532", 0.070, 0.90, 2, 0.04 },
	release = { "75490872912178", 0.065, 1.12, 2, 0.05 },
	click = { "88442833509532", 0.220, 1.00, 2, 0.07 },
	confirm = { "137214903496040", 0.280, 1.16, 2, 0.12 },
	denied = { "87519554692663", 0.160, 0.92, 1, 0.18 },
	page = { "75490872912178", 0.120, 1.04, 2, 0.12 },
	notice = { "137214903496040", 0.160, 1.10, 2, 0.15 },
	error = { "87519554692663", 0.200, 0.92, 1, 0.20 },
	operation = { "137214903496040", 0.260, 0.94, 2, 0.18 },
	upgrade = { "137214903496040", 0.240, 1.22, 2, 0.15 },
	purchase = { "88442833509532", 0.240, 0.87, 2, 0.15 },
	reward = { "137214903496040", 0.320, 1.30, 2, 0.20 },
	toggle_on = { "75490872912178", 0.120, 1.20, 1, 0.10 },
	toggle_off = { "75490872912178", 0.100, 0.88, 1, 0.10 },
	slider = { "139800881181209", 0.050, 1.30, 2, 0.08 },
	input = { "139800881181209", 0.070, 0.96, 1, 0.12 },
	boot = { "75490872912178", 0.160, 0.82, 1, 0.30 },
	ready = { "137214903496040", 0.280, 1.25, 1, 0.30 },
	milestone = { "137214903496040", 0.380, 1.42, 2, 0.35 },
	lock = { "87519554692663", 0.180, 0.78, 1, 0.16 },
	flip = { "75490872912178", 0.100, 1.08, 2, 0.09 },
}

local sounds, soundCursor, cueClock = {}, {}, {}
local cueCount = 0
local duckMusic

for name, definition in cueDefinitions do
	cueCount += 1
	local pool = {}
	for index = 1, definition[4] do
		pool[index] = Kit.create("Sound", audio, {
			Name = string.format("%s_%02d", name, index),
			SoundId = "rbxassetid://" .. definition[1],
			Volume = definition[2],
			PlaybackSpeed = definition[3],
			SoundGroup = effectsMix,
		})
	end
	sounds[name] = pool
	soundCursor[name] = 0
end

-- Cues in this set represent one physical gesture in quick succession
-- (mouse enters, then presses, then releases/activates, all within maybe
-- 100-200ms of each other for a fast click). Each used to cool down purely
-- on its own name, so a quick click played hover+press+release+click as up
-- to four independent, audibly overlapping sounds. Every cue in this set
-- now hushes whichever gesture-hush cue played immediately before it (not
-- just hover), so a fast click plays one clean cue at a time — press cut
-- off by release, release cut off by the final click/confirm — instead of
-- stacking.
local GESTURE_HUSH = { hover = true, press = true, release = true, click = true, confirm = true, denied = true }
local lastGestureSound = nil

Kit.sound = function(name)
	if not alive or not preferences.sfx then
		return
	end

	local definition = cueDefinitions[name]
	if not definition then
		return
	end

	if definition[6] and not preferences.hover then
		return
	end

	if GESTURE_HUSH[name] and lastGestureSound and lastGestureSound.Playing then
		lastGestureSound:Stop()
		lastGestureSound = nil
	end

	local now = os.clock()
	if now - (cueClock[name] or -math.huge) < definition[5] then
		return
	end
	cueClock[name] = now

	local pool = sounds[name]
	local index = soundCursor[name] % #pool + 1
	soundCursor[name] = index

	local sound = pool[index]
	sound:Stop()
	sound.TimePosition = 0
	sound.Volume = definition[2] * preferences.masterVolume * preferences.sfxVolume
	sound:Play()

	if GESTURE_HUSH[name] then
		lastGestureSound = sound
	end

	if duckMusic and name ~= "hover" and name ~= "press" and name ~= "release" and name ~= "slider" and name ~= "input" then
		duckMusic()
	end
end

trace("audio: %d interaction cues loaded", cueCount)

local duckGeneration = 0

duckMusic = function()
	if not preferences.music then
		return
	end

	duckGeneration += 1
	local generation = duckGeneration
	Kit.animate(musicMix, { Volume = 0.18 }, 0.08, Enum.EasingStyle.Quad)
	defer(0.36, function()
		if generation == duckGeneration then
			Kit.animate(musicMix, { Volume = 0.42 }, 0.24, Enum.EasingStyle.Quad)
		end
	end)
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

local function refreshPresentation()
	Kit.motion = preferences.motion

	local pageMix = if selected == "operations" then 1.08 elseif selected == "settings" then 0.72 else 0.9

	musicManager:RefreshVolume(preferences.masterVolume, preferences.musicVolume, pageMix)
	musicManager:SetPlaying(preferences.music)

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

local rail = Kit.create("Frame", root, {
	Name = "Navigation",
	BackgroundColor3 = C.navigation,
	BorderSizePixel = 0,
})

Kit.create("Frame", rail, {
	Name = "Edge",
	Position = UDim2.new(1, -1, 0, 0),
	Size = UDim2.new(0, 1, 1, 0),
	BackgroundColor3 = C.accent,
	BackgroundTransparency = 0.72,
	BorderSizePixel = 0,
})

local wordmark = Kit.text(rail, "Wordmark", "DECK//", 24, C.text, true)
wordmark.Font = Enum.Font.RobotoMono

local edition = Kit.text(rail, "Edition", "NETWORK OPERATIONS", 9, C.accent, true)
edition.Font = Enum.Font.RobotoMono

local navScroll = Kit.create("ScrollingFrame", rail, {
	Name = "Destinations",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.fromOffset(0, 400),
})

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

local balance = Kit.text(header, "Balance", "— compute", 16, C.text, true)
balance.Font = Enum.Font.RobotoMono
balance.TextXAlignment = Enum.TextXAlignment.Right

local telemetry = Kit.text(header, "Telemetry", "FPS —   ·   PING —", 11, C.muted)
telemetry.Font = Enum.Font.RobotoMono
telemetry.TextXAlignment = Enum.TextXAlignment.Right

Kit.create("Frame", header, {
	Name = "Divider",
	Position = UDim2.new(0, 0, 1, -1),
	Size = UDim2.new(1, 0, 0, 1),
	BorderSizePixel = 0,
	BackgroundColor3 = C.line,
})

local body = Kit.create("Frame", root, {
	Name = "Pages",
	BackgroundTransparency = 1,
	ClipsDescendants = true,
})

local director = own(PreviewDirector.new(gui, preferences))

local fitToasts

do
	local TOAST_SLOTS = 4
	local TOAST_BACKLOG = 6
	local TOAST_HEIGHT = 76
	local TOAST_GAP = 10
	-- Was a constant; now the base offset before the safe-area inset
	-- fitToasts() adds each resize, so toasts don't stack under a visible
	-- topbar/notch. TOAST_TOP itself stays fixed — toastTop is what
	-- activateToast/stepToasts actually read.
	local TOAST_TOP = 104
	local toastTop = TOAST_TOP
	local TOAST_MARGIN = 12
	local TOAST_LIFETIME = 3.2
	local TOAST_RESPONSE = 18

	local toastWidth = 540
	local toastFloor = math.huge
	local toastSlots = {}
	local toastFree = {}
	local toastLive = {}
	local toastBacklog = {}
	local toastStepper

	for index = 1, TOAST_SLOTS do
		local holder = Kit.create("Frame", root, {
			Name = "Notification" .. index,
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(toastWidth, TOAST_HEIGHT),
			Visible = false,
			ZIndex = 80,
		})

		local scale = Kit.create("UIScale", holder, { Name = "ToastScale", Scale = 1 })

		local shadow = Kit.create("Frame", holder, {
			Name = "Shadow",
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 1,
		})
		Kit.corner(shadow, 14)

		local card = Kit.card(holder, "Card", TOAST_HEIGHT, C.panel)
		card.Position = UDim2.fromOffset(0, 0)
		card.Size = UDim2.fromScale(1, 1)
		card.Active = true
		card.ZIndex = 2

		local bar = Kit.create("Frame", card, {
			Name = "Accent",
			Position = UDim2.fromOffset(0, 12),
			Size = UDim2.fromOffset(4, 52),
			BackgroundColor3 = C.accent,
			BorderSizePixel = 0,
			ZIndex = 51,
		})
		Kit.corner(bar, 2)

		local icon = Kit.icon(card, "Icon", "check", C.ink)
		icon.ZIndex = 51
		Kit.place(icon, 18, 26, 24, 24)

		local title = Kit.text(card, "Title", "Updated", 10, C.accent, true)
		title.ZIndex = 51
		title.Position = UDim2.fromOffset(56, 10)
		title.Size = UDim2.new(1, -72, 0, 18)

		local message = Kit.text(card, "Message", "", 13, C.text, true)
		message.TextWrapped = true
		message.TextTruncate = Enum.TextTruncate.None
		message.ZIndex = 51
		message.Position = UDim2.fromOffset(56, 27)
		message.Size = UDim2.new(1, -72, 0, 38)

		local timer = Kit.create("Frame", card, {
			Name = "Timer",
			Position = UDim2.new(0, 0, 1, -3),
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = C.accent,
			BorderSizePixel = 0,
			ZIndex = 52,
		})

		local slot = {
			holder = holder,
			scale = scale,
			card = card,
			bar = bar,
			icon = icon,
			title = title,
			message = message,
			timer = timer,
			hovered = false,
			entry = nil,
		}

		connect(card.MouseEnter, function()
			slot.hovered = true
		end)

		connect(card.MouseLeave, function()
			slot.hovered = false
		end)

		connect(card.InputBegan, function(input)
			if slot.entry
				and (input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch)
			then
				slot.entry.leaving = true
			end
		end)

		toastSlots[index] = slot
		toastFree[index] = slot
	end

	local function paintToast(slot, entry)
		local tint = if entry.failed then C.error else C.accent

		slot.title.Text = if entry.failed then "REQUEST REJECTED" else "COMPLETE"
		slot.title.TextColor3 = tint
		-- "codes"/"contracts" were unrelated feature-page icons left over
		-- from an earlier pass — neither reads as success or failure.
		-- "close"/"check" actually match the two states.
		slot.icon.Image = Icons.asset(if entry.failed then "close" else "check")
		slot.icon.ImageColor3 = tint
		slot.bar.BackgroundColor3 = tint
		slot.timer.BackgroundColor3 = tint
		slot.message.Text = if entry.repeats > 1
			then string.format("%s  ×%d", entry.message, entry.repeats)
			else entry.message
	end

	local function activateToast(request)
		local slot = table.remove(toastFree)
		if not slot then
			return false
		end

		local now = os.clock()
		local entry = {
			slot = slot,
			message = request.message,
			failed = request.failed,
			repeats = 1,
			expires = now + TOAST_LIFETIME,
			x = toastWidth + TOAST_MARGIN + 30,
			y = toastTop,
			targetY = toastTop,
			scale = 0.92,
			leaving = false,
		}

		slot.entry = entry
		slot.hovered = false
		paintToast(slot, entry)

		slot.timer.Size = UDim2.new(1, 0, 0, 3)
		slot.scale.Scale = entry.scale
		slot.holder.Position = UDim2.new(1, entry.x - TOAST_MARGIN, 0, entry.y)
		slot.holder.Visible = true

		if not entry.failed and request.cue == "milestone" then
			Kit.gradientAnimate(slot.bar, "sheen", { color = C.accent })
			if preferences.particles then
				Kit.confetti(slot.card, C.accent)
			end
		else
			Kit.Scheduler.clear(slot.bar, "gradient")
		end

		table.insert(toastLive, 1, entry)
		Kit.sound(if request.failed then "error" else request.cue or "notice")
		return true
	end

	local function approach(current, target, blend, epsilon)
		local value = current + (target - current) * blend
		if math.abs(target - value) <= epsilon then
			return target
		end
		return value
	end

	local function stepToasts(dt)
		local now = os.clock()
		local blend = if preferences.motion then 1 - math.exp(-TOAST_RESPONSE * dt) else 1
		local hidden = toastWidth + TOAST_MARGIN + 30
		local cursor = toastTop
		local kept = 0

		for _, entry in toastLive do
			local slot = entry.slot

			if not entry.leaving then
				if slot.hovered then
					entry.expires += dt
				elseif now >= entry.expires or (cursor > toastTop and cursor + TOAST_HEIGHT > toastFloor) then
					entry.leaving = true
				end
			end

			if not entry.leaving then
				entry.targetY = cursor
				cursor += TOAST_HEIGHT + TOAST_GAP
				slot.timer.Size = UDim2.new(math.clamp((entry.expires - now) / TOAST_LIFETIME, 0, 1), 0, 0, 3)
			end

			local x = approach(entry.x, if entry.leaving then hidden else 0, blend, 0.05)
			local y = approach(entry.y, entry.targetY, blend, 0.05)
			if x ~= entry.x or y ~= entry.y then
				entry.x, entry.y = x, y
				slot.holder.Position = UDim2.new(1, x - TOAST_MARGIN, 0, y)
			end

			local scale = approach(entry.scale, 1, blend, 0.001)
			if scale ~= entry.scale then
				entry.scale = scale
				slot.scale.Scale = scale
			end

			if entry.leaving and x == hidden then
				slot.entry = nil
				slot.hovered = false
				slot.holder.Visible = false
				table.insert(toastFree, slot)
			else
				kept += 1
				toastLive[kept] = entry
			end
		end

		for index = #toastLive, kept + 1, -1 do
			toastLive[index] = nil
		end

		while toastBacklog[1] and toastFree[1] do
			activateToast(table.remove(toastBacklog, 1))
		end

		if not toastLive[1] and toastStepper then
			toastStepper:Disconnect()
			toastStepper = nil
		end
	end

	fitToasts = function(size, topInset)
		toastWidth = if size.X < 550 then math.max(200, size.X - 88) else math.min(540, size.X - 24)
		toastFloor = size.Y - TOAST_MARGIN
		toastTop = TOAST_TOP + (topInset or 0)
		for _, slot in toastSlots do
			slot.holder.Size = UDim2.fromOffset(toastWidth, TOAST_HEIGHT)
		end
	end

	local function wakeToasts()
		if alive and not toastStepper then
			toastStepper = RunService.Heartbeat:Connect(stepToasts)
		end
	end

	own(function()
		if toastStepper then
			toastStepper:Disconnect()
			toastStepper = nil
		end
		table.clear(toastLive)
		table.clear(toastBacklog)
		table.clear(toastFree)
		table.clear(toastSlots)
	end)

	notify = function(message, ok, cue)
		if not alive or (not preferences.notifications and ok ~= false) then
			return
		end

		message = tostring(message or "")
		local failed = ok == false

		for _, entry in toastLive do
			if not entry.leaving and entry.failed == failed and entry.message == message then
				entry.repeats += 1
				entry.expires = os.clock() + TOAST_LIFETIME
				entry.scale = 0.96
				entry.slot.scale.Scale = entry.scale
				paintToast(entry.slot, entry)
				Kit.sound(if failed then "error" else cue or "notice")
				wakeToasts()
				return
			end
		end

		local request = { message = message, failed = failed, cue = cue }

		if not activateToast(request) then
			for index = #toastLive, 1, -1 do
				local oldest = toastLive[index]
				if not oldest.leaving then
					oldest.leaving = true
					break
				end
			end

			if #toastBacklog >= TOAST_BACKLOG then
				table.remove(toastBacklog, 1)
			end
			table.insert(toastBacklog, request)
		end

		wakeToasts()
	end
end

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
	end)
	Kit.place(button, 0, (index - 1) * 49, 180, 44)
	button.BackgroundTransparency = 1

	local icon = Kit.place(
		if key == "prestige" then Kit.rocketIcon(button, "Icon", C.muted) else Kit.icon(button, "Icon", key),
		14, 11, 22, 22
	)
	local caption = positionText(button, "Caption", title, 48, 0, 140, 44, 13, C.muted, true)

	local indicator = Kit.create("Frame", button, {
		Name = "Active",
		BackgroundColor3 = C.accent,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 13),
		Size = UDim2.fromOffset(3, 18),
		Visible = false,
	})
	Kit.corner(indicator, 2)

	nav[key] = {
		button = button,
		icon = icon,
		caption = caption,
		indicator = indicator,
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

		for name, item in nav do
			local active = name == key
			item.button.BackgroundColor3 = C.raised
			item.button.BackgroundTransparency = if active then 0 else 1
			item.indicator.Visible = active

			if active then
				item.indicator.Size = UDim2.fromOffset(1, 18)
				Kit.animate(item.indicator, { Size = UDim2.fromOffset(3, 18) }, 0.24, Enum.EasingStyle.Back)
			else
				item.indicator.Size = UDim2.fromOffset(3, 18)
			end

			if item.scale then
				Kit.animate(item.scale, { Scale = if active then 1.018 else 1 }, 0.24, Enum.EasingStyle.Back)
			end

			item.caption.TextColor3 = if active then C.text else C.muted
			Kit.tintIcon(item.icon, if active then C.accent else C.muted)
		end

		crumb.Text = "WORKSPACE  /  " .. string.upper(nav[key].caption.Text)
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
		page.Position = UDim2.fromOffset(if motion then 10 else 0, if motion then 14 else 0)
		Kit.animate(page, { Position = UDim2.fromOffset(0, 0) }, 0.38, Enum.EasingStyle.Quart)

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

local fitTutorial
local tutorialStarted = false

do
	local tutorialOverlay = Kit.create("Frame", root, {
		Name = "Tutorial",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 70,
	})

	local tutorialModal = Kit.card(tutorialOverlay, "Guide", 390, C.panel)
	tutorialModal.ZIndex = 71

	local tutorialModalScale = Kit.create("UIScale", tutorialModal, { Name = "EntryScale", Scale = 1 })

	local tutorialIcon = Kit.icon(tutorialModal, "Icon", "overview", C.accent)
	tutorialIcon.ZIndex = 72

	local tutorialKicker = positionText(tutorialModal, "Kicker", "GUIDED SETUP", 30, 28, 300, 20, 10, C.accent, true)
	tutorialKicker.ZIndex = 72

	local tutorialTitle = positionText(tutorialModal, "Title", "", 30, 74, 520, 70, 28, C.text, true)
	tutorialTitle.TextWrapped = true
	tutorialTitle.TextTruncate = Enum.TextTruncate.None
	tutorialTitle.ZIndex = 72

	local tutorialBody = positionText(tutorialModal, "Body", "", 30, 151, 520, 70, 14, C.muted)
	tutorialBody.TextWrapped = true
	tutorialBody.TextTruncate = Enum.TextTruncate.None
	tutorialBody.ZIndex = 72

	local tutorialProgress = positionText(tutorialModal, "Progress", "", 30, 236, 300, 22, 10, C.muted, true)
	tutorialProgress.ZIndex = 72

	local tutorialDots = {}
	for index = 1, #Config.Tutorial do
		local dot = Kit.create("Frame", tutorialModal, {
			Name = "Step" .. index,
			BackgroundColor3 = C.line,
			BorderSizePixel = 0,
			ZIndex = 72,
		})
		Kit.corner(dot, 3)
		tutorialDots[index] = dot
	end

	local tutorialStep = 1
	local tutorialBack, tutorialNext, tutorialSkip

	local function tutorialLabels()
		local width = tutorialModal.AbsoluteSize.X
		local last = tutorialStep == #Config.Tutorial

		tutorialSkip.Text = if width < 360 then "Skip" else "Skip guide"
		tutorialNext.Text = if width < 360 then "Next"
			elseif width < 480 then (if last then "Finish" else "Continue")
			else (if last then "Finish setup" else "Continue")
	end

	local function renderTutorial()
		local definition = Config.Tutorial[tutorialStep]
		if not definition then
			return
		end

		tutorialIcon.Image = Icons.asset(definition.icon)
		tutorialTitle.Text = definition.title
		tutorialBody.Text = definition.body
		tutorialProgress.Text = string.format("STEP %d OF %d", tutorialStep, #Config.Tutorial)

		for index, dot in ipairs(tutorialDots) do
			dot.BackgroundColor3 = if index <= tutorialStep then C.accent else C.line
		end

		Kit.enable(tutorialBack, tutorialStep > 1, "Back", false)
		tutorialLabels()
		switchPage(definition.page)
	end

	local function closeTutorial()
		if not tutorialOverlay.Visible then
			return
		end

		Kit.sound("release")

		if preferences.motion then
			Kit.animate(tutorialOverlay, { BackgroundTransparency = 1 }, 0.2)
			Kit.animate(tutorialModalScale, { Scale = 0.96 }, 0.2)
			Kit.Scheduler.after(tutorialOverlay, "hide", 0.2, function()
				tutorialOverlay.Visible = false
				tutorialOverlay.BackgroundTransparency = 0.25
				tutorialModalScale.Scale = 1
			end)
		else
			tutorialOverlay.Visible = false
		end

		act("tutorial", "complete", nil, true)
	end

	showTutorial = function(step)
		if tutorialStarted and tutorialOverlay.Visible then
			return
		end

		Kit.sound("page")

		tutorialStarted = true
		tutorialStep = math.clamp(step or 1, 1, #Config.Tutorial)

		Kit.Scheduler.clear(tutorialOverlay, "hide")
		tutorialOverlay.Visible = true

		if preferences.motion then
			tutorialOverlay.BackgroundTransparency = 1
			tutorialModalScale.Scale = 0.96
			Kit.animate(tutorialOverlay, { BackgroundTransparency = 0.25 }, 0.22)
			Kit.animate(tutorialModalScale, { Scale = 1 }, 0.26, Enum.EasingStyle.Back)
		else
			tutorialOverlay.BackgroundTransparency = 0.25
			tutorialModalScale.Scale = 1
		end

		renderTutorial()
	end

	Shared.fn.showTutorial = showTutorial

	tutorialBack = Kit.button(tutorialModal, "Back", "Back", function()
		tutorialStep = math.max(1, tutorialStep - 1)
		renderTutorial()
	end)
	tutorialBack.ZIndex = 72

	tutorialNext = liven(Kit.button(tutorialModal, "Next", "Continue", function()
		if tutorialStep >= #Config.Tutorial then
			closeTutorial()
			return
		end

		tutorialStep += 1
		act("tutorial", tostring(tutorialStep), nil, true)
		renderTutorial()
	end, "primary"))

	tutorialSkip = Kit.button(tutorialModal, "Skip", "Skip guide", closeTutorial)
	tutorialSkip.ZIndex = 72

	fitTutorial = function(size)
		local width = math.min(600, size.X - 32)
		local height = if size.X < 480 then 430 else 390

		Kit.place(tutorialModal, (size.X - width) / 2, (size.Y - height) / 2, width, height)
		Kit.place(tutorialIcon, 30, 28, 24, 24)

		tutorialKicker.Position = UDim2.fromOffset(66, 30)
		tutorialTitle.Size = UDim2.fromOffset(width - 60, 70)
		tutorialBody.Size = UDim2.fromOffset(width - 60, if size.X < 480 then 108 else 70)

		local controlsY = height - 70
		tutorialProgress.Position = UDim2.fromOffset(30, controlsY - 66)

		local dotWidth = math.max(16, math.floor((width - 60 - (#tutorialDots - 1) * 6) / #tutorialDots))
		for index, dot in ipairs(tutorialDots) do
			Kit.place(dot, 30 + (index - 1) * (dotWidth + 6), controlsY - 34, dotWidth, 5)
		end

		if width < 480 then
			local buttonWidth = (width - 76) / 3
			Kit.place(tutorialSkip, 30, controlsY, buttonWidth, 42)
			Kit.place(tutorialBack, 38 + buttonWidth, controlsY, buttonWidth, 42)
			Kit.place(tutorialNext, 46 + buttonWidth * 2, controlsY, buttonWidth, 42)
		else
			Kit.place(tutorialSkip, 30, controlsY, 120, 42)
			Kit.place(tutorialBack, width - 250, controlsY, 100, 42)
			Kit.place(tutorialNext, width - 138, controlsY, 108, 42)
		end

		tutorialLabels()
	end
end

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
		local railWidth = if compact then 64 else 208
		local gutter = if size.X < 550 then 12 else 28
		local width = math.max(220, size.X - railWidth - gutter * 2)
		local showIdentity = not compact and not short
		-- rail's own local coordinate space is only this tall (rail's
		-- Size.Y is shrunk by topInset below) — every rail child positioned
		-- relative to the rail's height must use this, not raw size.Y, or
		-- it ends up placed past rail's actual bottom edge once topInset
		-- is nonzero (topbar visible / device notch).
		local railLocalHeight = size.Y - topInset

		Kit.place(rail, 0, topInset, railWidth, railLocalHeight)
		Kit.place(wordmark, if compact then 15 else 24, 48, if compact then 42 else 160, 40)
		wordmark.Text = if compact then "D//" else "DECK//"
		edition.Visible = not compact
		Kit.place(edition, 24, 90, 160, 20)

		Kit.place(
			navScroll,
			if compact then 5 else 12,
			138,
			railWidth - (if compact then 10 else 24),
			math.max(80, railLocalHeight - (if showIdentity then 228 else 150))
		)

		-- navHeight's `short` branch used to be 40px, below the 44px
		-- minimum touch-target guideline (compact's 52 and the default 44
		-- both already clear it). navStep's short branch is bumped to
		-- match so rows don't start overlapping now that navHeight grew.
		local navStep = if compact then 56 elseif short then 48 else 49
		local navHeight = if compact then 52 elseif short then 44 else 44
		navScroll.CanvasSize = UDim2.fromOffset(0, #definitions * navStep)

		for index, definition in ipairs(definitions) do
			local key = definition[1]
			local item = nav[key]

			Kit.place(item.button, 2, (index - 1) * navStep, railWidth - (if compact then 14 else 32), navHeight)

			item.caption.Text = if compact then compactNames[key] else definition[2]
			item.caption.TextSize = if compact then 9 else 13
			item.caption.TextXAlignment = if compact then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
			item.caption.Position = if compact then UDim2.fromOffset(0, 30) else UDim2.fromOffset(48, 0)
			item.caption.Size = if compact then UDim2.new(1, 0, 0, 18) else UDim2.new(1, -52, 1, 0)
			item.icon.Position = UDim2.fromOffset(14, if compact then 5 else 11)
		end

		-- avatar/username/role are children of `rail`, positioned in its
		-- local space via railLocalHeight (declared above) rather than raw
		-- size.Y, for the same reason navScroll's height calc needs it.
		Kit.place(avatar, if compact then 15 else 20, railLocalHeight - 64, 34, 34)
		Kit.place(username, 66, railLocalHeight - 68, 130, 24)
		Kit.place(role, 66, railLocalHeight - 43, 130, 20)

		avatar.Visible = showIdentity
		username.Visible = showIdentity
		role.Visible = showIdentity

		Kit.place(header, railWidth + gutter, 24 + topInset, width, 68)
		Kit.place(crumb, 0, 22, math.max(1, width - 390), 22)
		crumb.Visible = width > 650

		Kit.place(balance, math.max(0, width - 220), 8, math.min(width, 220), 28)
		Kit.place(telemetry, math.max(0, width - 250), 37, math.min(width, 250), 20)

		Kit.place(body, railWidth + gutter, 93 + topInset, width, math.max(1, size.Y - 93 - topInset))

		fitToasts(size, topInset)

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

		if not tutorialStarted and state and not state.tutorialComplete then
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

		refreshPresentation()
		for _, callback in ipairs(settingRefresh) do
			callback()
		end

		loadingSet(1, "State synchronized")
		defer(math.max(0, 1.1 - (os.clock() - loadingStarted)), finishLoading)
	end

	Kit.setValue(balance, fmt(s.compute) .. " compute", bumpPeak(1.035))

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
			"FPS %d   ·   PING %s",
			math.floor(frames / elapsed + 0.5),
			if ping then ping .. "ms" else "—"
		)
		elapsed, frames = 0, 0

		if text ~= telemetryText then
			telemetryText = text
			telemetry.Text = text
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
