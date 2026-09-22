-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
-- screens/ScreenTerminal.tsx — Network Console & Live Telemetry Stream
local React = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@rbxts", "react")
local _theme = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "theme")
local C = _theme.C
local Font = _theme.Font
local Size = _theme.Size
local R = _theme.R
local Card = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Card").Card
local Button = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Button").Button
local Badge = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "ui", "Badge").Badge
local useGameState = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "hooks").useGameState
local act = TS.import(script, game:GetService("ReplicatedStorage"), "DeckGame", "App", "store").act
local INITIAL_LOGS = { {
	id = 1,
	timestamp = "00:00:01",
	message = "KERNEL: Kernel initialized in distributed mode.",
	level = "info",
}, {
	id = 2,
	timestamp = "00:00:04",
	message = "NETWORK: Handshake established with Fleet Command cluster.",
	level = "info",
}, {
	id = 3,
	timestamp = "00:00:12",
	message = "VOLTAGE: Energy grid nominal at 100/100 units.",
	level = "success",
}, {
	id = 4,
	timestamp = "00:01:30",
	message = "COMPUTE: Core processing cycles yielding steady throughput.",
	level = "success",
}, {
	id = 5,
	timestamp = "00:02:15",
	message = "HARDWARE: Rack temperature within safe operating parameters.",
	level = "info",
} }
local function ScreenTerminal()
	local gs = useGameState()
	local logs, setLogs = React.useState(INITIAL_LOGS)
	local commandText, setCommandText = React.useState("")
	local counter, setCounter = React.useState(10)
	local inputRef = React.createRef()
	local submitCommand = function()
		if commandText == "" then
			return nil
		end
		local cmd = string.lower(commandText)
		local nextId = counter + 1
		setCounter(nextId)
		local responseMsg = `Executed command: {commandText}`
		local level = "info"
		if cmd == "help" then
			responseMsg = "Available commands: help, status, recharge, ping, clear"
		elseif cmd == "status" then
			responseMsg = `STATUS: Compute={gs.compute}, Energy={gs.energy}, Data={gs.data}`
			level = "success"
		elseif cmd == "recharge" then
			act("recharge")
			responseMsg = "COMMAND: Fleet capacitor bank recharge signal dispatched."
			level = "success"
		elseif cmd == "ping" then
			responseMsg = "PONG: Fleet uplink latency: 12ms."
			level = "info"
		elseif cmd == "clear" then
			setLogs({})
			setCommandText("")
			return nil
		else
			responseMsg = `ERR: Unknown terminal command '{commandText}'. Type 'help' for diagnostics.`
			level = "warn"
		end
		local _array = {}
		local _length = #_array
		local _logsLength = #logs
		table.move(logs, 1, _logsLength, _length + 1, _array)
		_length += _logsLength
		_array[_length + 1] = {
			id = nextId,
			timestamp = "LIVE",
			message = `> {commandText}`,
			level = "info",
		}
		_array[_length + 2] = {
			id = nextId + 1,
			timestamp = "SYS",
			message = responseMsg,
			level = level,
		}
		setLogs(_array)
		setCommandText("")
	end
	local _exp = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 24),
		PaddingRight = UDim.new(0, 24),
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 40),
	})
	local _exp_1 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local _exp_2 = React.createElement(Card, {
		height = 70,
		layoutOrder = 1,
	}, React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	}), React.createElement("frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 12),
	}), React.createElement("textlabel", {
		Text = "TACTICAL NETWORK TERMINAL",
		Font = Font.bold,
		TextSize = Size.section,
		TextColor3 = C.textPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}), React.createElement(Badge, {
		label = "ONLINE",
		style = "compute",
		pill = true,
	})))
	local _exp_3 = React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	})
	local _exp_4 = React.createElement("uilistlayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
	})
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#logs)
	local _callback = function(log)
		local col = C.textSecondary
		if log.level == "success" then
			col = C.compute
		end
		if log.level == "warn" then
			col = C.warning
		end
		if log.level == "error" then
			col = C.danger
		end
		return React.createElement("frame", {
			key = log.id,
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
		}, React.createElement("textlabel", {
			Text = `[{log.timestamp}] {log.message}`,
			Font = Font.mono,
			TextSize = Size.caption,
			TextColor3 = col,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}))
	end
	for _k, _v in logs do
		_newValue[_k] = _callback(_v, _k - 1, logs)
	end
	-- ▲ ReadonlyArray.map ▲
	return React.createElement("scrollingframe", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.hairline,
		CanvasSize = UDim2.new(0, 0, 0, 750),
	}, _exp, _exp_1, _exp_2, React.createElement(Card, {
		height = 440,
		bgColor = Color3.fromRGB(10, 12, 16),
		layoutOrder = 2,
	}, _exp_3, React.createElement("scrollingframe", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.hairline,
		CanvasSize = UDim2.new(0, 0, 0, math.max(400, #logs * 26)),
	}, _exp_4, _newValue)), React.createElement("frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
	}, React.createElement("textbox", {
		ref = inputRef,
		PlaceholderText = "Enter command (e.g. 'status', 'recharge', 'help')...",
		PlaceholderColor3 = C.textMuted,
		Text = commandText,
		Font = Font.mono,
		TextSize = Size.body,
		TextColor3 = C.compute,
		BackgroundColor3 = C.recessed,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		ClearTextOnFocus = false,
		Event = {
			FocusLost = function(enterPressed)
				if enterPressed then
					submitCommand()
				end
			end,
		},
		Change = {
			Text = function(rbx)
				return setCommandText(rbx.Text)
			end,
		},
	}, React.createElement("uicorner", {
		CornerRadius = UDim.new(0, R.control),
	}), React.createElement("uipadding", {
		PaddingLeft = UDim.new(0, 14),
	}), React.createElement("uistroke", {
		Color = C.hairline,
		Thickness = 1,
	})), React.createElement(Button, {
		label = "Execute",
		variant = "primary",
		width = 110,
		height = 44,
		onClick = submitCommand,
	})))
end
return {
	default = ScreenTerminal,
}
