// components/NavDock.tsx — Precision obsidian vertical rail (desktop) / bottom tab bar (mobile)

import React from "@rbxts/react";
import { C, R, Font, Size } from "../theme";

interface NavDockProps {
	activeScreen: string;
	onNavigate: (screen: string) => void;
}

interface NavItem {
	id: string;
	label: string;
	icon: string;
}

const NAV_ITEMS: NavItem[] = [
	{ id: "overview",       label: "Command",   icon: "rbxassetid://7733960981" },
	{ id: "operations",     label: "Ops",       icon: "rbxassetid://7734051202" },
	{ id: "infrastructure", label: "Hardware",  icon: "rbxassetid://7734053426" },
	{ id: "research",       label: "Research",  icon: "rbxassetid://7733674922" },
	{ id: "modules",        label: "Modules",   icon: "rbxassetid://7733765045" },
	{ id: "contracts",      label: "Contracts", icon: "rbxassetid://7733919526" },
	{ id: "rewards",        label: "Rewards",   icon: "rbxassetid://7733946818" },
	{ id: "shop",           label: "Depot",     icon: "rbxassetid://7734056747" },
	{ id: "prestige",       label: "Prestige",  icon: "rbxassetid://7734056556" },
	{ id: "events",         label: "Terminal",  icon: "rbxassetid://7733673987" },
	{ id: "leaderboard",    label: "Rankings",  icon: "rbxassetid://7733946818" },
	{ id: "settings",       label: "Settings",  icon: "rbxassetid://7734058803" },
];

const TWEEN_INFO = new TweenInfo(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

function NavButton({
	item,
	isActive,
	isDesktop,
	onNavigate,
}: {
	item: NavItem;
	isActive: boolean;
	isDesktop: boolean;
	onNavigate: (screen: string) => void;
}) {
	const [hovered, setHovered] = React.useState(false);

	const bgColor = isActive
		? Color3.fromRGB(24, 34, 52)
		: (hovered ? Color3.fromRGB(24, 28, 38) : Color3.fromRGB(16, 18, 24));

	const strokeColor = isActive ? C.accent : C.hairline;
	const strokeTrans = isActive ? 0.35 : 0.85;
	const iconColor = isActive ? C.accent : (hovered ? C.textPrimary : C.textMuted);
	const textColor = isActive ? C.textPrimary : (hovered ? C.textSecondary : C.textMuted);

	return (
		<textbutton
			key={item.id}
			Text=""
			AutoButtonColor={false}
			BackgroundColor3={bgColor}
			BackgroundTransparency={isActive || hovered ? 0 : 1}
			BorderSizePixel={0}
			Size={isDesktop ? new UDim2(0, 58, 0, 48) : new UDim2(0, 56, 1, -12)}
			ZIndex={12}
			Event={{
				Activated: () => onNavigate(item.id),
				MouseEnter: () => setHovered(true),
				MouseLeave: () => setHovered(false),
			}}
		>
			<uicorner CornerRadius={new UDim(0, R.control)} />
			<uistroke Color={strokeColor} Thickness={1} Transparency={strokeTrans} />

			{/* Active indicator bar on the left edge */}
			{isDesktop && isActive && (
				<frame
					key="ActiveBar"
					BackgroundColor3={C.accent}
					BorderSizePixel={0}
					Size={new UDim2(0, 3, 0, 24)}
					Position={new UDim2(0, -6, 0.5, 0)}
					AnchorPoint={new Vector2(0, 0.5)}
					ZIndex={14}
				>
					<uicorner CornerRadius={new UDim(0, 2)} />
				</frame>
			)}

			<frame
				key="Content"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 1, 0)}
				ZIndex={13}
			>
				<uilistlayout
					FillDirection={Enum.FillDirection.Vertical}
					HorizontalAlignment={Enum.HorizontalAlignment.Center}
					VerticalAlignment={Enum.VerticalAlignment.Center}
					Padding={new UDim(0, 3)}
				/>
				<imagelabel
					key="Icon"
					Image={item.icon}
					ImageColor3={iconColor}
					BackgroundTransparency={1}
					Size={new UDim2(0, 20, 0, 20)}
					ScaleType={Enum.ScaleType.Fit}
				/>
				<textlabel
					key="Label"
					Text={item.label}
					Font={isActive ? Font.bold : Font.body}
					TextSize={10}
					TextColor3={textColor}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 12)}
					TextXAlignment={Enum.TextXAlignment.Center}
					TextYAlignment={Enum.TextYAlignment.Center}
				/>
			</frame>
		</textbutton>
	);
}

export default function NavDock({ activeScreen, onNavigate }: NavDockProps): React.Element {
	const vp = game.GetService("Workspace").CurrentCamera?.ViewportSize ?? new Vector2(800, 600);
	const isDesktop = vp.X >= 640;

	return (
		<frame
			key="NavDock"
			BackgroundColor3={C.panel}
			BorderSizePixel={0}
			Size={isDesktop ? new UDim2(0, 72, 1, -52) : new UDim2(1, 0, 0, 58)}
			Position={isDesktop ? new UDim2(0, 0, 0, 52) : new UDim2(0, 0, 1, -58)}
			ZIndex={15}
		>
			{/* Divider Hairline */}
			<frame
				key="Hairline"
				BackgroundColor3={C.hairline}
				BorderSizePixel={0}
				Size={isDesktop ? new UDim2(0, 1, 1, 0) : new UDim2(1, 0, 0, 1)}
				Position={isDesktop ? new UDim2(1, -1, 0, 0) : new UDim2(0, 0, 0, 0)}
				ZIndex={16}
			/>

			{/* Nav items list */}
			<scrollingframe
				key="NavList"
				BackgroundTransparency={1}
				BorderSizePixel={0}
				ScrollBarThickness={0}
				CanvasSize={isDesktop ? new UDim2(0, 0, 0, NAV_ITEMS.size() * 52 + 16) : new UDim2(0, NAV_ITEMS.size() * 60, 0, 0)}
				Size={new UDim2(1, 0, 1, 0)}
				ScrollingDirection={isDesktop ? Enum.ScrollingDirection.Y : Enum.ScrollingDirection.X}
				ZIndex={16}
			>
				<uilistlayout
					FillDirection={isDesktop ? Enum.FillDirection.Vertical : Enum.FillDirection.Horizontal}
					HorizontalAlignment={Enum.HorizontalAlignment.Center}
					VerticalAlignment={isDesktop ? Enum.VerticalAlignment.Top : Enum.VerticalAlignment.Center}
					Padding={new UDim(0, 4)}
				/>
				<uipadding
					PaddingTop={new UDim(0, 8)}
					PaddingBottom={new UDim(0, 8)}
					PaddingLeft={new UDim(0, 4)}
					PaddingRight={new UDim(0, 4)}
				/>

				{NAV_ITEMS.map((item) => (
					<NavButton
						key={item.id}
						item={item}
						isActive={activeScreen === item.id}
						isDesktop={isDesktop}
						onNavigate={onNavigate}
					/>
				))}
			</scrollingframe>
		</frame>
	);
}
