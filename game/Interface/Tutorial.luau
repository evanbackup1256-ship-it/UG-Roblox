local Tutorial = {}
Tutorial.__index = Tutorial

-- Guided-setup modal: a fixed sequence of steps from Config.Tutorial, each
-- switching to the relevant page as it's shown. Extracted verbatim from
-- InterfaceController.luau (previously a `do ... end` block) — fully
-- self-contained, touching only root/Kit/C/Icons/Config/preferences and
-- the positionText/act/switchPage/liven helpers passed in, with no
-- dependency on Shared or any page module beyond switchPage.
function Tutorial.new(root, Kit, C, Icons, Config, positionText, act, switchPage, preferences, liven)
	local self = setmetatable({}, Tutorial)

	local tutorialStarted = false
	-- Exposed as self.started (distinct from the internal tutorialStarted
	-- upvalue self.show already guards on) since InterfaceController.luau
	-- needs to check "has this ever started" from outside, at the moment
	-- initial state hydrates, before deciding whether to auto-open it.
	self.started = false

	local tutorialOverlay = Kit.create("Frame", root, {
		Name = "Tutorial",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 70,
	})

	local tutorialModal = Kit.card(tutorialOverlay, "Guide", 390, C.panel)
	tutorialModal.ZIndex = 71
	Kit.hudFrame(tutorialModal, 10, C.accent, 0.4)
	local tutorialModalScale = Kit.create("UIScale", tutorialModal, { Name = "EntryScale", Scale = 1 })

	local tutorialIcon = Kit.icon(tutorialModal, "Icon", "overview", C.accent)
	tutorialIcon.ZIndex = 72

	local tutorialKicker = positionText(tutorialModal, "Kicker", "GUIDED SETUP", 30, 28, 300, 20, 10, C.accent, true)
	tutorialKicker.ZIndex = 72

	local tutorialTitle = positionText(tutorialModal, "Title", "", 30, 74, 520, 70, 28, C.text, true)
	tutorialTitle.TextWrapped = true
	tutorialTitle.TextTruncate = Enum.TextTruncate.None
	tutorialTitle.ZIndex = 72

	local tutorialBody = positionText(tutorialModal, "Body", "", 30, 151, 520, 70, 14, C.muted)
	tutorialBody.TextWrapped = true
	tutorialBody.TextTruncate = Enum.TextTruncate.None
	tutorialBody.ZIndex = 72

	local tutorialProgress = positionText(tutorialModal, "Progress", "", 30, 236, 300, 22, 10, C.muted, true)
	tutorialProgress.ZIndex = 72

	local tutorialDots = {}
	for index = 1, #Config.Tutorial do
		local dot = Kit.create("Frame", tutorialModal, {
			Name = "Step" .. index,
			BackgroundColor3 = C.line,
			BorderSizePixel = 0,
			ZIndex = 72,
		})
		Kit.corner(dot, 3)
		tutorialDots[index] = dot
	end

	local tutorialStep = 1
	local tutorialBack, tutorialNext, tutorialSkip

	local function tutorialLabels()
		local width = tutorialModal.AbsoluteSize.X
		local last = tutorialStep == #Config.Tutorial

		tutorialSkip.Text = if width < 360 then "Skip" else "Skip guide"
		tutorialNext.Text = if width < 360 then "Next"
			elseif width < 480 then (if last then "Finish" else "Continue")
			else (if last then "Finish setup" else "Continue")
	end

	local function renderTutorial()
		local definition = Config.Tutorial[tutorialStep]
		if not definition then
			return
		end

		tutorialIcon.Image = Icons.asset(definition.icon)
		tutorialTitle.Text = definition.title
		tutorialBody.Text = definition.body
		tutorialProgress.Text = string.format("STEP %d OF %d", tutorialStep, #Config.Tutorial)

		for index, dot in ipairs(tutorialDots) do
			dot.BackgroundColor3 = if index <= tutorialStep then C.accent else C.line
		end

		Kit.enable(tutorialBack, tutorialStep > 1, "Back", false)
		tutorialLabels()
		switchPage(definition.page)
	end

	local function closeTutorial()
		if not tutorialOverlay.Visible then
			return
		end

		Kit.sound("release")

		if preferences.motion then
			Kit.animate(tutorialOverlay, { BackgroundTransparency = 1 }, 0.2)
			Kit.animate(tutorialModalScale, { Scale = 0.96 }, 0.2)
			Kit.Scheduler.after(tutorialOverlay, "hide", 0.2, function()
				tutorialOverlay.Visible = false
				tutorialOverlay.BackgroundTransparency = 0.25
				tutorialModalScale.Scale = 1
			end)
		else
			tutorialOverlay.Visible = false
		end

		act("tutorial", "complete", nil, true)
	end

	function self.show(step)
		if tutorialStarted and tutorialOverlay.Visible then
			return
		end

		Kit.sound("page")

		tutorialStarted = true
		self.started = true
		tutorialStep = math.clamp(step or 1, 1, #Config.Tutorial)

		Kit.Scheduler.clear(tutorialOverlay, "hide")
		tutorialOverlay.Visible = true

		if preferences.motion then
			tutorialOverlay.BackgroundTransparency = 1
			tutorialModalScale.Scale = 0.96
			Kit.animate(tutorialOverlay, { BackgroundTransparency = 0.25 }, 0.22)
			Kit.animate(tutorialModalScale, { Scale = 1 }, 0.26, Enum.EasingStyle.Back)
		else
			tutorialOverlay.BackgroundTransparency = 0.25
			tutorialModalScale.Scale = 1
		end

		renderTutorial()
	end

	tutorialBack = Kit.button(tutorialModal, "Back", "Back", function()
		tutorialStep = math.max(1, tutorialStep - 1)
		renderTutorial()
	end)
	tutorialBack.ZIndex = 72

	tutorialNext = liven(Kit.button(tutorialModal, "Next", "Continue", function()
		if tutorialStep >= #Config.Tutorial then
			closeTutorial()
			return
		end

		tutorialStep += 1
		act("tutorial", tostring(tutorialStep), nil, true)
		renderTutorial()
	end, "primary"))

	tutorialSkip = Kit.button(tutorialModal, "Skip", "Skip guide", closeTutorial)
	tutorialSkip.ZIndex = 72

	function self.fit(size)
		local width = math.min(600, size.X - 32)
		local height = if size.X < 480 then 430 else 390

		Kit.place(tutorialModal, (size.X - width) / 2, (size.Y - height) / 2, width, height)
		Kit.place(tutorialIcon, 30, 28, 24, 24)

		tutorialKicker.Position = UDim2.fromOffset(66, 30)
		tutorialTitle.Size = UDim2.fromOffset(width - 60, 70)
		tutorialBody.Size = UDim2.fromOffset(width - 60, if size.X < 480 then 108 else 70)

		local controlsY = height - 70
		tutorialProgress.Position = UDim2.fromOffset(30, controlsY - 66)

		local dotWidth = math.max(16, math.floor((width - 60 - (#tutorialDots - 1) * 6) / #tutorialDots))
		for index, dot in ipairs(tutorialDots) do
			Kit.place(dot, 30 + (index - 1) * (dotWidth + 6), controlsY - 34, dotWidth, 5)
		end

		if width < 480 then
			local buttonWidth = (width - 76) / 3
			Kit.place(tutorialSkip, 30, controlsY, buttonWidth, 42)
			Kit.place(tutorialBack, 38 + buttonWidth, controlsY, buttonWidth, 42)
			Kit.place(tutorialNext, 46 + buttonWidth * 2, controlsY, buttonWidth, 42)
		else
			Kit.place(tutorialSkip, 30, controlsY, 120, 42)
			Kit.place(tutorialBack, width - 250, controlsY, 100, 42)
			Kit.place(tutorialNext, width - 138, controlsY, 108, 42)
		end

		tutorialLabels()
	end

	return self
end

return Tutorial
