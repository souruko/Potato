
-- settings
--
-- loading, saving, defaults and migrations.
--
-- the savefile holds a list of windows, each with its own complete copy of the settings — position,
-- size, colours, keybindings, CC skills, the lot. nothing is shared between them except the one
-- colors_nocturne migration flag, which is about the savefile rather than about any window.
--
--     _G.Settings = {
--         colors_nocturne = true,
--         windows = { { left = 500, ... }, { left = 700, ... } },
--     }
--
-- a savefile written before 3.0 is flat: one window's worth of keys at the top level. it is wrapped
-- into windows[1] on load, see NormaliseSettings below.
---------------------------------------------------------------------------------------------------

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
--
-- the global copy carries the whole window list, so loading it gives this character the same number
-- of windows, in the same places, as the character that saved it.

-- class instances (Turbine.UI.Color and friends) are handed over as they are, same as ConvertToEuro
-- does: copying them field by field would flatten them into something the game can no longer use.
function _G.DeepCopySettings(value)

    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return value
    end

    local copy = {}
    for key, inner in pairs(value) do
        copy[key] = _G.DeepCopySettings(inner)
    end

    return copy

end

local DeepCopy = _G.DeepCopySettings

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

    local data = DeepCopy(_G.Settings)

    WriteScope(Turbine.DataScope.Character, data)

    if mirrorToGlobal then
        WriteScope(Turbine.DataScope.Account, data)
        globalCache = data
    end

end

-- copies this character's settings over the global one
_G.SaveGlobalSettings = function ()

    local data = DeepCopy(_G.Settings)

    WriteScope(Turbine.DataScope.Account, data)
    globalCache = data

    return true

end

-- replaces this character's settings with the global ones, and keeps them. the caller has to
-- rebuild the windows afterwards: the global copy can hold a different number of them.
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

_G.LoadCharacterSettings = function ()
    return LoadScope(Turbine.DataScope.Character)
end

_G.HasNoSettingsAtAll = function (characterData)
    return characterData == nil and globalCache == nil
end

-- a character that has never saved starts from the global copy, if there is one. a copy, so it does
-- not edit the cache as it goes.
_G.SettingsFallback = function ()
    return DeepCopy(globalCache)
end

---------------------------------------------------------------------------------------------------
-- what belongs to a window
--
-- everything except colors_nocturne, which is about the savefile rather than about any window. the
-- migration works that way round on purpose: a key it has never heard of belongs to a window far
-- more likely than not, and moving it is harmless, while leaving it stranded at the top level would
-- quietly reset the setting.

local SAVEFILE_KEYS = {
    colors_nocturne = true,
    windows = true,
}

-- keys the plugin has stopped reading. every savefile in the wild still carries some of them, and
-- there is no point copying them into each new window, so they are dropped on load.
--
-- tooltip_color / short_names / tooltip_label_spacing predate 2.0. the six tooltip_*_color values
-- were Turbine.UI.Color objects derived from the colour settings on every load; nothing has read
-- them since the redesign. sort and duration_bar_height are handled by the migrations below.
local DEAD_KEYS = {
    "tooltip_color",
    "short_names",
    "tooltip_label_spacing",
    "tooltip_color_player",
    "tooltip_color_npc",
    "tooltip_color_item",
    "tooltip_targeted_color",
    "tooltip_defeated_color",
    "tooltip_defeated_text_color",
}

_G.MAX_WINDOWS = 5

---------------------------------------------------------------------------------------------------
-- defaults and migrations for one window
--
-- every key is filled in only when it is missing, so this can run on a fresh window table, on one
-- lifted out of a savefile from any older version, and on whatever the global copy happens to hold.

function _G.NormaliseWindow(w)

for _, key in ipairs(DEAD_KEYS) do
    w[key] = nil
end

local function default(key, value)
    if w[key] == nil then
        w[key] = value
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
default("use_add_keybinding", true)
default("use_clear_keybinding", true)
default("only_clear_dead", false)

if w.reverseFill == nil then
    w.reverseFill = false
end
if w.horizontal == nil then
    w.horizontal = false
end
if w.cc_warning_threshold == nil then
    w.cc_warning_threshold = 5
end
if w.defeat_auto_remove_delay == nil then
    w.defeat_auto_remove_delay = 0
end
if w.display_morale == nil then
    w.display_morale = false
end
-- redesign defaults. size_preset drives the card dimensions; the old width / tooltip_height /
-- tooltip_spacing values are kept and become the "custom" case, so nothing is lost by switching
-- back and forth. see docs/redesign/HANDOFF.md.

-- sort was a 0/1 number; carry an existing savefile over to the named value and drop the old key.
-- duration_bar_height went with it: the bars are part of the card's fixed height now, so a user
-- height would only push the card out of shape.
if w.sort_order == nil then
    w.sort_order = (w.sort == 0) and "pinned" or "name"
end
w.sort = nil
w.duration_bar_height = nil

if w.size_preset == nil then
    w.size_preset = "comfortable"
end
if w.show_type_line == nil then
    w.show_type_line = true
end
if w.name_outline == nil then
    w.name_outline = true
end
if w.morale_warn_pct == nil then
    w.morale_warn_pct = 25
end
if w.morale_show_number == nil then
    w.morale_show_number = true
end
if w.morale_grey_stale == nil then
    w.morale_grey_stale = true
end
if w.show_drag_handle == nil then
    w.show_drag_handle = false
end
if w.show_dismiss == nil then
    w.show_dismiss = true
end
if w.cc_custom_skills == nil then w.cc_custom_skills = {} end
for i = 1, 5 do
    if w.cc_custom_skills[i] == nil then
        w.cc_custom_skills[i] = { name = "", duration = 30, enabled = false, icon = 1090541222 }
    end
    if w.cc_custom_skills[i].icon == nil then
        w.cc_custom_skills[i].icon = 1090541222
    end
end
if w.cc_skills == nil then w.cc_skills = {} end
local function _defaultSkill(key, duration)
    if w.cc_skills[key] == nil then
        w.cc_skills[key] = { enabled = true, duration = duration }
    end
end
_defaultSkill("blinding_flash",    30)
_defaultSkill("riddle",            30)
_defaultSkill("distracting_shot",  35)
_defaultSkill("thrum_of_the_sea",  25)
_defaultSkill("sop_righteousness", 15)
if w.color_player   == nil then w.color_player   = {r=0.294, g=0.561, b=0.369} end
if w.color_npc      == nil then w.color_npc      = {r=0.459, g=0.475, b=0.549} end
if w.color_item     == nil then w.color_item     = {r=0.247, g=0.259, b=0.302} end
if w.color_targeted == nil then w.color_targeted = {r=0.569, g=0.518, b=0.851} end
-- the card background. every other fill the card takes — hover, target, defeated, CC breaking — is
-- derived from this one in Theme.CardFill, so there is a single colour to set.
if w.color_card     == nil then w.color_card     = {r=0.110, g=0.118, b=0.169} end

return w

end

-- a brand new window, everything at its default
function _G.DefaultWindowSettings()
    return _G.NormaliseWindow({})
end

---------------------------------------------------------------------------------------------------
-- defaults and migrations for the savefile as a whole

function _G.NormaliseSettings()

    if _G.Settings == nil then
        _G.Settings = {}
    end

    -- 2.x and older wrote one window's worth of keys flat at the top level. lift them into the
    -- first window and clear them off the top, so the upgraded savefile carries no leftovers.
    if _G.Settings.windows == nil then

        local first = {}

        for key, value in pairs(_G.Settings) do
            if not SAVEFILE_KEYS[key] then
                first[key] = value
            end
        end

        for key in pairs(first) do
            _G.Settings[key] = nil
        end

        _G.Settings.windows = { first }

    end

    if _G.Settings.windows[1] == nil then
        _G.Settings.windows[1] = {}
    end

    -- these four keys predate the redesign, which stopped reading them: the card painted itself from
    -- the Nocturne tokens instead, so an old savefile still carries black NPCs and a yellow target.
    -- the card reads them again now, so those values are carried over to the redesign palette once —
    -- nothing visible is lost, since 2.0 was never drawing them. a flag on the savefile rather than
    -- on a window: it is about the file's age, and an old file only ever has the one window.
    if _G.Settings.colors_nocturne == nil then

        for _, w in ipairs(_G.Settings.windows) do
            w.color_player   = {r=0.294, g=0.561, b=0.369}  -- green
            w.color_npc      = {r=0.459, g=0.475, b=0.549}  -- greyRail
            w.color_item     = {r=0.247, g=0.259, b=0.302}  -- greyRailDim
            w.color_targeted = {r=0.569, g=0.518, b=0.851}  -- accent
            w.color_card     = {r=0.110, g=0.118, b=0.169}  -- card
        end

        _G.Settings.colors_nocturne = true

    end

    for _, w in ipairs(_G.Settings.windows) do
        _G.NormaliseWindow(w)
    end

end
