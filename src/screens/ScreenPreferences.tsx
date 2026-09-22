// screens/ScreenPreferences.tsx — Settings & System Preferences

import React from "@rbxts/react";
import { C, Font, Size, R } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { useGameState } from "../hooks";
import { act } from "../store";

export default function ScreenPreferences(): React.Element {
	const gs = useGameState();
	const [sfx, setSfx] = React.useState(true);
	const [music, setMusic] = React.useState(true);
	const [motion, setMotion] = React.useState(true);
	const [notifications, setNotifications] = React.useState(true);
	const [selectedTheme, setSelectedTheme] = React.useState("azure");

	const themes = [
		{ id: "azure", name: "Azure", color: Color3.fromRGB(59, 130, 246) },
		{ id: "mint", name: "Mint", color: Color3.fromRGB(16, 185, 129) },
		{ id: "amber", name: "Amber", color: Color3.fromRGB(245, 158, 11) },
		{ id: "purple", name: "Iris", color: Color3.fromRGB(139, 92, 246) },
		{ id: "rose", name: "Rose", color: Color3.fromRGB(244, 63, 94) },
	];

	return (
		<scrollingframe
			Size={new UDim2(1, 0, 1, 0)}
			BackgroundTransparency={1}
			BorderSizePixel={0}
			ScrollBarThickness={4}
			ScrollBarImageColor3={C.hairline}
			CanvasSize={new UDim2(0, 0, 0, 800)}
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

			{/* Header */}
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
							Text="SYSTEM PREFERENCES"
							Font={Font.bold}
							TextSize={Size.title}
							TextColor3={C.textPrimary}
							BackgroundTransparency={1}
							Size={new UDim2(0.7, 0, 1, 0)}
							TextXAlignment={Enum.TextXAlignment.Left}
						/>
						<Badge label="CONFIG" style="accent" pill={true} />
					</frame>
					<textlabel
						Text="Custom acoustic parameters, kinetic springs, and visual display palettes."
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textSecondary}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 0, 20)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
				</frame>
			</Card>

			{/* Audio Settings */}
			<Card height={140} layoutOrder={2}>
				<uipadding
					PaddingLeft={new UDim(0, 20)}
					PaddingRight={new UDim(0, 20)}
					PaddingTop={new UDim(0, 16)}
					PaddingBottom={new UDim(0, 16)}
				/>
				<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 12)} />
				<textlabel
					Text="ACOUSTIC EMISSIONS"
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.accent}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 16)}
					TextXAlignment={Enum.TextXAlignment.Left}
				/>
				<frame Size={new UDim2(1, 0, 0, 36)} BackgroundTransparency={1}>
					<textlabel
						Text="Sound Effects (SFX)"
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(0.7, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<Button
						label={sfx ? "ENABLED" : "MUTED"}
						variant={sfx ? "success" : "secondary"}
						width={100}
						height={32}
						onClick={() => setSfx(!sfx)}
					/>
				</frame>
				<frame Size={new UDim2(1, 0, 0, 36)} BackgroundTransparency={1}>
					<textlabel
						Text="Ambient Synthesis Track"
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(0.7, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<Button
						label={music ? "ENABLED" : "MUTED"}
						variant={music ? "success" : "secondary"}
						width={100}
						height={32}
						onClick={() => setMusic(!music)}
					/>
				</frame>
			</Card>

			{/* Visual & Kinetic Settings */}
			<Card height={140} layoutOrder={3}>
				<uipadding
					PaddingLeft={new UDim(0, 20)}
					PaddingRight={new UDim(0, 20)}
					PaddingTop={new UDim(0, 16)}
					PaddingBottom={new UDim(0, 16)}
				/>
				<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 12)} />
				<textlabel
					Text="PHYSICAL INTERACTION & KINETICS"
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.accent}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 16)}
					TextXAlignment={Enum.TextXAlignment.Left}
				/>
				<frame Size={new UDim2(1, 0, 0, 36)} BackgroundTransparency={1}>
					<textlabel
						Text="Kinetic Animations & Motion"
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(0.7, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<Button
						label={motion ? "FLUID" : "STATIC"}
						variant={motion ? "primary" : "secondary"}
						width={100}
						height={32}
						onClick={() => setMotion(!motion)}
					/>
				</frame>
				<frame Size={new UDim2(1, 0, 0, 36)} BackgroundTransparency={1}>
					<textlabel
						Text="Mission Status Notifications"
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textPrimary}
						BackgroundTransparency={1}
						Size={new UDim2(0.7, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Left}
					/>
					<Button
						label={notifications ? "ACTIVE" : "OFF"}
						variant={notifications ? "primary" : "secondary"}
						width={100}
						height={32}
						onClick={() => setNotifications(!notifications)}
					/>
				</frame>
			</Card>

			{/* Theme Palette */}
			<Card height={130} layoutOrder={4}>
				<uipadding
					PaddingLeft={new UDim(0, 20)}
					PaddingRight={new UDim(0, 20)}
					PaddingTop={new UDim(0, 16)}
					PaddingBottom={new UDim(0, 16)}
				/>
				<uilistlayout FillDirection={Enum.FillDirection.Vertical} Padding={new UDim(0, 12)} />
				<textlabel
					Text="INTERACTION ACCENT THEME"
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.accent}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 16)}
					TextXAlignment={Enum.TextXAlignment.Left}
				/>
				<frame Size={new UDim2(1, 0, 0, 48)} BackgroundTransparency={1}>
					<uilistlayout
						FillDirection={Enum.FillDirection.Horizontal}
						Padding={new UDim(0, 12)}
						VerticalAlignment={Enum.VerticalAlignment.Center}
					/>
					{themes.map((t) => (
						<Button
							key={t.id}
							label={t.name}
							variant={selectedTheme === t.id ? "primary" : "secondary"}
							width={90}
							height={36}
							onClick={() => setSelectedTheme(t.id)}
						/>
					))}
				</frame>
			</Card>

			{/* Commit Changes */}
			<frame Size={new UDim2(1, 0, 0, 44)} BackgroundTransparency={1} LayoutOrder={5}>
				<Button
					label="Save Changes & Commit"
					variant="primary"
					height={44}
					onClick={() => act("savePreferences", { sfx, music, motion, notifications, theme: selectedTheme })}
				/>
			</frame>
		</scrollingframe>
	);
}

