Functions.keys = {}

---@class KeyMapping
---@field type "keyboard" | "mouse_button" | "mouse_wheel"
---@field keyMappingKey string
---@field label? string @We override some labels to fit them better in menus
---@field minimalLabel? string @ Just like the label, but even more minimal, for example: "A.Right" -> ">"

---@class Key
---@field keyCode integer | nil
---@field name string | nil
---@field keyMapping KeyMapping

-- Some keys don't strictly align, so we create a lookup table for the fastest way to get the other key name
local keyMappingTranslation = {
    ["MOUSE_LEFT"] = "LEFTMOUSE",
    ["MOUSE_RIGHT"] = "RIGHTMOUSE",
    ["IOM_WHEEL_UP"] = "SCROLLUP",
    ["IOM_WHEEL_DOWN"] = "SCROLLDOWN",
    ["ESCAPE"] = "ESC",
    ["LSHIFT"] = "LEFTSHIFT",
    ["RETURN"] = "ENTER",
    ["BACK"] = "CANCEL",
    ["CAPITAL"] = "CAPS",
    ["LCONTROL"] = "LEFTCTRL",
    ["RCONTROL"] = "RIGHTCTRL",
    ["LMENU"] = "LEFTALT",
}

---@type table<string, Key>
local availableKeys = {
    ["V"] = {keyCode = 0, name = "~INPUT_NEXT_CAMERA~", keyMapping = {type = "keyboard", keyMappingKey = "V"}},
    ["S"] = {keyCode = 8, name = "~INPUT_SCRIPTED_FLY_UD~", keyMapping = {type = "keyboard", keyMappingKey = "S"}},
    ["D"] = {keyCode = 9, name = "~INPUT_SCRIPTED_FLY_LR~", keyMapping = {type = "keyboard", keyMappingKey = "D"}},
    ["PAGEUP"] = {keyCode = 10, name = "~INPUT_SCRIPTED_FLY_ZUP~", keyMapping = {type = "keyboard", keyMappingKey = "PAGEUP"}},
    ["PAGEDOWN"] = {keyCode = 11, name = "~INPUT_SCRIPTED_FLY_ZDOWN~", keyMapping = {type = "keyboard", keyMappingKey = "PAGEDOWN",}},
    ["SCROLLDOWN"] = {keyCode = 14, name = "~INPUT_WEAPON_WHEEL_NEXT~", keyMapping = {type = "mouse_wheel", keyMappingKey = "IOM_WHEEL_DOWN", label = "S.Down"}},
    ["SCROLLUP"] = {keyCode = 15, name = "~INPUT_WEAPON_WHEEL_PREV~", keyMapping = {type = "mouse_wheel", keyMappingKey = "IOM_WHEEL_UP", label = "S.Up"}},
    ["ENTER"] = {keyCode = 201, name = "~INPUT_FRONTEND_ACCEPT~", keyMapping = {type = "keyboard", keyMappingKey = "RETURN", label = "Enter", minimalLabel = "⤶"}},
    ["LEFTALT"] = {keyCode = 19, name = "~INPUT_CHARACTER_WHEE~", keyMapping = {type = "keyboard", keyMappingKey = "LMENU"}},
    ["Z"] = {keyCode = 20, name = "~INPUT_MULTIPLAYER_INFO~", keyMapping = {type = "keyboard", keyMappingKey = "Z"}},
    ["LEFTSHIFT"] = {keyCode = 21, name = "~INPUT_SPRINT~", keyMapping = {type = "keyboard", keyMappingKey = "LSHIFT"}},
    ["SPACE"] = {keyCode = 22, name = "~INPUT_JUMP~", keyMapping = {type = "keyboard", keyMappingKey = "SPACE"}},
    ["F"] = {keyCode = 23, name = "~INPUT_ENTER~", keyMapping = {type = "keyboard", keyMappingKey = "F"}},
    ["LEFTMOUSE"] = {keyCode = 24, name = "~INPUT_ATTACK~", keyMapping = {type = "mouse_button", keyMappingKey = "MOUSE_LEFT"}},
    ["RIGHTMOUSE"] = {keyCode = 25, name = "~INPUT_AIM~", keyMapping = {type = "mouse_button", keyMappingKey = "RIGHTMOUSE"}},
    ["C"] = {keyCode = 26, name = "~INPUT_LOOK_BEHIND~", keyMapping = {type = "keyboard", keyMappingKey = "C"}},
    ["TOP"] = {keyCode = 27, name = "~INPUT_PHONE~", keyMapping = {type = "keyboard", keyMappingKey = "UNUSED"}},
    ["B"] = {keyCode = 29, name = "~INPUT_SPECIAL_ABILITY_SECONDARY~", keyMapping = {type = "keyboard", keyMappingKey = "B"}},
    ["W"] = {keyCode = 32, name = "~INPUT_MOVE_UP_ONLY~", keyMapping = {type = "keyboard", keyMappingKey = "W"}},
    ["A"] = {keyCode = 34, name = "~INPUT_MOVE_LEFT_ONLY~", keyMapping = {type = "keyboard", keyMappingKey = "A"}},
    ["TAB"] = {keyCode = 37, name = "~INPUT_SELECT_WEAPON~", keyMapping = {type = "keyboard", keyMappingKey = "TAB"}},
    ["E"] = {keyCode = 38, name = "~INPUT_PICKUP~", keyMapping = {type = "keyboard", keyMappingKey = "E"}},
    ["["] = {keyCode = 39, name = "~INPUT_SNIPER_ZOOM~", keyMapping = {type = "keyboard", keyMappingKey = "UNUSED"}},
    ["]"] = {keyCode = 40, name = "~INPUT_SNIPER_ZOOM_IN_ONLY~", keyMapping = {type = "keyboard", keyMappingKey = "UNUSED"}},
    ["Q"] = {keyCode = 44, name = "~INPUT_COVER~", keyMapping = {type = "keyboard", keyMappingKey = "Q"}},
    ["R"] = {keyCode = 140, name = "~INPUT_MELEE_ATTACK_LIGHT~", keyMapping = {type = "keyboard", keyMappingKey = "R"}},
    ["G"] = {keyCode = 47, name = "~INPUT_DETONATE~", keyMapping = {type = "keyboard", keyMappingKey = "G"}},
    ["F9"] = {keyCode = 56, name = "~INPUT_DROP_WEAPON~", keyMapping = {type = "keyboard", keyMappingKey = "F9"}},
    ["F10"] = {keyCode = 57, name = "~INPUT_DROP_AMMO~", keyMapping = {type = "keyboard", keyMappingKey = "F10"}},
    ["RIGHTCTRL"] = {keyCode = 70, name = "~INPUT_VEH_ATTACK2~", keyMapping = {type = "keyboard", keyMappingKey = "RCONTROL"}},
    ["X"] = {keyCode = 73, name = "~INPUT_VEH_DUCK~", keyMapping = {type = "keyboard", keyMappingKey = "X"}},
    ["H"] = {keyCode = 74, name = "~INPUT_VEH_HEADLIGHT~", keyMapping = {type = "keyboard", keyMappingKey = "H"}},
    ["."] = {keyCode = 81, name = "~INPUT_VEH_NEXT_RADIO~", keyMapping = {type = "keyboard", keyMappingKey = "UNUSED"}},
    [","] = {keyCode = 82, name = "~INPUT_VEH_PREV_RADIO~", keyMapping = {type = "keyboard", keyMappingKey = "UNUSED"}},
    ["="] = {keyCode = 83, name = "~INPUT_VEH_NEXT_RADIO_TRACK~", keyMapping = {type = "keyboard", keyMappingKey = "UNUSED"}},
    ["-"] = {keyCode = 84, name = "~INPUT_VEH_PREV_RADIO_TRACK~", keyMapping = {type = "keyboard", keyMappingKey = "UNUSED"}},
    ["CAPS"] = {keyCode = 137, name = "~INPUT_VEH_PUSHBIKE_SPRINT~", keyMapping = {type = "keyboard", keyMappingKey = "CAPITAL"}},
    ["1"] = {keyCode = 157, name = "~INPUT_SELECT_WEAPON_UNARMED~", keyMapping = {type = "keyboard", keyMappingKey = "1"}},
    ["2"] = {keyCode = 158, name = "~INPUT_SELECT_WEAPON_MELEE~", keyMapping = {type = "keyboard", keyMappingKey = "2"}},
    ["6"] = {keyCode = 159, name = "INPUT_SELECT_WEAPON_HANDGUN~~", keyMapping = {type = "keyboard", keyMappingKey = "6"}},
    ["3"] = {keyCode = 160, name = "~INPUT_SELECT_WEAPON_SHOTGUN~", keyMapping = {type = "keyboard", keyMappingKey = "3"}},
    ["7"] = {keyCode = 161, name = "~INPUT_SELECT_WEAPON_SMG~", keyMapping = {type = "keyboard", keyMappingKey = "7"}},
    ["8"] = {keyCode = 162, name = "~INPUT_SELECT_WEAPON_AUTO_RIFLE~", keyMapping = {type = "keyboard", keyMappingKey = "8"}},
    ["9"] = {keyCode = 163, name = "~INPUT_SELECT_WEAPON_SNIPER~", keyMapping = {type = "keyboard", keyMappingKey = "9"}},
    ["4"] = {keyCode = 164, name = "~INPUT_SELECT_WEAPON_HEAVY~", keyMapping = {type = "keyboard", keyMappingKey = "4"}},
    ["5"] = {keyCode = 165, name = "~INPUT_SELECT_WEAPON_SPECIAL~", keyMapping = {type = "keyboard", keyMappingKey = "5"}},
    ["F5"] = {keyCode = 166, name = "~INPUT_SELECT_CHARACTER_MICHAEL~", keyMapping = {type = "keyboard", keyMappingKey = "F5"}},
    ["F6"] = {keyCode = 167, name = "~INPUT_SELECT_CHARACTER_FRANKLIN~", keyMapping = {type = "keyboard", keyMappingKey = "F6"}},
    ["F7"] = {keyCode = 168, name = "~INPUT_SELECT_CHARACTER_TREVOR~", keyMapping = {type = "keyboard", keyMappingKey = "F7"}},
    ["F8"] = {keyCode = 169, name = "~INPUT_SELECT_CHARACTER_MULTIPLAYER~", keyMapping = {type = "keyboard", keyMappingKey = "F8"}},
    ["F3"] = {keyCode = 170, name = "~INPUT_SAVE_REPLAY_CLIP~", keyMapping = {type = "keyboard", keyMappingKey = "F3"}},
    ["UP"] = {keyCode = 172, name = "~INPUT_CELLPHONE_UP~", keyMapping = {type = "keyboard", keyMappingKey = "UP", label = "A.Up", minimalLabel = "↑"}},
    ["DOWN"] = {keyCode = 173, name = "~INPUT_CELLPHONE_DOWN~", keyMapping = {type = "keyboard", keyMappingKey = "DOWN", label = "A.Down", minimalLabel = "↓"}},
    ["LEFT"] = {keyCode = 174, name = "~INPUT_CELLPHONE_LEFT~", keyMapping = {type = "keyboard", keyMappingKey = "LEFT", label = "A.Left", minimalLabel = "←"}},
    ["RIGHT"] = {keyCode = 175, name = "~INPUT_CELLPHONE_RIGHT~", keyMapping = {type = "keyboard", keyMappingKey = "RIGHT", label = "A.Right", minimalLabel = "→"}},
    ["CANCEL"] = {keyCode = 177, name = "~INPUT_CELLPHONE_CANCEL~", keyMapping = {type = "keyboard", keyMappingKey = "BACK"}}, -- BACKSPACE / ESC / RIGHT MOUSE BUTTON
    ["DELETE"] = {keyCode = 178, name = "~INPUT_CELLPHONE_OPTION~", keyMapping = {type = "keyboard", keyMappingKey = "DELETE"}},
    ["L"] = {keyCode = 182, name = "~INPUT_CELLPHONE_CAMERA_FOCUS_LOCK~", keyMapping = {type = "keyboard", keyMappingKey = "L"}},
    ["BACKSPACE"] = {keyCode = 202, name = "~INPUT_FRONTEND_CANCEL~", keyMapping = {type = "keyboard", keyMappingKey = "CANCEL", label = "Backspace", minimalLabel = "⟵"}},
    ["HOME"] = {keyCode = 213, name = "~INPUT_FRONTEND_SOCIAL_CLUB_SECONDARY~", keyMapping = {type = "keyboard", keyMappingKey = "HOME"}},
    ["~"] = {keyCode = 243, name = "~INPUT_ENTER_CHEAT_CODE~", keyMapping = {type = "keyboard", keyMappingKey = "UNUSED"}},
    ["M"] = {keyCode = 244, name = "~INPUT_INTERACTION_MENU~", keyMapping = {type = "keyboard", keyMappingKey = "M"}},
    ["T"] = {keyCode = 245, name = "~INPUT_MP_TEXT_CHAT_ALL~", keyMapping = {type = "keyboard", keyMappingKey = "T"}},
    ["Y"] = {keyCode = 246, name = "~INPUT_MP_TEXT_CHAT_TEAM~", keyMapping = {type = "keyboard", keyMappingKey = "Y"}},
    ["N"] = {keyCode = 249, name = "~INPUT_PUSH_TO_TALK~", keyMapping = {type = "keyboard", keyMappingKey = "N"}},
    ["F1"] = {keyCode = 288, name = "~INPUT_REPLAY_START_STOP_RECORDING~", keyMapping = {type = "keyboard", keyMappingKey = "F1"}},
    ["F2"] = {keyCode = 289, name = "~INPUT_REPLAY_START_STOP_RECORDING_SECONDARY~", keyMapping = {type = "keyboard", keyMappingKey = "F2"}},
    ["U"] = {keyCode = 303, name = "INPUT_REPLAY_SCREENSHOT~~", keyMapping = {type = "keyboard", keyMappingKey = "U"}},
    ["K"] = {keyCode = 311, name = "~INPUT_REPLAY_SHOWHOTKEY~", keyMapping = {type = "keyboard", keyMappingKey = "K"}},
    ["ESC"] = {keyCode = 322, name = "~INPUT_REPLAY_TOGGLE_TIMELINE~", keyMapping = {type = "keyboard", keyMappingKey = "ESCAPE"}},
    ["LEFTCTRL"] = {keyCode = 326, name = "~INPUT_DUCK~", keyMapping = {type = "keyboard", keyMappingKey = "LCONTROL"}},
    ["J"] = {keyCode = nil, name = nil, keyMapping = {type = "keyboard", keyMappingKey = "J"}}, -- Doesn't have a keycode
}

---@class SpecialCharacter
---@field key string -- Closest JS equivalent? Untested & unused
---@field keyMappingKey string

-- Lookup for special charactersa when getting the keybind
---@type table<string, SpecialCharacter>
local keyMapping = {
    ["b_100"] = {key = "LMB", keyMappingKey = "MOUSE_LEFT"},
    ["b_101"] = {key = "RMB", keyMappingKey = "MOUSE_RIGHT"},
    ["b_102"] = {key = "MMB", keyMappingKey = "MOUSE_MIDDLE"},
    ["b_103"] = {key = "Mouse.ExtraBtn1", keyMappingKey = "MOUSE_EXTRABTN1"},
    ["b_104"] = {key = "Mouse.ExtraBtn2", keyMappingKey = "MOUSE_EXTRABTN2"},
    ["b_105"] = {key = "Mouse.ExtraBtn3", keyMappingKey = "MOUSE_EXTRABTN3"},
    ["b_106"] = {key = "Mouse.ExtraBtn4", keyMappingKey = "MOUSE_EXTRABTN4"},
    ["b_107"] = {key = "Mouse.ExtraBtn5", keyMappingKey = "MOUSE_EXTRABTN5"},
    ["b_115"] = {key = "MouseWheel.Up", keyMappingKey = "IOM_WHEEL_UP"},
    ["b_116"] = {key = "MouseWheel.Down", keyMappingKey = "IOM_WHEEL_DOWN"},
    ["b_130"] = {key = "NumSubstract", keyMappingKey = "SUBTRACT"},
    ["b_131"] = {key = "NumAdd", keyMappingKey = "ADD"},
    ["b_134"] = {key = "Num Multiplication", keyMappingKey = "MULTIPLY"},
    ["b_135"] = {key = "Num Enter", keyMappingKey = "NUMPADENTER"},
    ["b_170"] = {key = "F1", keyMappingKey = "F1"},
    ["b_171"] = {key = "F2", keyMappingKey = "F2"},
    ["b_172"] = {key = "F3", keyMappingKey = "F3"},
    ["b_173"] = {key = "F4", keyMappingKey = "F4"},
    ["b_174"] = {key = "F5", keyMappingKey = "F5"},
    ["b_175"] = {key = "F6", keyMappingKey = "F6"},
    ["b_176"] = {key = "F7", keyMappingKey = "F7"},
    ["b_177"] = {key = "F8", keyMappingKey = "F8"},
    ["b_178"] = {key = "F9", keyMappingKey = "F9"},
    ["b_179"] = {key = "F10", keyMappingKey = "F10"},
    ["b_180"] = {key = "F11", keyMappingKey = "F11"},
    ["b_181"] = {key = "F12", keyMappingKey = "F12"},
    ["b_182"] = {key = "F13", keyMappingKey = "F13"},
    ["b_183"] = {key = "F14", keyMappingKey = "F14"},
    ["b_184"] = {key = "F15", keyMappingKey = "F15"},
    ["b_185"] = {key = "F16", keyMappingKey = "F16"},
    ["b_186"] = {key = "F17", keyMappingKey = "F17"},
    ["b_187"] = {key = "F18", keyMappingKey = "F18"},
    ["b_188"] = {key = "F19", keyMappingKey = "F19"},
    ["b_189"] = {key = "F20", keyMappingKey = "F20"},
    ["b_190"] = {key = "F21", keyMappingKey = "F21"},
    ["b_191"] = {key = "F22", keyMappingKey = "F22"},
    ["b_192"] = {key = "F23", keyMappingKey = "F23"},
    ["b_193"] = {key = "F24", keyMappingKey = "F24"},
    ["b_194"] = {key = "Arrow Up", keyMappingKey = "UP"},
    ["b_195"] = {key = "Arrow Down", keyMappingKey = "DOWN"},
    ["b_196"] = {key = "Arrow Left", keyMappingKey = "LEFT"},
    ["b_197"] = {key = "Arrow Right", keyMappingKey = "RIGHT"},
    ["b_198"] = {key = "Delete", keyMappingKey = "DELETE"},
    ["b_199"] = {key = "Escape", keyMappingKey = "ESCAPE"},
    ["b_201"] = {key = "End", keyMappingKey = "END"},
    ["b_210"] = {key = "Delete", keyMappingKey = "DELETE"},
    ["b_211"] = {key = "Insert", keyMappingKey = "INSERT"},
    ["b_212"] = {key = "End", keyMappingKey = "END"},
    ["b_1000"] = {key = "Shift", keyMappingKey = "LSHIFT"},
    ["b_1002"] = {key = "Tab", keyMappingKey = "TAB"},
    ["b_1003"] = {key = "Enter", keyMappingKey = "RETURN"},
    ["b_1004"] = {key = "Backspace", keyMappingKey = "BACK"},
    ["b_1009"] = {key = "PageUp", keyMappingKey = "PAGEUP"},
    ["b_1008"] = {key = "Home", keyMappingKey = "HOME"},
    ["b_1010"] = {key = "PageDown", keyMappingKey = "PAGEDOWN"},
    ["b_1012"] = {key = "CapsLock", keyMappingKey = "CAPITAL"},
    ["b_1013"] = {key = "Control", keyMappingKey = "LCONTROL"},
    ["b_1014"] = {key = "Right Control", keyMappingKey = "RCONTROL"},
    ["b_1015"] = {key = "Alt", keyMappingKey = "LMENU"},
    ["b_1055"] = {key = "Home", keyMappingKey = "HOME"},
    ["b_1056"] = {key = "PageUp", keyMappingKey = "PAGEUP"},
    ["b_2000"] = {key = "Space", keyMappingKey = "SPACE"},
}

---@class FullKeyData : KeyMapping
---@field keyCode integer

---@param key string
---@return FullKeyData | nil
function Functions.keys.getKeyMapping(key)
    local isSpecialCharacter = keyMapping[key] ~= nil
    if (isSpecialCharacter) then
        local keyData =
            availableKeys[keyMapping[key].keyMappingKey]
            or availableKeys[keyMappingTranslation[keyMapping[key].keyMappingKey]]

        if (keyData == nil) then
            return nil
        end

        return {
            key = keyMapping[key].key,
            type = keyData.keyMapping.type,
            keyMappingKey = keyData.keyMapping.keyMappingKey,
            keyCode = keyData.keyCode,
            label = keyData.keyMapping.label or keyMapping[key].key
        }
    else
        -- For non-speical leys on your keyboard
        local trimmedKey = key:sub(3)
        local keyData = availableKeys[trimmedKey]

        if (keyData == nil) then
            return nil
        end

        return {
            key = trimmedKey,
            type = keyData.keyMapping.type,
            keyMappingKey = keyData.keyMapping.keyMappingKey,
            keyCode = keyData.keyCode,
            label = keyData.keyMapping.label or trimmedKey
        }
    end
end

---@param command string
---@return KeyMapping | nil
function Functions.keys.getKeyDataForCommand(command)
    local hash = joaat(command) | 0x80000000
    local button = GetControlInstructionalButton(0, hash, true)

    return Functions.keys.getKeyMapping(button)
end

---@param key string | string[]
---@return Key | Key[]
function Functions.keys.get(key)
    if (type(key) == "string") then
        return availableKeys[key] or availableKeys[keyMappingTranslation[key]]
    end

    local keys = {}
    for i = 1, #key do
        keys[i] = Functions.keys.get(key[i])
    end

    return keys
end

function Functions.keys.getAll()
    return availableKeys
end

---@param keys string[]
---@return table<string, integer>
function Functions.keys.getTranslations(keys)
    local translatedKeys = {}

    for i = 1, #keys do
        translatedKeys[keys[i]] = availableKeys[keys[i]].keyCode
    end

    return translatedKeys
end

return Functions.keys