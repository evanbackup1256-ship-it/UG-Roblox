local Fuzzy = require(script.Parent.Parent.Fuzzy)

local GlobalSearch = {}
GlobalSearch.__index = GlobalSearch

local MAX_RESULTS = 8
local ROW_HEIGHT = 40

-- Global search: a header search box + dropdown results panel, backed by
-- SearchIndex's static entry list and Fuzzy's subsequence scorer (the same
-- matcher Infrastructure's own search uses, so there's one matching
-- algorithm across the whole game, not two). v1 jumps to the target page
-- only on selection — true per-item scroll-to-highlight would need every
-- catalogue page to register its own instances on Shared, which is
-- deferred (see the plan's fast-follow list) rather than done here.
--
-- `overlayRoot` is a separate parent from `header` for the results panel:
-- header is fixed at 68px tall (InterfaceController.luau's fit()), and the
-- panel needs to extend well below that — parenting it inside header put
-- almost the entire panel outside header's own local bounds, and combined
-- with the panel's own ClipsDescendants and a Size that was never given a
-- real starting value before the first layout pass, it rendered nothing.
function GlobalSearch.new(header, overlayRoot, Kit, C, entries, switchPage, connect)
	local self = setmetatable({}, GlobalSearch)

	local box = Kit.input(header, "GlobalSearch", "Search…")
	box.ZIndex = 60

	-- Below the `wide` breakpoint, the real box hides and this icon button
	-- takes its place; clicking it expands the box as an overlay (widened,
	-- focused) rather than trying to type into a ~40px sliver.
	local trigger
	local expanded = false
	local layout -- forward-declared; assigned below, called here by reference

	local function collapseBox()
		expanded = false
		box.Text = ""
	end

	local function expandBox()
		expanded = true
		if layout then
			layout()
		end
		box:CaptureFocus()
	end

	trigger = Kit.button(header, "SearchTrigger", "", expandBox, "icon")
	trigger.ZIndex = 60
	Kit.place(Kit.icon(trigger, "Icon", "search", C.muted), 11, 11, 18, 18)

	-- Parented to overlayRoot (not header — see the file-level comment
	-- above), and given a real starting Size immediately so the very first
	-- layout()/runQuery() pass has a real AbsoluteSize to read rather than
	-- Roblox's zero-ish default for a never-explicitly-sized Frame.
	local panel = Kit.create("Frame", overlayRoot, {
		Name = "GlobalSearchResults",
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 65,
		ClipsDescendants = true,
		Size = UDim2.fromOffset(260, 0),
	})
	Kit.corner(panel, Kit.radius.control)
	Kit.stroke(panel, C.line, 0.7, false)

	local rows = {}
	for index = 1, MAX_RESULTS do
		local row = Kit.create("TextButton", panel, {
			Name = "Result" .. index,
			Text = "",
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Visible = false,
			ZIndex = 66,
		})

		local label = Kit.text(row, "Label", "", 13, C.text, true)
		label.ZIndex = 67
		label.Position = UDim2.fromOffset(14, 4)

		local meta = Kit.text(row, "Meta", "", 11, C.muted)
		meta.ZIndex = 67
		meta.Position = UDim2.fromOffset(14, 21)

		connect(row.MouseEnter, function()
			row.BackgroundColor3 = C.raised
			row.BackgroundTransparency = 0
		end)
		connect(row.MouseLeave, function()
			row.BackgroundTransparency = 1
		end)

		rows[index] = { row = row, label = label, meta = meta, entry = nil }
	end

	local function closeResults()
		panel.Visible = false
	end

	local function runQuery(text)
		local query = string.gsub(text, "^%s+", "")
		query = string.gsub(query, "%s+$", "")

		if query == "" then
			closeResults()
			return
		end

		local scored = {}
		for _, entry in ipairs(entries) do
			local score = Fuzzy.score(query, entry.keywords)
			if score then
				table.insert(scored, { entry = entry, score = score })
			end
		end
		table.sort(scored, function(a, b)
			return a.score > b.score
		end)

		local shown = math.min(#scored, MAX_RESULTS)
		for index = 1, MAX_RESULTS do
			local slot = rows[index]
			if index <= shown then
				local entry = scored[index].entry
				slot.entry = entry
				slot.label.Text = entry.label
				slot.meta.Text = entry.category .. (if entry.subtitle then "  ·  " .. entry.subtitle else "")
				slot.row.Visible = true
			else
				slot.entry = nil
				slot.row.Visible = false
			end
		end

		panel.Visible = shown > 0
		panel.Size = UDim2.fromOffset(panel.AbsoluteSize.X, shown * ROW_HEIGHT)
	end

	for _, slot in ipairs(rows) do
		slot.row.Activated:Connect(function()
			if slot.entry then
				switchPage(slot.entry.page)
				box.Text = ""
				closeResults()
			end
		end)
	end

	connect(box:GetPropertyChangedSignal("Text"), function()
		runQuery(box.Text)
	end)

	local lastX, lastY, lastWidth, lastWide = 0, 0, 200, true

	layout = function()
		if lastWide then
			box.Visible = true
			trigger.Visible = false
			Kit.place(box, lastX, lastY, lastWidth, 36)
		elseif expanded then
			box.Visible = true
			trigger.Visible = false
			-- Overlay: widen past the collapsed column so there's room to
			-- actually type, anchored to the same right edge the trigger
			-- button sits at.
			local overlayWidth = math.min(260, lastWidth + 160)
			Kit.place(box, lastX + lastWidth - overlayWidth, lastY, overlayWidth, 36)
		else
			box.Visible = false
			trigger.Visible = true
			Kit.place(trigger, lastX + lastWidth - 40, lastY - 2, 40, 40)
		end

		-- Right-align the results panel under whichever control is
		-- currently visible (the full box, the overlay box, or the
		-- collapsed trigger), since all three share the same right edge.
		-- panel parents to overlayRoot, not header (header is fixed at
		-- 68px tall — far too short to contain a multi-row dropdown), so
		-- its position is header's AbsolutePosition plus the same local
		-- offset box/trigger use, converted into overlayRoot's own local
		-- space by subtracting overlayRoot's own AbsolutePosition.
		local panelWidth = math.max(220, lastWidth)
		local headerAbsolute = header.AbsolutePosition
		local overlayAbsolute = overlayRoot.AbsolutePosition
		local panelX = headerAbsolute.X + lastX + lastWidth - panelWidth - overlayAbsolute.X
		local panelY = headerAbsolute.Y + lastY + 40 - overlayAbsolute.Y
		Kit.place(panel, panelX, panelY, panelWidth, panel.AbsoluteSize.Y)
	end

	connect(box.FocusLost, function()
		-- Deferred so a click on a result row (which itself steals focus
		-- from the box, firing FocusLost first) isn't closed out from under
		-- the click before Activated has a chance to fire.
		task.defer(function()
			if not box:IsFocused() then
				closeResults()
				if not lastWide then
					collapseBox()
					layout()
				end
			end
		end)
	end)

	-- `wide` is whether the box shows as a full text field (true) or
	-- collapses to an icon-trigger that expands into an overlay on click
	-- (false) — the caller decides the breakpoint (matches the nav rail's
	-- own `compact` pattern) and passes the already-computed boolean plus
	-- the available x/y/width.
	function self.fit(x, y, width, wide)
		lastX, lastY, lastWidth, lastWide = x, y, width, wide
		if wide then
			expanded = false
		end
		layout()
	end

	return self
end

return GlobalSearch
