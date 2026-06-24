Functions.progressBar = {}

---@class ProgressBarDisableControls
---@field disableMovement? boolean
---@field disableCarMovement? boolean
---@field disableMouse? boolean
---@field disableCombat? boolean

---@class ProgressBarAnimation
---@field type? "anim" | "scenario"
---@field animDict? string
---@field dict? string
---@field anim? string
---@field clip? string
---@field flag? integer
---@field scenario? string

---@class ProgressBarData
---@field name? string
---@field label? string
---@field description? string
---@field icon? string @ Resolved via IconRegistry, falls back to Material Icons. Defaults to "time"
---@field duration integer
---@field position? "middle" | "bottom"
---@field useWhileDead? boolean
---@field allowRagdoll? boolean
---@field allowSwimming? boolean
---@field allowCuffed? boolean
---@field allowFalling? boolean
---@field canCancel? boolean
---@field disable? table
---@field disableControls? table | boolean
---@field animation? ProgressBarAnimation
---@field anim? table
---@field prop? table
---@field propTwo? table
---@field onFinish? function
---@field onCancel? function

---@class ManualProgressBarData
---@field type? "bar" | "circle"
---@field progress? number
---@field percent? number
---@field percentage? number
---@field value? number
---@field label? string
---@field description? string
---@field icon? string @ Resolved via IconRegistry, falls back to Material Icons. Defaults to "time"
---@field position? "middle" | "bottom"
---@field useWhileDead? boolean
---@field allowRagdoll? boolean
---@field allowSwimming? boolean
---@field allowCuffed? boolean
---@field allowFalling? boolean
---@field canCancel? boolean
---@field disable? table
---@field disableControls? table | boolean
---@field animation? ProgressBarAnimation
---@field anim? table
---@field prop? table
---@field propTwo? table

---@class ManualProgressBarCloseOptions
---@field success? boolean
---@field type? "bar" | "circle"
---@field progress? number
---@field percent? number
---@field percentage? number
---@field value? number
---@field label? string
---@field description? string
---@field icon? string @ Resolved via IconRegistry, falls back to Material Icons. Defaults to "time"
---@field position? "middle" | "bottom"
---@field canCancel? boolean
---@field delay? integer

---@param disableControls table | boolean | nil
---@return table | nil
local function normalizeDisableControls(disableControls)
    if (disableControls == false or disableControls == nil) then return nil end

    if (disableControls == true) then
        return {
            move = true,
            car = true,
            mouse = true,
            combat = true,
        }
    end

    if (type(disableControls) ~= "table") then return nil end

    return {
        move = disableControls.move or disableControls.disableMovement,
        car = disableControls.car or disableControls.disableCarMovement,
        mouse = disableControls.mouse or disableControls.disableMouse,
        combat = disableControls.combat or disableControls.disableCombat,
        sprint = disableControls.sprint,
    }
end

---@param animation ProgressBarAnimation | nil
---@return table | nil
local function normalizeAnimation(animation)
    if (type(animation) ~= "table") then return nil end

    if (animation.type == "scenario" or animation.scenario) then
        local anim = {}
        for k, v in pairs(animation) do anim[k] = v end
        anim.scenario = animation.scenario or animation.anim or animation.clip

        return anim
    end

    local anim = {}
    for k, v in pairs(animation) do anim[k] = v end

    anim.dict = animation.dict or animation.animDict
    anim.clip = animation.clip or animation.anim

    return anim
end

---@param data ProgressBarData | ManualProgressBarData | ManualProgressBarCloseOptions
---@return table
local function normalizeProgressData(data)
    local normalized = {}

    for k, v in pairs(data) do normalized[k] = v end

    normalized.disable = data.disable or normalizeDisableControls(data.disableControls)
    normalized.anim = data.anim or normalizeAnimation(data.animation)

    if (data.prop and data.propTwo) then
        normalized.prop = {data.prop, data.propTwo}
    end

    normalized.animation = nil
    normalized.disableControls = nil
    normalized.propTwo = nil
    normalized.onFinish = nil
    normalized.onCancel = nil

    return normalized
end

---@param progressType "bar" | "circle"
---@param data ProgressBarData
---@return boolean @If finished
local function start(progressType, data)
    if (type(data) ~= "table") then return false end

    local normalized = normalizeProgressData(data)
    local state

    if (progressType == "circle") then
        state = exports[LibName]:progressCircle(normalized)
    else
        state = exports[LibName]:progressBar(normalized)
    end

    if (state == true) then
        if (data.onFinish) then data.onFinish() end
    else
        if (data.onCancel) then data.onCancel() end
    end

    return state == true
end

---@param data ManualProgressBarData
---@return boolean
function Functions.progressBar.show(data)
    if (type(data) ~= "table") then return false end

    return exports[LibName]:showProgress(normalizeProgressData(data))
end

---@param data ManualProgressBarData
---@return boolean
function Functions.progressBar.update(data)
    if (type(data) ~= "table") then return false end

    return exports[LibName]:updateProgress(normalizeProgressData(data))
end

---@param options? boolean | ManualProgressBarCloseOptions
---@return boolean
function Functions.progressBar.hide(options)
    if (type(options) == "table") then
        return exports[LibName]:hideProgress(normalizeProgressData(options))
    end

    return exports[LibName]:hideProgress(options)
end

---@param data ProgressBarData
---@return boolean @If finished
function Functions.progressBar.start(data)
    return start("bar", data)
end

---@param data ProgressBarData
---@return boolean @If finished
function Functions.progressBar.circle(data)
    return start("circle", data)
end

---@param data ProgressBarData
---@return boolean @If finished
function Functions.progressBar.startCircle(data)
    return start("circle", data)
end

---@return boolean
function Functions.progressBar.active()
    return exports[LibName]:progressActive()
end

---@param force? boolean
---@return boolean
function Functions.progressBar.cancel(force)
    return exports[LibName]:cancelProgress(force)
end

return Functions.progressBar