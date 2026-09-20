local RunService = game:GetService("RunService")

local Toast = {}
Toast.__index = Toast

-- Toast notification system: a pool of TOAST_SLOTS card instances, an
-- exponential-approach entrance/exit animation driven off a single shared
-- Heartbeat stepper (only connected while at least one toast is live), and
-- a small backlog queue for when every slot is busy. Extracted verbatim
-- from InterfaceController.luau (previously a `do ... end` block) — this
-- was already the most self-contained piece of that file, touching only
-- Kit/C/Icons/preferences/root and producing exactly `notify`/`fit`, with
-- no dependency on Shared, act, or any page module.
function Toast.new(root, Kit, C, Icons, preferences, isAlive, connect, own)
	local self = setmetatable({}, Toast)

	local TOAST_SLOTS = 4
	local TOAST_BACKLOG = 6
	local TOAST_HEIGHT = 76
	local TOAST_GAP = 10
	-- Was a constant; now the base offset before the safe-area inset
	-- fit() adds each resize, so toasts don't stack under a visible
	-- topbar/notch. TOAST_TOP itself stays fixed — toastTop is what
	-- activateToast/stepToasts actually read.
	local TOAST_TOP = 104
	local toastTop = TOAST_TOP
	local TOAST_MARGIN = 12
	local TOAST_LIFETIME = 3.2
	local TOAST_RESPONSE = 18

	local toastWidth = 540
	local toastFloor = math.huge
	local toastSlots = {}
	local toastFree = {}
	local toastLive = {}
	local toastBacklog = {}
	local toastStepper

	for index = 1, TOAST_SLOTS do
		local holder = Kit.create("Frame", root, {
			Name = "Notification" .. index,
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(toastWidth, TOAST_HEIGHT),
			Visible = false,
			ZIndex = 80,
		})

		local scale = Kit.create("UIScale", holder, { Name = "ToastScale", Scale = 1 })

		local shadow = Kit.create("Frame", holder, {
			Name = "Shadow",
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 1,
		})
		Kit.corner(shadow, 14)

		local card = Kit.card(holder, "Card", TOAST_HEIGHT, C.panel)
		card.Position = UDim2.fromOffset(0, 0)
		card.Size = UDim2.fromScale(1, 1)
		card.Active = true
		card.ZIndex = 2

		local bar = Kit.create("Frame", card, {
			Name = "Accent",
			Position = UDim2.fromOffset(0, 12),
			Size = UDim2.fromOffset(4, 52),
			BackgroundColor3 = C.accent,
			BorderSizePixel = 0,
			ZIndex = 51,
		})
		Kit.corner(bar, 2)

		local icon = Kit.icon(card, "Icon", "check", C.ink)
		icon.ZIndex = 51
		Kit.place(icon, 18, 26, 24, 24)
		local iconScale = Kit.create("UIScale", icon, { Name = "IconScale", Scale = 1 })

		local title = Kit.text(card, "Title", "Updated", 10, C.accent, true)
		title.ZIndex = 51
		title.Position = UDim2.fromOffset(56, 10)
		title.Size = UDim2.new(1, -72, 0, 18)

		local message = Kit.text(card, "Message", "", 13, C.text, true)
		message.TextWrapped = true
		message.TextTruncate = Enum.TextTruncate.None
		message.ZIndex = 51
		message.Position = UDim2.fromOffset(56, 27)
		message.Size = UDim2.new(1, -72, 0, 38)

		local timer = Kit.create("Frame", card, {
			Name = "Timer",
			Position = UDim2.new(0, 0, 1, -3),
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = C.accent,
			BorderSizePixel = 0,
			ZIndex = 52,
		})

		local slot = {
			holder = holder,
			scale = scale,
			card = card,
			bar = bar,
			icon = icon,
			iconScale = iconScale,
			title = title,
			message = message,
			timer = timer,
			hovered = false,
			entry = nil,
		}

		connect(card.MouseEnter, function()
			slot.hovered = true
		end)

		connect(card.MouseLeave, function()
			slot.hovered = false
		end)

		connect(card.InputBegan, function(input)
			if slot.entry
				and (input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch)
			then
				slot.entry.leaving = true
			end
		end)

		toastSlots[index] = slot
		toastFree[index] = slot
	end

	local function paintToast(slot, entry)
		local tint = if entry.failed then C.error else C.accent

		slot.title.Text = if entry.failed then "REQUEST REJECTED" else "COMPLETE"
		slot.title.TextColor3 = tint
		-- "codes"/"contracts" were unrelated feature-page icons left over
		-- from an earlier pass — neither reads as success or failure.
		-- "close"/"check" actually match the two states.
		slot.icon.Image = Icons.asset(if entry.failed then "close" else "check")
		slot.icon.ImageColor3 = tint
		slot.bar.BackgroundColor3 = tint
		slot.timer.BackgroundColor3 = tint
		slot.message.Text = if entry.repeats > 1
			then string.format("%s  ×%d", entry.message, entry.repeats)
			else entry.message
	end

	local function activateToast(request)
		local slot = table.remove(toastFree)
		if not slot then
			return false
		end

		local now = os.clock()
		local entry = {
			slot = slot,
			message = request.message,
			failed = request.failed,
			repeats = 1,
			expires = now + TOAST_LIFETIME,
			x = toastWidth + TOAST_MARGIN + 30,
			y = toastTop,
			targetY = toastTop,
			scale = 0.92,
			leaving = false,
		}

		slot.entry = entry
		slot.hovered = false
		paintToast(slot, entry)

		slot.timer.Size = UDim2.new(1, 0, 0, 3)
		slot.scale.Scale = entry.scale
		slot.holder.Position = UDim2.new(1, entry.x - TOAST_MARGIN, 0, entry.y)
		slot.holder.Visible = true

		if not entry.failed and request.cue == "milestone" then
			Kit.gradientAnimate(slot.bar, "sheen", { color = C.accent })
			if preferences.particles then
				Kit.confetti(slot.card, C.accent)
			end
			-- Depth-separation cue: the icon overshoots ahead of the card on
			-- a bouncy preset while the card background settles on a slower
			-- smooth one, so the two layers visibly move at different rates
			-- for ~150-200ms on entrance — a brief parallax pop rather than
			-- a hover-tracked effect (a toast doesn't linger long enough for
			-- mouse-position tracking to read as intentional).
			slot.iconScale.Scale = 0.7
			Kit.animate(slot.iconScale, { Scale = 1.08 }, "bouncy")
			Kit.Scheduler.after(slot.iconScale, "iconSettle", 0.16, function()
				if slot.entry == entry then
					Kit.animate(slot.iconScale, { Scale = 1 }, "smooth")
				end
			end)
			slot.card.BackgroundTransparency = 1
			Kit.animate(slot.card, { BackgroundTransparency = 0 }, "smooth")
		else
			Kit.Scheduler.clear(slot.bar, "gradient")
			slot.iconScale.Scale = 1
			slot.card.BackgroundTransparency = 0
		end

		table.insert(toastLive, 1, entry)
		Kit.sound(if request.failed then "error" else request.cue or "notice")
		return true
	end

	local function approach(current, target, blend, epsilon)
		local value = current + (target - current) * blend
		if math.abs(target - value) <= epsilon then
			return target
		end
		return value
	end

	local function stepToasts(dt)
		local now = os.clock()
		local blend = if preferences.motion then 1 - math.exp(-TOAST_RESPONSE * dt) else 1
		local hidden = toastWidth + TOAST_MARGIN + 30
		local cursor = toastTop
		local kept = 0

		for _, entry in toastLive do
			local slot = entry.slot

			if not entry.leaving then
				if slot.hovered then
					entry.expires += dt
				elseif now >= entry.expires or (cursor > toastTop and cursor + TOAST_HEIGHT > toastFloor) then
					entry.leaving = true
				end
			end

			if not entry.leaving then
				entry.targetY = cursor
				cursor += TOAST_HEIGHT + TOAST_GAP
				slot.timer.Size = UDim2.new(math.clamp((entry.expires - now) / TOAST_LIFETIME, 0, 1), 0, 0, 3)
			end

			local x = approach(entry.x, if entry.leaving then hidden else 0, blend, 0.05)
			local y = approach(entry.y, entry.targetY, blend, 0.05)
			if x ~= entry.x or y ~= entry.y then
				entry.x, entry.y = x, y
				slot.holder.Position = UDim2.new(1, x - TOAST_MARGIN, 0, y)
			end

			local scale = approach(entry.scale, 1, blend, 0.001)
			if scale ~= entry.scale then
				entry.scale = scale
				slot.scale.Scale = scale
			end

			if entry.leaving and x == hidden then
				slot.entry = nil
				slot.hovered = false
				slot.holder.Visible = false
				table.insert(toastFree, slot)
			else
				kept += 1
				toastLive[kept] = entry
			end
		end

		for index = #toastLive, kept + 1, -1 do
			toastLive[index] = nil
		end

		while toastBacklog[1] and toastFree[1] do
			activateToast(table.remove(toastBacklog, 1))
		end

		if not toastLive[1] and toastStepper then
			toastStepper:Disconnect()
			toastStepper = nil
		end
	end

	local function wakeToasts()
		if isAlive() and not toastStepper then
			toastStepper = RunService.Heartbeat:Connect(stepToasts)
		end
	end

	own(function()
		if toastStepper then
			toastStepper:Disconnect()
			toastStepper = nil
		end
		table.clear(toastLive)
		table.clear(toastBacklog)
		table.clear(toastFree)
		table.clear(toastSlots)
	end)

	function self.notify(message, ok, cue)
		if not isAlive() or (not preferences.notifications and ok ~= false) then
			return
		end

		message = tostring(message or "")
		local failed = ok == false

		for _, entry in toastLive do
			if not entry.leaving and entry.failed == failed and entry.message == message then
				entry.repeats += 1
				entry.expires = os.clock() + TOAST_LIFETIME
				entry.scale = 0.96
				entry.slot.scale.Scale = entry.scale
				paintToast(entry.slot, entry)
				Kit.sound(if failed then "error" else cue or "notice")
				wakeToasts()
				return
			end
		end

		local request = { message = message, failed = failed, cue = cue }

		if not activateToast(request) then
			for index = #toastLive, 1, -1 do
				local oldest = toastLive[index]
				if not oldest.leaving then
					oldest.leaving = true
					break
				end
			end

			if #toastBacklog >= TOAST_BACKLOG then
				table.remove(toastBacklog, 1)
			end
			table.insert(toastBacklog, request)
		end

		wakeToasts()
	end

	function self.fit(size, topInset, bottomInset)
		toastWidth = if size.X < 550 then math.max(200, size.X - 88) else math.min(540, size.X - 24)
		-- bottomInset (the bottom tab bar's height, when passed) keeps
		-- toasts from stacking down into the bar — re-checked explicitly
		-- since the bottom bar is new chrome that didn't exist when
		-- toastFloor was first computed from raw screen height.
		toastFloor = size.Y - TOAST_MARGIN - (bottomInset or 0)
		toastTop = TOAST_TOP + (topInset or 0)
		for _, slot in toastSlots do
			slot.holder.Size = UDim2.fromOffset(toastWidth, TOAST_HEIGHT)
		end
	end

	return self
end

return Toast
