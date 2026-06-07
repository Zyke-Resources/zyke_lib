---@param player Character | CharacterIdentifier | PlayerId
---@param toInclude string[] | string | nil @List of items to include
---@param options? {flattenContainers?: boolean, firstOnly?: boolean, bundle?: boolean, metadata?: MetadataRequirement[]}
---@return Item[]
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getPlayerItems(player, toInclude, options)
    if (type(toInclude) == "string") then toInclude = {toInclude} end

    local _inv = Inventory

    local inventory = {}

    local plyId = Z.getPlayerId(player)
    if (not plyId) then return inventory end

    if (_inv == "QS") then
        inventory = exports['qs-inventory']:GetInventory(plyId) or {}
    elseif (_inv == "TGIANN") then
        inventory = exports["tgiann-inventory"]:GetPlayerItems(plyId) or {}
    elseif (_inv == "CODEM") then
        inventory = exports["codem-inventory"]:GetInventory(nil, plyId) or {}
    elseif (_inv == "OX") then
        inventory = exports["ox_inventory"]:GetInventory(plyId)?.items or {}
    else
        local player = Functions.getPlayerData(player)
        if (not player) then return inventory end

        if (Framework == "ESX") then
            inventory = player?.inventory or {}
        elseif (Framework == "QB") then
            inventory = player?.PlayerData?.items or {}
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

    local flattenContainers = options?.flattenContainers or false
    local firstOnly = options?.firstOnly or false
    local bundle = options?.bundle or false
    local metadata = options?.metadata

    ---@param inv table
    ---@param newInv Item[] | PlayerContainerItem[]
    ---@param currContainerId? string
    local function iterateInventory(inv, newInv, currContainerId)
        for _, _item in pairs(inv) do
            local item = Formatting.formatItem(_item)
            if (item.name) then
                local _, itemName = Functions.getItem(item.name)
                if (itemName) then item.name = itemName end
            end

            if (flattenContainers) then

                -- Possible future implementation for other inventory systems
                if (_inv == "OX") then
                    local containerId = item?.metadata?.container

                    if (containerId ~= nil) then
                        -- Might be able to grab it from the GetInventory export, but it didn't work from testing
                        local container = exports["ox_inventory"]:GetContainerFromSlot(plyId, item.slot)

                        if (container?.items and #container.items > 0) then
                            iterateInventory(container?.items, newInv, containerId)
                        end
                    end
                end
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

            if (currContainerId) then
                item.containerId = currContainerId
            end

            if (firstOnly) then return item end

            if (bundle and #newInv > 0) then
                newInv[1].amount += item.amount
            else
                newInv[#newInv+1] = item
            end

            ::continue::
        end
    end

    local formattedInventory = {}

    local result = iterateInventory(inventory, formattedInventory)
    if (firstOnly and result) then return result end

    return formattedInventory
end

return Functions.getPlayerItems