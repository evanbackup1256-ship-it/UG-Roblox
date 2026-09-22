// theme.ts — Design tokens. Obsidian Industrial / VisionOS.

export const C = {
	// Surfaces
	canvas:      Color3.fromRGB(9,   11,  15),
	panel:       Color3.fromRGB(16,  18,  24),
	card:        Color3.fromRGB(24,  26,  34),
	elevated:    Color3.fromRGB(34,  37,  48),
	recessed:    Color3.fromRGB(13,  15,  20),

	// Hairlines
	hairline:    Color3.fromRGB(40,  44,  58),
	hairlineSub: Color3.fromRGB(28,  31,  42),

	// Typography
	textPrimary:   Color3.fromRGB(248, 250, 252),
	textSecondary: Color3.fromRGB(148, 163, 184),
	textMuted:     Color3.fromRGB(100, 116, 139),
	textInverse:   Color3.fromRGB(10,  13,  18),

	// Semantic currencies
	compute:    Color3.fromRGB(16,  185, 129),
	energy:     Color3.fromRGB(245, 158, 11),
	data:       Color3.fromRGB(6,   182, 212),
	reputation: Color3.fromRGB(139, 92,  246),
	overclock:  Color3.fromRGB(236, 72,  153),

	// Semantic states
	accent:  Color3.fromRGB(59,  130, 246),
	accent2: Color3.fromRGB(245, 158, 11),
	success: Color3.fromRGB(16,  185, 129),
	warning: Color3.fromRGB(245, 158, 11),
	danger:  Color3.fromRGB(239, 68,  68),
	gold:    Color3.fromRGB(245, 158, 11),
};

export const R = {
	micro:   4  as number,
	badge:   6  as number,
	control: 8  as number,
	card:    12 as number,
	modal:   16 as number,
	pill:    999 as number,
};

export const Font = {
	display: Enum.Font.GothamMedium,
	body:    Enum.Font.Gotham,
	bold:    Enum.Font.GothamBold,
	mono:    Enum.Font.RobotoMono,
};

export const Size = {
	hero:    26,
	title:   19,
	section: 16,
	body:    14,
	caption: 12,
	micro:   11,
};

