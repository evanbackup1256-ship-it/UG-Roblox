// screens/ScreenSingularity.tsx — Quantum Relaunch & Prestige Mechanics

import React from "@rbxts/react";
import { C, Font, Size, R } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { useGameState } from "../hooks";
import { act, fmt } from "../store";

export default function ScreenSingularity(): React.Element {
	const gs = useGameState();
	const [confirmState, setConfirmState] = React.useState(false);

	const currentTokens = gs.prestigeTokens ?? 0;
	// Calculate projected tokens based on total compute earned
	const totalCompute = gs.totalEarned ?? gs.compute ?? 0;
	const potentialTokens = math.max(0, math.floor(math.sqrt(totalCompute / 1000000)) - currentTokens);
	const bonusPct = (currentTokens + potentialTokens) * 10;

	const handlePrestigeClick = () => {
		if (!confirmState) {
			setConfirmState(true);
			task.delay(4, () => {
				setConfirmState(false);
			});
		} else {
			act("prestige");
			setConfirmState(false);
		}
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

			{/* Prestige Warning Danger Card */}
			<Card height={240} bgColor={Color3.fromRGB(32, 14, 20)} layoutOrder={1}>
				<uipadding
					PaddingLeft={new UDim(0, 24)}
					PaddingRight={new UDim(0, 24)}
					PaddingTop={new UDim(0, 20)}
					PaddingBottom={new UDim(0, 20)}
				/>
				<frame Size={new UDim2(1, 0, 1, 0)} BackgroundTransparency={1}>
					<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 8)} />
					<frame Size={new UDim2(1, 0, 0, 24)} BackgroundTransparency={1}>
						<textlabel
							Text="QUANTUM SINGULARITY RELAUNCH"
							Font={Font.bold}
							TextSize={Size.title}
							TextColor3={C.danger}
							BackgroundTransparency={1}
							Size={new UDim2(0.7, 0, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
						<Badge label="HIGH VOLTAGE" style="danger" pill={true} />
					</frame>
					<textlabel
						Text="Initiating a singularity collapses current server infrastructure and raw compute reserves into ultra-dense Quantum Tokens."
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 40)}
						TextWrapped={true}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<textlabel
						Text="⚠️ WARNING: All server hardware and current compute will be dissolved. Research and achievements remain permanent."
						Font={Font.mono}
						TextSize={Size.caption}
						TextColor3={C.warning}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 22)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>

					{/* Action Trigger Button */}
					<frame Size={new UDim2(1, 0, 0, 50)} BackgroundTransparency={1}>
						<Button
							label={confirmState ? "⚠️ CONFIRM SINGULARITY — IRREVERSIBLE ACTION" : `Initiate Collapse (+${fmt(potentialTokens)} Quantum Tokens)`}
							variant="danger"
							height={46}
							disabled={potentialTokens <= 0 && !confirmState}
							onClick={handlePrestigeClick}
						/>
					</frame>
				</frame>
			</Card>

			{/* Telemetry Stats Card */}
			<frame Size={new UDim2(1, 0, 0, 130)} BackgroundTransparency={1} LayoutOrder={2}>
				<uigridlayout
					CellSize={new UDim2(0.485, 0, 0, 120)}
					CellPadding={new UDim2(0.03, 0, 0, 14)}
					SortOrder={Enum.SortOrder.LayoutOrder}
				/>
				<Card height={120}>
					<uipadding PaddingLeft={new UDim(0, 18)} PaddingRight={new UDim(0, 18)} PaddingTop={new UDim(0, 16)} />
					<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 4)} />
					<textlabel Text="CURRENT QUANTUM RESERVE" Font={Font.body} TextSize={Size.caption} TextColor3={C.textSecondary} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 16)} />
					<textlabel Text={`${fmt(currentTokens)} Tokens`} Font={Font.display} TextSize={Size.hero} TextColor3={C.reputation} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 32)} />
					<textlabel Text={`Current Global Bonus: +${currentTokens * 10}%`} Font={Font.mono} TextSize={Size.micro} TextColor3={C.compute} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 16)} />
				</Card>
				<Card height={120}>
					<uipadding PaddingLeft={new UDim(0, 18)} PaddingRight={new UDim(0, 18)} PaddingTop={new UDim(0, 16)} />
					<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 4)} />
					<textlabel Text="PROJECTED POST-COLLAPSE BONUS" Font={Font.body} TextSize={Size.caption} TextColor3={C.textSecondary} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 16)} />
					<textlabel Text={`+${bonusPct}% Multiplier`} Font={Font.display} TextSize={Size.hero} TextColor3={C.gold} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 32)} />
					<textlabel Text={`Yield Acceleration Factor: ×${string.format("%.1f", 1 + bonusPct / 100)}`} Font={Font.mono} TextSize={Size.micro} TextColor3={C.gold} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 16)} />
				</Card>
			</frame>
		</scrollingframe>
	);
}

