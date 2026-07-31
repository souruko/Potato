
-- Keys
--
-- turns a stored keybinding into something readable
--
-- the old FormatKeybinding printed the raw Turbine action code, so a binding showed as
-- "Ctrl+268435482". args.Action is a LotRO *action* enum value rather than a character code, so
-- there's no arithmetic that turns it into a key name — but Turbine.UI.Lotro.Action is an
-- ordinary table, so the reverse map can be built at load instead of hardcoded.
---------------------------------------------------------------------------------------------------

import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.Keys = {}

-- code -> name, built from the game's own Action enum
local actionNames = {}

if Turbine.UI.Lotro.Action ~= nil then
    for name, code in pairs(Turbine.UI.Lotro.Action) do
        if type(code) == "number" and actionNames[code] == nil then
            actionNames[code] = name
        end
    end
end

-- names the enum doesn't cover, for keys the game reports as unbound. only entries confirmed
-- in-game belong here — add a line as you find them, the panel prints the code when you bind
-- something unmapped.
local overrides = {
    [268435706] = "J",
}

-- turns an enum name like "ToggleHUD" into something a person reads
local function Humanise(name)

    local spaced = string.gsub(name, "(%l)(%u)", "%1 %2")
    spaced = string.gsub(spaced, "_", " ")

    return spaced

end

function _G.Keys.Name(action)

    if action == nil then
        return "unbound"
    end

    if overrides[action] ~= nil then
        return overrides[action]
    end

    if actionNames[action] ~= nil then
        return Humanise(actionNames[action])
    end

    return tostring(action)

end

-- true when we only have a number to show, so the panel can offer a hint
function _G.Keys.IsUnmapped(action)

    return action ~= nil
        and overrides[action] == nil
        and actionNames[action] == nil

end

-- "Ctrl + J"
function _G.Keys.Format(kb)

    if kb == nil or kb.action == nil then
        return "unbound"
    end

    local parts = {}
    if kb.ctrl  then parts[#parts + 1] = "Ctrl"  end
    if kb.alt   then parts[#parts + 1] = "Alt"   end
    if kb.shift then parts[#parts + 1] = "Shift" end
    parts[#parts + 1] = _G.Keys.Name(kb.action)

    return table.concat(parts, " + ")

end
