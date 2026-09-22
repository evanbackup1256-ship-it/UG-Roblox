// screens/ScreenTerminal.tsx — Network Console & Live Telemetry Stream

import React from "@rbxts/react";
import { C, Font, Size, R } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { useGameState } from "../hooks";
import { act } from "../store";

interface LogMessage {
	id: number;
	timestamp: string;
	message: string;
	level: "info" | "warn" | "error" | "success";
}

const INITIAL_LOGS: LogMessage[] = [
	{ id: 1, timestamp: "00:00:01", message: "KERNEL: Kernel initialized in distributed mode.", level: "info" },
	{ id: 2, timestamp: "00:00:04", message: "NETWORK: Handshake established with Fleet Command cluster.", level: "info" },
	{ id: 3, timestamp: "00:00:12", message: "VOLTAGE: Energy grid nominal at 100/100 units.", level: "success" },
	{ id: 4, timestamp: "00:01:30", message: "COMPUTE: Core processing cycles yielding steady throughput.", level: "success" },
	{ id: 5, timestamp: "00:02:15", message: "HARDWARE: Rack temperature within safe operating parameters.", level: "info" },
];

export default function ScreenTerminal(): React.Element {
	const gs = useGameState();
	const [logs, setLogs] = React.useState<LogMessage[]>(INITIAL_LOGS);
	const [commandText, setCommandText] = React.useState("");
	const [counter, setCounter] = React.useState(10);
	const inputRef = React.createRef<TextBox>();

	const submitCommand = () => {
		if (commandText === "") return;
		const cmd = commandText.lower();
		const nextId = counter + 1;
		setCounter(nextId);

		let responseMsg = `Executed command: ${commandText}`;
		let level: "info" | "warn" | "error" | "success" = "info";

		if (cmd === "help") {
			responseMsg = "Available commands: help, status, recharge, ping, clear";
		} else if (cmd === "status") {
			responseMsg = `STATUS: Compute=${gs.compute}, Energy=${gs.energy}, Data=${gs.data}`;
			level = "success";
		} else if (cmd === "recharge") {
			act("recharge");
			responseMsg = "COMMAND: Fleet capacitor bank recharge signal dispatched.";
			level = "success";
		} else if (cmd === "ping") {
			responseMsg = "PONG: Fleet uplink latency: 12ms.";
			level = "info";
		} else if (cmd === "clear") {
			setLogs([]);
			setCommandText("");
			return;
		} else {
			responseMsg = `ERR: Unknown terminal command '${commandText}'. Type 'help' for diagnostics.`;
			level = "warn";
		}

		setLogs([
			...logs,
			{ id: nextId, timestamp: "LIVE", message: `> ${commandText}`, level: "info" },
			{ id: nextId + 1, timestamp: "SYS", message: responseMsg, level: level },
		]);
		setCommandText("");
	};

	return (
		<scrollingframe
			Size={new UDim2(1, 0, 1, 0)}
			BackgroundTransparency={1}
			BorderSizePixel={0}
			ScrollBarThickness={4}
			ScrollBarImageColor3={C.hairline}
			CanvasSize={new UDim2(0, 0, 0, 750)}
		>
			<uipadding
				PaddingLeft={new UDim(0, 24)}
				PaddingRight={new UDim(0, 24)}
				PaddingTop={new UDim(0, 20)}
				PaddingBottom={new UDim(0, 40)}
			/>
			<uilistlayout
				FillDirection={Enum.FillDirection.Vertical}
				Padding={new UDim(0, 16)}
				SortOrder={Enum.SortOrder.LayoutOrder}
			/>

			{/* Terminal Shell Header */}
			<Card height={70} layoutOrder={1}>
				<uipadding
					PaddingLeft={new UDim(0, 20)}
					PaddingRight={new UDim(0, 20)}
					PaddingTop={new UDim(0, 14)}
					PaddingBottom={new UDim(0, 14)}
				/>
				<frame Size={new UDim2(1, 0, 1, 0)} BackgroundTransparency={1}>
					<uilistlayout
						FillDirection={Enum.FillDirection.Horizontal}
						VerticalAlignment={Enum.VerticalAlignment.Center}
						Padding={new UDim(0, 12)}
					/>
					<textlabel
						Text="TACTICAL NETWORK TERMINAL"
						Font={Font.bold}
						TextSize={Size.section}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(0.7, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<Badge label="ONLINE" style="compute" pill={true} />
				</frame>
			</Card>

			{/* CRT Terminal Screen Console */}
			<Card height={440} bgColor={Color3.fromRGB(10, 12, 16)} layoutOrder={2}>
				<uipadding
					PaddingLeft={new UDim(0, 16)}
					PaddingRight={new UDim(0, 16)}
					PaddingTop={new UDim(0, 16)}
					PaddingBottom={new UDim(0, 16)}
				/>
				<scrollingframe
					Size={new UDim2(1, 0, 1, 0)}
					BackgroundTransparency={1}
					BorderSizePixel={0}
					ScrollBarThickness={3}
					ScrollBarImageColor3={C.hairline}
					CanvasSize={new UDim2(0, 0, 0, math.max(400, logs.size() * 26))}
				>
					<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 4)} />
					{logs.map((log) => {
						let col = C.textSecondary;
						if (log.level === "success") col = C.compute;
						if (log.level === "warn") col = C.warning;
						if (log.level === "error") col = C.danger;

						return (
							<frame key={log.id} Size={new UDim2(1, 0, 0, 22)} BackgroundTransparency={1}>
								<textlabel
									Text={`[${log.timestamp}] ${log.message}`}
									Font={Font.mono}
									TextSize={Size.caption}
									TextColor3={col}
									BackgroundTransparency={1}
									Size={new UDim2(1, 0, 1, 0)}
									TextXAlignment={Enum.TextXAlignment.Left}
									TextYAlignment={Enum.TextYAlignment.Center}
								/>
							</frame>
						);
					})}
				</scrollingframe>
			</Card>

			{/* Command Input Bar */}
			<frame Size={new UDim2(1, 0, 0, 44)} BackgroundTransparency={1} LayoutOrder={3}>
				<textbox
					ref={inputRef}
					PlaceholderText="Enter command (e.g. 'status', 'recharge', 'help')..."
					PlaceholderColor3={C.textMuted}
					Text={commandText}
					Font={Font.mono}
					TextSize={Size.body}
					TextColor3={C.compute}
					BackgroundColor3={C.recessed}
					BorderSizePixel={0}
					Size={new UDim2(1, -120, 1, 0)}
					Position={new UDim2(0, 0, 0, 0)}
					ClearTextOnFocus={false}
					Event={{
						FocusLost: (enterPressed) => {
							if (enterPressed) submitCommand();
						},
					}}
					Change={{
						Text: (rbx) => setCommandText(rbx.Text),
					}}
				>
					<uicorner CornerRadius={new UDim(0, R.control)} />
					<uipadding PaddingLeft={new UDim(0, 14)} />
					<uistroke Color={C.hairline} Thickness={1} />
				</textbox>

				<Button
					label="Execute"
					variant="primary"
					width={110}
					height={44}
					onClick={submitCommand}
				/>
			</frame>
		</scrollingframe>
	);
}

