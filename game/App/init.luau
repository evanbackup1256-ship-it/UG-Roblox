--!strict
-- AppKit: Unified presentation toolkit export
local Theme = require(script.Theme)
local Springs = require(script.Springs)
local Elements = require(script.Elements)
local Buttons = require(script.Buttons)
local Inputs = require(script.Inputs)
local Acoustics = require(script.Acoustics)
local Feedback = require(script.Feedback)
local Odometer = require(script.Odometer)
local ToastManager = require(script.ToastManager)
local TourGuide = require(script.TourGuide)
local SearchPalette = require(script.SearchPalette)
local AppContext = require(script.AppContext)

local AppKit = {
	Theme = Theme,
	C = Theme.colors,
	Springs = Springs,
	Elements = Elements,
	Buttons = Buttons,
	Inputs = Inputs,
	Acoustics = Acoustics,
	Feedback = Feedback,
	Odometer = Odometer,
	ToastManager = ToastManager,
	TourGuide = TourGuide,
	SearchPalette = SearchPalette,
	AppContext = AppContext,
}

return AppKit

