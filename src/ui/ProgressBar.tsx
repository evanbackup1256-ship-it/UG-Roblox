// ui/ProgressBar.tsx — Animated progress bar with TweenService fill

import React from "@rbxts/react";
import { C, R } from "../theme";

interface ProgressBarProps {
	progress: number; // 0..1
	color?: Color3;
	height?: number;
	glow?: boolean;
}

const TWEEN = new TweenInfo(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out);

export function ProgressBar({ progress, color = C.accent, height = 6, glow = false }: ProgressBarProps) {
	const fillRef = React.createRef<Frame>();
	const clamp = math.clamp(progress, 0, 1);

	React.useEffect(() => {
		const fill = fillRef.current;
		if (!fill) return;
		game.GetService("TweenService")
			.Create(fill, TWEEN, { Size: new UDim2(clamp, 0, 1, 0) })
			.Play();
	}, [clamp]);

	return (
		<frame
			BackgroundColor3={C.recessed}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 0, height)}
		>
			<uicorner CornerRadius={new UDim(0, R.pill)} />
			<frame
				ref={fillRef}
				key="Fill"
				BackgroundColor3={color}
				BorderSizePixel={0}
				Size={new UDim2(clamp, 0, 1, 0)}
			>
				<uicorner CornerRadius={new UDim(0, R.pill)} />
				{glow && (
					<uistroke Color={color} Thickness={2} Transparency={0.5} />
				)}
			</frame>
		</frame>
	);
}

