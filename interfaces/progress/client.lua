---@alias ProgressType "bar" | "circle"

---@class ProgressDisable
---@field move? boolean
---@field car? boolean
---@field combat? boolean
---@field mouse? boolean
---@field sprint? boolean

---@class ProgressAnim
---@field dict? string
---@field clip? string
---@field flag? integer
---@field blendIn? number
---@field blendOut? number
---@field duration? integer
---@field playbackRate? number
---@field lockX? boolean
---@field lockY? boolean
---@field lockZ? boolean
---@field scenario? string
---@field playEnter? boolean

---@class ProgressProp
---@field model string | integer
---@field bone? integer
---@field pos? vector3 | table
---@field rot? vector3 | table
---@field rotOrder? integer

---@class ProgressData
---@field duration integer
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
---@field anim? ProgressAnim
---@field prop? ProgressProp | ProgressProp[]
---@field disable? ProgressDisable

---@class ActiveProgress
---@field id integer
---@field canCancel boolean
---@field cancelled boolean
---@field animType? "dict" | "scenario"
---@field animDict? string
---@field animClip? string

local activeProgress = nil
local progressId = 0
local playerState = LocalPlayer.state
local createdProgressProps = {}

local progressAssetTimeout = 5000
local progressPropsStateKey = "zyke_lib:progressProps"
local moveControls = {30, 31, 32, 33, 34, 35, 21, 22}
local carControls = {59, 60, 61, 62, 63, 64, 71, 72, 75, 76, 86, 87, 88, 89, 90, 91}
local combatControls = {24, 25, 37, 44, 45, 47, 58, 140, 141, 142, 143, 257, 263, 264}
local mouseControls = {1, 2, 106}

---@param data ProgressData
---@return boolean
local function shouldCancelForPedState(data)
    local ped = PlayerPedId()

    if (not data.useWhileDead and IsEntityDead(ped)) then return true end
    if (not data.allowRagdoll and IsPedRagdoll(ped)) then return true end
    if (not data.allowSwimming and IsPedSwimming(ped)) then return true end
    if (not data.allowCuffed and IsPedCuffed(ped)) then return true end
    if (not data.allowFalling and IsPedFalling(ped)) then return true end

    return false
end

---@param controls integer[]
local function disableControlList(controls)
    for i = 1, #controls do
        DisableControlAction(0, controls[i], true)
    end
end

---@param disable ProgressDisable | nil
local function disableProgressControls(disable)
    if (type(disable) ~= "table") then return end

    if (disable.move) then disableControlList(moveControls) end
    if (disable.car) then disableControlList(carControls) end
    if (disable.combat) then
        disableControlList(combatControls)
        DisablePlayerFiring(PlayerId(), true)
    end
    if (disable.mouse) then disableControlList(mouseControls) end
    if (disable.sprint) then DisableControlAction(0, 21, true) end
end

---@param prop ProgressProp
---@param ped integer
---@return integer?
local function createProgressProp(prop, ped)
    if (type(prop) ~= "table" or not prop.model) then return end
    if (not Z.loadModel(prop.model, true, progressAssetTimeout)) then return end

    local coords = GetEntityCoords(ped)
    local object = CreateObject(prop.model, coords.x, coords.y, coords.z, false, false, false)
    if (not object or object == 0) then return end

    local bone = GetPedBoneIndex(ped, prop.bone or 60309)
    local pos = prop.pos or {}
    local rot = prop.rot or {}

    AttachEntityToEntity(
        object,
        ped,
        bone,
        pos.x or 0.0,
        pos.y or 0.0,
        pos.z or 0.0,
        rot.x or 0.0,
        rot.y or 0.0,
        rot.z or 0.0,
        true,
        true,
        false,
        true,
        prop.rotOrder or 0,
        true
    )

    SetModelAsNoLongerNeeded(prop.model)
    return object
end

---@param props ProgressProp | ProgressProp[] | nil
---@param ped integer
---@return integer[]
local function createProgressProps(props, ped)
    local objects = {}
    if (type(props) ~= "table") then return objects end

    if (props.model) then
        local object = createProgressProp(props, ped)
        if (object) then objects[#objects + 1] = object end
        return objects
    end

    for i = 1, #props do
        local object = createProgressProp(props[i], ped)
        if (object) then objects[#objects + 1] = object end
    end

    return objects
end

---@param serverId integer
local function deleteProgressProps(serverId)
    local props = createdProgressProps[serverId]
    if (not props) then return end

    for i = 1, #props do
        local object = props[i]
        if (DoesEntityExist(object)) then DeleteEntity(object) end
    end

    createdProgressProps[serverId] = nil
end

---@param anim ProgressAnim | nil
---@param state ActiveProgress
local function startProgressAnim(anim, state)
    if (type(anim) ~= "table") then return end

    local ped = PlayerPedId()

    if (anim.dict) then
        if (not anim.clip or not Z.loadDict(anim.dict, true, progressAssetTimeout)) then return end

        TaskPlayAnim(
            ped,
            anim.dict,
            anim.clip,
            anim.blendIn or 3.0,
            anim.blendOut or 1.0,
            anim.duration or -1,
            anim.flag or 49,
            anim.playbackRate or 0.0,
            anim.lockX == true,
            anim.lockY == true,
            anim.lockZ == true
        )
        RemoveAnimDict(anim.dict)

        state.animType = "dict"
        state.animDict = anim.dict
        state.animClip = anim.clip
    elseif (anim.scenario) then
        TaskStartScenarioInPlace(ped, anim.scenario, 0, anim.playEnter ~= false)
        state.animType = "scenario"
    end
end

---@param state ActiveProgress
local function cleanupProgress(state)
    if (state.animType == "dict" and state.animDict and state.animClip) then
        StopAnimTask(PlayerPedId(), state.animDict, state.animClip, 1.0)
        Wait(0)
    elseif (state.animType == "scenario") then
        ClearPedTasks(PlayerPedId())
    end
end

---@param state ActiveProgress
---@param success boolean
---@param delay? integer
local function closeProgressUi(state, success, delay)
    CreateThread(function()
        if (delay and delay > 0) then Wait(delay) end

        SendNUIMessage({
            event = "CloseProgress",
            data = {
                id = state.id,
                success = success,
            }
        })
    end)
end

---@param progressType ProgressType
---@param data ProgressData
---@return boolean
local function startProgress(progressType, data)
    if (activeProgress) then return false end
    if (type(data) ~= "table" or not data.duration or data.duration <= 0) then return false end
    if (shouldCancelForPedState(data)) then return false end

    progressId = progressId + 1

    local state = {
        id = progressId,
        canCancel = data.canCancel == true,
        cancelled = false,
    }

    activeProgress = state
    playerState.invBusy = true
    startProgressAnim(data.anim, state)

    -- Keep progress props on our own state bag key so ox_lib can run beside us without double-spawning props.
    if (data.prop) then
        playerState:set(progressPropsStateKey, data.prop, true)
    end

    SendNUIMessage({
        event = "OpenProgress",
        data = {
            id = state.id,
            type = progressType,
            duration = data.duration,
            label = data.label,
            description = data.description,
            icon = data.icon,
            position = data.position,
            canCancel = state.canCancel,
        }
    })

    local endsAt = GetGameTimer() + data.duration

    while (activeProgress == state and GetGameTimer() < endsAt) do
        if (state.cancelled or shouldCancelForPedState(data)) then break end

        disableProgressControls(data.disable)
        Wait(0)
    end

    local success = activeProgress == state and not state.cancelled and not shouldCancelForPedState(data)

    if (data.prop) then playerState:set(progressPropsStateKey, nil, true) end
    cleanupProgress(state)
    playerState.invBusy = false

    if (activeProgress == state) then activeProgress = nil end
    closeProgressUi(state, success, success and 100 or 0)

    return success
end

---@param data ProgressData
---@return boolean
local function progressBar(data)
    return startProgress("bar", data)
end

---@param data ProgressData
---@return boolean
local function progressCircle(data)
    return startProgress("circle", data)
end

---@return boolean
local function progressActive()
    return activeProgress ~= nil
end

---@return boolean
local function cancelProgress()
    if (not activeProgress or not activeProgress.canCancel) then return false end

    activeProgress.cancelled = true

    return true
end

RegisterCommand("zyke_lib_cancelprogress", function()
    cancelProgress()
end, false)

RegisterKeyMapping("zyke_lib_cancelprogress", "Cancel progress", "keyboard", "x")

exports("progressBar", function(_, data)
    return progressBar(type(data) == "table" and data or _)
end)

exports("progressCircle", function(_, data)
    return progressCircle(type(data) == "table" and data or _)
end)

exports("progressActive", progressActive)
exports("cancelProgress", cancelProgress)

---@param resName string
AddEventHandler("onClientResourceStop", function(resName)
    if (resName ~= GetCurrentResourceName()) then return end

    playerState:set(progressPropsStateKey, nil, true)
    if (activeProgress) then
        cleanupProgress(activeProgress)
        activeProgress = nil
    end

    playerState.invBusy = false
    for serverId in pairs(createdProgressProps) do
        deleteProgressProps(serverId)
    end
end)

---@param serverId integer
RegisterNetEvent("onPlayerDropped", function(serverId)
    deleteProgressProps(serverId)
end)

-- Match ox_lib's progress prop state for backwards compatibility
AddStateBagChangeHandler(progressPropsStateKey, nil, function(bagName, key, value, reserved, replicated)
    if (replicated) then return end

    local ply = GetPlayerFromStateBagName(bagName)
    if (ply == 0) then return end

    local serverId = GetPlayerServerId(ply)
    deleteProgressProps(serverId)

    if (not value) then return end

    local ped = GetPlayerPed(ply)
    createdProgressProps[serverId] = createProgressProps(value, ped)
end)