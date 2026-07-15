-- TODO: Debug warning when overwriting commands

---@param commands string[] | string
---@param fn function
---@param helperMsg? string
---@param args? table<string[]>
---@param permission? {permission: string[] | string, errorMsg: string}
function Functions.registerCommand(commands, fn, helperMsg, args, permission)
    if (type(commands) ~= "table") then commands = {commands} end

    if (permission and type(permission.permission) ~= "table") then
        ---@diagnostic disable-next-line: assign-type-mismatch -- Linter is just stupid
        permission.permission = {permission.permission}
    end

    local function getArgs()
        if (not args or #args == 0) then return {} end

        local _args = {}

        for i = 1, #args do
            _args[#_args+1] = {name = args[i][1], help = args[i][2]}
        end

        return _args
    end

    local function addSuggestion(cmd)
        local _args = getArgs()

        if (Context == "server") then
            TriggerClientEvent("chat:addSuggestion", -1, ("/%s"):format(cmd), helperMsg, _args)
        else
            TriggerEvent("chat:addSuggestion", ("/%s"):format(cmd), helperMsg, _args)
        end
    end

    for i = 1, #commands do
        -- If we have a permission to check, do so before we trigger the input function
        if (permission) then
            if (Context == "server") then
                RegisterCommand(commands[i], function(plyId, ...)
                    if (Functions.hasPermission(plyId, permission.permission)) then
                        fn(plyId, ...)
                    else
                        ---@diagnostic disable-next-line: param-type-mismatch
                        Functions.notify(plyId, permission.errorMsg)
                    end
                end, false)
            else
                RegisterCommand(commands[i], function(plyId, ...)
                    if (Functions.hasPermission(permission.permission)) then
                        fn(plyId, ...)
                    else
                        ---@diagnostic disable-next-line: missing-parameter
                        Functions.notify(permission.errorMsg)
                    end
                end, false)
            end
        else
            RegisterCommand(commands[i], fn, false)
        end


        addSuggestion(commands[i])
    end
end

return Functions.registerCommand