-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenCommand.tsx — Command Center: job button, stat grid, overclock banner
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local Font = _theme.Font
local Size = _theme.Size
local R = _theme.R
local Card = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Card").Card
local Button = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Button").Button
local StatTile = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "StatTile").StatTile
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local _store = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store")
local act = _store.act
local fmt = _store.fmt
-- ------- constants -------------------------------------------------------
local ENERGY_CAP = 100
local FLOAT_INFO = TweenInfo.new(0.80, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- ------- floating +X label -----------------------------------------------
local function FloatPop(_param)
	local amount = _param.amount
	local id = _param.id
	local ref = React.createRef()
	React.useEffect(function()
		local lbl = ref.current
		if not lbl then
			return nil
		end
		local ts = game:GetService("TweenService")
		ts:Create(lbl, FLOAT_INFO, {
			Position = UDim2.new(0.5, 0, 0, -60),
			TextTransparency = 1,
		}):Play()
		task.delay(0.85, function()
			local l = ref.current
			if l and l.Parent then
				l.Parent = nil
			end
		end)
	end, {})
	return React.createElement("textlabel", {
		ref = ref,
		key = `pop_{id}`,
		Text = `+{fmt(amount)} ⚡`,
		Font = Font.bold,
		TextSize = Size.section,
		TextColor3 = C.compute,
		TextStrokeTransparency = 0.6,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0.5, 0, 0, -20),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 20,
	})
end
-- ------- main screen -----------------------------------------------------
local function ScreenCommand()
	local gs = useGameState()
	local pops, setPops = React.useState({})
	local popCounter = React.useRef(0)
	local energyPct = math.clamp(gs.energy / ENERGY_CAP, 0, 1)
	local totalOwned = (function()
		local n = 0
		local _exp = gs.owned
		-- ▼ ReadonlyMap.forEach ▼
		local _callback = function(v)
			n += v
		end
		for _k, _v in _exp do
			_callback(_v, _k, _exp)
		end
		-- ▲ ReadonlyMap.forEach ▲
		return n
	end)()
	local prestigeBonus = gs.prestigeTokens * 0.1
	local isOverclocked = gs.boostUntil > os.time()
	local function handleJob()
		local result = act("job")
		local _condition = result
		if _condition == nil then
			_condition = 1
		end
		local gained = _condition
		local _original = popCounter.current
		popCounter.current += 1
		local id = _original
		setPops(function(prev)
			local _array = {}
			local _length = #_array
			local _prevLength = #prev
			table.move(prev, 1, _prevLength, _length + 1, _array)
			_length += _prevLength
			_array[_length + 1] = {
				id = id,
				amount = gained,
			}
			return _array
		end)
	end
	local _exp = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local _exp_1 = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 24),
	})
	local _exp_2 = isOverclocked and (React.createElement("frame", {
		key = "OverclockBanner",
		BackgroundColor3 = Color3.fromRGB(40, 22, 6),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = 0,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.card),
	}), React.createElement("uistroke", {
		Color = C.warning,
		Thickness = 1,
		Transparency = 0.45,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
	}), React.createElement("textlabel", {
		Text = "⚡  OVERCLOCK ACTIVE — compute multiplier boosted",
		Font = Font.bold,
		TextSize = Size.body,
		TextColor3 = C.warning,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})))
	local _exp_3 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	})
	local _exp_4 = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 24),
		PaddingRight = UDim.new(0, 24),
		PaddingTop = UDim.new(0, 18),
		PaddingBottom = UDim.new(0, 18),
	})
	local _exp_5 = React.createElement("textlabel", {
		key = "HeroTitle",
		Text = "COMMAND CENTER",
		Font = Font.bold,
		TextSize = Size.hero,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	})
	local _exp_6 = React.createElement("textlabel", {
		key = "HeroSub",
		Text = "Generate compute manually or let your hardware empire run.",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = 2,
	})
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#pops)
	local _callback = function(p)
		return React.createElement(FloatPop, {
			key = tostring(p.id),
			amount = p.amount,
			id = p.id,
		})
	end
	for _k, _v in pops do
		_newValue[_k] = _callback(_v, _k - 1, pops)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("scrollingframe", {
		BackgroundColor3 = C.canvas,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.hairline,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, _exp, _exp_1, _exp_2, React.createElement(Card, {
		height = 160,
		layoutOrder = 1,
	}, _exp_3, _exp_4, _exp_5, _exp_6, React.createElement("frame", {
		key = "PopLayer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 3,
		ZIndex = 15,
		ClipsDescendants = false,
	}, _newValue), React.createElement("frame", {
		key = "ButtonWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 240, 0, 44),
		LayoutOrder = 4,
	}, React.createElement(Button, {
		label = "⚡  Generate Compute",
		onClick = handleJob,
		variant = "primary",
		width = 240,
		height = 44,
	}))), React.createElement("frame", {
		key = "StatGrid",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 230),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	}, React.createElement("uigridlayout", {
		CellSize = UDim2.new(0.5, -6, 0, 108),
		CellPadding = UDim2.new(0, 12, 0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}), React.createElement(StatTile, {
		title = "ENERGY",
		value = `{math.floor(gs.energy)} / {ENERGY_CAP}`,
		subtitle = "power reserve",
		color = C.energy,
		layoutOrder = 1,
		progress = energyPct,
	}), React.createElement(StatTile, {
		title = "HARDWARE",
		value = fmt(totalOwned),
		subtitle = "units deployed",
		color = C.data,
		layoutOrder = 2,
	}), React.createElement(StatTile, {
		title = "DATA",
		value = fmt(gs.data),
		subtitle = "bytes collected",
		color = C.data,
		layoutOrder = 3,
	}), React.createElement(StatTile, {
		title = "MULTIPLIER",
		value = `×{string.format("%.1f", 1 + prestigeBonus)}`,
		subtitle = `{gs.prestigeTokens} prestige tokens`,
		color = C.reputation,
		layoutOrder = 4,
	})), React.createElement(Card, {
		height = 72,
		layoutOrder = 3,
		bgColor = Color3.fromRGB(10, 22, 16),
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}), React.createElement("textlabel", {
		key = "ComputeLabel",
		Text = "COMPUTE",
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 80, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 1,
	}), React.createElement("textlabel", {
		key = "ComputeVal",
		Text = fmt(gs.compute),
		Font = Font.bold,
		TextSize = Size.title,
		TextColor3 = C.compute,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -88, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 2,
	})))
end
return {
	default = ScreenCommand,
}
