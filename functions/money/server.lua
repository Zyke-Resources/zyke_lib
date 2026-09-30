Functions.money = {}

-- Elaborate system to translate multi-inputs for different framework accounts
-- Even though I will probably never add anything else (•_•)
-- And most other methods are probably more performant －O－
---@param account string
---@return string
local function translateAccount(account)
    if (account == "bank") then return account end

    local accountNames = {
        ["QB"] = {"cash", "bank", "dirty_cash"},
        ["ESX"] = {"money", "bank", "black_money"}
    }

    -- Check your own accounts
    if (Functions.table.contains(accountNames[Framework], account)) then return account end

    -- After that, check all other accounts, if you have a hit, return the index from your own accounts
    -- This is because frameworks might have slightly different names, but will never mistake a completely different currency type, so it will work reliably

    for framework, accounts in pairs(accountNames) do
        if (framework == Framework) then goto continue end

        for i = 1, #accounts do
            if (account == accounts[i]) then -- If the name is matching what we're searching for
                return accountNames[Framework][i] -- Return the index in the correct account list
            end
        end

        ::continue::
    end

    return account
end

---@param player Character | CharacterIdentifier | PlayerId
---@param account string? @cash default
---@param amount number
---@param details string?
function Functions.money.add(player, account, amount, details)
    local player = Functions.getPlayerData(player)
    if (not player) then return end

    if (not account) then account = "cash" end

    account = translateAccount(account)

    -- Hotfix for qbox servers because they don't carry the dirty cash feature??
    if (
        (Inventory == "OX" or Inventory == "ONE")
        and (account == "black_money" or account == "dirty_cash")
    ) then
        return Functions.addItem(player, "black_money", amount)
    end

    if (Framework == "ESX") then player.addAccountMoney(account, amount, details) return end
    if (Framework == "QB") then player.Functions.AddMoney(account, amount, details) return end
end

---@param player Character | CharacterIdentifier | PlayerId
---@param account string? @cash default
---@return number | nil
function Functions.money.get(player, account)
    local player = Functions.getPlayerData(player)
    if (not player) then return end

    if (not account) then account = "cash" end

    account = translateAccount(account)

    -- Hotfix for qbox servers because they don't carry the dirty cash feature??
    if (
        (Inventory == "OX" or Inventory == "ONE")
        and (account == "black_money" or account == "dirty_cash")
    ) then
        local invItem = Functions.getPlayerItem(player, "black_money", false, true)[1]

        return invItem?.amount or 0
    end

    if (Framework == "ESX") then return player.getAccount(account).money end
    if (Framework == "QB") then return player.PlayerData.money[account] end

    return nil
end

---@param player Character | CharacterIdentifier | PlayerId
---@param account string? @cash default
function Functions.money.remove(player, account, amount, details)
    local player = Functions.getPlayerData(player)
    if (not player) then return end

    if (not account) then account = "cash" end

    account = translateAccount(account)

    -- Hotfix for qbox servers because they don't carry the dirty cash feature??
    if (
        (Inventory == "OX" or Inventory == "ONE")
        and (account == "black_money" or account == "dirty_cash")
    ) then
        return Functions.removeItem(player, "black_money", amount)
    end

    if (Framework == "ESX") then return player.removeAccountMoney(account, amount, details) end
    if (Framework == "QB") then return player.Functions.RemoveMoney(account, amount, details) end
end

return Functions.money