-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenContracts.tsx — Work orders / contracts screen
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local Font = _theme.Font
local Size = _theme.Size
local Button = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Button").Button
local ProgressBar = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "ProgressBar").ProgressBar
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local _store = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store")
local act = _store.act
local fmt = _store.fmt
-- ---------------------------------------------------------------------------
-- Data definitions
-- ---------------------------------------------------------------------------
local PLACEHOLDER_CONTRACTS = { {
	id = "startup_mvp",
	client = "NovaSpark Labs",
	description = "Bootstrap MVP cloud infrastructure for our seed-stage startup.",
	requirement = "Earn 10K compute",
	targetCompute = 10_000,
	reward = {
		data = 500,
		energy = 50,
	},
}, {
	id = "media_render",
	client = "Prismatic Studios",
	description = "Render 4K HDR visual effects pipeline at peak throughput.",
	requirement = "Earn 250K compute",
	targetCompute = 250_000,
	reward = {
		compute = 20_000,
		data = 2000,
	},
}, {
	id = "fintech_compliance",
	client = "Axiom Finance",
	description = "Host encrypted compliance ledger with 99.99% uptime SLA.",
	requirement = "Earn 1M compute",
	targetCompute = 1_000_000,
	reward = {
		prestigeTokens = 1,
		compute = 100_000,
	},
}, {
	id = "ai_training",
	client = "Cognition AI",
	description = "Distribute LLM training jobs across our quantum cluster.",
	requirement = "Earn 10M compute",
	targetCompute = 10_000_000,
	reward = {
		prestigeTokens = 3,
		data = 50_000,
	},
}, {
	id = "govt_archive",
	client = "Federal Bureau of Data",
	description = "Archive classified datasets into geographically redundant vaults.",
	requirement = "Earn 100M compute",
	targetCompute = 100_000_000,
	reward = {
		prestigeTokens = 10,
		energy = 10_000,
	},
}, {
	id = "singularity_bid",
	client = "Ω Collective",
	description = "Power the final convergence event. All or nothing.",
	requirement = "Earn 1B compute",
	targetCompute = 1_000_000_000,
	reward = {
		prestigeTokens = 50,
	},
} }
local function getContractStatus(contract, totalEarned, claimed)
	local _claimed = claimed
	local _id = contract.id
	if _claimed[_id] == true then
		return "completed"
	end
	if totalEarned >= contract.targetCompute then
		return "active"
	end
	if totalEarned >= contract.targetCompute * 0.01 then
		return "active"
	end
	return "available"
end
local function getProgress(contract, totalEarned)
	return math.clamp(totalEarned / contract.targetCompute, 0, 1)
end
-- ---------------------------------------------------------------------------
-- Sub-component: ContractCard
-- ---------------------------------------------------------------------------
local function rewardText(r)
	local parts = {}
	local _value = r.compute
	if _value ~= 0 and _value == _value and _value then
		local _arg0 = `⚡ {fmt(r.compute)} compute`
		table.insert(parts, _arg0)
	end
	local _value_1 = r.data
	if _value_1 ~= 0 and _value_1 == _value_1 and _value_1 then
		local _arg0 = `◈ {fmt(r.data)} data`
		table.insert(parts, _arg0)
	end
	local _value_2 = r.energy
	if _value_2 ~= 0 and _value_2 == _value_2 and _value_2 then
		local _arg0 = `⚙ {fmt(r.energy)} energy`
		table.insert(parts, _arg0)
	end
	local _value_3 = r.prestigeTokens
	if _value_3 ~= 0 and _value_3 == _value_3 and _value_3 then
		local _arg0 = `✦ {tostring(r.prestigeTokens)} prestige`
		table.insert(parts, _arg0)
	end
	return table.concat(parts, "  ·  ")
end
local function ContractCard(_param)
	local contract = _param.contract
	local status = _param.status
	local progress = _param.progress
	local layoutOrder = _param.layoutOrder
	local isCompleted = status == "completed"
	local isActive = status == "active"
	local canClaim = progress >= 1 and not isCompleted
	local borderColor = if isCompleted then C.compute elseif isActive then C.accent else C.hairline
	local borderAlpha = if isCompleted then 0.35 elseif isActive then 0.45 else 0.72
	return React.createElement("frame", {
		key = contract.id,
		BackgroundColor3 = if isCompleted then Color3.fromRGB(14, 24, 18) else C.card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, if isActive and not isCompleted then 172 else 148),
		LayoutOrder = layoutOrder,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.card),
	}), React.createElement("uistroke", {
		Color = borderColor,
		Thickness = 1,
		Transparency = borderAlpha,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	}), React.createElement("frame", {
		key = "TopRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 24),
		Position = UDim2.new(0, 16, 0, 14),
		ZIndex = 3,
	}, React.createElement("textlabel", {
		key = "Client",
		Text = string.upper(contract.client),
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = if isCompleted then C.compute else C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -90, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}), isCompleted and (React.createElement("frame", {
		key = "DoneBadge",
		BackgroundColor3 = Color3.fromRGB(14, 28, 20),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 82, 0, 20),
		Position = UDim2.new(1, -82, 0, 2),
		ZIndex = 3,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.badge),
	}), React.createElement("uistroke", {
		Color = C.compute,
		Thickness = 1,
		Transparency = 0.4,
	}), React.createElement("textlabel", {
		Text = "✓  FULFILLED",
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.compute,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4,
	}))), not isCompleted and isActive and (React.createElement("frame", {
		key = "ActiveBadge",
		BackgroundColor3 = Color3.fromRGB(14, 22, 40),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 62, 0, 20),
		Position = UDim2.new(1, -62, 0, 2),
		ZIndex = 3,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.badge),
	}), React.createElement("uistroke", {
		Color = C.accent,
		Thickness = 1,
		Transparency = 0.4,
	}), React.createElement("textlabel", {
		Text = "ACTIVE",
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.accent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4,
	})))), React.createElement("textlabel", {
		key = "Desc",
		Text = contract.description,
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = if isCompleted then C.textMuted else C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 36),
		Position = UDim2.new(0, 16, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 3,
	}), React.createElement("textlabel", {
		key = "Req",
		Text = `📋  {contract.requirement}`,
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 16),
		Position = UDim2.new(0, 16, 0, 86),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}), isActive and not isCompleted and (React.createElement("frame", {
		key = "ProgressWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 10),
		Position = UDim2.new(0, 16, 0, 108),
		ZIndex = 3,
	}, React.createElement(ProgressBar, {
		progress = progress,
		color = if progress >= 1 then C.compute else C.accent,
		height = 5,
		glow = progress >= 1,
	}), React.createElement("textlabel", {
		key = "Pct",
		Text = `{tostring(math.floor(progress * 100))}%`,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 36, 0, 10),
		Position = UDim2.new(1, -36, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 4,
	}))), React.createElement("frame", {
		key = "Footer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 32),
		Position = UDim2.new(0, 16, 0, if isActive and not isCompleted then 128 else 108),
		ZIndex = 3,
	}, React.createElement("textlabel", {
		key = "Reward",
		Text = rewardText(contract.reward),
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.data,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -110, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
	}), React.createElement("frame", {
		key = "BtnWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(1, -100, 0, 1),
		ZIndex = 3,
	}, if isCompleted then (React.createElement(Button, {
		label = "Completed",
		onClick = function() end,
		variant = "secondary",
		height = 30,
		disabled = true,
	})) elseif canClaim then (React.createElement(Button, {
		label = "Complete ✓",
		onClick = function()
			return act("claimContract", {
				id = contract.id,
			})
		end,
		variant = "success",
		height = 30,
	})) else (React.createElement(Button, {
		label = if isActive then "In Progress" else "Accept",
		onClick = function()
			return act("acceptContract", {
				id = contract.id,
			})
		end,
		variant = if isActive then "secondary" else "primary",
		height = 30,
		disabled = isActive,
	})))))
end
-- ---------------------------------------------------------------------------
-- Screen
-- ---------------------------------------------------------------------------
local function ScreenContracts()
	local state = useGameState()
	local claimed = state.claimed or {}
	local _condition = state.totalEarned
	if _condition == nil then
		_condition = 0
	end
	local totalEarned = _condition
	local _array = {}
	local _length = #_array
	table.move(PLACEHOLDER_CONTRACTS, 1, #PLACEHOLDER_CONTRACTS, _length + 1, _array)
	table.sort(_array, function(a, b)
		return a.targetCompute < b.targetCompute
	end)
	local sorted = _array
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
		Size = UDim2.new(1, 0, 0, 56),
		LayoutOrder = 0,
	}, React.createElement("textlabel", {
		Text = "CONTRACTS",
		Font = Font.bold,
		TextSize = Size.hero,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("textlabel", {
		Text = "Accept work orders from clients. Complete milestones to earn bonus resources.",
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}))
	local _exp_3 = React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	})
	local _exp_4 = React.createElement("uistroke", {
		Color = C.hairline,
		Thickness = 1,
		Transparency = 0.65,
	})
	local _exp_5 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local _exp_6 = React.createElement("frame", {
		key = "TotalStat",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 1, 0),
		LayoutOrder = 1,
	}, React.createElement("textlabel", {
		Text = "TOTAL COMPUTE EARNED",
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 16, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("textlabel", {
		Text = fmt(totalEarned),
		Font = Font.bold,
		TextSize = Size.section,
		TextColor3 = C.compute,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 16, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
	}))
	local _exp_7 = React.createElement("textlabel", {
		Text = "CONTRACTS FULFILLED",
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 16, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local _attributes = {}
	-- ▼ ReadonlyArray.reduce ▼
	local _result = 0
	local _callback = function(n, c)
		local _exp_8 = n
		local _id = c.id
		return _exp_8 + (if claimed[_id] then 1 else 0)
	end
	for _i = 1, #PLACEHOLDER_CONTRACTS do
		_result = _callback(_result, PLACEHOLDER_CONTRACTS[_i], _i - 1, PLACEHOLDER_CONTRACTS)
	end
	-- ▲ ReadonlyArray.reduce ▲
	_attributes.Text = tostring(_result)
	_attributes.Font = Font.bold
	_attributes.TextSize = Size.section
	_attributes.TextColor3 = C.accent
	_attributes.BackgroundTransparency = 1
	_attributes.Size = UDim2.new(1, 0, 0, 20)
	_attributes.Position = UDim2.new(0, 16, 0, 24)
	_attributes.TextXAlignment = Enum.TextXAlignment.Left
	local _exp_8 = React.createElement("frame", {
		key = "StatsRow",
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 48),
		LayoutOrder = 1,
	}, _exp_3, _exp_4, _exp_5, _exp_6, React.createElement("frame", {
		key = "CompStat",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 1, 0),
		LayoutOrder = 2,
	}, _exp_7, React.createElement("textlabel", _attributes)))
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#sorted)
	local _callback_1 = function(contract, i)
		local status = getContractStatus(contract, totalEarned, claimed)
		local progress = getProgress(contract, totalEarned)
		return React.createElement(ContractCard, {
			key = contract.id,
			contract = contract,
			status = status,
			progress = progress,
			layoutOrder = i + 2,
		})
	end
	for _k, _v in sorted do
		_newValue[_k] = _callback_1(_v, _k - 1, sorted)
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
	}, _exp, _exp_1, _exp_2, _exp_8, _newValue)
end
return {
	default = ScreenContracts,
}
