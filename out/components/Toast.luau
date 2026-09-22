-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- components/Toast.tsx — Global toast notification overlay with slide+fade animations
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local R = _theme.R
local Font = _theme.Font
local Size = _theme.Size
-- ─── Public API ───────────────────────────────────────────────────────────────
local nextId = 0
local toastListeners = {}
local activeToasts = {}
local function notifyListeners()
	-- Shallow-copy so React sees a new reference
	local _array = {}
	local _length = #_array
	table.move(activeToasts, 1, #activeToasts, _length + 1, _array)
	local snapshot = _array
	for _, l in toastListeners do
		task.spawn(function()
			return l(snapshot)
		end)
	end
end
--* Call from anywhere to show a toast notification. 
local function showToast(message, isError, title)
	if isError == nil then
		isError = false
	end
	local _original = nextId
	nextId += 1
	local id = _original
	local entry = {
		id = id,
		message = message,
		isError = isError,
		title = title,
	}
	local _array = {}
	local _length = #_array
	local _activeToastsLength = #activeToasts
	table.move(activeToasts, 1, _activeToastsLength, _length + 1, _array)
	_length += _activeToastsLength
	_array[_length + 1] = entry
	activeToasts = _array
	notifyListeners()
	-- Auto-dismiss after 4 seconds
	task.delay(4, function()
		-- ▼ ReadonlyArray.filter ▼
		local _newValue = {}
		local _callback = function(t)
			return t.id ~= id
		end
		local _length_1 = 0
		for _k, _v in activeToasts do
			if _callback(_v, _k - 1, activeToasts) == true then
				_length_1 += 1
				_newValue[_length_1] = _v
			end
		end
		-- ▲ ReadonlyArray.filter ▲
		activeToasts = _newValue
		notifyListeners()
	end)
end
-- ─── Individual Toast ──────────────────────────────────────────────────────────
local SLIDE_IN = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SLIDE_OUT = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local function ToastCard(_param)
	local entry = _param.entry
	local onDismiss = _param.onDismiss
	local containerRef = React.createRef()
	local mounted, setMounted = React.useState(false)
	local accentColor = if entry.isError then C.danger else C.success
	-- Slide in on mount
	React.useEffect(function()
		local frame = containerRef.current
		if not frame then
			return nil
		end
		-- Start off-screen to the right
		frame.Position = UDim2.new(1, 20, 0, 0)
		frame.BackgroundTransparency = 0
		-- Tiny delay so the frame renders first
		task.delay(0.02, function()
			local f = containerRef.current
			if not f then
				return nil
			end
			game:GetService("TweenService"):Create(f, SLIDE_IN, {
				Position = UDim2.new(0, 0, 0, 0),
			}):Play()
		end)
		setMounted(true)
	end, {})
	local dismiss = function()
		local frame = containerRef.current
		if not frame then
			onDismiss(entry.id)
			return nil
		end
		local t = game:GetService("TweenService"):Create(frame, SLIDE_OUT, {
			Position = UDim2.new(1, 30, 0, 0),
			BackgroundTransparency = 1,
		})
		t.Completed:Connect(function()
			return onDismiss(entry.id)
		end)
		t:Play()
	end
	return React.createElement("frame", {
		ref = containerRef,
		key = tostring(entry.id),
		BackgroundColor3 = C.card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = false,
		ZIndex = 102,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.card),
	}), React.createElement("uistroke", {
		Color = accentColor,
		Thickness = 1,
		Transparency = 0.6,
	}), React.createElement("frame", {
		key = "AccentBar",
		BackgroundColor3 = accentColor,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 103,
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.card),
	})), React.createElement("frame", {
		key = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 14, 0, 0),
		ZIndex = 103,
	}, React.createElement("uipadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	}), React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}), entry.title ~= nil and entry.title ~= "" and (React.createElement("textlabel", {
		key = "Title",
		Text = entry.title,
		Font = Font.bold,
		TextSize = Size.caption,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 15),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 0,
	})), React.createElement("textlabel", {
		key = "Message",
		Text = entry.message,
		Font = Font.body,
		TextSize = Size.caption,
		TextColor3 = C.textSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = 1,
	})), React.createElement("textbutton", {
		key = "DismissBtn",
		Text = "✕",
		Font = Font.body,
		TextSize = Size.micro,
		TextColor3 = C.textMuted,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(1, -6, 0, 6),
		AnchorPoint = Vector2.new(1, 0),
		ZIndex = 104,
		Event = {
			Activated = dismiss,
		},
	}))
end
-- ─── Toast Container ───────────────────────────────────────────────────────────
local function Toast()
	local toasts, setToasts = React.useState({})
	React.useEffect(function()
		-- Register listener
		table.insert(toastListeners, setToasts)
		return function()
			local idx = (table.find(toastListeners, setToasts) or 0) - 1
			if idx ~= -1 then
				table.remove(toastListeners, idx + 1)
			end
		end
	end, {})
	local handleDismiss = function(id)
		setToasts(function(prev)
			-- ▼ ReadonlyArray.filter ▼
			local _newValue = {}
			local _callback = function(t)
				return t.id ~= id
			end
			local _length = 0
			for _k, _v in prev do
				if _callback(_v, _k - 1, prev) == true then
					_length += 1
					_newValue[_length] = _v
				end
			end
			-- ▲ ReadonlyArray.filter ▲
			return _newValue
		end)
		-- Also prune from global list
		-- ▼ ReadonlyArray.filter ▼
		local _newValue = {}
		local _callback = function(t)
			return t.id ~= id
		end
		local _length = 0
		for _k, _v in activeToasts do
			if _callback(_v, _k - 1, activeToasts) == true then
				_length += 1
				_newValue[_length] = _v
			end
		end
		-- ▲ ReadonlyArray.filter ▲
		activeToasts = _newValue
	end
	local _exp = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#toasts)
	local _callback = function(entry)
		return React.createElement(ToastCard, {
			key = tostring(entry.id),
			entry = entry,
			onDismiss = handleDismiss,
		})
	end
	for _k, _v in toasts do
		_newValue[_k] = _callback(_v, _k - 1, toasts)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("frame", {
		key = "ToastOverlay",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 300, 1, -80),
		Position = UDim2.new(1, -308, 0, 64),
		AnchorPoint = Vector2.new(0, 0),
		ZIndex = 100,
		ClipsDescendants = false,
	}, _exp, _newValue)
end
return {
	showToast = showToast,
	default = Toast,
}
