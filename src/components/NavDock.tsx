// components/NavDock.tsx — Vertical sidebar (desktop) / bottom tab bar (mobile)

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
	{ id: "overview",       label: "Overview",    icon: "rbxassetid://7733765045" },
	{ id: "operations",     label: "Ops",         icon: "rbxassetid://7733765045" },
	{ id: "infrastructure", label: "Infra",       icon: "rbxassetid://7733765045" },
	{ id: "research",       label: "Research",    icon: "rbxassetid://7733765045" },
	{ id: "modules",        label: "Modules",     icon: "rbxassetid://7733765045" },
	{ id: "contracts",      label: "Contracts",   icon: "rbxassetid://7733765045" },
	{ id: "rewards",        label: "Rewards",     icon: "rbxassetid://7733765045" },
	{ id: "shop",           label: "Shop",        icon: "rbxassetid://7733765045" },
	{ id: "prestige",       label: "Prestige",    icon: "rbxassetid://7733765045" },
	{ id: "events",         label: "Events",      icon: "rbxassetid://7733765045" },
	{ id: "leaderboard",    label: "Leaders",     icon: "rbxassetid://7733765045" },
	{ id: "settings",       label: "Settings",    icon: "rbxassetid://7733765045" },
];

const TWEEN_FAST = new TweenInfo(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);

// Individual nav button with hover/active states
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
	const pillRef = React.createRef<Frame>();
	const btnRef = React.createRef<TextButton>();

	const tween = (obj: Instance, props: object) => {
		game.GetService("TweenService").Create(obj as Instance, TWEEN_FAST, props).Play();
	};

	// Animate pill in when active
	React.useEffect(() => {
		const pill = pillRef.current;
		if (!pill) return;
		tween(pill, {
			BackgroundTransparency: isActive ? 0 : 1,
			Size: isActive
				? (isDesktop
					? new UDim2(0, 46, 0, 32)
					: new UDim2(0, 52, 0, 28))
				: (isDesktop
					? new UDim2(0, 0, 0, 32)
					: new UDim2(0, 0, 0, 28)),
		});
	}, [isActive]);

	return (
		<textbutton
			ref={btnRef}
			key={item.id}
			Text=""
			AutoButtonColor={false}
			BackgroundTransparency={1}
			BorderSizePixel={0}
			Size={
				isDesktop
					? new UDim2(1, 0, 0, 56)
					: new UDim2(0, 58, 1, 0)
			}
			ZIndex={11}
			Event={{
				Activated: () => onNavigate(item.id),
				MouseEnter: () => {
					if (isActive) return;
					const btn = btnRef.current;
					if (btn) tween(btn, { BackgroundTransparency: 0.95 });
				},
				MouseLeave: () => {
					if (isActive) return;
					const btn = btnRef.current;
					if (btn) tween(btn, { BackgroundTransparency: 1 });
				},
			}}
		>
			{/* Active azure pill glow — centered behind icon+label */}
			<frame
				ref={pillRef}
				key="ActivePill"
				BackgroundColor3={Color3.fromRGB(59, 130, 246)}
				BackgroundTransparency={isActive ? 0 : 1}
				BorderSizePixel={0}
				AnchorPoint={new Vector2(0.5, 0.5)}
				Position={new UDim2(0.5, 0, 0.5, 0)}
				Size={
					isDesktop
						? (isActive ? new UDim2(0, 46, 0, 32) : new UDim2(0, 0, 0, 32))
						: (isActive ? new UDim2(0, 52, 0, 28) : new UDim2(0, 0, 0, 28))
				}
				ZIndex={10}
			>
				<uicorner CornerRadius={new UDim(0, R.pill)} />
				<uistroke
					Color={Color3.fromRGB(96, 165, 250)}
					Thickness={1}
					Transparency={isActive ? 0.45 : 1}
				/>
				{/* Glow halo */}
				<frame
					key="Glow"
					BackgroundColor3={Color3.fromRGB(59, 130, 246)}
					BackgroundTransparency={0.65}
					BorderSizePixel={0}
					AnchorPoint={new Vector2(0.5, 0.5)}
					Position={new UDim2(0.5, 0, 0.5, 0)}
					Size={new UDim2(1, 12, 1, 12)}
					ZIndex={9}
				>
					<uicorner CornerRadius={new UDim(0, R.pill)} />
				</frame>
			</frame>

			{/* Content: icon + label stacked */}
			<frame
				key="Content"
				BackgroundTransparency={1}
				AnchorPoint={new Vector2(0.5, 0.5)}
				Position={new UDim2(0.5, 0, 0.5, 0)}
				Size={new UDim2(0, 40, 0, 40)}
				ZIndex={12}
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
					ImageColor3={isActive ? Color3.fromRGB(255, 255, 255) : C.textMuted}
					BackgroundTransparency={1}
					Size={new UDim2(0, 22, 0, 22)}
					ScaleType={Enum.ScaleType.Fit}
				/>
				<textlabel
					key="Label"
					Text={item.label}
					Font={Font.mono}
					TextSize={9}
					TextColor3={isActive ? C.textPrimary : C.textMuted}
					BackgroundTransparency={1}
					Size={new UDim2(0, 52, 0, 11)}
					TextXAlignment={Enum.TextXAlignment.Center}
					TextScaled={false}
				/>
			</frame>
		</textbutton>
	);
}

export default function NavDock({ activeScreen, onNavigate }: NavDockProps): React.Element {
	// Simple heuristic: if viewport width >= 640 → desktop sidebar, else bottom bar
	const vp = game.GetService("Workspace").CurrentCamera?.ViewportSize ?? new Vector2(800, 600);
	const isDesktop = vp.X >= 640;

	return (
		<frame
			key="NavDock"
			BackgroundColor3={C.panel}
			BorderSizePixel={0}
			Size={
				isDesktop
					? new UDim2(0, 72, 1, -56)
					: new UDim2(1, 0, 0, 64)
			}
			Position={
				isDesktop
					? new UDim2(0, 0, 0, 56)
					: new UDim2(0, 0, 1, -64)
			}
			ZIndex={15}
		>
			{/* Right hairline (desktop) / top hairline (mobile) */}
			<frame
				key="Hairline"
				BackgroundColor3={C.hairline}
				BorderSizePixel={0}
				Size={
					isDesktop
						? new UDim2(0, 1, 1, 0)
						: new UDim2(1, 0, 0, 1)
				}
				Position={
					isDesktop
						? new UDim2(1, -1, 0, 0)
						: new UDim2(0, 0, 0, 0)
				}
				ZIndex={16}
			/>

			{/* Nav items list */}
			<scrollingframe
				key="NavList"
				BackgroundTransparency={1}
				BorderSizePixel={0}
				ScrollBarThickness={0}
				CanvasSize={
					isDesktop
						? new UDim2(0, 0, 0, NAV_ITEMS.size() * 56)
						: new UDim2(0, NAV_ITEMS.size() * 58, 0, 0)
				}
				Size={new UDim2(1, 0, 1, 0)}
				ScrollingDirection={
					isDesktop
						? Enum.ScrollingDirection.Y
						: Enum.ScrollingDirection.X
				}
				ZIndex={16}
			>
				<uilistlayout
					FillDirection={
						isDesktop
							? Enum.FillDirection.Vertical
							: Enum.FillDirection.Horizontal
					}
					HorizontalAlignment={Enum.HorizontalAlignment.Center}
					VerticalAlignment={Enum.VerticalAlignment.Top}
					Padding={new UDim(0, 0)}
				/>
				<uipadding
					PaddingTop={isDesktop ? new UDim(0, 8) : new UDim(0, 0)}
					PaddingBottom={isDesktop ? new UDim(0, 8) : new UDim(0, 0)}
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

