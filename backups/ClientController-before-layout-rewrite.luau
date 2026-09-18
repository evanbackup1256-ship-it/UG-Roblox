local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local Run = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local UserInput = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local package = RS:WaitForChild("DeckGame")
local Config = require(package:WaitForChild("Config"))
local UI = require(package:WaitForChild("UIPrimitives"))
local Icons = require(package:WaitForChild("Icons"))
local MotionService = require(package:WaitForChild("MotionService"))
local Action = package:WaitForChild("Action")
local GetState = package:WaitForChild("GetState")
local Changed = package:WaitForChild("Changed")
local Preferences = package:WaitForChild("Preferences")
local Ping = package:WaitForChild("Ping")
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)
local C = {
	bg = Color3.fromRGB(12, 17, 23),
	side = Color3.fromRGB(18, 26, 34),
	panel = Color3.fromRGB(35, 47, 58),
	raised = Color3.fromRGB(48, 63, 75),
	text = Color3.fromRGB(244, 247, 248),
	muted = Color3.fromRGB(169, 183, 190),
	faint = Color3.fromRGB(112, 129, 138),
	accent = Color3.fromRGB(126, 235, 196),
	ink = Color3.fromRGB(13, 48, 39),
	line = Color3.fromRGB(94, 116, 128),
	danger = Color3.fromRGB(242, 170, 151)
}
local motion = true
local audioEnabled = true
local prefs = table.clone(Config.Settings)
local refreshSettings = function()
end
local preferencesHydrated = false
local preferenceVersion = 0
local purchaseQuantity = 1
local applyPreferences
local particleLayer
local soundFolder = Instance.new("Folder")
soundFolder.Name = "DeckAudio"
soundFolder.Parent = SoundService
local sounds = {}
for name, def in pairs({
	hover = {
		"139800881181209",
		0.07
	},
	click = {
		"88442833509532",
		0.16
	},
	switch = {
		"75490872912178",
		0.12
	},
	success = {
		"137214903496040",
		0.2
	},
	error = {
		"87519554692663",
		0.16
	},
	toggle = {
		"88442833509532",
		0.14,
		1.3
	},
	slider = {
		"139800881181209",
		0.1,
		0.8
	},
	purchase = {
		"137214903496040",
		0.18,
		1.2
	},
	research = {
		"137214903496040",
		0.22,
		0.85
	},
	boost = {
		"75490872912178",
		0.2,
		0.7
	},
	focus = {
		"139800881181209",
		0.08,
		1.15
	},
	open = {
		"75490872912178",
		0.1,
		0.9
	},
	close = {
		"87519554692663",
		0.08,
		1.2
	},
	tick = {
		"88442833509532",
		0.06,
		1.6
	},
	milestone = {
		"137214903496040",
		0.24,
		0.7
	},
	ambient = {
		"9042294694",
		0.04,
		0.8
	},
	confirm = {
		"137214903496040",
		0.14,
		1.35
	},
	page = {
		"75490872912178",
		0.09,
		0.76
	},
	deny = {
		"87519554692663",
		0.1,
		0.92
	}
}) do
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = "rbxassetid://" .. def[1]
	s.Volume = def[2]
	s.Parent = soundFolder
	sounds[name] = s
	s:SetAttribute("BaseVolume", def[2])
	s.PlaybackSpeed = def[3] or 1
end
local playlist = {
	{
		id = "9042295159",
		name = "Spirit Warmth"
	},
	{
		id = "9042294694",
		name = "Never Gone Forever"
	},
	{
		id = "9042293112",
		name = "Feelings of Time"
	}
}
local music = Instance.new("Sound")
music.Name = "DeckMusic"
music.Volume = 0
music.Parent = SoundService
local trackIndex = 0
local function nextTrack()
	trackIndex = trackIndex % # playlist + 1
	music.SoundId = "rbxassetid://" .. playlist[trackIndex].id
	if prefs.music then
		music:Play()
	end
end
music.Ended:Connect(nextTrack)
nextTrack()
applyPreferences = function()
	motion = prefs.motion
	audioEnabled = prefs.sfx
	for _, s in pairs(sounds) do
		s.Volume = (s:GetAttribute("BaseVolume") or 0.1) * prefs.masterVolume * prefs.sfxVolume
	end
	music.Volume = prefs.masterVolume * prefs.musicVolume
	if prefs.music then
		if not music.IsPlaying then
			music:Resume()
			if not music.IsPlaying then
				music:Play()
			end
		end
	else
		music:Pause()
	end
	if particleLayer then
		particleLayer.Visible = prefs.particles ~= false
	end
end
local function changePreference(key, value)
	prefs[key] = value
	applyPreferences()
	preferenceVersion += 1
	local version = preferenceVersion
	task.delay(0.3, function()
		if version == preferenceVersion then
			Preferences:FireServer(table.clone(prefs))
		end
	end)
end
applyPreferences()
task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync(soundFolder:GetChildren())
	end)
end)
local lastHover = 0
local function play(name)
	if not audioEnabled then
		return
	end
	if name == "hover" then
		if not prefs.hover or os.clock() - lastHover < 0.09 then
			return
		end
		lastHover = os.clock()
	end
	local s = sounds[name]
	if s then
		s.TimePosition = 0
		s:Play()
	end
end
local make = UI.create
local round = UI.round
local function label(parent, text, x, y, w, h, size, color, bold)
	return UI.label(parent, text, x, y, w, h, size, color or C.text, bold)
end
local activeTweens = setmetatable({}, {
	__mode = "k"
})
local magneticButtons = {}
local function tween(o, props, duration)
	local keys = activeTweens[o] or {}
	activeTweens[o] = keys
	for key in pairs(props) do
		if keys[key] then
			keys[key]:Cancel()
		end
	end
	if not motion then
		for k, v in pairs(props) do
			o[k] = v
		end
		return
	end
	local t = Tween:Create(o, TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
	for key in pairs(props) do
		keys[key] = t
	end
	t:Play()
end
local function panel(parent, name, x, y, w, h, color)
	local wrap = make("Frame", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		ClipsDescendants = false
	})
	local shadow = make("ImageLabel", wrap, {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://5028857084",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.88,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(99, 99, 158, 158),
		Position = UDim2.fromOffset(- 16, - 12),
		Size = UDim2.new(1, 32, 1, 32),
		ZIndex = 1
	})
	local surface = make("Frame", wrap, {
		Name = "Surface",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color or C.panel,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = 2
	})
	round(surface, 14)
	local outline = make("UIStroke", surface, {
		Color = C.line,
		Transparency = 0.52,
		Thickness = 1
	})
	wrap.MouseEnter:Connect(function()
		tween(outline, {
			Transparency = 0.28
		}, 0.18)
		tween(shadow, {
			ImageTransparency = 0.76
		}, 0.18)
	end)
	wrap.MouseLeave:Connect(function()
		tween(outline, {
			Transparency = 0.52
		}, 0.22)
		tween(shadow, {
			ImageTransparency = 0.88
		}, 0.22)
	end)
	return surface, wrap
end
local function button(parent, text, x, y, w, h, callback, primary)
	local b = make("TextButton", parent, {
		Name = text,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = primary and C.ink or C.text,
		BackgroundColor3 = primary and C.accent or C.raised,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ClipsDescendants = true,
		Selectable = false,
		ZIndex = 30
	})
	round(b, 11)
	b.TextXAlignment = Enum.TextXAlignment.Center
	b.TextYAlignment = Enum.TextYAlignment.Center
	b.TextScaled = false
	local magnet = {
		button = b,
		basePosition = b.Position,
		offset = Vector2.zero,
		active = false,
		spring = MotionService.vectorSpring(7, 1.05)
	}
	table.insert(magneticButtons, magnet)
	local edge = make("UIStroke", b, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = primary and C.accent or C.line,
		Thickness = 2,
		Transparency = primary and 0.86 or 0.9,
		LineJoinMode = Enum.LineJoinMode.Round,
		ZIndex = 31
	})
	local scale = make("UIScale", b, {
		Scale = 1
	})
	local sheen = make("Frame", b, {
		Name = "Sheen",
		Position = UDim2.fromScale(- 0.35, 0),
		Size = UDim2.fromScale(0.24, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Rotation = 12,
		ZIndex = 32
	})
	make("UICorner", sheen, {
		CornerRadius = UDim.new(0, 11)
	})
	b.MouseEnter:Connect(function()
		magnet.active = true
		if not b:GetAttribute("NoHoverStroke") then
			tween(edge, {
				Transparency = 0.35
			}, 0.16)
		end
		tween(sheen, {
			Position = UDim2.fromScale(1.2, 0)
		}, 0.42)
		play("hover")
	end)
	b.MouseLeave:Connect(function()
		magnet.active = false
		if not b:GetAttribute("NoHoverStroke") then
			tween(edge, {
				Transparency = 1
			}, 0.2)
		end
		tween(b, {
			TextTransparency = 0
		})
		tween(sheen, {
			Position = UDim2.fromScale(- 0.35, 0)
		}, 0.2)
	end)
	b.MouseButton1Down:Connect(function()
		if not b:GetAttribute("NoHoverStroke") then
			tween(edge, {
				Transparency = 0.05
			}, 0.08)
		end
		tween(scale, {
			Scale = 0.97
		}, 0.08)
		tween(b, {
			TextTransparency = 0.22
		}, 0.08)
	end)
	b.MouseButton1Up:Connect(function()
		if not b:GetAttribute("NoHoverStroke") then
			tween(edge, {
				Transparency = 0.5
			}, 0.14)
		end
		tween(scale, {
			Scale = 1
		}, 0.14)
		tween(b, {
			TextTransparency = 0
		}, 0.14)
	end)
	b.MouseLeave:Connect(function()
		tween(scale, {
			Scale = 1
		}, 0.14)
	end)
	b.Activated:Connect(function()
		play("click")
		callback()
	end)
	return b
end
local function fmt(n)
	n = n or 0
	if n >= 1e12 then
		return string.format("%.2fT", n / 1e12)
	end
	if n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	end
	if n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	end
	if n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return n % 1 == 0 and tostring(n) or string.format("%.1f", n)
end
local gui = make("ScreenGui", player:WaitForChild("PlayerGui"), {
	Name = "DeckEmpire",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
local backdrop = make("Frame", gui, {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0
})
particleLayer = make("Frame", gui, {
	Name = "AmbientParticles",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = false,
	ZIndex = 1
})
local particles = {}
math.randomseed(os.clock() * 1000)
for i = 1, 30 do
	local dot = make("Frame", particleLayer, {
		Name = "Particle",
		Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4)),
		Position = UDim2.fromScale(math.random(), 1 + math.random() * 0.2),
		BackgroundColor3 = i % 5 == 0 and C.accent or C.line,
		BackgroundTransparency = 0.58 + math.random() * 0.28,
		BorderSizePixel = 0,
		ZIndex = 1
	})
	round(dot, 4)
	table.insert(particles, {
		object = dot,
		x = math.random(),
		y = 1 + math.random() * 0.2,
		speed = 0.012 + math.random() * 0.022,
		phase = math.random() * 6.28,
		drift = 0.006 + math.random() * 0.014
	})
end
local canvas = make("Frame", backdrop, {
	Name = "Canvas",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1
})
local side = make("Frame", canvas, {
	Name = "Navigation",
	Size = UDim2.fromOffset(200, 780),
	BackgroundColor3 = C.side,
	BorderSizePixel = 0
})
make("Frame", side, {
	Position = UDim2.new(1, - 1, 0, 0),
	Size = UDim2.new(0, 1, 1, 0),
	BackgroundColor3 = C.line,
	BackgroundTransparency = 0.7,
	BorderSizePixel = 0
})
local logo = make("Frame", side, {
	Position = UDim2.fromOffset(26, 34),
	Size = UDim2.fromOffset(30, 30),
	BackgroundColor3 = C.accent,
	BorderSizePixel = 0
})
round(logo, 9)
local logoText = label(logo, "D", 0, 0, 30, 30, 20, C.ink, true)
logoText.TextXAlignment = Enum.TextXAlignment.Center
label(side, "deck", 68, 31, 110, 30, 27, C.text, true)
label(side, "CLOUD EMPIRE", 27, 85, 160, 16, 10, C.faint, true)
label(side, "WORKSPACE", 27, 133, 160, 18, 10, C.faint, true)
local navButtons = {}
local switchPage
local pageOrder = {
	overview = 1,
	infrastructure = 2,
	research = 3,
	contracts = 4,
	rewards = 5,
	shop = 6,
	events = 7,
	settings = 8
}
local definitions = {
	{
		"overview",
		"Overview",
		""
	},
	{
		"infrastructure",
		"Infrastructure",
		""
	},
	{
		"research",
		"Research",
		""
	},
	{
		"contracts",
		"Contracts",
		""
	},
	{
		"rewards",
		"Rewards",
		""
	},
	{
		"shop",
		"Shop",
		""
	},
	{
		"events",
		"News & codes",
		""
	}
}
for i, def in ipairs(definitions) do
	local b = button(side, "", 16, 164 + (i - 1) * 52, 168, 44, function()
		switchPage(def[1])
	end, false)
	b.Name = "Nav_" .. def[1]
	b.BackgroundTransparency = 1
	local icon = label(b, def[3], 13, 0, 26, 44, 22, C.muted, true)
	Icons.attach(icon, def[1])
	icon.TextXAlignment = Enum.TextXAlignment.Center
	local text = label(b, def[2], 47, 0, 113, 44, 13, C.muted, true)
	navButtons[def[1]] = {
		button = b,
		text = text,
		icon = icon
	}
end
local note = panel(side, "Guide", 16, 532, 168, 88, C.panel)
label(note, "A little, then a lot.", 14, 15, 142, 20, 12, C.text, true)
local tip = label(note, "Run jobs. Deploy servers.", 14, 42, 140, 20, 11, C.muted, false)
tip.TextWrapped = true
tip.TextTruncate = Enum.TextTruncate.None
label(note, "YOUR NEXT BIG THING", 14, 67, 142, 14, 8, C.accent, true)
local preferencesButton = button(side, "", 16, 650, 168, 38, function()
	switchPage("settings")
end, false)
preferencesButton:SetAttribute("NoHoverStroke", true)
local preferencesIcon = label(preferencesButton, "", 13, 0, 26, 38, 14, C.muted, false)
Icons.attach(preferencesIcon, "settings")
local preferencesTitle = label(preferencesButton, "Preferences", 47, 0, 113, 38, 13, C.text, true)
preferencesButton.MouseEnter:Connect(function()
	tween(preferencesButton, {
		BackgroundColor3 = C.raised
	}, 0.16)
end)
preferencesButton.MouseLeave:Connect(function()
	tween(preferencesButton, {
		BackgroundColor3 = C.panel
	}, 0.2)
end)
local avatar = make("Frame", side, {
	Position = UDim2.fromOffset(25, 716),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = C.raised,
	BorderSizePixel = 0
})
round(avatar, 17)
local avatarPreview = require(package:WaitForChild("AvatarPreview")).new(avatar, player, function()
	return motion
end)
local avatarName = label(side, player.DisplayName, 70, 713, 114, 21, 12, C.text, true)
local avatarRole = label(side, "Cloud founder", 70, 735, 114, 16, 10, C.faint, false)
local main = make("Frame", canvas, {
	Name = "Main",
	Position = UDim2.fromOffset(228, 0),
	Size = UDim2.fromOffset(984, 780),
	BackgroundTransparency = 1
})
label(main, "YOUR CLOUD  /", 0, 26, 110, 24, 10, C.faint, true)
local crumb = label(main, "Overview", 108, 26, 220, 24, 11, C.muted, true)
local saveLabel = label(main, "Connecting…", 480, 26, 170, 24, 10, C.muted, false)
saveLabel.TextXAlignment = Enum.TextXAlignment.Right
local fpsLabel = label(main, "FPS  --", 660, 26, 78, 24, 10, C.muted, true)
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
local pingLabel = label(main, "PING  --", 746, 26, 90, 24, 10, C.muted, true)
pingLabel.TextXAlignment = Enum.TextXAlignment.Right
local status = make("Frame", main, {
	Position = UDim2.fromOffset(870, 32),
	Size = UDim2.fromOffset(102, 20),
	BackgroundColor3 = C.raised,
	BorderSizePixel = 0
})
round(status, 10)
local statusText = label(status, "CONNECTING", 10, 0, 86, 20, 9, C.muted, true)
statusText.Position = UDim2.fromOffset(0, 0)
statusText.Size = UDim2.fromScale(1, 1)
statusText.TextXAlignment = Enum.TextXAlignment.Center
statusText.TextSize = 11
make("Frame", main, {
	Position = UDim2.fromOffset(0, 67),
	Size = UDim2.fromOffset(984, 1),
	BorderSizePixel = 0,
	BackgroundColor3 = C.line,
	BackgroundTransparency = 0.7
})
local pages = {}
for _, name in ipairs({
	"overview",
	"infrastructure",
	"research",
	"contracts",
	"rewards",
	"shop",
	"events",
	"settings"
}) do
	pages[name] = make("ScrollingFrame", main, {
		Name = name,
		Position = UDim2.fromOffset(- 14, 79),
		Size = UDim2.fromOffset(1012, 685),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = C.faint,
		ScrollBarImageTransparency = 0.28,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false
	})
	make("UIScale", pages[name], {
		Name = "MotionScale",
		Scale = 1
	})
	make("UIPadding", pages[name], {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 24)
	})
end
local state = nil
local updateCallbacks = {}
local frameCount = 0
local frameClock = 0
local function updatePing()
	local started = os.clock()
	local ok = pcall(function()
		Ping:InvokeServer(started)
	end)
	if ok then
		local milliseconds = math.clamp(math.floor((os.clock() - started) * 500 + 0.5), 1, 999)
		pingLabel.Text = "PING  " .. milliseconds .. "ms"
		pingLabel.TextColor3 = milliseconds > 180 and Color3.fromRGB(242, 188, 148) or C.muted
	else
		pingLabel.Text = "PING  --"
	end
end
task.spawn(function()
	while gui.Parent do
		updatePing()
		task.wait(2)
	end
end)
local toast = make("TextLabel", canvas, {
	Name = "Toast",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromOffset(728, 762),
	Size = UDim2.fromOffset(450, 44),
	BackgroundColor3 = C.accent,
	TextColor3 = C.ink,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	Text = "",
	Visible = false,
	ZIndex = 20,
	BorderSizePixel = 0
})
round(toast, 12)
local toastVersion = 0
local function notify(text, ok, soundName)
	toastVersion += 1
	local version = toastVersion
	toast.Text = text
	toast.BackgroundColor3 = ok == false and Color3.fromRGB(240, 188, 150) or C.accent
	play(ok == false and "error" or soundName or "success")
	if not prefs.notifications and ok ~= false then
		toast.Visible = false
		return
	end
	toast.Visible = true
	toast.Position = UDim2.new(0.5, 0, 1, - 10)
	toast.TextTransparency = 1
	toast.BackgroundTransparency = 1
	tween(toast, {
		Position = UDim2.new(0.5, 0, 1, - 24),
		TextTransparency = 0,
		BackgroundTransparency = 0
	}, 0.24)
	task.delay(2.6, function()
		if version == toastVersion then
			tween(toast, {
				TextTransparency = 1,
				BackgroundTransparency = 1
			}, 0.2)
			task.delay(0.2, function()
				if version == toastVersion then
					toast.Visible = false
				end
			end)
		end
	end)
end
local function apply(s)
	if not s then
		return
	end
	state = s
	if not preferencesHydrated and s.settings then
		preferencesHydrated = true
		for k, v in pairs(s.settings) do
			if Config.Settings[k] ~= nil then
				prefs[k] = v
			end
		end
		applyPreferences()
		refreshSettings()
	end
	saveLabel.Text = s.saveStatus or "Connected"
	statusText.Text = "●  CONNECTED"
	statusText.TextColor3 = C.accent
	for _, callback in ipairs(updateCallbacks) do
		callback(s)
	end
end
local pending = false
local function act(kind, key)
	if pending or not state then
		return
	end
	pending = true
	local ok, result = pcall(function()
		return Action:InvokeServer(kind, key, kind == "buy" and purchaseQuantity or nil)
	end)
	pending = false
	if ok and result then
		apply(result.state)
		notify(result.message, result.ok, kind == "buy" and "purchase" or kind == "research" and "research" or kind == "boost" and "boost" or "success")
	else
		notify("Connection interrupted. Try again.", false)
	end
end
local viewports = {}
local crateViewports = {}
local allViewports = {}
local activeOrbit = nil
local viewportClock = 0
local visibilityClock = 0
local viewportBudget = 10
local particleClock = 0
local function serverRoom(parent, x, y, w, h, tierIndex)
	local viewport = make("ViewportFrame", parent, {
		Name = "CloudRoom",
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(181, 199, 204),
		LightColor = Color3.fromRGB(246, 255, 249),
		LightDirection = Vector3.new(- 1, - 0.7, - 1),
		ZIndex = 3,
		Active = true
	})
	viewport:SetAttribute("LayoutVisible", true)
	local world = make("WorldModel", viewport, {})
	local camera = make("Camera", viewport, {
		FieldOfView = 34,
		CFrame = CFrame.lookAt(Vector3.new(13, 11, 16), Vector3.new(0, 2, 0))
	})
	viewport.CurrentCamera = camera
	local function part(size, pos, color, material)
		return make("Part", world, {
			Size = size,
			Position = pos,
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
			Anchored = true,
			CanCollide = false,
			TopSurface = Enum.SurfaceType.Smooth,
			BottomSurface = Enum.SurfaceType.Smooth
		})
	end
	local sceneSeed = tierIndex or 1
	local cols = math.min(3, 2 + math.floor((sceneSeed - 1) / 8) % 2)
	local rows = math.min(2, 1 + math.floor((sceneSeed - 1) / 15) % 2)
	local width = cols * 3.6 + 1
	local depth = rows * 4 + 1
	part(Vector3.new(width, 0.3, depth), Vector3.new(0, - 0.15, 0), Color3.fromRGB(53, 72, 74))
	part(Vector3.new(width + 0.2, 0.12, depth + 0.2), Vector3.new(0, - 0.35, 0), Color3.fromRGB(18, 29, 34))
	for sideIndex = - 1, 1, 2 do
		part(Vector3.new(0.045, 0.03, depth - 0.3), Vector3.new(sideIndex * (width / 2 - 0.2), 0.02, 0), C.accent, Enum.Material.Neon)
	end
	local lights = {}
	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			local x1 = (col - (cols - 1) / 2) * 3.6
			local z = (row - (rows - 1) / 2) * 4
			local shellColor = (tierIndex and Config.Tiers[tierIndex].color:Lerp(Color3.fromRGB(45, 58, 70), 0.72)) or Color3.fromRGB(53, 69, 80)
			part(Vector3.new(2.3, 4.6, 2.4), Vector3.new(x1, 2.3, z), shellColor)
			part(Vector3.new(2.1, 0.13, 2.25), Vector3.new(x1, 4.65, z), Color3.fromRGB(141, 165, 170))
			for sideIndex = - 1, 1, 2 do
				part(Vector3.new(0.08, 4.25, 0.12), Vector3.new(x1 + sideIndex * 1.03, 2.3, z + 1.25), Color3.fromRGB(111, 136, 145))
			end
			for slot = 0, 3 do
				part(Vector3.new(1.84, 0.52, 0.16), Vector3.new(x1, 0.7 + slot * 0.78, z + 1.22), Color3.fromRGB(83, 105, 117))
				local light = part(Vector3.new(0.1, 0.12, 0.1), Vector3.new(x1 + 0.68, 0.7 + slot * 0.78, z + 1.34), C.accent, Enum.Material.Neon)
				table.insert(lights, light)
				part(Vector3.new(0.82, 0.07, 0.1), Vector3.new(x1 - 0.22, 0.7 + slot * 0.78, z + 1.34), Color3.fromRGB(26, 34, 36))
			end
		end
	end
	if tierIndex and tierIndex >= 5 then
		local tint = Config.Tiers[tierIndex].color
		local sphere = part(Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, 6, 0), tint, Enum.Material.Neon)
		sphere.Shape = Enum.PartType.Ball
		for i = 0, math.min(6, 3 + (sceneSeed % 4)) do
			local angle = i * math.pi / 4
			local orbit = 2.8 + (sceneSeed % 3) * 0.45
			local node = part(Vector3.new(0.22 + (sceneSeed % 3) * 0.04, 0.22 + (sceneSeed % 3) * 0.04, 0.22 + (sceneSeed % 3) * 0.04), Vector3.new(math.cos(angle) * orbit, 6 + (sceneSeed % 2) * 0.35, math.sin(angle) * orbit), tint, Enum.Material.Neon)
			node.Shape = Enum.PartType.Ball
		end
		if sceneSeed % 3 == 0 then
			for ring = 1, 2 do
				part(Vector3.new(0.08, 0.08, 5.8 + ring * 0.45), Vector3.new(0, 6, 0), tint, Enum.Material.Neon)
			end
		end
	end
	table.insert(updateCallbacks, function(s)
		local count = math.clamp((tierIndex and s.owned[Config.Tiers[tierIndex].key] or s.units) * 5, 0, # lights)
		for i, l in ipairs(lights) do
			l.Color = i <= count and C.accent or Color3.fromRGB(72, 92, 87)
		end
	end)
	local entry = {
		viewport = viewport,
		camera = camera,
		angle = 0.67,
		target = 0.67,
		dragging = false,
		radius = math.sqrt(width * width + depth * depth) / 2,
		hovered = false,
		active = true,
		kind = "server"
	}
	table.insert(viewports, entry)
	table.insert(allViewports, entry)
	viewport.MouseEnter:Connect(function()
		entry.hovered = true
	end)
	viewport.MouseLeave:Connect(function()
		entry.hovered = false
	end)
	viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			entry.dragging = true
			entry.last = input.Position.X
			activeOrbit = entry
		end
	end)
	return viewport
end
local function crateRoom(parent, x, y, w, h, crate)
	local viewport = make("ViewportFrame", parent, {
		Name = "CrateViewport",
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(130, 150, 160),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(- 1, - 0.5, - 1),
		ZIndex = 3,
		Active = true
	})
	viewport:SetAttribute("LayoutVisible", true)
	local world = make("WorldModel", viewport, {})
	local camera = make("Camera", viewport, {
		FieldOfView = 28
	})
	viewport.CurrentCamera = camera
	local tint = crate.color
	local function part(size, pos, color, mat, shape)
		local p = make("Part", world, {
			Size = size,
			Position = pos,
			Color = color,
			Material = mat or Enum.Material.SmoothPlastic,
			Anchored = true,
			CanCollide = false
		});
		if shape then
			p.Shape = shape
		end
		return p
	end
	part(Vector3.new(7, 0.3, 6), Vector3.new(0, - 2.25, 0), Color3.fromRGB(16, 22, 28), Enum.Material.Metal)
	part(Vector3.new(5.8, 3.8, 4.8), Vector3.new(0, 0, 0), Color3.fromRGB(31, 42, 50), Enum.Material.Metal)
	part(Vector3.new(5.25, 3.25, 4.25), Vector3.new(0, 0.2, 0), tint, Enum.Material.Glass)
	for sx = - 1, 1, 2 do
		for sz = - 1, 1, 2 do
			part(Vector3.new(0.16, 4.2, 0.16), Vector3.new(sx * 2.65, 0, sz * 2.15), tint, Enum.Material.Neon)
		end
	end
	part(Vector3.new(0.3, 0.3, 0.3), Vector3.new(0, 2.15, 0), tint, Enum.Material.Neon, Enum.PartType.Ball)
	for i = 1, 8 do
		local a = i * math.pi / 4
		local n = part(Vector3.new(0.18, 0.18, 0.18), Vector3.new(math.cos(a) * 3.1, 2.1, math.sin(a) * 3.1), tint, Enum.Material.Neon, Enum.PartType.Ball)
	end
	local entry = {
		viewport = viewport,
		camera = camera,
		angle = 0,
		radius = 11,
		crate = crate,
		active = true,
		kind = "crate"
	}
	table.insert(crateViewports, entry)
	table.insert(allViewports, entry)
	return viewport
end
UserInput.InputChanged:Connect(function(input)
	if activeOrbit and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		activeOrbit.target -= (input.Position.X - activeOrbit.last) * 0.008
		activeOrbit.last = input.Position.X
	end
end)
UserInput.InputEnded:Connect(function(input)
	if activeOrbit and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		activeOrbit.dragging = false
		activeOrbit = nil
	end
end)
Run.RenderStepped:Connect(function(dt)
	frameCount += 1
	frameClock += dt
	if frameClock >= 0.5 then
		local fps = math.floor(frameCount / frameClock + 0.5)
		fpsLabel.Text = "FPS  " .. math.clamp(fps, 0, 999)
		fpsLabel.TextColor3 = fps < 30 and Color3.fromRGB(242, 188, 148) or C.muted
		frameCount = 0
		frameClock = 0
	end
	local now = os.clock()
	local pointer = UserInput:GetMouseLocation()
	for _, m in ipairs(magneticButtons) do
		local b = m.button
		if b.Parent and b.Visible then
			local center = b.AbsolutePosition + b.AbsoluteSize / 2
			local delta = pointer - center
			local distance = delta.Magnitude
			local target = Vector2.zero
			if m.active and distance < 110 then
				target = delta * (0.10 * (1 - distance / 110))
			end
			m.offset = m.spring:Step(target, dt)
			local base = m.basePosition
			b.Position = UDim2.new(base.X.Scale, base.X.Offset + math.round(m.offset.X), base.Y.Scale, base.Y.Offset + math.round(m.offset.Y))
		end
	end
	particleClock += dt
	if particleClock >= 1 / 30 then
		local step = particleClock
		particleClock = 0
		particleLayer.Visible = prefs.particles ~= false
		for _, p in ipairs(particles) do
			p.y -= step * p.speed
			if p.y < - .06 then
				p.y = 1.04
				p.x = math.random()
			end
			p.object.Position = UDim2.fromScale(p.x + math.sin(now + p.phase) * p.drift, p.y)
		end
	end
	viewportClock += dt
	if viewportClock < 1 / 60 then
		return
	end
	local step = viewportClock
	viewportClock = 0
	visibilityClock += step
	if visibilityClock >= 0.12 then
		visibilityClock = 0
		local candidates = {}
		for _, entry in ipairs(allViewports) do
			local visible = prefs.previews ~= false and entry.viewport.Parent ~= nil and entry.viewport:GetAttribute("LayoutVisible") ~= false
			local ancestor = entry.viewport.Parent
			while visible and ancestor and ancestor ~= gui do
				if ancestor:IsA("GuiObject") and not ancestor.Visible then
					visible = false
					break
				end
				ancestor = ancestor.Parent
			end
			if visible then
				local pos = entry.viewport.AbsolutePosition
				local size = entry.viewport.AbsoluteSize
				visible = pos.Y + size.Y >= 0 and pos.Y <= backdrop.AbsoluteSize.Y
			end
			entry.active = visible
			entry.viewport.ImageTransparency = visible and 0 or 1
			if visible then
				local center = entry.viewport.AbsolutePosition + entry.viewport.AbsoluteSize / 2
				local viewportCenter = backdrop.AbsolutePosition + backdrop.AbsoluteSize / 2
				table.insert(candidates, {
					entry = entry,
					distance = (center - viewportCenter).Magnitude
				})
			end
		end
		table.sort(candidates, function(a, b)
			return a.distance < b.distance
		end)
		for index, candidate in ipairs(candidates) do
			candidate.entry.active = index <= viewportBudget or candidate.entry.hovered or candidate.entry.dragging
			candidate.entry.viewport.Visible = candidate.entry.active
		end
		for _, entry in ipairs(allViewports) do
			if not entry.active then
				entry.viewport.Visible = false
			end
		end
	end
	for _, entry in ipairs(crateViewports) do
		if entry.active then
			entry.angle += step * 0.35
			local target = Vector3.new(0, 0, 0)
			local d = entry.radius
			entry.camera.CFrame = CFrame.lookAt(target + Vector3.new(math.sin(entry.angle) * d, 5.5, math.cos(entry.angle) * d), target)
		end
	end
	for _, entry in ipairs(viewports) do
		if entry.active then
			if prefs.autoOrbit and motion and not entry.dragging and not entry.hovered then
				entry.target += step * prefs.orbitSpeed * 0.4
			end
			entry.angle = motion and entry.angle + (entry.target - entry.angle) * math.min(1, step * 10) or entry.target
			local aspect = entry.viewport.AbsoluteSize.X / math.max(1, entry.viewport.AbsoluteSize.Y)
			local distance = math.max(12, (entry.radius + 1) / math.tan(math.rad(17)) * math.max(0.72, 1 / math.max(0.5, aspect)))
			local target = Vector3.new(0, 1.85, 0)
			entry.camera.CFrame = CFrame.lookAt(target + Vector3.new(math.sin(entry.angle) * distance, distance * 0.54, math.cos(entry.angle) * distance), target)
		end
	end
end)
local home = pages.overview
local hero = panel(home, "Hero", 0, 0, 984, 280, Color3.fromRGB(39, 67, 56))
label(hero, "START SMALL. BUILD SOMETHING REAL.", 26, 22, 570, 18, 10, C.accent, true)
label(hero, "Your cloud, your way.", 26, 75, 565, 44, 34, C.text, true)
label(hero, "Stack a first rack, tune the system, and scale when you're ready.", 27, 126, 540, 22, 14, C.muted, false)
local job = button(hero, "Run a job   +2", 27, 198, 165, 42, function()
	act("job")
end, true)
label(hero, "One job at a time. It adds up.", 209, 208, 350, 22, 12, C.muted, false)
serverRoom(hero, 605, 0, 368, 256)
local orbitHint = label(hero, "DRAG TO ORBIT", 615, 250, 348, 18, 11, C.muted, false)
orbitHint.TextXAlignment = Enum.TextXAlignment.Center
local stats = {}
for i, def in ipairs({
	{
		"BALANCE",
		"Available compute"
	},
	{
		"PRODUCTION",
		"Compute / second"
	},
	{
		"YOUR FLEET",
		"Infrastructure units"
	}
}) do
	local card = panel(home, "Stat" .. i, (i - 1) * 334, 300, 316, 98)
	label(card, def[1], 20, 15, 190, 14, 9, C.muted, true)
	stats[i] = label(card, "—", 20, 38, 270, 30, 27, i == 2 and C.accent or C.text, true)
	label(card, def[2], 20, 75, 270, 14, 10, C.faint, false)
end
table.insert(updateCallbacks, function(s)
	stats[1].Text = fmt(s.compute)
	stats[2].Text = fmt(s.rate) .. " /s"
	stats[3].Text = tostring(s.units)
	job.Text = "Run a job   +" .. fmt(Config.job(s))
end)
label(home, "Your infrastructure", 0, 420, 440, 27, 21, C.text, true)
label(home, "The machines doing the work right now.", 0, 451, 600, 18, 12, C.muted, false)
button(home, "View all  →", 860, 421, 124, 34, function()
	switchPage("infrastructure")
end, false)
local function tierCard(parent, tier, index, x, y, w, large)
	local h = large and 214 or 148
	local card = panel(parent, "Tier_" .. tier.key, x, y, w, h)
	local icon = make("Frame", card, {
		Position = UDim2.fromOffset(20, 20),
		Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = tier.color,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 3
	})
	round(icon, 10)
	local tierIcon = label(icon, "", 0, 0, 36, 36, 14, tier.color, true)
	tierIcon.TextXAlignment = Enum.TextXAlignment.Center
	Icons.attach(tierIcon, tier.icon or "infrastructure")
	label(card, tier.name, 68, 19, w - 160, 22, 16, C.text, true)
	local count = label(card, "0 owned", w - 109, 22, 89, 18, 10, C.muted, false)
	count.TextXAlignment = Enum.TextXAlignment.Right
	label(card, large and tier.subtitle or "+" .. fmt(tier.rate) .. " compute /s each", 68, 46, w - 93, 18, 11, C.muted, false)
	if large then
		label(card, "BASE OUTPUT", 20, 90, w - 40, 15, 9, C.faint, true)
		label(card, "+" .. fmt(tier.rate) .. " /s", 20, 111, w - 40, 29, 25, tier.color, true)
		serverRoom(card, w - 200, 69, 175, 90, index)
	end
	local price = label(card, "— compute", 20, h - 56, w - 204, 30, 14, C.text, true)
	local buy = button(card, "Deploy  +", w - 153, h - 59, 133, 38, function()
		act("buy", tier.key)
	end, true)
	table.insert(updateCallbacks, function(s)
		local n = s.owned[tier.key]
		local cost = Config.buyCost(tier, n, s)
		count.Text = n .. " owned"
		price.Text = fmt(cost) .. " compute each"
		local unlocked = s.units >= tier.unlock
		buy.Text = n >= 200 and "At capacity" or (unlocked and "Deploy  +" or tier.unlock .. " units to unlock")
		buy.TextSize = unlocked and 13 or 12
		buy.BackgroundColor3 = (unlocked and s.compute >= cost and n < 200) and C.accent or C.raised
		buy.TextColor3 = (unlocked and s.compute >= cost and n < 200) and C.ink or C.muted
	end)
end
for i = 1, 2 do
	tierCard(home, Config.Tiers[i], i, (i - 1) * 501, 489, 483, false)
end
local objective = panel(home, "NextContract", 0, 657, 984, 70)
local objectiveTitle = label(objective, "Your first milestone", 20, 12, 660, 21, 13, C.text, true)
local objectiveText = label(objective, "Deploy a server rack to complete your first contract.", 20, 37, 690, 17, 11, C.muted, false)
button(objective, "Contracts  →", 808, 16, 156, 36, function()
	switchPage("contracts")
end, false)
table.insert(updateCallbacks, function(s)
	local nextItem = nil
	for _, c in ipairs(Config.Contracts) do
		if not s.claimed[c.key] then
			nextItem = c
			break
		end
	end
	objectiveTitle.Text = nextItem and ("NEXT MILESTONE  /  " .. nextItem.name) or "Every contract complete"
	objectiveText.Text = nextItem and (nextItem.subtitle .. "  ·  Reward " .. fmt(nextItem.reward) .. " compute") or "Your cloud is thriving. Keep scaling your infrastructure."
end)
local infra = pages.infrastructure
label(infra, "Room to grow.", 0, 2, 900, 43, 32, C.text, true)
label(infra, "Every unit earns while you play. Bulk orders buy up to your selected amount.", 0, 53, 760, 23, 13, C.muted, false)
local quantityButton
quantityButton = button(infra, "Buy ×1", 820, 40, 164, 38, function()
	purchaseQuantity = purchaseQuantity == 1 and 5 or purchaseQuantity == 5 and 10 or 1
	quantityButton.Text = "Buy ×" .. purchaseQuantity
end, false)
for i, t in ipairs(Config.Tiers) do
	tierCard(infra, t, i, ((i - 1) % 2) * 501, 104 + math.floor((i - 1) / 2) * 235, 483, true)
end
local research = pages.research
label(research, "Work smarter.", 0, 2, 900, 43, 32, C.text, true)
label(research, "Small improvements. Compounding returns.", 0, 53, 900, 23, 13, C.muted, false)
for i, r in ipairs(Config.Research) do
	local card = panel(research, "Research_" .. r.key, ((i - 1) % 2) * 501, 104 + math.floor((i - 1) / 2) * 302, 483, 280)
	local researchIcon = label(card, "", 24, 22, 22, 22, 12, C.accent, true)
	Icons.attach(researchIcon, "research")
	label(card, string.format("%02d", i) .. "  /  RESEARCH", 54, 24, 370, 18, 12, C.accent, true)
	label(card, r.name, 24, 64, 430, 30, 24, C.text, true)
	label(card, r.subtitle, 24, 106, 430, 34, 12, C.muted, false).TextWrapped = true
	local level = label(card, "Level 0 / 8", 24, 163, 420, 22, 13, C.text, true)
	local track = make("Frame", card, {
		Position = UDim2.fromOffset(24, 196),
		Size = UDim2.fromOffset(435, 4),
		BackgroundColor3 = C.raised,
		BorderSizePixel = 0,
		ZIndex = 3
	})
	round(track, 2)
	local fill = make("Frame", track, {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.accent,
		BorderSizePixel = 0,
		ZIndex = 4
	})
	round(fill, 2)
	local cost = label(card, "—", 24, 225, 225, 28, 14, C.text, true)
	local buy = button(card, "Research  +", 309, 220, 150, 38, function()
		act("research", r.key)
	end, true)
	table.insert(updateCallbacks, function(s)
		local n = s.research[r.key]
		local price = Config.researchCost(r, n, s)
		level.Text = "Level " .. n .. " / " .. r.max
		cost.Text = n >= r.max and "Fully upgraded" or fmt(price) .. " compute"
		tween(fill, { Size = UDim2.fromScale(n / r.max, 1) }, 0.35)
		buy.Text = n >= r.max and "Complete" or "Research  +"
		buy.BackgroundColor3 = (s.compute >= price and n < r.max) and C.accent or C.raised
		buy.TextColor3 = (s.compute >= price and n < r.max) and C.ink or C.muted
	end)
end
local explainer = panel(research, "ResearchGuide", 0, 104 + math.ceil(# Config.Research / 2) * 302, 984, 104)
label(explainer, "Make every server count.", 24, 21, 910, 25, 17, C.text, true)
label(explainer, "Parallel processing boosts your entire fleet. Job optimization increases every manual job payout.", 24, 56, 923, 22, 12, C.muted, false)
local contracts = pages.contracts
label(contracts, "Big things, one step at a time.", 0, 2, 950, 43, 32, C.text, true)
label(contracts, "Complete milestones and reinvest the rewards into your cloud.", 0, 53, 940, 23, 13, C.muted, false)
for i, c in ipairs(Config.Contracts) do
	local card = panel(contracts, "Contract_" .. c.key, 0, 103 + (i - 1) * 110, 984, 92)
	label(card, string.format("%02d", i), 22, 20, 46, 40, 24, C.faint, true)
	label(card, c.name, 84, 13, 550, 23, 15, C.text, true)
	label(card, c.subtitle, 84, 40, 580, 18, 11, C.muted, false)
	local progress = label(card, "0 / " .. fmt(c.target), 654, 17, 135, 22, 11, C.muted, false)
	progress.TextXAlignment = Enum.TextXAlignment.Right
	local track = make("Frame", card, {
		Position = UDim2.fromOffset(84, 70),
		Size = UDim2.fromOffset(705, 3),
		BackgroundColor3 = C.raised,
		BorderSizePixel = 0,
		ZIndex = 3
	})
	round(track, 2)
	local fill = make("Frame", track, {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.accent,
		BorderSizePixel = 0,
		ZIndex = 4
	})
	round(fill, 2)
	local claim = button(card, "Claim " .. fmt(c.reward), 815, 27, 149, 38, function()
		act("claim", c.key)
	end, true)
	table.insert(updateCallbacks, function(s)
		local n = Config.metric(s, c.metric)
		local ready = n >= c.target and not s.claimed[c.key]
		progress.Text = fmt(math.min(n, c.target)) .. " / " .. fmt(c.target)
		tween(fill, { Size = UDim2.fromScale(math.clamp(n / c.target, 0, 1), 1) }, 0.35)
		local reward = Config.reward(c, s)
		claim.Text = s.claimed[c.key] and "Completed" or (ready and "Claim " .. fmt(reward) or "+" .. fmt(reward) .. " compute")
		claim.BackgroundColor3 = ready and C.accent or C.raised
		claim.TextColor3 = ready and C.ink or C.muted
	end)
end
local rewards = pages.rewards
label(rewards, "Keep the streak alive.", 0, 2, 950, 43, 32, C.text, true)
label(rewards, "Daily drops and permanent achievements, all earned in play.", 0, 53, 940, 23, 13, C.muted, false)
local daily = panel(rewards, "DailyReward", 0, 104, 984, 142, Color3.fromRGB(38, 52, 48))
local dailyIcon = label(daily, "", 24, 18, 22, 22, 11, C.accent, true)
Icons.attach(dailyIcon, "rewards")
label(daily, "DAILY DROP", 54, 20, 370, 18, 11, C.accent, true)
local dailyInfo = label(daily, "Your next reward is waiting.", 24, 51, 620, 24, 18, C.text, true)
local dailyButton = button(daily, "Claim reward", 795, 48, 165, 42, function()
	act("daily")
end, true)
table.insert(updateCallbacks, function(s)
	local today = os.date("!%Y-%m-%d")
	local claimed = s.daily and s.daily.day == today
	dailyInfo.Text = claimed and ("Streak " .. tostring(s.daily.streak) .. "  ·  Come back tomorrow") or ("Day " .. tostring((s.daily and s.daily.streak or 0) + 1) .. "  ·  +" .. tostring(100 + ((s.daily and s.daily.streak or 0) + 1) * 50) .. " compute")
	dailyButton.Text = claimed and "Claimed" or "Claim reward"
	dailyButton.BackgroundColor3 = claimed and C.raised or C.accent
	dailyButton.TextColor3 = claimed and C.muted or C.ink
end)
for i, a in ipairs(Config.Achievements) do
	local card = panel(rewards, "Achievement_" .. a.key, ((i - 1) % 2) * 501, 274 + math.floor((i - 1) / 2) * 116, 483, 96)
	local achievementIcon = label(card, "", 20, 16, 22, 22, 11, a.color or C.accent, true)
	Icons.attach(achievementIcon, a.icon or "rewards")
	label(card, a.name, 54, 14, 266, 22, 15, C.text, true)
	label(card, a.subtitle, 20, 43, 300, 18, 11, C.muted, false)
	local claim = button(card, "Locked", 332, 29, 128, 36, function()
		act("achievement", a.key)
	end, false)
	table.insert(updateCallbacks, function(s)
		local metric = s.achievementMetrics and s.achievementMetrics[a.metric] or 0
		local done = s.achievements and s.achievements[a.key]
		claim.Text = done and "Unlocked" or (metric >= a.target and "Unlock" or fmt(math.min(metric, a.target)) .. " / " .. fmt(a.target))
		claim.BackgroundColor3 = (done or metric < a.target) and C.raised or C.accent
		claim.TextColor3 = (done or metric < a.target) and C.muted or C.ink
	end)
end
local shop = pages.shop
label(shop, "The exchange.", 0, 2, 950, 43, 32, C.text, true)
label(shop, "Deploy a complete fleet package. Every server starts producing immediately.", 0, 53, 940, 23, 13, C.muted, false)
local shopService = require(package:WaitForChild("ShopService"))
local shopBalance = label(shop, "— compute", 0, 91, 300, 22, 13, C.accent, true)
for i, crate in ipairs(Config.ShopOffers) do
	local card = panel(shop, "Crate_" .. crate.key, ((i - 1) % 3) * 334, 130, 316, 350, Color3.fromRGB(28, 35, 43))
	crateRoom(card, 18, 22, 280, 180, crate)
	label(card, crate.name, 20, 217, 276, 25, 19, C.text, true)
	label(card, crate.subtitle, 20, 247, 276, 18, 11, C.muted, false)
	label(card, tostring(crate.quantity) .. " SERVERS · 5% PACKAGE SAVING", 20, 278, 276, 16, 9, crate.color, true)
	local buy = button(card, "Deploy package", 20, 305, 276, 38, function()
		act("buyPackage", crate.key)
	end, true)
	table.insert(updateCallbacks, function(s)
		local price, reason = shopService.quote(Config, s, crate.key)
		local ready = price ~= nil and s.compute >= price
		buy.Text = price and ("Deploy · " .. fmt(price)) or reason
		buy.BackgroundColor3 = ready and C.accent or C.raised
		buy.TextColor3 = ready and C.ink or C.muted
		shopBalance.Text = fmt(s.compute) .. " compute"
	end)
end
local events = pages.events
label(events, "News & codes.", 0, 2, 950, 43, 32, C.text, true)
label(events, "Redeem rewards, follow new drops, and keep your cloud moving.", 0, 53, 940, 23, 13, C.muted, false)
local codePanel = panel(events, "CodePanel", 0, 104, 476, 230, Color3.fromRGB(30, 39, 47))
local codeIcon = label(codePanel, "", 22, 20, 24, 24, 12, C.accent, true)
Icons.attach(codeIcon, "codes")
label(codePanel, "Redeem a code", 60, 18, 360, 25, 19, C.text, true)
label(codePanel, "Enter a launch code for a one-time compute drop.", 22, 56, 420, 20, 12, C.muted, false)
local codeInput = make("TextBox", codePanel, {
	Name = "CodeInput",
	Position = UDim2.fromOffset(22, 98),
	Size = UDim2.fromOffset(270, 44),
	BackgroundColor3 = C.raised,
	BorderSizePixel = 0,
	ClearTextOnFocus = false,
	PlaceholderText = "CLOUDSTART",
	PlaceholderColor3 = C.faint,
	Text = "",
	TextColor3 = C.text,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4
})
round(codeInput, 10)
make("UIPadding", codeInput, { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) })
local redeem = button(codePanel, "Redeem", 306, 98, 148, 44, function()
	if codeInput.Text ~= "" then
		act("code", string.sub(codeInput.Text, 1, 32))
	end
end, true)
label(codePanel, "Codes are permanently recorded to your profile.", 22, 171, 420, 18, 10, C.faint, false)

local changelog = panel(events, "Changelog", 500, 104, 484, 430, Color3.fromRGB(30, 39, 47))
local changeIcon = label(changelog, "", 22, 20, 24, 24, 12, C.accent, true)
Icons.attach(changeIcon, "changelog")
label(changelog, "What's new", 60, 18, 360, 25, 19, C.text, true)
label(changelog, Config.Changelog.version .. "  ·  " .. Config.Changelog.date, 22, 57, 420, 18, 11, C.accent, true)
for i, entry in ipairs(Config.Changelog.entries) do
	label(changelog, string.format("%02d", i), 22, 86 + (i - 1) * 42, 24, 20, 10, C.faint, true)
	label(changelog, entry, 58, 86 + (i - 1) * 42, 390, 34, 11, C.muted, false)
end
local support = panel(events, "SupportCloud", 0, 560, 984, 118, Color3.fromRGB(39, 49, 59))
local supportIcon = label(support, "", 22, 22, 24, 24, 12, C.accent, true)
Icons.attach(supportIcon, "rewards")
label(support, "Support the cloud", 60, 18, 340, 25, 19, C.text, true)
label(support, "Optional support keeps new frontiers, music, and events shipping.", 60, 49, 500, 20, 12, C.muted, false)
local starterProduct = button(support, "Starter compute", 600, 22, 160, 40, function()
	local product = Config.Products.ComputeStarter
	if product and product.id > 0 then
		MarketplaceService:PromptProductPurchase(player, product.id)
	else
		notify("Starter compute is not configured yet.", false)
	end
end, false)
local vaultProduct = button(support, "Compute vault", 778, 22, 160, 40, function()
	local product = Config.Products.ComputeVault
	if product and product.id > 0 then
		MarketplaceService:PromptProductPurchase(player, product.id)
	else
		notify("Compute vault is not configured yet.", false)
	end
end, true)
local founderPass = button(support, "Founder pass", 600, 68, 160, 32, function()
	local passId = Config.Gamepasses.Founder
	if passId > 0 then
		MarketplaceService:PromptGamePassPurchase(player, passId)
	else
		notify("Founder pass is not configured yet.", false)
	end
end, false)
local productionPass = button(support, "2× production", 778, 68, 160, 32, function()
	local passId = Config.Gamepasses.DoubleProduction
	if passId > 0 then
		MarketplaceService:PromptGamePassPurchase(player, passId)
	else
		notify("Production pass is not configured yet.", false)
	end
end, false)
local settings = pages.settings
label(settings, "Make yourself at home.", 0, 2, 950, 43, 32, C.text, true)
label(settings, "A few thoughtful controls for your workspace.", 0, 53, 940, 23, 13, C.muted, false)
refreshSettings = require(package:WaitForChild("Settings")).build(settings, {
	make = make,
	label = label,
	panel = panel,
	tween = tween,
	button = button,
	colors = C,
	preferences = prefs,
	change = changePreference,
	play = play,
	nextTrack = nextTrack,
	trackName = function()
		return "NOW PLAYING  /  " .. playlist[trackIndex].name .. " · APM Music"
	end,
})
local help = panel(settings, "HowToPlay", 0, 1240, 984, 170)
label(help, "From one rack to an empire.", 24, 22, 920, 25, 19, C.text, true)
label(help, "01   Run jobs to earn your first compute.", 24, 61, 900, 22, 13, C.muted, false)
label(help, "02   Deploy servers for automatic production. Research makes them more efficient.", 24, 92, 900, 22, 13, C.muted, false)
label(help, "03   Complete contracts, collect rewards, and unlock larger infrastructure.", 24, 123, 900, 22, 13, C.muted, false)
local boost = panel(home, "Overclock", 0, 747, 984, 120, Color3.fromRGB(38, 43, 58))
local boostIcon = label(boost, "", 24, 18, 26, 26, 21, C.accent, true)
Icons.attach(boostIcon, "operations")
label(boost, "Overclock your cloud", 62, 20, 620, 26, 21, C.text, true)
local boostInfo = label(boost, "Double production for 30 seconds. Recharge between activations.", 24, 57, 670, 22, 12, C.muted, false)
local boostButton = button(boost, "Activate ×2", 795, 38, 165, 42, function()
	act("boost")
end, true)
table.insert(updateCallbacks, function(s)
	local now = workspace:GetServerTimeNow()
	local remaining = math.max(0, math.ceil((s.boostUntil or 0) - now))
	local waitTime = math.max(0, math.ceil((s.boostReady or 0) - now))
	boostButton.Text = remaining > 0 and (remaining .. "s active") or waitTime > 0 and (waitTime .. "s recharge") or "Activate ×2"
	boostButton.BackgroundColor3 = waitTime > 0 and C.raised or C.accent
	boostButton.TextColor3 = waitTime > 0 and C.muted or C.ink
	boostInfo.Text = remaining > 0 and "Your entire fleet is producing at double speed." or "Double production for " .. (30 + (s.research.overclock or 0) * 5 + (s.research.redundancy or 0) * 3) .. " seconds. Recharge between activations."
end)
local layoutRecords = {}
for _, o in ipairs(canvas:GetDescendants()) do
	if o:IsA("GuiObject") then
		layoutRecords[o] = {
			position = o.Position,
			size = o.Size,
			visible = o.Visible
		}
	end
end
local function mapChildren(parent, factor)
	for _, o in ipairs(parent:GetChildren()) do
		local record = layoutRecords[o]
		if record and o.Name ~= "Shadow" and not o:GetAttribute("NativeControl") then
			local p, s = record.position, record.size
			local fixed = s.X.Scale == 0 and s.X.Offset <= 50 and s.Y.Offset >= s.X.Offset * 0.6 and o.Name ~= "Surface"
			o.Position = UDim2.new(p.X.Scale, math.round(p.X.Offset * factor), p.Y.Scale, p.Y.Offset)
			o.Size = UDim2.new(s.X.Scale, math.round(s.X.Offset * (fixed and 1 or factor)), s.Y.Scale, s.Y.Offset)
			mapChildren(o, fixed and 1 or factor)
		end
	end
end
local function fit()
	local width, height = math.round(backdrop.AbsoluteSize.X), math.round(backdrop.AbsoluteSize.Y)
	if width < 1 or height < 1 then
		return
	end
	local compact = width < 1000
	local rail = compact and 76 or 200
	local gutter = width < 600 and 16 or 28
	local content = math.max(240, width - rail - gutter * 2)
	side.Size = UDim2.new(0, rail, 1, 0)
	main.Position = UDim2.fromOffset(rail + gutter, 0)
	main.Size = UDim2.new(1, - rail - gutter * 2, 1, 0)
	mapChildren(main, content / 984)
	for _, page in pairs(pages) do
		page.Position = UDim2.fromOffset(- 14, 79)
		page.Size = UDim2.new(1, 28, 1, - 95)
	end
	for _, o in ipairs(side:GetChildren()) do
		local record = layoutRecords[o]
		if record and o ~= logo and o ~= avatar and not string.match(o.Name, "^Nav_") then
			if o:IsA("TextLabel") or o.Name == "Guide" then
				o.Visible = not compact
			end
			if record.position.Y.Offset >= 650 then
				o.Position = UDim2.new(record.position.X.Scale, record.position.X.Offset, 1, record.position.Y.Offset - 780)
			end
		end
	end
	logo.Position = UDim2.fromOffset(compact and 23 or 26, 34)
	avatar.Position = UDim2.new(0, compact and 21 or 25, 1, - 64)
	side.Guide.Visible = not compact and height >= 730
	local navGap = side.AbsoluteSize.Y < 700 and 46 or 52
	for index, definition in ipairs(definitions) do
		local nav = navButtons[definition[1]]
		nav.button.Position = UDim2.fromOffset(compact and 10 or 16, 164 + (index - 1) * navGap)
		nav.button.Size = UDim2.fromOffset(compact and 56 or 168, 44)
		nav.text.Visible = not compact
		nav.icon.Position = UDim2.fromOffset(compact and 15 or 13, 0)
	end
	local pref = preferencesButton
	if pref then
		pref.Size = UDim2.fromOffset(compact and 56 or 168, 38)
		pref.Position = UDim2.new(0, compact and 10 or 16, 1, - 114)
		preferencesTitle.Visible = not compact
		preferencesIcon.Position = UDim2.fromOffset(compact and 15 or 13, 0)
		pref.Visible = height >= 500
	end
	avatar.Visible = height >= 420
	avatarName.Visible = not compact and height >= 500
	avatarRole.Visible = not compact and height >= 500
	status.Position = UDim2.new(1, - 124, 0, 28)
	status.Size = UDim2.fromOffset(124, 28)
	saveLabel.Position = UDim2.new(1, - 520, 0, 28)
	saveLabel.Size = UDim2.fromOffset(155, 28)
	saveLabel.Visible = content > 590
	fpsLabel.Position = UDim2.new(1, - 355, 0, 28)
	fpsLabel.Size = UDim2.fromOffset(78, 28)
	fpsLabel.Visible = content > 620
	pingLabel.Position = UDim2.new(1, - 265, 0, 28)
	pingLabel.Size = UDim2.fromOffset(90, 28)
	pingLabel.Visible = content > 620
	crumb.Position = UDim2.fromOffset(108, 26)
	crumb.Visible = content > 370
	local single = content < 780
	if single then
		local tierKeys, researchKeys = {}, {}
		for _, item in ipairs(Config.Tiers) do
			table.insert(tierKeys, "Tier_" .. item.key)
		end
		for _, item in ipairs(Config.Research) do
			table.insert(researchKeys, "Research_" .. item.key)
		end
		for pageName, keys in pairs({
			infrastructure = tierKeys,
			research = researchKeys
		}) do
			for i, name in ipairs(keys) do
				local wrap = pages[pageName]:FindFirstChild(name)
				local record = layoutRecords[wrap]
				local gap = pageName == "research" and 302 or 235
				wrap.Position = UDim2.fromOffset(0, 104 + (i - 1) * gap)
				wrap.Size = UDim2.fromOffset(content, record.size.Y.Offset)
				mapChildren(wrap, content / record.size.X.Offset)
			end
		end
		research.ResearchGuide.Position = UDim2.fromOffset(0, 104 + # Config.Research * 302)
		for i = 1, 3 do
			local wrap = home["Stat" .. i]
			wrap.Position = UDim2.fromOffset(0, 300 + (i - 1) * 112)
			wrap.Size = UDim2.fromOffset(content, 98)
			mapChildren(wrap, content / 316)
		end
		for _, o in ipairs(home:GetChildren()) do
			local r = layoutRecords[o]
			if r and not o:FindFirstChild("Surface") and r.position.Y.Offset >= 420 then
				o.Position = UDim2.new(o.Position.X.Scale, o.Position.X.Offset, 0, r.position.Y.Offset + 238)
			end
		end
		for i, name in ipairs({
			"Tier_rack",
			"Tier_node"
		}) do
			local wrap = home[name]
			wrap.Position = UDim2.fromOffset(0, 727 + (i - 1) * 168)
			wrap.Size = UDim2.fromOffset(content, 148)
			mapChildren(wrap, content / 483)
		end
		home.NextContract.Position = UDim2.fromOffset(0, 1063)
		home.Overclock.Position = UDim2.fromOffset(0, 1153)
	end
	local smallHero = main.AbsoluteSize.X < 760
	hero.CloudRoom.Visible = not smallHero
	hero.CloudRoom:SetAttribute("LayoutVisible", not smallHero)
	orbitHint.Visible = not smallHero
	for _, o in ipairs(hero:GetChildren()) do
		local r = layoutRecords[o]
		if r and o:IsA("TextLabel") and o ~= orbitHint then
			if smallHero then
				o.Position = UDim2.fromOffset(24, r.position.Y.Offset)
				o.Size = UDim2.fromOffset(content - 48, r.size.Y.Offset)
				o.Visible = r.position.Y.Offset ~= 208
				if r.position.Y.Offset == 75 then
					o.TextSize = content < 460 and 24 or 34
				end
			else
				o.Visible = true
				if r.position.Y.Offset == 75 then
					o.TextSize = 34
				end
			end
		end
	end
	toast.Size = UDim2.fromOffset(math.min(450, width - 32), 44)
	for _, m in ipairs(magneticButtons) do
		m.basePosition = m.button.Position
		m.offset = Vector2.zero
		m.spring:Reset(Vector2.zero)
	end
end
backdrop:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local transitionVersion = 0
local selectedPage = nil
local PageController = {}
PageController.__index = PageController
function PageController.new()
	return setmetatable({
		current = nil
	}, PageController)
end
function PageController:Select(key)
	self.current = key
end
local pageController = PageController.new()
switchPage = function(key)
	if selectedPage == key then
		return
	end
	local previousIndex = pageOrder[selectedPage] or pageOrder[key] or 1
	local nextIndex = pageOrder[key] or previousIndex
	local direction = nextIndex >= previousIndex and 1 or - 1
	pageController:Select(key)
	if selectedPage then
		play("switch")
	end
	selectedPage = key
	transitionVersion += 1
	local version = transitionVersion
	for name, page in pairs(pages) do
		page.Visible = name == key
	end
	crumb.Text = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
	for name, nav in pairs(navButtons) do
		local active = name == key
		nav.button.BackgroundColor3 = active and Color3.fromRGB(38, 67, 58) or C.side
		nav.button.BackgroundTransparency = active and 0 or 1
		nav.text.TextColor3 = active and C.accent or C.muted
		nav.icon.TextColor3 = nav.text.TextColor3
	end
	local page = pages[key]
	local scale = page:FindFirstChild("MotionScale")
	page.Position = UDim2.fromOffset(- 14 + direction * 28, 79)
	if scale then
		scale.Scale = 0.985
	end
	if motion then
		local pageInfo = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		Tween:Create(page, pageInfo, {
			Position = UDim2.fromOffset(- 14, 79)
		}):Play()
		if scale then
			Tween:Create(scale, pageInfo, {
				Scale = 1
			}):Play()
		end
	else
		page.Position = UDim2.fromOffset(- 14, 79)
		if scale then
			scale.Scale = 1
		end
	end
	local headings = {}
	for _, child in ipairs(page:GetChildren()) do
		if child:IsA("TextLabel") and child.Position.Y.Offset < 80 then
			table.insert(headings, child)
			child.TextTransparency = 1
			tween(child, {
				TextTransparency = 0
			}, 0.3)
		end
	end
	local ordered = {}
	for _, wrap in ipairs(page:GetChildren()) do
		if wrap:FindFirstChild("Surface") then
			table.insert(ordered, wrap)
		end
	end
	table.sort(ordered, function(a, b)
		return a.Position.Y.Offset < b.Position.Y.Offset
	end)
	for i, wrap in ipairs(ordered) do
		local surface = wrap.Surface
		local shadow = wrap:FindFirstChild("Shadow")
		surface.BackgroundTransparency = motion and 0.32 or 0.02
		if shadow then
			shadow.ImageTransparency = 1
		end
		task.delay(motion and math.min(i - 1, 5) * 0.035 or 0, function()
			if version ~= transitionVersion then
				return
			end
				tween(surface, {
					BackgroundTransparency = 0.02
				}, 0.34)
				if shadow then
					tween(shadow, {
						ImageTransparency = 0.88
				}, 0.3)
			end
		end)
	end
end
switchPage("overview")
Changed.OnClientEvent:Connect(apply)
task.spawn(function()
	for attempt = 1, 3 do
		local ok, s = pcall(function()
			return GetState:InvokeServer()
		end)
		if ok and s then
			apply(s)
			return
		end
		task.wait(1)
	end
	notify("Unable to connect. Rejoin to retry.", false)
end)
print("[DECK] Cloud Empire interface ready")
return true
