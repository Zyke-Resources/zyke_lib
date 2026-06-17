-- For different inventories, there's different capitalization needs (primarily for weapons)
-- First, just check if the item is valid under the normal name
-- If we can't find it as valid, try uppercase/lowercase

---@param name string
---@return Item | nil, string | nil @ Item, normalized name
function Functions.getItem(name)
    -- All mentions of the Items table goes through here first
    -- We guard it, in case the Items list hasn't been resolved yet
    while (not HasLoaderFinished or not Items) do Wait(10) end

    if (Items[name]) then
        return Formatting.formatItem(Items[name]), name
    end

    local lowercase = name:lower()
    if (Items[lowercase]) then
        return Formatting.formatItem(Items[lowercase]), lowercase
    end

    local uppercase = name:upper()
    if (Items[uppercase]) then
        return Formatting.formatItem(Items[uppercase]), uppercase
    end

    return nil
end

return Functions.getItem