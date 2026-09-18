local ShopService = {}

local function find(entries, key)
    for _, entry in ipairs(entries) do
        if entry.key == key then
            return entry
        end
    end
    return nil
end

function ShopService.quote(config, state, key)
    local offer = find(config.ShopOffers, key)
    if not offer then
        return nil, "Unknown package"
    end

    local tier = find(config.Tiers, offer.tier)
    if not tier or config.units(state) < tier.unlock then
        return nil, "Grow your fleet to unlock"
    end

    local owned = state.owned[tier.key] or 0
    if owned + offer.quantity > 200 then
        return nil, "Fleet capacity reached"
    end

    local total = 0
    for offset = 0, offer.quantity - 1 do
        total += config.buyCost(tier, owned + offset, state)
    end

    return math.max(1, math.floor(total * (1 - (offer.discount or 0.05)))), nil, offer, tier
end

function ShopService.purchase(config, state, key)
    local price, reason, offer, tier = ShopService.quote(config, state, key)
    if not price then
        return false, reason
    end

    if state.compute < price then
        return false, "More compute needed."
    end

    state.compute -= price
    state.owned[tier.key] = (state.owned[tier.key] or 0) + offer.quantity
    return true, offer.name .. " deployed · " .. offer.quantity .. " servers online"
end

return ShopService
