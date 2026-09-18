local Validation = {}

function Validation.number(value: any, defaultValue: number, maximum: number?): number
    if type(value) ~= "number" or value ~= value or value == math.huge or value < 0 then
        return defaultValue
    end
    return math.min(value, maximum or 1e18)
end

function Validation.preference(defaultValue: any, value: any): any
    if type(defaultValue) == "boolean" then
        if type(value) == "boolean" then
            return value
        end
        return nil
    end
    if type(defaultValue) == "number" and type(value) == "number" and value == value then
        return math.clamp(value, 0, 1)
    end
    return nil
end

function Validation.key(value: any): string?
    if type(value) ~= "string" or #value < 1 or #value > 64 then
        return nil
    end
    return value
end

return Validation
