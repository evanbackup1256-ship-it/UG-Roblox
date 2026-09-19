local Icons = require(script.Parent.Parent.Icons)
local Tokens = require(script.Parent.Tokens)
local Scheduler = require(script.Parent.Scheduler)
local Primitives = require(script.Parent.Primitives)
local Motion = require(script.Parent.Motion)
local Button = require(script.Parent.Button)

local colors = Tokens.colors

local M = {}

-- A self-contained checkbox toggle: not built on Kit.button at all (no
-- shared state, no risk of inheriting an unrelated effect meant for
-- momentary push-buttons). Full 44x44 touch target with a smaller visible
-- box centered inside it; checked state fills the box and pops a
-- checkmark in, rather than sliding a pill thumb.
function M.checkbox(parent, name, initial, onToggle)
	local hit = Primitives.create("TextButton", parent, {
		Name = name,
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(44, 44),
		AutoButtonColor = false,
		Selectable = true,
	})

	local box = Primitives.create("Frame", hit, {
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = colors.raised,
		BorderSizePixel = 0,
	})
	Primitives.corner(box, 10)
	local edge = Primitives.stroke(box, colors.line, Tokens.glow.restTransparency)
	Scheduler.Theme.paint(edge, "Color", "line")
	Motion.focusRing(hit)

	local mark = Primitives.create("ImageLabel", box, {
		Name = "Mark",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.asset("check"),
		ImageColor3 = colors.ink,
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
	})
	local markScale = Primitives.create("UIScale", mark, { Scale = 0.4 })

	local checked = initial and true or false

	local function paint(animated)
		if checked then
			if animated then
				Motion.animate(box, { BackgroundColor3 = colors.accent }, 0.16)
				Motion.animate(edge, { Transparency = 1 }, 0.16)
				markScale.Scale = 0.55
				mark.ImageTransparency = 0.2
				Motion.animate(markScale, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
				Motion.animate(mark, { ImageTransparency = 0 }, 0.14)
			else
				box.BackgroundColor3 = colors.accent
				edge.Transparency = 1
				markScale.Scale = 1
				mark.ImageTransparency = 0
			end
		else
			if animated then
				Motion.animate(box, { BackgroundColor3 = colors.raised }, 0.16)
				Motion.animate(edge, { Transparency = Tokens.glow.restTransparency }, 0.16)
				Motion.animate(markScale, { Scale = 0.4 }, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				Motion.animate(mark, { ImageTransparency = 1 }, 0.12)
			else
				box.BackgroundColor3 = colors.raised
				edge.Transparency = Tokens.glow.restTransparency
				markScale.Scale = 0.4
				mark.ImageTransparency = 1
			end
		end
	end

	paint(false)

	local function hover()
		if hit:GetAttribute("Disabled") then return end
		if not checked then
			Motion.animate(edge, { Transparency = Tokens.glow.hoverTransparency, Color = colors.accent }, 0.16)
		end
	end
	local function leave()
		if not checked then
			Motion.animate(edge, { Transparency = Tokens.glow.restTransparency, Color = colors.line }, 0.2)
		end
	end
	hit.MouseEnter:Connect(hover)
	hit.MouseLeave:Connect(leave)
	hit.SelectionGained:Connect(hover)
	hit.SelectionLost:Connect(leave)

	hit.Activated:Connect(function()
		if hit:GetAttribute("Disabled") then
			Button.sound("denied")
			Motion.shake(box)
			return
		end
		checked = not checked
		Button.sound(if checked then "toggle_on" else "toggle_off")
		paint(true)
		if onToggle then
			onToggle(checked)
		end
	end)

	return {
		instance = hit,
		SetChecked = function(_, value, animated)
			value = value and true or false
			if value == checked then
				return
			end
			checked = value
			paint(animated ~= false)
		end,
	}
end

function M.progress(parent, name)
	local track = Primitives.create("Frame", parent, {
		Name = name,
		BorderSizePixel = 0,
		BackgroundColor3 = colors.raised,
		Size = UDim2.new(1, 0, 0, 4),
	})
	Scheduler.Theme.paint(track, "BackgroundColor3", "raised")
	Primitives.corner(track, 2)
	local fill = Primitives.create("Frame", track, {
		Name = "Fill",
		BackgroundColor3 = colors.accent,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	})
	Scheduler.Theme.paint(fill, "BackgroundColor3", "accent")
	Primitives.corner(fill, 2)
	return track, fill
end

function M.input(parent, name, placeholder)
	local field = Primitives.create("TextBox", parent, {
		Name = name,
		Text = "",
		PlaceholderText = placeholder,
		PlaceholderColor3 = colors.muted,
		TextColor3 = colors.text,
		TextSize = Tokens.type.body,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		BackgroundColor3 = colors.background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
	})
	Scheduler.Theme.paint(field, "PlaceholderColor3", "muted")
	Scheduler.Theme.paint(field, "TextColor3", "text")
	Scheduler.Theme.paint(field, "BackgroundColor3", "background")
	Primitives.corner(field, Tokens.radius.control)
	local edge = Primitives.stroke(field, colors.line, Tokens.glow.restTransparency)
	Scheduler.Theme.paint(edge, "Color", "line")
	Primitives.create("UIPadding", field, { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) })
	field.Focused:Connect(function()
		Motion.animate(edge, { Color = colors.accent, Transparency = Tokens.glow.hoverTransparency, Thickness = Tokens.glow.thickness }, 0.16)
		Button.sound("input")
	end)
	field.FocusLost:Connect(function()
		Motion.animate(edge, { Color = colors.line, Transparency = Tokens.glow.restTransparency, Thickness = Tokens.glow.thickness }, 0.18)
		Button.sound("release")
	end)
	return field
end

return M
