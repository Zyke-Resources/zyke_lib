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
    elseif (BankingSystem == "KARTIK_BANKING") then
        return exports["kartik-banking"]:GetAccountMoney(name)
    elseif (BankingSystem == "LATION_BANKING") then
        return exports["lation_banking"]:GetAccountBalance(name)
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
    elseif (BankingSystem == "KARTIK_BANKING") then
        return exports["kartik-banking"]:AddAccountMoney(name, amount) ~= false
    elseif (BankingSystem == "LATION_BANKING") then
        return exports["lation_banking"]:AddAccountMoney(name, amount, nil) ~= false
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
    elseif (BankingSystem == "KARTIK_BANKING") then
        return exports["kartik-banking"]:RemoveAccountMoney(name, amount) ~= false
    elseif (BankingSystem == "LATION_BANKING") then
        return exports["lation_banking"]:RemoveAccountMoney(name, amount, nil) ~= false
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

-- Makes the society account when it is missing, where the banking system can make one. The others only report
-- whether it exists
---@param name string @ Society account name
---@param label string @ Shown in the banking system
---@return boolean exists
function Functions.society.ensure(name, label)
    if (type(name) ~= "string" or name == "") then return false end

    if (BankingSystem == "RENEWED_BANKING") then
        -- Returns the account as it is when it already exists
        return exports["Renewed-Banking"]:CreateJobAccount({name = name, label = label}, 0) ~= nil
    elseif (BankingSystem) then
        local balance = Functions.society.get(name)

        return type(balance) == "number"
    end

    if (Framework == "QB") then
        -- CreateJobAccount doesn't check for an existing account
        if (MySQL.scalar.await("SELECT 1 FROM `bank_accounts` WHERE `account_name` = ?", {name})) then return true end

        return exports["qb-banking"]:CreateJobAccount(name, 0) ~= nil
    end

    if (Framework == "ESX") then
        local p = promise.new()

        TriggerEvent("esx_addonaccount:getSharedAccount", name, function(account)
            p:resolve(account ~= nil)
        end)

        if (Citizen.Await(p)) then return true end

        -- AddSharedAccount came with later esx_addonaccount versions
        local created, account = pcall(function()
            return exports["esx_addonaccount"]:AddSharedAccount({name = name, label = label}, 0)
        end)

        return created and account ~= nil
    end

    return false
end

-- esx_society keeps a job's shared account as society_<job>, QBCore and Qbox banking use the job name
---@param job string
---@return string account
function Functions.society.getAccountName(job)
    if (Framework == "ESX" and job:sub(1, 8) ~= "society_") then return "society_" .. job end

    return job
end

return Functions.society