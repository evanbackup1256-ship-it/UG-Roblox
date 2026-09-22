-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- ui/Card.tsx — Premium glassmorphic dark card
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local function Card(_param)
	local height = _param.height
	if height == nil then
		height = 120
	end
	local bgColor = _param.bgColor
	if bgColor == nil then
		bgColor = C.card
	end
	local children = _param.children
	local layoutOrder = _param.layoutOrder
	local zIndex = _param.zIndex
	if zIndex == nil then
		zIndex = 2
	end
	return React.createElement("frame", {
		BackgroundColor3 = bgColor,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = layoutOrder,
		ZIndex = zIndex,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.card),
	}), React.createElement("uistroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 0.88,
	}, React.createElement("uigradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.70), NumberSequenceKeypoint.new(1, 0.96) }),
	})), React.createElement("frame", {
		key = "TopBevel",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.90,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -16, 0, 1),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = zIndex + 1,
	}, React.createElement("uigradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
	})), React.createElement("imagelabel", {
		key = "Shadow",
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.55,
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		Size = UDim2.new(1, 28, 1, 28),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = zIndex - 1,
	}), children)
end
return {
	Card = Card,
}
