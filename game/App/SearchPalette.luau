--!strict
-- SearchPalette: Spotlight command palette with frosted glass scrim,
-- quick shortcuts, fuzzy search results, and seamless keyboard dismiss.
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local Springs = require(script.Parent.Springs)
local Elements = require(script.Parent.Elements)
local Acoustics = require(script.Parent.Acoustics)
local Feedback = require(script.Parent.Feedback)
local Fuzzy = require(script.Parent.Parent.Fuzzy)

local C = Theme.colors
local SearchPalette = {}
SearchPalette.__index = SearchPalette

local MAX_ITEMS = 6

local QUICK_SHORTCUTS = {
	{ label = "Command Deck", subtitle = "Central processing core & telemetry", page = "overview", category = "COMMAND" },
	{ label = "Hardware Procurement", subtitle = "Server racks, clusters & data centers", page = "infrastructure", category = "HARDWARE" },
	{ label = "Research Matrix", subtitle = "Technological upgrades & fleet synergies", page = "research", category = "RESEARCH" },
	{ label = "Firmware Subsystems", subtitle = "Core, array & nexus calibration", page = "modules", category = "MODULE" },
	{ label = "Fleet Operations", subtitle = "Tactical missions & energy reserve", page = "operations", category = "MISSIONS" },
}

function SearchPalette.new(overlayRoot: Instance, entries: { any }, switchScreen: (string) -> ())
	local self = setmetatable({}, SearchPalette)

	-- Full-screen modal overlay container frame
	local overlay = Elements.create("Frame", overlayRoot, {
		Name = "SearchPaletteOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 110,
		Visible = false,
	})

	-- Dismiss scrim backdrop button
	local scrim = Elements.create("TextButton", overlay, {
		Name = "ScrimBackdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 111,
	})

	-- Centered spotlight card (Active = true sinks clicks so clicking inside NEVER dismisses)
	local modal = Elements.create("CanvasGroup", overlay, {
		Name = "SearchModal",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 75),
		Size = UDim2.new(0.92, 0, 0, 58),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		ClipsDescendants = true,
		Active = true,
		ZIndex = 115,
	})
	Elements.corner(modal, Theme.radii.card)

	local sizeConstraint = Elements.create("UISizeConstraint", modal, {
		MaxSize = Vector2.new(560, 900),
		MinSize = Vector2.new(280, 58),
	})

	local modalScale = Elements.create("UIScale", modal, {
		Name = "ModalScale",
		Scale = 1,
	})

	-- Subtle satin shimmer across the top edge of modal


	-- Ambient drop stroke around the spotlight modal
	local modalStroke = Elements.stroke(modal, C.hairlineGlow, 1, 0.50)

	-- Search icon
	local searchIcon = Elements.icon(modal, "SearchIcon", "search", C.accent)
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.Position = UDim2.new(0, 18, 0, 29)
	searchIcon.Size = UDim2.fromOffset(20, 20)
	searchIcon.ZIndex = 120

	-- Search text input box (ends at Width - 96, leaving 8px before clear button at Width - 88)
	local searchBox = Elements.create("TextBox", modal, {
		Name = "SearchBox",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 48, 0, 29),
		Size = UDim2.new(1, -144, 0, 44),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "Jump to hardware, research, modules…",
		PlaceholderColor3 = C.textMuted,
		TextColor3 = C.textPrimary,
		Font = Theme.typography.fontBody,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 120,
	})

	-- Clear button inside the search box (Width - 88 to Width - 66)
	local clearBtn = Elements.create("TextButton", modal, {
		Name = "ClearBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -66, 0, 29),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Text = "×",
		Font = Theme.typography.fontBold,
		TextSize = 14,
		TextColor3 = C.textMuted,
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 122,
	})
	Elements.corner(clearBtn, Theme.radii.pill)

	clearBtn.MouseEnter:Connect(function()
		Springs.target(clearBtn, { BackgroundColor3 = C.elevated, TextColor3 = C.textPrimary }, "smooth")
	end)
	clearBtn.MouseLeave:Connect(function()
		Springs.target(clearBtn, { BackgroundColor3 = C.recessed, TextColor3 = C.textMuted }, "smooth")
	end)
	clearBtn.Activated:Connect(function()
		searchBox.Text = ""
		searchBox:CaptureFocus()
	end)

	-- Close [ESC] badge button on the right (Width - 60 to Width - 14)
	local closeBtn = Elements.create("TextButton", modal, {
		Name = "CloseBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, 29),
		Size = UDim2.fromOffset(46, 26),
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Text = "ESC ✕",
		Font = Theme.typography.fontMono,
		TextSize = 10,
		TextColor3 = C.textMuted,
		AutoButtonColor = false,
		ZIndex = 122,
	})
	Elements.corner(closeBtn, Theme.radii.badge)
	Elements.stroke(closeBtn, C.hairline, 1, 0.60)

	closeBtn.MouseEnter:Connect(function()
		Springs.target(closeBtn, { BackgroundColor3 = C.elevated, TextColor3 = C.textPrimary }, "smooth")
	end)
	closeBtn.MouseLeave:Connect(function()
		Springs.target(closeBtn, { BackgroundColor3 = C.recessed, TextColor3 = C.textMuted }, "smooth")
	end)

	-- Instant dismiss on click or touch for scrim and close button
	local function dismiss()
		self:hide()
	end
	closeBtn.Activated:Connect(dismiss)
	closeBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dismiss()
		end
	end)

	scrim.Activated:Connect(dismiss)
	scrim.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dismiss()
		end
	end)

	-- Divider between search input and result list
	local divider = Elements.divider(modal, true)
	divider.Position = UDim2.new(0, 16, 0, 58)
	divider.Size = UDim2.new(1, -32, 0, 1)
	divider.Visible = false

	-- Results container with dynamic height
	local resultsContainer = Elements.create("Frame", modal, {
		Name = "Results",
		Position = UDim2.new(0, 0, 0, 59),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 118,
	})

	local rowButtons = {}
	for i = 1, MAX_ITEMS do
		local row = Elements.create("TextButton", resultsContainer, {
			Name = "Row_" .. i,
			Size = UDim2.new(1, -16, 0, 44),
			Position = UDim2.new(0, 8, 0, 6 + (i - 1) * 46),
			BackgroundColor3 = C.recessed,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Visible = false,
			ZIndex = 120,
		})
		Elements.corner(row, Theme.radii.control)

		local rTitle = Elements.text(row, "Title", "", 13, C.textPrimary, true)
		rTitle.Position = UDim2.new(0, 16, 0, 5)
		rTitle.Size = UDim2.new(1, -140, 0, 18)
		rTitle.TextTruncate = Enum.TextTruncate.AtEnd

		local rDetail = Elements.text(row, "Detail", "", 11, C.textMuted)
		rDetail.Position = UDim2.new(0, 16, 0, 23)
		rDetail.Size = UDim2.new(1, -140, 0, 16)
		rDetail.TextTruncate = Enum.TextTruncate.AtEnd

		local rBadge = Elements.badge(row, "GO", "accent", true)
		rBadge.AnchorPoint = Vector2.new(1, 0.5)
		rBadge.Position = UDim2.new(1, -12, 0.5, 0)
		rBadge.Size = UDim2.fromOffset(80, 22)

		row.MouseEnter:Connect(function()
			Springs.target(row, { BackgroundColor3 = C.elevated, BackgroundTransparency = 0 }, "smooth")
			rTitle.TextColor3 = C.accent
		end)
		row.MouseLeave:Connect(function()
			Springs.target(row, { BackgroundTransparency = 1 }, "smooth")
			rTitle.TextColor3 = C.textPrimary
		end)

		rowButtons[i] = {
			button = row,
			title = rTitle,
			detail = rDetail,
			badge = rBadge,
			targetPage = "",
		}
	end

	local firstTargetPage = ""

	local function renderMatches(items: { any }, isQueryActive: boolean?)
		local shown = math.min(#items, MAX_ITEMS)

		if shown == 0 and isQueryActive then
			firstTargetPage = ""
			local r = rowButtons[1]
			r.title.Text = "No matching systems found"
			r.detail.Text = "Try keywords like hardware, research, modules, dispatch…"
			r.targetPage = ""
			r.button.Visible = true

			local badgeLabel = r.badge:FindFirstChild("BadgeText") :: TextLabel?
			if badgeLabel then
				badgeLabel.Text = "EMPTY"
			end

			for i = 2, MAX_ITEMS do
				rowButtons[i].button.Visible = false
				rowButtons[i].targetPage = ""
			end

			divider.Visible = true
			resultsContainer.Size = UDim2.new(1, 0, 0, 58)
			Springs.target(modal, { Size = UDim2.new(0.92, 0, 0, 116) }, "snappy")
			return
		end

		firstTargetPage = if shown > 0 then (items[1].page or "overview") else ""

		for i = 1, MAX_ITEMS do
			local r = rowButtons[i]
			if i <= shown then
				local m = items[i]
				r.title.Text = m.label or m.name or ""
				r.detail.Text = m.subtitle or m.category or ""
				r.targetPage = m.page or "overview"
				r.button.Visible = true

				local badgeLabel = r.badge:FindFirstChild("BadgeText") :: TextLabel?
				if badgeLabel then
					badgeLabel.Text = string.upper(m.category or m.page or "GO")
				end
			else
				r.button.Visible = false
				r.targetPage = ""
			end
		end

		divider.Visible = (shown > 0)
		local resultsH = if shown > 0 then (shown * 46 + 12) else 0
		resultsContainer.Size = UDim2.new(1, 0, 0, resultsH)
		Springs.target(modal, { Size = UDim2.new(0.92, 0, 0, 58 + resultsH) }, "snappy")
	end

	local function updateResults(query: string)
		clearBtn.Visible = (query ~= "")
		if query == "" then
			renderMatches(QUICK_SHORTCUTS)
			return
		end

		local matches = {}
		for _, entry in ipairs(entries) do
			local labelLower = string.lower(entry.label or entry.name or "")
			local haystack = string.lower(entry.keywords or entry.search or labelLower)
			local score = 0

			-- Intelligent multi-tiered relevance scoring:
			if string.sub(labelLower, 1, #query) == query then
				-- Exact prefix of title -> maximum relevance
				score += 10000 + (100 - #labelLower)
			elseif string.find(labelLower, query, 1, true) then
				-- Substring inside title
				score += 5000 + (100 - #labelLower)
			elseif string.find(haystack, query, 1, true) then
				-- Substring inside keywords/category
				score += 2000
			else
				local fScore = Fuzzy.score(query, haystack)
				if fScore and fScore > 0 then
					score += fScore
				end
			end

			if score > 0 then
				table.insert(matches, { entry = entry, score = score })
			end
		end

		table.sort(matches, function(a, b) return a.score > b.score end)

		local list = {}
		for _, item in ipairs(matches) do
			table.insert(list, item.entry)
		end

		renderMatches(list, query ~= "")
	end

	for _, r in ipairs(rowButtons) do
		r.button.Activated:Connect(function()
			if r.targetPage ~= "" then
				Acoustics.play("tab", 0.04)
				switchScreen(r.targetPage)
				self:hide()
			end
		end)
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		updateResults(string.lower(searchBox.Text))
	end)

	-- Handle Enter to select top match and ESC to dismiss
	searchBox.FocusLost:Connect(function(enterPressed, inputThatCausedFocusLost)
		if inputThatCausedFocusLost and inputThatCausedFocusLost.KeyCode == Enum.KeyCode.Escape then
			self:hide()
		elseif enterPressed and firstTargetPage ~= "" then
			Acoustics.play("tab", 0.04)
			switchScreen(firstTargetPage)
			self:hide()
		end
	end)

	-- Global Escape key listener
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.Escape and overlay.Visible then
			self:hide()
		end
	end)

	self.overlay = overlay
	self.scrim = scrim
	self.modal = modal
	self.modalScale = modalScale
	self.searchBox = searchBox
	self.updateResults = updateResults
	self.firstTargetPage = function() return firstTargetPage end
	self.hideThread = nil
	return self
end

function SearchPalette:isOpen(): boolean
	return self.overlay.Visible
end

function SearchPalette:show()
	if self.hideThread then
		pcall(task.cancel, self.hideThread)
		self.hideThread = nil
	end

	self.overlay.Visible = true
	self.scrim.BackgroundTransparency = 1
	Springs.target(self.scrim, { BackgroundTransparency = 0.55 }, "smooth")

	self.modal.Position = UDim2.new(0.5, 0, 0, 45)
	self.modalScale.Scale = 0.96
	self.modal.GroupTransparency = 1
	Springs.target(self.modal, { Position = UDim2.new(0.5, 0, 0, 75), GroupTransparency = 0 }, "smooth")
	Springs.target(self.modalScale, { Scale = 1.0 }, "smooth")

	self.searchBox.Text = ""
	self.updateResults("")
	task.defer(function()
		if self.overlay.Visible then
			self.searchBox:CaptureFocus()
		end
	end)
end

function SearchPalette:open()
	self:show()
end

function SearchPalette:hide()
	self.searchBox:ReleaseFocus()
	Springs.target(self.scrim, { BackgroundTransparency = 1 }, "smooth")
	Springs.target(self.modal, { Position = UDim2.new(0.5, 0, 0, 45), GroupTransparency = 1 }, "smooth")
	Springs.target(self.modalScale, { Scale = 0.96 }, "smooth")

	if self.hideThread then
		pcall(task.cancel, self.hideThread)
	end
	self.hideThread = task.delay(0.2, function()
		self.hideThread = nil
		if not self.overlay then return end
		self.overlay.Visible = false
		self.searchBox.Text = ""
	end)
end

function SearchPalette:close()
	self:hide()
end

function SearchPalette:toggle()
	if self:isOpen() then
		self:hide()
	else
		self:show()
	end
end

function SearchPalette:Destroy()
	if self.overlay then
		self.overlay:Destroy()
	end
end
SearchPalette.destroy = SearchPalette.Destroy

return SearchPalette
