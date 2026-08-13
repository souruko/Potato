import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "Potato.Class"
import "Potato.Type"

import "Potato.ui.theme"
import "Potato.ui.potatoWindow"
import "Potato.ui.optionPanel"

import "Potato.chatParse"
import "Potato.targetChanged"


---------------------------------------------------------------------------------------------------
-- fake savefile

-- German and French clients serialise numbers with a comma decimal separator, which the savefile
-- reader then cannot parse back — the settings come out mangled or the load fails outright. The
-- standard workaround (same one FervourFocus, LootLogs and TbdBars use) is to write every number as
-- a string and turn it back into a number on load, so no number ever goes through the serialiser.
local function IsEuroClient()
    return Turbine.Shell.IsCommand("hilfe") or Turbine.Shell.IsCommand("aide")
end

local function ConvertToEuro(dataRaw)
    if type(dataRaw) ~= "table" then
        return type(dataRaw) == "number" and tostring(dataRaw) or dataRaw
    end
    -- Turbine.UI.Color and friends are left alone: they are class instances, not settings data, and
    -- walking them with pairs() would flatten them into something the game can no longer use.
    if getmetatable(dataRaw) ~= nil then
        return dataRaw
    end
    local newData = {}
    for i, myData in pairs(dataRaw) do
        local tempIndex = type(i) == "number" and tostring(i) or i
        local tempData
        if type(myData) == "table" then
            tempData = ConvertToEuro(myData)
        elseif type(myData) == "number" then
            tempData = tostring(myData)
        else
            tempData = myData
        end
        newData[tempIndex] = tempData
    end
    return newData
end

local function ConvertFromEuro(dataRaw)
    if type(dataRaw) ~= "table" then
        local n = tonumber(dataRaw)
        return n ~= nil and n or dataRaw
    end
    if getmetatable(dataRaw) ~= nil then
        return dataRaw
    end
    local newData = {}
    for i, myData in pairs(dataRaw) do
        local tempIndex = tonumber(i)
        if tempIndex == nil then tempIndex = i end
        local tempData
        if type(myData) == "table" then
            tempData = ConvertFromEuro(myData)
        else
            tempData = tonumber(myData)
            if tempData == nil then tempData = myData end
        end
        newData[tempIndex] = tempData
    end
    return newData
end

local euroClient = IsEuroClient()

---------------------------------------------------------------------------------------------------
-- the two savefiles
--
-- character scope is the one the plugin reads and writes as you go. account scope is the "global"
-- copy: a preset you hand to every character, written and read on demand from the Global tab of the
-- options panel.
--
-- it used to be written on every save, as a fallback for a character that had no file of its own.
-- that made it impossible to keep a deliberate set of shared settings, since the last character to
-- change anything overwrote it. it is now only auto-written while no global copy exists at all, so
-- a fresh install still passes its settings to the next character; once there is one, only "Save to
-- global" replaces it.

local DERIVED_KEYS = {
    "tooltip_color_player",
    "tooltip_color_npc",
    "tooltip_color_item",
    "tooltip_targeted_color",
    "tooltip_defeated_color",
    "tooltip_defeated_text_color",
}

-- class instances (Turbine.UI.Color and friends) are handed over as they are, same as ConvertToEuro
-- does: copying them field by field would flatten them into something the game can no longer use.
local function DeepCopy(value)

    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return value
    end

    local copy = {}
    for key, inner in pairs(value) do
        copy[key] = DeepCopy(inner)
    end

    return copy

end

-- what actually goes to disk: the settings minus the Turbine.UI.Color objects built from them,
-- which are rebuilt on every load anyway and are not savefile data. a copy all the way down, so the
-- payload can be kept as the in-memory global copy without aliasing the live settings.
local function SettingsPayload()

    local data = DeepCopy(_G.Settings)

    for _, key in ipairs(DERIVED_KEYS) do
        data[key] = nil
    end

    return data

end

local function WriteScope(scope, data)

    if euroClient then
        data = ConvertToEuro(data)
    end

    Turbine.PluginData.Save(scope, "potatoSaveFile", data, nil)

end

-- runs on savefiles written before the euro fix too: numbers that are already numbers survive
-- tonumber unchanged, and strings that are not numbers ("name", "comfortable") fall back to
-- themselves.
local function LoadScope(scope)

    local data = Turbine.PluginData.Load(scope, "potatoSaveFile", nil)

    if data ~= nil and euroClient then
        data = ConvertFromEuro(data)
    end

    return data

end

-- Turbine.PluginData.Load only reads synchronously while the plugin is loading; called any later —
-- from the options panel, say — it insists on an async handler and throws. so the global copy is
-- read once, here, and kept in memory: every later read of it, and every write, goes through this
-- cache instead of touching the disk again.
local globalCache = LoadScope(Turbine.DataScope.Account)

-- decided once, when the plugin loaded, so the mirroring cannot start or stop halfway through a
-- session: either there was a global copy to protect or there wasn't
local mirrorToGlobal = (globalCache == nil)

_G.SaveSettings = function ()

    local data = SettingsPayload()

    WriteScope(Turbine.DataScope.Character, data)

    if mirrorToGlobal then
        WriteScope(Turbine.DataScope.Account, data)
        globalCache = data
    end

end

-- copies this character's settings over the global one
_G.SaveGlobalSettings = function ()

    local data = SettingsPayload()

    WriteScope(Turbine.DataScope.Account, data)
    globalCache = data

    return true

end

-- replaces this character's settings with the global ones, and keeps them
_G.LoadGlobalSettings = function ()

    if globalCache == nil then
        return false
    end

    _G.Settings = DeepCopy(globalCache)

    _G.NormaliseSettings()
    _G.SaveSettings()

    return true

end

_G.HasGlobalSettings = function ()
    return globalCache ~= nil
end

---------------------------------------------------------------------------------------------------
-- defaults and migrations
--
-- every key is filled in only when it is missing, so this can run on a fresh install, on a savefile
-- from any older version, and on whatever the global copy happens to hold.

function _G.NormaliseSettings()

if _G.Settings == nil then
    _G.Settings = {}
end

local function default(key, value)
    if _G.Settings[key] == nil then
        _G.Settings[key] = value
    end
end

default("left", 500)
default("top", 500)
default("width", 200)
default("tooltip_height", 50)
default("max_tooltip_count", 5)
default("tooltip_spacing", 5)
default("highlight_defeated", true)
default("display_durations", true)
default("keybinding_add",   { shift = false, alt = false, ctrl = false, action = 268435706 })
default("keybinding_clear", { shift = false, alt = false, ctrl = true,  action = 268435482 })
default("use_clear_keybinding", true)
default("only_clear_dead", false)

if _G.Settings.reverseFill == nil then
    _G.Settings.reverseFill = false
end
if _G.Settings.horizontal == nil then
    _G.Settings.horizontal = false
end
if _G.Settings.cc_warning_threshold == nil then
    _G.Settings.cc_warning_threshold = 5
end
if _G.Settings.defeat_auto_remove_delay == nil then
    _G.Settings.defeat_auto_remove_delay = 0
end
if _G.Settings.display_morale == nil then
    _G.Settings.display_morale = false
end
-- redesign defaults. size_preset drives the card dimensions; the old width / tooltip_height /
-- tooltip_spacing values are kept and become the "custom" case, so nothing is lost by switching
-- back and forth. see docs/redesign/HANDOFF.md.

-- sort was a 0/1 number; carry an existing savefile over to the named value and drop the old key.
-- duration_bar_height went with it: the bars are part of the card's fixed height now, so a user
-- height would only push the card out of shape.
if _G.Settings.sort_order == nil then
    _G.Settings.sort_order = (_G.Settings.sort == 0) and "pinned" or "name"
end
_G.Settings.sort = nil
_G.Settings.duration_bar_height = nil

if _G.Settings.size_preset == nil then
    _G.Settings.size_preset = "comfortable"
end
if _G.Settings.show_type_line == nil then
    _G.Settings.show_type_line = true
end
if _G.Settings.name_outline == nil then
    _G.Settings.name_outline = true
end
if _G.Settings.morale_warn_pct == nil then
    _G.Settings.morale_warn_pct = 25
end
if _G.Settings.morale_show_number == nil then
    _G.Settings.morale_show_number = true
end
if _G.Settings.morale_grey_stale == nil then
    _G.Settings.morale_grey_stale = true
end
if _G.Settings.show_drag_handle == nil then
    _G.Settings.show_drag_handle = false
end
if _G.Settings.show_dismiss == nil then
    _G.Settings.show_dismiss = true
end
if _G.Settings.cc_custom_skills == nil then _G.Settings.cc_custom_skills = {} end
for i = 1, 5 do
    if _G.Settings.cc_custom_skills[i] == nil then
        _G.Settings.cc_custom_skills[i] = { name = "", duration = 30, enabled = false, icon = 1090541222 }
    end
    if _G.Settings.cc_custom_skills[i].icon == nil then
        _G.Settings.cc_custom_skills[i].icon = 1090541222
    end
end
if _G.Settings.cc_skills == nil then _G.Settings.cc_skills = {} end
local function _defaultSkill(key, duration)
    if _G.Settings.cc_skills[key] == nil then
        _G.Settings.cc_skills[key] = { enabled = true, duration = duration }
    end
end
_defaultSkill("blinding_flash",    30)
_defaultSkill("riddle",            30)
_defaultSkill("distracting_shot",  35)
_defaultSkill("thrum_of_the_sea",  25)
_defaultSkill("sop_righteousness", 15)
if _G.Settings.color_player   == nil then _G.Settings.color_player   = {r=0.157, g=0.365, b=0.2} end
if _G.Settings.color_npc      == nil then _G.Settings.color_npc      = {r=0,     g=0,     b=0}   end
if _G.Settings.color_item     == nil then _G.Settings.color_item     = {r=0.2,   g=0.2,   b=0.2} end
if _G.Settings.color_targeted == nil then _G.Settings.color_targeted = {r=1,     g=1,     b=0}   end
-- the card background. every other fill the card takes — hover, target, defeated, CC breaking — is
-- derived from this one in Theme.CardFill, so there is a single colour to set.
if _G.Settings.color_card     == nil then _G.Settings.color_card     = {r=0.110, g=0.118, b=0.169} end

-- these four keys predate the redesign, which stopped reading them: the card painted itself from
-- the Nocturne tokens instead, so an old savefile still carries black NPCs and a yellow target.
-- the card reads them again now, so those values are carried over to the redesign palette once —
-- nothing visible is lost, since 2.0 was never drawing them.
if _G.Settings.colors_nocturne == nil then

    _G.Settings.color_player   = {r=0.294, g=0.561, b=0.369}  -- green
    _G.Settings.color_npc      = {r=0.459, g=0.475, b=0.549}  -- greyRail
    _G.Settings.color_item     = {r=0.247, g=0.259, b=0.302}  -- greyRailDim
    _G.Settings.color_targeted = {r=0.569, g=0.518, b=0.851}  -- accent
    _G.Settings.color_card     = {r=0.110, g=0.118, b=0.169}  -- card

    _G.Settings.colors_nocturne = true

end

local function toColor(t) return Turbine.UI.Color(t.r, t.g, t.b) end
_G.Settings.tooltip_color_player        = toColor(_G.Settings.color_player)
_G.Settings.tooltip_color_npc           = toColor(_G.Settings.color_npc)
_G.Settings.tooltip_color_item          = toColor(_G.Settings.color_item)
_G.Settings.tooltip_targeted_color      = toColor(_G.Settings.color_targeted)
_G.Settings.tooltip_defeated_color      = Turbine.UI.Color.Gray
_G.Settings.tooltip_defeated_text_color = Turbine.UI.Color(0.8, 0.8, 0.8)

end

---------------------------------------------------------------------------------------------------
-- boot
--
-- this character's own file, falling back to the global one for a character that has never saved

_G.Settings = LoadScope(Turbine.DataScope.Character)

local firstRun = (_G.Settings == nil and globalCache == nil)

-- a copy, so a character running on the global copy does not edit the cache as it goes
if _G.Settings == nil then
    _G.Settings = DeepCopy(globalCache)
end

_G.NormaliseSettings()

if firstRun then
    Turbine.Shell.WriteLine("potato: setup your keybinding in the plugin manager options!")
    _G.SaveSettings()
end

---------------------------------------------------------------------------------------------------

function _G.ShowAnchor(value)
    Potato:ShowAnchor(value)
end

---------------------------------------------------------------------------------------------------

Potato = ui.PotatoWindow()
Options = ui.OptionPanel()

plugin.GetOptionsPanel = function( self )
  return Options
end




-- split into groups by type