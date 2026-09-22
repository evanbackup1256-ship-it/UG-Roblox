// screens/ScreenResearch.tsx — Research and Technology Upgrades

import React from "@rbxts/react";
import { C, Font, Size, R } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { useGameState } from "../hooks";
import { act, fmt } from "../store";

const Config = require(game.GetService("ReplicatedStorage")
	.WaitForChild("DeckGame")
	.WaitForChild("Config") as ModuleScript) as { Research?: ResearchItem[] };

interface ResearchItem {
	key: string;
	name: string;
	description: string;
	cost: number;
	multiplier: number;
}

const DEFAULT_RESEARCH: ResearchItem[] = [
	{ key: "parallel_cores", name: "Parallel Compute Architecture", description: "Expands instruction pipelines, boosting base compute yield by +25%.", cost: 500, multiplier: 1.25 },
	{ key: "subzero_cooling", name: "Cryogenic Cooling Loop", description: "Prevents thermal throttling across all server hardware clusters.", cost: 2500, multiplier: 1.50 },
	{ key: "quantum_bus", name: "Quantum Interconnect Bus", description: "Ultra-low latency data transmission channels between facilities.", cost: 12000, multiplier: 2.00 },
	{ key: "neural_cache", name: "Neural Predictive Caching", description: "Anticipates workload demands with AI-driven branch prediction.", cost: 50000, multiplier: 2.50 },
	{ key: "hyper_optical", name: "Hyper-Optical Transceivers", description: "Replaces copper bus with multi-wavelength laser packet switching.", cost: 200000, multiplier: 3.00 },
	{ key: "dark_silicon", name: "Dark Silicon Activation", description: "Powers dormant die sectors dynamically during burst workloads.", cost: 1000000, multiplier: 4.00 },
];

export default function ScreenResearch(): React.Element {
	const gs = useGameState();
	const researchMap = gs.research ?? new Map<string, number>();

	const items: ResearchItem[] = Config.Research ? (Config.Research as ResearchItem[]) : DEFAULT_RESEARCH;

	return (
		<scrollingframe
			Size={new UDim2(1, 0, 1, 0)}
			BackgroundTransparency={1}
			BorderSizePixel={0}
			ScrollBarThickness={4}
			ScrollBarImageColor3={C.hairline}
			CanvasSize={new UDim2(0, 0, 0, 850)}
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

			{/* Header info card */}
			<Card height={100} layoutOrder={1}>
				<uipadding
					PaddingLeft={new UDim(0, 20)}
					PaddingRight={new UDim(0, 20)}
					PaddingTop={new UDim(0, 16)}
					PaddingBottom={new UDim(0, 16)}
				/>
				<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 6)} />
				<frame Size={new UDim2(1, 0, 0, 24)} BackgroundTransparency={1}>
					<textlabel
						Text="RESEARCH & DEVELOPMENT"
						Font={Font.bold}
						TextSize={Size.title}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(0.7, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<Badge label="INNOVATION" style="accent" pill={true} />
				</frame>
				<textlabel
					Text="Unlock high-order hardware enhancements to compound global compute yield."
					Font={Font.body}
					TextSize={Size.body}
					TextColor3={C.textSecondary}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 20)}
					TextXAlignment={Enum.TextXAlignment.Left}
				/>
			</Card>

			{/* Research nodes list */}
			{items.map((item, idx) => {
				const currentLevel = researchMap.get(item.key) ?? 0;
				const cost = math.floor(item.cost * math.pow(1.5, currentLevel));
				const canAfford = gs.compute >= cost;

				return (
					<Card key={item.key} height={120} layoutOrder={idx + 2}>
						<uipadding
							PaddingLeft={new UDim(0, 20)}
							PaddingRight={new UDim(0, 20)}
							PaddingTop={new UDim(0, 16)}
							PaddingBottom={new UDim(0, 16)}
						/>
						<frame Size={new UDim2(1, -150, 1, 0)} BackgroundTransparency={1}>
							<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 4)} />
							<frame Size={new UDim2(1, 0, 0, 22)} BackgroundTransparency={1}>
								<textlabel
									Text={item.name}
									Font={Font.bold}
									TextSize={Size.section}
									TextColor3={C.textPrimary}
									BackgroundTransparency={1}
									Size={new UDim2(0.7, 0, 1, 0)}
									TextXAlignment={Enum.TextXAlignment.Left}
								/>
								<Badge label={`MK ${currentLevel + 1}`} style={currentLevel > 0 ? "compute" : "default"} />
							</frame>
							<textlabel
								Text={item.description}
								Font={Font.body}
								TextSize={Size.caption}
								TextColor3={C.textSecondary}
								BackgroundTransparency={1}
								Size={new UDim2(1, 0, 0, 32)}
								TextWrapped={true}
								TextXAlignment={Enum.TextXAlignment.Left}
							/>
							<textlabel
								Text={`Multiplier: ×${string.format("%.2f", item.multiplier * (currentLevel + 1))}`}
								Font={Font.mono}
								TextSize={Size.micro}
								TextColor3={C.compute}
								BackgroundTransparency={1}
								Size={new UDim2(1, 0, 0, 16)}
								TextXAlignment={Enum.TextXAlignment.Left}
							/>
						</frame>

						<frame
							Size={new UDim2(0, 140, 1, 0)}
							Position={new UDim2(1, -140, 0, 0)}
							BackgroundTransparency={1}
						>
							<uilistlayout
								FillDirection={Enum.FillDirection.Vertical}
								VerticalAlignment={Enum.VerticalAlignment.Center}
								HorizontalAlignment={Enum.HorizontalAlignment.Right}
								Padding={new UDim(0, 8)}
							/>
							<textlabel
								Text={`${fmt(cost)} ⚡`}
								Font={Font.bold}
								TextSize={Size.body}
								TextColor3={canAfford ? C.compute : C.textMuted}
								BackgroundTransparency={1}
								Size={new UDim2(1, 0, 0, 20)}
								TextXAlignment={Enum.TextXAlignment.Right}
							/>
							<Button
								label="Upgrade"
								variant={canAfford ? "primary" : "secondary"}
								width={130}
								height={36}
								disabled={!canAfford}
								onClick={() => act("research", { key: item.key })}
							/>
						</frame>
					</Card>
				);
			})}
		</scrollingframe>
	);
}

