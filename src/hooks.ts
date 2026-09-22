// hooks.ts — Custom React hooks

import React from "@rbxts/react";
import { getState, subscribe, PlayerState } from "./store";

/** Subscribe to the global game state and re-render on changes. */
export function useGameState(): PlayerState {
	const [state, setReactState] = React.useState(getState);
	React.useEffect(() => {
		return subscribe((newState: PlayerState) => setReactState(newState));
	}, []);
	return state;
}

/** Returns a TweenService-based spring value animator for a GuiObject ref.
 *  Returns a callback: call it with target properties to tween. */
export function useTween(
	ref: React.RefObject<GuiObject>,
	info: TweenInfo,
) {
	return (props: { [key: string]: unknown }) => {
		const obj = ref.current;
		if (!obj) return;
		const TweenService = game.GetService("TweenService");
		TweenService.Create(obj as Instance, info, props as { [key: string]: unknown }).Play();
	};
}

