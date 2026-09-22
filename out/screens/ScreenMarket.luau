-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenMarket.tsx — Supply Procurement & Boost Market
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local Font = _theme.Font
local Size = _theme.Size
local Card = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Card").Card
local Button = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Button").Button
local Badge = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Badge").Badge
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local _store = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store")
local act = _store.act
local fmt = _store.fmt
local MARKET_ITEMS = { {
	id = "overclock_boost",
	title = "Cryo-Overclock Injection",
	subtitle = "Supercharges server clocks by +100% for 120 seconds.",
	costCompute = 15000,
	icon = "operations",
	action = "boost",
}, {
	id = "energy_cell",
	title = "High-Density Energy Cell",
	subtitle = "Instantly recharges total fleet capacitor bank to full.",
	costCompute = 5000,
	icon = "energy",
	action = "recharge",
}, {
	id = "data_dump",
	title = "Archive Decryption Key",
	subtitle = "Extracts +5,000 raw telemetry packets into permanent storage.",
	costCompute = 25000,
	icon = "data",
	action = "buyData",
}, {
	id = "quantum_accelerator",
	title = "Temporal Accelerator",
	subtitle = "Advances all background mission completion clocks by 1 hour.",
	costData = 2000,
	icon = "research",
	action = "skipHour",
}, {
	id = "vip_infrastructure",
	title = "Autonomous Core AI",
	subtitle = "Generates background compute cycles even while inactive.",
	isPremium = true,
	icon = "infrastructure",
	action = "buyVip",
}, {
	id = "prestige_beacon",
	title = "Tachyon Harmonic Beacon",
	subtitle = "Permanently adds +0.50× to future Singularity prestige resets.",
	isPremium = true,
	icon = "rewards",
	action = "buyBeacon",
} }
local function ScreenMarket()
	local gs = useGameState()
	local _exp = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 24),
		PaddingRight = UDim.new(0, 24),
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 40),
	})
	local _exp_1 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local _exp_2 = React.createElement(Card, {
		height = 100,
		layoutOrder = 1,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	}), React.createElement("frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
	}), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
	}, React.createElement("textlabel", {
		Text = "SUPPLY & PROCUREMENT DEPOT",
		Font = Font.bold,
		TextSize = Size.title,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Badge, {
		label = "MARKETPLACE",
		style = "energy",
		pill = true,
	})), React.createElement("textlabel", {
		Text = "Procure hardware bursts, thermal accelerators, and quantum expansion assets.",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
	})))
	local _exp_3 = React.createElement("uigridlayout", {
		CellSize = UDim2.new(0.485, 0, 0, 180),
		CellPadding = UDim2.new(0.03, 0, 0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#MARKET_ITEMS)
	local _callback = function(item, idx)
		local canBuy = true
		local costDisplay = "FREE"
		local _value = item.costCompute
		if _value ~= 0 and _value == _value and _value then
			canBuy = gs.compute >= item.costCompute
			costDisplay = `{fmt(item.costCompute)} ⚡`
		else
			local _value_1 = item.costData
			if _value_1 ~= 0 and _value_1 == _value_1 and _value_1 then
				canBuy = gs.data >= item.costData
				costDisplay = `{fmt(item.costData)} 💾`
			elseif item.isPremium then
				costDisplay = "ROBUX"
			end
		end
		return React.createElement(Card, {
			key = item.id,
			height = 180,
			layoutOrder = idx,
		}, React.createElement("uipadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 14),
			PaddingBottom = UDim.new(0, 14),
		}), React.createElement("frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, React.createElement("uilistlayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 6),
		}), React.createElement("frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
		}, React.createElement("textlabel", {
			Text = item.title,
			Font = Font.bold,
			TextSize = Size.section,
			TextColor3 = C.textPrimary,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.65, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}), React.createElement(Badge, {
			label = if item.isPremium then "PREMIUM" else "DEPOT",
			style = if item.isPremium then "reputation" else "accent",
			pill = true,
		})), React.createElement("textlabel", {
			Text = item.subtitle,
			Font = Font.body,
			TextSize = Size.caption,
			TextColor3 = C.textSecondary,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 48),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}), React.createElement("frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
		}, React.createElement("uilistlayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		}), React.createElement("textlabel", {
			Text = costDisplay,
			Font = Font.mono,
			TextSize = Size.body,
			TextColor3 = if item.isPremium then C.reputation else (if canBuy then C.compute else C.textMuted),
			BackgroundTransparency = 1,
			Size = UDim2.new(0.5, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		}), React.createElement(Button, {
			label = if item.isPremium then "Get" else "Purchase",
			variant = if item.isPremium then "amber" else (if canBuy then "primary" else "secondary"),
			width = 100,
			height = 34,
			disabled = not canBuy and not item.isPremium,
			onClick = function()
				return act("shopBuy", {
					item = item.id,
				})
			end,
		}))))
	end
	for _k, _v in MARKET_ITEMS do
		_newValue[_k] = _callback(_v, _k - 1, MARKET_ITEMS)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("scrollingframe", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.hairline,
		CanvasSize = UDim2.new(0, 0, 0, 850),
	}, _exp, _exp_1, _exp_2, React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 680),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	}, _exp_3, _newValue))
end
return {
	default = ScreenMarket,
}
