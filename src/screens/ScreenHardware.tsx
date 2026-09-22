// screens/ScreenHardware.tsx — Buy hardware tiers, search/filter, qty toggle

import React from "@rbxts/react";
import { C, Font, Size, R } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { Badge } from "../ui/Badge";
import { TextInput } from "../ui/TextInput";
import { useGameState } from "../hooks";
import { act, fmt } from "../store";

interface ConfigTierRaw {
	name?: string;
	description?: string;
	cost?: number;
}

const Config = require(game.GetService("ReplicatedStorage")
	.WaitForChild("DeckGame")
	.WaitForChild("Config") as ModuleScript) as { Tiers?: Record<string, ConfigTierRaw> };

// Tier dot colors cycling through accent palette
const TIER_COLORS: Color3[] = [
	Color3.fromRGB(16,  185, 129),
	Color3.fromRGB(59,  130, 246),
	Color3.fromRGB(245, 158, 11),
	Color3.fromRGB(139, 92,  246),
	Color3.fromRGB(236, 72,  153),
	Color3.fromRGB(6,   182, 212),
];

type FilterMode = "all" | "deployed" | "available";
const QTY_OPTIONS = [1, 5, 10] as const;

interface TierEntry {
	key: string;
	name: string;
	description: string;
	cost: number;
	colorIdx: number;
}

function tierList(): TierEntry[] {
	const tiers = Config.Tiers ?? {};
	const result: TierEntry[] = [];
	let i = 0;
	for (const [k, v] of pairs(tiers)) {
		result.push({
			key: k as string,
			name: v.name ?? (k as string),
			description: v.description ?? "",
			cost: v.cost ?? 100,
			colorIdx: i % TIER_COLORS.size(),
		});
		i++;
	}
	return result;
}

// ------- Filter Button --------------------------------------------------
interface FilterBtnProps {
	label: string;
	active: boolean;
	onClick: () => void;
}
function FilterBtn({ label, active, onClick }: FilterBtnProps) {
	return (
		<textbutton
			Text={label}
			Font={active ? Font.bold : Font.body}
			TextSize={Size.caption}
			TextColor3={active ? C.textPrimary : C.textMuted}
			BackgroundColor3={active ? C.elevated : C.recessed}
			BorderSizePixel={0}
			Size={new UDim2(0, 88, 1, 0)}
			AutoButtonColor={false}
			Event={{ Activated: onClick }}
		>
			<uicorner CornerRadius={new UDim(0, R.control)} />
			<uistroke
				Color={active ? C.accent : C.hairline}
				Thickness={1}
				Transparency={active ? 0.5 : 0.75}
			/>
		</textbutton>
	);
}

// ------- Qty Pill -------------------------------------------------------
interface QtyPillProps {
	qty: number;
	active: boolean;
	onClick: () => void;
}
function QtyPill({ qty, active, onClick }: QtyPillProps) {
	return (
		<textbutton
			Text={`×${qty}`}
			Font={active ? Font.bold : Font.body}
			TextSize={Size.caption}
			TextColor3={active ? C.textInverse : C.textSecondary}
			BackgroundColor3={active ? C.accent : C.recessed}
			BorderSizePixel={0}
			Size={new UDim2(0, 48, 1, 0)}
			AutoButtonColor={false}
			Event={{ Activated: onClick }}
		>
			<uicorner CornerRadius={new UDim(0, R.pill)} />
		</textbutton>
	);
}

// ------- Tier Card ------------------------------------------------------
interface TierCardProps {
	tier: TierEntry;
	owned: number;
	qty: number;
	compute: number;
	onBuy: () => void;
	layoutOrder: number;
}
function TierCard({ tier, owned, qty, compute, onBuy, layoutOrder }: TierCardProps) {
	const totalCost = tier.cost * qty;
	const canBuy = compute >= totalCost;
	const dotColor = TIER_COLORS[tier.colorIdx];

	return (
		<Card height={168} layoutOrder={layoutOrder}>
			<uipadding
				PaddingLeft={new UDim(0, 16)}
				PaddingRight={new UDim(0, 16)}
				PaddingTop={new UDim(0, 14)}
				PaddingBottom={new UDim(0, 14)}
			/>
			<uilistlayout
				FillDirection={Enum.FillDirection.Vertical}
				Padding={new UDim(0, 6)}
				SortOrder={Enum.SortOrder.LayoutOrder}
			/>

			{/* Header row: dot + name + owned badge */}
			<frame
				key="Header"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 26)}
				LayoutOrder={1}
			>
				{/* Colored dot */}
				<frame
					key="Dot"
					BackgroundColor3={dotColor}
					BorderSizePixel={0}
					Size={new UDim2(0, 10, 0, 10)}
					Position={new UDim2(0, 0, 0.5, 0)}
					AnchorPoint={new Vector2(0, 0.5)}
				>
					<uicorner CornerRadius={new UDim(0, R.pill)} />
					<uistroke Color={dotColor} Thickness={3} Transparency={0.6} />
				</frame>

				{/* Tier name */}
				<textlabel
					key="TierName"
					Text={tier.name}
					Font={Font.bold}
					TextSize={Size.section}
					TextColor3={C.textPrimary}
					BackgroundTransparency={1}
					Size={new UDim2(1, -80, 1, 0)}
					Position={new UDim2(0, 18, 0, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextYAlignment={Enum.TextYAlignment.Center}
				/>

				{/* Owned badge */}
				<frame
					key="OwnedBadge"
					BackgroundTransparency={1}
					Position={new UDim2(1, 0, 0.5, 0)}
					AnchorPoint={new Vector2(1, 0.5)}
					Size={new UDim2(0, 60, 1, 0)}
				>
					<Badge label={`${owned} owned`} style="default" />
				</frame>
			</frame>

			{/* Subtitle */}
			<textlabel
				key="TierDesc"
				Text={tier.description !== "" ? tier.description : "Cloud hardware module."}
				Font={Font.body}
				TextSize={Size.caption}
				TextColor3={C.textSecondary}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 28)}
				TextXAlignment={Enum.TextXAlignment.Left}
				TextYAlignment={Enum.TextYAlignment.Top}
				TextWrapped={true}
				LayoutOrder={2}
			/>

			{/* Cost */}
			<textlabel
				key="Cost"
				Text={`⚡ ${fmt(totalCost)} compute${qty > 1 ? ` (×${qty})` : ""}`}
				Font={Font.mono}
				TextSize={Size.caption}
				TextColor3={canBuy ? C.compute : C.danger}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 16)}
				TextXAlignment={Enum.TextXAlignment.Left}
				LayoutOrder={3}
			/>

			{/* Buy button */}
			<frame
				key="BuyWrap"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 36)}
				LayoutOrder={4}
			>
				<Button
					label={canBuy ? `Buy ×${qty}` : "Insufficient Compute"}
					onClick={onBuy}
					variant={canBuy ? "primary" : "secondary"}
					disabled={!canBuy}
					height={36}
				/>
			</frame>
		</Card>
	);
}

// ------- main screen ----------------------------------------------------
export default function ScreenHardware(): React.Element {
	const gs = useGameState();
	const [search, setSearch] = React.useState("");
	const [filter, setFilter] = React.useState<FilterMode>("all");
	const [qty, setQty] = React.useState<1 | 5 | 10>(1);

	const [allTiers] = React.useState<TierEntry[]>(() => {
		const [ok, result] = pcall(tierList);
		return (ok && typeIs(result, "table") ? result : []) as TierEntry[];
	});

	// Client-side filter
	const visibleTiers = allTiers.filter((t) => {
		const q = search.lower();
		if (q !== "" && !t.name.lower().find(q)[0]) return false;
		const owned = gs.owned.get(t.key) ?? 0;
		if (filter === "deployed" && owned === 0) return false;
		if (filter === "available" && owned > 0) return false;
		return true;
	});

	function handleBuy(tier: TierEntry) {
		act("buy", { tier: tier.key, qty });
	}

	return (
		<scrollingframe
			BackgroundColor3={C.canvas}
			BackgroundTransparency={0}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 1, 0)}
			CanvasSize={new UDim2(0, 0, 0, 0)}
			AutomaticCanvasSize={Enum.AutomaticSize.Y}
			ScrollBarThickness={3}
			ScrollBarImageColor3={C.hairline}
			ScrollingDirection={Enum.ScrollingDirection.Y}
		>
			<uilistlayout
				FillDirection={Enum.FillDirection.Vertical}
				Padding={new UDim(0, 10)}
				SortOrder={Enum.SortOrder.LayoutOrder}
			/>
			<uipadding
				PaddingLeft={new UDim(0, 14)}
				PaddingRight={new UDim(0, 14)}
				PaddingTop={new UDim(0, 14)}
				PaddingBottom={new UDim(0, 24)}
			/>

			{/* Page title */}
			<textlabel
				key="PageTitle"
				Text="HARDWARE MARKET"
				Font={Font.bold}
				TextSize={Size.hero}
				TextColor3={C.textPrimary}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 32)}
				TextXAlignment={Enum.TextXAlignment.Left}
				LayoutOrder={1}
			/>

			{/* Search */}
			<frame
				key="SearchWrap"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 40)}
				LayoutOrder={2}
			>
				<TextInput
					placeholder="Search hardware…"
					onChange={(t) => setSearch(t)}
				/>
			</frame>

			{/* Filter row */}
			<frame
				key="FilterRow"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 34)}
				LayoutOrder={3}
			>
				<uilistlayout
					FillDirection={Enum.FillDirection.Horizontal}
					Padding={new UDim(0, 8)}
					SortOrder={Enum.SortOrder.LayoutOrder}
					VerticalAlignment={Enum.VerticalAlignment.Center}
				/>
				<FilterBtn label="All" active={filter === "all"} onClick={() => setFilter("all")} />
				<FilterBtn label="Deployed" active={filter === "deployed"} onClick={() => setFilter("deployed")} />
				<FilterBtn label="Available" active={filter === "available"} onClick={() => setFilter("available")} />
			</frame>

			{/* Qty row */}
			<frame
				key="QtyRow"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 30)}
				LayoutOrder={4}
			>
				<uilistlayout
					FillDirection={Enum.FillDirection.Horizontal}
					Padding={new UDim(0, 6)}
					SortOrder={Enum.SortOrder.LayoutOrder}
					VerticalAlignment={Enum.VerticalAlignment.Center}
				/>
				<textlabel
					Text="QTY"
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.textMuted}
					BackgroundTransparency={1}
					Size={new UDim2(0, 34, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextYAlignment={Enum.TextYAlignment.Center}
				/>
				{QTY_OPTIONS.map((q) => (
					<QtyPill
						key={tostring(q)}
						qty={q}
						active={qty === q}
						onClick={() => setQty(q as 1 | 5 | 10)}
					/>
				))}
			</frame>

			{/* Compute balance */}
			<frame
				key="BalanceRow"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 18)}
				LayoutOrder={5}
			>
				<textlabel
					Text={`Balance: ${fmt(gs.compute)} compute`}
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.compute}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
					TextYAlignment={Enum.TextYAlignment.Center}
				/>
			</frame>

			{/* Tier grid */}
			{visibleTiers.size() === 0 ? (
				<Card height={80} layoutOrder={6}>
					<textlabel
						Text="No hardware matches your filter"
						Font={Font.body}
						TextSize={Size.body}
						TextColor3={C.textMuted}
						BackgroundTransparency={1}
						Size={new UDim2(1, 0, 1, 0)}
						TextXAlignment={Enum.TextXAlignment.Center}
						TextYAlignment={Enum.TextYAlignment.Center}
					/>
				</Card>
			) : (
				<frame
					key="TierGrid"
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 0, 0)}
					AutomaticSize={Enum.AutomaticSize.Y}
					LayoutOrder={6}
				>
					<uigridlayout
						CellSize={new UDim2(0.5, -6, 0, 168)}
						CellPadding={new UDim2(0, 12, 0, 12)}
						SortOrder={Enum.SortOrder.LayoutOrder}
						FillDirection={Enum.FillDirection.Horizontal}
					/>
					{visibleTiers.map((t, i) => (
						<TierCard
							key={t.key}
							tier={t}
							owned={gs.owned.get(t.key) ?? 0}
							qty={qty}
							compute={gs.compute}
							onBuy={() => handleBuy(t)}
							layoutOrder={i + 1}
						/>
					))}
				</frame>
			)}
		</scrollingframe>
	);
}

