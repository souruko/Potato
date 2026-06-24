import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

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
    _G.Settings.tooltip_label_spacing = 5
    _G.Settings.highlight_defeated = true
    _G.Settings.display_durations = true
    _G.Settings.sort = 1 -- 0=noSort 1=byName
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
if _G.Settings.color_player == nil then _G.Settings.color_player = {r=0.157, g=0.365, b=0.2} end
if _G.Settings.color_npc    == nil then _G.Settings.color_npc    = {r=0,     g=0,     b=0}   end
if _G.Settings.color_item   == nil then _G.Settings.color_item   = {r=0.2,   g=0.2,   b=0.2} end

local function toColor(t) return Turbine.UI.Color(t.r, t.g, t.b) end
_G.Settings.tooltip_color_player        = toColor(_G.Settings.color_player)
_G.Settings.tooltip_color_npc           = toColor(_G.Settings.color_npc)
_G.Settings.tooltip_color_item          = toColor(_G.Settings.color_item)
_G.Settings.tooltip_targeted_color      = Turbine.UI.Color.Yellow
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