// screens/ScreenOperations.tsx — Energy management and mission dispatch

import React from "@rbxts/react";
import { C, Font, Size, R } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { ProgressBar } from "../ui/ProgressBar";
import { useGameState } from "../hooks";
import { act, fmt } from "../store";

interface ConfigOpRaw {
	name?: string;
	description?: string;
	successRate?: number;
	rewardCompute?: number;
	rewardData?: number;
	energyCost?: number;
}

const Config = require(game.GetService("ReplicatedStorage")
	.WaitForChild("DeckGame")
	.WaitForChild("Config") as ModuleScript) as { Operations?: Record<string, ConfigOpRaw> };

const ENERGY_CAP = 100;

interface OpEntry {
	key: string;
	name: string;
	description: string;
	successRate: number; // 0..1
	rewardCompute: number;
	rewardData: number;
	energyCost: number;
}

function opList(): OpEntry[] {
	const ops = Config.Operations ?? {};
	const result: OpEntry[] = [];
	for (const [k, v] of pairs(ops)) {
		result.push({
			key: k as string,
			name: v.name ?? (k as string),
			description: v.description ?? "",
			successRate: v.successRate ?? 0.8,
			rewardCompute: v.rewardCompute ?? 0,
			rewardData: v.rewardData ?? 0,
			energyCost: v.energyCost ?? 10,
		});
	}
	return result;
}

// ------- mission card ---------------------------------------------------
interface MissionCardProps {
	op: OpEntry;
	index: number;
	energy: number;
	onDispatch: () => void;
}

function MissionCard({ op, index, energy, onDispatch }: MissionCardProps) {
	const canDispatch = energy >= op.energyCost;
	const pct = op.successRate;
	const pctStr = `${math.floor(pct * 100)}%`;
	const rewardStr = op.rewardCompute > 0
		? `+${fmt(op.rewardCompute)} compute`
		: `+${fmt(op.rewardData)} data`;

	const tagLabel = `TASK ${string.format("%02d", index)}`;

	return (
		<Card height={200} layoutOrder={index}>
			<uipadding
				PaddingLeft={new UDim(0, 18)}
				PaddingRight={new UDim(0, 18)}
				PaddingTop={new UDim(0, 16)}
				PaddingBottom={new UDim(0, 16)}
			/>
			<uilistlayout
				FillDirection={Enum.FillDirection.Vertical}
				Padding={new UDim(0, 8)}
				SortOrder={Enum.SortOrder.LayoutOrder}
			/>

			{/* Badge row */}
			<frame
				key="BadgeRow"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 22)}
				LayoutOrder={1}
			>
				<Badge label={tagLabel} style="accent" />
			</frame>

			{/* Name */}
			<textlabel
				key="OpName"
				Text={op.name}
				Font={Font.bold}
				TextSize={Size.section}
				TextColor3={C.textPrimary}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 22)}
				TextXAlignment={Enum.TextXAlignment.Left}
				LayoutOrder={2}
			/>

			{/* Description */}
			<textlabel
				key="OpDesc"
				Text={op.description !== "" ? op.description : "Execute automated cloud operations."}
				Font={Font.body}
				TextSize={Size.caption}
				TextColor3={C.textSecondary}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 32)}
				TextXAlignment={Enum.TextXAlignment.Left}
				TextYAlignment={Enum.TextYAlignment.Top}
				TextWrapped={true}
				LayoutOrder={3}
			/>

			{/* Stats row */}
			<frame
				key="StatsRow"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 16)}
				LayoutOrder={4}
			>
				<uilistlayout
					FillDirection={Enum.FillDirection.Horizontal}
					Padding={new UDim(0, 16)}
					SortOrder={Enum.SortOrder.LayoutOrder}
					VerticalAlignment={Enum.VerticalAlignment.Center}
				/>
				<textlabel
					key="SuccessRate"
					Text={`Success ${pctStr}`}
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.compute}
					BackgroundTransparency={1}
					Size={new UDim2(0, 110, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					LayoutOrder={1}
				/>
				<textlabel
					key="Reward"
					Text={rewardStr}
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.data}
					BackgroundTransparency={1}
					Size={new UDim2(0, 140, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					LayoutOrder={2}
				/>
				<textlabel
					key="EnergyCost"
					Text={`⚡ −${op.energyCost}`}
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.energy}
					BackgroundTransparency={1}
					Size={new UDim2(0, 70, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					LayoutOrder={3}
				/>
			</frame>

			{/* Dispatch button */}
			<frame
				key="BtnWrap"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 36)}
				LayoutOrder={5}
			>
				<Button
					label={canDispatch ? "▶  Dispatch" : `Need ${op.energyCost} ⚡`}
					onClick={onDispatch}
					variant="success"
					disabled={!canDispatch}
					height={36}
				/>
			</frame>
		</Card>
	);
}

// ------- main screen ----------------------------------------------------
export default function ScreenOperations(): React.Element {
	const gs = useGameState();
	const energyPct = math.clamp(gs.energy / ENERGY_CAP, 0, 1);

	const [ops] = React.useState<OpEntry[]>(() => {
		const [ok, result] = pcall(opList);
		return (ok && typeIs(result, "table") ? result : []) as OpEntry[];
	});

	function handleRecharge() {
		act("recharge");
	}

	function handleDispatch(op: OpEntry) {
		act("dispatch", { op: op.key });
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

			{/* ── ENERGY HERO ─────────────────────────────────────────── */}
			<Card height={164} layoutOrder={1} bgColor={Color3.fromRGB(22, 17, 5)}>
				<uipadding
					PaddingLeft={new UDim(0, 20)}
					PaddingRight={new UDim(0, 20)}
					PaddingTop={new UDim(0, 18)}
					PaddingBottom={new UDim(0, 18)}
				/>
				<uilistlayout
					FillDirection={Enum.FillDirection.Vertical}
					Padding={new UDim(0, 10)}
					SortOrder={Enum.SortOrder.LayoutOrder}
				/>

				<textlabel
					key="EnergyLabel"
					Text="POWER RESERVE"
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.textMuted}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 14)}
					TextXAlignment={Enum.TextXAlignment.Left}
					LayoutOrder={1}
				/>

				<textlabel
					key="EnergyValue"
					Text={`${math.floor(gs.energy)}  /  ${ENERGY_CAP}`}
					Font={Font.bold}
					TextSize={34}
					TextColor3={C.energy}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 40)}
					TextXAlignment={Enum.TextXAlignment.Left}
					LayoutOrder={2}
				/>

				<frame
					key="BarWrap"
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 8)}
					LayoutOrder={3}
				>
					<ProgressBar progress={energyPct} color={C.energy} height={8} glow={true} />
				</frame>

				<frame
					key="RechargeBtnWrap"
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 38)}
					LayoutOrder={4}
				>
					<Button
						label="↺  Recharge Energy"
						onClick={handleRecharge}
						variant="amber"
						height={38}
					/>
				</frame>
			</Card>

			{/* ── SECTION LABEL ───────────────────────────────────────── */}
			<textlabel
				key="MissionsLabel"
				Text="AVAILABLE MISSIONS"
				Font={Font.mono}
				TextSize={Size.caption}
				TextColor3={C.textMuted}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 16)}
				TextXAlignment={Enum.TextXAlignment.Left}
				LayoutOrder={2}
			/>

			{/* ── MISSION CARDS ───────────────────────────────────────── */}
			{ops.size() === 0 ? (
				<Card height={80} layoutOrder={3}>
					<textlabel
						Text="No operations configured"
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textMuted}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Center}
						TextYAlignment={Enum.TextYAlignment.Center}
					/>
				</Card>
			) : (
				ops.map((op, i) => (
					<MissionCard
						key={op.key}
						op={op}
						index={i + 1}
						energy={gs.energy}
						onDispatch={() => handleDispatch(op)}
					/>
				))
			)}
		</scrollingframe>
	);
}

