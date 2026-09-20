-- Fuzzy: simple subsequence-with-gaps scorer, case-insensitive. Not full
-- Levenshtein/edit-distance — overkill for the short catalogue names this
-- backs (tier/research/module/shop/contract/achievement names, all a few
-- words). A query matches a haystack if every query character appears in
-- the haystack in order (not necessarily contiguous); the score rewards
-- matches that start earlier and run more contiguously, so "grid" ranks
-- "Fusion grid" above a haystack where the letters are more spread out.
local M = {}

-- Returns a score (higher is better) or nil if the query's characters
-- don't all appear in order within haystack. Both inputs are matched
-- case-insensitively; callers should pass already-lowercased strings when
-- comparing many haystacks against the same query repeatedly, to avoid
-- re-lowercasing the query on every call.
function M.score(query: string, haystack: string): number?
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

		-- Earlier matches score higher (a match starting at haystack
		-- position 1 is worth more than one starting at position 20).
		score += math.max(0, 40 - foundAt)

		-- Consecutive characters (foundAt immediately follows the
		-- previous match) score a contiguity bonus, so a tight run of
		-- matched letters outranks the same letters scattered apart.
		if previousMatchIndex and foundAt == previousMatchIndex + 1 then
			score += 15
		end

		previousMatchIndex = foundAt
		haystackIndex = foundAt + 1
	end

	-- Bonus for the match consuming a larger fraction of the haystack
	-- (favors shorter, more precisely-matched names over long ones that
	-- happen to also contain the query as a sparse subsequence).
	score += 20 * (queryLength / haystackLength)

	return score
end

function M.matches(query: string, haystack: string): boolean
	return M.score(query, haystack) ~= nil
end

return M
