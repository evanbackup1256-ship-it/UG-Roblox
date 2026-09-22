-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- ui/StatTile.tsx — Metric tile with bump-on-change animation
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local Font = _theme.Font
local Size = _theme.Size
local Card = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Card").Card
local ProgressBar = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "ProgressBar").ProgressBar
local BUMP_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local UNBUMP_INFO = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function StatTile(_param)
	local title = _param.title
	local subtitle = _param.subtitle
	local value = _param.value
	local color = _param.color
	local layoutOrder = _param.layoutOrder
	local progress = _param.progress
	local valRef = React.createRef()
	local prevValue = React.useRef(value)
	React.useEffect(function()
		if value ~= prevValue.current then
			prevValue.current = value
			local lbl = valRef.current
			if not lbl then
				return nil
			end
			local ts = game:GetService("TweenService")
			ts:Create(lbl, BUMP_INFO, {
				TextSize = Size.title + 4,
				TextColor3 = color,
			}):Play()
			task.delay(0.15, function()
				ts:Create(lbl, UNBUMP_INFO, {
					TextSize = Size.title,
					TextColor3 = C.textPrimary,
				}):Play()
			end)
		end
	end, { value })
	return React.createElement(Card, {
		height = if progress ~= nil then 112 else 98,
		layoutOrder = layoutOrder,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	}), React.createElement("textlabel", {
		key = "Title",
		Text = title,
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}), React.createElement("textlabel", {
		ref = valRef,
		key = "Value",
		Text = value,
		Font = Font.display,
		TextSize = Size.title,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	}), React.createElement("textlabel", {
		key = "Subtitle",
		Text = subtitle,
		Font = Font.body,
		TextSize = Size.micro,
		TextColor3 = color,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 3,
	}), progress ~= nil and (React.createElement("frame", {
		key = "BarWrap",
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
	}, React.createElement(ProgressBar, {
		progress = progress,
		color = color,
		height = 4,
	}))))
end
return {
	StatTile = StatTile,
}
