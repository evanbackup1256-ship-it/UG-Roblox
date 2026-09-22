// screens/ScreenAllocations.tsx — Daily rewards + streak + achievements

import React from "@rbxts/react";
import { C, R, Font, Size } from "../theme";
import { Card } from "../ui/Card";
import { Button } from "../ui/Button";
import { ProgressBar } from "../ui/ProgressBar";
import { useGameState } from "../hooks";
import { act, fmt } from "../store";

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

interface DayReward {
	day: number;
	label: string;
	icon: string;
}

const DAY_REWARDS: DayReward[] = [
	{ day: 1, label: "+500 ⚡",   icon: "⚡" },
	{ day: 2, label: "+1K ◈",    icon: "◈" },
	{ day: 3, label: "+2K ⚡",   icon: "⚡" },
	{ day: 4, label: "+50 ⚙",    icon: "⚙" },
	{ day: 5, label: "+5K ⚡",   icon: "⚡" },
	{ day: 6, label: "+200 ◈",   icon: "◈" },
	{ day: 7, label: "✦ 1 Prestige", icon: "✦" },
];

interface AchievementDef {
	id: string;
	name: string;
	description: string;
	icon: string;
	target: number;
	getValue: (compute: number, jobs: number, totalEarned: number) => number;
}

const ACHIEVEMENTS: AchievementDef[] = [
	{
		id: "first_job",
		name: "First Job",
		description: "Dispatch your first compute job.",
		icon: "🖥",
		target: 1,
		getValue: (_, jobs) => jobs,
	},
	{
		id: "kilowatt",
		name: "Kilowatt Club",
		description: "Earn 1,000 compute total.",
		icon: "⚡",
		target: 1_000,
		getValue: (_, __, total) => total,
	},
	{
		id: "megawatt",
		name: "Megawatt Tier",
		description: "Earn 1,000,000 compute total.",
		icon: "🔋",
		target: 1_000_000,
		getValue: (_, __, total) => total,
	},
	{
		id: "gigawatt",
		name: "Gigawatt Empire",
		description: "Earn 1,000,000,000 compute total.",
		icon: "🌐",
		target: 1_000_000_000,
		getValue: (_, __, total) => total,
	},
	{
		id: "century_jobs",
		name: "Century Operator",
		description: "Dispatch 100 compute jobs.",
		icon: "📡",
		target: 100,
		getValue: (_, jobs) => jobs,
	},
	{
		id: "hyperscale",
		name: "Hyperscale",
		description: "Dispatch 1,000 compute jobs.",
		icon: "🚀",
		target: 1_000,
		getValue: (_, jobs) => jobs,
	},
];

// ---------------------------------------------------------------------------
// Day reward box
// ---------------------------------------------------------------------------

interface DayBoxProps {
	reward: DayReward;
	claimed: boolean;
	isToday: boolean;
}

function DayBox({ reward, claimed, isToday }: DayBoxProps) {
	const bg = claimed
		? Color3.fromRGB(14, 28, 20)
		: isToday
			? Color3.fromRGB(36, 28, 12)
			: C.recessed;

	const border = claimed
		? C.compute
		: isToday
			? C.energy
			: C.hairline;

	const borderAlpha = claimed ? 0.35 : isToday ? 0.3 : 0.72;

	return (
		<frame
			key={`day${tostring(reward.day)}`}
			BackgroundColor3={bg}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 1, 0)}
		>
			<uicorner CornerRadius={new UDim(0, R.control)} />
			<uistroke Color={border} Thickness={isToday ? 2 : 1} Transparency={borderAlpha} />

			{/* Amber glow for today */}
			{isToday && (
				<frame
					key="Glow"
					BackgroundColor3={C.energy}
					BackgroundTransparency={0.88}
					BorderSizePixel={0}
					Size={new UDim2(1, 0, 1, 0)}
					ZIndex={1}
				>
					<uicorner CornerRadius={new UDim(0, R.control)} />
				</frame>
			)}

			<textlabel
				key="DayNum"
				Text={`DAY ${tostring(reward.day)}`}
				Font={Font.mono}
				TextSize={Size.micro}
				TextColor3={isToday ? C.energy : C.textMuted}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 14)}
				Position={new UDim2(0, 0, 0, 8)}
				TextXAlignment={Enum.TextXAlignment.Center}
				ZIndex={2}
			/>

			<textlabel
				key="Icon"
				Text={claimed ? "✓" : reward.icon}
				Font={Font.bold}
				TextSize={24}
				TextColor3={claimed ? C.compute : isToday ? C.energy : C.textSecondary}
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 30)}
				Position={new UDim2(0, 0, 0, 26)}
				TextXAlignment={Enum.TextXAlignment.Center}
				ZIndex={2}
			/>

			<textlabel
				key="Label"
				Text={claimed ? "Claimed" : reward.label}
				Font={Font.mono}
				TextSize={Size.micro}
				TextColor3={claimed ? C.compute : C.textSecondary}
				BackgroundTransparency={1}
				Size={new UDim2(1, -4, 0, 14)}
				Position={new UDim2(0, 2, 0, 60)}
				TextXAlignment={Enum.TextXAlignment.Center}
				TextWrapped={true}
				ZIndex={2}
			/>
		</frame>
	);
}

// ---------------------------------------------------------------------------
// Achievement row
// ---------------------------------------------------------------------------

interface AchievementRowProps {
	ach: AchievementDef;
	value: number;
	unlocked: boolean;
	layoutOrder: number;
}

function AchievementRow({ ach, value, unlocked, layoutOrder }: AchievementRowProps) {
	const progress = math.clamp(value / ach.target, 0, 1);

	return (
		<frame
			key={ach.id}
			BackgroundColor3={unlocked ? Color3.fromRGB(14, 24, 18) : C.card}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 0, 72)}
			LayoutOrder={layoutOrder}
		>
			<uicorner CornerRadius={new UDim(0, R.card)} />
			<uistroke
				Color={unlocked ? C.compute : C.hairline}
				Thickness={1}
				Transparency={unlocked ? 0.4 : 0.72}
			/>
			<uipadding
				PaddingLeft={new UDim(0, 14)}
				PaddingRight={new UDim(0, 14)}
				PaddingTop={new UDim(0, 12)}
				PaddingBottom={new UDim(0, 12)}
			/>

			{/* Icon */}
			<textlabel
				key="Icon"
				Text={ach.icon}
				Font={Font.bold}
				TextSize={22}
				TextColor3={unlocked ? C.compute : C.textMuted}
				BackgroundTransparency={1}
				Size={new UDim2(0, 36, 0, 36)}
				Position={new UDim2(0, 14, 0.5, -18)}
				TextXAlignment={Enum.TextXAlignment.Center}
				ZIndex={3}
			/>

			{/* Name + desc */}
			<textlabel
				key="Name"
				Text={ach.name}
				Font={Font.bold}
				TextSize={Size.body}
				TextColor3={unlocked ? C.textPrimary : C.textSecondary}
				BackgroundTransparency={1}
				Size={new UDim2(1, -140, 0, 18)}
				Position={new UDim2(0, 58, 0, 12)}
				TextXAlignment={Enum.TextXAlignment.Left}
				ZIndex={3}
			/>
			<textlabel
				key="Desc"
				Text={ach.description}
				Font={Font.body}
				TextSize={Size.caption}
				TextColor3={C.textMuted}
				BackgroundTransparency={1}
				Size={new UDim2(1, -140, 0, 14)}
				Position={new UDim2(0, 58, 0, 32)}
				TextXAlignment={Enum.TextXAlignment.Left}
				ZIndex={3}
			/>

			{/* Progress bar + value */}
			<frame
				key="PbarWrap"
				BackgroundTransparency={1}
				Size={new UDim2(1, -140, 0, 6)}
				Position={new UDim2(0, 58, 0, 52)}
				ZIndex={3}
			>
				<ProgressBar progress={progress} color={unlocked ? C.compute : C.accent} height={4} />
			</frame>

			{/* Progress text */}
			<textlabel
				key="ProgText"
				Text={unlocked ? "✓ UNLOCKED" : `${fmt(math.min(value, ach.target))} / ${fmt(ach.target)}`}
				Font={Font.mono}
				TextSize={Size.micro}
				TextColor3={unlocked ? C.compute : C.textMuted}
				BackgroundTransparency={1}
				Size={new UDim2(0, 110, 1, 0)}
				Position={new UDim2(1, -110, 0, 0)}
				TextXAlignment={Enum.TextXAlignment.Right}
				ZIndex={3}
			/>
		</frame>
	);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

export default function ScreenAllocations(): React.Element {
	const state = useGameState();
	const claimed  = state.claimed  ?? new Map<string, boolean>();
	const achievements = state.achievements ?? new Map<string, boolean>();

	// Derive streak from claimed daily keys "daily_1" … "daily_7"
	let streak = 0;
	for (let d = 1; d <= 7; d++) {
		if (claimed.get(`daily_${tostring(d)}`) === true) streak = d;
		else break;
	}
	const todayIdx = streak; // 0-based, so today is DAY streak+1 (or day 1 if none)
	const todayDay = math.min(streak + 1, 7);
	const canClaim = !claimed.get(`daily_${tostring(todayDay)}`);

	return (
		<scrollingframe
			BackgroundTransparency={1}
			BorderSizePixel={0}
			Size={new UDim2(1, 0, 1, 0)}
			CanvasSize={new UDim2(0, 0, 0, 0)}
			AutomaticCanvasSize={Enum.AutomaticSize.Y}
			ScrollBarThickness={3}
			ScrollBarImageColor3={C.accent}
			ScrollBarImageTransparency={0.5}
		>
			<uilistlayout
				FillDirection={Enum.FillDirection.Vertical}
				Padding={new UDim(0, 12)}
				SortOrder={Enum.SortOrder.LayoutOrder}
				HorizontalAlignment={Enum.HorizontalAlignment.Center}
			/>
			<uipadding
				PaddingLeft={new UDim(0, 16)}
				PaddingRight={new UDim(0, 16)}
				PaddingTop={new UDim(0, 16)}
				PaddingBottom={new UDim(0, 24)}
			/>

			{/* Page title */}
			<frame key="Title" BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 32)} LayoutOrder={0}>
				<textlabel
					Text="DAILY ALLOCATION"
					Font={Font.bold}
					TextSize={Size.hero}
					TextColor3={C.textPrimary}
					BackgroundTransparency={1}
					Size={new UDim2(1, 0, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
				/>
			</frame>

			{/* Streak card */}
			<frame
				key="StreakCard"
				BackgroundColor3={Color3.fromRGB(28, 22, 10)}
				BorderSizePixel={0}
				Size={new UDim2(1, 0, 0, 90)}
				LayoutOrder={1}
			>
				<uicorner CornerRadius={new UDim(0, R.card)} />
				<uistroke Color={C.energy} Thickness={1} Transparency={0.35} />

				{/* Flame icon */}
				<textlabel
					key="Flame"
					Text="🔥"
					Font={Font.bold}
					TextSize={36}
					BackgroundTransparency={1}
					Size={new UDim2(0, 50, 1, 0)}
					Position={new UDim2(0, 16, 0, 0)}
					TextXAlignment={Enum.TextXAlignment.Center}
					TextYAlignment={Enum.TextYAlignment.Center}
				/>

				{/* Streak count */}
				<textlabel
					key="Count"
					Text={tostring(streak)}
					Font={Font.bold}
					TextSize={40}
					TextColor3={C.energy}
					BackgroundTransparency={1}
					Size={new UDim2(0, 60, 0, 48)}
					Position={new UDim2(0, 74, 0, 21)}
					TextXAlignment={Enum.TextXAlignment.Left}
					ZIndex={3}
				/>

				<textlabel
					key="StreakLabel"
					Text="day streak"
					Font={Font.body}
					TextSize={Size.caption}
					TextColor3={C.textSecondary}
					BackgroundTransparency={1}
					Size={new UDim2(0, 80, 0, 16)}
					Position={new UDim2(0, 74, 0, 62)}
					TextXAlignment={Enum.TextXAlignment.Left}
					ZIndex={3}
				/>

				{/* Day progress */}
				<textlabel
					key="DayOf"
					Text={`Day ${tostring(todayDay)} of 7`}
					Font={Font.mono}
					TextSize={Size.section}
					TextColor3={C.textPrimary}
					BackgroundTransparency={1}
					Size={new UDim2(0, 140, 0, 24)}
					Position={new UDim2(1, -156, 0, 14)}
					TextXAlignment={Enum.TextXAlignment.Right}
					ZIndex={3}
				/>

				<textlabel
					key="NextLabel"
					Text={streak >= 7 ? "Full week complete!" : "Keep logging in daily"}
					Font={Font.body}
					TextSize={Size.caption}
					TextColor3={C.textMuted}
					BackgroundTransparency={1}
					Size={new UDim2(0, 160, 0, 16)}
					Position={new UDim2(1, -176, 0, 44)}
					TextXAlignment={Enum.TextXAlignment.Right}
					ZIndex={3}
				/>
			</frame>

			{/* 7-day reward grid */}
			<frame
				key="DayGrid"
				BackgroundTransparency={1}
				Size={new UDim2(1, 0, 0, 90)}
				LayoutOrder={2}
			>
				<uigridlayout
					CellSize={new UDim2(1 / 7, -4, 1, 0)}
					CellPadding={new UDim2(0, 4, 0, 0)}
					SortOrder={Enum.SortOrder.LayoutOrder}
					StartCorner={Enum.StartCorner.TopLeft}
					FillDirection={Enum.FillDirection.Horizontal}
				/>
				{DAY_REWARDS.map((r) => {
					const isClaimed = claimed.get(`daily_${tostring(r.day)}`) === true;
					const isToday   = r.day === todayDay && !isClaimed;
					return (
						<DayBox key={`day${tostring(r.day)}`} reward={r} claimed={isClaimed} isToday={isToday} />
					);
				})}
			</frame>

			{/* Claim button */}
			<frame key="ClaimBtn" BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 44)} LayoutOrder={3}>
				<Button
					label={canClaim ? `Claim Day ${tostring(todayDay)} Reward` : "Already Claimed Today"}
					onClick={() => {
						if (canClaim) act("claim");
					}}
					variant={canClaim ? "amber" : "secondary"}
					height={44}
					disabled={!canClaim}
				/>
			</frame>

			{/* Achievements section header */}
			<frame key="AchHeader" BackgroundTransparency={1} Size={new UDim2(1, 0, 0, 28)} LayoutOrder={4}>
				<textlabel
					Text="ACHIEVEMENTS"
					Font={Font.bold}
					TextSize={Size.section}
					TextColor3={C.textPrimary}
					BackgroundTransparency={1}
					Size={new UDim2(0.6, 0, 1, 0)}
					TextXAlignment={Enum.TextXAlignment.Left}
				/>
				<textlabel
					Text={`${tostring(ACHIEVEMENTS.reduce((n, a) => n + (achievements.get(a.id) ? 1 : 0), 0))} / ${tostring(ACHIEVEMENTS.size())} unlocked`}
					Font={Font.mono}
					TextSize={Size.caption}
					TextColor3={C.textMuted}
					BackgroundTransparency={1}
					Size={new UDim2(0.4, 0, 1, 0)}
					Position={new UDim2(0.6, 0, 0, 0)}
					TextXAlignment={Enum.TextXAlignment.Right}
				/>
			</frame>

			{ACHIEVEMENTS.map((ach, i) => {
				const unlocked = achievements.get(ach.id) === true;
				const value    = ach.getValue(state.compute, state.jobs, state.totalEarned);
				return (
					<AchievementRow
						key={ach.id}
						ach={ach}
						value={value}
						unlocked={unlocked}
						layoutOrder={5 + i}
					/>
				);
			})}
		</scrollingframe>
	);
}

