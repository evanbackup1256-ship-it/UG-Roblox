local Primitives = require(script.Parent.Primitives)

local M = {}

--======================================================================--
-- Layout: pure coordinate math over the existing Kit.place, not Roblox
-- layout instances (UIListLayout/UIGridLayout). A layout instance would
-- override manual Position every frame, silently fighting every spring-
-- driven entrance animation and the page-transition slide — Kit.stack/
-- Kit.grid only ever decide WHERE Kit.place puts something; nothing about
-- Kit.card/Kit.place itself changes. Every page's layoutPage callback can
-- adopt these incrementally, one call site at a time — nothing breaks for
-- pages that keep hand-rolling their own Y-cursor math.
--======================================================================--

-- Vertical run of items at a shared x/width, replacing the hand-rolled
-- `y += height + gap` cursor duplicated per page. `items` is an array of
-- either an Instance (uses its own current Size.Y.Offset as height) or
-- {instance, height} for an explicit height. Returns the Y position AFTER
-- the stack, so callers can keep placing more content below it.
function M.stack(items, x, y, width, gap)
	gap = gap or 12
	local cursor = y

	for _, item in ipairs(items) do
		local instance, height
		if typeof(item) == "Instance" then
			instance, height = item, item.Size.Y.Offset
		else
			instance, height = item[1], item[2]
		end

		Primitives.place(instance, x, cursor, width, height)
		cursor += height + gap
	end

	return cursor
end

-- N-column wrapping grid, replacing the `columns = math.clamp((w+16)//300,
-- 1, 3)` + `(shown % columns)*(cw+16)` math duplicated per page (each with
-- slightly different breakpoints today). `items` is an array of Instances.
-- `opts.rowHeight` may be a fixed number or a function(instance) -> number
-- for per-item heights. Returns (nextY, columns, columnWidth) so callers
-- that resize per-item content (e.g. wrapping a name label to the new
-- column width) can still do so.
function M.grid(items, x, y, width, opts)
	opts = opts or {}
	local minColumnWidth = opts.minColumnWidth or 300
	local maxColumns = opts.maxColumns or 3
	local gap = opts.gap or 16
	local rowHeight = opts.rowHeight or 200

	local columns = math.clamp((width + gap) // (minColumnWidth + gap), 1, maxColumns)
	columns = math.max(1, columns)
	local columnWidth = (width - (columns - 1) * gap) / columns

	local tallestInRow = 0
	local rowStartIndex = 1

	for index, instance in ipairs(items) do
		local column = (index - 1) % columns
		local row = (index - 1) // columns

		local height = if type(rowHeight) == "function" then rowHeight(instance) else rowHeight

		local itemX = x + column * (columnWidth + gap)
		local itemY = y + row * (height + gap)
		Primitives.place(instance, itemX, itemY, columnWidth, height)

		if column == 0 then
			tallestInRow = height
			rowStartIndex = index
		else
			tallestInRow = math.max(tallestInRow, height)
		end
	end

	if #items == 0 then
		return y, columns, columnWidth
	end

	local rows = ((#items - 1) // columns) + 1
	local nextY = y
	if type(rowHeight) == "function" then
		-- Per-item heights: re-walk rows to sum actual row heights rather
		-- than assuming a fixed rowHeight for every row.
		local cursor = y
		local index = 1
		while index <= #items do
			local rowMax = 0
			for column = 0, columns - 1 do
				local item = items[index + column]
				if item then
					rowMax = math.max(rowMax, rowHeight(item))
				end
			end
			cursor += rowMax + gap
			index += columns
		end
		nextY = cursor
	else
		nextY = y + rows * (rowHeight + gap)
	end

	return nextY, columns, columnWidth
end

return M
