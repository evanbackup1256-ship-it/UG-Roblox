-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- ui/ProgressBar.tsx — Animated progress bar with TweenService fill
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local function ProgressBar(_param)
	local progress = _param.progress
	local color = _param.color
	if color == nil then
		color = C.accent
	end
	local height = _param.height
	if height == nil then
		height = 6
	end
	local glow = _param.glow
	if glow == nil then
		glow = false
	end
	local fillRef = React.createRef()
	local clamp = math.clamp(progress, 0, 1)
	React.useEffect(function()
		local fill = fillRef.current
		if not fill then
			return nil
		end
		game:GetService("TweenService"):Create(fill, TWEEN, {
			Size = UDim2.new(clamp, 0, 1, 0),
		}):Play()
	end, { clamp })
	return React.createElement("frame", {
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height),
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), React.createElement("frame", {
		ref = fillRef,
		key = "Fill",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(clamp, 0, 1, 0),
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.pill),
	}), glow and (React.createElement("uistroke", {
		Color = color,
		Thickness = 2,
		Transparency = 0.5,
	}))))
end
return {
	ProgressBar = ProgressBar,
}
