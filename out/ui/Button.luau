-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- ui/Button.tsx — TweenService-animated button with three variants
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local R = _theme.R
local Font = _theme.Font
local Size = _theme.Size
local VARIANTS = {
	primary = {
		bg = Color3.fromRGB(59, 130, 246),
		bgHover = Color3.fromRGB(37, 99, 235),
		bgPress = Color3.fromRGB(29, 78, 216),
		text = Color3.fromRGB(255, 255, 255),
		stroke = Color3.fromRGB(96, 165, 250),
	},
	secondary = {
		bg = Color3.fromRGB(26, 30, 42),
		bgHover = Color3.fromRGB(34, 40, 56),
		bgPress = Color3.fromRGB(20, 24, 34),
		text = Color3.fromRGB(248, 250, 252),
		stroke = Color3.fromRGB(44, 55, 74),
	},
	danger = {
		bg = Color3.fromRGB(239, 68, 68),
		bgHover = Color3.fromRGB(220, 38, 38),
		bgPress = Color3.fromRGB(185, 28, 28),
		text = Color3.fromRGB(255, 255, 255),
		stroke = Color3.fromRGB(252, 165, 165),
	},
	success = {
		bg = Color3.fromRGB(16, 185, 129),
		bgHover = Color3.fromRGB(5, 150, 105),
		bgPress = Color3.fromRGB(4, 120, 87),
		text = Color3.fromRGB(255, 255, 255),
		stroke = Color3.fromRGB(110, 231, 183),
	},
	amber = {
		bg = Color3.fromRGB(245, 158, 11),
		bgHover = Color3.fromRGB(217, 119, 6),
		bgPress = Color3.fromRGB(180, 83, 9),
		text = Color3.fromRGB(24, 16, 6),
		stroke = Color3.fromRGB(251, 191, 36),
	},
}
local PRESS_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOVER_INFO = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function Button(_param)
	local label = _param.label
	local onClick = _param.onClick
	local variant = _param.variant
	if variant == nil then
		variant = "primary"
	end
	local width = _param.width
	local height = _param.height
	if height == nil then
		height = 40
	end
	local disabled = _param.disabled
	if disabled == nil then
		disabled = false
	end
	local layoutOrder = _param.layoutOrder
	local v = VARIANTS[variant]
	local ref = React.createRef()
	local tween = function(obj, info, props)
		game:GetService("TweenService"):Create(obj, info, props):Play()
	end
	return React.createElement("textbutton", {
		ref = ref,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = v.bg,
		BorderSizePixel = 0,
		Size = if width ~= 0 and width == width and width then UDim2.new(0, width, 0, height) else UDim2.new(1, 0, 0, height),
		LayoutOrder = layoutOrder,
		Active = not disabled,
		BackgroundTransparency = if disabled then 0.4 else 0,
		Event = {
			MouseEnter = function()
				local btn = ref.current
				if not btn or disabled then
					return nil
				end
				tween(btn, HOVER_INFO, {
					BackgroundColor3 = v.bgHover,
				})
			end,
			MouseLeave = function()
				local btn = ref.current
				if not btn or disabled then
					return nil
				end
				tween(btn, HOVER_INFO, {
					BackgroundColor3 = v.bg,
				})
			end,
			MouseButton1Down = function()
				local btn = ref.current
				if not btn or disabled then
					return nil
				end
				tween(btn, PRESS_INFO, {
					BackgroundColor3 = v.bgPress,
					Size = UDim2.new(1, 0, 0, height - 2),
				})
			end,
			MouseButton1Up = function()
				local btn = ref.current
				if not btn or disabled then
					return nil
				end
				local _object = {
					BackgroundColor3 = v.bgHover,
				}
				local _left = "Size"
				local _exp = if width ~= 0 and width == width and width then 0 else 1
				local _condition = width
				if _condition == nil then
					_condition = 0
				end
				_object[_left] = UDim2.new(_exp, _condition, 0, height)
				tween(btn, RELEASE_INFO, _object)
			end,
			Activated = function()
				if not disabled then
					onClick()
				end
			end,
		},
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	}), React.createElement("uistroke", {
		Color = v.stroke,
		Thickness = 1,
		Transparency = 0.65,
	}), React.createElement("textlabel", {
		Text = label,
		Font = Font.bold,
		TextSize = Size.body,
		TextColor3 = v.text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}))
end
return {
	Button = Button,
}
