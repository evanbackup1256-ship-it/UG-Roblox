--!strict
-- Feedback: Visual micro-interactions, floating rewards, ambient glow, and particle cues
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local Springs = require(script.Parent.Springs)
local Elements = require(script.Parent.Elements)

local C = Theme.colors
local Feedback = {}

-- Safely converts either Vector2 or UDim2 or nil into a valid UDim2 position
local function toUDim2(pos: any): UDim2
	if typeof(pos) == "UDim2" then
		return pos
	elseif typeof(pos) == "Vector2" then
		return UDim2.new(pos.X, 0, pos.Y, 0)
	end
	return UDim2.fromScale(0.5, 0.45)
end

-- Drifting floating text on user action / reward (e.g. "+50 COMPUTE", "DEPLOYED!")
function Feedback.floatText(parent: Instance, text: string, color: Color3?, startPos: (UDim2 | Vector2)?)
	if not Springs.motionEnabled then return end

	local safePos = toUDim2(startPos)
	local txtColor = color or C.accent

	local label = Elements.create("TextLabel", parent, {
		Name = "FloatText",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = safePos,
		Size = UDim2.fromOffset(240, 26),
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.typography.fontBold,
		TextSize = 14,
		TextColor3 = txtColor,
		TextStrokeColor3 = C.canvas,
		TextStrokeTransparency = 0.3,
		ZIndex = 25,
	})

	local targetPos = UDim2.new(safePos.X.Scale, safePos.X.Offset, safePos.Y.Scale, safePos.Y.Offset - 36)
	local driftTween = TweenService:Create(label, TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = targetPos,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})

	driftTween.Completed:Connect(function()
		label:Destroy()
	end)
	driftTween:Play()
end

-- Tactile micro-flash on numbers or metrics when updated (zero raster blur)
function Feedback.bump(instance: GuiObject, peakScale: number?)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		local baseColor = instance.TextColor3
		local highlightColor = Color3.fromRGB(255, 255, 255)
		return function()
			if not Springs.motionEnabled then return end
			instance.TextColor3 = highlightColor
			Springs.target(instance, { TextColor3 = baseColor }, "smooth")
		end
	else
		local scale = instance:FindFirstChildOfClass("UIScale")
		if not scale then
			scale = Elements.create("UIScale", instance, { Name = "BumpScale", Scale = 1 })
		end

		return function()
			if not Springs.motionEnabled then return end
			scale.Scale = peakScale or 1.06
			Springs.target(scale, { Scale = 1.0 }, "bouncy")
		end
	end
end

-- Celebratory confetti particle burst
function Feedback.confetti(parent: Instance, color: Color3?)
	if not Springs.motionEnabled then return end
	local burstColor = color or C.accent

	local emitter = Elements.create("Frame", parent, {
		Name = "ConfettiBurst",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 20,
	})

	local rng = Random.new()
	for _ = 1, 12 do
		local particle = Elements.create("Frame", emitter, {
			Size = UDim2.fromOffset(rng:NextInteger(4, 7), rng:NextInteger(4, 7)),
			BackgroundColor3 = if rng:NextNumber() > 0.5 then burstColor else C.accent2,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0),
		})
		Elements.corner(particle, Theme.radii.pill)

		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(25, 60)
		local targetOffset = Vector2.new(math.cos(angle) * distance, math.sin(angle) * distance)

		local tween = TweenService:Create(particle, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(targetOffset.X, targetOffset.Y),
			BackgroundTransparency = 1,
		})
		tween:Play()
	end

	task.delay(0.6, function()
		emitter:Destroy()
	end)
end

-- Ambient breathing glow stroke for ready items (e.g. daily reward ready, prestige ready)
function Feedback.ambientGlow(card: GuiObject, options: { color: Color3? }?)
	local oldStroke = card:FindFirstChild("AmbientGlow")
	if oldStroke then
		oldStroke:Destroy()
	end

	local glowColor = (options and options.color) or C.accent
	local stroke = Elements.create("UIStroke", card, {
		Name = "AmbientGlow",
		Color = glowColor,
		Thickness = 1.5,
		Transparency = 0.8,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	local active = true
	local currentTween: Tween? = nil

	local function pulse()
		if not active or not card.Parent or not stroke.Parent then return end
		local t1 = TweenService:Create(stroke, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = 0.25,
		})
		currentTween = t1
		t1.Completed:Connect(function()
			if not active or not card.Parent or not stroke.Parent then return end
			local t2 = TweenService:Create(stroke, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.85,
			})
			currentTween = t2
			t2.Completed:Connect(pulse)
			t2:Play()
		end)
		t1:Play()
	end

	pulse()

	return {
		stop = function()
			active = false
			if currentTween then
				pcall(function() currentTween:Cancel() end)
			end
			if stroke and stroke.Parent then
				stroke:Destroy()
			end
		end,
	}
end

-- Lock/unlock visual state for cards
function Feedback.lock(card: GuiObject, isLocked: boolean, button: GuiButton?)
	local stroke = card:FindFirstChildOfClass("UIStroke")
	if isLocked then
		card.BackgroundTransparency = 0.35
		if stroke then
			stroke.Transparency = 0.90
		end
		if button then
			button.Active = false
		end
	else
		card.BackgroundTransparency = 0
		if stroke then
			stroke.Transparency = Theme.hairlines.restTransparency
		end
		if button then
			button.Active = true
		end
	end
end

-- Skeleton shimmer: a subtle satin light beam that sweeps across a card/container
function Feedback.shimmer(instance: GuiObject, options: { speed: number?, color: Color3?, delay: number?, intensity: number?, angle: number? }?): () -> ()
	if not Springs.motionEnabled then
		return function() end
	end

	local sheenColor = (options and options.color) or Color3.fromRGB(255, 255, 255)
	local speed = (options and options.speed) or 2.2
	local repeatDelay = (options and options.delay) or 1.2
	local peakTrans = math.clamp((options and options.intensity) or 0.80, 0.35, 0.95)
	local angle = (options and options.angle) or 25

	local shimmerHost = Elements.create("Frame", instance, {
		Name = "ShimmerHost",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = false,
		ZIndex = (instance.ZIndex or 1) + 1,
	})

	local existingCorner = instance:FindFirstChildOfClass("UICorner")
	local radius = if existingCorner then existingCorner.CornerRadius.Offset else Theme.radii.card
	Elements.corner(shimmerHost, radius)

	local sheen = Elements.create("Frame", shimmerHost, {
		Name = "Sheen",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(-0.6, 0, 0.5, 0),
		Size = UDim2.new(0.6, 0, 2.2, 0),
		BackgroundColor3 = sheenColor,
		BorderSizePixel = 0,
		Active = false,
	})

	Elements.create("UIGradient", sheen, {
		Rotation = angle,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, peakTrans),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})

	local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, repeatDelay)
	local tween = TweenService:Create(sheen, tweenInfo, {
		Position = UDim2.new(1.6, 0, 0.5, 0),
	})
	tween:Play()

	return function()
		pcall(function()
			tween:Cancel()
			shimmerHost:Destroy()
		end)
	end
end

-- Tactile spring pulse on any element (e.g. icons, capsules, telemetry)
function Feedback.pulse(instance: GuiObject, peakScale: number?)
	if not Springs.motionEnabled then return end
	local scale = instance:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Elements.create("UIScale", instance, { Name = "PulseScale", Scale = 1 })
	end
	scale.Scale = peakScale or 1.15
	Springs.target(scale, { Scale = 1.0 }, "bouncy")
end

-- Expanding tactile ripple ring from a click/event origin
function Feedback.ringPulse(parent: Instance, origin: (UDim2 | Vector2)?, color: Color3?)
	if not Springs.motionEnabled then return end
	local safePos = toUDim2(origin)
	local pulseColor = color or C.accent

	local ring = Elements.create("Frame", parent, {
		Name = "RippleRing",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = safePos,
		Size = UDim2.fromOffset(6, 6),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
	})
	Elements.corner(ring, Theme.radii.pill)

	local stroke = Elements.create("UIStroke", ring, {
		Color = pulseColor,
		Thickness = 2,
		Transparency = 0.2,
	})

	local tween = TweenService:Create(ring, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(80, 80),
	})
	local fade = TweenService:Create(stroke, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Transparency = 1,
	})
	tween.Completed:Connect(function()
		ring:Destroy()
	end)
	tween:Play()
	fade:Play()
end

return Feedback

