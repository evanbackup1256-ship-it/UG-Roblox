--!strict
-- ToastManager: Non-intrusive floating notification alerts for milestones and actions
local Theme = require(script.Parent.Theme)
local Springs = require(script.Parent.Springs)
local Elements = require(script.Parent.Elements)

local C = Theme.colors
local ToastManager = {}
ToastManager.__index = ToastManager

function ToastManager.new(root: Instance, acoustics: any?)
	local self = setmetatable({}, ToastManager)
	self.container = Elements.create("Frame", root, {
		Name = "ToastStack",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(340, 300),
		BackgroundTransparency = 1,
		ZIndex = 100,
	})

	local listLayout = Elements.create("UIListLayout", self.container, {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	self.acoustics = acoustics
	self.order = 0
	return self
end

function ToastManager:notify(message: string, isError: boolean?, titleText: string?)
	if self.acoustics then
		self.acoustics.play(if isError then "error" else "notice", 0.03)
	end

	self.order += 1
	local toast = Elements.create("CanvasGroup", self.container, {
		Name = "Toast_" .. self.order,
		Size = UDim2.fromOffset(320, 64),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		LayoutOrder = self.order,
		GroupTransparency = 1,
	})
	Elements.corner(toast, Theme.radii.card)
	Elements.stroke(toast, C.hairline, 1, 0.8)

	local barCol = if isError then C.danger else C.accent
	local accentBar = Elements.create("Frame", toast, {
		Name = "Bar",
		Size = UDim2.new(0, 4, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundColor3 = barCol,
		BorderSizePixel = 0,
	})
	Elements.corner(accentBar, 2)

	local icon = Elements.icon(toast, "Icon", if isError then "error" else "check", barCol)
	Elements.place(icon, 20, 22, 20, 20)

	local title = Elements.text(toast, "Title", titleText or (if isError then "Alert" else "Notification"), 12, barCol, true)
	title.Position = UDim2.new(0, 48, 0, 12)
	title.Size = UDim2.new(1, -56, 0, 16)

	local body = Elements.text(toast, "Body", message, 13, C.textPrimary)
	body.Position = UDim2.new(0, 48, 0, 30)
	body.Size = UDim2.new(1, -56, 0, 24)
	body.TextWrapped = true

	local scale = Elements.create("UIScale", toast, { Scale = 0.85 })
	Springs.target(scale, { Scale = 1.0 }, "smooth")
	Springs.target(toast, { GroupTransparency = 0 }, "smooth")
	local toastStroke = toast:FindFirstChildOfClass("UIStroke")
	if toastStroke then
		toastStroke.Transparency = 1
		Springs.target(toastStroke, { Transparency = 0.8 }, "smooth")
	end

	task.delay(3.5, function()
		if toast.Parent then
			Springs.target(scale, { Scale = 0.95 }, "smooth")
			Springs.target(toast, { GroupTransparency = 1 }, "smooth")
			if toastStroke then
				Springs.target(toastStroke, { Transparency = 1 }, "smooth")
			end
			task.delay(0.3, function()
				toast:Destroy()
			end)
		end
	end)
end

function ToastManager:destroy()
	self.container:Destroy()
end
ToastManager.Destroy = ToastManager.destroy

return ToastManager

