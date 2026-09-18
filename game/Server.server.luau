local ServerScriptService = game:GetService("ServerScriptService")

-- Nevermore packages (ServiceBag/Maid/Signal/BaseObject) resolve their own
-- cross-package requires via require(script.Parent.loader).load(script),
-- which only works once Loader.bootstrapGame has walked node_modules and
-- created those "loader" link modules next to every package. Must run
-- before anything requires ServiceBag/Maid/Signal — first thing here.
-- Server-only package set (this migration adds no client-side ServiceBag),
-- so the packages start private under ServerScriptService; in Studio,
-- bootstrapGame's fast path reparents this folder to ReplicatedStorage as
-- part of populating it — that relocation is expected Nevermore behavior,
-- not a bug, and does not affect anything server-only that requires it by
-- reference rather than by a path assumption.
local packages = ServerScriptService:WaitForChild("node_modules"):WaitForChild("@quenty")
local Loader = require(packages:WaitForChild("loader"))
Loader.bootstrapGame(packages)

-- Resolved here, right after bootstrap, via the live `packages` reference
-- rather than a fresh path lookup from ServerController: bootstrapGame's
-- Studio fast path reparents `packages` itself to ReplicatedStorage as a
-- side effect of populating it (real Nevermore behavior — see the comment
-- above), so a fresh ServerScriptService.node_modules... lookup done later
-- would hang forever in Studio specifically. `packages` stays a valid
-- reference regardless of where its Parent ends up.
local ServiceBag = require(packages:WaitForChild("servicebag"):WaitForChild("Shared"):WaitForChild("ServiceBag"))
local Maid = require(packages:WaitForChild("maid"):WaitForChild("Shared"):WaitForChild("Maid"))

local ServerController = require(ServerScriptService:WaitForChild("DeckServer"):WaitForChild("ServerController"))
ServerController.start(ServiceBag, Maid)
