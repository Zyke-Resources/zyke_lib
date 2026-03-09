local awaitSystemStarting, override = ...

if (override == "none") then
    Functions.debug.internal("^2Banking system override set to 'none', skipping detection^7")
    return
end

local systems = {
    {fileName = "Renewed-Banking", variable = "RENEWED_BANKING"},
    {fileName = "RxBanking", variable = "RX_BANKING"},
    {fileName = "okokBanking", variable = "OKOK_BANKING"},
    {fileName = "bablo-banking", variable = "BABLO_BANKING"}
}

if (override ~= "auto") then
    for i = 1, #systems do
        if (systems[i].fileName == override) then
            local resState = awaitSystemStarting(override)

            if (resState ~= "started") then
                print("^1========== [WARNING] ==========^7")
                print(("^1> Banking override '%s' is set, but the resource is not started (state: %s)^7"):format(override, resState))
                print("^1> Please make sure the resource is installed and started in your server.cfg^7")
                print("^1> You can change this in dependency_override.lua^7")
            else
                BankingSystem = systems[i].variable
                Functions.debug.internal("^2Using " .. override .. " as banking system (override)^7")
            end

            return
        end
    end

    local valid = {}
    for i = 1, #systems do valid[#valid+1] = systems[i].fileName end
    print(("^1[zyke_lib] Invalid banking override '%s'. Valid options: %s^7"):format(override, table.concat(valid, ", ")))
else
    for i = 1, #systems do
        local resState = awaitSystemStarting(systems[i].fileName)

        -- If it's started, we use it
        if (resState == "started") then
            BankingSystem = systems[i].variable
            Functions.debug.internal("^2Using " .. systems[i].fileName .. " as banking system^7")

            break
        end
    end
end