-- Fuzzy: simple subsequence-with-gaps scorer, case-insensitive. A query
-- matches a haystack if every query character appears in the haystack in
-- order (not necessarily contiguous); score rewards earlier and more
-- contiguous matches.
local M = {}

function M.score(query: any, haystack: any): number?
	if type(query) ~= "string" or type(haystack) ~= "string" then
		return nil
	end
	if query == "" then
		return 0
	end

	query = string.lower(query)
	haystack = string.lower(haystack)

	local queryLength = #query
	local haystackLength = #haystack
	if queryLength > haystackLength then
		return nil
	end

	local score = 0
	local haystackIndex = 1
	local previousMatchIndex = nil

	for queryIndex = 1, queryLength do
		local char = string.sub(query, queryIndex, queryIndex)
		local foundAt = string.find(haystack, char, haystackIndex, true)
		if not foundAt then
			return nil
		end

		score += math.max(0, 40 - foundAt)
		if previousMatchIndex and foundAt == previousMatchIndex + 1 then
			score += 15
		end

		previousMatchIndex = foundAt
		haystackIndex = foundAt + 1
	end

	score += 20 * (queryLength / haystackLength)

	return score
end

function M.matches(query: string, haystack: string): boolean
	return M.score(query, haystack) ~= nil
end

return M
