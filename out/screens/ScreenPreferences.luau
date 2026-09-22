-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenPreferences.tsx — Settings & System Preferences
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local Font = _theme.Font
local Size = _theme.Size
local Card = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Card").Card
local Button = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Button").Button
local Badge = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Badge").Badge
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local act = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store").act
local function ScreenPreferences()
	local gs = useGameState()
	local sfx, setSfx = React.useState(true)
	local music, setMusic = React.useState(true)
	local motion, setMotion = React.useState(true)
	local notifications, setNotifications = React.useState(true)
	local selectedTheme, setSelectedTheme = React.useState("azure")
	local themes = { {
		id = "azure",
		name = "Azure",
		color = Color3.fromRGB(59, 130, 246),
	}, {
		id = "mint",
		name = "Mint",
		color = Color3.fromRGB(16, 185, 129),
	}, {
		id = "amber",
		name = "Amber",
		color = Color3.fromRGB(245, 158, 11),
	}, {
		id = "purple",
		name = "Iris",
		color = Color3.fromRGB(139, 92, 246),
	}, {
		id = "rose",
		name = "Rose",
		color = Color3.fromRGB(244, 63, 94),
	} }
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
		Text = "SYSTEM PREFERENCES",
		Font = Font.bold,
		TextSize = Size.title,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Badge, {
		label = "CONFIG",
		style = "accent",
		pill = true,
	})), React.createElement("textlabel", {
		Text = "Custom acoustic parameters, kinetic springs, and visual display palettes.",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
	})))
	local _exp_3 = React.createElement(Card, {
		height = 140,
		layoutOrder = 2,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 12),
	}), React.createElement("textlabel", {
		Text = "ACOUSTIC EMISSIONS",
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.accent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
	}, React.createElement("textlabel", {
		Text = "Sound Effects (SFX)",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Button, {
		label = if sfx then "ENABLED" else "MUTED",
		variant = if sfx then "success" else "secondary",
		width = 100,
		height = 32,
		onClick = function()
			return setSfx(not sfx)
		end,
	})), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
	}, React.createElement("textlabel", {
		Text = "Ambient Synthesis Track",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Button, {
		label = if music then "ENABLED" else "MUTED",
		variant = if music then "success" else "secondary",
		width = 100,
		height = 32,
		onClick = function()
			return setMusic(not music)
		end,
	})))
	local _exp_4 = React.createElement(Card, {
		height = 140,
		layoutOrder = 3,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 12),
	}), React.createElement("textlabel", {
		Text = "PHYSICAL INTERACTION & KINETICS",
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.accent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
	}, React.createElement("textlabel", {
		Text = "Kinetic Animations & Motion",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Button, {
		label = if motion then "FLUID" else "STATIC",
		variant = if motion then "primary" else "secondary",
		width = 100,
		height = 32,
		onClick = function()
			return setMotion(not motion)
		end,
	})), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
	}, React.createElement("textlabel", {
		Text = "Mission Status Notifications",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Button, {
		label = if notifications then "ACTIVE" else "OFF",
		variant = if notifications then "primary" else "secondary",
		width = 100,
		height = 32,
		onClick = function()
			return setNotifications(not notifications)
		end,
	})))
	local _exp_5 = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	})
	local _exp_6 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 12),
	})
	local _exp_7 = React.createElement("textlabel", {
		Text = "INTERACTION ACCENT THEME",
		Font = Font.mono,
		TextSize = Size.caption,
		TextColor3 = C.accent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local _exp_8 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 12),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#themes)
	local _callback = function(t)
		return React.createElement(Button, {
			key = t.id,
			label = t.name,
			variant = if selectedTheme == t.id then "primary" else "secondary",
			width = 90,
			height = 36,
			onClick = function()
				return setSelectedTheme(t.id)
			end,
		})
	end
	for _k, _v in themes do
		_newValue[_k] = _callback(_v, _k - 1, themes)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("scrollingframe", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.hairline,
		CanvasSize = UDim2.new(0, 0, 0, 800),
	}, _exp, _exp_1, _exp_2, _exp_3, _exp_4, React.createElement(Card, {
		height = 130,
		layoutOrder = 4,
	}, _exp_5, _exp_6, _exp_7, React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
	}, _exp_8, _newValue)), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
	}, React.createElement(Button, {
		label = "Save Changes & Commit",
		variant = "primary",
		height = 44,
		onClick = function()
			return act("savePreferences", {
				sfx = sfx,
				music = music,
				motion = motion,
				notifications = notifications,
				theme = selectedTheme,
			})
		end,
	})))
end
return {
	default = ScreenPreferences,
}
