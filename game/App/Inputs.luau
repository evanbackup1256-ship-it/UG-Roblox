--!strict
-- Inputs: Modern interactive controls (Segmented, Toggle, Slider, ProgressBar, InputField)
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local Springs = require(script.Parent.Springs)
local Elements = require(script.Parent.Elements)

local C = Theme.colors
local Inputs = {}

local acousticsInstance: any = nil
function Inputs.setAcoustics(acoustics: any)
	acousticsInstance = acoustics
end

local function playSound(name: string, pitchVariation: number?)
	if acousticsInstance then
		acousticsInstance.play(name, pitchVariation)
	end
end

-- =========================================================================
-- 1. SEGMENTED PILL SWITCHER (Sliding physical spring pill)
-- =========================================================================
function Inputs.segmented(
	parent: Instance,
	name: string,
	options: { string },
	initialIndex: number?,
	onChange: ((number) -> ())?
)
	local count = #options
	local container = Elements.create("Frame", parent, {
		Name = name,
		Size = UDim2.fromOffset(count * 80 + 8, 36),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
	})
	Elements.corner(container, Theme.radii.pill)
	Elements.stroke(container, C.hairline, 1, 0.70)

	local pillIndicator = Elements.create("Frame", container, {
		Name = "ActivePill",
		BackgroundColor3 = C.elevated,
		BorderSizePixel = 0,
		ZIndex = 1,
	})
	Elements.corner(pillIndicator, Theme.radii.pill)
	Elements.stroke(pillIndicator, C.hairlineGlow, 1, 0.50)

	local currentIndex = initialIndex or 1
	local optionButtons = {}
	local optionLabels = {}

	local function updateLayout()
		local width = container.AbsoluteSize.X
		if width <= 0 then width = count * 80 + 8 end
		local innerWidth = width - 8
		local segmentWidth = innerWidth / count

		pillIndicator.Size = UDim2.new(0, segmentWidth, 1, -8)
		pillIndicator.Position = UDim2.new(0, 4 + (currentIndex - 1) * segmentWidth, 0, 4)

		for i = 1, count do
			local btn = optionButtons[i]
			btn.Position = UDim2.new(0, 4 + (i - 1) * segmentWidth, 0, 4)
			btn.Size = UDim2.new(0, segmentWidth, 1, -8)
		end
	end

	local function setIndex(index: number, fireCallback: boolean?)
		index = math.clamp(index, 1, count)
		currentIndex = index

		local width = container.AbsoluteSize.X
		if width <= 0 then width = count * 80 + 8 end
		local innerWidth = width - 8
		local segmentWidth = innerWidth / count

		Springs.target(pillIndicator, {
			Position = UDim2.new(0, 4 + (index - 1) * segmentWidth, 0, 4),
			Size = UDim2.new(0, segmentWidth, 1, -8),
		}, "smooth")

		for i = 1, count do
			local lbl = optionLabels[i]
			if i == index then
				Springs.target(lbl, { TextColor3 = C.textPrimary }, "smooth")
			else
				Springs.target(lbl, { TextColor3 = C.textMuted }, "smooth")
			end
		end

		if fireCallback ~= false and onChange then
			onChange(index)
		end
	end

	for i, optText in ipairs(options) do
		local btn = Elements.create("TextButton", container, {
			Name = "Segment_" .. i,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 2,
		})

		local lbl = Elements.create("TextLabel", btn, {
			Name = "Label",
			Text = optText,
			Font = Theme.typography.fontBold,
			TextSize = Theme.typography.sizeCaption,
			TextColor3 = if i == currentIndex then C.textPrimary else C.textMuted,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		})

		btn.Activated:Connect(function()
			if currentIndex ~= i then
				playSound("tab", 0.04)
				setIndex(i, true)
			end
		end)

		optionButtons[i] = btn
		optionLabels[i] = lbl
	end

	container:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
	task.defer(updateLayout)

	local controller = {
		instance = container,
		select = function(selfOrIdx, idx)
			local i = if type(selfOrIdx) == "number" then selfOrIdx else idx
			setIndex(i, false)
		end,
		getIndex = function() return currentIndex end,
	}

	return controller
end

-- =========================================================================
-- 2. TOGGLE (Mechanical sliding pill switch)
-- =========================================================================
function Inputs.toggle(
	parent: Instance,
	name: string,
	initialState: boolean?,
	onChange: ((boolean) -> ())?
)
	local active = initialState == true

	local track = Elements.create("TextButton", parent, {
		Name = name,
		Size = UDim2.fromOffset(48, 26),
		BackgroundColor3 = if active then C.accent else C.recessed,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	Elements.corner(track, Theme.radii.pill)
	local trackStroke = Elements.stroke(track, if active then C.accent else C.hairline, 1, 0.6)

	local thumb = Elements.create("Frame", track, {
		Name = "Thumb",
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = if active then UDim2.new(1, -23, 0.5, 0) else UDim2.new(0, 3, 0.5, 0),
		BackgroundColor3 = C.textPrimary,
		BorderSizePixel = 0,
	})
	Elements.corner(thumb, Theme.radii.pill)

	local function sync(animate: boolean?)
		local targetPos = if active then UDim2.new(1, -23, 0.5, 0) else UDim2.new(0, 3, 0.5, 0)
		local targetCol = if active then C.accent else C.recessed
		local strokeCol = if active then C.accent else C.hairline

		if animate ~= false then
			Springs.target(thumb, { Position = targetPos }, "smooth")
			Springs.target(track, { BackgroundColor3 = targetCol }, "smooth")
			Springs.target(trackStroke, { Color = strokeCol }, "smooth")
		else
			thumb.Position = targetPos
			track.BackgroundColor3 = targetCol
			trackStroke.Color = strokeCol
		end
	end

	local function toggle()
		active = not active
		playSound(if active then "toggle_on" else "toggle_off", 0.04)
		sync(true)
		if onChange then
			onChange(active)
		end
	end

	track.Activated:Connect(toggle)

	local controller = {
		instance = track,
		set = function(selfOrVal, val, animated)
			local v = if type(selfOrVal) == "boolean" then selfOrVal else val
			local a = if type(selfOrVal) == "boolean" then val else animated
			active = v == true
			sync(a)
		end,
		getValue = function() return active end,
	}

	return controller
end

-- =========================================================================
-- 3. PROGRESS BAR (Liquid spring meter with spark)
-- =========================================================================
function Inputs.progressBar(parent: Instance, name: string, height: number?, barColor: Color3?)
	local col = barColor or C.accent
	local h = height or 6

	local track = Elements.create("Frame", parent, {
		Name = name,
		Size = UDim2.new(1, 0, 0, h),
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	Elements.corner(track, Theme.radii.pill)

	local fill = Elements.create("Frame", track, {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = col,
		BorderSizePixel = 0,
	})
	Elements.corner(fill, Theme.radii.pill)

	local currentRatio = 0

	local function setProgress(ratio: number, animated: boolean?)
		ratio = math.clamp(ratio or 0, 0, 1)
		currentRatio = ratio
		local targetSize = UDim2.fromScale(ratio, 1)

		if animated ~= false then
			Springs.target(fill, { Size = targetSize }, "smooth")
		else
			fill.Size = targetSize
		end
	end

	local controller = {
		instance = track,
		fill = fill,
		setProgress = function(selfOrRatio, ratio, animated)
			local r = if type(selfOrRatio) == "number" then selfOrRatio else ratio
			local a = if type(selfOrRatio) == "number" then ratio else animated
			setProgress(r, a)
		end,
		SetProgress = function(selfOrRatio, ratio, animated)
			local r = if type(selfOrRatio) == "number" then selfOrRatio else ratio
			local a = if type(selfOrRatio) == "number" then ratio else animated
			setProgress(r, a)
		end,
		set = function(selfOrRatio, ratio, animated)
			local r = if type(selfOrRatio) == "number" then selfOrRatio else ratio
			local a = if type(selfOrRatio) == "number" then ratio else animated
			setProgress(r, a)
		end,
		getProgress = function() return currentRatio end,
		setColor = function(selfOrCol, newCol)
			local c = if typeof(selfOrCol) == "Color3" then selfOrCol else newCol
			fill.BackgroundColor3 = c
		end,
	}

	return controller
end

-- =========================================================================
-- 4. INPUT FIELD (Search & text entry with focus animation)
-- =========================================================================
function Inputs.input(
	parent: Instance,
	name: string,
	placeholder: string?,
	onQueryChange: ((string) -> ())?,
	iconKey: string?
): Frame
	local container = Elements.create("Frame", parent, {
		Name = name,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
	})
	Elements.corner(container, Theme.radii.control)
	local stroke = Elements.stroke(container, C.hairline, 1, 0.70)

	local icon = Elements.icon(container, "InputIcon", iconKey or "search", C.textMuted)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 12, 0.5, 0)
	icon.Size = UDim2.fromOffset(18, 18)

	local textBox = Elements.create("TextBox", container, {
		Name = "InputBox",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 38, 0.5, 0),
		Size = UDim2.new(1, -74, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = placeholder or "Search…",
		PlaceholderColor3 = C.textMuted,
		TextColor3 = C.textPrimary,
		Font = Theme.typography.fontBody,
		TextSize = Theme.typography.sizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	})

	local clearBtn = Elements.create("TextButton", container, {
		Name = "ClearBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Text = "×",
		Font = Theme.typography.fontBold,
		TextSize = 16,
		TextColor3 = C.textMuted,
		AutoButtonColor = false,
		Visible = false,
	})

	clearBtn.Activated:Connect(function()
		textBox.Text = ""
		if onQueryChange then onQueryChange("") end
	end)

	textBox.Focused:Connect(function()
		playSound("input", 0.02)
		Springs.target(stroke, { Color = C.hairlineGlow, Transparency = 0.20 }, "smooth")
	end)

	textBox.FocusLost:Connect(function()
		Springs.target(stroke, { Color = C.hairline, Transparency = 0.70 }, "smooth")
	end)

	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		clearBtn.Visible = (textBox.Text ~= "")
		if onQueryChange then
			onQueryChange(string.lower(textBox.Text))
		end
	end)

	return container
end

-- =========================================================================
-- 5. SEARCH INPUT (Component returning container + textBox + helpers)
-- =========================================================================
function Inputs.searchInput(
	parent: Instance,
	name: string,
	placeholder: string?,
	iconKey: string?,
	onQueryChange: ((string) -> ())?
)
	local container = Elements.create("Frame", parent, {
		Name = name,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
	})
	Elements.corner(container, Theme.radii.control)
	local stroke = Elements.stroke(container, C.hairline, 1, 0.70)

	local icon = Elements.icon(container, "InputIcon", iconKey or "search", C.textMuted)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 12, 0.5, 0)
	icon.Size = UDim2.fromOffset(18, 18)

	local textBox = Elements.create("TextBox", container, {
		Name = "TextBox",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 38, 0.5, 0),
		Size = UDim2.new(1, -74, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = placeholder or "Search…",
		PlaceholderColor3 = C.textMuted,
		TextColor3 = C.textPrimary,
		Font = Theme.typography.fontBody,
		TextSize = Theme.typography.sizeBody,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	})

	local clearBtn = Elements.create("TextButton", container, {
		Name = "ClearBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Text = "×",
		Font = Theme.typography.fontBold,
		TextSize = 16,
		TextColor3 = C.textMuted,
		AutoButtonColor = false,
		Visible = false,
	})

	clearBtn.Activated:Connect(function()
		textBox.Text = ""
		if onQueryChange then onQueryChange("") end
	end)

	textBox.Focused:Connect(function()
		playSound("input", 0.02)
		Springs.target(stroke, { Color = C.hairlineGlow, Transparency = 0.20 }, "smooth")
	end)

	textBox.FocusLost:Connect(function()
		Springs.target(stroke, { Color = C.hairline, Transparency = 0.70 }, "smooth")
	end)

	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		clearBtn.Visible = (textBox.Text ~= "")
		if onQueryChange then
			onQueryChange(textBox.Text)
		end
	end)

	return {
		instance = container,
		textBox = textBox,
		getText = function() return textBox.Text end,
		setText = function(selfOrText, text)
			local t = if type(selfOrText) == "string" then selfOrText else text
			textBox.Text = t or ""
		end,
		clear = function()
			textBox.Text = ""
			if onQueryChange then onQueryChange("") end
		end,
	}
end

-- =========================================================================
-- 6. SLIDER (Tactile continuous scrubber with percentage readout)
-- =========================================================================
function Inputs.slider(
	parent: Instance,
	name: string,
	initialValue: number?,
	onChange: ((number) -> ())?
)
	local currentValue = math.clamp(initialValue or 1, 0, 1)

	local container = Elements.create("TextButton", parent, {
		Name = name,
		Size = UDim2.new(0, 220, 0, 40),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})

	local track = Elements.create("Frame", container, {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, -54, 0, 6),
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
	})
	Elements.corner(track, Theme.radii.pill)

	local fill = Elements.create("Frame", track, {
		Name = "Fill",
		Size = UDim2.fromScale(currentValue, 1),
		BackgroundColor3 = C.accent,
		BorderSizePixel = 0,
	})
	Elements.corner(fill, Theme.radii.pill)

	local thumb = Elements.create("Frame", track, {
		Name = "Thumb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(currentValue, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = C.textPrimary,
		BorderSizePixel = 0,
	})
	Elements.corner(thumb, Theme.radii.pill)
	Elements.stroke(thumb, C.hairlineGlow, 1, 0.40)

	local valueLabel = Elements.create("TextLabel", container, {
		Name = "ValueLabel",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(46, 24),
		BackgroundTransparency = 1,
		Text = string.format("%d%%", math.floor(currentValue * 100 + 0.5)),
		Font = Theme.typography.fontMono,
		TextSize = Theme.typography.sizeCaption,
		TextColor3 = C.accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	local dragging = false

	local function updateFromX(x: number)
		local trackAbs = track.AbsolutePosition.X
		local trackWidth = math.max(1, track.AbsoluteSize.X)
		local ratio = math.clamp((x - trackAbs) / trackWidth, 0, 1)
		ratio = math.floor(ratio * 100 + 0.5) / 100

		if ratio ~= currentValue then
			currentValue = ratio
			fill.Size = UDim2.fromScale(ratio, 1)
			thumb.Position = UDim2.fromScale(ratio, 0.5)
			valueLabel.Text = string.format("%d%%", math.floor(ratio * 100 + 0.5))

			if onChange then
				onChange(currentValue)
			end
		end
	end

	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Springs.target(thumb, { Size = UDim2.fromOffset(22, 22) }, "smooth")
			playSound("slider", 0.04)
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)

	local function stopDrag()
		if dragging then
			dragging = false
			Springs.target(thumb, { Size = UDim2.fromOffset(18, 18) }, "smooth")
		end
	end

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			stopDrag()
		end
	end)
	UserInputService.WindowFocusReleased:Connect(stopDrag)

	local function setValue(val: number, animated: boolean?)
		val = math.clamp(val or 0, 0, 1)
		currentValue = val
		valueLabel.Text = string.format("%d%%", math.floor(val * 100 + 0.5))

		if animated ~= false then
			Springs.target(fill, { Size = UDim2.fromScale(val, 1) }, "smooth")
			Springs.target(thumb, { Position = UDim2.fromScale(val, 0.5) }, "smooth")
		else
			fill.Size = UDim2.fromScale(val, 1)
			thumb.Position = UDim2.fromScale(val, 0.5)
		end
	end

	return {
		instance = container,
		track = track,
		fill = fill,
		thumb = thumb,
		valueLabel = valueLabel,
		getValue = function() return currentValue end,
		setValue = function(selfOrVal, val, animated)
			local v = if type(selfOrVal) == "number" then selfOrVal else val
			local a = if type(selfOrVal) == "number" then val else animated
			setValue(v, a)
		end,
		set = function(selfOrVal, val, animated)
			local v = if type(selfOrVal) == "number" then selfOrVal else val
			local a = if type(selfOrVal) == "number" then val else animated
			setValue(v, a)
		end,
	}
end

return Inputs
