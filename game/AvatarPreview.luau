local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AvatarPreview = {}
AvatarPreview.__index = AvatarPreview

function AvatarPreview.new(parent, player, motionEnabled)
	local self = setmetatable({}, AvatarPreview)
	self.destroyed = false
	self.angle = math.pi
	self.elapsed = 0

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "PlayerAvatar"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.Ambient = Color3.fromRGB(235, 240, 255)
	viewport.LightColor = Color3.fromRGB(255, 239, 217)
	viewport.LightDirection = Vector3.new(-1, -0.5, -1)
	viewport.ZIndex = 4
	viewport.Parent = parent
	self.viewport = viewport

	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local camera = Instance.new("Camera")
	camera.FieldOfView = 32
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	self.connection = RunService.RenderStepped:Connect(function(delta)
		self.elapsed += delta
		if self.elapsed < 1 / 60 or not self.focus or not parent.Visible then
			return
		end

		local step = math.min(self.elapsed, 0.1)
		self.elapsed = 0
		if motionEnabled() then
			self.angle += step * 0.4
		end

		local offset = Vector3.new(math.sin(self.angle), 0.12, math.cos(self.angle)) * self.distance
		camera.CFrame = CFrame.lookAt(self.focus + offset, self.focus)
	end)

	self.destroyConnection = parent.Destroying:Connect(function()
		self:Destroy()
	end)

	task.spawn(function()
		for attempt = 1, 3 do
			-- Bail before spending an attempt at all if we were torn down
			-- while waiting between retries: without this, a preview
			-- destroyed during the task.wait() below still went on to
			-- make one more CreateHumanoidModelFromUserIdAsync call for
			-- a viewport that no longer exists, delaying nothing useful.
			if self.destroyed then
				return
			end

			local ok, model = pcall(function()
				return Players:CreateHumanoidModelFromUserIdAsync(player.UserId)
			end)

			if self.destroyed then
				if ok then model:Destroy() end
				return
			end

			if ok then
				for _, item in ipairs(model:GetDescendants()) do
					if item:IsA("BasePart") then
						item.Anchored = true
						item.CanCollide = false
						item.CanTouch = false
						item.CanQuery = false
					elseif item:IsA("BaseScript") then
						item:Destroy()
					end
				end

				model:PivotTo(CFrame.new())
				model.Parent = world
				local bounds, size = model:GetBoundingBox()
				local head = model:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					self.focus = head.Position - Vector3.new(0, head.Size.Y * 0.35, 0)
					self.distance = math.max(4, head.Size.X * 2.4, head.Size.Y * 3)
				else
					self.focus = bounds.Position
					self.distance = math.max(size.X, size.Y, size.Z) * 1.8
				end
				viewport:SetAttribute("AvatarReady", true)
				return
			end

			task.wait(attempt)
		end

		if not self.destroyed then
			viewport:SetAttribute("AvatarReady", false)
		end
	end)

	return self
end

function AvatarPreview:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	self.connection:Disconnect()
	self.destroyConnection:Disconnect()
	self.viewport:Destroy()
end

return AvatarPreview
