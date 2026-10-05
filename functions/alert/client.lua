---@class LationAlertData
---@field header? string
---@field content? string
---@field icon? string
---@field iconColor? string
---@field type? "default" | "info" | "success" | "warning" | "error"
---@field size? "xs" | "sm" | "md" | "lg" | "xl"
---@field cancel? boolean
---@field labels? table
---@field callouts? table[]

---@param data LationAlertData
---@return "confirm" | "cancel"
local function alert(data)
    if (GetResourceState("lation_ui") ~= "started") then
        error("[zyke_lib] Z.alert requires lation_ui to be started", 2)
    end

    return exports.lation_ui:alert(data)
end

return alert
