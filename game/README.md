# Deck Empire

This folder mirrors the live Studio scripts for Deck Empire.

## Layout

- `Client.luau` starts the live `ClientController`.
- Shared modules are placed directly in `ReplicatedStorage.DeckGame`.
- `Server.luau` starts `DeckServer.ServerController`; `Framework.luau` and `PersistenceService.luau` remain in that server folder.
- `default.project.json` maps the folder to the same Studio hierarchy for Rojo-based sync.

## Dependencies

The live place uses Trove and ProfileStore. Fluid is not part of the current live codebase.

## Verification

Run `npm run validate` to check the local content validation script, then use a Studio Play test to verify runtime behavior.
