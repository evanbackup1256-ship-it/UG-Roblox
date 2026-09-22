// components/Toast.tsx — Global toast notification overlay with slide+fade animations

import React from "@rbxts/react";
import { C, R, Font, Size } from "../theme";

// ─── Public API ───────────────────────────────────────────────────────────────

interface ToastEntry {
	id: number;
	message: string;
	isError: boolean;
	title?: string;
}

type ToastListener = (toasts: ToastEntry[]) => void;

let nextId = 0;
const toastListeners = new Array<ToastListener>();
let activeToasts: ToastEntry[] = [];

function notifyListeners() {
	// Shallow-copy so React sees a new reference
	const snapshot = [...activeToasts];
	for (const l of toastListeners) {
		task.spawn(() => l(snapshot));
	}
}

/** Call from anywhere to show a toast notification. */
export function showToast(message: string, isError = false, title?: string): void {
	const id = nextId++;
	const entry: ToastEntry = { id, message, isError, title };
	activeToasts = [...activeToasts, entry];
	notifyListeners();

	// Auto-dismiss after 4 seconds
	task.delay(4, () => {
		activeToasts = activeToasts.filter((t) => t.id !== id);
		notifyListeners();
	});
}

// ─── Individual Toast ──────────────────────────────────────────────────────────

const SLIDE_IN = new TweenInfo(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);
const SLIDE_OUT = new TweenInfo(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In);

function ToastCard({ entry, onDismiss }: { entry: ToastEntry; onDismiss: (id: number) => void }) {
	const containerRef = React.createRef<Frame>();
	const [mounted, setMounted] = React.useState(false);

	const accentColor = entry.isError ? C.danger : C.success;

	// Slide in on mount
	React.useEffect(() => {
		const frame = containerRef.current;
		if (!frame) return;

		// Start off-screen to the right
		frame.Position = new UDim2(1, 20, 0, 0);
		frame.BackgroundTransparency = 0;

		// Tiny delay so the frame renders first
		task.delay(0.02, () => {
			const f = containerRef.current;
			if (!f) return;
			game
				.GetService("TweenService")
				.Create(f, SLIDE_IN, { Position: new UDim2(0, 0, 0, 0) })
				.Play();
		});

		setMounted(true);
	}, []);

	const dismiss = () => {
		const frame = containerRef.current;
		if (!frame) {
			onDismiss(entry.id);
			return;
		}
		const t = game
			.GetService("TweenService")
			.Create(frame, SLIDE_OUT, {
				Position: new UDim2(1, 30, 0, 0),
				BackgroundTransparency: 1,
			});
		t.Completed.Connect(() => onDismiss(entry.id));
		t.Play();
	};

	return (
		<frame
			ref={containerRef}
			key={tostring(entry.id)}
			BackgroundColor3={C.card}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 0, 0)}
			AutomaticSize={Enum.AutomaticSize.Y}
			ClipsDescendants={false}
			ZIndex={102}
		>
			<uicorner CornerRadius={new UDim(0, R.card)} />
			<uistroke Color={accentColor} Thickness={1} Transparency={0.6} />

			{/* Left accent bar */}
			<frame
				key="AccentBar"
				BackgroundColor3={accentColor}
				BorderSizePixel={0}
				Size={new UDim2(0, 3, 1, 0)}
				Position={new UDim2(0, 0, 0, 0)}
				ZIndex={103}
			>
				<uicorner CornerRadius={new UDim(0, R.card)} />
			</frame>

			{/* Content */}
			<frame
				key="Content"
				BackgroundTransparency={1}
				Size={new UDim2(1, -32, 0, 0)}
				AutomaticSize={Enum.AutomaticSize.Y}
				Position={new UDim2(0, 14, 0, 0)}
				ZIndex={103}
			>
				<uipadding
					PaddingTop={new UDim(0, 10)}
					PaddingBottom={new UDim(0, 10)}
					PaddingLeft={new UDim(0, 4)}
					PaddingRight={new UDim(0, 4)}
				/>
				<uilistlayout
					FillDirection={Enum.FillDirection.Vertical}
					Padding={new UDim(0, 3)}
					SortOrder={Enum.SortOrder.LayoutOrder}
				/>
				{entry.title !== undefined && entry.title !== "" && (
					<textlabel
						key="Title"
						Text={entry.title}
						Font={Font.bold}
						TextSize={Size.caption}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 15)}
						TextXAlignment={Enum.TextXAlignment.Left}
						TextTruncate={Enum.TextTruncate.AtEnd}
						LayoutOrder={0}
					/>
				)}
				<textlabel
					key="Message"
					Text={entry.message}
					Font={Font.body}
					TextSize={Size.caption}
					TextColor3={C.textSecondary}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 0)}
					AutomaticSize={Enum.AutomaticSize.Y}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextWrapped={true}
					LayoutOrder={1}
				/>
			</frame>

			{/* Dismiss X button */}
			<textbutton
				key="DismissBtn"
				Text="✕"
				Font={Font.body}
				TextSize={Size.micro}
				TextColor3={C.textMuted}
				AutoButtonColor={false}
				BackgroundTransparency={1}
				BorderSizePixel={0}
				Size={new UDim2(0, 20, 0, 20)}
				Position={new UDim2(1, -6, 0, 6)}
				AnchorPoint={new Vector2(1, 0)}
				ZIndex={104}
				Event={{ Activated: dismiss }}
			/>
		</frame>
	);
}

// ─── Toast Container ───────────────────────────────────────────────────────────

export default function Toast(): React.Element {
	const [toasts, setToasts] = React.useState<ToastEntry[]>([]);

	React.useEffect(() => {
		// Register listener
		toastListeners.push(setToasts);
		return () => {
			const idx = toastListeners.indexOf(setToasts);
			if (idx !== -1) toastListeners.remove(idx);
		};
	}, []);

	const handleDismiss = (id: number) => {
		setToasts((prev) => prev.filter((t) => t.id !== id));
		// Also prune from global list
		activeToasts = activeToasts.filter((t) => t.id !== id);
	};

	return (
		<frame
			key="ToastOverlay"
			BackgroundTransparency={1}
			BorderSizePixel={0}
			Size={new UDim2(0, 300, 1, -80)}
			Position={new UDim2(1, -308, 0, 64)}
			AnchorPoint={new Vector2(0, 0)}
			ZIndex={100}
			ClipsDescendants={false}
		>
			<uilistlayout
				FillDirection={Enum.FillDirection.Vertical}
				VerticalAlignment={Enum.VerticalAlignment.Top}
				Padding={new UDim(0, 8)}
				SortOrder={Enum.SortOrder.LayoutOrder}
			/>

			{toasts.map((entry) => (
				<ToastCard
					key={tostring(entry.id)}
					entry={entry}
					onDismiss={handleDismiss}
				/>
			))}
		</frame>
	);
}

