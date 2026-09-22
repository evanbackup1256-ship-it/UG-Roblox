// screens/ScreenContracts.tsx — Work orders / contracts screen

import React from "@rbxts/react";
import { C, R, Font, Size } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { ProgressBar } from "../ui/ProgressBar";
import { useGameState } from "../hooks";
import { act, fmt } from "../store";

// ---------------------------------------------------------------------------
// Data definitions
// ---------------------------------------------------------------------------

type ContractStatus = "available" | "active" | "completed";

interface ContractReward {
	compute?: number;
	data?: number;
	energy?: number;
	prestigeTokens?: number;
}

interface ContractDef {
	id: string;
	client: string;
	description: string;
	requirement: string;
	targetCompute: number;   // compute milestone to complete
	reward: ContractReward;
}

const PLACEHOLDER_CONTRACTS: ContractDef[] = [
	{
		id: "startup_mvp",
		client: "NovaSpark Labs",
		description: "Bootstrap MVP cloud infrastructure for our seed-stage startup.",
		requirement: "Earn 10K compute",
		targetCompute: 10_000,
		reward: { data: 500, energy: 50 },
	},
	{
		id: "media_render",
		client: "Prismatic Studios",
		description: "Render 4K HDR visual effects pipeline at peak throughput.",
		requirement: "Earn 250K compute",
		targetCompute: 250_000,
		reward: { compute: 20_000, data: 2000 },
	},
	{
		id: "fintech_compliance",
		client: "Axiom Finance",
		description: "Host encrypted compliance ledger with 99.99% uptime SLA.",
		requirement: "Earn 1M compute",
		targetCompute: 1_000_000,
		reward: { prestigeTokens: 1, compute: 100_000 },
	},
	{
		id: "ai_training",
		client: "Cognition AI",
		description: "Distribute LLM training jobs across our quantum cluster.",
		requirement: "Earn 10M compute",
		targetCompute: 10_000_000,
		reward: { prestigeTokens: 3, data: 50_000 },
	},
	{
		id: "govt_archive",
		client: "Federal Bureau of Data",
		description: "Archive classified datasets into geographically redundant vaults.",
		requirement: "Earn 100M compute",
		targetCompute: 100_000_000,
		reward: { prestigeTokens: 10, energy: 10_000 },
	},
	{
		id: "singularity_bid",
		client: "Ω Collective",
		description: "Power the final convergence event. All or nothing.",
		requirement: "Earn 1B compute",
		targetCompute: 1_000_000_000,
		reward: { prestigeTokens: 50 },
	},
];

function getContractStatus(contract: ContractDef, totalEarned: number, claimed: Map<string, boolean>): ContractStatus {
	if (claimed.get(contract.id) === true) return "completed";
	if (totalEarned >= contract.targetCompute) return "active"; // ready to claim
	if (totalEarned >= contract.targetCompute * 0.01) return "active"; // started
	return "available";
}

function getProgress(contract: ContractDef, totalEarned: number): number {
	return math.clamp(totalEarned / contract.targetCompute, 0, 1);
}

// ---------------------------------------------------------------------------
// Sub-component: ContractCard
// ---------------------------------------------------------------------------

interface ContractCardProps {
	contract: ContractDef;
	status: ContractStatus;
	progress: number;
	layoutOrder: number;
}

function rewardText(r: ContractReward): string {
	const parts: string[] = [];
	if (r.compute)        parts.push(`⚡ ${fmt(r.compute)} compute`);
	if (r.data)           parts.push(`◈ ${fmt(r.data)} data`);
	if (r.energy)         parts.push(`⚙ ${fmt(r.energy)} energy`);
	if (r.prestigeTokens) parts.push(`✦ ${tostring(r.prestigeTokens)} prestige`);
	return parts.join("  ·  ");
}

function ContractCard({ contract, status, progress, layoutOrder }: ContractCardProps) {
	const isCompleted = status === "completed";
	const isActive    = status === "active";
	const canClaim    = progress >= 1 && !isCompleted;

	const borderColor = isCompleted
		? C.compute
		: isActive
			? C.accent
			: C.hairline;
	const borderAlpha = isCompleted ? 0.35 : isActive ? 0.45 : 0.72;

	return (
		<frame
			key={contract.id}
			BackgroundColor3={isCompleted ? Color3.fromRGB(14, 24, 18) : C.card}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 0, isActive && !isCompleted ? 172 : 148)}
			LayoutOrder={layoutOrder}
		>
			<uicorner CornerRadius={new UDim(0, R.card)} />
			<uistroke Color={borderColor} Thickness={1} Transparency={borderAlpha} />

			<uipadding
				PaddingLeft={new UDim(0, 16)}
				PaddingRight={new UDim(0, 16)}
				PaddingTop={new UDim(0, 14)}
				PaddingBottom={new UDim(0, 14)}
			/>

			{/* Client name row */}
			<frame key="TopRow" BackgroundTransparency={1} Size={new UDim2(1, -32, 0, 24)} Position={new UDim2(0, 16, 0, 14)} ZIndex={3}>
				<textlabel
					key="Client"
					Text={contract.client.upper()}
					Font={Font.mono}
					TextSize={Size.micro}
					TextColor3={isCompleted ? C.compute : C.textMuted}
					BackgroundTransparency={1}
					Size={new UDim2(1, -90, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					ZIndex={3}
				/>
				{isCompleted && (
					<frame
						key="DoneBadge"
						BackgroundColor3={Color3.fromRGB(14, 28, 20)}
						BorderSizePixel={0}
						Size={new UDim2(0, 82, 0, 20)}
						Position={new UDim2(1, -82, 0, 2)}
						ZIndex={3}
					>
						<uicorner CornerRadius={new UDim(0, R.badge)} />
						<uistroke Color={C.compute} Thickness={1} Transparency={0.4} />
						<textlabel
							Text="✓  FULFILLED"
							Font={Font.mono}
							TextSize={Size.micro}
							TextColor3={C.compute}
							BackgroundTransparency={1}
							Size={new UDim2(1, 0, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Center}
							ZIndex={4}
						/>
					</frame>
				)}
				{!isCompleted && isActive && (
					<frame
						key="ActiveBadge"
						BackgroundColor3={Color3.fromRGB(14, 22, 40)}
						BorderSizePixel={0}
						Size={new UDim2(0, 62, 0, 20)}
						Position={new UDim2(1, -62, 0, 2)}
						ZIndex={3}
					>
						<uicorner CornerRadius={new UDim(0, R.badge)} />
						<uistroke Color={C.accent} Thickness={1} Transparency={0.4} />
						<textlabel
							Text="ACTIVE"
							Font={Font.mono}
							TextSize={Size.micro}
							TextColor3={C.accent}
							BackgroundTransparency={1}
							Size={new UDim2(1, 0, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Center}
							ZIndex={4}
						/>
					</frame>
				)}
			</frame>

			{/* Contract description */}
			<textlabel
				key="Desc"
				Text={contract.description}
				Font={Font.body}
				TextSize={Size.body}
				TextColor3={isCompleted ? C.textMuted : C.textPrimary}
				BackgroundTransparency={1}
				Size={new UDim2(1, -32, 0, 36)}
				Position={new UDim2(0, 16, 0, 44)}
				TextXAlignment={Enum.TextXAlignment.Left}
				TextWrapped={true}
				ZIndex={3}
			/>

			{/* Requirement */}
			<textlabel
				key="Req"
				Text={`📋  ${contract.requirement}`}
				Font={Font.mono}
				TextSize={Size.caption}
				TextColor3={C.textSecondary}
				BackgroundTransparency={1}
				Size={new UDim2(1, -32, 0, 16)}
				Position={new UDim2(0, 16, 0, 86)}
				TextXAlignment={Enum.TextXAlignment.Left}
				ZIndex={3}
			/>

			{/* Progress bar (active only) */}
			{isActive && !isCompleted && (
				<frame
					key="ProgressWrap"
					BackgroundTransparency={1}
					Size={new UDim2(1, -32, 0, 10)}
					Position={new UDim2(0, 16, 0, 108)}
					ZIndex={3}
				>
					<ProgressBar progress={progress} color={progress >= 1 ? C.compute : C.accent} height={5} glow={progress >= 1} />
					<textlabel
						key="Pct"
						Text={`${tostring(math.floor(progress * 100))}%`}
						Font={Font.mono}
						TextSize={Size.micro}
						TextColor3={C.textMuted}
						BackgroundTransparency={1}
						Size={new UDim2(0, 36, 0, 10)}
						Position={new UDim2(1, -36, 0, 0)}
						TextXAlignment={Enum.TextXAlignment.Right}
						ZIndex={4}
					/>
				</frame>
			)}

			{/* Footer: reward + button */}
			<frame
				key="Footer"
				BackgroundTransparency={1}
				Size={new UDim2(1, -32, 0, 32)}
				Position={new UDim2(0, 16, 0, isActive && !isCompleted ? 128 : 108)}
				ZIndex={3}
			>
				<textlabel
					key="Reward"
					Text={rewardText(contract.reward)}
					Font={Font.mono}
					TextSize={Size.micro}
					TextColor3={C.data}
					BackgroundTransparency={1}
					Size={new UDim2(1, -110, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextTruncate={Enum.TextTruncate.AtEnd}
					ZIndex={3}
				/>

				<frame key="BtnWrap" BackgroundTransparency={1} Size={new UDim2(0, 100, 0, 30)} Position={new UDim2(1, -100, 0, 1)} ZIndex={3}>
					{isCompleted ? (
						<Button label="Completed" onClick={() => {}} variant="secondary" height={30} disabled={true} />
					) : canClaim ? (
						<Button
							label="Complete ✓"
							onClick={() => act("claimContract", { id: contract.id })}
							variant="success"
							height={30}
						/>
					) : (
						<Button
							label={isActive ? "In Progress" : "Accept"}
							onClick={() => act("acceptContract", { id: contract.id })}
							variant={isActive ? "secondary" : "primary"}
							height={30}
							disabled={isActive}
						/>
					)}
				</frame>
			</frame>
		</frame>
	);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

export default function ScreenContracts(): React.Element {
	const state = useGameState();
	const claimed = state.claimed ?? new Map<string, boolean>();
	const totalEarned = state.totalEarned ?? 0;

	const sorted = [...PLACEHOLDER_CONTRACTS].sort(
		(a, b) => a.targetCompute < b.targetCompute,
	);

	return (
		<scrollingframe
			BackgroundTransparency={1}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 1, 0)}
			CanvasSize={new UDim2(0, 0, 0, 0)}
			AutomaticCanvasSize={Enum.AutomaticSize.Y}
			ScrollBarThickness={3}
			ScrollBarImageColor3={C.accent}
			ScrollBarImageTransparency={0.5}
		>
			<uilistlayout
				FillDirection={Enum.FillDirection.Vertical}
				Padding={new UDim(0, 10)}
				SortOrder={Enum.SortOrder.LayoutOrder}
				HorizontalAlignment={Enum.HorizontalAlignment.Center}
			/>
			<uipadding
				PaddingLeft={new UDim(0, 16)}
				PaddingRight={new UDim(0, 16)}
				PaddingTop={new UDim(0, 16)}
				PaddingBottom={new UDim(0, 24)}
			/>

			{/* Header */}
			<frame key="Header" BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 56)} LayoutOrder={0}>
				<textlabel
					Text="CONTRACTS"
					Font={Font.bold}
					TextSize={Size.hero}
					TextColor3={C.textPrimary}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 28)}
					TextXAlignment={Enum.TextXAlignment.Left}
				/>
				<textlabel
					Text="Accept work orders from clients. Complete milestones to earn bonus resources."
					Font={Font.body}
					TextSize={Size.caption}
					TextColor3={C.textSecondary}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 18)}
					Position={new UDim2(0, 0, 0, 32)}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextWrapped={true}
				/>
			</frame>

			{/* Stats row */}
			<frame
				key="StatsRow"
				BackgroundColor3={C.recessed}
				BorderSizePixel={0}
				Size={new UDim2(1, 0, 0, 48)}
				LayoutOrder={1}
			>
				<uicorner CornerRadius={new UDim(0, R.control)} />
				<uistroke Color={C.hairline} Thickness={1} Transparency={0.65} />
				<uilistlayout
					FillDirection={Enum.FillDirection.Horizontal}
					VerticalAlignment={Enum.VerticalAlignment.Center}
					Padding={new UDim(0, 0)}
					SortOrder={Enum.SortOrder.LayoutOrder}
				/>

				{/* Total compute stat */}
				<frame key="TotalStat" BackgroundTransparency={1} Size={new UDim2(0.5, 0, 1, 0)} LayoutOrder={1}>
					<textlabel
						Text="TOTAL COMPUTE EARNED"
						Font={Font.mono}
						TextSize={Size.micro}
						TextColor3={C.textMuted}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 14)}
						Position={new UDim2(0, 16, 0, 8)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<textlabel
						Text={fmt(totalEarned)}
						Font={Font.bold}
						TextSize={Size.section}
						TextColor3={C.compute}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 20)}
						Position={new UDim2(0, 16, 0, 24)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
				</frame>

				{/* Completed count */}
				<frame key="CompStat" BackgroundTransparency={1} Size={new UDim2(0.5, 0, 1, 0)} LayoutOrder={2}>
					<textlabel
						Text="CONTRACTS FULFILLED"
						Font={Font.mono}
						TextSize={Size.micro}
						TextColor3={C.textMuted}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 14)}
						Position={new UDim2(0, 16, 0, 8)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<textlabel
						Text={tostring(
							PLACEHOLDER_CONTRACTS.reduce((n, c) => n + (claimed.get(c.id) ? 1 : 0), 0),
						)}
						Font={Font.bold}
						TextSize={Size.section}
						TextColor3={C.accent}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 20)}
						Position={new UDim2(0, 16, 0, 24)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
				</frame>
			</frame>

			{sorted.map((contract, i) => {
				const status   = getContractStatus(contract, totalEarned, claimed);
				const progress = getProgress(contract, totalEarned);
				return (
					<ContractCard
						key={contract.id}
						contract={contract}
						status={status}
						progress={progress}
						layoutOrder={i + 2}
					/>
				);
			})}
		</scrollingframe>
	);
}

