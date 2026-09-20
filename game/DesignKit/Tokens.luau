local Tokens = {}

-- Playground: light, bright, playful mobile-game palette. Warm cream
-- background instead of dark charcoal, white card surfaces (elevation now
-- reads via shadow depth — see Primitives.M.shadow — not a surface-color
-- shift), bold saturated primary colors instead of muted jewel tones.
Tokens.colors = {
	-- Neutral surface depths
	bgDeep = Color3.fromRGB(255, 250, 240),      -- #FFFAF0 Warm cream canvas
	background = Color3.fromRGB(255, 253, 246),  -- #FFFDF6 Main window backdrop
	navigation = Color3.fromRGB(255, 255, 255),  -- #FFFFFF Bottom bar / header backing
	panel = Color3.fromRGB(255, 255, 255),       -- #FFFFFF Standard card surface
	raised = Color3.fromRGB(255, 255, 255),      -- Elevated surfaces stay white; lift reads via shadow, not tint
	glass = Color3.fromRGB(255, 255, 255),
	line = Color3.fromRGB(230, 225, 210),        -- Faint warm-gray, rare internal dividers only (not card edges)
	lineGlow = Color3.fromRGB(255, 209, 70),     -- Active-state ring color
	lineSubtle = Color3.fromRGB(240, 236, 224),

	-- Typography
	text = Color3.fromRGB(45, 35, 30),           -- Warm near-black, not pure black — softer/friendlier
	textDim = Color3.fromRGB(90, 78, 70),
	textSub = Color3.fromRGB(140, 128, 118),
	muted = Color3.fromRGB(170, 160, 150),
	ink = Color3.fromRGB(255, 255, 255),         -- Text on bold-color buttons is now white
	paper = Color3.fromRGB(45, 35, 30),          -- Inverted use: dark text/surface on light contexts

	-- Semantic currencies & states — bold saturated primaries, 1:1 slot
	-- mapping onto the prior jewel-tone accents so every currency/category
	-- call site keeps its semantic color, only the hex changes.
	accent = Color3.fromRGB(255, 107, 53),       -- #FF6B35 Bold coral-orange (primary action)
	compute = Color3.fromRGB(0, 200, 150),       -- #00C896 Vivid teal-green
	energy = Color3.fromRGB(255, 184, 0),        -- #FFB800 Bold golden-yellow
	warning = Color3.fromRGB(255, 184, 0),
	accent2 = Color3.fromRGB(255, 184, 0),
	data = Color3.fromRGB(0, 176, 255),          -- #00B0FF Vivid sky blue
	reputation = Color3.fromRGB(155, 93, 255),   -- #9B5DFF Bold violet
	overclock = Color3.fromRGB(255, 71, 133),    -- #FF4785 Hot pink
	gold = Color3.fromRGB(255, 184, 0),
	error = Color3.fromRGB(255, 69, 58),         -- #FF453A Bright red
	danger = Color3.fromRGB(255, 69, 58),
	thermal = Color3.fromRGB(255, 69, 58),
	success = Color3.fromRGB(0, 200, 150),
}

-- Big, fully-rounded shapes — roughly double the prior tight-industrial
-- scale, for the "chunky mobile-game" look.
Tokens.radius = {
	micro = 8,
	badge = 10,
	control = 16,  -- buttons, inputs, segmented chips
	card = 24,     -- content cards, list rows
	surface = 28,  -- large containers, modals
	hero = 32,     -- hero banners, main frame
	pill = 999,    -- status pills, dock, rounded tags
}

-- Cards no longer separate via a hairline border (see Primitives.M.shadow
-- for the drop-shadow mechanic that replaces it) — Tokens.glow is kept
-- only for the few small elements that still want a thin ring (e.g.
-- Kit.button's Edge stroke, too small for a shadow treatment to read well).
Tokens.glow = {
	restTransparency = 0.75,
	hoverTransparency = 0.35,
	activeTransparency = 0.15,
	thickness = 1,
	bevelColor = Color3.fromRGB(255, 255, 255),
	bevelTransparency = 0.94,
}

-- Stacked-frame drop shadow (no external asset dependency): 2-3
-- decreasingly-opaque, increasingly-offset Frames parented behind a card,
-- tinted warm (not gray) to reinforce the "chunky candy" look rather than
-- a neutral/photographic shadow.
Tokens.shadow = {
	color = Color3.fromRGB(255, 140, 90),
	layers = {
		{ offset = 2, transparency = 0.85 },
		{ offset = 5, transparency = 0.90 },
		{ offset = 9, transparency = 0.94 },
	},
	hoverOffsetBoost = 4,       -- added to each layer's offset on hover (lift effect)
	hoverTransparencyDelta = -0.06, -- darkens slightly on hover
}

-- Typographic hierarchy (clean, readable scale) — unchanged shape, sizes
-- nudged up slightly for the friendlier, chunkier feel.
Tokens.type = {
	display = 36,
	title = 26,
	headline = 22,
	subtitle = 17,
	body = 15,
	caption = 13,
	micro = 11,
}

-- Friendly rounded display font, used everywhere including numeric
-- readouts (mono is deliberately dropped — see Tokens.font.mono below).
-- FredokaOne is Roblox's standard rounded/friendly built-in face; if it
-- proves too heavy for dense numeric tables (Leaderboard/Operations),
-- GothamRounded is the documented fallback — decide via a direct Studio
-- render comparison, not blind substitution.
Tokens.font = {
	regular = Enum.Font.FredokaOne,
	bold = Enum.Font.FredokaOne,
	-- Kept as a distinct key (not deleted) since a few call sites read
	-- Tokens.font.mono directly for numeric labels — aliased to the same
	-- friendly face per "numbers off mono" rather than requiring those
	-- call sites to change what key they read.
	mono = Enum.Font.FredokaOne,
}

return Tokens
