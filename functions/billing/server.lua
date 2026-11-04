Functions.billing = {}

---@class BillData
---@field identifier string @ Character billed
---@field plyId? integer @ Nil while the character is offline
---@field amount integer
---@field reason string
---@field job string @ Job whose society receives the money
---@field sender? string @ Identifier of the member who sent it, the billed character when nil

-- Bills a character to a job's society. With a billing script it is a bill the character pays from that script, with
-- esx_billing also while offline. Without one the amount is taken from the online character's bank at once and paid
-- into the society
---@param data BillData
---@return boolean billed
---@return boolean paid @ The money came in now
---@return (integer | string)? billId @ An unpaid bill, for isOpen and cancel
function Functions.billing.send(data)
    local identifier, amount, reason = data.identifier, data.amount, data.reason
    local account = Functions.society.getAccountName(data.job)

    if (BillingSystem == "okokBilling") then
        -- Bills by server id only and answers no invoice, so an offline character can't be billed and the bill can't
        -- be looked up later. A society as the author makes it a society invoice, keyed by the plain job name
        if (not data.plyId) then return false, false end

        exports["okokBilling"]:CreateInvoice(data.plyId, amount, reason, data.job)

        return true, false
    end

    if (BillingSystem == "esx_billing") then
        local before = MySQL.scalar.await("SELECT COALESCE(MAX(`id`), 0) FROM `billing`") or 0

        exports["esx_billing"]:BillPlayerByIdentifier(identifier, data.sender or identifier, account, reason, amount)

        -- The export answers nothing, so its row is looked up. It may write it a moment later, and writes none for a
        -- society esx_addonaccount doesn't know
        for _ = 1, 10 do
            local billId = MySQL.scalar.await("SELECT `id` FROM `billing` WHERE `id` > ? AND `identifier` = ? AND `target` = ? AND `label` = ? AND `amount` = ? ORDER BY `id` DESC LIMIT 1", {
                before, identifier, account, reason, amount,
            })
            if (billId) then return true, false, billId end

            Wait(100)
        end

        return false, false
    end

    if (not data.plyId) then return false, false end

    -- ESX removeAccountMoney answers nothing, so the balance is checked first
    local balance = Functions.money.get(data.plyId, "bank")
    if (not balance or balance < amount) then return false, false end

    Functions.money.remove(data.plyId, "bank", amount, reason)
    Functions.society.add(account, amount)

    return true, true
end

-- Whether a bill is still unpaid. esx_billing deletes a bill once it is paid, okokBilling names no bill to check
---@param billId integer | string @ The third answer of send
---@return boolean? open @ Nil when the billing script can't tell or there is none
function Functions.billing.isOpen(billId)
    if (BillingSystem ~= "esx_billing") then return nil end

    return MySQL.scalar.await("SELECT 1 FROM `billing` WHERE `id` = ?", {billId}) ~= nil
end

-- Takes back an unpaid bill. False when it is gone, the character paid it, or okokBilling has no way to take it back
---@param billId integer | string @ The third answer of send
---@return boolean removed
function Functions.billing.cancel(billId)
    if (BillingSystem ~= "esx_billing") then return false end

    return (tonumber(MySQL.update.await("DELETE FROM `billing` WHERE `id` = ?", {billId})) or 0) > 0
end

return Functions.billing