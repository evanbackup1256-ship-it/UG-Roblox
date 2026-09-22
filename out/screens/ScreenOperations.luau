-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenOperations.tsx — Energy management and mission dispatch
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local Font = _theme.Font
local Size = _theme.Size
local Card = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Card").Card
local Button = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Button").Button
local Badge = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Badge").Badge
local ProgressBar = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "ProgressBar").ProgressBar
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local _store = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store")
local act = _store.act
local fmt = _store.fmt
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("DeckGame"):WaitForChild("Config"))
local ENERGY_CAP = 100
local function opList()
	local ops = Config.Operations or {}
	local result = {}
	for k, v in pairs(ops) do
		local _object = {
			key = k,
		}
		local _left = "name"
		local _condition = v.name
		if _condition == nil then
			_condition = k
		end
		_object[_left] = _condition
		local _left_1 = "description"
		local _condition_1 = v.description
		if _condition_1 == nil then
			_condition_1 = ""
		end
		_object[_left_1] = _condition_1
		local _left_2 = "successRate"
		local _condition_2 = v.successRate
		if _condition_2 == nil then
			_condition_2 = 0.8
		end
		_object[_left_2] = _condition_2
		local _left_3 = "rewardCompute"
		local _condition_3 = v.rewardCompute
		if _condition_3 == nil then
			_condition_3 = 0
		end
		_object[_left_3] = _condition_3
		local _left_4 = "rewardData"
		local _condition_4 = v.rewardData
		if _condition_4 == nil then
			_condition_4 = 0
		end
		_object[_left_4] = _condition_4
		local _left_5 = "energyCost"
		local _condition_5 = v.energyCost
		if _condition_5 == nil then
			_condition_5 = 10
		end
		_object[_left_5] = _condition_5
		table.insert(result, _object)
	end
	return result
end
-- ------- mission card ---------------------------------------------------
local function MissionCard(_param)
	local op = _param.op
	local index = _param.index
	local energy = _param.energy
	local onDispatch = _param.onDispatch
	local canDispatch = energy >= op.energyCost
	local pct = op.successRate
	local pctStr = `{math.floor(pct * 100)}%`
	local rewardStr = if op.rewardCompute > 0 then `+{fmt(op.rewardCompute)} compute` else `+{fmt(op.rewardData)} data`
	local tagLabel = `TASK {string.format("%02d", index)}`
	return React.createElement(Card, {
		height = 200,
		layoutOrder = index,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}), React.createElement("frame", {
		key = "BadgeRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 1,
	}, React.createElement(Badge, {
		label = tagLabel,
		style = "accent",
	})), React.createElement("textlabel", {
		key = "OpName",
		Text = op.name,
		Font = Font.bold,
		TextSize = Size.section,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	}), React.createElement("textlabel", {
		key = "OpDesc",
		Text = if op.description ~= "" then op.description else "Execute automated cloud operations.",
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LayoutOrder = 3,
	}), React.createElement("frame", {
		key = "StatsRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 4,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}), React.createElement("textlabel", {
		key = "SuccessRate",
		Text = `Success {pctStr}`,
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.compute,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 110, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}), React.createElement("textlabel", {
		key = "Reward",
		Text = rewardStr,
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.data,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 140, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	}), React.createElement("textlabel", {
		key = "EnergyCost",
		Text = `⚡ −{op.energyCost}`,
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.energy,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 70, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 3,
	})), React.createElement("frame", {
		key = "BtnWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 5,
	}, React.createElement(Button, {
		label = if canDispatch then "▶  Dispatch" else `Need {op.energyCost} ⚡`,
		onClick = onDispatch,
		variant = "success",
		disabled = not canDispatch,
		height = 36,
	})))
end
-- ------- main screen ----------------------------------------------------
local function ScreenOperations()
	local gs = useGameState()
	local energyPct = math.clamp(gs.energy / ENERGY_CAP, 0, 1)
	local ops = React.useState(function()
		local ok, result = pcall(opList)
		return if ok and type(result) == "table" then result else {}
	end)
	local function handleRecharge()
		act("recharge")
	end
	local function handleDispatch(op)
		act("dispatch", {
			op = op.key,
		})
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
	local _exp_2 = React.createElement(Card, {
		height = 164,
		layoutOrder = 1,
		bgColor = Color3.fromRGB(22, 17, 5),
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 18),
		PaddingBottom = UDim.new(0, 18),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}), React.createElement("textlabel", {
		key = "EnergyLabel",
		Text = "POWER RESERVE",
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}), React.createElement("textlabel", {
		key = "EnergyValue",
		Text = `{math.floor(gs.energy)}  /  {ENERGY_CAP}`,
		Font = Font.bold,
		TextSize = 34,
		TextColor3 = C.energy,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	}), React.createElement("frame", {
		key = "BarWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 8),
		LayoutOrder = 3,
	}, React.createElement(ProgressBar, {
		progress = energyPct,
		color = C.energy,
		height = 8,
		glow = true,
	})), React.createElement("frame", {
		key = "RechargeBtnWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		LayoutOrder = 4,
	}, React.createElement(Button, {
		label = "↺  Recharge Energy",
		onClick = handleRecharge,
		variant = "amber",
		height = 38,
	})))
	local _exp_3 = React.createElement("textlabel", {
		key = "MissionsLabel",
		Text = "AVAILABLE MISSIONS",
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	})
	local _result
	if #ops == 0 then
		_result = (React.createElement(Card, {
			height = 80,
			layoutOrder = 3,
		}, React.createElement("textlabel", {
			Text = "No operations configured",
			Font = Font.body,
			TextSize = Size.body,
			TextColor3 = C.textMuted,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		})))
	else
		-- ▼ ReadonlyArray.map ▼
		local _newValue = table.create(#ops)
		local _callback = function(op, i)
			return React.createElement(MissionCard, {
				key = op.key,
				op = op,
				index = i + 1,
				energy = gs.energy,
				onDispatch = function()
					return handleDispatch(op)
				end,
			})
		end
		for _k, _v in ops do
			_newValue[_k] = _callback(_v, _k - 1, ops)
		end
		-- ▲ ReadonlyArray.map ▲
		_result = _newValue
	end
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
	}, _exp, _exp_1, _exp_2, _exp_3, _result)
end
return {
	default = ScreenOperations,
}
