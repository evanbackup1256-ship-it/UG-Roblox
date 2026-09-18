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

require(ServerScriptService:WaitForChild("DeckServer"):WaitForChild("ServerController"))
