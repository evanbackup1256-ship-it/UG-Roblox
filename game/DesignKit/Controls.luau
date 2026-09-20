local Icons = require(script.Parent.Parent.Icons)
local Tokens = require(script.Parent.Tokens)
local Scheduler = require(script.Parent.Scheduler)
local Primitives = require(script.Parent.Primitives)
local Motion = require(script.Parent.Motion)
local Button = require(script.Parent.Button)
local SpringDriver = require(script.Parent.SpringDriver)

local colors = Tokens.colors

local M = {}

-- Clean Minimalist Checkbox
function M.checkbox(parent, name, initial, onToggle)
	local hit = Primitives.create("TextButton", parent, {
		Name = name or "Checkbox",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(40, 40),
		AutoButtonColor = false,
		Selectable = true,
	})

	local box = Primitives.create("Frame", hit, {
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = colors.recessed or colors.bgDeep,
		BorderSizePixel = 0,
	})
	Primitives.corner(box, Tokens.radius.control)
	local edge = Primitives.stroke(box, colors.line, 0.65, false)
	Motion.focusRing(hit)

	local mark = Primitives.create("ImageLabel", box, {
		Name = "Mark",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Image = Icons.asset("check"),
		ImageColor3 = colors.ink,
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
	})
	local markScale = Primitives.create("UIScale", mark, { Scale = 0.5 })

	local checked = initial and true or false

	local function paint(animated)
		if checked then
			if animated then
				Motion.animate(box, { BackgroundColor3 = colors.accent }, "snappy")
				Motion.animate(edge, { Transparency = 0.8 }, "snappy")
				Motion.animate(markScale, { Scale = 1 }, "bouncy")
				Motion.animate(mark, { ImageTransparency = 0 }, "snappy")
			else
				box.BackgroundColor3 = colors.accent
				edge.Transparency = 0.8
				markScale.Scale = 1
				mark.ImageTransparency = 0
			end
		else
			if animated then
				Motion.animate(box, { BackgroundColor3 = colors.recessed or colors.bgDeep }, "snappy")
				Motion.animate(edge, { Transparency = 0.65 }, "snappy")
				Motion.animate(markScale, { Scale = 0.5 }, "snappy")
				Motion.animate(mark, { ImageTransparency = 1 }, "snappy")
			else
				box.BackgroundColor3 = colors.recessed or colors.bgDeep
				edge.Transparency = 0.65
				markScale.Scale = 0.5
				mark.ImageTransparency = 1
			end
		end
	end

	paint(false)

	hit.MouseEnter:Connect(function()
		if hit:GetAttribute("Disabled") then return end
		if not checked then
			Motion.animate(edge, { Transparency = 0.3, Color = colors.lineGlow }, 0.15)
		end
	end)
	hit.MouseLeave:Connect(function()
		if not checked then
			Motion.animate(edge, { Transparency = 0.65, Color = colors.line }, 0.18)
		end
	end)

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

	local checkboxObj
	local function setChecked(value, animated)
		value = value and true or false
		if value == checked then return end
		checked = value
		paint(animated ~= false)
	end

	local function dispatchSet(selfOrVal, val, animated)
		if type(selfOrVal) == "table" and (selfOrVal == checkboxObj or selfOrVal.instance == hit) then
			setChecked(val, animated)
		else
			setChecked(selfOrVal, val)
		end
	end

	checkboxObj = {
		instance = hit,
		set = dispatchSet,
		SetChecked = dispatchSet,
		setChecked = dispatchSet,
		setValue = dispatchSet,
		GetChecked = function() return checked end,
		getChecked = function() return checked end,
		getValue = function() return checked end,
	}

	return checkboxObj
end

-- Sleek Pill Toggle Switch
function M.toggle(parent, name, initial, onToggle)
	local hit = Primitives.create("TextButton", parent, {
		Name = name or "Toggle",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(46, 30),
		AutoButtonColor = false,
		Selectable = true,
	})

	local track = Primitives.create("Frame", hit, {
		Name = "Track",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = initial and colors.accent or (colors.recessed or colors.bgDeep),
		BorderSizePixel = 0,
	})
	Primitives.corner(track, Tokens.radius.pill)
	local edge = Primitives.stroke(track, colors.line, 0.65, false)
	Motion.focusRing(hit)

	local thumb = Primitives.create("Frame", track, {
		Name = "Thumb",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = initial and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = initial and colors.ink or colors.text,
		BorderSizePixel = 0,
	})
	Primitives.corner(thumb, Tokens.radius.pill)

	local checked = initial and true or false

	local function paint(animated)
		local targetTrackColor = checked and colors.accent or (colors.recessed or colors.bgDeep)
		local targetThumbColor = checked and colors.ink or colors.text
		local targetThumbPos = checked and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)

		if animated then
			Motion.animate(track, { BackgroundColor3 = targetTrackColor }, 0.16)
			Motion.animate(thumb, { BackgroundColor3 = targetThumbColor }, 0.16)
			SpringDriver.animate(thumb, "slide", { Position = targetThumbPos }, "snappy")
		else
			track.BackgroundColor3 = targetTrackColor
			thumb.BackgroundColor3 = targetThumbColor
			thumb.Position = targetThumbPos
		end
	end

	hit.Activated:Connect(function()
		if hit:GetAttribute("Disabled") then
			Button.sound("denied")
			Motion.shake(track)
			return
		end
		checked = not checked
		Button.sound(if checked then "toggle_on" else "toggle_off")
		paint(true)
		if onToggle then
			onToggle(checked)
		end
	end)

	local toggleObj
	local function setChecked(val, animated)
		val = val and true or false
		if val == checked then return end
		checked = val
		paint(animated ~= false)
	end

	local function dispatchSet(selfOrVal, val, animated)
		if type(selfOrVal) == "table" and (selfOrVal == toggleObj or selfOrVal.instance == hit) then
			setChecked(val, animated)
		else
			setChecked(selfOrVal, val)
		end
	end

	toggleObj = {
		instance = hit,
		set = dispatchSet,
		SetChecked = dispatchSet,
		setChecked = dispatchSet,
		setValue = dispatchSet,
		GetChecked = function() return checked end,
		getChecked = function() return checked end,
		getValue = function() return checked end,
	}

	return toggleObj
end

-- Minimalist Segmented Chip Switcher
function M.segmented(parent, name, options, initialIndex, onSelect)
	local container = Primitives.create("Frame", parent, {
		Name = name or "SegmentedControl",
		BackgroundColor3 = colors.recessed or colors.bgDeep,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
	})
	Primitives.corner(container, Tokens.radius.control)
	local stroke = Primitives.stroke(container, colors.line, 0.7, false)

	local count = #options
	local segmentWidth = 1 / math.max(1, count)

	-- Sliding active chip indicator
	local indicator = Primitives.create("Frame", container, {
		Name = "Indicator",
		BackgroundColor3 = colors.accent,
		BorderSizePixel = 0,
		Size = UDim2.new(segmentWidth, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2),
		ZIndex = 2,
	})
	Primitives.corner(indicator, Tokens.radius.control)

	local buttons = {}
	local currentIndex = initialIndex or 1

	local function updateIndicator(idx, animated)
		local targetPos = UDim2.new(segmentWidth * (idx - 1), 2, 0, 2)
		if animated ~= false then
			SpringDriver.animate(indicator, "slide", { Position = targetPos }, "snappy")
		else
			indicator.Position = targetPos
		end

		for i, btn in ipairs(buttons) do
			local isActive = (i == idx)
			local targetColor = isActive and colors.ink or colors.textSub
			if animated ~= false then
				Motion.animate(btn, { TextColor3 = targetColor }, 0.14)
			else
				btn.TextColor3 = targetColor
			end
		end
	end

	for i, opt in ipairs(options) do
		local label = typeof(opt) == "table" and (opt.label or opt.name or tostring(i)) or tostring(opt)
		local btn = Primitives.create("TextButton", container, {
			Name = "Option_" .. i,
			Text = label,
			Font = Tokens.font.bold,
			TextSize = Tokens.type.caption,
			TextColor3 = (i == currentIndex) and colors.ink or colors.textSub,
			BackgroundTransparency = 1,
			Size = UDim2.new(segmentWidth, 0, 1, 0),
			Position = UDim2.new(segmentWidth * (i - 1), 0, 0, 0),
			ZIndex = 3,
			AutoButtonColor = false,
		})
		buttons[i] = btn

		btn.Activated:Connect(function()
			if currentIndex == i then return end
			currentIndex = i
			Button.sound("select")
			updateIndicator(currentIndex, true)
			if onSelect then
				onSelect(currentIndex, opt)
			end
		end)
	end

	updateIndicator(currentIndex, false)

	local segmentObj
	local function setIdx(idx, animated)
		if idx < 1 or idx > count or idx == currentIndex then return end
		currentIndex = idx
		updateIndicator(currentIndex, animated ~= false)
	end

	local function dispatchIndex(selfOrIdx, idx, animated)
		if type(selfOrIdx) == "table" and (selfOrIdx == segmentObj or selfOrIdx.instance == container) then
			setIdx(idx, animated)
		else
			setIdx(selfOrIdx, idx)
		end
	end

	segmentObj = {
		instance = container,
		SetIndex = dispatchIndex,
		setIndex = dispatchIndex,
		set = dispatchIndex,
		GetIndex = function() return currentIndex end,
		getIndex = function() return currentIndex end,
		getValue = function() return currentIndex end,
	}

	return segmentObj
end

-- Clean Progress Track
function M.progress(parent, name)
	local track = Primitives.create("Frame", parent, {
		Name = name or "Progress",
		BorderSizePixel = 0,
		BackgroundColor3 = colors.recessed or colors.bgDeep,
		Size = UDim2.new(1, 0, 0, 4),
	})
	Primitives.corner(track, 2)
	local fill = Primitives.create("Frame", track, {
		Name = "Fill",
		BackgroundColor3 = colors.accent,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	})
	Primitives.corner(fill, 2)
	return track, fill
end

-- Enhanced Progress Bar with liquid spring fill and discreet spark
function M.progressBar(parent, name, height, color)
	local h = height or 6
	local track = Primitives.create("Frame", parent, {
		Name = name or "ProgressBar",
		BackgroundColor3 = colors.recessed or colors.bgDeep,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, h),
		ClipsDescendants = true,
	})
	Primitives.corner(track, Tokens.radius.pill)
	local stroke = Primitives.stroke(track, colors.line, 0.65, false)

	local fillColor = color or colors.accent
	local fill = Primitives.create("Frame", track, {
		Name = "Fill",
		BackgroundColor3 = fillColor,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	})
	Primitives.corner(fill, Tokens.radius.pill)

	local spark = Primitives.create("Frame", fill, {
		Name = "Spark",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	})
	Primitives.corner(spark, 1)

	local currentRatio = 0

	local controller
	local function doSetProgress(ratio, animated)
		ratio = math.clamp(ratio or 0, 0, 1)
		currentRatio = ratio
		local targetSize = UDim2.fromScale(ratio, 1)
		if animated ~= false then
			SpringDriver.animate(fill, "progress", { Size = targetSize }, "smooth")
		else
			fill.Size = targetSize
		end
		spark.Visible = (ratio > 0.02 and ratio < 0.99)
	end

	local function dispatchProgress(selfOrRatio, ratio, animated)
		if type(selfOrRatio) == "table" and (selfOrRatio == controller or selfOrRatio.instance == track) then
			doSetProgress(ratio, animated)
		else
			doSetProgress(selfOrRatio, ratio)
		end
	end

	local function dispatchColor(selfOrColor, newColor)
		local c = if type(selfOrColor) == "table" then newColor else selfOrColor
		fill.BackgroundColor3 = c
	end

	controller = {
		instance = track,
		track = track,
		fill = fill,
		spark = spark,
		SetProgress = dispatchProgress,
		setProgress = dispatchProgress,
		set = dispatchProgress,
		GetProgress = function() return currentRatio end,
		getProgress = function() return currentRatio end,
		getValue = function() return currentRatio end,
		SetColor = dispatchColor,
		setColor = dispatchColor,
	}

	return controller
end

-- Loading Skeleton Bar
function M.skeleton(parent, width, height)
	local bar = Primitives.create("Frame", parent, {
		Name = "SkeletonBar",
		Size = UDim2.fromOffset(width or 120, height or 16),
		BackgroundColor3 = colors.raised,
		BorderSizePixel = 0,
	})
	Primitives.corner(bar, Tokens.radius.control)
	return bar
end

-- Clean Input Field
function M.input(parent, name, placeholder, onEntered)
	local container = Primitives.create("Frame", parent, {
		Name = name or "InputField",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = colors.recessed or colors.bgDeep,
		BorderSizePixel = 0,
	})
	Primitives.corner(container, Tokens.radius.control)
	local stroke = Primitives.stroke(container, colors.line, 0.65, false)

	local box = Primitives.create("TextBox", container, {
		Name = "TextBox",
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Font = Tokens.font.regular,
		TextSize = Tokens.type.body,
		TextColor3 = colors.text,
		PlaceholderColor3 = colors.muted,
		PlaceholderText = placeholder or "Enter value…",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	box.Focused:Connect(function()
		Motion.animate(stroke, { Color = colors.lineGlow, Transparency = 0.3 }, 0.15)
	end)
	box.FocusLost:Connect(function(enterPressed)
		Motion.animate(stroke, { Color = colors.line, Transparency = 0.65 }, 0.18)
		if onEntered and enterPressed then
			onEntered(box.Text)
		end
	end)

	return box
end

return M
