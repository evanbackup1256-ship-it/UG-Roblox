// components/SearchPalette.tsx — Command palette modal with keyboard navigation

import React from "@rbxts/react";
import { UserInputService } from "@rbxts/services";
import { C, R, Font, Size } from "../theme";
import { TextInput } from "../ui/TextInput";

interface SearchPaletteProps {
	visible: boolean;
	onClose: () => void;
	onNavigate: (screen: string) => void;
}

interface ScreenEntry {
	id: string;
	label: string;
	description: string;
	icon: string;
}

const SCREENS: ScreenEntry[] = [
	{ id: "overview",       label: "Overview",        description: "Dashboard & live metrics",         icon: "rbxassetid://7733765045" },
	{ id: "operations",     label: "Operations",      description: "Dispatch compute jobs & missions", icon: "rbxassetid://7733765045" },
	{ id: "infrastructure", label: "Infrastructure",  description: "Buy & manage hardware tiers",      icon: "rbxassetid://7733765045" },
	{ id: "research",       label: "Research",        description: "Unlock technology upgrades",       icon: "rbxassetid://7733765045" },
	{ id: "modules",        label: "Modules",         description: "Equip active modifier cards",      icon: "rbxassetid://7733765045" },
	{ id: "contracts",      label: "Contracts",       description: "Accept & fulfil SLA contracts",    icon: "rbxassetid://7733765045" },
	{ id: "rewards",        label: "Rewards",         description: "Claim daily & milestone rewards",  icon: "rbxassetid://7733765045" },
	{ id: "shop",           label: "Shop",            description: "Premium items & boosters",         icon: "rbxassetid://7733765045" },
	{ id: "prestige",       label: "Prestige",        description: "Reset for permanent bonuses",      icon: "rbxassetid://7733765045" },
	{ id: "events",         label: "Events",          description: "Limited-time challenges",          icon: "rbxassetid://7733765045" },
	{ id: "leaderboard",    label: "Leaderboard",     description: "Global operator rankings",         icon: "rbxassetid://7733765045" },
	{ id: "settings",       label: "Settings",        description: "Audio, graphics & account",        icon: "rbxassetid://7733765045" },
];

const ANIM_IN  = new TweenInfo(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);
const ANIM_OUT = new TweenInfo(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In);

function highlightMatch(text: string, query: string): boolean {
	if (query === "") return true;
	return string.find(string.lower(text), string.lower(query), 1, true)[0] !== undefined;
}

export default function SearchPalette({ visible, onClose, onNavigate }: SearchPaletteProps): React.Element {
	const [query, setQuery] = React.useState("");
	const [selectedIdx, setSelectedIdx] = React.useState(0);
	const paletteRef = React.createRef<Frame>();
	const backdropRef = React.createRef<TextButton>();
	const inputRef = React.createRef<TextBox>();

	const filtered = SCREENS.filter(
		(s) => highlightMatch(s.label, query) || highlightMatch(s.description, query),
	);

	// Clamp selection when filter changes
	React.useEffect(() => {
		if (selectedIdx >= filtered.size()) {
			setSelectedIdx(math.max(0, filtered.size() - 1));
		}
	}, [query]);

	// Animate in/out when visible changes
	React.useEffect(() => {
		const palette = paletteRef.current;
		const backdrop = backdropRef.current;
		if (!palette || !backdrop) return;

		const ts = game.GetService("TweenService");

		if (visible) {
			// Reset to off position then tween in
			palette.Position = new UDim2(0.5, 0, 0.35, 0);
			palette.BackgroundTransparency = 0;
			backdrop.BackgroundTransparency = 0.45;

			ts.Create(palette, ANIM_IN, {
				Position: new UDim2(0.5, 0, 0.42, 0),
			}).Play();

			// Focus text input
			task.delay(0.05, () => {
				const box = inputRef.current;
				if (box) box.CaptureFocus();
			});
		} else {
			ts.Create(palette, ANIM_OUT, {
				Position: new UDim2(0.5, 0, 0.35, 0),
				BackgroundTransparency: 1,
			}).Play();
			ts.Create(backdrop, ANIM_OUT, {
				BackgroundTransparency: 1,
			}).Play();
		}
	}, [visible]);

	// Keyboard navigation
	React.useEffect(() => {
		const conn = UserInputService.InputBegan.Connect((input: InputObject, gp: boolean) => {
			if (!visible) return;

			if (input.KeyCode === Enum.KeyCode.Escape) {
				onClose();
				return;
			}

			if (input.KeyCode === Enum.KeyCode.Return || input.KeyCode === Enum.KeyCode.KeypadEnter) {
				const sel = filtered[selectedIdx];
				if (sel) {
					onNavigate(sel.id);
					onClose();
					setQuery("");
				}
				return;
			}

			if (input.KeyCode === Enum.KeyCode.Up) {
				setSelectedIdx((prev) => math.max(0, prev - 1));
				return;
			}

			if (input.KeyCode === Enum.KeyCode.Down) {
				setSelectedIdx((prev) => math.min(filtered.size() - 1, prev + 1));
				return;
			}
		});

		return () => conn.Disconnect();
	}, [visible, filtered, selectedIdx]);

	// Reset query on close
	React.useEffect(() => {
		if (!visible) {
			setQuery("");
			setSelectedIdx(0);
		}
	}, [visible]);

	const handleSelect = (id: string) => {
		onNavigate(id);
		onClose();
		setQuery("");
	};

	return (
		<frame
			key="SearchPaletteRoot"
			BackgroundTransparency={1}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 1, 0)}
			Position={new UDim2(0, 0, 0, 0)}
			ZIndex={50}
			Visible={true}
		>
			{/* Dark backdrop — click to close */}
			<textbutton
				ref={backdropRef}
				key="Backdrop"
				Text=""
				AutoButtonColor={false}
				BackgroundColor3={Color3.fromRGB(0, 0, 0)}
				BackgroundTransparency={visible ? 0.45 : 1}
				BorderSizePixel={0}
				Size={new UDim2(1, 0, 1, 0)}
				ZIndex={51}
				Active={visible}
				Event={{ Activated: onClose }}
			/>

			{/* Palette card */}
			<frame
				ref={paletteRef}
				key="Palette"
				BackgroundColor3={C.elevated}
				BorderSizePixel={0}
				Size={new UDim2(0, 540, 0, 0)}
				AutomaticSize={Enum.AutomaticSize.Y}
				AnchorPoint={new Vector2(0.5, 0.5)}
				Position={new UDim2(0.5, 0, 0.42, 0)}
				ZIndex={52}
				BackgroundTransparency={visible ? 0 : 1}
			>
				<uicorner CornerRadius={new UDim(0, R.modal)} />
				<uistroke Color={C.hairline} Thickness={1} Transparency={0.3} />

				{/* Subtle top gradient bevel */}
				<frame
					key="TopBevel"
					BackgroundColor3={Color3.fromRGB(255, 255, 255)}
					BackgroundTransparency={0.92}
					BorderSizePixel={0}
					Size={new UDim2(1, -20, 0, 1)}
					Position={new UDim2(0.5, 0, 0, 0)}
					AnchorPoint={new Vector2(0.5, 0)}
					ZIndex={53}
				>
					<uigradient
						Transparency={
							new NumberSequence([
								new NumberSequenceKeypoint(0, 1),
								new NumberSequenceKeypoint(0.5, 0),
								new NumberSequenceKeypoint(1, 1),
							])
						}
					/>
				</frame>

				<uilistlayout
					FillDirection={Enum.FillDirection.Vertical}
					SortOrder={Enum.SortOrder.LayoutOrder}
					Padding={new UDim(0, 0)}
				/>

				{/* ── Search Input Header ── */}
				<frame
					key="Header"
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 60)}
					ZIndex={53}
					LayoutOrder={0}
				>
					<uipadding
						PaddingLeft={new UDim(0, 14)}
						PaddingRight={new UDim(0, 14)}
						PaddingTop={new UDim(0, 10)}
						PaddingBottom={new UDim(0, 10)}
					/>

					{/* Search icon */}
					<imagelabel
						key="SearchIcon"
						Image="rbxassetid://7733765045"
						ImageColor3={C.accent}
						BackgroundTransparency={1}
						Size={new UDim2(0, 20, 0, 20)}
						Position={new UDim2(0, 0, 0.5, 0)}
						AnchorPoint={new Vector2(0, 0.5)}
						ScaleType={Enum.ScaleType.Fit}
						ZIndex={54}
					/>

					{/* Text box */}
					<textbox
						ref={inputRef}
						key="QueryInput"
						PlaceholderText="Search screens…"
						PlaceholderColor3={C.textMuted}
						Text={query}
						Font={Font.body}
						TextSize={Size.section}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						BorderSizePixel={0}
						Size={new UDim2(1, -56, 1, 0)}
						Position={new UDim2(0, 30, 0, 0)}
						TextXAlignment={Enum.TextXAlignment.Left}
						ClearTextOnFocus={false}
						ZIndex={54}
						Change={{
							Text: (rbx) => setQuery(rbx.Text),
						}}
					/>

					{/* ESC hint */}
					<frame
						key="EscHint"
						BackgroundColor3={C.recessed}
						BorderSizePixel={0}
						Size={new UDim2(0, 32, 0, 20)}
						Position={new UDim2(1, 0, 0.5, 0)}
						AnchorPoint={new Vector2(1, 0.5)}
						ZIndex={54}
					>
						<uicorner CornerRadius={new UDim(0, R.micro)} />
						<uistroke Color={C.hairline} Thickness={1} Transparency={0.5} />
						<textlabel
							Text="ESC"
							Font={Font.mono}
							TextSize={9}
							TextColor3={C.textMuted}
							BackgroundTransparency={1}
							Size={new UDim2(1, 0, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Center}
							ZIndex={55}
						/>
					</frame>
				</frame>

				{/* Divider */}
				<frame
					key="Divider"
					BackgroundColor3={C.hairline}
					BorderSizePixel={0}
					Size={new UDim2(1, 0, 0, 1)}
					ZIndex={53}
					LayoutOrder={1}
				/>

				{/* ── Results List ── */}
				<scrollingframe
					key="Results"
					BackgroundTransparency={1}
					BorderSizePixel={0}
					ScrollBarThickness={3}
					ScrollBarImageColor3={C.hairline}
					CanvasSize={new UDim2(0, 0, 0, filtered.size() * 52)}
					Size={new UDim2(1, 0, 0, math.min(filtered.size(), 7) * 52)}
					ScrollingDirection={Enum.ScrollingDirection.Y}
					ZIndex={53}
					LayoutOrder={2}
				>
					<uilistlayout
						FillDirection={Enum.FillDirection.Vertical}
						SortOrder={Enum.SortOrder.LayoutOrder}
						Padding={new UDim(0, 0)}
					/>
					<uipadding
						PaddingTop={new UDim(0, 4)}
						PaddingBottom={new UDim(0, 4)}
					/>

					{filtered.size() === 0 && (
						<frame
							key="NoResults"
							BackgroundTransparency={1}
							Size={new UDim2(1, 0, 0, 52)}
							ZIndex={54}
						>
							<textlabel
								Text="No screens match your query"
								Font={Font.body}
								TextSize={Size.body}
								TextColor3={C.textMuted}
								BackgroundTransparency={1}
								Size={new UDim2(1, 0, 1, 0)}
								TextXAlignment={Enum.TextXAlignment.Center}
								ZIndex={55}
							/>
						</frame>
					)}

					{filtered.map((screen, idx) => {
						const isSelected = idx === selectedIdx;
						return (
							<textbutton
								key={screen.id}
								Text=""
								AutoButtonColor={false}
								BackgroundColor3={
									isSelected
										? Color3.fromRGB(59, 130, 246)
										: C.elevated
								}
								BackgroundTransparency={isSelected ? 0.78 : 1}
								BorderSizePixel={0}
								Size={new UDim2(1, 0, 0, 52)}
								ZIndex={54}
								LayoutOrder={idx}
								Event={{
									Activated: () => handleSelect(screen.id),
									MouseEnter: () => setSelectedIdx(idx),
								}}
							>
								<uipadding
									PaddingLeft={new UDim(0, 14)}
									PaddingRight={new UDim(0, 14)}
									PaddingTop={new UDim(0, 8)}
									PaddingBottom={new UDim(0, 8)}
								/>

								{/* Left azure accent bar for selected */}
								{isSelected && (
									<frame
										key="SelectBar"
										BackgroundColor3={Color3.fromRGB(59, 130, 246)}
										BorderSizePixel={0}
										Size={new UDim2(0, 3, 0.7, 0)}
										Position={new UDim2(0, 0, 0.5, 0)}
										AnchorPoint={new Vector2(0, 0.5)}
										ZIndex={55}
									>
										<uicorner CornerRadius={new UDim(0, R.pill)} />
									</frame>
								)}

								<uilistlayout
									FillDirection={Enum.FillDirection.Horizontal}
									VerticalAlignment={Enum.VerticalAlignment.Center}
									Padding={new UDim(0, 10)}
								/>

								{/* Icon */}
								<imagelabel
									key="Icon"
									Image={screen.icon}
									ImageColor3={isSelected ? Color3.fromRGB(96, 165, 250) : C.textMuted}
									BackgroundTransparency={1}
									Size={new UDim2(0, 22, 0, 22)}
									ScaleType={Enum.ScaleType.Fit}
									ZIndex={55}
								/>

								{/* Text column */}
								<frame
									key="TextCol"
									BackgroundTransparency={1}
									Size={new UDim2(1, -32, 1, 0)}
									ZIndex={55}
								>
									<uilistlayout
										FillDirection={Enum.FillDirection.Vertical}
										VerticalAlignment={Enum.VerticalAlignment.Center}
										Padding={new UDim(0, 2)}
									/>
									<textlabel
										key="ScreenName"
										Text={screen.label}
										Font={Font.bold}
										TextSize={Size.body}
										TextColor3={
											isSelected ? Color3.fromRGB(248, 250, 252) : C.textPrimary
										}
										BackgroundTransparency={1}
										Size={new UDim2(1, 0, 0, 16)}
										TextXAlignment={Enum.TextXAlignment.Left}
										ZIndex={56}
									/>
									<textlabel
										key="Desc"
										Text={screen.description}
										Font={Font.body}
										TextSize={Size.caption}
										TextColor3={
											isSelected ? Color3.fromRGB(148, 163, 184) : C.textMuted
										}
										BackgroundTransparency={1}
										Size={new UDim2(1, 0, 0, 14)}
										TextXAlignment={Enum.TextXAlignment.Left}
										TextTruncate={Enum.TextTruncate.AtEnd}
										ZIndex={56}
									/>
								</frame>

								{/* Enter hint on selected */}
								{isSelected && (
									<frame
										key="EnterHint"
										BackgroundColor3={C.recessed}
										BorderSizePixel={0}
										Size={new UDim2(0, 40, 0, 20)}
										AnchorPoint={new Vector2(1, 0.5)}
										Position={new UDim2(1, 0, 0.5, 0)}
										ZIndex={55}
									>
										<uicorner CornerRadius={new UDim(0, R.micro)} />
										<uistroke Color={Color3.fromRGB(59, 130, 246)} Thickness={1} Transparency={0.55} />
										<textlabel
											Text="↵"
											Font={Font.mono}
											TextSize={Size.caption}
											TextColor3={Color3.fromRGB(96, 165, 250)}
											BackgroundTransparency={1}
											Size={new UDim2(1, 0, 1, 0)}
											TextXAlignment={Enum.TextXAlignment.Center}
											ZIndex={56}
										/>
									</frame>
								)}
							</textbutton>
						);
					})}
				</scrollingframe>

				{/* ── Footer hint bar ── */}
				<frame
					key="Footer"
					BackgroundColor3={C.recessed}
					BorderSizePixel={0}
					Size={new UDim2(1, 0, 0, 32)}
					ZIndex={53}
					LayoutOrder={3}
				>
					<uicorner CornerRadius={new UDim(0, R.modal)} />

					<frame
						key="HintRow"
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 1, 0)}
						ZIndex={54}
					>
						<uipadding
							PaddingLeft={new UDim(0, 14)}
							PaddingRight={new UDim(0, 14)}
						/>
						<uilistlayout
							FillDirection={Enum.FillDirection.Horizontal}
							VerticalAlignment={Enum.VerticalAlignment.Center}
							Padding={new UDim(0, 16)}
						/>

						{/* ↑↓ navigate */}
						<textlabel
							key="NavHint"
							Text="↑↓  navigate"
							Font={Font.mono}
							TextSize={9}
							TextColor3={C.textMuted}
							BackgroundTransparency={1}
							Size={new UDim2(0, 0, 1, 0)}
							AutomaticSize={Enum.AutomaticSize.X}
							TextXAlignment={Enum.TextXAlignment.Left}
							ZIndex={55}
						/>
						{/* ↵ select */}
						<textlabel
							key="SelectHint"
							Text="↵  select"
							Font={Font.mono}
							TextSize={9}
							TextColor3={C.textMuted}
							BackgroundTransparency={1}
							Size={new UDim2(0, 0, 1, 0)}
							AutomaticSize={Enum.AutomaticSize.X}
							TextXAlignment={Enum.TextXAlignment.Left}
							ZIndex={55}
						/>
						{/* ESC close */}
						<textlabel
							key="CloseHint"
							Text="ESC  close"
							Font={Font.mono}
							TextSize={9}
							TextColor3={C.textMuted}
							BackgroundTransparency={1}
							Size={new UDim2(0, 0, 1, 0)}
							AutomaticSize={Enum.AutomaticSize.X}
							TextXAlignment={Enum.TextXAlignment.Left}
							ZIndex={55}
						/>
					</frame>
				</frame>
			</frame>
		</frame>
	);
}

