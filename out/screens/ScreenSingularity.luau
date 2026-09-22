-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenSingularity.tsx — Quantum Relaunch & Prestige Mechanics
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
local function ScreenSingularity()
	local gs = useGameState()
	local confirmState, setConfirmState = React.useState(false)
	local _condition = gs.prestigeTokens
	if _condition == nil then
		_condition = 0
	end
	local currentTokens = _condition
	-- Calculate projected tokens based on total compute earned
	local _condition_1 = gs.totalEarned
	if _condition_1 == nil then
		_condition_1 = gs.compute
		if _condition_1 == nil then
			_condition_1 = 0
		end
	end
	local totalCompute = _condition_1
	local potentialTokens = math.max(0, math.floor(math.sqrt(totalCompute / 1000000)) - currentTokens)
	local bonusPct = (currentTokens + potentialTokens) * 10
	local handlePrestigeClick = function()
		if not confirmState then
			setConfirmState(true)
			task.delay(4, function()
				setConfirmState(false)
			end)
		else
			act("prestige")
			setConfirmState(false)
		end
	end
	return React.createElement("scrollingframe", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.hairline,
		CanvasSize = UDim2.new(0, 0, 0, 750),
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 24),
		PaddingRight = UDim.new(0, 24),
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 40),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}), React.createElement(Card, {
		height = 240,
		bgColor = Color3.fromRGB(32, 14, 20),
		layoutOrder = 1,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 24),
		PaddingRight = UDim.new(0, 24),
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 20),
	}), React.createElement("frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 8),
	}), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
	}, React.createElement("textlabel", {
		Text = "QUANTUM SINGULARITY RELAUNCH",
		Font = Font.bold,
		TextSize = Size.title,
		TextColor3 = C.danger,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Badge, {
		label = "HIGH VOLTAGE",
		style = "danger",
		pill = true,
	})), React.createElement("textlabel", {
		Text = "Initiating a singularity collapses current server infrastructure and raw compute reserves into ultra-dense Quantum Tokens.",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("textlabel", {
		Text = "⚠️ WARNING: All server hardware and current compute will be dissolved. Research and achievements remain permanent.",
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.warning,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
	}, React.createElement(Button, {
		label = if confirmState then "⚠️ CONFIRM SINGULARITY — IRREVERSIBLE ACTION" else `Initiate Collapse (+{fmt(potentialTokens)} Quantum Tokens)`,
		variant = "danger",
		height = 46,
		disabled = potentialTokens <= 0 and not confirmState,
		onClick = handlePrestigeClick,
	})))), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 130),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	}, React.createElement("uigridlayout", {
		CellSize = UDim2.new(0.485, 0, 0, 120),
		CellPadding = UDim2.new(0.03, 0, 0, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}), React.createElement(Card, {
		height = 120,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18),
		PaddingTop = UDim.new(0, 16),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
	}), React.createElement("textlabel", {
		Text = "CURRENT QUANTUM RESERVE",
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
	}), React.createElement("textlabel", {
		Text = `{fmt(currentTokens)} Tokens`,
		Font = Font.display,
		TextSize = Size.hero,
		TextColor3 = C.reputation,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
	}), React.createElement("textlabel", {
		Text = `Current Global Bonus: +{currentTokens * 10}%`,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.compute,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
	})), React.createElement(Card, {
		height = 120,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18),
		PaddingTop = UDim.new(0, 16),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
	}), React.createElement("textlabel", {
		Text = "PROJECTED POST-COLLAPSE BONUS",
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
	}), React.createElement("textlabel", {
		Text = `+{bonusPct}% Multiplier`,
		Font = Font.display,
		TextSize = Size.hero,
		TextColor3 = C.gold,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
	}), React.createElement("textlabel", {
		Text = `Yield Acceleration Factor: ×{string.format("%.1f", 1 + bonusPct / 100)}`,
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = C.gold,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
	}))))
end
return {
	default = ScreenSingularity,
}
