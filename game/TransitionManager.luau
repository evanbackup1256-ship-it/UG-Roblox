local TransitionManager = {}
TransitionManager.__index = TransitionManager

-- Page curtain transition: an expanding-aperture mask that covers the
-- screen, calls back at full coverage (the moment InterfaceController's
-- switchPage does its page-visibility swap), then reveals. Built once at
-- construction and reused every call, not recreated per transition — same
-- pool-of-reusable-state discipline PreviewDirector uses for its viewport
-- entries.
local COVER_DURATION = 0.16
local REVEAL_DURATION = 0.22

function TransitionManager.new(Kit, root, preferences)
	local overlay = Kit.create("Frame", root, {
		Name = "TransitionOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 60,
		Visible = false,
	})

	local mask = Kit.create("Frame", overlay, {
		Name = "Mask",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0, 0),
		BackgroundColor3 = Kit.colors.background,
		BorderSizePixel = 0,
	})
	Kit.corner(mask, 9999)

	local self = setmetatable({
		Kit = Kit,
		preferences = preferences,
		overlay = overlay,
		mask = mask,
	}, TransitionManager)

	return self
end

-- Runs the cover half, invokes `callback` at the moment of full coverage
-- (where the caller should do its own instant visibility swap), then runs
-- the reveal half. Under reduced motion, calls back immediately with no
-- overlay animation at all, matching every other DesignKit primitive's
-- collapse-to-instant contract.
function TransitionManager:Play(callback)
	local Kit = self.Kit

	if not self.preferences.motion or not Kit.motion then
		callback()
		return
	end

	local overlay, mask = self.overlay, self.mask
	overlay.Visible = true
	overlay.BackgroundTransparency = 1
	mask.Size = UDim2.fromScale(0, 0)

	Kit.animate(mask, { Size = UDim2.fromScale(2.4, 2.4) }, COVER_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	task.delay(COVER_DURATION, function()
		if not overlay.Parent then
			return
		end

		callback()

		Kit.animate(mask, { Size = UDim2.fromScale(0, 0) }, REVEAL_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.delay(REVEAL_DURATION, function()
			if overlay.Parent then
				overlay.Visible = false
			end
		end)
	end)
end

function TransitionManager:Destroy()
	self.overlay:Destroy()
end

return TransitionManager
