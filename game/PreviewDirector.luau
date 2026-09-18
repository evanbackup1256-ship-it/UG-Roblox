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
	else
		-- Server racks
		local count = 2 + entry.seed % 2

		for i = 1, count do
			local x = (i - (count + 1) / 2) * 2.7
			local height = 3.8 + (entry.seed % 4) * 0.35

			part(Vector3.new(2.1, height, 2.4), Vector3.new(x, height / 2, 0), metal)
			part(Vector3.new(2.15, 0.14, 2.45), Vector3.new(x, height, 0), tint:Lerp(Color3.new(1, 1, 1), 0.25))

			for slot = 1, 5 do
				local y = slot * height / 6
				part(Vector3.new(1.8, 0.44, 0.16), Vector3.new(x, y, 1.23), Color3.fromRGB(87, 104, 99))
				part(Vector3.new(1.05, 0.06, 0.05), Vector3.new(x - 0.17, y, 1.34), Color3.fromRGB(25, 34, 31))
				part(Vector3.new(0.12, 0.12, 0.05), Vector3.new(x + 0.64, y, 1.35), tint, Enum.Material.Neon)
			end
		end
	end

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
			local distance = 19 * math.max(1, 1 / aspect)
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