// components/TopBar.tsx — Full-width HUD bar for Deck Cloud Empire

import React from "@rbxts/react";
import { RunService } from "@rbxts/services";
import { C, R, Font, Size } from "../theme";
import { ProgressBar } from "../ui/ProgressBar";
import { fmt } from "../store";

interface TopBarProps {
	activeScreen: string;
	callsign: string;
	compute: number;
	computeRate: number;
	energy: number;
	energyCap: number;
	data: number;
	onSearchOpen: () => void;
}

// Thin hairline pill wrapper — recessed well with pill corners
function Pill({ children, width }: { children: React.ReactNode; width?: number }) {
	return (
		<frame
			BackgroundColor3={C.recessed}
			BorderSizePixel={0}
			Size={width ? new UDim2(0, width, 1, -16) : new UDim2(0, 0, 1, -16)}
			AutomaticSize={width ? Enum.AutomaticSize.None : Enum.AutomaticSize.X}
			AnchorPoint={new Vector2(0, 0.5)}
			Position={new UDim2(0, 0, 0.5, 0)}
		>
			<uicorner CornerRadius={new UDim(0, R.pill)} />
			<uistroke Color={C.hairline} Thickness={1} Transparency={0.45} />
			<uipadding
				PaddingLeft={new UDim(0, 10)}
				PaddingRight={new UDim(0, 10)}
				PaddingTop={new UDim(0, 5)}
				PaddingBottom={new UDim(0, 5)}
			/>
			{children}
		</frame>
	);
}

export default function TopBar({
	activeScreen,
	callsign,
	compute,
	computeRate,
	energy,
	energyCap,
	data,
	onSearchOpen,
}: TopBarProps): React.Element {
	const [fps, setFps] = React.useState(60);
	const fpsRef = React.useRef<number>(60);
	const sampleCountRef = React.useRef<number>(0);
	const accumRef = React.useRef<number>(0);

	React.useEffect(() => {
		const conn = RunService.Heartbeat.Connect((dt: number) => {
			accumRef.current += dt;
			sampleCountRef.current += 1;
			if (sampleCountRef.current >= 20) {
				const avg = sampleCountRef.current / accumRef.current;
				fpsRef.current = math.round(avg);
				setFps(fpsRef.current);
				sampleCountRef.current = 0;
				accumRef.current = 0;
			}
		});
		return () => conn.Disconnect();
	}, []);

	const energyPct = energyCap > 0 ? math.clamp(energy / energyCap, 0, 1) : 0;

	// FPS color: green ≥50, amber 30-49, red <30
	const fpsColor =
		fps >= 50 ? C.compute : fps >= 30 ? C.energy : C.danger;

	const breadcrumb = `> ${string.upper(activeScreen)}`;

	return (
		<frame
			key="TopBar"
			BackgroundColor3={C.panel}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 0, 56)}
			Position={new UDim2(0, 0, 0, 0)}
			ZIndex={20}
		>
			{/* Bottom hairline */}
			<frame
				key="BottomHairline"
				BackgroundColor3={C.hairline}
				BorderSizePixel={0}
				Size={new UDim2(1, 0, 0, 1)}
				Position={new UDim2(0, 0, 1, -1)}
				ZIndex={21}
			/>

			{/* ── Left: Operator Pill ── */}
			<frame
				key="LeftSection"
				BackgroundTransparency={1}
				Size={new UDim2(0, 240, 1, 0)}
				Position={new UDim2(0, 8, 0, 0)}
				ZIndex={21}
			>
				<frame
					key="OperatorPill"
					BackgroundColor3={C.recessed}
					BorderSizePixel={0}
					Size={new UDim2(0, 0, 1, -16)}
					AutomaticSize={Enum.AutomaticSize.X}
					AnchorPoint={new Vector2(0, 0.5)}
					Position={new UDim2(0, 0, 0.5, 0)}
					ZIndex={22}
				>
					<uicorner CornerRadius={new UDim(0, R.pill)} />
					<uistroke Color={C.hairline} Thickness={1} Transparency={0.45} />
					<uipadding
						PaddingLeft={new UDim(0, 6)}
						PaddingRight={new UDim(0, 12)}
						PaddingTop={new UDim(0, 4)}
						PaddingBottom={new UDim(0, 4)}
					/>

					<uilistlayout
						FillDirection={Enum.FillDirection.Horizontal}
						VerticalAlignment={Enum.VerticalAlignment.Center}
						Padding={new UDim(0, 8)}
					/>

					{/* Avatar */}
					<imagelabel
						key="Avatar"
						Image="rbxassetid://7733765045"
						ImageColor3={C.accent}
						BackgroundColor3={C.elevated}
						BorderSizePixel={0}
						Size={new UDim2(0, 28, 0, 28)}
					>
						<uicorner CornerRadius={new UDim(0, R.pill)} />
						<uistroke Color={C.accent} Thickness={1} Transparency={0.55} />
					</imagelabel>

					{/* Text stack */}
					<frame
						key="TextStack"
						BackgroundTransparency={1}
						Size={new UDim2(0, 0, 1, 0)}
						AutomaticSize={Enum.AutomaticSize.X}
					>
						<uilistlayout
							FillDirection={Enum.FillDirection.Vertical}
							VerticalAlignment={Enum.VerticalAlignment.Center}
							Padding={new UDim(0, 1)}
						/>
						<textlabel
							key="Callsign"
							Text={callsign}
							Font={Font.bold}
							TextSize={Size.caption}
							TextColor3={C.textPrimary}
							BackgroundTransparency={1}
							Size={new UDim2(0, 0, 0, 14)}
							AutomaticSize={Enum.AutomaticSize.X}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
						<textlabel
							key="Breadcrumb"
							Text={breadcrumb}
							Font={Font.mono}
							TextSize={Size.micro}
							TextColor3={C.textMuted}
							BackgroundTransparency={1}
							Size={new UDim2(0, 0, 0, 12)}
							AutomaticSize={Enum.AutomaticSize.X}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
					</frame>
				</frame>
			</frame>

			{/* ── Right: Stat Pills Row ── */}
			<frame
				key="RightSection"
				BackgroundTransparency={1}
				Size={new UDim2(0, 0, 1, 0)}
				AutomaticSize={Enum.AutomaticSize.X}
				AnchorPoint={new Vector2(1, 0)}
				Position={new UDim2(1, -8, 0, 0)}
				ZIndex={21}
			>
				<uilistlayout
					FillDirection={Enum.FillDirection.Horizontal}
					VerticalAlignment={Enum.VerticalAlignment.Center}
					HorizontalAlignment={Enum.HorizontalAlignment.Right}
					Padding={new UDim(0, 6)}
				/>

				{/* Search button */}
				<textbutton
					key="SearchBtn"
					Text=""
					AutoButtonColor={false}
					BackgroundColor3={C.recessed}
					BorderSizePixel={0}
					Size={new UDim2(0, 36, 0, 36)}
					ZIndex={22}
					Event={{
						Activated: onSearchOpen,
					}}
				>
					<uicorner CornerRadius={new UDim(0, R.control)} />
					<uistroke Color={C.hairline} Thickness={1} Transparency={0.45} />
					<imagelabel
						Image="rbxassetid://7733765045"
						ImageColor3={C.textSecondary}
						BackgroundTransparency={1}
						Size={new UDim2(0, 18, 0, 18)}
						Position={new UDim2(0.5, 0, 0.5, 0)}
						AnchorPoint={new Vector2(0.5, 0.5)}
						ScaleType={Enum.ScaleType.Fit}
					/>
				</textbutton>

				{/* FPS Pill */}
				<frame
					key="FpsPill"
					BackgroundColor3={C.recessed}
					BorderSizePixel={0}
					Size={new UDim2(0, 58, 1, -16)}
					AnchorPoint={new Vector2(0, 0.5)}
					Position={new UDim2(0, 0, 0.5, 0)}
					ZIndex={22}
				>
					<uicorner CornerRadius={new UDim(0, R.pill)} />
					<uistroke Color={C.hairline} Thickness={1} Transparency={0.45} />
					<textlabel
						key="FpsLabel"
						Text="FPS"
						Font={Font.mono}
						TextSize={Size.micro}
						TextColor3={C.textMuted}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 11)}
						Position={new UDim2(0.5, 0, 0, 5)}
						AnchorPoint={new Vector2(0.5, 0)}
						TextXAlignment={Enum.TextXAlignment.Center}
					/>
					<textlabel
						key="FpsValue"
						Text={tostring(fps)}
						Font={Font.bold}
						TextSize={Size.caption}
						TextColor3={fpsColor}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 14)}
						Position={new UDim2(0.5, 0, 1, -6)}
						AnchorPoint={new Vector2(0.5, 1)}
						TextXAlignment={Enum.TextXAlignment.Center}
					/>
				</frame>

				{/* Data Pill */}
				<frame
					key="DataPill"
					BackgroundColor3={C.recessed}
					BorderSizePixel={0}
					Size={new UDim2(0, 80, 1, -16)}
					AnchorPoint={new Vector2(0, 0.5)}
					Position={new UDim2(0, 0, 0.5, 0)}
					ZIndex={22}
				>
					<uicorner CornerRadius={new UDim(0, R.pill)} />
					<uistroke Color={C.data} Thickness={1} Transparency={0.72} />
					<uipadding PaddingLeft={new UDim(0, 8)} PaddingRight={new UDim(0, 8)} />
					<textlabel
						key="Label"
						Text="DATA"
						Font={Font.mono}
						TextSize={Size.micro}
						TextColor3={C.data}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 11)}
						Position={new UDim2(0, 0, 0, 5)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<textlabel
						key="Value"
						Text={fmt(data)}
						Font={Font.bold}
						TextSize={Size.caption}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 14)}
						Position={new UDim2(0, 0, 1, -6)}
						AnchorPoint={new Vector2(0, 1)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
				</frame>

				{/* Energy Pill */}
				<frame
					key="EnergyPill"
					BackgroundColor3={C.recessed}
					BorderSizePixel={0}
					Size={new UDim2(0, 100, 1, -16)}
					AnchorPoint={new Vector2(0, 0.5)}
					Position={new UDim2(0, 0, 0.5, 0)}
					ZIndex={22}
				>
					<uicorner CornerRadius={new UDim(0, R.pill)} />
					<uistroke Color={C.energy} Thickness={1} Transparency={0.72} />
					<uipadding
						PaddingLeft={new UDim(0, 8)}
						PaddingRight={new UDim(0, 8)}
						PaddingBottom={new UDim(0, 5)}
					/>
					<textlabel
						key="Label"
						Text="ENERGY"
						Font={Font.mono}
						TextSize={Size.micro}
						TextColor3={C.energy}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 11)}
						Position={new UDim2(0, 0, 0, 5)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<textlabel
						key="Value"
						Text={`${fmt(energy)} / ${fmt(energyCap)}`}
						Font={Font.bold}
						TextSize={Size.caption}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 13)}
						Position={new UDim2(0, 0, 0, 19)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					{/* Mini energy bar pinned to bottom */}
					<frame
						key="EnergyBarWrap"
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 4)}
						Position={new UDim2(0, 0, 1, -9)}
					>
						<ProgressBar progress={energyPct} color={C.energy} height={4} />
					</frame>
				</frame>

				{/* Compute Pill */}
				<frame
					key="ComputePill"
					BackgroundColor3={C.recessed}
					BorderSizePixel={0}
					Size={new UDim2(0, 110, 1, -16)}
					AnchorPoint={new Vector2(0, 0.5)}
					Position={new UDim2(0, 0, 0.5, 0)}
					ZIndex={22}
				>
					<uicorner CornerRadius={new UDim(0, R.pill)} />
					<uistroke Color={C.compute} Thickness={1} Transparency={0.72} />
					<uipadding PaddingLeft={new UDim(0, 8)} PaddingRight={new UDim(0, 8)} />
					<textlabel
						key="Label"
						Text="COMPUTE"
						Font={Font.mono}
						TextSize={Size.micro}
						TextColor3={C.compute}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 11)}
						Position={new UDim2(0, 0, 0, 5)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<frame
						key="ValueRow"
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 14)}
						Position={new UDim2(0, 0, 1, -6)}
						AnchorPoint={new Vector2(0, 1)}
					>
						<uilistlayout
							FillDirection={Enum.FillDirection.Horizontal}
							VerticalAlignment={Enum.VerticalAlignment.Center}
							Padding={new UDim(0, 3)}
						/>
						<textlabel
							key="Amount"
							Text={fmt(compute)}
							Font={Font.bold}
							TextSize={Size.caption}
							TextColor3={C.textPrimary}
							BackgroundTransparency={1}
							Size={new UDim2(0, 0, 1, 0)}
							AutomaticSize={Enum.AutomaticSize.X}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
						<textlabel
							key="Rate"
							Text={`+${fmt(computeRate)}/s`}
							Font={Font.mono}
							TextSize={Size.micro}
							TextColor3={C.compute}
							BackgroundTransparency={1}
							Size={new UDim2(0, 0, 1, 0)}
							AutomaticSize={Enum.AutomaticSize.X}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
					</frame>
				</frame>
			</frame>
		</frame>
	);
}

