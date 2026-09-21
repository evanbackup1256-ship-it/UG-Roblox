--!strict
-- TourGuide: Interactive onboarding walkthrough console
local Theme = require(script.Parent.Theme)
local Springs = require(script.Parent.Springs)
local Elements = require(script.Parent.Elements)
local Buttons = require(script.Parent.Buttons)

local C = Theme.colors
local TourGuide = {}
TourGuide.__index = TourGuide

function TourGuide.new(root: Instance, Config: any, act: (string, string?, any?, boolean?) -> (), switchScreen: (string) -> ())
	local self = setmetatable({}, TourGuide)
	self.step = 1
	self.started = false

	local overlay = Elements.create("Frame", root, {
		Name = "TourOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 80,
	})

	local modal = Elements.card(overlay, "TourModal", 360, C.card)
	modal.Size = UDim2.new(0.92, 0, 0, 360)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.ZIndex = 81

	local sizeConstraint = Elements.create("UISizeConstraint", modal, {
		MaxSize = Vector2.new(560, 420),
		MinSize = Vector2.new(280, 340),
	})

	local modalScale = Elements.create("UIScale", modal, { Scale = 0.9 })

	local kicker = Elements.text(modal, "Kicker", "SYSTEM ONBOARDING", 11, C.accent, true)
	kicker.Font = Theme.typography.fontMono
	kicker.Position = UDim2.new(0, 24, 0, 24)
	kicker.Size = UDim2.new(1, -48, 0, 20)

	local title = Elements.text(modal, "Title", "", 22, C.textPrimary, true)
	title.TextWrapped = true
	title.Position = UDim2.new(0, 24, 0, 50)
	title.Size = UDim2.new(1, -48, 0, 60)

	local body = Elements.text(modal, "Body", "", 13, C.textSecondary)
	body.TextWrapped = true
	body.Position = UDim2.new(0, 24, 0, 116)
	body.Size = UDim2.new(1, -48, 0, 76)

	local progressLabel = Elements.text(modal, "Progress", "", 11, C.textMuted, true)
	progressLabel.Font = Theme.typography.fontMono
	progressLabel.Position = UDim2.new(0, 24, 0, 200)
	progressLabel.Size = UDim2.new(1, -48, 0, 20)

	local stepDots = {}
	local totalSteps = #Config.Tutorial
	for i = 1, totalSteps do
		local dot = Elements.create("Frame", modal, {
			Name = "Dot_" .. i,
			Size = UDim2.fromOffset(16, 4),
			Position = UDim2.fromOffset(24 + (i - 1) * 22, 230),
			BackgroundColor3 = C.hairline,
			BorderSizePixel = 0,
		})
		Elements.corner(dot, 2)
		stepDots[i] = dot
	end

	local btnNext: TextButton
	local btnBack: TextButton
	local btnSkip: TextButton

	local function renderStep()
		local stepData = Config.Tutorial[self.step]
		if not stepData then return end

		title.Text = stepData.title
		body.Text = stepData.body
		progressLabel.Text = string.format("STEP %d / %d", self.step, totalSteps)

		for i = 1, totalSteps do
			stepDots[i].BackgroundColor3 = if i <= self.step then C.accent else C.hairline
		end

		btnNext.Text = if self.step >= totalSteps then "Complete Guide" else "Next Step"
		btnBack.Visible = self.step > 1

		if stepData.page then
			switchScreen(stepData.page)
		end
	end

	btnNext = Buttons.button(modal, "NextBtn", "Next Step", function()
		if self.step >= totalSteps then
			act("tutorial", "complete")
			self:hide()
		else
			self.step += 1
			act("tutorial", tostring(self.step))
			renderStep()
		end
	end, "primary")
	btnNext.AnchorPoint = Vector2.new(1, 1)

	btnBack = Buttons.button(modal, "BackBtn", "Back", function()
		if self.step > 1 then
			self.step -= 1
			act("tutorial", tostring(self.step))
			renderStep()
		end
	end, "secondary")
	btnBack.AnchorPoint = Vector2.new(1, 1)

	btnSkip = Buttons.button(modal, "SkipBtn", "Dismiss", function()
		act("tutorial", "complete")
		self:hide()
	end, "ghost")
	btnSkip.AnchorPoint = Vector2.new(0, 1)

	local function updateButtons(w: number)
		if w < 380 then
			btnSkip.Position = UDim2.new(0, 16, 1, -20)
			btnSkip.Size = UDim2.fromOffset(64, 36)

			btnNext.Position = UDim2.new(1, -16, 1, -20)
			btnNext.Size = UDim2.fromOffset(100, 36)

			btnBack.Position = UDim2.new(1, -122, 1, -20)
			btnBack.Size = UDim2.fromOffset(60, 36)
		else
			btnSkip.Position = UDim2.new(0, 24, 1, -24)
			btnSkip.Size = UDim2.fromOffset(80, 40)

			btnNext.Position = UDim2.new(1, -24, 1, -24)
			btnNext.Size = UDim2.fromOffset(140, 40)

			btnBack.Position = UDim2.new(1, -174, 1, -24)
			btnBack.Size = UDim2.fromOffset(80, 40)
		end
	end

	updateButtons(modal.AbsoluteSize.X > 0 and modal.AbsoluteSize.X or 400)
	modal:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updateButtons(modal.AbsoluteSize.X)
	end)

	self.overlay = overlay
	self.modal = modal
	self.modalScale = modalScale
	self.renderStep = renderStep
	return self
end

function TourGuide:show(startStep: number?)
	self.step = startStep or 1
	self.started = true
	self.overlay.Visible = true
	self.modalScale.Scale = 0.92
	Springs.target(self.modalScale, { Scale = 1.0 }, "smooth")
	self.renderStep()
end

function TourGuide:hide()
	Springs.target(self.modalScale, { Scale = 0.9 }, "smooth")
	task.delay(0.15, function()
		self.overlay.Visible = false
		self.started = false
	end)
end

function TourGuide:Destroy()
	if self.overlay then
		self.overlay:Destroy()
	end
end
TourGuide.destroy = TourGuide.Destroy

return TourGuide

