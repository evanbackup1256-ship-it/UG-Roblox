--!strict
-- Buttons: Physical weighted spring buttons with integrated acoustic feedback
local Theme = require(script.Parent.Theme)
local Springs = require(script.Parent.Springs)
local Elements = require(script.Parent.Elements)

local C = Theme.colors
local Buttons = {}

local acousticsInstance: any = nil

function Buttons.setAcoustics(acoustics: any)
	acousticsInstance = acoustics
end

local function playSound(name: string, pitchVariation: number?)
	if acousticsInstance then
		acousticsInstance.play(name, pitchVariation)
	end
end

local VARIANTS = {
	primary = {
		bg = Color3.fromRGB(59, 130, 246),
		bgHover = Color3.fromRGB(37, 99, 235),
		text = Color3.fromRGB(255, 255, 255),
		stroke = Color3.fromRGB(96, 165, 250),
	},
	secondary = {
		bg = Color3.fromRGB(24, 30, 41),
		bgHover = Color3.fromRGB(34, 42, 57),
		text = Color3.fromRGB(248, 250, 252),
		stroke = Color3.fromRGB(44, 55, 74),
	},
	amber = {
		bg = Color3.fromRGB(245, 158, 11),
		bgHover = Color3.fromRGB(217, 119, 6),
		text = Color3.fromRGB(24, 16, 6),
		stroke = Color3.fromRGB(251, 191, 36),
	},
	danger = {
		bg = Color3.fromRGB(220, 38, 38),
		bgHover = Color3.fromRGB(185, 28, 28),
		text = Color3.fromRGB(255, 255, 255),
		stroke = Color3.fromRGB(248, 113, 113),
	},
	ghost = {
		bg = Color3.fromRGB(0, 0, 0),
		bgHover = Color3.fromRGB(28, 34, 46),
		text = Color3.fromRGB(148, 163, 184),
		stroke = Color3.fromRGB(34, 42, 57),
		bgTrans = 1,
	},
}

local Feedback = require(script.Parent.Feedback)

local TweenService = game:GetService("TweenService")
local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Buttons.button(
	parent: Instance,
	name: string,
	text: string,
	onClick: (() -> ())?,
	variantName: string?
): TextButton
	local v = VARIANTS[variantName or "secondary"] or VARIANTS.secondary

	local btn = Elements.create("TextButton", parent, {
		Name = name,
		Size = UDim2.fromOffset(140, 38),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = v.bg,
		BackgroundTransparency = v.bgTrans or 0,
		BorderSizePixel = 0,
		Text = text,
		Font = Theme.typography.fontBold,
		TextSize = Theme.typography.sizeBody,
		TextColor3 = v.text,
		AutoButtonColor = false,
		AutoLocalize = false,
		ClipsDescendants = false,
		ZIndex = 5,
	})
	Elements.corner(btn, Theme.radii.control)
	local scale = Elements.create("UIScale", btn, { Scale = 1 })

	local stroke = Elements.stroke(btn, v.stroke, 1, Theme.hairlines.restTransparency)
	
	if variantName == "primary" then
		task.delay(1.5, function()
			if btn.Parent then
				Feedback.shimmer(btn, { speed = 2.5, delay = 2.5, color = Color3.fromRGB(255, 255, 255), intensity = 0.6 })
			end
		end)
	end

	btn:SetAttribute("EnabledState", true)
	btn:SetAttribute("NormalColor", v.bg)
	btn:SetAttribute("HoverColor", v.bgHover)
	btn:SetAttribute("TextColor", v.text)

	btn.MouseEnter:Connect(function()
		if btn:GetAttribute("EnabledState") ~= true then return end
		playSound("hover", 0.03)
		TweenService:Create(btn, TWEEN_INFO, { BackgroundColor3 = v.bgHover }):Play()
		TweenService:Create(stroke, TWEEN_INFO, { Transparency = Theme.hairlines.hoverTransparency }):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(scale, TWEEN_INFO, { Scale = 1.0 }):Play()
		if btn:GetAttribute("EnabledState") ~= true then return end
		TweenService:Create(btn, TWEEN_INFO, { BackgroundColor3 = v.bg }):Play()
		TweenService:Create(stroke, TWEEN_INFO, { Transparency = Theme.hairlines.restTransparency }):Play()
	end)

	btn.MouseButton1Down:Connect(function()
		if btn:GetAttribute("EnabledState") ~= true then return end
		playSound("press", 0.04)
		TweenService:Create(scale, TWEEN_INFO, { Scale = 0.96 }):Play()
		TweenService:Create(stroke, TWEEN_INFO, { Transparency = Theme.hairlines.activeTransparency }):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		if btn:GetAttribute("EnabledState") ~= true then return end
		playSound("release", 0.04)
		TweenService:Create(scale, TWEEN_INFO, { Scale = 1.0 }):Play()
		TweenService:Create(stroke, TWEEN_INFO, { Transparency = Theme.hairlines.hoverTransparency }):Play()
	end)

	if onClick then
		btn.Activated:Connect(function()
			if btn:GetAttribute("EnabledState") ~= true then
				playSound("denied", 0.02)
				return
			end
			playSound("click", 0.05)
			onClick()
		end)
	end

	return btn
end

function Buttons.enable(btn: TextButton, isEnabled: boolean, labelText: string?, keepLayout: boolean?)
	btn:SetAttribute("EnabledState", isEnabled)
	local normalBg = btn:GetAttribute("NormalColor") or C.card
	local textCol = btn:GetAttribute("TextColor") or C.textPrimary

	if labelText then
		btn.Text = labelText
	end

	if isEnabled then
		btn.Active = true
		btn.AutoButtonColor = false
		TweenService:Create(btn, TWEEN_INFO, {
			BackgroundColor3 = normalBg,
			BackgroundTransparency = 0,
		}):Play()
		btn.TextColor3 = textCol
	else
		btn.Active = false
		TweenService:Create(btn, TWEEN_INFO, {
			BackgroundColor3 = C.recessed,
			BackgroundTransparency = 0.2,
		}):Play()
		btn.TextColor3 = C.textMuted
	end
end

return Buttons

