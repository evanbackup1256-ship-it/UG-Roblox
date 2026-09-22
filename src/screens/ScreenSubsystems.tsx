// screens/ScreenSubsystems.tsx — Module / subsystem upgrade grid

import React from "@rbxts/react";
import { C, R, Font, Size } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { useGameState } from "../hooks";
import { act, fmt } from "../store";

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

interface ModuleDef {
	id: string;
	name: string;
	description: string;
	effectLabel: string; // e.g. "+10% compute rate"
	baseCost: number;
	maxLevel: number;
	unlocksAt: number; // prestige tokens required to unlock
}

const PLACEHOLDER_MODULES: ModuleDef[] = [
	{
		id: "overclock",
		name: "Overclocking Suite",
		description: "Push hardware beyond rated limits.",
		effectLabel: "+15% compute rate per level",
		baseCost: 500,
		maxLevel: 10,
		unlocksAt: 0,
	},
	{
		id: "cooling",
		name: "Cryo Cooling",
		description: "Advanced liquid nitrogen cooling loops.",
		effectLabel: "+8% energy efficiency per level",
		baseCost: 750,
		maxLevel: 10,
		unlocksAt: 0,
	},
	{
		id: "redundancy",
		name: "Redundancy Array",
		description: "Fault-tolerant multi-path data pipelines.",
		effectLabel: "+12% data throughput per level",
		baseCost: 1200,
		maxLevel: 8,
		unlocksAt: 1,
	},
	{
		id: "ai_scheduler",
		name: "AI Scheduler",
		description: "Neural job orchestration reduces idle cycles.",
		effectLabel: "+20% job XP per level",
		baseCost: 2500,
		maxLevel: 6,
		unlocksAt: 2,
	},
	{
		id: "quantum_cache",
		name: "Quantum Cache",
		description: "Quantum-coherent L4 cache for ultra-low latency.",
		effectLabel: "+25% tick speed per level",
		baseCost: 8000,
		maxLevel: 5,
		unlocksAt: 3,
	},
	{
		id: "singularity_core",
		name: "Singularity Core",
		description: "Experimental self-optimising compute fabric.",
		effectLabel: "+40% all resources per level",
		baseCost: 50000,
		maxLevel: 3,
		unlocksAt: 5,
	},
];

// Try to pull from Config; fall back to placeholders
function getModules(): ModuleDef[] {
	try {
		const cfg = (require(game.GetService("ReplicatedStorage").WaitForChild("DeckGame").WaitForChild("Config") as ModuleScript) as { Subsystems?: ModuleDef[] });
		if (cfg.Subsystems && cfg.Subsystems.size() > 0) return cfg.Subsystems;
	} catch (_) {}
	return PLACEHOLDER_MODULES;
}

const MODULES = getModules();

// ---------------------------------------------------------------------------
// Sub-component: ModuleCard
// ---------------------------------------------------------------------------

interface ModuleCardProps {
	mod: ModuleDef;
	level: number;
	prestigeTokens: number;
	compute: number;
	layoutOrder: number;
}

function ModuleCard({ mod, level, prestigeTokens, compute, layoutOrder }: ModuleCardProps) {
	const locked = prestigeTokens < mod.unlocksAt;
	const maxed  = level >= mod.maxLevel;
	const cost   = math.floor(mod.baseCost * math.pow(1.65, level));
	const canAfford = compute >= cost;

	const cardBg  = locked ? Color3.fromRGB(18, 19, 24) : C.card;
	const alpha   = locked ? 0.55 : 0;

	return (
		<frame
			key={mod.id}
			BackgroundColor3={cardBg}
			BackgroundTransparency={0}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 0, 148)}
			LayoutOrder={layoutOrder}
		>
			<uicorner CornerRadius={new UDim(0, R.card)} />
			<uistroke
				Color={locked ? C.hairlineSub : C.hairline}
				Thickness={1}
				Transparency={locked ? 0.5 : 0.72}
			/>

			{/* Dim overlay for locked */}
			{locked && (
				<frame
					key="LockOverlay"
					BackgroundColor3={Color3.fromRGB(0, 0, 0)}
					BackgroundTransparency={0.45}
					BorderSizePixel={0}
					Size={new UDim2(1, 0, 1, 0)}
					ZIndex={6}
				>
					<uicorner CornerRadius={new UDim(0, R.card)} />
					<textlabel
						Text="🔒  LOCKED"
						Font={Font.bold}
						TextSize={Size.body}
						TextColor3={C.textMuted}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Center}
						TextYAlignment={Enum.TextYAlignment.Center}
						ZIndex={7}
					/>
				</frame>
			)}

			<uipadding
				PaddingLeft={new UDim(0, 16)}
				PaddingRight={new UDim(0, 16)}
				PaddingTop={new UDim(0, 14)}
				PaddingBottom={new UDim(0, 14)}
			/>

			{/* Header row: name + level badge */}
			<frame
				key="Header"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 26)}
				Position={new UDim2(0, 16, 0, 14)}
				ZIndex={3}
			>
				<textlabel
					key="Name"
					Text={mod.name}
					Font={Font.bold}
					TextSize={Size.section}
					TextColor3={locked ? C.textMuted : C.textPrimary}
					BackgroundTransparency={1}
					Size={new UDim2(1, -80, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextTruncate={Enum.TextTruncate.AtEnd}
					ZIndex={3}
				/>
				<frame
					key="LvlBadge"
					BackgroundColor3={maxed ? Color3.fromRGB(36, 18, 56) : Color3.fromRGB(18, 30, 48)}
					BorderSizePixel={0}
					Size={new UDim2(0, 68, 0, 22)}
					Position={new UDim2(1, -68, 0, 2)}
					ZIndex={3}
				>
					<uicorner CornerRadius={new UDim(0, R.badge)} />
					<uistroke
						Color={maxed ? C.reputation : C.accent}
						Thickness={1}
						Transparency={0.45}
					/>
					<textlabel
						Text={maxed ? "MAX" : `LVL ${tostring(level)}`}
						Font={Font.mono}
						TextSize={Size.micro}
						TextColor3={maxed ? C.reputation : C.accent}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Center}
						ZIndex={4}
					/>
				</frame>
			</frame>

			{/* Description */}
			<textlabel
				key="Desc"
				Text={mod.description}
				Font={Font.body}
				TextSize={Size.caption}
				TextColor3={locked ? C.textMuted : C.textSecondary}
				BackgroundTransparency={1}
				Size={new UDim2(1, -32, 0, 18)}
				Position={new UDim2(0, 16, 0, 46)}
				TextXAlignment={Enum.TextXAlignment.Left}
				TextWrapped={true}
				ZIndex={3}
			/>

			{/* Effect chip */}
			<frame
				key="Effect"
				BackgroundColor3={Color3.fromRGB(14, 28, 20)}
				BorderSizePixel={0}
				Size={new UDim2(1, -32, 0, 20)}
				Position={new UDim2(0, 16, 0, 70)}
				ZIndex={3}
			>
				<uicorner CornerRadius={new UDim(0, R.micro)} />
				<uistroke Color={C.compute} Thickness={1} Transparency={0.65} />
				<textlabel
					Text={mod.effectLabel}
					Font={Font.mono}
					TextSize={Size.micro}
					TextColor3={C.compute}
					BackgroundTransparency={1}
					Size={new UDim2(1, -12, 1, 0)}
					Position={new UDim2(0, 6, 0, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					ZIndex={4}
				/>
			</frame>

			{/* Footer: cost + button */}
			<frame
				key="Footer"
				BackgroundTransparency={1}
				Size={new UDim2(1, -32, 0, 36)}
				Position={new UDim2(0, 16, 0, 98)}
				ZIndex={3}
			>
				<uilistlayout
					FillDirection={Enum.FillDirection.Horizontal}
					VerticalAlignment={Enum.VerticalAlignment.Center}
					HorizontalAlignment={Enum.HorizontalAlignment.Left}
					Padding={new UDim(0, 10)}
					SortOrder={Enum.SortOrder.LayoutOrder}
				/>

				{/* Cost */}
				<frame
					key="CostChip"
					BackgroundColor3={Color3.fromRGB(16, 28, 20)}
					BorderSizePixel={0}
					Size={new UDim2(0, 100, 0, 28)}
					LayoutOrder={1}
					ZIndex={3}
				>
					<uicorner CornerRadius={new UDim(0, R.control)} />
					<uistroke
						Color={canAfford && !locked ? C.compute : C.textMuted}
						Thickness={1}
						Transparency={0.5}
					/>
					<textlabel
						Text={maxed ? "MAXED" : `⚡ ${fmt(cost)}`}
						Font={Font.mono}
						TextSize={Size.caption}
						TextColor3={canAfford && !locked && !maxed ? C.compute : C.textMuted}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Center}
						ZIndex={4}
					/>
				</frame>

				{/* Upgrade button */}
				<frame key="BtnWrap" BackgroundTransparency={1} Size={new UDim2(1, -110, 0, 36)} LayoutOrder={2} ZIndex={3}>
					<Button
						label={maxed ? "MAXED" : locked ? "LOCKED" : "Upgrade"}
						onClick={() => {
							if (locked || maxed || !canAfford) return;
							act("upgradeSubsystem", { id: mod.id });
						}}
						variant={maxed ? "secondary" : locked ? "secondary" : canAfford ? "success" : "secondary"}
						height={34}
						disabled={locked || maxed || !canAfford}
					/>
				</frame>
			</frame>
		</frame>
	);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

export default function ScreenSubsystems(): React.Element {
	const state = useGameState();
	const research = state.research ?? new Map<string, number>();

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

			{/* Section header */}
			<frame key="Header" BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 48)} LayoutOrder={0}>
				<textlabel
					Text="SUBSYSTEMS"
					Font={Font.bold}
					TextSize={Size.hero}
					TextColor3={C.textPrimary}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 28)}
					TextXAlignment={Enum.TextXAlignment.Left}
				/>
				<textlabel
					Text="Upgrade infrastructure modules to amplify all resource generation."
					Font={Font.body}
					TextSize={Size.caption}
					TextColor3={C.textSecondary}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 16)}
					Position={new UDim2(0, 0, 0, 30)}
					TextXAlignment={Enum.TextXAlignment.Left}
				/>
			</frame>

			{MODULES.map((mod, i) => {
				const level = (research.get(mod.id) as number | undefined) ?? 0;
				return (
					<ModuleCard
						key={mod.id}
						mod={mod}
						level={level}
						prestigeTokens={state.prestigeTokens}
						compute={state.compute}
						layoutOrder={i + 1}
					/>
				);
			})}
		</scrollingframe>
	);
}

