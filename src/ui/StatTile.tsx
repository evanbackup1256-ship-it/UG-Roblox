// ui/StatTile.tsx — Metric tile with bump-on-change animation

import React from "@rbxts/react";
import { C, R, Font, Size } from "../theme";
import { Card } from "./Card";
import { ProgressBar } from "./ProgressBar";

interface StatTileProps {
	title: string;
	subtitle: string;
	value: string;
	color: Color3;
	layoutOrder?: number;
	progress?: number; // 0..1, shows progress bar if set
}

const BUMP_INFO = new TweenInfo(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out);
const UNBUMP_INFO = new TweenInfo(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

export function StatTile({ title, subtitle, value, color, layoutOrder, progress }: StatTileProps) {
	const valRef = React.createRef<TextLabel>();
	const prevValue = React.useRef(value);

	React.useEffect(() => {
		if (value !== prevValue.current) {
			prevValue.current = value;
			const lbl = valRef.current;
			if (!lbl) return;
			const ts = game.GetService("TweenService");
			ts.Create(lbl, BUMP_INFO, { TextSize: Size.title + 4, TextColor3: color })
				.Play();
			task.delay(0.15, () => {
				ts.Create(lbl, UNBUMP_INFO, { TextSize: Size.title, TextColor3: C.textPrimary })
					.Play();
			});
		}
	}, [value]);

	return (
		<Card height={progress !== undefined ? 112 : 98} layoutOrder={layoutOrder}>
			<uilistlayout
				FillDirection={Enum.FillDirection.Vertical}
				Padding={new UDim(0, 4)}
				SortOrder={Enum.SortOrder.LayoutOrder}
			/>
			<uipadding
				PaddingLeft={new UDim(0, 18)}
				PaddingRight={new UDim(0, 18)}
				PaddingTop={new UDim(0, 14)}
				PaddingBottom={new UDim(0, 14)}
			/>

			<textlabel
				key="Title"
				Text={title}
				Font={Font.body}
				TextSize={Size.caption}
				TextColor3={C.textSecondary}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 16)}
				TextXAlignment={Enum.TextXAlignment.Left}
				LayoutOrder={1}
			/>
			<textlabel
				ref={valRef}
				key="Value"
				Text={value}
				Font={Font.display}
				TextSize={Size.title}
				TextColor3={C.textPrimary}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 26)}
				TextXAlignment={Enum.TextXAlignment.Left}
				LayoutOrder={2}
			/>
			<textlabel
				key="Subtitle"
				Text={subtitle}
				Font={Font.body}
				TextSize={Size.micro}
				TextColor3={color}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 14)}
				TextXAlignment={Enum.TextXAlignment.Left}
				LayoutOrder={3}
			/>
			{progress !== undefined && (
				<frame key="BarWrap" Size={new UDim2(1, 0, 0, 6)} BackgroundTransparency={1} LayoutOrder={4}>
					<ProgressBar progress={progress} color={color} height={4} />
				</frame>
			)}
		</Card>
	);
}

