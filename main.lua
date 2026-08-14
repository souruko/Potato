import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "Potato.Class"
import "Potato.Type"

import "Potato.settings"

import "Potato.ui.theme"
import "Potato.ui.potatoWindow"
import "Potato.ui.optionPanel"

import "Potato.chatParse"
import "Potato.targetChanged"


---------------------------------------------------------------------------------------------------
-- boot
--
-- this character's own file, falling back to the global one for a character that has never saved.
-- settings.lua owns the loading, the defaults and the 2.x migration; all that is left here is to
-- ask for them and to put the windows on screen.

local characterData = _G.LoadCharacterSettings()

local firstRun = _G.HasNoSettingsAtAll(characterData)

_G.Settings = characterData

if _G.Settings == nil then
    _G.Settings = _G.SettingsFallback()
end

_G.NormaliseSettings()

if firstRun then
    Turbine.Shell.WriteLine("potato: setup your keybinding in the plugin manager options!")
    _G.SaveSettings()
end

---------------------------------------------------------------------------------------------------
-- the windows
--
-- one PotatoWindow per entry in _G.Settings.windows, kept in _G.PotatoWindows at the same index.
-- window 1 always exists and cannot be removed; it is also the one that listens for key events and
-- hands them to whichever window the pressed key belongs to (see PotatoWindow.KeyDown).

_G.PotatoWindows = {}

local function CreateWindow(index)

    local window = ui.PotatoWindow(_G.Settings.windows[index], index)

    _G.PotatoWindows[index] = window

    return window

end

-- throws every window away and builds the list again from the settings. used after loading the
-- global copy, which can hold a different number of windows than this character had.
function _G.RebuildWindows()

    for i = #_G.PotatoWindows, 1, -1 do
        _G.PotatoWindows[i]:Destroy()
        _G.PotatoWindows[i] = nil
    end

    for i = 1, #_G.Settings.windows do
        CreateWindow(i)
    end

end

-- a copy of the window being viewed, nudged clear of it so it is not hidden underneath, with both
-- keys unbound so it cannot steal the copied window's keybinding. the drag handle comes on: a new
-- window is one you are about to place.
function _G.AddWindow(copyIndex)

    if #_G.Settings.windows >= _G.MAX_WINDOWS then
        return nil
    end

    local source = _G.Settings.windows[copyIndex] or _G.Settings.windows[1]
    local new = _G.DeepCopySettings(source)

    _G.NormaliseWindow(new)

    new.left = (new.left or 500) + 24
    new.top  = (new.top  or 500) + 24

    new.use_add_keybinding   = false
    new.use_clear_keybinding = false
    new.show_drag_handle     = true

    local index = #_G.Settings.windows + 1
    _G.Settings.windows[index] = new

    CreateWindow(index)

    _G.SaveSettings()

    return index

end

function _G.RemoveWindow(index)

    -- the first window is the plugin: there is always something to pin into
    if index == nil or index <= 1 or index > #_G.Settings.windows then
        return false
    end

    _G.PotatoWindows[index]:Destroy()

    table.remove(_G.PotatoWindows, index)
    table.remove(_G.Settings.windows, index)

    -- the windows above the removed one have all shifted down
    for i, window in ipairs(_G.PotatoWindows) do
        window.index = i
        window.settings = _G.Settings.windows[i]
    end

    _G.SaveSettings()

    return true

end

for i = 1, #_G.Settings.windows do
    CreateWindow(i)
end

---------------------------------------------------------------------------------------------------

Options = ui.OptionPanel()

plugin.GetOptionsPanel = function( self )
  return Options
end
