-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenStandings.tsx — Leaderboards and Global Fleet Standings
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local Font = _theme.Font
local Size = _theme.Size
local Card = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Card").Card
local Button = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Button").Button
local Badge = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Badge").Badge
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local fmt = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store").fmt
local SAMPLE_STANDINGS = { {
	rank = 1,
	userId = 1,
	callsign = "NexusPrime",
	score = 8500000000,
}, {
	rank = 2,
	userId = 2,
	callsign = "ValkyrieCore",
	score = 6200000000,
}, {
	rank = 3,
	userId = 3,
	callsign = "ApexOverclock",
	score = 4900000000,
}, {
	rank = 4,
	userId = 4,
	callsign = "CyberFleet_01",
	score = 2100000000,
}, {
	rank = 5,
	userId = 5,
	callsign = "ZeroDayNode",
	score = 1450000000,
}, {
	rank = 6,
	userId = 6,
	callsign = "SolarisGrid",
	score = 980000000,
}, {
	rank = 7,
	userId = 7,
	callsign = "HyperionCluster",
	score = 620000000,
}, {
	rank = 8,
	userId = 8,
	callsign = "QuantumShift",
	score = 410000000,
} }
local function ScreenStandings()
	local gs = useGameState()
	local category, setCategory = React.useState("compute")
	local entries, setEntries = React.useState(SAMPLE_STANDINGS)
	local loading, setLoading = React.useState(false)
	local refreshLeaderboard = function()
		setLoading(true)
		task.delay(0.5, function()
			setLoading(false)
		end)
	end
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
		height = 90,
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
		Text = "FLEET STANDINGS & TELEMETRY",
		Font = Font.bold,
		TextSize = Size.title,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Badge, {
		label = "GLOBAL",
		style = "accent",
		pill = true,
	})), React.createElement("textlabel", {
		Text = "Competitive rankings across enterprise operators worldwide.",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
	})))
	local _exp_3 = React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 12),
	}), React.createElement(Button, {
		label = "All-Time Compute",
		variant = if category == "compute" then "primary" else "secondary",
		width = 160,
		height = 36,
		onClick = function()
			return setCategory("compute")
		end,
	}), React.createElement(Button, {
		label = "Prestige Tokens",
		variant = if category == "prestige" then "primary" else "secondary",
		width = 160,
		height = 36,
		onClick = function()
			return setCategory("prestige")
		end,
	}), React.createElement(Button, {
		label = if loading then "Refreshing..." else "↻ Refresh",
		variant = "secondary",
		width = 120,
		height = 36,
		disabled = loading,
		onClick = refreshLeaderboard,
	}))
	local _exp_4 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 14),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})
	local _exp_5 = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
	})
	local _exp_6 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
	})
	local _exp_7 = React.createElement(Badge, {
		label = "#2 SILVER",
		style = "default",
		pill = true,
	})
	local _attributes = {}
	local _result = entries[2]
	if _result ~= nil then
		_result = _result.callsign
	end
	local _condition = _result
	if _condition == nil then
		_condition = "—"
	end
	_attributes.Text = _condition
	_attributes.Font = Font.bold
	_attributes.TextSize = Size.section
	_attributes.TextColor3 = C.textPrimary
	_attributes.BackgroundTransparency = 1
	_attributes.Size = UDim2.new(1, 0, 0, 22)
	local _exp_8 = React.createElement("textlabel", _attributes)
	local _attributes_1 = {}
	local _result_1 = entries[2]
	if _result_1 ~= nil then
		_result_1 = _result_1.score
	end
	local _condition_1 = _result_1
	if _condition_1 == nil then
		_condition_1 = 0
	end
	_attributes_1.Text = fmt(_condition_1)
	_attributes_1.Font = Font.mono
	_attributes_1.TextSize = Size.body
	_attributes_1.TextColor3 = C.accent
	_attributes_1.BackgroundTransparency = 1
	_attributes_1.Size = UDim2.new(1, 0, 0, 20)
	local _exp_9 = React.createElement(Card, {
		height = 140,
		bgColor = Color3.fromRGB(20, 22, 28),
	}, _exp_5, _exp_6, _exp_7, _exp_8, React.createElement("textlabel", _attributes_1))
	local _exp_10 = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
	})
	local _exp_11 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
	})
	local _exp_12 = React.createElement(Badge, {
		label = "#1 GOLD",
		style = "energy",
		pill = true,
	})
	local _attributes_2 = {}
	local _result_2 = entries[1]
	if _result_2 ~= nil then
		_result_2 = _result_2.callsign
	end
	local _condition_2 = _result_2
	if _condition_2 == nil then
		_condition_2 = "—"
	end
	_attributes_2.Text = _condition_2
	_attributes_2.Font = Font.bold
	_attributes_2.TextSize = Size.section + 2
	_attributes_2.TextColor3 = C.gold
	_attributes_2.BackgroundTransparency = 1
	_attributes_2.Size = UDim2.new(1, 0, 0, 24)
	local _exp_13 = React.createElement("textlabel", _attributes_2)
	local _attributes_3 = {}
	local _result_3 = entries[1]
	if _result_3 ~= nil then
		_result_3 = _result_3.score
	end
	local _condition_3 = _result_3
	if _condition_3 == nil then
		_condition_3 = 0
	end
	_attributes_3.Text = fmt(_condition_3)
	_attributes_3.Font = Font.mono
	_attributes_3.TextSize = Size.body
	_attributes_3.TextColor3 = C.gold
	_attributes_3.BackgroundTransparency = 1
	_attributes_3.Size = UDim2.new(1, 0, 0, 20)
	local _exp_14 = React.createElement(Card, {
		height = 140,
		bgColor = Color3.fromRGB(28, 28, 36),
	}, _exp_10, _exp_11, _exp_12, _exp_13, React.createElement("textlabel", _attributes_3))
	local _exp_15 = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
	})
	local _exp_16 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
	})
	local _exp_17 = React.createElement(Badge, {
		label = "#3 BRONZE",
		style = "danger",
		pill = true,
	})
	local _attributes_4 = {}
	local _result_4 = entries[3]
	if _result_4 ~= nil then
		_result_4 = _result_4.callsign
	end
	local _condition_4 = _result_4
	if _condition_4 == nil then
		_condition_4 = "—"
	end
	_attributes_4.Text = _condition_4
	_attributes_4.Font = Font.bold
	_attributes_4.TextSize = Size.section
	_attributes_4.TextColor3 = C.textPrimary
	_attributes_4.BackgroundTransparency = 1
	_attributes_4.Size = UDim2.new(1, 0, 0, 22)
	local _exp_18 = React.createElement("textlabel", _attributes_4)
	local _attributes_5 = {}
	local _result_5 = entries[3]
	if _result_5 ~= nil then
		_result_5 = _result_5.score
	end
	local _condition_5 = _result_5
	if _condition_5 == nil then
		_condition_5 = 0
	end
	_attributes_5.Text = fmt(_condition_5)
	_attributes_5.Font = Font.mono
	_attributes_5.TextSize = Size.body
	_attributes_5.TextColor3 = C.accent
	_attributes_5.BackgroundTransparency = 1
	_attributes_5.Size = UDim2.new(1, 0, 0, 20)
	local _exp_19 = React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 140),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
	}, _exp_4, _exp_9, _exp_14, React.createElement(Card, {
		height = 140,
		bgColor = Color3.fromRGB(20, 22, 28),
	}, _exp_15, _exp_16, _exp_17, _exp_18, React.createElement("textlabel", _attributes_5)))
	-- ▼ ReadonlyArray.filter ▼
	local _newValue = {}
	local _callback = function(_, idx)
		return idx >= 3
	end
	local _length = 0
	for _k, _v in entries do
		if _callback(_v, _k - 1, entries) == true then
			_length += 1
			_newValue[_length] = _v
		end
	end
	-- ▲ ReadonlyArray.filter ▲
	-- ▼ ReadonlyArray.map ▼
	local _newValue_1 = table.create(#_newValue)
	local _callback_1 = function(item, idx)
		return React.createElement(Card, {
			key = tostring(item.rank),
			height = 52,
			layoutOrder = idx + 4,
		}, React.createElement("uipadding", {
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}), React.createElement("frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, React.createElement("uilistlayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 14),
		}), React.createElement("textlabel", {
			Text = `#{item.rank}`,
			Font = Font.mono,
			TextSize = Size.body,
			TextColor3 = C.textMuted,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 36, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		}), React.createElement("textlabel", {
			Text = item.callsign,
			Font = Font.bold,
			TextSize = Size.body,
			TextColor3 = C.textPrimary,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.6, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		}), React.createElement("textlabel", {
			Text = `{fmt(item.score)} ⚡`,
			Font = Font.mono,
			TextSize = Size.body,
			TextColor3 = C.compute,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.3, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
		})))
	end
	for _k, _v in _newValue do
		_newValue_1[_k] = _callback_1(_v, _k - 1, _newValue)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("scrollingframe", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.hairline,
		CanvasSize = UDim2.new(0, 0, 0, 900),
	}, _exp, _exp_1, _exp_2, _exp_3, _exp_19, _newValue_1)
end
return {
	default = ScreenStandings,
}
