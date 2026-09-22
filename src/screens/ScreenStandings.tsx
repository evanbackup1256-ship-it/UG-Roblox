// screens/ScreenStandings.tsx — Leaderboards and Global Fleet Standings

import React from "@rbxts/react";
import { C, Font, Size, R } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { useGameState } from "../hooks";
import { fmt } from "../store";

interface LeaderboardEntry {
	rank: number;
	userId: number;
	callsign: string;
	score: number;
}

const SAMPLE_STANDINGS: LeaderboardEntry[] = [
	{ rank: 1, userId: 1, callsign: "NexusPrime", score: 8500000000 },
	{ rank: 2, userId: 2, callsign: "ValkyrieCore", score: 6200000000 },
	{ rank: 3, userId: 3, callsign: "ApexOverclock", score: 4900000000 },
	{ rank: 4, userId: 4, callsign: "CyberFleet_01", score: 2100000000 },
	{ rank: 5, userId: 5, callsign: "ZeroDayNode", score: 1450000000 },
	{ rank: 6, userId: 6, callsign: "SolarisGrid", score: 980000000 },
	{ rank: 7, userId: 7, callsign: "HyperionCluster", score: 620000000 },
	{ rank: 8, userId: 8, callsign: "QuantumShift", score: 410000000 },
];

export default function ScreenStandings(): React.Element {
	const gs = useGameState();
	const [category, setCategory] = React.useState<"compute" | "prestige">("compute");
	const [entries, setEntries] = React.useState<LeaderboardEntry[]>(SAMPLE_STANDINGS);
	const [loading, setLoading] = React.useState(false);

	const refreshLeaderboard = () => {
		setLoading(true);
		task.delay(0.5, () => {
			setLoading(false);
		});
	};

	return (
		<scrollingframe
			Size={new UDim2(1, 0, 1, 0)}
			BackgroundTransparency={1}
			BorderSizePixel={0}
			ScrollBarThickness={4}
			ScrollBarImageColor3={C.hairline}
			CanvasSize={new UDim2(0, 0, 0, 900)}
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

			{/* Screen Header */}
			<Card height={90} layoutOrder={1}>
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
							Text="FLEET STANDINGS & TELEMETRY"
							Font={Font.bold}
							TextSize={Size.title}
							TextColor3={C.textPrimary}
							BackgroundTransparency={1}
							Size={new UDim2(0.7, 0, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
						<Badge label="GLOBAL" style="accent" pill={true} />
					</frame>
					<textlabel
						Text="Competitive rankings across enterprise operators worldwide."
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textSecondary}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 20)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
				</frame>
			</Card>

			{/* Filter toggles & refresh */}
			<frame Size={new UDim2(1, 0, 0, 40)} BackgroundTransparency={1} LayoutOrder={2}>
				<uilistlayout
					FillDirection={Enum.FillDirection.Horizontal}
					VerticalAlignment={Enum.VerticalAlignment.Center}
					Padding={new UDim(0, 12)}
				/>
				<Button
					label="All-Time Compute"
					variant={category === "compute" ? "primary" : "secondary"}
					width={160}
					height={36}
					onClick={() => setCategory("compute")}
				/>
				<Button
					label="Prestige Tokens"
					variant={category === "prestige" ? "primary" : "secondary"}
					width={160}
					height={36}
					onClick={() => setCategory("prestige")}
				/>
				<Button
					label={loading ? "Refreshing..." : "↻ Refresh"}
					variant="secondary"
					width={120}
					height={36}
					disabled={loading}
					onClick={refreshLeaderboard}
				/>
			</frame>

			{/* Top 3 Podium Cards */}
			<frame Size={new UDim2(1, 0, 0, 140)} BackgroundTransparency={1} LayoutOrder={3}>
				<uilistlayout
					FillDirection={Enum.FillDirection.Horizontal}
					Padding={new UDim(0, 14)}
					HorizontalAlignment={Enum.HorizontalAlignment.Center}
				/>

				{/* 2nd Place */}
				<Card height={140} bgColor={Color3.fromRGB(20, 22, 28)}>
					<uipadding PaddingLeft={new UDim(0, 16)} PaddingRight={new UDim(0, 16)} PaddingTop={new UDim(0, 16)} />
					<uilistlayout FillDirection={Enum.FillDirection.Vertical} HorizontalAlignment={Enum.HorizontalAlignment.Center} Padding={new UDim(0, 4)} />
					<Badge label="#2 SILVER" style="default" pill={true} />
					<textlabel Text={entries[1]?.callsign ?? "—"} Font={Font.bold} TextSize={Size.section} TextColor3={C.textPrimary} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 22)} />
					<textlabel Text={fmt(entries[1]?.score ?? 0)} Font={Font.mono} TextSize={Size.body} TextColor3={C.accent} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 20)} />
				</Card>

				{/* 1st Place */}
				<Card height={140} bgColor={Color3.fromRGB(28, 28, 36)}>
					<uipadding PaddingLeft={new UDim(0, 16)} PaddingRight={new UDim(0, 16)} PaddingTop={new UDim(0, 16)} />
					<uilistlayout FillDirection={Enum.FillDirection.Vertical} HorizontalAlignment={Enum.HorizontalAlignment.Center} Padding={new UDim(0, 4)} />
					<Badge label="#1 GOLD" style="energy" pill={true} />
					<textlabel Text={entries[0]?.callsign ?? "—"} Font={Font.bold} TextSize={Size.section + 2} TextColor3={C.gold} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 24)} />
					<textlabel Text={fmt(entries[0]?.score ?? 0)} Font={Font.mono} TextSize={Size.body} TextColor3={C.gold} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 20)} />
				</Card>

				{/* 3rd Place */}
				<Card height={140} bgColor={Color3.fromRGB(20, 22, 28)}>
					<uipadding PaddingLeft={new UDim(0, 16)} PaddingRight={new UDim(0, 16)} PaddingTop={new UDim(0, 16)} />
					<uilistlayout FillDirection={Enum.FillDirection.Vertical} HorizontalAlignment={Enum.HorizontalAlignment.Center} Padding={new UDim(0, 4)} />
					<Badge label="#3 BRONZE" style="danger" pill={true} />
					<textlabel Text={entries[2]?.callsign ?? "—"} Font={Font.bold} TextSize={Size.section} TextColor3={C.textPrimary} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 22)} />
					<textlabel Text={fmt(entries[2]?.score ?? 0)} Font={Font.mono} TextSize={Size.body} TextColor3={C.accent} BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 20)} />
				</Card>
			</frame>

			{/* Detailed list rows */}
			{entries.filter((_, idx: number) => idx >= 3).map((item: LeaderboardEntry, idx: number) => (
				<Card key={tostring(item.rank)} height={52} layoutOrder={idx + 4}>
					<uipadding
						PaddingLeft={new UDim(0, 20)}
						PaddingRight={new UDim(0, 20)}
						PaddingTop={new UDim(0, 8)}
						PaddingBottom={new UDim(0, 8)}
					/>
					<frame Size={new UDim2(1, 0, 1, 0)} BackgroundTransparency={1}>
						<uilistlayout
							FillDirection={Enum.FillDirection.Horizontal}
							VerticalAlignment={Enum.VerticalAlignment.Center}
							Padding={new UDim(0, 14)}
						/>
						<textlabel
							Text={`#${item.rank}`}
							Font={Font.mono}
							TextSize={Size.body}
							TextColor3={C.textMuted}
							BackgroundTransparency={1}
							Size={new UDim2(0, 36, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
						<textlabel
							Text={item.callsign}
							Font={Font.bold}
							TextSize={Size.body}
							TextColor3={C.textPrimary}
							BackgroundTransparency={1}
							Size={new UDim2(0.6, 0, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
						<textlabel
							Text={`${fmt(item.score)} ⚡`}
							Font={Font.mono}
							TextSize={Size.body}
							TextColor3={C.compute}
							BackgroundTransparency={1}
							Size={new UDim2(0.3, 0, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Right}
						/>
					</frame>
				</Card>
			))}
		</scrollingframe>
	);
}

