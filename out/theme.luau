-- Compiled with roblox-ts v3.0.0
-- theme.ts — Design tokens. Obsidian Industrial / VisionOS.
local C = {
	canvas = Color3.fromRGB(9, 11, 15),
	panel = Color3.fromRGB(16, 18, 24),
	card = Color3.fromRGB(24, 26, 34),
	elevated = Color3.fromRGB(34, 37, 48),
	recessed = Color3.fromRGB(13, 15, 20),
	hairline = Color3.fromRGB(40, 44, 58),
	hairlineSub = Color3.fromRGB(28, 31, 42),
	textPrimary = Color3.fromRGB(248, 250, 252),
	textSecondary = Color3.fromRGB(148, 163, 184),
	textMuted = Color3.fromRGB(100, 116, 139),
	textInverse = Color3.fromRGB(10, 13, 18),
	compute = Color3.fromRGB(16, 185, 129),
	energy = Color3.fromRGB(245, 158, 11),
	data = Color3.fromRGB(6, 182, 212),
	reputation = Color3.fromRGB(139, 92, 246),
	overclock = Color3.fromRGB(236, 72, 153),
	accent = Color3.fromRGB(59, 130, 246),
	accent2 = Color3.fromRGB(245, 158, 11),
	success = Color3.fromRGB(16, 185, 129),
	warning = Color3.fromRGB(245, 158, 11),
	danger = Color3.fromRGB(239, 68, 68),
	gold = Color3.fromRGB(245, 158, 11),
}
local R = {
	micro = 4,
	badge = 6,
	control = 8,
	card = 12,
	modal = 16,
	pill = 999,
}
local Font = {
	display = Enum.Font.GothamMedium,
	body = Enum.Font.Gotham,
	bold = Enum.Font.GothamBold,
	mono = Enum.Font.RobotoMono,
}
local Size = {
	hero = 26,
	title = 19,
	section = 16,
	body = 14,
	caption = 12,
	micro = 11,
}
return {
	C = C,
	R = R,
	Font = Font,
	Size = Size,
}
