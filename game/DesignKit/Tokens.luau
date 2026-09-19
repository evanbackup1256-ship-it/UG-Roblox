local Tokens = {}

-- "Clean modern mobile idle game" palette: deep indigo background instead
-- of near-black, two bold accent colors instead of one muted mint, no
-- more thin hairline-grey as the dominant edge treatment.
Tokens.colors = {
	background = Color3.fromRGB(20, 16, 43),   -- #14102B
	navigation = Color3.fromRGB(26, 21, 56),   -- #1A1538
	panel = Color3.fromRGB(30, 24, 64),        -- #1E1840
	raised = Color3.fromRGB(42, 35, 84),       -- #2A2354
	line = Color3.fromRGB(58, 49, 104),        -- subtle divider, between panel and raised
	text = Color3.fromRGB(245, 243, 255),      -- #F5F3FF
	muted = Color3.fromRGB(156, 147, 196),     -- #9C93C4
	accent = Color3.fromRGB(61, 220, 151),     -- #3DDC97, primary/positive
	accent2 = Color3.fromRGB(255, 159, 69),    -- #FF9F45, secondary/highlight (amber)
	warning = Color3.fromRGB(255, 180, 84),    -- #FFB454
	ink = Color3.fromRGB(18, 16, 42),          -- #12102A, text-on-accent-fill
	paper = Color3.fromRGB(237, 233, 251),     -- #EDE9FB, light-fill surfaces
	error = Color3.fromRGB(255, 107, 129),     -- #FF6B81
}

-- Corner radii: large and rounded throughout, replacing the old 6-8px
-- sharp-cornered admin-dashboard shapes.
Tokens.radius = {
	control = 16, -- cards, inputs, checkboxes' outer hit target
	surface = 20, -- large panels / hero cards
	pill = 999,   -- buttons, badges — always fully rounded
}

-- Soft glow strokes replace thin 1px hairlines: thicker, more transparent
-- at rest, so edges read as ambient light rather than a hard outline.
Tokens.glow = {
	restTransparency = 0.82,
	hoverTransparency = 0.55,
	thickness = 3,
}

-- Documented type scale — new page/header work should read from this
-- rather than inventing another one-off TextSize.
Tokens.type = {
	title = 34,
	subtitle = 20,
	body = 15,
	caption = 11,
}

return Tokens
