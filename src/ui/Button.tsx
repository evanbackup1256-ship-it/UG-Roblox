// ui/Button.tsx — TweenService-animated button with three variants

import React from "@rbxts/react";
import { C, R, Font, Size } from "../theme";

type Variant = "primary" | "secondary" | "danger" | "success" | "amber";

interface ButtonProps {
	label: string;
	onClick: () => void;
	variant?: Variant;
	width?: number;
	height?: number;
	disabled?: boolean;
	layoutOrder?: number;
}

const VARIANTS: Record<Variant, { bg: Color3; bgHover: Color3; bgPress: Color3; text: Color3; stroke: Color3 }> = {
	primary: {
		bg:      Color3.fromRGB(59,  130, 246),
		bgHover: Color3.fromRGB(37,  99,  235),
		bgPress: Color3.fromRGB(29,  78,  216),
		text:    Color3.fromRGB(255, 255, 255),
		stroke:  Color3.fromRGB(96,  165, 250),
	},
	secondary: {
		bg:      Color3.fromRGB(26,  30,  42),
		bgHover: Color3.fromRGB(34,  40,  56),
		bgPress: Color3.fromRGB(20,  24,  34),
		text:    Color3.fromRGB(248, 250, 252),
		stroke:  Color3.fromRGB(44,  55,  74),
	},
	danger: {
		bg:      Color3.fromRGB(239, 68,  68),
		bgHover: Color3.fromRGB(220, 38,  38),
		bgPress: Color3.fromRGB(185, 28,  28),
		text:    Color3.fromRGB(255, 255, 255),
		stroke:  Color3.fromRGB(252, 165, 165),
	},
	success: {
		bg:      Color3.fromRGB(16,  185, 129),
		bgHover: Color3.fromRGB(5,   150, 105),
		bgPress: Color3.fromRGB(4,   120, 87),
		text:    Color3.fromRGB(255, 255, 255),
		stroke:  Color3.fromRGB(110, 231, 183),
	},
	amber: {
		bg:      Color3.fromRGB(245, 158, 11),
		bgHover: Color3.fromRGB(217, 119, 6),
		bgPress: Color3.fromRGB(180, 83,  9),
		text:    Color3.fromRGB(24,  16,  6),
		stroke:  Color3.fromRGB(251, 191, 36),
	},
};

const PRESS_INFO = new TweenInfo(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
const RELEASE_INFO = new TweenInfo(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
const HOVER_INFO = new TweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

export function Button({ label, onClick, variant = "primary", width, height = 40, disabled = false, layoutOrder }: ButtonProps) {
	const v = VARIANTS[variant];
	const ref = React.createRef<TextButton>();

	const tween = (obj: Instance, info: TweenInfo, props: object) => {
		game.GetService("TweenService").Create(obj, info, props).Play();
	};

	return (
		<textbutton
			ref={ref}
			Text=""
			AutoButtonColor={false}
			BackgroundColor3={v.bg}
			BorderSizePixel={0}
			Size={width ? new UDim2(0, width, 0, height) : new UDim2(1, 0, 0, height)}
			LayoutOrder={layoutOrder}
			Active={!disabled}
			BackgroundTransparency={disabled ? 0.4 : 0}
			Event={{
				MouseEnter: () => {
					const btn = ref.current;
					if (!btn || disabled) return;
					tween(btn, HOVER_INFO, { BackgroundColor3: v.bgHover });
				},
				MouseLeave: () => {
					const btn = ref.current;
					if (!btn || disabled) return;
					tween(btn, HOVER_INFO, { BackgroundColor3: v.bg });
				},
				MouseButton1Down: () => {
					const btn = ref.current;
					if (!btn || disabled) return;
					tween(btn, PRESS_INFO, { BackgroundColor3: v.bgPress, Size: new UDim2(1, 0, 0, height - 2) });
				},
				MouseButton1Up: () => {
					const btn = ref.current;
					if (!btn || disabled) return;
					tween(btn, RELEASE_INFO, { BackgroundColor3: v.bgHover, Size: new UDim2(width ? 0 : 1, width ?? 0, 0, height) });
				},
				Activated: () => {
					if (!disabled) onClick();
				},
			}}
		>
			<uicorner CornerRadius={new UDim(0, R.control)} />
			<uistroke Color={v.stroke} Thickness={1} Transparency={0.65} />

			<textlabel
				Text={label}
				Font={Font.bold}
				TextSize={Size.body}
				TextColor3={v.text}
				BackgroundTransparency={1}
				Size={new UDim2(1, -16, 1, 0)}
				Position={new UDim2(0.5, 0, 0.5, 0)}
				AnchorPoint={new Vector2(0.5, 0.5)}
				TextXAlignment={Enum.TextXAlignment.Center}
				TextYAlignment={Enum.TextYAlignment.Center}
			/>
		</textbutton>
	);
}

