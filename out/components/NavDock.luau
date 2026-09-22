-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- components/NavDock.tsx — Vertical sidebar (desktop) / bottom tab bar (mobile)
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local Font = _theme.Font
local NAV_ITEMS = { {
	id = "overview",
	label = "Overview",
	icon = "rbxassetid://7733765045",
}, {
	id = "operations",
	label = "Ops",
	icon = "rbxassetid://7733765045",
}, {
	id = "infrastructure",
	label = "Infra",
	icon = "rbxassetid://7733765045",
}, {
	id = "research",
	label = "Research",
	icon = "rbxassetid://7733765045",
}, {
	id = "modules",
	label = "Modules",
	icon = "rbxassetid://7733765045",
}, {
	id = "contracts",
	label = "Contracts",
	icon = "rbxassetid://7733765045",
}, {
	id = "rewards",
	label = "Rewards",
	icon = "rbxassetid://7733765045",
}, {
	id = "shop",
	label = "Shop",
	icon = "rbxassetid://7733765045",
}, {
	id = "prestige",
	label = "Prestige",
	icon = "rbxassetid://7733765045",
}, {
	id = "events",
	label = "Events",
	icon = "rbxassetid://7733765045",
}, {
	id = "leaderboard",
	label = "Leaders",
	icon = "rbxassetid://7733765045",
}, {
	id = "settings",
	label = "Settings",
	icon = "rbxassetid://7733765045",
} }
local TWEEN_FAST = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
-- Individual nav button with hover/active states
local function NavButton(_param)
	local item = _param.item
	local isActive = _param.isActive
	local isDesktop = _param.isDesktop
	local onNavigate = _param.onNavigate
	local pillRef = React.createRef()
	local btnRef = React.createRef()
	local tween = function(obj, props)
		game:GetService("TweenService"):Create(obj, TWEEN_FAST, props):Play()
	end
	-- Animate pill in when active
	React.useEffect(function()
		local pill = pillRef.current
		if not pill then
			return nil
		end
		tween(pill, {
			BackgroundTransparency = if isActive then 0 else 1,
			Size = if isActive then (if isDesktop then UDim2.new(0, 46, 0, 32) else UDim2.new(0, 52, 0, 28)) else (if isDesktop then UDim2.new(0, 0, 0, 32) else UDim2.new(0, 0, 0, 28)),
		})
	end, { isActive })
	return React.createElement("textbutton", {
		ref = btnRef,
		key = item.id,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = if isDesktop then UDim2.new(1, 0, 0, 56) else UDim2.new(0, 58, 1, 0),
		ZIndex = 11,
		Event = {
			Activated = function()
				return onNavigate(item.id)
			end,
			MouseEnter = function()
				if isActive then
					return nil
				end
				local btn = btnRef.current
				if btn then
					tween(btn, {
						BackgroundTransparency = 0.95,
					})
				end
			end,
			MouseLeave = function()
				if isActive then
					return nil
				end
				local btn = btnRef.current
				if btn then
					tween(btn, {
						BackgroundTransparency = 1,
					})
				end
			end,
		},
	}, React.createElement("frame", {
		ref = pillRef,
		key = "ActivePill",
		BackgroundColor3 = Color3.fromRGB(59, 130, 246),
		BackgroundTransparency = if isActive then 0 else 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = if isDesktop then (if isActive then UDim2.new(0, 46, 0, 32) else UDim2.new(0, 0, 0, 32)) else (if isActive then UDim2.new(0, 52, 0, 28) else UDim2.new(0, 0, 0, 28)),
		ZIndex = 10,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("uistroke", {
		Color = Color3.fromRGB(96, 165, 250),
		Thickness = 1,
		Transparency = if isActive then 0.45 else 1,
	}), React.createElement("frame", {
		key = "Glow",
		BackgroundColor3 = Color3.fromRGB(59, 130, 246),
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 12, 1, 12),
		ZIndex = 9,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}))), React.createElement("frame", {
		key = "Content",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 40, 0, 40),
		ZIndex = 12,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
	}), React.createElement("imagelabel", {
		key = "Icon",
		Image = item.icon,
		ImageColor3 = if isActive then Color3.fromRGB(255, 255, 255) else C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 22, 0, 22),
		ScaleType = Enum.ScaleType.Fit,
	}), React.createElement("textlabel", {
		key = "Label",
		Text = item.label,
		Font = Font.mono,
		TextSize = 9,
		TextColor3 = if isActive then C.textPrimary else C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 52, 0, 11),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = false,
	})))
end
local function NavDock(_param)
	local activeScreen = _param.activeScreen
	local onNavigate = _param.onNavigate
	-- Simple heuristic: if viewport width >= 640 → desktop sidebar, else bottom bar
	local _result = game:GetService("Workspace").CurrentCamera
	if _result ~= nil then
		_result = _result.ViewportSize
	end
	local _condition = _result
	if _condition == nil then
		_condition = Vector2.new(800, 600)
	end
	local vp = _condition
	local isDesktop = vp.X >= 640
	local _exp = React.createElement("frame", {
		key = "Hairline",
		BackgroundColor3 = C.hairline,
		BorderSizePixel = 0,
		Size = if isDesktop then UDim2.new(0, 1, 1, 0) else UDim2.new(1, 0, 0, 1),
		Position = if isDesktop then UDim2.new(1, -1, 0, 0) else UDim2.new(0, 0, 0, 0),
		ZIndex = 16,
	})
	local _exp_1 = React.createElement("uilistlayout", {
		FillDirection = if isDesktop then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 0),
	})
	local _exp_2 = React.createElement("uipadding", {
		PaddingTop = if isDesktop then UDim.new(0, 8) else UDim.new(0, 0),
		PaddingBottom = if isDesktop then UDim.new(0, 8) else UDim.new(0, 0),
	})
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#NAV_ITEMS)
	local _callback = function(item)
		return React.createElement(NavButton, {
			key = item.id,
			item = item,
			isActive = activeScreen == item.id,
			isDesktop = isDesktop,
			onNavigate = onNavigate,
		})
	end
	for _k, _v in NAV_ITEMS do
		_newValue[_k] = _callback(_v, _k - 1, NAV_ITEMS)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("frame", {
		key = "NavDock",
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		Size = if isDesktop then UDim2.new(0, 72, 1, -56) else UDim2.new(1, 0, 0, 64),
		Position = if isDesktop then UDim2.new(0, 0, 0, 56) else UDim2.new(0, 0, 1, -64),
		ZIndex = 15,
	}, _exp, React.createElement("scrollingframe", {
		key = "NavList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = if isDesktop then UDim2.new(0, 0, 0, #NAV_ITEMS * 56) else UDim2.new(0, #NAV_ITEMS * 58, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ScrollingDirection = if isDesktop then Enum.ScrollingDirection.Y else Enum.ScrollingDirection.X,
		ZIndex = 16,
	}, _exp_1, _exp_2, _newValue))
end
return {
	default = NavDock,
}
