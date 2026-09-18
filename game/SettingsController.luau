local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Settings = {}

function Settings.build(parent, api)
	local scrollContainer = parent:IsA("ScrollingFrame") and parent
		or parent:FindFirstAncestorWhichIsA("ScrollingFrame")

	local make, label, panel, tween = api.make, api.label, api.panel, api.tween
	local C, prefs = api.colors, api.preferences

	local refreshers = {}
	local activeDrag = nil
	local connections = {}
	local pendingThreads = {}

	-- Track every connection so we can clean up cleanly
	local function connect(signal, callback)
		local conn = signal:Connect(callback)
		table.insert(connections, conn)
		return conn
	end

	-- Track delayed work the same way, so a destroyed panel can't run a
	-- callback against instances that no longer exist
	local function delay(seconds, callback)
		local thread
		thread = task.delay(seconds, function(...)
			pendingThreads[thread] = nil
			callback(...)
		end)
		pendingThreads[thread] = true
		return thread
	end

	local function cancel(thread)
		if pendingThreads[thread] then
			pendingThreads[thread] = nil
			task.cancel(thread)
		end
	end

	local function stopDrag()
		if not activeDrag then
			return
		end

		local drag = activeDrag
		activeDrag = nil

		if scrollContainer then
			scrollContainer.ScrollingEnabled = drag.scrollingEnabled
		end

		drag.finish()
	end

	connect(Input.InputChanged, function(input)
		local drag = activeDrag
		if not drag then
			return
		end

		if input == drag.input
			or (drag.mouse and input.UserInputType == Enum.UserInputType.MouseMovement)
		then
			drag.update(input.Position.X)
		end
	end)

	connect(Input.InputEnded, function(input)
		local drag = activeDrag
		if not drag then
			return
		end

		if input == drag.input
			or (drag.mouse and input.UserInputType == Enum.UserInputType.MouseButton1)
		then
			stopDrag()
		end
	end)

	connect(Input.WindowFocusReleased, stopDrag)

	connect(parent:GetPropertyChangedSignal("Visible"), function()
		if not parent.Visible then
			stopDrag()
		end
	end)

	-- The Destroying connection itself must also be cleaned up
	connect(parent.Destroying, function()
		stopDrag()

		for thread in pendingThreads do
			task.cancel(thread)
		end
		table.clear(pendingThreads)

		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		table.clear(connections)
	end)

	local function focusRing(button)
		local stroke = make("UIStroke", button, {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = C.accent,
			Thickness = 1,
			Transparency = 1,
		})

		local hovered = false
		local selected = false

		local function refresh()
			tween(stroke, {
				Transparency = (hovered or selected) and 0.3 or 1,
			}, 0.18)
		end

		connect(button.MouseEnter, function()
			hovered = true
			refresh()
		end)

		connect(button.MouseLeave, function()
			hovered = false
			refresh()
		end)

		connect(button.SelectionGained, function()
			selected = true
			refresh()
		end)

		connect(button.SelectionLost, function()
			selected = false
			refresh()
		end)
	end

	local function corner(instance, radius)
		make("UICorner", instance, {
			CornerRadius = UDim.new(0, radius),
		})
	end

	local function section(name, title, y, height)
		local p = panel(parent, name, 0, y, 984, height)
		local root = make("Frame", p, {
			Name = "SettingsRows",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 3,
		})
		root:SetAttribute("NativeControl", true)
		label(root, title, 24, 18, 650, 25, 19, C.text, true)
		return root
	end

	local function row(parentFrame, title, detail, y)
		local r = make("Frame", parentFrame, {
			Size = UDim2.new(1, -48, 0, 70),
			Position = UDim2.fromOffset(24, y),
			BackgroundTransparency = 1,
		})

		local titleLabel = label(r, title, 0, 6, 600, 24, 14, C.text, true)
		titleLabel.Size = UDim2.new(0.58, 0, 0, 24)

		local hint = label(r, detail, 0, 33, 600, 20, 12, C.muted, false)
		hint.Size = UDim2.new(0.58, 0, 0, 20)

		make("Frame", r, {
			Position = UDim2.new(0, 0, 1, -1),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = C.line,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
		})

		return r
	end

	local function toggle(parentFrame, key, title, detail, y)
		local r = row(parentFrame, title, detail, y)
		r.Name = "Row_" .. key

		local b = make("TextButton", r, {
			Name = "Toggle_" .. key,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 17),
			Size = UDim2.fromOffset(54, 30),
			BackgroundColor3 = C.raised,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Selectable = true,
			ZIndex = 4,
		})
		corner(b, 15)
		focusRing(b)

		local dot = make("Frame", b, {
			Name = "Thumb",
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.fromOffset(3, 3),
			BackgroundColor3 = C.text,
			BorderSizePixel = 0,
			ZIndex = 5,
		})
		corner(dot, 12)

		local pulse = make("UIScale", b, { Scale = 1 })
		local squashThread = nil

		connect(b.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				tween(pulse, { Scale = 0.94 }, 0.09)
			end
		end)

		connect(b.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				tween(pulse, { Scale = 1 }, 0.2)
			end
		end)

		connect(b.MouseLeave, function()
			tween(pulse, { Scale = 1 }, 0.2)
		end)

		local value = label(r, "", 0, 20, 52, 24, 12, C.muted, true)
		value.AnchorPoint = Vector2.new(1, 0)
		value.Position = UDim2.new(1, -66, 0, 20)
		value.TextXAlignment = Enum.TextXAlignment.Right

		local function refresh()
			local enabled = prefs[key]
			b:SetAttribute("Enabled", enabled)
			value.Text = enabled and "On" or "Off"

			tween(b, {
				BackgroundColor3 = enabled and C.accent or C.raised,
			}, 0.18)

			tween(dot, {
				Position = enabled and UDim2.fromOffset(27, 3) or UDim2.fromOffset(3, 3),
				BackgroundColor3 = enabled and C.ink or C.muted,
			}, 0.18)
		end

		connect(b.Activated, function()
			api.change(key, not prefs[key])
			api.play("toggle")
			refresh()

			-- The thumb stretches toward its new resting position and
			-- snaps back over the same span the slide takes, so the two
			-- motions land together instead of racing each other.
			if squashThread then
				cancel(squashThread)
				squashThread = nil
			end

			tween(dot, { Size = UDim2.fromOffset(27, 24) }, 0.07)

			squashThread = delay(0.07, function()
				squashThread = nil
				tween(dot, { Size = UDim2.fromOffset(24, 24) }, 0.11)
			end)
		end)

		table.insert(refreshers, refresh)
		refresh()
	end

	local function slider(parentFrame, key, title, detail, y)
		local r = row(parentFrame, title, detail, y)
		r.Name = "Row_" .. key

		local b = make("TextButton", r, {
			Name = "Slider_" .. key,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 10),
			Size = UDim2.new(0.35, 0, 0, 45),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Selectable = true,
			ZIndex = 4,
		})

		local rail = make("Frame", b, {
			Name = "Rail",
			Position = UDim2.new(0, 0, 0.5, -3),
			Size = UDim2.new(1, -50, 0, 6),
			BackgroundColor3 = C.raised,
			BorderSizePixel = 0,
			ZIndex = 4,
		})
		corner(rail, 3)

		local fill = make("Frame", rail, {
			Name = "Fill",
			Size = UDim2.fromScale(prefs[key], 1),
			BackgroundColor3 = C.accent,
			BorderSizePixel = 0,
			ZIndex = 5,
		})
		corner(fill, 3)

		local knob = make("Frame", rail, {
			Name = "Thumb",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(prefs[key], 0.5),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = C.text,
			BorderSizePixel = 0,
			ZIndex = 6,
		})
		corner(knob, 8)

		local knobScale = make("UIScale", knob, { Scale = 1 })
		local ring = make("UIStroke", knob, {
			Color = C.accent,
			Thickness = 3,
			Transparency = 1,
		})

		local function emphasize(active)
			tween(knobScale, { Scale = active and 1.28 or 1 }, 0.16)
			tween(ring, { Transparency = active and 0.55 or 1 }, 0.16)
		end

		connect(b.MouseEnter, function()
			emphasize(true)
		end)

		connect(b.MouseLeave, function()
			if not activeDrag or activeDrag.button ~= b then
				emphasize(false)
			end
		end)

		connect(b.SelectionGained, function()
			emphasize(true)
		end)

		connect(b.SelectionLost, function()
			emphasize(false)
		end)

		local percent = label(b, "", 0, 0, 44, 45, 12, C.accent, true)
		percent.AnchorPoint = Vector2.new(1, 0)
		percent.Position = UDim2.fromScale(1, 0)
		percent.TextXAlignment = Enum.TextXAlignment.Right

		local function refresh()
			b:SetAttribute("Value", prefs[key])
			tween(fill, { Size = UDim2.fromScale(prefs[key], 1) }, 0.08)
			tween(knob, { Position = UDim2.fromScale(prefs[key], 0.5) }, 0.08)
			percent.Text = math.round(prefs[key] * 100) .. "%"
		end

		-- Every write to this slider's value is quantized to whole
		-- percent here, so the drag path and the gamepad/keyboard path
		-- can never drift apart or leave the stored value off-grid.
		local function step(target)
			local v = math.round(math.clamp(target, 0, 1) * 100) / 100

			if v == prefs[key] then
				return
			end

			api.change(key, v)
			refresh()
		end

		local function updateFromPointer(x)
			step((x - rail.AbsolutePosition.X) / math.max(1, rail.AbsoluteSize.X))
		end

		-- Pointer / touch drag
		connect(b.InputBegan, function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			stopDrag()

			activeDrag = {
				button = b,
				input = input,
				mouse = input.UserInputType == Enum.UserInputType.MouseButton1,
				scrollingEnabled = scrollContainer and scrollContainer.ScrollingEnabled or true,
				update = updateFromPointer,
				finish = function()
					emphasize(false)
					api.play("slider")
				end,
			}

			if scrollContainer then
				scrollContainer.ScrollingEnabled = false
			end

			emphasize(true)
			updateFromPointer(input.Position.X)
		end)

		-- Gamepad / keyboard adjustment (only when selected)
		connect(b.InputBegan, function(input)
			if GuiService.SelectedObject ~= b then
				return
			end

			local dir = 0
			if input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight then
				dir = 1
			elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft then
				dir = -1
			end

			if dir ~= 0 then
				step(prefs[key] + dir * 0.05)
			end
		end)

		table.insert(refreshers, refresh)
		refresh()
	end

	-- ── Audio section ────────────────────────────────────────────────
	local audio = section("AudioSettings", "Audio & music", 104, 560)

	toggle(audio, "music", "Background music", "A calm electronic soundtrack.", 58)
	toggle(audio, "sfx", "Sound effects", "Purchases, rewards, and interaction sounds.", 132)
	toggle(audio, "hover", "Hover sounds", "Subtle feedback as you explore.", 206)
	slider(audio, "masterVolume", "Master volume", "The overall mix.", 280)
	slider(audio, "sfxVolume", "Effects volume", "Adjust UI sound levels.", 354)
	slider(audio, "musicVolume", "Music volume", "Keep your soundtrack in the background.", 428)

	local track = label(audio, api.trackName(), 24, 509, 620, 25, 12, C.muted, false)
	track.Size = UDim2.new(1, -190, 0, 25)

	local nextTrack = api.button(audio, "Next track  →", 810, 503, 150, 36, function()
		api.nextTrack()
		track.Text = api.trackName()
	end, false)
	nextTrack.Position = UDim2.new(1, -174, 0, 503)

	-- ── Visual section ───────────────────────────────────────────────
	local visual = section("VisualSettings", "Motion & display", 684, 530)

	toggle(visual, "motion", "Interface animations", "Switch off for reduced motion.", 58)
	toggle(visual, "notifications", "Reward notifications", "Show completion and purchase toasts.", 132)
	toggle(visual, "previews", "3D previews", "Disable scene rendering for a lighter UI.", 206)
	toggle(visual, "autoOrbit", "Automatic orbit", "Slowly rotate idle 3D previews.", 280)
	slider(visual, "orbitSpeed", "Orbit speed", "Set the pace of the automatic camera.", 354)
	toggle(visual, "particles", "Ambient particles", "Soft atmospheric motion in the background.", 428)

	-- Return a refresh function that the caller can invoke when preferences change externally
	return function()
		for _, refresh in ipairs(refreshers) do
			refresh()
		end
	end
end

return Settings
