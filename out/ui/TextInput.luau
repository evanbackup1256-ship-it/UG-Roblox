-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- ui/TextInput.tsx — Styled search input with clear button
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local Font = _theme.Font
local Size = _theme.Size
local function TextInput(_param)
	local placeholder = _param.placeholder
	if placeholder == nil then
		placeholder = "Search…"
	end
	local onChange = _param.onChange
	local layoutOrder = _param.layoutOrder
	local focused, setFocused = React.useState(false)
	local ref = React.createRef()
	return React.createElement("frame", {
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = layoutOrder,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	}), React.createElement("uistroke", {
		Color = if focused then C.accent else C.hairline,
		Thickness = 1,
		Transparency = if focused then 0.3 else 0.65,
	}), React.createElement("imagelabel", {
		key = "SearchIco",
		Image = "rbxassetid://7733765045",
		ImageColor3 = if focused then C.accent else C.textMuted,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ScaleType = Enum.ScaleType.Fit,
	}), React.createElement("textbox", {
		ref = ref,
		key = "Input",
		PlaceholderText = placeholder,
		PlaceholderColor3 = C.textMuted,
		Text = "",
		Font = Font.body,
		TextSize = Size.body,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -36, 1, 0),
		Position = UDim2.new(0, 32, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Event = {
			Focused = function()
				return setFocused(true)
			end,
			FocusLost = function()
				return setFocused(false)
			end,
		},
		Change = {
			Text = function(rbx)
				return onChange(rbx.Text)
			end,
		},
	}))
end
return {
	TextInput = TextInput,
}
