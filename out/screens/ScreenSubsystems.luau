-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenSubsystems.tsx — Module / subsystem upgrade grid
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local Font = _theme.Font
local Size = _theme.Size
local Button = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Button").Button
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local _store = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store")
local act = _store.act
local fmt = _store.fmt
-- ---------------------------------------------------------------------------
-- Data
-- ---------------------------------------------------------------------------
local PLACEHOLDER_MODULES = { {
	id = "overclock",
	name = "Overclocking Suite",
	description = "Push hardware beyond rated limits.",
	effectLabel = "+15% compute rate per level",
	baseCost = 500,
	maxLevel = 10,
	unlocksAt = 0,
}, {
	id = "cooling",
	name = "Cryo Cooling",
	description = "Advanced liquid nitrogen cooling loops.",
	effectLabel = "+8% energy efficiency per level",
	baseCost = 750,
	maxLevel = 10,
	unlocksAt = 0,
}, {
	id = "redundancy",
	name = "Redundancy Array",
	description = "Fault-tolerant multi-path data pipelines.",
	effectLabel = "+12% data throughput per level",
	baseCost = 1200,
	maxLevel = 8,
	unlocksAt = 1,
}, {
	id = "ai_scheduler",
	name = "AI Scheduler",
	description = "Neural job orchestration reduces idle cycles.",
	effectLabel = "+20% job XP per level",
	baseCost = 2500,
	maxLevel = 6,
	unlocksAt = 2,
}, {
	id = "quantum_cache",
	name = "Quantum Cache",
	description = "Quantum-coherent L4 cache for ultra-low latency.",
	effectLabel = "+25% tick speed per level",
	baseCost = 8000,
	maxLevel = 5,
	unlocksAt = 3,
}, {
	id = "singularity_core",
	name = "Singularity Core",
	description = "Experimental self-optimising compute fabric.",
	effectLabel = "+40% all resources per level",
	baseCost = 50000,
	maxLevel = 3,
	unlocksAt = 5,
} }
-- Try to pull from Config; fall back to placeholders
local function getModules()
	local _exitType, _returns = TS.try(function()
		local cfg = (require(game:GetService("ReplicatedStorage"):WaitForChild("DeckGame"):WaitForChild("Config")))
		if cfg.Subsystems and #cfg.Subsystems > 0 then
			return TS.TRY_RETURN, { cfg.Subsystems }
		end
	end, function(_) end)
	if _exitType then
		return unpack(_returns)
	end
	return PLACEHOLDER_MODULES
end
local MODULES = getModules()
-- ---------------------------------------------------------------------------
-- Sub-component: ModuleCard
-- ---------------------------------------------------------------------------
local function ModuleCard(_param)
	local mod = _param.mod
	local level = _param.level
	local prestigeTokens = _param.prestigeTokens
	local compute = _param.compute
	local layoutOrder = _param.layoutOrder
	local locked = prestigeTokens < mod.unlocksAt
	local maxed = level >= mod.maxLevel
	local cost = math.floor(mod.baseCost * math.pow(1.65, level))
	local canAfford = compute >= cost
	local cardBg = if locked then Color3.fromRGB(18, 19, 24) else C.card
	local alpha = if locked then 0.55 else 0
	return React.createElement("frame", {
		key = mod.id,
		BackgroundColor3 = cardBg,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 148),
		LayoutOrder = layoutOrder,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.card),
	}), React.createElement("uistroke", {
		Color = if locked then C.hairlineSub else C.hairline,
		Thickness = 1,
		Transparency = if locked then 0.5 else 0.72,
	}), locked and (React.createElement("frame", {
		key = "LockOverlay",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 6,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.card),
	}), React.createElement("textlabel", {
		Text = "🔒  LOCKED",
		Font = Font.bold,
		TextSize = Size.body,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 7,
	}))), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	}), React.createElement("frame", {
		key = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0, 16, 0, 14),
		ZIndex = 3,
	}, React.createElement("textlabel", {
		key = "Name",
		Text = mod.name,
		Font = Font.bold,
		TextSize = Size.section,
		TextColor3 = if locked then C.textMuted else C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
	}), React.createElement("frame", {
		key = "LvlBadge",
		BackgroundColor3 = if maxed then Color3.fromRGB(36, 18, 56) else Color3.fromRGB(18, 30, 48),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 68, 0, 22),
		Position = UDim2.new(1, -68, 0, 2),
		ZIndex = 3,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.badge),
	}), React.createElement("uistroke", {
		Color = if maxed then C.reputation else C.accent,
		Thickness = 1,
		Transparency = 0.45,
	}), React.createElement("textlabel", {
		Text = if maxed then "MAX" else `LVL {tostring(level)}`,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = if maxed then C.reputation else C.accent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4,
	}))), React.createElement("textlabel", {
		key = "Desc",
		Text = mod.description,
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = if locked then C.textMuted else C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 18),
		Position = UDim2.new(0, 16, 0, 46),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 3,
	}), React.createElement("frame", {
		key = "Effect",
		BackgroundColor3 = Color3.fromRGB(14, 28, 20),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -32, 0, 20),
		Position = UDim2.new(0, 16, 0, 70),
		ZIndex = 3,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.micro),
	}), React.createElement("uistroke", {
		Color = C.compute,
		Thickness = 1,
		Transparency = 0.65,
	}), React.createElement("textlabel", {
		Text = mod.effectLabel,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.compute,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	})), React.createElement("frame", {
		key = "Footer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 36),
		Position = UDim2.new(0, 16, 0, 98),
		ZIndex = 3,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}), React.createElement("frame", {
		key = "CostChip",
		BackgroundColor3 = Color3.fromRGB(16, 28, 20),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 100, 0, 28),
		LayoutOrder = 1,
		ZIndex = 3,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	}), React.createElement("uistroke", {
		Color = if canAfford and not locked then C.compute else C.textMuted,
		Thickness = 1,
		Transparency = 0.5,
	}), React.createElement("textlabel", {
		Text = if maxed then "MAXED" else `⚡ {fmt(cost)}`,
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = if canAfford and not locked and not maxed then C.compute else C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4,
	})), React.createElement("frame", {
		key = "BtnWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -110, 0, 36),
		LayoutOrder = 2,
		ZIndex = 3,
	}, React.createElement(Button, {
		label = if maxed then "MAXED" elseif locked then "LOCKED" else "Upgrade",
		onClick = function()
			if locked or maxed or not canAfford then
				return nil
			end
			act("upgradeSubsystem", {
				id = mod.id,
			})
		end,
		variant = if maxed then "secondary" elseif locked then "secondary" elseif canAfford then "success" else "secondary",
		height = 34,
		disabled = locked or maxed or not canAfford,
	}))))
end
-- ---------------------------------------------------------------------------
-- Screen
-- ---------------------------------------------------------------------------
local function ScreenSubsystems()
	local state = useGameState()
	local research = state.research or {}
	local _exp = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})
	local _exp_1 = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 24),
	})
	local _exp_2 = React.createElement("frame", {
		key = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 48),
		LayoutOrder = 0,
	}, React.createElement("textlabel", {
		Text = "SUBSYSTEMS",
		Font = Font.bold,
		TextSize = Size.hero,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("textlabel", {
		Text = "Upgrade infrastructure modules to amplify all resource generation.",
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
	}))
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#MODULES)
	local _callback = function(mod, i)
		local _id = mod.id
		local _condition = (research[_id])
		if _condition == nil then
			_condition = 0
		end
		local level = _condition
		return React.createElement(ModuleCard, {
			key = mod.id,
			mod = mod,
			level = level,
			prestigeTokens = state.prestigeTokens,
			compute = state.compute,
			layoutOrder = i + 1,
		})
	end
	for _k, _v in MODULES do
		_newValue[_k] = _callback(_v, _k - 1, MODULES)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("scrollingframe", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.accent,
		ScrollBarImageTransparency = 0.5,
	}, _exp, _exp_1, _exp_2, _newValue)
end
return {
	default = ScreenSubsystems,
}
