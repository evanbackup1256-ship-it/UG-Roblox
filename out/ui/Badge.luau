-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- ui/Badge.tsx — Semantic pill/label badge
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local Font = _theme.Font
local Size = _theme.Size
local STYLES = {
	default = {
		bg = C.elevated,
		text = C.textSecondary,
		stroke = C.hairline,
	},
	compute = {
		bg = Color3.fromRGB(16, 32, 24),
		text = C.compute,
		stroke = C.compute,
	},
	energy = {
		bg = Color3.fromRGB(36, 28, 12),
		text = C.energy,
		stroke = C.energy,
	},
	data = {
		bg = Color3.fromRGB(12, 28, 36),
		text = C.data,
		stroke = C.data,
	},
	reputation = {
		bg = Color3.fromRGB(24, 18, 38),
		text = C.reputation,
		stroke = C.reputation,
	},
	danger = {
		bg = Color3.fromRGB(36, 16, 16),
		text = C.danger,
		stroke = C.danger,
	},
	accent = {
		bg = Color3.fromRGB(18, 30, 48),
		text = C.accent,
		stroke = C.accent,
	},
}
local function Badge(_param)
	local label = _param.label
	local style = _param.style
	if style == nil then
		style = "default"
	end
	local pill = _param.pill
	if pill == nil then
		pill = false
	end
	local s = STYLES[style]
	return React.createElement("frame", {
		BackgroundColor3 = s.bg,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 84, 0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, if pill then R.pill else R.badge),
	}), React.createElement("uistroke", {
		Color = s.stroke,
		Thickness = 1,
		Transparency = 0.55,
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 3),
		PaddingBottom = UDim.new(0, 3),
	}), React.createElement("textlabel", {
		Text = string.upper(label),
		Font = Font.mono,
		TextSize = Size.micro,
		TextColor3 = s.text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.X,
	}))
end
return {
	Badge = Badge,
}
