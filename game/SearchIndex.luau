-- SearchIndex: a static, build-once index of everything global search can
-- jump to — the pages plus every catalogue entry (tiers, research,
-- modules, shop offers, contracts, achievements). Built straight from
-- Config, the same source every page renders from.
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

-- `definitions` is InterfaceController's page list ({key, navTitle,
-- headingTitle, headingDescription}).
function M.build(definitions, Config): { Entry }
	local entries = {}

	for _, definition in ipairs(definitions) do
		local key = definition.key or definition[1]
		if key then
			local label = definition.shortTitle or definition.headingTitle or definition[3] or definition[2] or key
			local subtitle = definition.breadcrumb or definition.headingDescription or definition[4] or ""
			table.insert(entries, {
				id = "page:" .. key,
				label = label,
				subtitle = subtitle,
				category = "Page",
				page = key,
				keywords = string.lower(label .. " " .. key .. " " .. subtitle),
			})
		end
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
						keywords = string.lower(item.name .. " " .. (item.subtitle or "") .. " " .. item.key .. " " .. catalogue.category .. " " .. catalogue.page),
					})
				end
			end
		end
	end

	return entries
end

return M
