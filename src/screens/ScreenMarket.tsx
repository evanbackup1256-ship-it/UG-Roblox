// screens/ScreenMarket.tsx — Supply Procurement & Boost Market

import React from "@rbxts/react";
import { C, Font, Size, R } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { useGameState } from "../hooks";
import { act, fmt } from "../store";

interface MarketItem {
	id: string;
	title: string;
	subtitle: string;
	costCompute?: number;
	costData?: number;
	isPremium?: boolean;
	icon: string;
	action: string;
}

const MARKET_ITEMS: MarketItem[] = [
	{ id: "overclock_boost", title: "Cryo-Overclock Injection", subtitle: "Supercharges server clocks by +100% for 120 seconds.", costCompute: 15000, icon: "operations", action: "boost" },
	{ id: "energy_cell", title: "High-Density Energy Cell", subtitle: "Instantly recharges total fleet capacitor bank to full.", costCompute: 5000, icon: "energy", action: "recharge" },
	{ id: "data_dump", title: "Archive Decryption Key", subtitle: "Extracts +5,000 raw telemetry packets into permanent storage.", costCompute: 25000, icon: "data", action: "buyData" },
	{ id: "quantum_accelerator", title: "Temporal Accelerator", subtitle: "Advances all background mission completion clocks by 1 hour.", costData: 2000, icon: "research", action: "skipHour" },
	{ id: "vip_infrastructure", title: "Autonomous Core AI", subtitle: "Generates background compute cycles even while inactive.", isPremium: true, icon: "infrastructure", action: "buyVip" },
	{ id: "prestige_beacon", title: "Tachyon Harmonic Beacon", subtitle: "Permanently adds +0.50× to future Singularity prestige resets.", isPremium: true, icon: "rewards", action: "buyBeacon" },
];

export default function ScreenMarket(): React.Element {
	const gs = useGameState();

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

			{/* Header Hero */}
			<Card height={100} layoutOrder={1}>
				<uipadding
					PaddingLeft={new UDim(0, 20)}
					PaddingRight={new UDim(0, 20)}
					PaddingTop={new UDim(0, 16)}
					PaddingBottom={new UDim(0, 16)}
				/>
				<frame Size={new UDim2(1, 0, 1, 0)} BackgroundTransparency={1}>
					<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 4)} />
					<frame Size={new UDim2(1, 0, 0, 24)} BackgroundTransparency={1}>
						<textlabel
							Text="SUPPLY & PROCUREMENT DEPOT"
							Font={Font.bold}
							TextSize={Size.title}
							TextColor3={C.textPrimary}
							BackgroundTransparency={1}
							Size={new UDim2(0.7, 0, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
						<Badge label="MARKETPLACE" style="energy" pill={true} />
					</frame>
					<textlabel
						Text="Procure hardware bursts, thermal accelerators, and quantum expansion assets."
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textSecondary}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 20)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
				</frame>
			</Card>

			{/* Grid of Items */}
			<frame Size={new UDim2(1, 0, 0, 680)} BackgroundTransparency={1} LayoutOrder={2}>
				<uigridlayout
					CellSize={new UDim2(0.485, 0, 0, 180)}
					CellPadding={new UDim2(0.03, 0, 0, 16)}
					SortOrder={Enum.SortOrder.LayoutOrder}
				/>

				{MARKET_ITEMS.map((item, idx) => {
					let canBuy = true;
					let costDisplay = "FREE";
					if (item.costCompute) {
						canBuy = gs.compute >= item.costCompute;
						costDisplay = `${fmt(item.costCompute)} ⚡`;
					} else if (item.costData) {
						canBuy = gs.data >= item.costData;
						costDisplay = `${fmt(item.costData)} 💾`;
					} else if (item.isPremium) {
						costDisplay = "ROBUX";
					}

					return (
						<Card key={item.id} height={180} layoutOrder={idx}>
							<uipadding
								PaddingLeft={new UDim(0, 16)}
								PaddingRight={new UDim(0, 16)}
								PaddingTop={new UDim(0, 14)}
								PaddingBottom={new UDim(0, 14)}
							/>
							<frame Size={new UDim2(1, 0, 1, 0)} BackgroundTransparency={1}>
								<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 6)} />
								<frame Size={new UDim2(1, 0, 0, 24)} BackgroundTransparency={1}>
									<textlabel
										Text={item.title}
										Font={Font.bold}
										TextSize={Size.section}
										TextColor3={C.textPrimary}
										BackgroundTransparency={1}
										Size={new UDim2(0.65, 0, 1, 0)}
										TextXAlignment={Enum.TextXAlignment.Left}
										TextTruncate={Enum.TextTruncate.AtEnd}
									/>
									<Badge label={item.isPremium ? "PREMIUM" : "DEPOT"} style={item.isPremium ? "reputation" : "accent"} pill={true} />
								</frame>
								<textlabel
									Text={item.subtitle}
									Font={Font.body}
									TextSize={Size.caption}
									TextColor3={C.textSecondary}
									BackgroundTransparency={1}
									Size={new UDim2(1, 0, 0, 48)}
									TextWrapped={true}
									TextXAlignment={Enum.TextXAlignment.Left}
								/>
								<frame Size={new UDim2(1, 0, 0, 36)} BackgroundTransparency={1}>
									<uilistlayout
										FillDirection={Enum.FillDirection.Horizontal}
										VerticalAlignment={Enum.VerticalAlignment.Center}
										Padding={new UDim(0, 8)}
									/>
									<textlabel
										Text={costDisplay}
										Font={Font.mono}
										TextSize={Size.body}
										TextColor3={item.isPremium ? C.reputation : (canBuy ? C.compute : C.textMuted)}
										BackgroundTransparency={1}
										Size={new UDim2(0.5, 0, 1, 0)}
										TextXAlignment={Enum.TextXAlignment.Left}
									/>
									<Button
										label={item.isPremium ? "Get" : "Purchase"}
										variant={item.isPremium ? "amber" : (canBuy ? "primary" : "secondary")}
										width={100}
										height={34}
										disabled={!canBuy && !item.isPremium}
										onClick={() => act("shopBuy", { item: item.id })}
									/>
								</frame>
							</frame>
						</Card>
					);
				})}
			</frame>
		</scrollingframe>
	);
}

