local NetworkService = {}

local REMOTES = {
	{className = "RemoteFunction", name = "GetState"},
	{className = "RemoteFunction", name = "Action"},
	{className = "RemoteEvent", name = "Changed"},
	{className = "RemoteEvent", name = "Preferences"},
	{className = "RemoteFunction", name = "Ping"},
	{className = "RemoteFunction", name = "Leaderboard"},
}

function NetworkService.remote(folder, className, name)
	local existing = folder:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local remote = Instance.new(className)
	remote.Name = name
	remote:SetAttribute("DeckProtocol", 2)
	remote.Parent = folder
	return remote
end

function NetworkService.bind(folder)
	local bound = {}

	for _, definition in ipairs(REMOTES) do
		local key = string.lower(string.sub(definition.name, 1, 1)) .. string.sub(definition.name, 2)
		bound[key] = NetworkService.remote(folder, definition.className, definition.name)
	end

	return table.freeze(bound)
end

return NetworkService
