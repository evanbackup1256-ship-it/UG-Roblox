// ui/Card.tsx — Premium glassmorphic dark card

import React from "@rbxts/react";
import { C, R } from "../theme";

interface CardProps {
	height?: number;
	bgColor?: Color3;
	children?: React.ReactNode;
	layoutOrder?: number;
	zIndex?: number;
	key?: string;
}

export function Card({ height = 120, bgColor = C.card, children, layoutOrder, zIndex = 2 }: CardProps) {
	return (
		<frame
			BackgroundColor3={bgColor}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 0, height)}
			LayoutOrder={layoutOrder}
			ZIndex={zIndex}
		>
			<uicorner CornerRadius={new UDim(0, R.card)} />

			{/* Hairline border — gradient from bright top to dim bottom */}
			<uistroke
				Color={Color3.fromRGB(255, 255, 255)}
				Thickness={1}
				Transparency={0.88}
			>
				<uigradient
					Rotation={90}
					Transparency={
						new NumberSequence([
							new NumberSequenceKeypoint(0, 0.70),
							new NumberSequenceKeypoint(1, 0.96),
						])
					}
				/>
			</uistroke>

			{/* Glowing top bevel line */}
			<frame
				key="TopBevel"
				BackgroundColor3={Color3.fromRGB(255, 255, 255)}
				BackgroundTransparency={0.90}
				BorderSizePixel={0}
				Size={new UDim2(1, -16, 0, 1)}
				Position={new UDim2(0.5, 0, 0, 0)}
				AnchorPoint={new Vector2(0.5, 0)}
				ZIndex={zIndex + 1}
			>
				<uigradient
					Transparency={
						new NumberSequence([
							new NumberSequenceKeypoint(0, 1),
							new NumberSequenceKeypoint(0.5, 0),
							new NumberSequenceKeypoint(1, 1),
						])
					}
				/>
			</frame>

			{/* Drop shadow behind card */}
			<imagelabel
				key="Shadow"
				Image="rbxassetid://1316045217"
				ImageColor3={Color3.fromRGB(0, 0, 0)}
				ImageTransparency={0.55}
				BackgroundTransparency={1}
				ScaleType={Enum.ScaleType.Slice}
				SliceCenter={new Rect(10, 10, 118, 118)}
				Size={new UDim2(1, 28, 1, 28)}
				Position={new UDim2(0.5, 0, 0.5, 6)}
				AnchorPoint={new Vector2(0.5, 0.5)}
				ZIndex={zIndex - 1}
			/>

			{/* Dedicated content frame so children's layouts don't capture decorations */}
			<frame
				key="InnerContent"
				BackgroundTransparency={1}
				BorderSizePixel={0}
				Size={new UDim2(1, 0, 1, 0)}
				ZIndex={zIndex + 2}
			>
				{children}
			</frame>
		</frame>
	);
}

