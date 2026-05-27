---@class ZykeDuiCreateOptions
---@field url string @ URL to render
---@field width number @ DUI texture width
---@field height number @ DUI texture height
---@field debug? boolean @ Print lifecycle messages

---@class ZykeDuiInstance
---@field id string
---@field url string
---@field duiObject number
---@field duiHandle string
---@field runtimeTxd number
---@field txdObject number
---@field dictName string
---@field txtName string
---@field resourceName string
---@field debug boolean
---@field removed? boolean

local dui = {}
local duiInstance = {}
duiInstance.__index = duiInstance

local currentId = 0
local instancesByResource = {}

---@param resourceName string @ Resource name to make texture-safe
---@return string safeName
local function getSafeResourceName(resourceName)
    local safeName = tostring(resourceName or "unknown"):gsub("[^%w_]", "_")
    if (safeName == "") then return "unknown" end

    return safeName
end

---@param resourceName string @ Consuming resource name
---@return string id
local function getNextDuiId(resourceName)
    currentId = currentId + 1

    return ("zyke_lib_dui_%s_%s_%s"):format(getSafeResourceName(resourceName), GetGameTimer(), currentId)
end

---@param value any @ Native return value
---@return boolean valid
local function hasNativeValue(value)
    return value ~= nil and value ~= false
end

---@param data any @ Raw constructor options
---@return boolean valid
---@return string? errorMessage
local function validateCreateOptions(data)
    if (type(data) ~= "table") then return false, "expected DUI options table" end
    if (type(data.url) ~= "string" or data.url == "") then return false, "expected non-empty DUI url" end
    if (type(data.width) ~= "number" or data.width <= 0) then return false, "expected positive DUI width" end
    if (type(data.height) ~= "number" or data.height <= 0) then return false, "expected positive DUI height" end

    return true, nil
end

---@param duiObject number? @ DUI object handle
---@return nil
local function destroyDuiObject(duiObject)
    if (not hasNativeValue(duiObject)) then return end

    SetDuiUrl(duiObject, "about:blank")
    DestroyDui(duiObject)
end

---@param instance ZykeDuiInstance @ DUI instance
---@return nil
local function trackInstance(instance)
    local resourceInstances = instancesByResource[instance.resourceName]
    if (not resourceInstances) then
        resourceInstances = {}
        instancesByResource[instance.resourceName] = resourceInstances
    end

    resourceInstances[instance.id] = instance
end

---@param instance ZykeDuiInstance @ DUI instance
---@return nil
local function untrackInstance(instance)
    local resourceInstances = instancesByResource[instance.resourceName]
    if (not resourceInstances) then return end

    resourceInstances[instance.id] = nil
    if (next(resourceInstances) ~= nil) then return end

    instancesByResource[instance.resourceName] = nil
end

---@param instance ZykeDuiInstance @ DUI instance
---@param message string @ Debug message
---@return nil
local function debugDui(instance, message)
    if (not instance.debug) then return end

    print(("[zyke_lib DUI] %s (%s)"):format(message, instance.id))
end

---@param message table @ Serializable message payload
---@return boolean success
---@return string? errorMessage
function duiInstance:sendMessage(message)
    if (self.removed) then return false, "DUI instance has been removed" end
    if (type(message) ~= "table") then return false, "expected DUI message table" end

    SendDuiMessage(self.duiObject, json.encode(message))
    debugDui(self, "sent message")

    return true, nil
end

---@param url string @ URL to render
---@return boolean success
---@return string? errorMessage
function duiInstance:setUrl(url)
    if (self.removed) then return false, "DUI instance has been removed" end
    if (type(url) ~= "string") then return false, "expected DUI url string" end

    self.url = url
    SetDuiUrl(self.duiObject, url)
    debugDui(self, ("set url to %s"):format(url))

    return true, nil
end

---@return boolean success
function duiInstance:remove()
    if (self.removed) then return true end

    destroyDuiObject(self.duiObject)
    untrackInstance(self)

    self.removed = true
    debugDui(self, "removed")

    return true
end

---@param data ZykeDuiCreateOptions @ DUI creation options
---@return ZykeDuiInstance? instance
---@return string? errorMessage
function dui:new(data)
    local valid, errorMessage = validateCreateOptions(data)
    if (not valid) then return nil, errorMessage end

    local resourceName = ResName or GetCurrentResourceName()
    local id = getNextDuiId(resourceName)
    local dictName = ("%s_dict"):format(id)
    local txtName = ("%s_txt"):format(id)
    local duiObject = CreateDui(data.url, data.width, data.height)
    if (not hasNativeValue(duiObject)) then return nil, "failed to create DUI object" end

    local duiHandle = GetDuiHandle(duiObject)
    if (type(duiHandle) ~= "string" or duiHandle == "") then
        destroyDuiObject(duiObject)

        return nil, "failed to get DUI handle"
    end

    local runtimeTxd = CreateRuntimeTxd(dictName)
    if (not hasNativeValue(runtimeTxd)) then
        destroyDuiObject(duiObject)

        return nil, "failed to create runtime texture dictionary"
    end

    local txdObject = CreateRuntimeTextureFromDuiHandle(runtimeTxd, txtName, duiHandle)
    if (not hasNativeValue(txdObject)) then
        destroyDuiObject(duiObject)

        return nil, "failed to create DUI runtime texture"
    end

    local instance = setmetatable({
        id = id,
        url = data.url,
        duiObject = duiObject,
        duiHandle = duiHandle,
        runtimeTxd = runtimeTxd,
        txdObject = txdObject,
        dictName = dictName,
        txtName = txtName,
        resourceName = resourceName,
        debug = data.debug == true,
    }, duiInstance)

    trackInstance(instance)
    debugDui(instance, "created")

    return instance, nil
end

---@param resourceName string @ Stopping resource name
---@return nil
local function onResourceStop(resourceName)
    local resourceInstances = instancesByResource[resourceName]
    if (not resourceInstances) then return end

    local instances = {}

    for _, instance in pairs(resourceInstances) do
        instances[#instances + 1] = instance
    end

    for i = 1, #instances do
        instances[i]:remove()
    end

    instancesByResource[resourceName] = nil
end

AddEventHandler("onResourceStop", onResourceStop)

Functions.dui = dui

return Functions.dui
