--!strict
-- Elements: Core visual primitives for the App architecture
local Theme = require(script.Parent.Theme)
local Springs = require(script.Parent.Springs)
local Icons = require(script.Parent.Parent.Icons)

local C = Theme.colors
local Elements = {}

function Elements.create(className: string, parent: Instance?, properties: { [string]: any }?): any
	local instance = Instance.new(className)
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		instance.ResampleMode = Enum.ResamplerMode.Default
		instance.ScaleType = Enum.ScaleType.Fit
	end
	if properties then
		for prop, val in properties do
			if prop == "Font" and typeof(val) == "Font" then
				(instance :: any).FontFace = val
			elseif prop == "FontFace" and typeof(val) == "EnumItem" then
				(instance :: any).Font = val
			else
				pcall(function() (instance :: any)[prop] = val end)
			end
		end
	end
	
	if parent then
		instance.Parent = parent
	end
	
	return instance
end

function Elements.corner(instance: Instance, radius: number?): UICorner
	local existing = instance:FindFirstChildOfClass("UICorner")
	if existing then
		existing.CornerRadius = UDim.new(0, radius or Theme.radii.control)
		return existing
	end
	return Elements.create("UICorner", instance, {
		CornerRadius = UDim.new(0, radius or Theme.radii.control),
	})
end

function Elements.stroke(instance: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	local existing = instance:FindFirstChildOfClass("UIStroke")
	if existing then
		existing.Color = color or C.hairline
		existing.Thickness = thickness or Theme.hairlines.thickness
		existing.Transparency = transparency or Theme.hairlines.restTransparency
		existing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		return existing
	end
	return Elements.create("UIStroke", instance, {
		Color = color or C.hairline,
		Thickness = thickness or Theme.hairlines.thickness,
		Transparency = transparency or Theme.hairlines.restTransparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Elements.card(parent: Instance, name: string, height: number?, bgCol: Color3?): Frame
	local frame = Elements.create("Frame", parent, {
		Name = name,
		BackgroundColor3 = bgCol or C.card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height or 80),
		ZIndex = 10,
	})

	Elements.corner(frame, Theme.radii.card)
	
	-- Ambient subtle noise texture for realism
	Elements.create("ImageLabel", frame, {
		Name = "Noise",
		Image = "rbxassetid://16124706509", -- Premium subtle noise grain
		ImageTransparency = 0.95,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(256, 256),
		ZIndex = 11,
	})
	
	-- Glassmorphic ambient light gradient
	Elements.create("UIGradient", frame, {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 0.8))
		}),
		Rotation = 45,
	})

	local shadowCfg = Theme.shadows.card
	local shadow = Elements.create("ImageLabel", frame, {
		Name = "DropShadow",
		Image = "rbxassetid://1316045217", -- High fidelity smooth shadow 9-slice
		ImageColor3 = shadowCfg.color,
		ImageTransparency = shadowCfg.transparency,
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		Size = UDim2.new(1, shadowCfg.size * 2, 1, shadowCfg.size * 2),
		Position = UDim2.new(0.5, shadowCfg.offset.X, 0.5, shadowCfg.offset.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 9,
	})

	-- Beautiful glowing top edge
	local topGlow = Elements.create("Frame", frame, {
		Name = "TopGlow",
		Size = UDim2.new(1, -12, 0, 1),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		ZIndex = 12,
	})
	Elements.create("UIGradient", topGlow, {
		Transparency = ColorSequence.new({
			ColorSequenceKeypoint.new(0, 1),
			ColorSequenceKeypoint.new(0.5, 0),
			ColorSequenceKeypoint.new(1, 1)
		})
	})

	local stroke = Elements.stroke(frame, Theme.hairlines.bevelColor, 1, Theme.hairlines.bevelTransparency)
	Elements.create("UIGradient", stroke, {
		Rotation = 90,
		Transparency = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.hairlines.hoverTransparency),
			ColorSequenceKeypoint.new(1, Theme.hairlines.restTransparency)
		})
	})

	return frame
end

function Elements.interactiveCard(parent: Instance, name: string, height: number?, color: Color3?): Frame
	local card = Elements.card(parent, name, height, color)
	card.Active = true
	return card
end

function Elements.recessedWell(parent: Instance, name: string, height: number?): Frame
	local well = Elements.create("Frame", parent, {
		Name = name,
		Size = UDim2.new(1, 0, 0, height or 40),
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
	})
	Elements.corner(well, Theme.radii.control)
	Elements.stroke(well, C.hairlineSubtle, 1, 0.85)
	return well
end

function Elements.badge(parent: Instance, text: string, style: string?, pill: boolean?): Frame
	local bgCol = C.elevated
	local txtCol = C.textSecondary
	local strokeCol = C.hairline

	if style == "accent" or style == "compute" then
		bgCol = Color3.fromRGB(16, 32, 24)
		txtCol = C.compute
		strokeCol = C.compute
	elseif style == "energy" or style == "warning" then
		bgCol = Color3.fromRGB(36, 28, 12)
		txtCol = C.energy
		strokeCol = C.energy
	elseif style == "danger" or style == "error" then
		bgCol = Color3.fromRGB(36, 16, 16)
		txtCol = C.danger
		strokeCol = C.danger
	elseif style == "data" then
		bgCol = Color3.fromRGB(12, 28, 36)
		txtCol = C.data
		strokeCol = C.data
	elseif style == "reputation" then
		bgCol = Color3.fromRGB(24, 18, 38)
		txtCol = C.reputation
		strokeCol = C.reputation
	end

	local badgeFrame = Elements.create("Frame", parent, {
		Name = "Badge",
		BackgroundColor3 = bgCol,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(80, 22),
	})
	Elements.corner(badgeFrame, if pill then Theme.radii.pill else Theme.radii.badge)
	Elements.stroke(badgeFrame, strokeCol, 1, 0.70)

	local label = Elements.create("TextLabel", badgeFrame, {
		Name = "BadgeText",
		Text = string.upper(text),
		Font = Theme.typography.fontMono,
		TextSize = Theme.typography.sizeMicro,
		TextColor3 = txtCol,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	return badgeFrame
end

local function resolveDotColor(val: any): Color3
	if typeof(val) == "Color3" then
		return val
	elseif type(val) == "string" then
		local s = string.lower(val)
		if s == "mint" or s == "green" or s == "compute" or s == "success" then
			return C.compute or Color3.fromRGB(16, 185, 129)
		elseif s == "amber" or s == "energy" or s == "gold" or s == "warning" then
			return C.energy or Color3.fromRGB(245, 158, 11)
		elseif s == "azure" or s == "accent" or s == "blue" then
			return C.accent or Color3.fromRGB(59, 130, 246)
		elseif s == "danger" or s == "error" or s == "red" then
			return C.danger or Color3.fromRGB(239, 68, 68)
		elseif s == "cyan" or s == "data" then
			return C.data or Color3.fromRGB(6, 182, 212)
		end
	end
	return C.accent
end

function Elements.statusDot(parent: Instance, arg2: any?, arg3: any?, arg4: any?): Frame
	local dotName = "StatusDot"
	local dotColor: Color3
	local labelText: string? = nil
	local dotSize: number = 8

	if typeof(arg2) == "Color3" then
		dotColor = arg2
		if type(arg3) == "string" then labelText = arg3 end
		if type(arg4) == "number" then dotSize = arg4 end
	elseif type(arg2) == "string" and (typeof(arg3) == "Color3" or (type(arg3) == "string" and arg3 ~= "")) then
		dotName = arg2
		dotColor = resolveDotColor(arg3)
		if type(arg4) == "number" then dotSize = arg4 end
	elseif type(arg2) == "string" then
		dotColor = resolveDotColor(arg2)
		if type(arg3) == "string" then labelText = arg3 end
		if type(arg4) == "number" then dotSize = arg4 end
	else
		dotColor = C.accent
	end

	local container = Elements.create("Frame", parent, {
		Name = dotName,
		Size = UDim2.fromOffset(if labelText then 80 else dotSize, dotSize),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	local dot = Elements.create("Frame", container, {
		Name = "Dot",
		Size = UDim2.fromOffset(dotSize, dotSize),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = dotColor,
		BorderSizePixel = 0,
	})
	Elements.corner(dot, Theme.radii.pill)

	local halo = Elements.create("UIStroke", dot, {
		Name = "Halo",
		Color = dotColor,
		Thickness = 1,
		Transparency = 0.5,
	})

	dot:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		halo.Color = dot.BackgroundColor3
	end)

	if labelText and labelText ~= "" then
		Elements.create("TextLabel", container, {
			Name = "Label",
			Text = labelText,
			Font = Theme.typography.fontMono,
			TextSize = Theme.typography.sizeMicro,
			TextColor3 = C.textMuted,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, dotSize + 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(1, -(dotSize + 6), 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	return container
end

function Elements.divider(parent: Instance, isHorizontal: boolean?): Frame
	if isHorizontal == false then
		return Elements.create("Frame", parent, {
			Name = "DividerV",
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = C.hairlineSubtle,
			BorderSizePixel = 0,
		})
	end
	return Elements.create("Frame", parent, {
		Name = "DividerH",
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.hairlineSubtle,
		BorderSizePixel = 0,
	})
end

function Elements.icon(parent: Instance, name: string, iconKey: string, color: Color3?): ImageLabel
	local iconId = if type(Icons.resolve) == "function" then Icons.resolve(iconKey)
		elseif type(Icons.asset) == "function" then Icons.asset(iconKey)
		else "rbxassetid://7733765045"
	return Elements.create("ImageLabel", parent, {
		Name = name,
		Image = iconId,
		ImageColor3 = color or C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 20),
		ScaleType = Enum.ScaleType.Fit,
		ResampleMode = Enum.ResamplerMode.Default,
		ZIndex = 2,
	})
end

function Elements.rocketIcon(parent: Instance, name: string, color: Color3?): Frame
	local shell = Elements.create("Frame", parent, {
		Name = name,
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		ZIndex = 2,
	})
	local icon = Elements.icon(shell, "RocketImg", "operations", color or C.energy)
	icon.Size = UDim2.fromScale(1, 1)
	return shell
end

function Elements.tintIcon(iconImg: ImageLabel, color: Color3)
	iconImg.ImageColor3 = color
end

function Elements.text(parent: Instance, name: string, content: string, size: number?, color: Color3?, bold: boolean?): TextLabel
	return Elements.create("TextLabel", parent, {
		Name = name,
		Text = content,
		Font = if bold then Theme.typography.fontBold else Theme.typography.fontBody,
		TextSize = size or Theme.typography.sizeBody,
		TextColor3 = color or C.textPrimary,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutoLocalize = false,
		RichText = false,
		ZIndex = 2,
	})
end

function Elements.place(instance: GuiObject, x: number, y: number, width: number, height: number)
	local rx = math.round(x)
	local ry = math.round(y)
	local rw = math.max(0, math.round(width))
	local rh = math.max(0, math.round(height))

	local parent = instance.Parent
	if not parent or not parent:IsA("GuiObject") or parent.AbsoluteSize.X == 0 or parent.AbsoluteSize.Y == 0 then
		instance.Size = UDim2.fromOffset(rw, rh)
		instance.Position = UDim2.fromOffset(
			math.round(rx + rw * instance.AnchorPoint.X),
			math.round(ry + rh * instance.AnchorPoint.Y)
		)
		return
	end

	local pw = parent.AbsoluteSize.X
	local ph = parent.AbsoluteSize.Y

	instance.Size = UDim2.fromScale(rw / pw, rh / ph)
	instance.Position = UDim2.fromScale(
		(rx + rw * instance.AnchorPoint.X) / pw,
		(ry + rh * instance.AnchorPoint.Y) / ph
	)
	
	-- Keep aspect ratio locked to prevent vertical squish/stretch during container resizes
	local constraint = instance:FindFirstChildOfClass("UIAspectRatioConstraint")
	if not constraint and rw > 0 and rh > 0 then
		constraint = Instance.new("UIAspectRatioConstraint")
		constraint.AspectRatio = rw / rh
		constraint.AspectType = Enum.AspectType.FitWithinMaxSize
		constraint.DominantAxis = Enum.DominantAxis.Width
		constraint.Parent = instance
	end
end

return Elements

