-- Flattening containers is not possible on the client-side, use the server-sided version instead

---@param toInclude string[] | string | nil @List of items to include
---@param options? {firstOnly?: boolean, bundle?: boolean, metadata?: MetadataRequirement[]}
---@return Item[]
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getPlayerItems(toInclude, options)
    if (type(toInclude) == "string") then toInclude = {toInclude} end

    local _inv = Inventory

    local inventory = {}

    if (_inv == "QS") then
        inventory = exports['qs-inventory']:getUserInventory() or {}
    elseif (_inv == "TGIANN") then
        inventory = exports["tgiann-inventory"]:GetPlayerItems() or {}
    elseif (_inv == "CODEM") then
        inventory = exports["codem-inventory"]:GetClientPlayerInventory() or {}
    elseif (_inv == "OX") then
        inventory = exports["ox_inventory"]:GetPlayerItems() or {}
    else
        local player = Functions.getPlayerData()
        if (not player) then return inventory end

        if (Framework == "ESX") then
            inventory = player?.inventory or {}
        elseif (Framework == "QB") then
            inventory = player?.items or {}
        end
    end

    ---@type table<string, true>
    local _toInclude = {}
    if (toInclude) then
        for i = 1, #toInclude do
            local _, itemName = Functions.getItem(toInclude[i])
            _toInclude[itemName or toInclude[i]] = true
        end
    end

    local firstOnly = options?.firstOnly or false
    local bundle = options?.bundle or false
    local metadata = options?.metadata

    local formattedInventory = {}
    for _, _item in pairs(inventory) do
        local item = Formatting.formatItem(_item)
        if (item.name) then
            local _, itemName = Functions.getItem(item.name)
            if (itemName) then item.name = itemName end
        end

        if (toInclude and not _toInclude[item.name]) then goto continue end

        if (metadata ~= nil) then
            local hasAllMetadata = true

            for j = 1, #metadata do
                local itemVal = item.metadata[metadata[j].name]
                if (not itemVal) then hasAllMetadata = false break end

                if (metadata[j].match ~= nil) then
                    if (metadata[j].match ~= itemVal) then hasAllMetadata = false break end
                elseif (metadata[j].exclude ~= nil) then
                    if (metadata[j].exclude == itemVal) then hasAllMetadata = false break end
                else
                    error("Missing metadata search type.")
                end
            end

            if (not hasAllMetadata) then goto continue end
        end

        if (firstOnly) then return item end

        if (bundle and #formattedInventory > 0) then
            formattedInventory[1].amount += item.amount
        else
            formattedInventory[#formattedInventory+1] = item
        end

        ::continue::
    end

    return formattedInventory
end

return Functions.getPlayerItems