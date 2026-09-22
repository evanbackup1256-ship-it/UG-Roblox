// screens/ScreenCommand.tsx — Command Center: job button, stat grid, overclock banner

import React from "@rbxts/react";
import { C, Font, Size, R } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { StatTile } from "../ui/StatTile";
import { ProgressBar } from "../ui/ProgressBar";
import { useGameState } from "../hooks";
import { act, fmt } from "../store";

// ------- constants -------------------------------------------------------
const ENERGY_CAP = 100;
const FLOAT_INFO  = new TweenInfo(0.80, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

// ------- floating +X label -----------------------------------------------
interface FloatPopProps { amount: number; id: number }
function FloatPop({ amount, id }: FloatPopProps) {
	const ref = React.createRef<TextLabel>();

	React.useEffect(() => {
		const lbl = ref.current;
		if (!lbl) return;
		const ts = game.GetService("TweenService");
		ts.Create(lbl, FLOAT_INFO, {
			Position: new UDim2(0.5, 0, 0, -60),
			TextTransparency: 1,
		}).Play();
		task.delay(0.85, () => {
			const l = ref.current;
			if (l && l.Parent) l.Parent = undefined;
		});
	}, []);

	return (
		<textlabel
			ref={ref}
			key={`pop_${id}`}
			Text={`+${fmt(amount)} ⚡`}
			Font={Font.bold}
			TextSize={Size.section}
			TextColor3={C.compute}
			TextStrokeTransparency={0.6}
			BackgroundTransparency={1}
			Size={new UDim2(1, 0, 0, 30)}
			Position={new UDim2(0.5, 0, 0, -20)}
			AnchorPoint={new Vector2(0.5, 0)}
			ZIndex={20}
		/>
	);
}

// ------- main screen -----------------------------------------------------
export default function ScreenCommand(): React.Element {
	const gs = useGameState();
	const [pops, setPops] = React.useState<Array<{ id: number; amount: number }>>([]);
	const popCounter = React.useRef(0);

	const energyPct   = math.clamp(gs.energy / ENERGY_CAP, 0, 1);
	const totalOwned   = (() => {
		let n = 0;
		gs.owned.forEach((v) => { n += v; });
		return n;
	})();
	const prestigeBonus = gs.prestigeTokens * 0.1;
	const isOverclocked = gs.boostUntil > os.time();

	function handleJob() {
		const result = act("job") as number | undefined;
		const gained = result ?? 1;
		const id = popCounter.current++;
		setPops((prev) => [...prev, { id, amount: gained }]);
	}

	return (
		<scrollingframe
			BackgroundColor3={C.canvas}
			BackgroundTransparency={0}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 1, 0)}
			CanvasSize={new UDim2(0, 0, 0, 0)}
			AutomaticCanvasSize={Enum.AutomaticSize.Y}
			ScrollBarThickness={3}
			ScrollBarImageColor3={C.hairline}
			ScrollingDirection={Enum.ScrollingDirection.Y}
		>
			<uilistlayout
				FillDirection={Enum.FillDirection.Vertical}
				Padding={new UDim(0, 12)}
				SortOrder={Enum.SortOrder.LayoutOrder}
			/>
			<uipadding
				PaddingLeft={new UDim(0, 14)}
				PaddingRight={new UDim(0, 14)}
				PaddingTop={new UDim(0, 14)}
				PaddingBottom={new UDim(0, 24)}
			/>

			{/* ── OVERCLOCK BANNER ─────────────────────────────────────── */}
			{isOverclocked && (
				<frame
					key="OverclockBanner"
					BackgroundColor3={Color3.fromRGB(40, 22, 6)}
					BorderSizePixel={0}
					Size={new UDim2(1, 0, 0, 44)}
					LayoutOrder={0}
				>
					<uicorner CornerRadius={new UDim(0, R.card)} />
					<uistroke Color={C.warning} Thickness={1} Transparency={0.45} />
					<uipadding
						PaddingLeft={new UDim(0, 16)}
						PaddingRight={new UDim(0, 16)}
					/>
					<textlabel
						Text="⚡  OVERCLOCK ACTIVE — compute multiplier boosted"
						Font={Font.bold}
						TextSize={Size.body}
						TextColor3={C.warning}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Left}
						TextYAlignment={Enum.TextYAlignment.Center}
					/>
				</frame>
			)}

			{/* ── HERO CARD ────────────────────────────────────────────── */}
			<Card height={192} layoutOrder={1}>
				<uilistlayout
					FillDirection={Enum.FillDirection.Vertical}
					Padding={new UDim(0, 6)}
					SortOrder={Enum.SortOrder.LayoutOrder}
					HorizontalAlignment={Enum.HorizontalAlignment.Center}
				/>
				<uipadding
					PaddingLeft={new UDim(0, 20)}
					PaddingRight={new UDim(0, 20)}
					PaddingTop={new UDim(0, 20)}
					PaddingBottom={new UDim(0, 20)}
				/>

				<textlabel
					key="HeroTitle"
					Text="COMMAND CENTER"
					Font={Font.bold}
					TextSize={Size.hero}
					TextColor3={C.textPrimary}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 32)}
					TextXAlignment={Enum.TextXAlignment.Left}
					LayoutOrder={1}
				/>
				<textlabel
					key="HeroSub"
					Text="Generate compute manually or let your hardware empire run."
					Font={Font.body}
					TextSize={Size.body}
					TextColor3={C.textSecondary}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 20)}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextWrapped={true}
					LayoutOrder={2}
				/>

				{/* Float pop container */}
				<frame
					key="PopLayer"
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 0)}
					LayoutOrder={3}
					ZIndex={15}
					ClipsDescendants={false}
				>
					{pops.map((p) => <FloatPop key={tostring(p.id)} amount={p.amount} id={p.id} />)}
				</frame>

				<frame
					key="ButtonWrap"
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 48)}
					LayoutOrder={4}
				>
					<Button
						label="⚡  Generate Compute"
						onClick={handleJob}
						variant="primary"
						height={48}
					/>
				</frame>
			</Card>

			{/* ── STAT GRID ────────────────────────────────────────────── */}
			<frame
				key="StatGrid"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 230)}
				AutomaticSize={Enum.AutomaticSize.Y}
				LayoutOrder={2}
			>
				<uigridlayout
					CellSize={new UDim2(0.5, -6, 0, 108)}
					CellPadding={new UDim2(0, 12, 0, 12)}
					SortOrder={Enum.SortOrder.LayoutOrder}
					FillDirection={Enum.FillDirection.Horizontal}
					HorizontalAlignment={Enum.HorizontalAlignment.Left}
					VerticalAlignment={Enum.VerticalAlignment.Top}
				/>

				<StatTile
					title="ENERGY"
					value={`${math.floor(gs.energy)} / ${ENERGY_CAP}`}
					subtitle="power reserve"
					color={C.energy}
					layoutOrder={1}
					progress={energyPct}
				/>
				<StatTile
					title="HARDWARE"
					value={fmt(totalOwned)}
					subtitle="units deployed"
					color={C.data}
					layoutOrder={2}
				/>
				<StatTile
					title="DATA"
					value={fmt(gs.data)}
					subtitle="bytes collected"
					color={C.data}
					layoutOrder={3}
				/>
				<StatTile
					title="MULTIPLIER"
					value={`×${string.format("%.1f", 1 + prestigeBonus)}`}
					subtitle={`${gs.prestigeTokens} prestige tokens`}
					color={C.reputation}
					layoutOrder={4}
				/>
			</frame>

			{/* ── COMPUTE TOTAL ────────────────────────────────────────── */}
			<Card height={72} layoutOrder={3} bgColor={Color3.fromRGB(10, 22, 16)}>
				<uipadding
					PaddingLeft={new UDim(0, 20)}
					PaddingRight={new UDim(0, 20)}
					PaddingTop={new UDim(0, 14)}
					PaddingBottom={new UDim(0, 14)}
				/>
				<uilistlayout
					FillDirection={Enum.FillDirection.Horizontal}
					VerticalAlignment={Enum.VerticalAlignment.Center}
					HorizontalAlignment={Enum.HorizontalAlignment.Left}
					Padding={new UDim(0, 8)}
					SortOrder={Enum.SortOrder.LayoutOrder}
				/>
				<textlabel
					key="ComputeLabel"
					Text="COMPUTE"
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.textMuted}
					BackgroundTransparency={1}
					Size={new UDim2(0, 80, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextYAlignment={Enum.TextYAlignment.Center}
					LayoutOrder={1}
				/>
				<textlabel
					key="ComputeVal"
					Text={fmt(gs.compute)}
					Font={Font.bold}
					TextSize={Size.title}
					TextColor3={C.compute}
					BackgroundTransparency={1}
					Size={new UDim2(1, -88, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextYAlignment={Enum.TextYAlignment.Center}
					LayoutOrder={2}
				/>
			</Card>
		</scrollingframe>
	);
}

