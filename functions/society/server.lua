Functions.society = {}

---@param name string @ Society account name
---@return number? balance
function Functions.society.get(name)
    if (type(name) ~= "string" or name == "") then return nil end

    if (BankingSystem == "TGG_BANKING") then
        return exports["tgg-banking"]:GetSocietyAccountMoney(name)
    elseif (BankingSystem == "RENEWED_BANKING") then
        return exports["Renewed-Banking"]:getAccountMoney(name)
    elseif (BankingSystem == "RX_BANKING") then
        local account = exports["RxBanking"]:GetSocietyAccount(name)

        return account and account.balance
    elseif (BankingSystem == "OKOK_BANKING") then
        return exports["okokBanking"]:GetAccount(name)
    elseif (BankingSystem == "BABLO_BANKING") then
        return exports["bablo-banking"]:GetSocietyBalance(name)
    elseif (BankingSystem == "SKY_BANKING") then
        return exports["sky_base"]:getJobBalance(name)
    end

    if (Framework == "QB") then
        return exports["qb-banking"]:GetAccountBalance(name)
    end

    if (Framework == "ESX") then
        local p = promise.new()

        TriggerEvent("esx_addonaccount:getSharedAccount", name, function(account)
            p:resolve(account and account.money)
        end)

        return Citizen.Await(p)
    end

    return nil
end

---@param name string @ Society account name
---@param amount number @ Amount to add
---@return boolean success
function Functions.society.add(name, amount)
    if (type(name) ~= "string" or name == "") then return false end

    amount = math.floor(tonumber(amount) or 0)
    if (amount <= 0) then return false end

    if (BankingSystem == "TGG_BANKING") then
        return exports["tgg-banking"]:AddSocietyMoney(name, amount)
    elseif (BankingSystem == "RENEWED_BANKING") then
        return exports["Renewed-Banking"]:addAccountMoney(name, amount) ~= false
    elseif (BankingSystem == "RX_BANKING") then
        return exports["RxBanking"]:AddSocietyMoney(name, amount, "payment", nil, nil) ~= false
    elseif (BankingSystem == "OKOK_BANKING") then
        return exports["okokBanking"]:AddMoney(name, amount) ~= false
    elseif (BankingSystem == "BABLO_BANKING") then
        local result = exports["bablo-banking"]:AddSocietyMoney(name, amount)

        return result and result.success == true
    elseif (BankingSystem == "SKY_BANKING") then
        return exports["sky_base"]:addJobBalance(name, amount) ~= false
    end

    if (Framework == "QB") then
        return exports["qb-banking"]:AddMoney(name, amount) ~= false
    end

    if (Framework == "ESX") then
        local p = promise.new()

        TriggerEvent("esx_addonaccount:getSharedAccount", name, function(account)
            if (account) then
                account.addMoney(amount)
            end

            p:resolve(account ~= nil)
        end)

        return Citizen.Await(p)
    end

    return false
end

---@param name string @ Society account name
---@param amount number @ Amount to remove
---@return boolean success
function Functions.society.remove(name, amount)
    if (type(name) ~= "string" or name == "") then return false end

    amount = math.floor(tonumber(amount) or 0)
    if (amount <= 0) then return false end

    if (BankingSystem == "TGG_BANKING") then
        return exports["tgg-banking"]:RemoveSocietyMoney(name, amount)
    elseif (BankingSystem == "RENEWED_BANKING") then
        return exports["Renewed-Banking"]:removeAccountMoney(name, amount) ~= false
    elseif (BankingSystem == "RX_BANKING") then
        return exports["RxBanking"]:RemoveSocietyMoney(name, amount, "payment", nil, nil) ~= false
    elseif (BankingSystem == "OKOK_BANKING") then
        return exports["okokBanking"]:RemoveMoney(name, amount) ~= false
    elseif (BankingSystem == "BABLO_BANKING") then
        local result = exports["bablo-banking"]:RemoveSocietyMoney(name, amount)

        return result and result.success == true
    elseif (BankingSystem == "SKY_BANKING") then
        return exports["sky_base"]:removeJobBalance(name, amount) == true
    end

    if (Framework == "QB") then
        return exports["qb-banking"]:RemoveMoney(name, amount) ~= false
    end

    if (Framework == "ESX") then
        local p = promise.new()

        TriggerEvent("esx_addonaccount:getSharedAccount", name, function(account)
            if (account and account.money and account.money >= amount) then
                account.removeMoney(amount)
                p:resolve(true)
            else
                p:resolve(false)
            end
        end)

        return Citizen.Await(p) == true
    end

    return false
end

return Functions.society