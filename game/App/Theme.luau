--!strict
-- Theme: Design Tokens and Aesthetic System for Sleek Obsidian
-- Refined neutral charcoals, satin surfaces, crisp 1px hairlines,
-- and intentional high-contrast accents (Linear / Apple VisionOS).
local Theme = {}

Theme.colors = {
	-- Neutral surface depths
	canvas = Color3.fromRGB(10, 10, 12),          -- Deep canvas backing
	panel = Color3.fromRGB(18, 18, 22),           -- Sidebar, dock, header
	card = Color3.fromRGB(26, 26, 30),            -- Standard card surface
	elevated = Color3.fromRGB(36, 36, 42),        -- Interactive hover / modal
	recessed = Color3.fromRGB(14, 14, 16),        -- Well track / inset
	glass = Color3.fromRGB(22, 22, 26),           -- Semi-translucent surface

	-- Crisp 1px hairlines
	hairline = Color3.fromRGB(42, 42, 48),       -- Standard hairline border
	hairlineSubtle = Color3.fromRGB(32, 32, 38), -- Very faint divider
	hairlineGlow = Color3.fromRGB(59, 130, 246), -- #3B82F6 Active focus hairline

	-- Typography
	textPrimary = Color3.fromRGB(248, 250, 252), -- #F8FAFC Primary crisp white
	textSecondary = Color3.fromRGB(148, 163, 184),-- #94A3B8 Secondary slate label
	textMuted = Color3.fromRGB(100, 116, 139),   -- #64748B Subdued metadata / captions
	textInverse = Color3.fromRGB(10, 13, 18),    -- #0A0D12 Dark text on bright buttons

	-- Semantic Currencies
	compute = Color3.fromRGB(16, 185, 129),      -- #10B981 Emerald Mint
	energy = Color3.fromRGB(245, 158, 11),       -- #F59E0B Warm Amber
	data = Color3.fromRGB(6, 182, 212),          -- #06B6D4 Electric Cyan
	reputation = Color3.fromRGB(139, 92, 246),   -- #8B5CF6 Amethyst Spec
	overclock = Color3.fromRGB(236, 72, 153),    -- #EC4899 Plasma Rose

	-- Semantic States
	accent = Color3.fromRGB(59, 130, 246),       -- #3B82F6 Electric Azure (primary)
	accent2 = Color3.fromRGB(245, 158, 11),      -- Secondary gold highlight
	success = Color3.fromRGB(16, 185, 129),      -- Positive mint
	warning = Color3.fromRGB(245, 158, 11),      -- Caution amber
	danger = Color3.fromRGB(239, 68, 68),        -- #EF4444 Danger crimson
	error = Color3.fromRGB(239, 68, 68),         -- Error crimson
	gold = Color3.fromRGB(245, 158, 11),         -- Warm Amber Gold
	mint = Color3.fromRGB(16, 185, 129),         -- Mint shortcut
	amber = Color3.fromRGB(245, 158, 11),        -- Amber shortcut

	-- Safe background aliases & badge backgrounds
	bg = Color3.fromRGB(9, 11, 15),
	badgeMintBg = Color3.fromRGB(16, 32, 24),
	badgeAmberBg = Color3.fromRGB(36, 28, 12),
	badgeAzureBg = Color3.fromRGB(18, 30, 48),
}

-- Convenient short-alias table for color lookups
Theme.C = Theme.colors

Theme.radii = {
	micro = 4,
	badge = 6,
	control = 8,
	card = 12,
	modal = 16,
	pill = 999,
}

Theme.hairlines = {
	thickness = 1,
	restTransparency = 0.70,
	hoverTransparency = 0.30,
	activeTransparency = 0.10,
	bevelColor = Color3.fromRGB(255, 255, 255),
	bevelTransparency = 0.94,
}

local function resolveFont(name: string, fallback: Enum.Font): Enum.Font
	local ok, font = pcall(function() return (Enum.Font :: any)[name] end)
	if ok and font then return font end
	return fallback
end

Theme.typography = {
	fontDisplay = resolveFont("BuilderSansMedium", Enum.Font.GothamMedium),
	fontBody = resolveFont("BuilderSans", Enum.Font.Gotham),
	fontBold = resolveFont("BuilderSansBold", Enum.Font.GothamBold),
	fontMono = Enum.Font.RobotoMono,

	sizeHero = 26,
	sizeTitle = 19,
	sizeSection = 16,
	sizeBody = 14,
	sizeCaption = 12,
	sizeMicro = 11,
}

Theme.springs = {
	snappy = { damping = 1.0, frequency = 12 },
	smooth = { damping = 1.0, frequency = 8 },
	bouncy = { damping = 0.85, frequency = 10 },
	subtle = { damping = 1.0, frequency = 6 },
}

Theme.presets = {
	azure = {
		name = "Electric Azure",
		accent = Color3.fromRGB(59, 130, 246),
		accent2 = Color3.fromRGB(245, 158, 11),
		textInverse = Color3.fromRGB(10, 13, 18),
	},
	mint = {
		name = "Emerald Mint",
		accent = Color3.fromRGB(16, 185, 129),
		accent2 = Color3.fromRGB(59, 130, 246),
		textInverse = Color3.fromRGB(8, 18, 14),
	},
	amber = {
		name = "Warm Amber",
		accent = Color3.fromRGB(245, 158, 11),
		accent2 = Color3.fromRGB(16, 185, 129),
		textInverse = Color3.fromRGB(24, 16, 6),
	},
	purple = {
		name = "Iris Purple",
		accent = Color3.fromRGB(139, 92, 246),
		accent2 = Color3.fromRGB(59, 130, 246),
		textInverse = Color3.fromRGB(16, 10, 26),
	},
	rose = {
		name = "Electric Rose",
		accent = Color3.fromRGB(244, 63, 94),
		accent2 = Color3.fromRGB(245, 158, 11),
		textInverse = Color3.fromRGB(26, 8, 12),
	},
}

Theme.presetOrder = { "azure", "mint", "amber", "purple", "rose" }
Theme.defaultPreset = "azure"

function Theme.applyPreset(presetKey: string)
	local p = Theme.presets[presetKey] or Theme.presets.azure
	Theme.colors.accent = p.accent
	Theme.colors.accent2 = p.accent2
	Theme.colors.textInverse = p.textInverse
	Theme.colors.hairlineGlow = p.accent
end

return Theme

