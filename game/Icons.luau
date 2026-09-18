local Icons = {}

-- A handful of these intentionally share an asset: operations/modules reuse
-- the same rack icon on purpose. The rest (rewards/reputation/gift/star,
-- data/infrastructure, energy/volume) look like unfinished placeholders
-- rather than deliberate aliases — worth sourcing distinct icons for those
-- when art is available, since right now three unrelated concepts can
-- render identically and be mistaken for one another.
--
-- rocket/sparkles (rbxassetid://7734056556) is confirmed broken in-game —
-- it renders as a solid black square rather than an icon (verified live in
-- Studio). Every Creator Store "rocket icon" search tried as a replacement
-- either didn't match this app's thin-line style or had an opaque
-- background that also rendered as a solid block (tested live). Avoid
-- picking "rocket"/"sparkles" for new UI. The Relaunch nav/hero icon and
-- the "launch" dispatch operation both use Kit.rocketIcon / "operations"
-- instead now — see InterfaceController.luau and DesignKit.luau.
local assets = {
	overview = "rbxassetid://7733960981",
	infrastructure = "rbxassetid://7734053426",
	research = "rbxassetid://7733674922",
	contracts = "rbxassetid://7733919526",
	rewards = "rbxassetid://7733946818",
	shop = "rbxassetid://7734056747",
	settings = "rbxassetid://7734058803",
	operations = "rbxassetid://7733765045",
	modules = "rbxassetid://7733765045",
	data = "rbxassetid://7734053426",
	energy = "rbxassetid://7734059629",
	reputation = "rbxassetid://7733946818",
	events = "rbxassetid://7733673987",
	codes = "rbxassetid://7733749837",
	changelog = "rbxassetid://7733779668",
	ping = "rbxassetid://8997387110",
	fps = "rbxassetid://7743874262",
	search = "rbxassetid://7734052925",
	filter = "rbxassetid://7733673345",
	arrowLeft = "rbxassetid://7733717447",
	arrowRight = "rbxassetid://7733717651",
	close = "rbxassetid://7734068321",
	check = "rbxassetid://7733715400",
	lock = "rbxassetid://7733969313",
	unlock = "rbxassetid://7733969554",
	info = "rbxassetid://7733920644",
	calendar = "rbxassetid://7733917120",
	gift = "rbxassetid://7733946818",
	star = "rbxassetid://7733946818",
	leaderboard = "rbxassetid://7733946818",
	rocket = "rbxassetid://7734056556",
	sparkles = "rbxassetid://7734056556",
	volume = "rbxassetid://7734059629",
	music = "rbxassetid://7734058260",
	play = "rbxassetid://7734051202",
}

local warnedKeys = {}

-- assets.operations is always a valid non-empty string, so falling back to
-- it means Icons.resolve never returns nil/"" — callers can rely on that.
-- An unrecognized key still resolves (to the operations icon) rather than
-- erroring, but now warns once per key so a typo surfaces during
-- development instead of silently wearing the wrong icon forever.
local function resolve(key)
	local asset = assets[key]
	if asset then
		return asset
	end

	if not warnedKeys[key] then
		warnedKeys[key] = true
		warn(string.format("Icons: unknown icon key %q, falling back to \"operations\"", tostring(key)))
	end

	return assets.operations
end

function Icons.attach(host, key)
	assert(host and host:IsA("TextLabel"), "Icons.attach requires a TextLabel")

	local image = host:FindFirstChild("VectorIcon")
	local isNew = image == nil

	if isNew then
		image = Instance.new("ImageLabel")
		image.Name = "VectorIcon"
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.Size = UDim2.fromScale(0.82, 0.82)
		image.BackgroundTransparency = 1
		image.ScaleType = Enum.ScaleType.Fit
		image.ZIndex = host.ZIndex
		image.Parent = host
	end

	image.Image = resolve(key)
	image.ImageColor3 = host.TextColor3
	host:SetAttribute("IconKey", key)
	host:SetAttribute("IconAsset", image.Image)
	host.Text = ""
	host.TextTransparency = 1

	-- Only wire this once per host: re-attaching (swapping the icon key on
	-- an existing button) must not stack a second live connection reacting
	-- to every future color change.
	if isNew then
		host:GetPropertyChangedSignal("TextColor3"):Connect(function()
			image.ImageColor3 = host.TextColor3
		end)
	end

	return image
end

function Icons.asset(key)
	return resolve(key)
end

return Icons
