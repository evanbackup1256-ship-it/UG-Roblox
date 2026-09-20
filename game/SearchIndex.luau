-- SearchIndex: a static, build-once index of everything global search can
-- jump to — the 12 pages plus every catalogue entry (tiers, research,
-- modules, shop offers, contracts, achievements). Built straight from
-- Config (the same source every page module already renders from) rather
-- than querying each page module's rendered state, so it needs zero
-- changes to any of the 11 page modules and stays correct automatically
-- as Config grows. Pure data/logic, no UI dependency — sanity-checkable
-- from Studio's command bar before any search UI exists.
export type Entry = {
	id: string,
	label: string,
	subtitle: string?,
	category: string,
	page: string,
	keywords: string,
}

local M = {}

local CATALOGUES = {
	{ field = "Tiers", category = "Hardware", page = "infrastructure" },
	{ field = "Research", category = "Research", page = "research" },
	{ field = "Modules", category = "Module", page = "modules" },
	{ field = "ShopOffers", category = "Shop", page = "shop" },
	{ field = "Contracts", category = "Contract", page = "contracts" },
	{ field = "Achievements", category = "Achievement", page = "rewards" },
}

-- `definitions` is InterfaceController.luau's existing 12-entry page list
-- ({key, navTitle, headingTitle, headingDescription}) — passed by
-- reference, not duplicated, so this index and the nav rail always agree
-- on page names.
function M.build(definitions, Config): { Entry }
	local entries = {}

	for _, definition in ipairs(definitions) do
		local key, navTitle, headingTitle, headingDescription = definition[1], definition[2], definition[3], definition[4]
		table.insert(entries, {
			id = "page:" .. key,
			label = headingTitle or navTitle,
			subtitle = headingDescription,
			category = "Page",
			page = key,
			keywords = string.lower((headingTitle or navTitle) .. " " .. navTitle .. " " .. (headingDescription or "")),
		})
	end

	for _, catalogue in ipairs(CATALOGUES) do
		local items = Config[catalogue.field]
		if items then
			for _, item in ipairs(items) do
				if item.key and item.name then
					table.insert(entries, {
						id = catalogue.field .. ":" .. item.key,
						label = item.name,
						subtitle = item.subtitle,
						category = catalogue.category,
						page = catalogue.page,
						keywords = string.lower(item.name .. " " .. (item.subtitle or "") .. " " .. item.key),
					})
				end
			end
		end
	end

	return entries
end

return M
