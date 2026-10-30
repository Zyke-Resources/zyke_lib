Functions.table = {}

---@param tbl table
---@return table
function Functions.table.copy(tbl)
    local copy = {}

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = Functions.table.copy(v)
        else
            copy[k] = v
        end
    end

    return copy
end

-- A table met again inside its own copy, a cycle or json.decode's metatable on FXServer 35186 to 35245, gets the copy
-- being built instead of overflowing the stack. A table met again anywhere else is copied apart as before
---@param value any
---@param building table<table, table> @ Tables still being copied, to their copy
---@return any copy
local function copyValue(value, building)
    if (type(value) ~= "table") then return value end
    if (building[value]) then return building[value] end

    local copy = {}
    building[value] = copy

    for origKey, origValue in next, value, nil do
        copy[copyValue(origKey, building)] = copyValue(origValue, building)
    end

    setmetatable(copy, copyValue(getmetatable(value), building))

    building[value] = nil

    return copy
end

---@param tbl table
---@return table copy
function Functions.table.deepCopy(tbl)
    return copyValue(tbl, {})
end

---@param tbl table
---@return integer
function Functions.table.count(tbl)
    if (not tbl) then
        Functions.debug.internal("Attempted to count", type(tbl), "table.")

        return 0
    end

    local count = 0

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

---@param tbl table -- Needs to be an array
---@param desiredString string | string[]
---@return boolean, number | nil
function Functions.table.contains(tbl, desiredString)
    if (not tbl) then error("Attempt to scan non-existent table") end
    if (#tbl == 0) then return false, nil end
    if (not desiredString or #desiredString == 0) then return false, nil end

    if (type(desiredString) == "string") then
        desiredString = {desiredString}
    end

    for i = 1, #tbl do
        for j = 1, #desiredString do
            if (tbl[i] == desiredString[j]) then
                return true, i
            end
        end
    end

    return false, nil
end

---@param tbl table
---@param predicate function
---@return any, number | string | nil
function Functions.table.find(tbl, predicate)
    if (not tbl) or (type(tbl) ~= "table") then error("Attempt to scan non-existent table") end

    for key, value in pairs(tbl) do
        if (predicate(value)) then
            return value, key
        end
    end

    return nil, nil
end

---@param tbl1 table
---@param tbl2 table
---@return table
function Functions.table.combine(tbl1, tbl2)
    local result = {}

    for k, v in pairs(tbl1) do
        result[k] = v
    end

    for k, v in pairs(tbl2) do
        result[k] = v
    end

    return result
end

---@param tbl table
---@return string
function Functions.table.getRandomDictionaryKey(tbl)
    local keys = {}

    for key, _ in pairs(tbl) do
        keys[#keys+1] = key
    end

    return keys[math.random(1, #keys)]
end

---@param tbl any[]
---@return table any[]
function Functions.table.ensureUniqueEntries(tbl)
    local seen = {}
    local uniqueEntries = {}

    for _, value in pairs(tbl) do
        if not (seen[value]) then
            table.insert(uniqueEntries, value)
            seen[value] = true
        end
    end

    return uniqueEntries
end

---@param tbl table
---@return boolean
function Functions.table.isArray(tbl)
    if (next(tbl) == nil) then return false end

    for key in pairs(tbl) do
        if (type(key) ~= "number") then return false end
    end

    return true
end

---@param tbl table
---@return boolean
function Functions.table.doesTableHaveEntries(tbl)
    for _ in pairs(tbl) do return true end

    return false
end

---@param tbl table
---@return string | number | nil
function Functions.table.getFirstDictionaryKey(tbl)
    for key in pairs (tbl) do return key end

    return nil
end

-- Filter out keys in a table without modifying the original reference
-- Mainly used to construct new metadata and remove keys such as long descriptions
---@param newTbl table
---@param orgTbl table
---@param keys string[]
function Functions.table.filterKeys(newTbl, orgTbl, keys)
    for key, value in pairs(orgTbl) do
        if (not Z.table.contains(keys, key)) then
            if type(value) == "table" then
                newTbl[key] = {}
                Functions.table.filterKeys(newTbl[key], value, keys)
            else
                newTbl[key] = value
            end
        end
    end
end

-- Experimental metatable testing
---@param value table
---@return metatable
function Functions.table.new(value)
    local tbl = value or {}

    local methods = {
        ---@param toAppend table
        append = function(self, toAppend)
            for _, val in ipairs(toAppend) do
                table.insert(self, val)
            end
        end,

        ---@param name string
        contains = function(self, name)
            for k, v in pairs(self) do
                if (v == name) then
                    return true
                end
            end

            return false
        end,

        forEach = function(self, func)
            for k, v in pairs(self) do
                func(v, k)
            end
        end,

        ---@return integer
        count = function(self)
            local num = 0

            for _ in pairs(self) do num += 1 end

            return num
        end,

        ---@return boolean
        isArray = function(self)
            return Functions.table.isArray(self)
        end,

        ---@return boolean
        isEmpty = function(self)
            return not Functions.table.doesTableHaveEntries(self)
        end
    }

    setmetatable(tbl, {
        __index = methods
    })

    return tbl
end

return Functions.table