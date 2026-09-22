-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- components/TopBar.tsx — Full-width HUD bar for Deck Cloud Empire
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local RunService = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services").RunService
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local Font = _theme.Font
local Size = _theme.Size
local ProgressBar = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "ProgressBar").ProgressBar
local fmt = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store").fmt
-- Thin hairline pill wrapper — recessed well with pill corners
local function Pill(_param)
	local children = _param.children
	local width = _param.width
	return React.createElement("frame", {
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = if width ~= 0 and width == width and width then UDim2.new(0, width, 1, -16) else UDim2.new(0, 0, 1, -16),
		AutomaticSize = if width ~= 0 and width == width and width then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("uistroke", {
		Color = C.hairline,
		Thickness = 1,
		Transparency = 0.45,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
	}), children)
end
local function TopBar(_param)
	local activeScreen = _param.activeScreen
	local callsign = _param.callsign
	local compute = _param.compute
	local computeRate = _param.computeRate
	local energy = _param.energy
	local energyCap = _param.energyCap
	local data = _param.data
	local onSearchOpen = _param.onSearchOpen
	local fps, setFps = React.useState(60)
	local fpsRef = React.useRef(60)
	local sampleCountRef = React.useRef(0)
	local accumRef = React.useRef(0)
	React.useEffect(function()
		local conn = RunService.Heartbeat:Connect(function(dt)
			accumRef.current += dt
			sampleCountRef.current += 1
			if sampleCountRef.current >= 20 then
				local avg = sampleCountRef.current / accumRef.current
				fpsRef.current = math.round(avg)
				setFps(fpsRef.current)
				sampleCountRef.current = 0
				accumRef.current = 0
			end
		end)
		return function()
			return conn:Disconnect()
		end
	end, {})
	local energyPct = if energyCap > 0 then math.clamp(energy / energyCap, 0, 1) else 0
	-- FPS color: green ≥50, amber 30-49, red <30
	local fpsColor = if fps >= 50 then C.compute elseif fps >= 30 then C.energy else C.danger
	local breadcrumb = `> {string.upper(activeScreen)}`
	return React.createElement("frame", {
		key = "TopBar",
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 20,
	}, React.createElement("frame", {
		key = "BottomHairline",
		BackgroundColor3 = C.hairline,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		ZIndex = 21,
	}), React.createElement("frame", {
		key = "LeftSection",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 240, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		ZIndex = 21,
	}, React.createElement("frame", {
		key = "OperatorPill",
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, -16),
		AutomaticSize = Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		ZIndex = 22,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("uistroke", {
		Color = C.hairline,
		Thickness = 1,
		Transparency = 0.45,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}), React.createElement("imagelabel", {
		key = "Avatar",
		Image = "rbxassetid://7733960981",
		ImageColor3 = C.accent,
		BackgroundColor3 = C.elevated,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 28, 0, 28),
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("uistroke", {
		Color = C.accent,
		Thickness = 1,
		Transparency = 0.55,
	})), React.createElement("frame", {
		key = "TextStack",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 1),
	}), React.createElement("textlabel", {
		key = "Callsign",
		Text = callsign,
		Font = Font.bold,
		TextSize = Size.caption,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 14),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("textlabel", {
		key = "Breadcrumb",
		Text = breadcrumb,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 12),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
	})))), React.createElement("frame", {
		key = "RightSection",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 0),
		ZIndex = 21,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
	}), React.createElement("textbutton", {
		key = "SearchBtn",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 36, 0, 36),
		ZIndex = 22,
		Event = {
			Activated = onSearchOpen,
		},
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	}), React.createElement("uistroke", {
		Color = C.hairline,
		Thickness = 1,
		Transparency = 0.45,
	}), React.createElement("imagelabel", {
		Image = "rbxassetid://7734052925",
		ImageColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ScaleType = Enum.ScaleType.Fit,
	})), React.createElement("frame", {
		key = "FpsPill",
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 58, 1, -16),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		ZIndex = 22,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("uistroke", {
		Color = C.hairline,
		Thickness = 1,
		Transparency = 0.45,
	}), React.createElement("textlabel", {
		key = "FpsLabel",
		Text = "FPS",
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 11),
		Position = UDim2.new(0.5, 0, 0, 5),
		AnchorPoint = Vector2.new(0.5, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
	}), React.createElement("textlabel", {
		key = "FpsValue",
		Text = tostring(fps),
		Font = Font.bold,
		TextSize = Size.caption,
		TextColor3 = fpsColor,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0.5, 0, 1, -6),
		AnchorPoint = Vector2.new(0.5, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
	})), React.createElement("frame", {
		key = "DataPill",
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 80, 1, -16),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		ZIndex = 22,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("uistroke", {
		Color = C.data,
		Thickness = 1,
		Transparency = 0.72,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}), React.createElement("textlabel", {
		key = "Label",
		Text = "DATA",
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.data,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 11),
		Position = UDim2.new(0, 0, 0, 5),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("textlabel", {
		key = "Value",
		Text = fmt(data),
		Font = Font.bold,
		TextSize = Size.caption,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, -6),
		AnchorPoint = Vector2.new(0, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	})), React.createElement("frame", {
		key = "EnergyPill",
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 100, 1, -16),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		ZIndex = 22,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("uistroke", {
		Color = C.energy,
		Thickness = 1,
		Transparency = 0.72,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 5),
	}), React.createElement("textlabel", {
		key = "Label",
		Text = "ENERGY",
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.energy,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 11),
		Position = UDim2.new(0, 0, 0, 5),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("textlabel", {
		key = "Value",
		Text = `{fmt(energy)} / {fmt(energyCap)}`,
		Font = Font.bold,
		TextSize = Size.caption,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 13),
		Position = UDim2.new(0, 0, 0, 19),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("frame", {
		key = "EnergyBarWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 4),
		Position = UDim2.new(0, 0, 1, -9),
	}, React.createElement(ProgressBar, {
		progress = energyPct,
		color = C.energy,
		height = 4,
	}))), React.createElement("frame", {
		key = "ComputePill",
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 110, 1, -16),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		ZIndex = 22,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("uistroke", {
		Color = C.compute,
		Thickness = 1,
		Transparency = 0.72,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}), React.createElement("textlabel", {
		key = "Label",
		Text = "COMPUTE",
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.compute,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 11),
		Position = UDim2.new(0, 0, 0, 5),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("frame", {
		key = "ValueRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, -6),
		AnchorPoint = Vector2.new(0, 1),
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
	}), React.createElement("textlabel", {
		key = "Amount",
		Text = fmt(compute),
		Font = Font.bold,
		TextSize = Size.caption,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("textlabel", {
		key = "Rate",
		Text = `+{fmt(computeRate)}/s`,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.compute,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
	})))))
end
return {
	default = TopBar,
}
