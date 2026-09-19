local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")

local Kit = require(script.Parent.DesignKit)
local Motion = require(script.Parent.MotionService)

local Director = {}
Director.__index = Director

function Director.new(root, preferences)
	local self = setmetatable({
		root = root,
		preferences = preferences,
		entries = {},
		clock = 0,
		connections = {},
		drag = nil,
	}, Director)

	local function connect(signal, callback)
		local conn = signal:Connect(callback)
		table.insert(self.connections, conn)
		return conn
	end

	connect(RunService.RenderStepped, function(dt)
		self:Step(math.min(dt, 0.1))
	end)

	connect(Input.InputChanged, function(input)
		local drag = self.drag
		if not drag then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement or input == drag.input then
			local delta = (input.Position.X - drag.lastX) * -0.009
			drag.angle += delta
			drag.lastDelta = delta
			drag.lastX = input.Position.X
		end
	end)

	connect(Input.InputEnded, function(input)
		local drag = self.drag
		if not drag then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.input then
			-- Coast out from the last sampled drag delta instead of
			-- stopping dead, scaled to a per-second rate for the Step()
			-- decay below.
			drag.spin = (drag.lastDelta or 0) * 6
			self.drag = nil
		end
	end)

	-- Scroll-wheel zoom: only for the entry directly under the pointer, and
	-- only when nothing else is mid-drag (zooming the entry someone else is
	-- currently orbiting would read as the camera fighting the player).
	-- ViewportFrame has no dedicated MouseWheel event of its own — the
	-- input has to be picked up via UserInputService and hit-tested against
	-- each entry's own on-screen bounds. Position is read via
	-- GetMouseLocation() rather than input.Position: the latter is
	-- documented for MouseMovement/Touch, but its X/Y population on a
	-- MouseWheel event specifically isn't documented, whereas
	-- GetMouseLocation() is guaranteed available whenever a mouse exists.
	connect(Input.InputChanged, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel or self.drag then
			return
		end

		local position = Input:GetMouseLocation()
		for _, entry in ipairs(self.entries) do
			if entry.active and self:IsVisible(entry) then
				local p = entry.viewport.AbsolutePosition
				local s = entry.viewport.AbsoluteSize
				if position.X >= p.X and position.X <= p.X + s.X and position.Y >= p.Y and position.Y <= p.Y + s.Y then
					entry.zoomDistance = math.clamp(entry.zoomDistance - input.Position.Z * 0.08, 0.6, 1.8)
					break
				end
			end
		end
	end)

	-- Track the Destroying connection too so everything is cleaned up
	connect(root.Destroying, function()
		for _, connection in ipairs(self.connections) do
			connection:Disconnect()
		end
		table.clear(self.connections)
		self.drag = nil
	end)

	return self
end

function Director:Add(parent, seed, tint, crate)
	local viewport = Kit.create("ViewportFrame", parent, {
		Name = "Scene",
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(187, 199, 182),
		LightColor = Color3.fromRGB(255, 249, 224),
		LightDirection = Vector3.new(-1, -1, -1),
		Size = UDim2.fromScale(1, 1),
		Active = true,
	})

	local entry = {
		viewport = viewport,
		seed = seed,
		tint = tint,
		crate = crate,
		angle = 0.65,
		active = false,
		lastSeen = 0,
		zoomDistance = 1,
	}

	table.insert(self.entries, entry)

	viewport.InputBegan:Connect(function(input)
		if not self.preferences.previews then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			entry.input = input
			entry.lastX = input.Position.X
			self.drag = entry
			Kit.sound("hover")
		end
	end)

	return viewport
end

function Director:Build(entry)
	if entry.world or entry.camera then
		return -- already built
	end

	local world = Kit.create("WorldModel", entry.viewport, { Name = "PreviewModel" })

	local function part(size, position, color, material)
		return Kit.create("Part", world, {
			Size = size,
			Position = position,
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			CastShadow = false,
		})
	end

	local tint = entry.tint
	local metal = Color3.fromRGB(58, 70, 68)
	local darkMetal = Color3.fromRGB(30, 38, 37)
	local brightTint = tint:Lerp(Color3.new(1, 1, 1), 0.35)

	-- Base platform
	part(Vector3.new(10, 0.25, 7), Vector3.new(0, -0.25, 0), Color3.fromRGB(97, 111, 97))
	part(Vector3.new(9.7, 0.06, 6.7), Vector3.zero, Color3.fromRGB(36, 48, 42))

	if entry.crate then
		-- Shipping crate
		part(Vector3.new(5, 3.5, 3.8), Vector3.new(0, 1.8, 0), metal)
		part(Vector3.new(5.3, 0.28, 4.1), Vector3.new(0, 3.6, 0), tint)

		for _, x in ipairs({ -2.3, 2.3 }) do
			part(Vector3.new(0.22, 3.8, 4), Vector3.new(x, 1.9, 0), tint)
		end

		part(Vector3.new(1, 0.8, 0.2), Vector3.new(0, 2, 2), tint, Enum.Material.Neon)

		for i = 1, 4 do
			part(Vector3.new(3.5, 0.08, 0.14), Vector3.new(0, 0.5 + i * 0.4, -2), Color3.fromRGB(110, 127, 115))
		end

		-- Corner brackets: reinforce the crate's four vertical edges with a
		-- narrower, darker metal strip so the silhouette reads as riveted
		-- hardware rather than a flat-shaded box.
		for _, x in ipairs({ -2.45, 2.45 }) do
			for _, z in ipairs({ -1.85, 1.85 }) do
				part(Vector3.new(0.16, 3.5, 0.16), Vector3.new(x, 1.8, z), darkMetal)
			end
		end

		-- Corner rivets on the top face — small studs at each bracket's
		-- top end, catching the rim light as tiny highlights.
		for _, x in ipairs({ -2.45, 2.45 }) do
			for _, z in ipairs({ -1.85, 1.85 }) do
				part(Vector3.new(0.24, 0.1, 0.24), Vector3.new(x, 3.56, z), darkMetal, Enum.Material.Metal)
			end
		end

		-- Recessed door seam down the front face, splitting it visually
		-- into two panels the way a real shipping container's doors would.
		part(Vector3.new(0.06, 3.3, 0.05), Vector3.new(0, 1.8, 1.91), darkMetal)

		-- Handle/latch on the front face, right of the seam.
		part(Vector3.new(0.5, 0.14, 0.16), Vector3.new(1.1, 1.9, 1.94), darkMetal, Enum.Material.Metal)
		part(Vector3.new(0.14, 0.5, 0.16), Vector3.new(1.1, 1.6, 1.94), darkMetal, Enum.Material.Metal)

		-- Side vent grille: a short run of thin slats on one side wall,
		-- mirroring the front-face vent stripes already present.
		for i = 1, 3 do
			part(Vector3.new(0.1, 0.06, 1.6), Vector3.new(-2.49, 2.3 + i * 0.22, 0), darkMetal)
		end
	else
		-- Server racks
		local count = 2 + entry.seed % 2

		for i = 1, count do
			local x = (i - (count + 1) / 2) * 2.7
			local height = 3.8 + (entry.seed % 4) * 0.35

			part(Vector3.new(2.1, height, 2.4), Vector3.new(x, height / 2, 0), metal)
			part(Vector3.new(2.15, 0.14, 2.45), Vector3.new(x, height, 0), brightTint)

			-- Vertical corner posts, slightly proud of the cabinet face —
			-- the same "riveted hardware" silhouette break the crate's
			-- brackets add, scaled for a taller, narrower rack.
			for _, z in ipairs({ -1.19, 1.19 }) do
				part(Vector3.new(0.12, height, 0.12), Vector3.new(x - 1.03, height / 2, z), darkMetal)
				part(Vector3.new(0.12, height, 0.12), Vector3.new(x + 1.03, height / 2, z), darkMetal)
			end

			-- Base foot / kick plate, grounding the cabinet visually.
			part(Vector3.new(2.2, 0.16, 2.5), Vector3.new(x, 0.08, 0), darkMetal)

			for slot = 1, 5 do
				local y = slot * height / 6
				part(Vector3.new(1.8, 0.44, 0.16), Vector3.new(x, y, 1.23), Color3.fromRGB(87, 104, 99))
				part(Vector3.new(1.05, 0.06, 0.05), Vector3.new(x - 0.17, y, 1.34), Color3.fromRGB(25, 34, 31))
				part(Vector3.new(0.12, 0.12, 0.05), Vector3.new(x + 0.64, y, 1.35), tint, Enum.Material.Neon)

				-- A thin horizontal seam under each slot, and a small
				-- secondary status LED beside the main one, so each bay
				-- reads as its own populated unit instead of a repeated
				-- flat plate.
				part(Vector3.new(1.8, 0.02, 0.02), Vector3.new(x, y - 0.24, 1.3), darkMetal)
				part(Vector3.new(0.08, 0.08, 0.05), Vector3.new(x + 0.5, y, 1.35), Color3.fromRGB(210, 210, 210), Enum.Material.Neon)
			end

			-- Rear cable bundle: a loose vertical run of thin dark cylinders
			-- along the back face, breaking up the rack's flat back plane
			-- and reading as real infrastructure from any angle.
			for i = 1, 3 do
				part(
					Vector3.new(0.1, height * 0.7, 0.1),
					Vector3.new(x - 0.6 + (i - 1) * 0.6, height * 0.4, -1.22),
					darkMetal
				)
			end
		end
	end

	-- Rim/back light: ViewportFrame.LightDirection/LightColor/Ambient (set
	-- on the viewport itself, above) is a single baked-in key light with no
	-- second slot for a back light. A genuine second light needs an actual
	-- light Instance parented under the WorldModel — standard WorldModel
	-- lighting behavior, illuminates parts rendered through this viewport.
	-- Torn down automatically as a descendant of `world` in the existing
	-- unload path below, no separate cleanup needed.
	local rimAnchor = Kit.create("Part", world, {
		Name = "RimAnchor",
		Size = Vector3.new(0.2, 0.2, 0.2),
		Position = Vector3.new(0, 3, -3),
		Transparency = 1,
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		CastShadow = false,
	})
	Kit.create("PointLight", rimAnchor, {
		Color = Color3.fromRGB(150, 190, 255),
		Brightness = 1.4,
		Range = 16,
	})

	entry.camera = Kit.create("Camera", entry.viewport, { FieldOfView = 32 })
	entry.viewport.CurrentCamera = entry.camera
	entry.world = world
end

function Director:IsVisible(entry)
	local object = entry.viewport.Parent
	local p = entry.viewport.AbsolutePosition
	local s = entry.viewport.AbsoluteSize

	local left, top = p.X, p.Y
	local right, bottom = p.X + s.X, p.Y + s.Y

	while object and object ~= self.root do
		if object:IsA("GuiObject") then
			if not object.Visible then
				return false
			end

			if object.ClipsDescendants then
				local a = object.AbsolutePosition
				local b = object.AbsoluteSize
				left = math.max(left, a.X)
				top = math.max(top, a.Y)
				right = math.min(right, a.X + b.X)
				bottom = math.min(bottom, a.Y + b.Y)
			end
		end
		object = object.Parent
	end

	return right > left and bottom > top and s.X > 0
end

function Director:Step(dt)
	self.clock += dt

	-- Visibility / build / unload pass (every ~0.1 s)
	if self.clock >= 0.1 then
		self.clock = 0

		local count = 0
		local built = false

		for _, entry in ipairs(self.entries) do
			local shouldBeActive = self.preferences.previews
				and self:IsVisible(entry)
				and count < 6

			entry.active = shouldBeActive

			if entry.active then
				count += 1
				entry.lastSeen = os.clock()

				if not entry.camera and not built then
					self:Build(entry)
					built = true -- only build one per tick
				end
			elseif entry.world and os.clock() - (entry.lastSeen or 0) > 8 then
				-- Unload after 8 s off-screen
				if entry.world then
					entry.world:Destroy()
				end
				if entry.camera then
					entry.camera:Destroy()
				end
				entry.world = nil
				entry.camera = nil
				entry.spin = nil
				entry.zoomDistance = 1
			end

			entry.viewport.Visible = entry.active
		end
	end

	-- Per-frame camera + light update
	for _, entry in ipairs(self.entries) do
		if entry.active and entry.camera then
			-- Subtle light sway on crates
			if entry.crate and self.preferences.motion and self.preferences.particles then
				entry.viewport.LightDirection = Vector3.new(
					-1 + math.sin(os.clock() * 0.35) * 0.2,
					-1,
					-1
				)
			end

			-- Drag release inertia: coast out the residual spin left by
			-- InputEnded, decaying toward zero rather than stopping dead.
			-- Skipped entirely under reduced motion, same as auto-orbit below.
			if self.preferences.motion and self.drag ~= entry and entry.spin and math.abs(entry.spin) > 0.001 then
				entry.angle += entry.spin * dt
				entry.spin = Motion.damped(entry.spin, 0, dt, 4)
			else
				entry.spin = nil
			end

			-- Auto-orbit (only when not being dragged), smoothed in/out so
			-- toggling the preference or starting/ending a drag blends
			-- instead of snapping the orbit on or off.
			local orbitTarget = (self.preferences.motion and self.preferences.autoOrbit and self.drag ~= entry) and 1 or 0
			entry.orbitBlend = Motion.damped(entry.orbitBlend or 0, orbitTarget, dt, 5)
			if entry.orbitBlend > 0.001 then
				entry.angle += dt * self.preferences.orbitSpeed * 0.5 * entry.orbitBlend
			end

			local aspect = entry.viewport.AbsoluteSize.X / math.max(1, entry.viewport.AbsoluteSize.Y)
			local distance = 19 * math.max(1, 1 / aspect) * entry.zoomDistance
			local focus = Vector3.new(0, 1.5, 0)

			entry.camera.CFrame = CFrame.lookAt(
				focus + Vector3.new(
					math.sin(entry.angle) * distance,
					distance * 0.48,
					math.cos(entry.angle) * distance
				),
				focus
			)
		end
	end
end

return Director