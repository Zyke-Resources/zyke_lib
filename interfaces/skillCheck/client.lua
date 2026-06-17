---@alias SkillCheckPreset "easy" | "medium" | "hard"

---@class SkillCheckDifficulty
---@field areaSize number @ Size of the success area in degrees
---@field speedMultiplier number @ Multiplier for the indicator speed

---@alias SkillCheckDifficultyInput SkillCheckPreset | SkillCheckDifficulty

---@class SkillCheckPayload
---@field difficulty SkillCheckDifficultyInput | SkillCheckDifficultyInput[]
---@field inputs? string[]

---@type promise?
local activeSkillCheck = nil

---@type boolean | nil
local previousKeepInput = nil

local skillCheckPresets = {
    easy = { areaSize = 50, speedMultiplier = 1 },
    medium = { areaSize = 40, speedMultiplier = 1.5 },
    hard = { areaSize = 25, speedMultiplier = 1.75 },
}

---@param difficulty SkillCheckDifficultyInput @ Difficulty preset name or custom difficulty
---@return SkillCheckDifficulty difficulty
local function normalizeDifficulty(difficulty)
    local settings = difficulty
    if (type(difficulty) == "string") then settings = skillCheckPresets[difficulty] or skillCheckPresets.easy end
    if (type(settings) ~= "table") then settings = skillCheckPresets.easy end

    local areaSize = tonumber(settings.areaSize) or skillCheckPresets.easy.areaSize
    local speedMultiplier = tonumber(settings.speedMultiplier) or skillCheckPresets.easy.speedMultiplier

    return {
        areaSize = Functions.numbers.clamp(areaSize, 5, 120),
        speedMultiplier = Functions.numbers.clamp(speedMultiplier, 0.25, 6),
    }
end

---@param difficulty SkillCheckDifficultyInput | SkillCheckDifficultyInput[] @ Difficulty input or stage list
---@return SkillCheckDifficulty | SkillCheckDifficulty[] difficulty
local function normalizeDifficultyInput(difficulty)
    if (type(difficulty) == "table" and difficulty.areaSize == nil and difficulty.speedMultiplier == nil) then
        local normalizedDifficulties = {}
        for i = 1, #difficulty do
            normalizedDifficulties[i] = normalizeDifficulty(difficulty[i])
        end

        if (#normalizedDifficulties > 0) then return normalizedDifficulties end
    end

    return normalizeDifficulty(difficulty)
end

---@param firstArg any @ Direct export difficulty or ignored dynamic-export argument
---@param secondArg? any @ Difficulty from dynamic callers or inputs from direct callers
---@param thirdArg? string[] @ Inputs from dynamic callers
---@return SkillCheckDifficultyInput | SkillCheckDifficultyInput[] difficulty
---@return string[]? inputs
local function resolveSkillCheckArgs(firstArg, secondArg, thirdArg)
    if (firstArg == nil and secondArg ~= nil) then return secondArg, thirdArg end

    return firstArg, secondArg
end

---@param success boolean @ Whether the skill check succeeded
local function resolveSkillCheck(success)
    local skillCheck = activeSkillCheck
    if (not skillCheck) then return end

    activeSkillCheck = nil
    SetNuiFocus(false, false)
    if (previousKeepInput ~= nil) then
        SetNuiFocusKeepInput(previousKeepInput)
        previousKeepInput = nil
    end

    skillCheck:resolve(success == true)
end

---@param difficulty SkillCheckDifficultyInput | SkillCheckDifficultyInput[] @ Skill check difficulty or stage list
---@param inputs? string[] @ Random key pool, defaults to `e` when omitted
---@return boolean? success
local function startSkillCheck(difficulty, inputs)
    if (activeSkillCheck) then return nil end

    activeSkillCheck = promise:new()
    previousKeepInput = IsNuiFocusKeepingInput()
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        event = "OpenSkillCheck",
        data = {
            difficulty = normalizeDifficultyInput(difficulty),
            inputs = inputs,
        }
    })

    return Citizen.Await(activeSkillCheck)
end

---@param firstArg any @ Direct export difficulty or ignored dynamic-export argument
---@param secondArg? any @ Difficulty from dynamic callers or inputs from direct callers
---@param thirdArg? string[] @ Inputs from dynamic callers
---@return boolean? success
Functions.skillCheck = function(firstArg, secondArg, thirdArg)
    local difficulty, inputs = resolveSkillCheckArgs(firstArg, secondArg, thirdArg)

    return startSkillCheck(difficulty, inputs)
end

---@return boolean isActive
Functions.skillCheckActive = function()
    return activeSkillCheck ~= nil
end

---@return boolean cancelled
Functions.cancelSkillCheck = function()
    if (not activeSkillCheck) then return false end

    SendNUIMessage({ event = "CancelSkillCheck" })

    return true
end

---@param passed? table
---@param cb function
RegisterNUICallback("Eventhandler:SkillCheck", function(passed, cb)
    cb("ok")

    passed = passed or {}
    if (passed.event ~= "complete") then return end

    local data = passed.data or {}
    resolveSkillCheck(data.success == true)
end)

---@param resourceName string
AddEventHandler("onClientResourceStop", function(resourceName)
    if (resourceName ~= ResName) then return end

    resolveSkillCheck(false)
end)
