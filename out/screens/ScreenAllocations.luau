-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenAllocations.tsx — Daily rewards + streak + achievements
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
-- Data
-- ---------------------------------------------------------------------------
local DAY_REWARDS = { {
	day = 1,
	label = "+500 ⚡",
	icon = "⚡",
}, {
	day = 2,
	label = "+1K ◈",
	icon = "◈",
}, {
	day = 3,
	label = "+2K ⚡",
	icon = "⚡",
}, {
	day = 4,
	label = "+50 ⚙",
	icon = "⚙",
}, {
	day = 5,
	label = "+5K ⚡",
	icon = "⚡",
}, {
	day = 6,
	label = "+200 ◈",
	icon = "◈",
}, {
	day = 7,
	label = "✦ 1 Prestige",
	icon = "✦",
} }
local ACHIEVEMENTS = { {
	id = "first_job",
	name = "First Job",
	description = "Dispatch your first compute job.",
	icon = "🖥",
	target = 1,
	getValue = function(_, jobs)
		return jobs
	end,
}, {
	id = "kilowatt",
	name = "Kilowatt Club",
	description = "Earn 1,000 compute total.",
	icon = "⚡",
	target = 1_000,
	getValue = function(_, __, total)
		return total
	end,
}, {
	id = "megawatt",
	name = "Megawatt Tier",
	description = "Earn 1,000,000 compute total.",
	icon = "🔋",
	target = 1_000_000,
	getValue = function(_, __, total)
		return total
	end,
}, {
	id = "gigawatt",
	name = "Gigawatt Empire",
	description = "Earn 1,000,000,000 compute total.",
	icon = "🌐",
	target = 1_000_000_000,
	getValue = function(_, __, total)
		return total
	end,
}, {
	id = "century_jobs",
	name = "Century Operator",
	description = "Dispatch 100 compute jobs.",
	icon = "📡",
	target = 100,
	getValue = function(_, jobs)
		return jobs
	end,
}, {
	id = "hyperscale",
	name = "Hyperscale",
	description = "Dispatch 1,000 compute jobs.",
	icon = "🚀",
	target = 1_000,
	getValue = function(_, jobs)
		return jobs
	end,
} }
-- ---------------------------------------------------------------------------
-- Day reward box
-- ---------------------------------------------------------------------------
local function DayBox(_param)
	local reward = _param.reward
	local claimed = _param.claimed
	local isToday = _param.isToday
	local bg = if claimed then Color3.fromRGB(14, 28, 20) elseif isToday then Color3.fromRGB(36, 28, 12) else C.recessed
	local border = if claimed then C.compute elseif isToday then C.energy else C.hairline
	local borderAlpha = if claimed then 0.35 elseif isToday then 0.3 else 0.72
	return React.createElement("frame", {
		key = `day{tostring(reward.day)}`,
		BackgroundColor3 = bg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	}), React.createElement("uistroke", {
		Color = border,
		Thickness = if isToday then 2 else 1,
		Transparency = borderAlpha,
	}), isToday and (React.createElement("frame", {
		key = "Glow",
		BackgroundColor3 = C.energy,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	}))), React.createElement("textlabel", {
		key = "DayNum",
		Text = `DAY {tostring(reward.day)}`,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = if isToday then C.energy else C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
	}), React.createElement("textlabel", {
		key = "Icon",
		Text = if claimed then "✓" else reward.icon,
		Font = Font.bold,
		TextSize = 24,
		TextColor3 = if claimed then C.compute elseif isToday then C.energy else C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
	}), React.createElement("textlabel", {
		key = "Label",
		Text = if claimed then "Claimed" else reward.label,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = if claimed then C.compute else C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -4, 0, 14),
		Position = UDim2.new(0, 2, 0, 60),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		ZIndex = 2,
	}))
end
-- ---------------------------------------------------------------------------
-- Achievement row
-- ---------------------------------------------------------------------------
local function AchievementRow(_param)
	local ach = _param.ach
	local value = _param.value
	local unlocked = _param.unlocked
	local layoutOrder = _param.layoutOrder
	local progress = math.clamp(value / ach.target, 0, 1)
	return React.createElement("frame", {
		key = ach.id,
		BackgroundColor3 = if unlocked then Color3.fromRGB(14, 24, 18) else C.card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 72),
		LayoutOrder = layoutOrder,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.card),
	}), React.createElement("uistroke", {
		Color = if unlocked then C.compute else C.hairline,
		Thickness = 1,
		Transparency = if unlocked then 0.4 else 0.72,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	}), React.createElement("textlabel", {
		key = "Icon",
		Text = ach.icon,
		Font = Font.bold,
		TextSize = 22,
		TextColor3 = if unlocked then C.compute else C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 14, 0.5, -18),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	}), React.createElement("textlabel", {
		key = "Name",
		Text = ach.name,
		Font = Font.bold,
		TextSize = Size.body,
		TextColor3 = if unlocked then C.textPrimary else C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -140, 0, 18),
		Position = UDim2.new(0, 58, 0, 12),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}), React.createElement("textlabel", {
		key = "Desc",
		Text = ach.description,
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -140, 0, 14),
		Position = UDim2.new(0, 58, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}), React.createElement("frame", {
		key = "PbarWrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -140, 0, 6),
		Position = UDim2.new(0, 58, 0, 52),
		ZIndex = 3,
	}, React.createElement(ProgressBar, {
		progress = progress,
		color = if unlocked then C.compute else C.accent,
		height = 4,
	})), React.createElement("textlabel", {
		key = "ProgText",
		Text = if unlocked then "✓ UNLOCKED" else `{fmt(math.min(value, ach.target))} / {fmt(ach.target)}`,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = if unlocked then C.compute else C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 110, 1, 0),
		Position = UDim2.new(1, -110, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
	}))
end
-- ---------------------------------------------------------------------------
-- Screen
-- ---------------------------------------------------------------------------
local function ScreenAllocations()
	local state = useGameState()
	local claimed = state.claimed or {}
	local achievements = state.achievements or {}
	-- Derive streak from claimed daily keys "daily_1" … "daily_7"
	local streak = 0
	for d = 1, 7 do
		local _arg0 = `daily_{tostring(d)}`
		if claimed[_arg0] == true then
			streak = d
		else
			break
		end
	end
	local todayIdx = streak
	local todayDay = math.min(streak + 1, 7)
	local _arg0 = `daily_{tostring(todayDay)}`
	local canClaim = not claimed[_arg0]
	local _exp = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 12),
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
		key = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = 0,
	}, React.createElement("textlabel", {
		Text = "DAILY ALLOCATION",
		Font = Font.bold,
		TextSize = Size.hero,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}))
	local _exp_3 = React.createElement("frame", {
		key = "StreakCard",
		BackgroundColor3 = Color3.fromRGB(28, 22, 10),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 90),
		LayoutOrder = 1,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.card),
	}), React.createElement("uistroke", {
		Color = C.energy,
		Thickness = 1,
		Transparency = 0.35,
	}), React.createElement("textlabel", {
		key = "Flame",
		Text = "🔥",
		Font = Font.bold,
		TextSize = 36,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 50, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}), React.createElement("textlabel", {
		key = "Count",
		Text = tostring(streak),
		Font = Font.bold,
		TextSize = 40,
		TextColor3 = C.energy,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 60, 0, 48),
		Position = UDim2.new(0, 74, 0, 21),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}), React.createElement("textlabel", {
		key = "StreakLabel",
		Text = "day streak",
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 80, 0, 16),
		Position = UDim2.new(0, 74, 0, 62),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}), React.createElement("textlabel", {
		key = "DayOf",
		Text = `Day {tostring(todayDay)} of 7`,
		Font = Font.mono,
		TextSize = Size.section,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 140, 0, 24),
		Position = UDim2.new(1, -156, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
	}), React.createElement("textlabel", {
		key = "NextLabel",
		Text = if streak >= 7 then "Full week complete!" else "Keep logging in daily",
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 160, 0, 16),
		Position = UDim2.new(1, -176, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
	}))
	local _exp_4 = React.createElement("uigridlayout", {
		CellSize = UDim2.new(1 / 7, -4, 1, 0),
		CellPadding = UDim2.new(0, 4, 0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		StartCorner = Enum.StartCorner.TopLeft,
		FillDirection = Enum.FillDirection.Horizontal,
	})
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#DAY_REWARDS)
	local _callback = function(r)
		local _arg0_1 = `daily_{tostring(r.day)}`
		local isClaimed = claimed[_arg0_1] == true
		local isToday = r.day == todayDay and not isClaimed
		return React.createElement(DayBox, {
			key = `day{tostring(r.day)}`,
			reward = r,
			claimed = isClaimed,
			isToday = isToday,
		})
	end
	for _k, _v in DAY_REWARDS do
		_newValue[_k] = _callback(_v, _k - 1, DAY_REWARDS)
	end
	-- ▲ ReadonlyArray.map ▲
	local _exp_5 = React.createElement("frame", {
		key = "DayGrid",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 90),
		LayoutOrder = 2,
	}, _exp_4, _newValue)
	local _exp_6 = React.createElement("frame", {
		key = "ClaimBtn",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = 3,
	}, React.createElement(Button, {
		label = if canClaim then `Claim Day {tostring(todayDay)} Reward` else "Already Claimed Today",
		onClick = function()
			if canClaim then
				act("claim")
			end
		end,
		variant = if canClaim then "amber" else "secondary",
		height = 44,
		disabled = not canClaim,
	}))
	local _exp_7 = React.createElement("textlabel", {
		Text = "ACHIEVEMENTS",
		Font = Font.bold,
		TextSize = Size.section,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.6, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local _attributes = {}
	-- ▼ ReadonlyArray.reduce ▼
	local _result = 0
	local _callback_1 = function(n, a)
		local _exp_8 = n
		local _id = a.id
		return _exp_8 + (if achievements[_id] then 1 else 0)
	end
	for _i = 1, #ACHIEVEMENTS do
		_result = _callback_1(_result, ACHIEVEMENTS[_i], _i - 1, ACHIEVEMENTS)
	end
	-- ▲ ReadonlyArray.reduce ▲
	_attributes.Text = `{tostring(_result)} / {tostring(#ACHIEVEMENTS)} unlocked`
	_attributes.Font = Font.mono
	_attributes.TextSize = Size.caption
	_attributes.TextColor3 = C.textMuted
	_attributes.BackgroundTransparency = 1
	_attributes.Size = UDim2.new(0.4, 0, 1, 0)
	_attributes.Position = UDim2.new(0.6, 0, 0, 0)
	_attributes.TextXAlignment = Enum.TextXAlignment.Right
	local _exp_8 = React.createElement("frame", {
		key = "AchHeader",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = 4,
	}, _exp_7, React.createElement("textlabel", _attributes))
	-- ▼ ReadonlyArray.map ▼
	local _newValue_1 = table.create(#ACHIEVEMENTS)
	local _callback_2 = function(ach, i)
		local _id = ach.id
		local unlocked = achievements[_id] == true
		local value = ach.getValue(state.compute, state.jobs, state.totalEarned)
		return React.createElement(AchievementRow, {
			key = ach.id,
			ach = ach,
			value = value,
			unlocked = unlocked,
			layoutOrder = 5 + i,
		})
	end
	for _k, _v in ACHIEVEMENTS do
		_newValue_1[_k] = _callback_2(_v, _k - 1, ACHIEVEMENTS)
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
	}, _exp, _exp_1, _exp_2, _exp_3, _exp_5, _exp_6, _exp_8, _newValue_1)
end
return {
	default = ScreenAllocations,
}
