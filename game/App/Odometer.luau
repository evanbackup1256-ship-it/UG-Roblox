--!strict
-- Odometer: Smoothly interpolated numerical ticker for currencies and rates
local RunService = game:GetService("RunService")
local Springs = require(script.Parent.Springs)

local Odometer = {}
Odometer.__index = Odometer

function Odometer.new(target: Instance, formatFnOrSize: any?, color: Color3?)
	local self = setmetatable({}, Odometer)
	local label: TextLabel

	if target:IsA("TextLabel") then
		label = target
		self.format = if type(formatFnOrSize) == "function" then formatFnOrSize else tostring
	else
		label = Instance.new("TextLabel")
		label.Name = "OdometerLabel"
		label.BackgroundTransparency = 1
		label.TextColor3 = color or Color3.fromRGB(16, 185, 129)
		label.TextSize = if type(formatFnOrSize) == "number" then formatFnOrSize else 14
		label.Font = Enum.Font.RobotoMono
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Parent = target
		self.format = tostring
	end

	self.label = label
	self.container = label
	self.current = 0
	self.target = 0
	self.active = true

	self.connection = RunService.RenderStepped:Connect(function(dt)
		if not self.active or not label.Parent then return end
		if math.abs(self.target - self.current) > 0.01 then
			local blend = 1 - math.exp(-12 * dt)
			self.current = self.current + (self.target - self.current) * blend
			if math.abs(self.target - self.current) < 0.05 then
				self.current = self.target
			end
			self.label.Text = self.format(self.current)
		end
	end)

	return self
end

function Odometer:set(val: number, immediate: boolean?)
	self.target = val or 0
	if immediate or not Springs.motionEnabled then
		self.current = self.target
		self.label.Text = self.format(self.target)
	end
end

function Odometer:setValue(val: number, immediate: boolean?)
	self:set(val, immediate)
end

function Odometer:setFormat(formatFn: (number) -> string)
	self.format = formatFn
	self.label.Text = self.format(self.current)
end

function Odometer:destroy()
	self.active = false
	if self.connection then
		self.connection:Disconnect()
	end
end
Odometer.Destroy = Odometer.destroy

return Odometer
