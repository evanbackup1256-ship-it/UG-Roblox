# Deck Empire

This folder mirrors the live Studio scripts for Deck Empire.

## Layout

- `Client.luau` starts the live `ClientController`.
- Shared modules are placed directly in `ReplicatedStorage.DeckGame`.
- `Server.luau` bootstraps the Nevermore package tree (`Loader.bootstrapGame`) then starts `DeckServer.ServerController`; `PersistenceService.luau` remains in that server folder.
- `default.project.json` maps the folder to the same Studio hierarchy for Rojo-based sync.

## Dependencies

The server DI kernel is Nevermore's `ServiceBag` (`@quenty/servicebag`, npm-installed under `node_modules/@quenty`, Rojo-mounted under `ServerScriptService.node_modules`). `SessionService`/`ProductionService` are registered as ServiceBag services; each owns its own Nevermore `Maid` for connection cleanup instead of a shared kernel-managed Trove. `ActionService` and `LeaderboardService` are plain constructed modules with no ServiceBag registration (no cross-service dependency needs the lifecycle ordering).

ProfileStore (`ServerPackages/ProfileStore.lua`) remains the save-data layer, unchanged. Trove (`Packages/Trove.lua`) is still Wally-vendored but no longer required anywhere — the old `Framework.luau` kernel it backed was replaced and removed in this migration; safe to drop from `wally.toml` in a future pass if nothing picks it back up.

## Verification

Run `npm run validate` to check the local content validation script, then use a Studio Play test to verify runtime behavior.
