-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenHardware.tsx — Buy hardware tiers, search/filter, qty toggle
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local Font = _theme.Font
local Size = _theme.Size
local R = _theme.R
local Card = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Card").Card
local Button = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Button").Button
local Badge = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Badge").Badge
local TextInput = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "TextInput").TextInput
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local _store = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store")
local act = _store.act
local fmt = _store.fmt
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("DeckGame"):WaitForChild("Config"))
-- Tier dot colors cycling through accent palette
local TIER_COLORS = { Color3.fromRGB(16, 185, 129), Color3.fromRGB(59, 130, 246), Color3.fromRGB(245, 158, 11), Color3.fromRGB(139, 92, 246), Color3.fromRGB(236, 72, 153), Color3.fromRGB(6, 182, 212) }
local QTY_OPTIONS = { 1, 5, 10 }
local function tierList()
	local tiers = Config.Tiers or {}
	local result = {}
	local i = 0
	for k, v in pairs(tiers) do
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
		local _left_2 = "cost"
		local _condition_2 = v.cost
		if _condition_2 == nil then
			_condition_2 = 100
		end
		_object[_left_2] = _condition_2
		_object.colorIdx = i % #TIER_COLORS
		table.insert(result, _object)
		i += 1
	end
	return result
end
-- ------- Filter Button --------------------------------------------------
local function FilterBtn(_param)
	local label = _param.label
	local active = _param.active
	local onClick = _param.onClick
	return React.createElement("textbutton", {
		Text = label,
		Font = if active then Font.bold else Font.body,
		TextSize = Size.caption,
		TextColor3 = if active then C.textPrimary else C.textMuted,
		BackgroundColor3 = if active then C.elevated else C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 88, 1, 0),
		AutoButtonColor = false,
		Event = {
			Activated = onClick,
		},
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	}), React.createElement("uistroke", {
		Color = if active then C.accent else C.hairline,
		Thickness = 1,
		Transparency = if active then 0.5 else 0.75,
	}))
end
-- ------- Qty Pill -------------------------------------------------------
local function QtyPill(_param)
	local qty = _param.qty
	local active = _param.active
	local onClick = _param.onClick
	return React.createElement("textbutton", {
		Text = `×{qty}`,
		Font = if active then Font.bold else Font.body,
		TextSize = Size.caption,
		TextColor3 = if active then C.textInverse else C.textSecondary,
		BackgroundColor3 = if active then C.accent else C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 48, 1, 0),
		AutoButtonColor = false,
		Event = {
			Activated = onClick,
		},
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}))
end
-- ------- Tier Card ------------------------------------------------------
local function TierCard(_param)
	local tier = _param.tier
	local owned = _param.owned
	local qty = _param.qty
	local compute = _param.compute
	local onBuy = _param.onBuy
	local layoutOrder = _param.layoutOrder
	local totalCost = tier.cost * qty
	local canBuy = compute >= totalCost
	local dotColor = TIER_COLORS[tier.colorIdx + 1]
	return React.createElement(Card, {
		height = 168,
		layoutOrder = layoutOrder,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}), React.createElement("frame", {
		key = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 1,
	}, React.createElement("frame", {
		key = "Dot",
		BackgroundColor3 = dotColor,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("uistroke", {
		Color = dotColor,
		Thickness = 3,
		Transparency = 0.6,
	})), React.createElement("textlabel", {
		key = "TierName",
		Text = tier.name,
		Font = Font.bold,
		TextSize = Size.section,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 18, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}), React.createElement("frame", {
		key = "OwnedBadge",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.new(0, 60, 1, 0),
	}, React.createElement(Badge, {
		label = `{owned} owned`,
		style = "default",
	}))), React.createElement("textlabel", {
		key = "TierDesc",
		Text = if tier.description ~= "" then tier.description else "Cloud hardware module.",
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LayoutOrder = 2,
	}), React.createElement("textlabel", {
		key = "Cost",
		Text = `⚡ {fmt(totalCost)} compute{if qty > 1 then ` (×{qty})` else ""}`,
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = if canBuy then C.compute else C.danger,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 3,
	}), React.createElement("frame", {
		key = "BuyWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 4,
	}, React.createElement(Button, {
		label = if canBuy then `Buy ×{qty}` else "Insufficient Compute",
		onClick = onBuy,
		variant = if canBuy then "primary" else "secondary",
		disabled = not canBuy,
		height = 36,
	})))
end
-- ------- main screen ----------------------------------------------------
local function ScreenHardware()
	local gs = useGameState()
	local search, setSearch = React.useState("")
	local filter, setFilter = React.useState("all")
	local qty, setQty = React.useState(1)
	local allTiers = React.useState(function()
		local ok, result = pcall(tierList)
		return if ok and type(result) == "table" then result else {}
	end)
	-- Client-side filter
	-- ▼ ReadonlyArray.filter ▼
	local _newValue = {}
	local _callback = function(t)
		local q = string.lower(search)
		local _condition = q ~= ""
		if _condition then
			local _value = (string.find(string.lower(t.name), q))
			_condition = not (_value ~= 0 and _value == _value and _value)
		end
		if _condition then
			return false
		end
		local _owned = gs.owned
		local _key = t.key
		local _condition_1 = _owned[_key]
		if _condition_1 == nil then
			_condition_1 = 0
		end
		local owned = _condition_1
		if filter == "deployed" and owned == 0 then
			return false
		end
		if filter == "available" and owned > 0 then
			return false
		end
		return true
	end
	local _length = 0
	for _k, _v in allTiers do
		if _callback(_v, _k - 1, allTiers) == true then
			_length += 1
			_newValue[_length] = _v
		end
	end
	-- ▲ ReadonlyArray.filter ▲
	local visibleTiers = _newValue
	local function handleBuy(tier)
		act("buy", {
			tier = tier.key,
			qty = qty,
		})
	end
	local _exp = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local _exp_1 = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 24),
	})
	local _exp_2 = React.createElement("textlabel", {
		key = "PageTitle",
		Text = "HARDWARE MARKET",
		Font = Font.bold,
		TextSize = Size.hero,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	})
	local _exp_3 = React.createElement("frame", {
		key = "SearchWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 2,
	}, React.createElement(TextInput, {
		placeholder = "Search hardware…",
		onChange = function(t)
			return setSearch(t)
		end,
	}))
	local _exp_4 = React.createElement("frame", {
		key = "FilterRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 3,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}), React.createElement(FilterBtn, {
		label = "All",
		active = filter == "all",
		onClick = function()
			return setFilter("all")
		end,
	}), React.createElement(FilterBtn, {
		label = "Deployed",
		active = filter == "deployed",
		onClick = function()
			return setFilter("deployed")
		end,
	}), React.createElement(FilterBtn, {
		label = "Available",
		active = filter == "available",
		onClick = function()
			return setFilter("available")
		end,
	}))
	local _exp_5 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local _exp_6 = React.createElement("textlabel", {
		Text = "QTY",
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 34, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	-- ▼ ReadonlyArray.map ▼
	local _newValue_1 = table.create(#QTY_OPTIONS)
	local _callback_1 = function(q)
		return React.createElement(QtyPill, {
			key = tostring(q),
			qty = q,
			active = qty == q,
			onClick = function()
				return setQty(q)
			end,
		})
	end
	for _k, _v in QTY_OPTIONS do
		_newValue_1[_k] = _callback_1(_v, _k - 1, QTY_OPTIONS)
	end
	-- ▲ ReadonlyArray.map ▲
	local _exp_7 = React.createElement("frame", {
		key = "QtyRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 4,
	}, _exp_5, _exp_6, _newValue_1)
	local _exp_8 = React.createElement("frame", {
		key = "BalanceRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 5,
	}, React.createElement("textlabel", {
		Text = `Balance: {fmt(gs.compute)} compute`,
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.compute,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}))
	local _result
	if #visibleTiers == 0 then
		_result = (React.createElement(Card, {
			height = 80,
			layoutOrder = 6,
		}, React.createElement("textlabel", {
			Text = "No hardware matches your filter",
			Font = Font.body,
			TextSize = Size.body,
			TextColor3 = C.textMuted,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		})))
	else
		local _exp_9 = React.createElement("uigridlayout", {
			CellSize = UDim2.new(0.5, -6, 0, 168),
			CellPadding = UDim2.new(0, 12, 0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
		})
		-- ▼ ReadonlyArray.map ▼
		local _newValue_2 = table.create(#visibleTiers)
		local _callback_2 = function(t, i)
			local _attributes = {
				key = t.key,
				tier = t,
			}
			local _owned = gs.owned
			local _key = t.key
			local _condition = _owned[_key]
			if _condition == nil then
				_condition = 0
			end
			_attributes.owned = _condition
			_attributes.qty = qty
			_attributes.compute = gs.compute
			_attributes.onBuy = function()
				return handleBuy(t)
			end
			_attributes.layoutOrder = i + 1
			return React.createElement(TierCard, _attributes)
		end
		for _k, _v in visibleTiers do
			_newValue_2[_k] = _callback_2(_v, _k - 1, visibleTiers)
		end
		-- ▲ ReadonlyArray.map ▲
		_result = (React.createElement("frame", {
			key = "TierGrid",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 6,
		}, _exp_9, _newValue_2))
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
	}, _exp, _exp_1, _exp_2, _exp_3, _exp_4, _exp_7, _exp_8, _result)
end
return {
	default = ScreenHardware,
}
