import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "Potato.ui.theme"
import "Potato.ui.potatoWindow"
import "Potato.ui.optionPanel"

import "Potato.chatParse"
import "Potato.targetChanged"


---------------------------------------------------------------------------------------------------
-- fake savefile

_G.SaveSettings = function ()
    Turbine.PluginData.Save(Turbine.DataScope.Character, "potatoSaveFile", _G.Settings, nil)
    Turbine.PluginData.Save(Turbine.DataScope.Account, "potatoSaveFile", _G.Settings, nil)
end

_G.Settings = Turbine.PluginData.Load( Turbine.DataScope.Character, "potatoSaveFile" , nil)

if _G.Settings == nil then
_G.Settings = Turbine.PluginData.Load( Turbine.DataScope.Account, "potatoSaveFile" , nil)

end

if _G.Settings == nil then

    _G.Settings = {}
    _G.Settings.left = 500
    _G.Settings.top = 500
    _G.Settings.width = 200
    _G.Settings.tooltip_height = 50
    _G.Settings.max_tooltip_count = 5
    _G.Settings.tooltip_spacing = 5
    _G.Settings.highlight_defeated = true
    _G.Settings.display_durations = true
    _G.Settings.sort_order = "name" -- "pinned" | "name"
    _G.Settings.keybinding_add = {}
    _G.Settings.keybinding_add.shift = false
    _G.Settings.keybinding_add.alt = false
    _G.Settings.keybinding_add.ctrl = false
    _G.Settings.keybinding_add.action = 268435706
    _G.Settings.keybinding_clear = {}
    _G.Settings.keybinding_clear.shift = false
    _G.Settings.keybinding_clear.alt = false
    _G.Settings.keybinding_clear.ctrl = true
    _G.Settings.keybinding_clear.action = 268435482
    _G.Settings.use_clear_keybinding = true
    _G.Settings.only_clear_dead = false

    Turbine.Shell.WriteLine("potato: setup your keybinding in the plugin manager options!")

    _G.SaveSettings()

end

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