-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenResearch.tsx — Research and Technology Upgrades
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
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("DeckGame"):WaitForChild("Config"))
local DEFAULT_RESEARCH = { {
	key = "parallel_cores",
	name = "Parallel Compute Architecture",
	description = "Expands instruction pipelines, boosting base compute yield by +25%.",
	cost = 500,
	multiplier = 1.25,
}, {
	key = "subzero_cooling",
	name = "Cryogenic Cooling Loop",
	description = "Prevents thermal throttling across all server hardware clusters.",
	cost = 2500,
	multiplier = 1.50,
}, {
	key = "quantum_bus",
	name = "Quantum Interconnect Bus",
	description = "Ultra-low latency data transmission channels between facilities.",
	cost = 12000,
	multiplier = 2.00,
}, {
	key = "neural_cache",
	name = "Neural Predictive Caching",
	description = "Anticipates workload demands with AI-driven branch prediction.",
	cost = 50000,
	multiplier = 2.50,
}, {
	key = "hyper_optical",
	name = "Hyper-Optical Transceivers",
	description = "Replaces copper bus with multi-wavelength laser packet switching.",
	cost = 200000,
	multiplier = 3.00,
}, {
	key = "dark_silicon",
	name = "Dark Silicon Activation",
	description = "Powers dormant die sectors dynamically during burst workloads.",
	cost = 1000000,
	multiplier = 4.00,
} }
local function ScreenResearch()
	local gs = useGameState()
	local researchMap = gs.research or {}
	local items = if Config.Research then (Config.Research) else DEFAULT_RESEARCH
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
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
	}), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
	}, React.createElement("textlabel", {
		Text = "RESEARCH & DEVELOPMENT",
		Font = Font.bold,
		TextSize = Size.title,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Badge, {
		label = "INNOVATION",
		style = "accent",
		pill = true,
	})), React.createElement("textlabel", {
		Text = "Unlock high-order hardware enhancements to compound global compute yield.",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
	}))
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#items)
	local _callback = function(item, idx)
		local _key = item.key
		local _condition = researchMap[_key]
		if _condition == nil then
			_condition = 0
		end
		local currentLevel = _condition
		local cost = math.floor(item.cost * math.pow(1.5, currentLevel))
		local canAfford = gs.compute >= cost
		return React.createElement(Card, {
			key = item.key,
			height = 120,
			layoutOrder = idx + 2,
		}, React.createElement("uipadding", {
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
		}), React.createElement("frame", {
			Size = UDim2.new(1, -150, 1, 0),
			BackgroundTransparency = 1,
		}, React.createElement("uilistlayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 4),
		}), React.createElement("frame", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
		}, React.createElement("textlabel", {
			Text = item.name,
			Font = Font.bold,
			TextSize = Size.section,
			TextColor3 = C.textPrimary,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.7, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		}), React.createElement(Badge, {
			label = `MK {currentLevel + 1}`,
			style = if currentLevel > 0 then "compute" else "default",
		})), React.createElement("textlabel", {
			Text = item.description,
			Font = Font.body,
			TextSize = Size.caption,
			TextColor3 = C.textSecondary,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 32),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}), React.createElement("textlabel", {
			Text = `Multiplier: ×{string.format("%.2f", item.multiplier * (currentLevel + 1))}`,
			Font = Font.mono,
			TextSize = Size.micro,
			TextColor3 = C.compute,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
		})), React.createElement("frame", {
			Size = UDim2.new(0, 140, 1, 0),
			Position = UDim2.new(1, -140, 0, 0),
			BackgroundTransparency = 1,
		}, React.createElement("uilistlayout", {
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
		}), React.createElement("textlabel", {
			Text = `{fmt(cost)} ⚡`,
			Font = Font.bold,
			TextSize = Size.body,
			TextColor3 = if canAfford then C.compute else C.textMuted,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Right,
		}), React.createElement(Button, {
			label = "Upgrade",
			variant = if canAfford then "primary" else "secondary",
			width = 130,
			height = 36,
			disabled = not canAfford,
			onClick = function()
				return act("research", {
					key = item.key,
				})
			end,
		})))
	end
	for _k, _v in items do
		_newValue[_k] = _callback(_v, _k - 1, items)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("scrollingframe", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.hairline,
		CanvasSize = UDim2.new(0, 0, 0, 850),
	}, _exp, _exp_1, _exp_2, _newValue)
end
return {
	default = ScreenResearch,
}
