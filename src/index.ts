// index.client.ts — Roblox client entrypoint
// Mounts the React app, wires state from the server.

import React from "@rbxts/react";
import { createRoot } from "@rbxts/react-roblox";
import { ReplicatedStorage, Players, RunService } from "@rbxts/services";
import { setState, getState } from "./store";
import { App } from "./components/App";

const player = Players.LocalPlayer;
const playerGui = player.WaitForChild("PlayerGui");

// Fetch initial state
const DeckGame = ReplicatedStorage.WaitForChild("DeckGame");
const GetState = DeckGame.WaitForChild("GetState") as RemoteFunction;
const Changed = DeckGame.WaitForChild("Changed") as RemoteEvent;

const initialState = GetState.InvokeServer() as object;
if (initialState) setState(initialState as never);

// Subscribe to server-pushed state changes
Changed.OnClientEvent.Connect((newState: unknown) => {
	if (newState) setState(newState as never);
});

// Create ScreenGui
const gui = new Instance("ScreenGui");
gui.Name = "DeckReactApp";
gui.ResetOnSpawn = false;
gui.DisplayOrder = 10;
gui.IgnoreGuiInset = false;
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
gui.Parent = playerGui;

// Mount React tree
const root = createRoot(gui);
root.render(React.createElement(App, {}));

