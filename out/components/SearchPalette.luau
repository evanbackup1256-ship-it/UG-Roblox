-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- components/SearchPalette.tsx — Command palette modal with keyboard navigation
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local UserInputService = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "services").UserInputService
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local Font = _theme.Font
local Size = _theme.Size
local SCREENS = { {
	id = "overview",
	label = "Overview",
	description = "Dashboard & live metrics",
	icon = "rbxassetid://7733765045",
}, {
	id = "operations",
	label = "Operations",
	description = "Dispatch compute jobs & missions",
	icon = "rbxassetid://7733765045",
}, {
	id = "infrastructure",
	label = "Infrastructure",
	description = "Buy & manage hardware tiers",
	icon = "rbxassetid://7733765045",
}, {
	id = "research",
	label = "Research",
	description = "Unlock technology upgrades",
	icon = "rbxassetid://7733765045",
}, {
	id = "modules",
	label = "Modules",
	description = "Equip active modifier cards",
	icon = "rbxassetid://7733765045",
}, {
	id = "contracts",
	label = "Contracts",
	description = "Accept & fulfil SLA contracts",
	icon = "rbxassetid://7733765045",
}, {
	id = "rewards",
	label = "Rewards",
	description = "Claim daily & milestone rewards",
	icon = "rbxassetid://7733765045",
}, {
	id = "shop",
	label = "Shop",
	description = "Premium items & boosters",
	icon = "rbxassetid://7733765045",
}, {
	id = "prestige",
	label = "Prestige",
	description = "Reset for permanent bonuses",
	icon = "rbxassetid://7733765045",
}, {
	id = "events",
	label = "Events",
	description = "Limited-time challenges",
	icon = "rbxassetid://7733765045",
}, {
	id = "leaderboard",
	label = "Leaderboard",
	description = "Global operator rankings",
	icon = "rbxassetid://7733765045",
}, {
	id = "settings",
	label = "Settings",
	description = "Audio, graphics & account",
	icon = "rbxassetid://7733765045",
} }
local ANIM_IN = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local ANIM_OUT = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local function highlightMatch(text, query)
	if query == "" then
		return true
	end
	return (string.find(string.lower(text), string.lower(query), 1, true)) ~= nil
end
local function SearchPalette(_param)
	local visible = _param.visible
	local onClose = _param.onClose
	local onNavigate = _param.onNavigate
	local query, setQuery = React.useState("")
	local selectedIdx, setSelectedIdx = React.useState(0)
	local paletteRef = React.createRef()
	local backdropRef = React.createRef()
	local inputRef = React.createRef()
	-- ▼ ReadonlyArray.filter ▼
	local _newValue = {}
	local _callback = function(s)
		return highlightMatch(s.label, query) or highlightMatch(s.description, query)
	end
	local _length = 0
	for _k, _v in SCREENS do
		if _callback(_v, _k - 1, SCREENS) == true then
			_length += 1
			_newValue[_length] = _v
		end
	end
	-- ▲ ReadonlyArray.filter ▲
	local filtered = _newValue
	-- Clamp selection when filter changes
	React.useEffect(function()
		if selectedIdx >= #filtered then
			setSelectedIdx(math.max(0, #filtered - 1))
		end
	end, { query })
	-- Animate in/out when visible changes
	React.useEffect(function()
		local palette = paletteRef.current
		local backdrop = backdropRef.current
		if not palette or not backdrop then
			return nil
		end
		local ts = game:GetService("TweenService")
		if visible then
			-- Reset to off position then tween in
			palette.Position = UDim2.new(0.5, 0, 0.35, 0)
			palette.BackgroundTransparency = 0
			backdrop.BackgroundTransparency = 0.45
			ts:Create(palette, ANIM_IN, {
				Position = UDim2.new(0.5, 0, 0.42, 0),
			}):Play()
			-- Focus text input
			task.delay(0.05, function()
				local box = inputRef.current
				if box then
					box:CaptureFocus()
				end
			end)
		else
			ts:Create(palette, ANIM_OUT, {
				Position = UDim2.new(0.5, 0, 0.35, 0),
				BackgroundTransparency = 1,
			}):Play()
			ts:Create(backdrop, ANIM_OUT, {
				BackgroundTransparency = 1,
			}):Play()
		end
	end, { visible })
	-- Keyboard navigation
	React.useEffect(function()
		local conn = UserInputService.InputBegan:Connect(function(input, gp)
			if not visible then
				return nil
			end
			if input.KeyCode == Enum.KeyCode.Escape then
				onClose()
				return nil
			end
			if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
				local sel = filtered[selectedIdx + 1]
				if sel then
					onNavigate(sel.id)
					onClose()
					setQuery("")
				end
				return nil
			end
			if input.KeyCode == Enum.KeyCode.Up then
				setSelectedIdx(function(prev)
					return math.max(0, prev - 1)
				end)
				return nil
			end
			if input.KeyCode == Enum.KeyCode.Down then
				setSelectedIdx(function(prev)
					return math.min(#filtered - 1, prev + 1)
				end)
				return nil
			end
		end)
		return function()
			return conn:Disconnect()
		end
	end, { visible, filtered, selectedIdx })
	-- Reset query on close
	React.useEffect(function()
		if not visible then
			setQuery("")
			setSelectedIdx(0)
		end
	end, { visible })
	local handleSelect = function(id)
		onNavigate(id)
		onClose()
		setQuery("")
	end
	if not visible then
		return React.createElement("frame", {
			Visible = false,
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
		})
	end
	local _exp = React.createElement("textbutton", {
		ref = backdropRef,
		key = "Backdrop",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = if visible then 0.45 else 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 51,
		Active = visible,
		Event = {
			Activated = onClose,
		},
	})
	local _exp_1 = React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.modal),
	})
	local _exp_2 = React.createElement("uistroke", {
		Color = C.hairline,
		Thickness = 1,
		Transparency = 0.3,
	})
	local _exp_3 = React.createElement("frame", {
		key = "TopBevel",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -20, 0, 1),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 53,
	}, React.createElement("uigradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
	}))
	local _exp_4 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
	})
	local _exp_5 = React.createElement("frame", {
		key = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 60),
		ZIndex = 53,
		LayoutOrder = 0,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
	}), React.createElement("imagelabel", {
		key = "SearchIcon",
		Image = "rbxassetid://7733765045",
		ImageColor3 = C.accent,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 54,
	}), React.createElement("textbox", {
		ref = inputRef,
		key = "QueryInput",
		PlaceholderText = "Search screens…",
		PlaceholderColor3 = C.textMuted,
		Text = query,
		Font = Font.body,
		TextSize = Size.section,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -56, 1, 0),
		Position = UDim2.new(0, 30, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 54,
		Change = {
			Text = function(rbx)
				return setQuery(rbx.Text)
			end,
		},
	}), React.createElement("frame", {
		key = "EscHint",
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 32, 0, 20),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ZIndex = 54,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.micro),
	}), React.createElement("uistroke", {
		Color = C.hairline,
		Thickness = 1,
		Transparency = 0.5,
	}), React.createElement("textlabel", {
		Text = "ESC",
		Font = Font.mono,
		TextSize = 9,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 55,
	})))
	local _exp_6 = React.createElement("frame", {
		key = "Divider",
		BackgroundColor3 = C.hairline,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 53,
		LayoutOrder = 1,
	})
	local _exp_7 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
	})
	local _exp_8 = React.createElement("uipadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	})
	local _exp_9 = #filtered == 0 and (React.createElement("frame", {
		key = "NoResults",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 52),
		ZIndex = 54,
	}, React.createElement("textlabel", {
		Text = "No screens match your query",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 55,
	})))
	-- ▼ ReadonlyArray.map ▼
	local _newValue_1 = table.create(#filtered)
	local _callback_1 = function(screen, idx)
		local isSelected = idx == selectedIdx
		return React.createElement("textbutton", {
			key = screen.id,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = if isSelected then Color3.fromRGB(59, 130, 246) else C.elevated,
			BackgroundTransparency = if isSelected then 0.78 else 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 52),
			ZIndex = 54,
			LayoutOrder = idx,
			Event = {
				Activated = function()
					return handleSelect(screen.id)
				end,
				MouseEnter = function()
					return setSelectedIdx(idx)
				end,
			},
		}, React.createElement("uipadding", {
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}), isSelected and (React.createElement("frame", {
			key = "SelectBar",
			BackgroundColor3 = Color3.fromRGB(59, 130, 246),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 3, 0.7, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ZIndex = 55,
		}, React.createElement("uicorner", {
			CornerRadius = UDim.new(0, R.pill),
		}))), React.createElement("uilistlayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
		}), React.createElement("imagelabel", {
			key = "Icon",
			Image = screen.icon,
			ImageColor3 = if isSelected then Color3.fromRGB(96, 165, 250) else C.textMuted,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 22, 0, 22),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 55,
		}), React.createElement("frame", {
			key = "TextCol",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -32, 1, 0),
			ZIndex = 55,
		}, React.createElement("uilistlayout", {
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
		}), React.createElement("textlabel", {
			key = "ScreenName",
			Text = screen.label,
			Font = Font.bold,
			TextSize = Size.body,
			TextColor3 = if isSelected then Color3.fromRGB(248, 250, 252) else C.textPrimary,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 56,
		}), React.createElement("textlabel", {
			key = "Desc",
			Text = screen.description,
			Font = Font.body,
			TextSize = Size.caption,
			TextColor3 = if isSelected then Color3.fromRGB(148, 163, 184) else C.textMuted,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 56,
		})), isSelected and (React.createElement("frame", {
			key = "EnterHint",
			BackgroundColor3 = C.recessed,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 40, 0, 20),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			ZIndex = 55,
		}, React.createElement("uicorner", {
			CornerRadius = UDim.new(0, R.micro),
		}), React.createElement("uistroke", {
			Color = Color3.fromRGB(59, 130, 246),
			Thickness = 1,
			Transparency = 0.55,
		}), React.createElement("textlabel", {
			Text = "↵",
			Font = Font.mono,
			TextSize = Size.caption,
			TextColor3 = Color3.fromRGB(96, 165, 250),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 56,
		}))))
	end
	for _k, _v in filtered do
		_newValue_1[_k] = _callback_1(_v, _k - 1, filtered)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("frame", {
		key = "SearchPaletteRoot",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 50,
		Visible = visible,
	}, _exp, React.createElement("frame", {
		ref = paletteRef,
		key = "Palette",
		BackgroundColor3 = C.elevated,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 540, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		ZIndex = 52,
		BackgroundTransparency = if visible then 0 else 1,
	}, _exp_1, _exp_2, _exp_3, _exp_4, _exp_5, _exp_6, React.createElement("scrollingframe", {
		key = "Results",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.hairline,
		CanvasSize = UDim2.new(0, 0, 0, #filtered * 52),
		Size = UDim2.new(1, 0, 0, math.min(#filtered, 7) * 52),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 53,
		LayoutOrder = 2,
	}, _exp_7, _exp_8, _exp_9, _newValue_1), React.createElement("frame", {
		key = "Footer",
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
		ZIndex = 53,
		LayoutOrder = 3,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.modal),
	}), React.createElement("frame", {
		key = "HintRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 54,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 16),
	}), React.createElement("textlabel", {
		key = "NavHint",
		Text = "↑↓  navigate",
		Font = Font.mono,
		TextSize = 9,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 55,
	}), React.createElement("textlabel", {
		key = "SelectHint",
		Text = "↵  select",
		Font = Font.mono,
		TextSize = 9,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 55,
	}), React.createElement("textlabel", {
		key = "CloseHint",
		Text = "ESC  close",
		Font = Font.mono,
		TextSize = 9,
		TextColor3 = C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 55,
	})))))
end
return {
	default = SearchPalette,
}
