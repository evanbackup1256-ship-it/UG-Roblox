-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- components/NavDock.tsx — Precision obsidian vertical rail (desktop) / bottom tab bar (mobile)
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local Font = _theme.Font
local NAV_ITEMS = { {
	id = "overview",
	label = "Command",
	icon = "rbxassetid://7733960981",
}, {
	id = "operations",
	label = "Ops",
	icon = "rbxassetid://7734051202",
}, {
	id = "infrastructure",
	label = "Hardware",
	icon = "rbxassetid://7734053426",
}, {
	id = "research",
	label = "Research",
	icon = "rbxassetid://7733674922",
}, {
	id = "modules",
	label = "Modules",
	icon = "rbxassetid://7733765045",
}, {
	id = "contracts",
	label = "Contracts",
	icon = "rbxassetid://7733919526",
}, {
	id = "rewards",
	label = "Rewards",
	icon = "rbxassetid://7733946818",
}, {
	id = "shop",
	label = "Depot",
	icon = "rbxassetid://7734056747",
}, {
	id = "prestige",
	label = "Prestige",
	icon = "rbxassetid://7734056556",
}, {
	id = "events",
	label = "Terminal",
	icon = "rbxassetid://7733673987",
}, {
	id = "leaderboard",
	label = "Rankings",
	icon = "rbxassetid://7733946818",
}, {
	id = "settings",
	label = "Settings",
	icon = "rbxassetid://7734058803",
} }
local TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function NavButton(_param)
	local item = _param.item
	local isActive = _param.isActive
	local isDesktop = _param.isDesktop
	local onNavigate = _param.onNavigate
	local hovered, setHovered = React.useState(false)
	local bgColor = if isActive then Color3.fromRGB(24, 34, 52) else (if hovered then Color3.fromRGB(24, 28, 38) else Color3.fromRGB(16, 18, 24))
	local strokeColor = if isActive then C.accent else C.hairline
	local strokeTrans = if isActive then 0.35 else 0.85
	local iconColor = if isActive then C.accent else (if hovered then C.textPrimary else C.textMuted)
	local textColor = if isActive then C.textPrimary else (if hovered then C.textSecondary else C.textMuted)
	return React.createElement("textbutton", {
		key = item.id,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = bgColor,
		BackgroundTransparency = if isActive or hovered then 0 else 1,
		BorderSizePixel = 0,
		Size = if isDesktop then UDim2.new(0, 58, 0, 48) else UDim2.new(0, 56, 1, -12),
		ZIndex = 12,
		Event = {
			Activated = function()
				return onNavigate(item.id)
			end,
			MouseEnter = function()
				return setHovered(true)
			end,
			MouseLeave = function()
				return setHovered(false)
			end,
		},
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	}), React.createElement("uistroke", {
		Color = strokeColor,
		Thickness = 1,
		Transparency = strokeTrans,
	}), isDesktop and isActive and (React.createElement("frame", {
		key = "ActiveBar",
		BackgroundColor3 = C.accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 0, 24),
		Position = UDim2.new(0, -6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 14,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, 2),
	}))), React.createElement("frame", {
		key = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 13,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
	}), React.createElement("imagelabel", {
		key = "Icon",
		Image = item.icon,
		ImageColor3 = iconColor,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 0, 20),
		ScaleType = Enum.ScaleType.Fit,
	}), React.createElement("textlabel", {
		key = "Label",
		Text = item.label,
		Font = if isActive then Font.bold else Font.body,
		TextSize = 10,
		TextColor3 = textColor,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 12),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})))
end
local function NavDock(_param)
	local activeScreen = _param.activeScreen
	local onNavigate = _param.onNavigate
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
		VerticalAlignment = if isDesktop then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
	})
	local _exp_2 = React.createElement("uipadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
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
		Size = if isDesktop then UDim2.new(0, 72, 1, -52) else UDim2.new(1, 0, 0, 58),
		Position = if isDesktop then UDim2.new(0, 0, 0, 52) else UDim2.new(0, 0, 1, -58),
		ZIndex = 15,
	}, _exp, React.createElement("scrollingframe", {
		key = "NavList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = if isDesktop then UDim2.new(0, 0, 0, #NAV_ITEMS * 52 + 16) else UDim2.new(0, #NAV_ITEMS * 60, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ScrollingDirection = if isDesktop then Enum.ScrollingDirection.Y else Enum.ScrollingDirection.X,
		ZIndex = 16,
	}, _exp_1, _exp_2, _newValue))
end
return {
	default = NavDock,
}
