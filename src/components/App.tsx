// App.tsx — Root React component: screen router, nav state, transitions

import React from "@rbxts/react";
import { C, R } from "../theme";
import { useGameState } from "../hooks";
import TopBar from "./TopBar";
import NavDock from "./NavDock";
import Toast from "./Toast";
import SearchPalette from "./SearchPalette";

// Lazy-import screens (all resolved at require time, not lazy in Lua sense)
import ScreenCommand from "../screens/ScreenCommand";
import ScreenOperations from "../screens/ScreenOperations";
import ScreenHardware from "../screens/ScreenHardware";
import ScreenResearch from "../screens/ScreenResearch";
import ScreenSubsystems from "../screens/ScreenSubsystems";
import ScreenContracts from "../screens/ScreenContracts";
import ScreenAllocations from "../screens/ScreenAllocations";
import ScreenMarket from "../screens/ScreenMarket";
import ScreenSingularity from "../screens/ScreenSingularity";
import ScreenTerminal from "../screens/ScreenTerminal";
import ScreenStandings from "../screens/ScreenStandings";
import ScreenPreferences from "../screens/ScreenPreferences";

const SCREENS: Record<string, () => React.Element> = {
	overview:       ScreenCommand,
	operations:     ScreenOperations,
	infrastructure: ScreenHardware,
	research:       ScreenResearch,
	modules:        ScreenSubsystems,
	contracts:      ScreenContracts,
	rewards:        ScreenAllocations,
	shop:           ScreenMarket,
	prestige:       ScreenSingularity,
	events:         ScreenTerminal,
	leaderboard:    ScreenStandings,
	settings:       ScreenPreferences,
};

const SCREEN_BREADCRUMBS: Record<string, string> = {
	overview:       "FLEET // COMMAND",
	operations:     "FLEET // DISPATCH",
	infrastructure: "FLEET // HARDWARE",
	research:       "LAB // RESEARCH",
	modules:        "LAB // SUBSYSTEMS",
	contracts:      "ENTERPRISE // WORK ORDERS",
	rewards:        "FLEET // ALLOCATIONS",
	shop:           "SUPPLY // PROCUREMENT",
	prestige:       "QUANTUM // RELAUNCH",
	events:         "NETWORK // TERMINAL",
	leaderboard:    "FLEET // STANDINGS",
	settings:       "SYSTEM // PREFERENCES",
};

const TRANS_INFO = new TweenInfo(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out);
const Players = game.GetService("Players");
const player = Players.LocalPlayer;

export function App() {
	const state = useGameState();
	const [activeScreen, setActiveScreen] = React.useState("overview");
	const [searchOpen, setSearchOpen] = React.useState(false);
	const contentRef = React.createRef<Frame>();
	const prevScreen = React.useRef("overview");

	const navigate = (screen: string) => {
		if (screen === activeScreen) return;

		// Slide-out current screen
		const content = contentRef.current;
		if (content) {
			game.GetService("TweenService")
				.Create(content, TRANS_INFO, {
					Position: new UDim2(-0.08, 0, 0, 0),
					BackgroundTransparency: 1,
				})
				.Play();
		}

		task.delay(0.18, () => {
			prevScreen.current = activeScreen;
			setActiveScreen(screen);

			// Slide in new screen from right
			task.defer(() => {
				const c = contentRef.current;
				if (!c) return;
				c.Position = new UDim2(0.08, 0, 0, 0);
				c.BackgroundTransparency = 0;
				game.GetService("TweenService")
					.Create(c, TRANS_INFO, { Position: new UDim2(0, 0, 0, 0) })
					.Play();
			});
		});
	};

	const ScreenComponent = SCREENS[activeScreen] ?? ScreenCommand;
	const breadcrumb = SCREEN_BREADCRUMBS[activeScreen] ?? "FLEET // COMMAND";

	const energyCap = 100; // TODO: wire from Config
	const energy = math.clamp(state.energy ?? 100, 0, energyCap);

	return (
		<frame
			key="AppRoot"
			Size={new UDim2(1, 0, 1, 0)}
			BackgroundColor3={C.canvas}
			BorderSizePixel={0}
		>
			{/* Top bar */}
			<TopBar
				activeScreen={activeScreen}
				callsign={state.callsign ?? player.DisplayName}
				compute={state.compute ?? 0}
				computeRate={0}
				energy={energy}
				energyCap={energyCap}
				data={state.data ?? 0}
				onSearchOpen={() => setSearchOpen(true)}
			/>

			{/* Navigation dock */}
			<NavDock activeScreen={activeScreen} onNavigate={navigate} />

			{/* Main content area */}
			<frame
				ref={contentRef}
				key="ContentArea"
				BackgroundTransparency={1}
				BorderSizePixel={0}
				// Positioned to the right of the nav dock on desktop
				Size={new UDim2(1, -72, 1, -56)}
				Position={new UDim2(0, 72, 0, 56)}
				ClipsDescendants={true}
			>
				<ScreenComponent />
			</frame>

			{/* Toast layer */}
			<Toast />

			{/* Search palette modal */}
			<SearchPalette
				visible={searchOpen}
				onClose={() => setSearchOpen(false)}
				onNavigate={(s: string) => { navigate(s); setSearchOpen(false); }}
			/>
		</frame>
	);
}

