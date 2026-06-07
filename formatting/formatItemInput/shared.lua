-- Formatting inputted items to easily handle them throughout the library
-- Should probably just learn to use the same names for everything to avoid this, but it is what it is

-- VERIFY: MULTI METADATA SUPPORT

---@class InputtedItem
---@field name string
---@field amount? integer
---@field metadata table?

---@param item string | table
---@param amount? integer
---@return InputtedItem[] | Item[], string[]
function Formatting.formatItemInput(item, amount, metadata)
    ---@param itemData table
    ---@return Item
    local function formatInputItem(itemData)
        local formattedItem = Formatting.formatItem(itemData)
        if (formattedItem.name) then
            local _, itemName = Functions.getItem(formattedItem.name)
            if (itemName) then formattedItem.name = itemName end
        end

        return formattedItem
    end

    ---@type InputtedItem[] | Item[]
    local formattedItems = {}

    ---@type string[] @Array of included item names
    local included = {}

    if (type(item) == "string") then -- Simple add to the table and return
        formattedItems[#formattedItems+1] = formatInputItem({name = item, amount = amount or 1, metadata = metadata})
    else
        -- Check for various table structures
        local isArray = Functions.table.isArray(item)
        if (not isArray) then
            item = {item}
        end

        for k, v in pairs(item) do
            local isKeyName = type(k) == "string" -- Check for item:amount

            if (isKeyName) then
                local _name = k
                local _amount = isKeyName and v or 1

                ---@diagnostic disable-next-line: assign-type-mismatch
                formattedItems[#formattedItems+1] = formatInputItem({name = _name, amount = _amount})
            else
                formattedItems[#formattedItems+1] = formatInputItem(v)
            end
        end
    end

    for i = 1, #formattedItems do
        included[#included+1] = formattedItems[i].name
    end

    return formattedItems, included
end

return Formatting.formatItemInput