-- ThemePresets: Refined, high-craft accent themes for Sleek Obsidian
local M = {}

M.presets = {
	azure = {
		accent = Color3.fromRGB(56, 139, 253),     -- Electric Azure (#388BFD)
		accent2 = Color3.fromRGB(245, 158, 11),    -- Warm Amber
		ink = Color3.fromRGB(10, 13, 18),
	},
	mint = {
		accent = Color3.fromRGB(16, 185, 129),     -- Emerald Mint (#10B981)
		accent2 = Color3.fromRGB(56, 139, 253),    -- Electric Azure
		ink = Color3.fromRGB(8, 18, 14),
	},
	amber = {
		accent = Color3.fromRGB(245, 158, 11),     -- Warm Amber (#F59E0B)
		accent2 = Color3.fromRGB(16, 185, 129),    -- Emerald Mint
		ink = Color3.fromRGB(24, 16, 6),
	},
	purple = {
		accent = Color3.fromRGB(139, 92, 246),     -- Iris Purple (#8B5CF6)
		accent2 = Color3.fromRGB(56, 139, 253),    -- Electric Azure
		ink = Color3.fromRGB(16, 10, 26),
	},
	rose = {
		accent = Color3.fromRGB(244, 63, 94),      -- Electric Rose (#F43F5E)
		accent2 = Color3.fromRGB(245, 158, 11),    -- Warm Amber
		ink = Color3.fromRGB(26, 8, 12),
	},
}

M.order = { "azure", "mint", "amber", "purple", "rose" }

M.labels = {
	azure = "Electric Azure",
	mint = "Emerald Mint",
	amber = "Warm Amber",
	purple = "Iris Purple",
	rose = "Electric Rose",
}

M.default = "azure"

return M
