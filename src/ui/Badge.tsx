// ui/Badge.tsx — Semantic pill/label badge

import React from "@rbxts/react";
import { C, R, Font, Size } from "../theme";

type BadgeStyle = "default" | "compute" | "energy" | "data" | "reputation" | "danger" | "accent";

interface BadgeProps {
	label: string;
	style?: BadgeStyle;
	pill?: boolean;
}

const STYLES: Record<BadgeStyle, { bg: Color3; text: Color3; stroke: Color3 }> = {
	default:    { bg: C.elevated,                     text: C.textSecondary, stroke: C.hairline },
	compute:    { bg: Color3.fromRGB(16, 32, 24),     text: C.compute,       stroke: C.compute  },
	energy:     { bg: Color3.fromRGB(36, 28, 12),     text: C.energy,        stroke: C.energy   },
	data:       { bg: Color3.fromRGB(12, 28, 36),     text: C.data,          stroke: C.data     },
	reputation: { bg: Color3.fromRGB(24, 18, 38),     text: C.reputation,    stroke: C.reputation },
	danger:     { bg: Color3.fromRGB(36, 16, 16),     text: C.danger,        stroke: C.danger   },
	accent:     { bg: Color3.fromRGB(18, 30, 48),     text: C.accent,        stroke: C.accent   },
};

export function Badge({ label, style = "default", pill = false }: BadgeProps) {
	const s = STYLES[style];
	return (
		<frame BackgroundColor3={s.bg} BorderSizePixel={0} Size={new UDim2(0, 84, 0, 22)} AutomaticSize={Enum.AutomaticSize.X}>
			<uicorner CornerRadius={new UDim(0, pill ? R.pill : R.badge)} />
			<uistroke Color={s.stroke} Thickness={1} Transparency={0.55} />
			<uipadding
				PaddingLeft={new UDim(0, 8)}
				PaddingRight={new UDim(0, 8)}
				PaddingTop={new UDim(0, 3)}
				PaddingBottom={new UDim(0, 3)}
			/>
			<textlabel
				Text={label.upper()}
				Font={Font.mono}
				TextSize={Size.micro}
				TextColor3={s.text}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 1, 0)}
				TextXAlignment={Enum.TextXAlignment.Center}
				TextYAlignment={Enum.TextYAlignment.Center}
				AutomaticSize={Enum.AutomaticSize.X}
			/>
		</frame>
	);
}

