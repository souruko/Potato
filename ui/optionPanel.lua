
-- OptionPanel
--
-- the settings panel shown in the plugin manager
--
-- a 150px tab rail and five panes, each sized to fit without scrolling. replaces the old
-- 600x1280 single scroll with its four separate apply buttons.
--
-- apply semantics, consistent across every pane: toggles commit immediately because they're cheap
-- and reversible; anything numeric or textual commits on the pane's Apply button.
---------------------------------------------------------------------------------------------------

import "Turbine.UI"
import "Turbine.UI.Lotro"

import "Potato.ui.theme"
import "Potato.ui.widgets"
import "Potato.ui.keys"


OptionPanel = class ( Turbine.UI.Control )

local PANEL_W   = 600
local PANEL_H   = 470
local RAIL_W    = 150
local PANE_W    = PANEL_W - RAIL_W
local PAD_X     = 20
local PAD_TOP   = 16
local FOOT_H    = 50
local CONTENT_H = PANEL_H - FOOT_H
local BODY_W    = PANE_W - (PAD_X * 2)

local TABS = { "Layout", "Keybindings", "Combat", "CC timers", "Appearance" }

-- a CC row and the number of custom ones that fit above the footer. the pane doesn't scroll, so the
-- add button stops offering new slots once the space is used up.
local CC_ROW_H     = 26
local CC_MAX_CUSTOM = 5

-- the exact-colour editor on the Appearance pane, which opens over the space between the swatch
-- rows and the previews
local EXACT_TOP = 170
local EXACT_H   = 102

local function SettingColor(t)
    if t == nil then return _G.Theme.color.greyRail end
    return Turbine.UI.Color(t.r, t.g, t.b)
end

---------------------------------------------------------------------------------------------------

function OptionPanel:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetSize(PANEL_W, PANEL_H)
    self:SetBackColor(_G.Theme.color.ground)

    self.panes = {}
    self.tabs = {}
    self.previews = {}

    self:BuildRail()

    self:BuildLayoutPane()
    self:BuildKeybindingsPane()
    self:BuildCombatPane()
    self:BuildCCPane()
    self:BuildAppearancePane()

    self:SelectTab(1)

end

---------------------------------------------------------------------------------------------------
-- tab rail

function OptionPanel:BuildRail()

    local color = _G.Theme.color

    local rail = Turbine.UI.Control()
    rail:SetParent(self)
    rail:SetPosition(0, 0)
    rail:SetSize(RAIL_W, PANEL_H)
    rail:SetBackColor(color.surfaceSunk)

    _G.Widgets.Rect(rail, RAIL_W - 1, 0, 1, PANEL_H, color.line)

    -- the LotRO gold band, kept as the brand block
    _G.Widgets.Rect(rail, 0, 8, RAIL_W, 24, color.goldBand)
    _G.Widgets.Label(
        rail, 12, 8, RAIL_W - 12, 24, "Potato",
        _G.Theme.font.band, color.goldText
    )

    for i, name in ipairs(TABS) do

        local y = 40 + ((i - 1) * _G.Theme.metrics.tabHeight)

        local tab = {}
        tab.fill = _G.Widgets.Rect(rail, 0, y, RAIL_W - 1, _G.Theme.metrics.tabHeight, color.surfaceSunk)
        tab.marker = _G.Widgets.Rect(rail, 0, y, 3, _G.Theme.metrics.tabHeight, color.accent)
        tab.label = _G.Widgets.Label(
            rail, 12, y, RAIL_W - 24, _G.Theme.metrics.tabHeight, name,
            _G.Theme.font.body, color.textMuted
        )

        tab.hit = Turbine.UI.Control()
        tab.hit:SetParent(rail)
        tab.hit:SetPosition(0, y)
        tab.hit:SetSize(RAIL_W - 1, _G.Theme.metrics.tabHeight)
        tab.hit:SetMouseVisible(true)

        local index = i
        tab.hit.MouseClick = function(sender, args)
            self:SelectTab(index)
        end

        self.tabs[i] = tab

    end

    -- rail footer
    local footTop = PANEL_H - 46
    _G.Widgets.Rect(rail, 0, footTop, RAIL_W - 1, 1, color.line)
    _G.Widgets.Label(
        rail, 12, footTop + 8, RAIL_W - 20, 30,
        "Saved per character",
        _G.Theme.font.help, color.textQuiet,
        Turbine.UI.ContentAlignment.TopLeft
    )
    _G.Widgets.Label(
        rail, 12, footTop + 22, RAIL_W - 20, 30,
        "Falls back to account",
        _G.Theme.font.help, color.textQuiet,
        Turbine.UI.ContentAlignment.TopLeft
    )

end

function OptionPanel:SelectTab(index)

    self.selectedTab = index

    for i, tab in ipairs(self.tabs) do
        local active = (i == index)
        tab.fill:SetBackColor(active and _G.Theme.color.surface or _G.Theme.color.surfaceSunk)
        tab.marker:SetVisible(active)
        tab.label:SetForeColor(active and _G.Theme.color.accentText or _G.Theme.color.textMuted)
    end

    for i, pane in ipairs(self.panes) do
        pane:SetVisible(i == index)
    end

end

---------------------------------------------------------------------------------------------------
-- pane scaffolding

function OptionPanel:NewPane(title)

    local pane = Turbine.UI.Control()
    pane:SetParent(self)
    pane:SetPosition(RAIL_W, 0)
    pane:SetSize(PANE_W, PANEL_H)
    pane:SetVisible(false)

    _G.Widgets.Label(
        pane, PAD_X, PAD_TOP, BODY_W, 22, title,
        _G.Theme.font.title, _G.Theme.color.text
    )

    self.panes[#self.panes + 1] = pane

    return pane

end

function OptionPanel:AddFooter(pane, onApply, onReset)

    _G.Widgets.Rect(pane, 0, CONTENT_H, PANE_W, 1, _G.Theme.color.line)

    _G.Widgets.Button(pane, PAD_X, CONTENT_H + 12, "Apply", function()
        if onApply then onApply() end
        _G.SaveSettings()
        Potato:ApplySettings()
        self:RefreshPreviews()
    end)

    _G.Widgets.Button(pane, PAD_X + 90, CONTENT_H + 12, "Reset section", function()
        if onReset then onReset() end
        _G.SaveSettings()
        Potato:ApplySettings()
        self:RefreshPreviews()
    end, true)

end

-- toggles commit as soon as they're clicked
function OptionPanel:Commit()

    _G.SaveSettings()
    Potato:ApplySettings()
    self:RefreshPreviews()

end

function OptionPanel:RegisterPreview(widget, state, bars)

    self.previews[#self.previews + 1] = { widget = widget, state = state, bars = bars }

end

-- previews re-render on every change on any pane, so the panel never has to be closed to see the
-- result of a setting
function OptionPanel:RefreshPreviews()

    for _, entry in ipairs(self.previews) do

        entry.widget:SetState(entry.state, entry.bars)

        -- the rail carries whatever colors the Appearance pane has been given
        if entry.state == "player" then
            entry.widget.rail:SetBackColor(SettingColor(_G.Settings.color_player))
        elseif entry.state == "object" then
            entry.widget.rail:SetBackColor(SettingColor(_G.Settings.color_item))
        elseif entry.state == "target" then
            entry.widget.rail:SetBackColor(SettingColor(_G.Settings.color_targeted))
        elseif entry.state == "npc" then
            entry.widget.rail:SetBackColor(SettingColor(_G.Settings.color_npc))
        end

        entry.widget.type:SetVisible(_G.Settings.show_type_line ~= false)

    end

end

---------------------------------------------------------------------------------------------------
-- pane 1 — Layout

function OptionPanel:BuildLayoutPane()

    local pane = self:NewPane("Layout")
    local y = PAD_TOP + 34

    self.dragHandleCheck = _G.Widgets.Checkbox(
        pane, PAD_X, y, "Show drag handle", _G.Settings.show_drag_handle,
        function(value)
            _G.Settings.show_drag_handle = value
            self:Commit()
        end
    )
    y = y + 28

    self.dismissCheck = _G.Widgets.Checkbox(
        pane, PAD_X, y, "Show close button on hover", _G.Settings.show_dismiss,
        function(value)
            _G.Settings.show_dismiss = value
            self:Commit()
        end
    )
    y = y + 22

    _G.Widgets.Help(pane, PAD_X, y, BODY_W,
        "With it off, clear trackers with the keybinding instead.")
    y = y + 20

    -- size preset
    _G.Widgets.Label(pane, PAD_X, y, 70, 22, "Size", _G.Theme.font.body, _G.Theme.color.textMuted)

    local presetIndex = 2
    if _G.Settings.size_preset == "compact" then presetIndex = 1
    elseif _G.Settings.size_preset == "custom" then presetIndex = 3 end

    self.sizeSegment = _G.Widgets.Segmented(
        pane, PAD_X + 70, y, { "Compact", "Comfortable", "Custom" }, presetIndex,
        function(index)
            _G.Settings.size_preset = ({ "compact", "comfortable", "custom" })[index]
            self:UpdateCustomEnabled()
            self:Commit()
        end
    )
    y = y + 30

    -- direction
    _G.Widgets.Label(pane, PAD_X, y, 70, 22, "Direction", _G.Theme.font.body, _G.Theme.color.textMuted)

    self.directionSegment = _G.Widgets.Segmented(
        pane, PAD_X + 70, y, { "Vertical", "Horizontal" }, _G.Settings.horizontal and 2 or 1,
        function(index)
            _G.Settings.horizontal = (index == 2)
            self:Commit()
        end
    )

    self.reverseFillCheck = _G.Widgets.Checkbox(
        pane, PAD_X + 70 + self.directionSegment.width + 16, y + 2, "Fill in reverse",
        _G.Settings.reverseFill,
        function(value)
            _G.Settings.reverseFill = value
            self:Commit()
        end
    )
    y = y + 30

    -- order
    _G.Widgets.Label(pane, PAD_X, y, 70, 22, "Order", _G.Theme.font.body, _G.Theme.color.textMuted)

    self.orderSegment = _G.Widgets.Segmented(
        pane, PAD_X + 70, y, { "As pinned", "By name" },
        (_G.Settings.sort_order == "name") and 2 or 1,
        function(index)
            _G.Settings.sort_order = (index == 2) and "name" or "pinned"
            self:Commit()
        end
    )
    y = y + 36

    -- custom dimensions
    local stepX = PAD_X
    local function dimension(label, value, min, max, unit)

        _G.Widgets.Label(pane, stepX, y, 46, 20, label, _G.Theme.font.help, _G.Theme.color.textQuiet)
        local stepper = _G.Widgets.Stepper(pane, stepX, y + 16, {
            value = value, min = min, max = max, unit = unit or "",
        })
        stepX = stepX + stepper.width + 14

        return stepper

    end

    self.widthStepper  = dimension("Width",  _G.Settings.width,             80,  600)
    self.heightStepper = dimension("Height", _G.Settings.tooltip_height,    20,  200)
    self.gapStepper    = dimension("Gap",    _G.Settings.tooltip_spacing,   0,   40)
    self.maxStepper    = dimension("Max",    _G.Settings.max_tooltip_count, 1,   20)

    y = y + 44

    _G.Widgets.Help(pane, PAD_X, y, BODY_W,
        "Width, height and gap only apply to the Custom size.")
    y = y + 24

    -- live preview
    _G.Widgets.Divider(pane, PAD_X, y, BODY_W)
    y = y + 14

    local previewA = _G.Widgets.PreviewCard(pane, PAD_X, y, 200, 40,
        { name = "Cave-claw", state = "target", bars = false })
    local previewB = _G.Widgets.PreviewCard(pane, PAD_X + 210, y, 200, 40,
        { name = "Gimli", type = "FELLOWSHIP", state = "player", bars = false })

    self:RegisterPreview(previewA, "target", false)
    self:RegisterPreview(previewB, "player", false)

    y = y + 46
    _G.Widgets.Help(pane, PAD_X, y, BODY_W,
        "Preview updates as you change anything on any tab.")

    self:UpdateCustomEnabled()

    self:AddFooter(pane,
        function()
            _G.Settings.width             = self.widthStepper:GetValue()
            _G.Settings.tooltip_height    = self.heightStepper:GetValue()
            _G.Settings.tooltip_spacing   = self.gapStepper:GetValue()
            _G.Settings.max_tooltip_count = self.maxStepper:GetValue()
        end,
        function()
            _G.Settings.size_preset = "comfortable"
            _G.Settings.horizontal = false
            _G.Settings.reverseFill = false
            _G.Settings.sort_order = "name"
            _G.Settings.show_drag_handle = false
            _G.Settings.show_dismiss = true
            _G.Settings.width = 260
            _G.Settings.tooltip_height = 52
            _G.Settings.tooltip_spacing = 2
            _G.Settings.max_tooltip_count = 5

            self.sizeSegment:SetSelected(2)
            self.directionSegment:SetSelected(1)
            self.orderSegment:SetSelected(2)
            self.reverseFillCheck:SetChecked(false)
            self.dragHandleCheck:SetChecked(false)
            self.dismissCheck:SetChecked(true)
            self.widthStepper:SetValue(260)
            self.heightStepper:SetValue(52)
            self.gapStepper:SetValue(2)
            self.maxStepper:SetValue(5)
            self:UpdateCustomEnabled()
        end
    )

end

-- the dimension steppers only mean anything under the Custom preset
function OptionPanel:UpdateCustomEnabled()

    local custom = (_G.Settings.size_preset == "custom")

    self.widthStepper:SetEnabled(custom)
    self.heightStepper:SetEnabled(custom)
    self.gapStepper:SetEnabled(custom)

end

---------------------------------------------------------------------------------------------------
-- pane 2 — Keybindings

function OptionPanel:BuildKeybindingsPane()

    local pane = self:NewPane("Keybindings")
    local y = PAD_TOP + 34

    -- fixed columns, so both rows line up and neither can be pushed into the next by a long
    -- binding. the row has to close by BODY_W: 110 label + 126 cap + two 78px buttons + gaps.
    local LABEL_W = 110
    local CAP_X   = PAD_X + LABEL_W + 4
    local CAP_MAX = 126
    local BTN1_X  = CAP_X + CAP_MAX + 6
    local BTN2_X  = BTN1_X + 84

    -- pin
    _G.Widgets.Label(pane, PAD_X, y, LABEL_W, 26, "Pin target",
        _G.Theme.font.body, _G.Theme.color.text)

    self.addKeyCap = _G.Widgets.KeyCap(
        pane, CAP_X, y, _G.Keys.Format(_G.Settings.keybinding_add), CAP_MAX)

    _G.Widgets.Button(pane, BTN1_X, y, "Rebind", function()
        self:BeginCapture("add")
    end)

    y = y + 30
    _G.Widgets.Help(pane, PAD_X, y, BODY_W,
        "Pins whatever you have selected. Press again on the same target to un-pin.")
    y = y + 30

    -- clear
    _G.Widgets.Label(pane, PAD_X, y, LABEL_W, 26, "Clear trackers",
        _G.Theme.font.body, _G.Theme.color.text)

    self.clearKeyCap = _G.Widgets.KeyCap(
        pane, CAP_X, y, _G.Keys.Format(_G.Settings.keybinding_clear), CAP_MAX)

    _G.Widgets.Button(pane, BTN1_X, y, "Rebind", function()
        self:BeginCapture("clear")
    end)

    _G.Widgets.Button(pane, BTN2_X, y, "Unbind", function()
        _G.Settings.use_clear_keybinding = false
        self.clearKeyCap:SetText("unbound")
        self:Commit()
    end, true)

    y = y + 32

    self.onlyDeadCheck = _G.Widgets.Checkbox(
        pane, PAD_X, y, "Clear defeated only", _G.Settings.only_clear_dead,
        function(value)
            _G.Settings.only_clear_dead = value
            self:Commit()
        end
    )
    y = y + 36

    -- inline capture prompt, replacing the old fullscreen overlay
    self.capturePrompt = Turbine.UI.Control()
    self.capturePrompt:SetParent(pane)
    self.capturePrompt:SetPosition(PAD_X, y)
    self.capturePrompt:SetSize(BODY_W, 110)
    self.capturePrompt:SetVisible(false)
    self.capturePrompt:SetWantsKeyEvents(true)

    _G.Widgets.Box(self.capturePrompt, 0, 0, BODY_W, 110, _G.Theme.color.card, _G.Theme.color.line)

    _G.Widgets.Label(self.capturePrompt, 14, 12, BODY_W - 28, 14, "WHILE REBINDING",
        _G.Theme.font.columnHead, _G.Theme.color.textQuiet)

    _G.Widgets.Box(self.capturePrompt, 14, 32, BODY_W - 28, 56, _G.Theme.color.well, _G.Theme.color.line)

    _G.Widgets.Label(self.capturePrompt, 28, 32, 90, 56, "Press any key",
        _G.Theme.font.body, _G.Theme.color.text)

    local escCap = _G.Widgets.KeyCap(self.capturePrompt, 130, 47)
    escCap:SetText("Esc")
    escCap:SetAccent(true)

    _G.Widgets.Label(self.capturePrompt, 180, 32, 90, 56, "cancels",
        _G.Theme.font.body, _G.Theme.color.textMuted)

    self.capturePrompt.KeyDown = function(sender, args)
        self:HandleCapture(args)
    end

    self:AddFooter(pane, nil, function()
        _G.Settings.keybinding_add   = { shift = false, alt = false, ctrl = false, action = 268435706 }
        _G.Settings.keybinding_clear = { shift = false, alt = false, ctrl = true,  action = 268435482 }
        _G.Settings.use_clear_keybinding = true
        _G.Settings.only_clear_dead = false
        self.addKeyCap:SetText(_G.Keys.Format(_G.Settings.keybinding_add))
        self.clearKeyCap:SetText(_G.Keys.Format(_G.Settings.keybinding_clear))
        self.onlyDeadCheck:SetChecked(false)
    end)

end

function OptionPanel:BeginCapture(which)

    self.capturing = which
    self.capturePrompt:SetVisible(true)
    self.capturePrompt:Focus()

end

function OptionPanel:HandleCapture(args)

    if self.capturing == nil then return end

    -- ignore the modifiers themselves
    if args.Action == 92 or args.Action == 19 then return end

    -- esc cancels
    if args.Action == 145 then
        self.capturing = nil
        self.capturePrompt:SetVisible(false)
        return
    end

    local binding = {
        shift  = args.Shift,
        alt    = args.Alt,
        ctrl   = args.Control,
        action = args.Action,
    }

    if self.capturing == "add" then
        _G.Settings.keybinding_add = binding
        self.addKeyCap:SetText(_G.Keys.Format(binding))
    else
        _G.Settings.keybinding_clear = binding
        _G.Settings.use_clear_keybinding = true
        self.clearKeyCap:SetText(_G.Keys.Format(binding))
    end

    -- the code -> name map is built from the game's Action enum and doesn't cover every key, so
    -- say so rather than silently showing a number
    if _G.Keys.IsUnmapped(args.Action) then
        Turbine.Shell.WriteLine(
            "potato: no name known for key code " .. tostring(args.Action) ..
            " - add it to the overrides table in ui/keys.lua to show it as a key."
        )
    end

    self.capturing = nil
    self.capturePrompt:SetVisible(false)
    self:Commit()

end

---------------------------------------------------------------------------------------------------
-- pane 3 — Combat

function OptionPanel:BuildCombatPane()

    local pane = self:NewPane("Combat")
    local y = PAD_TOP + 34

    self.dimDefeatedCheck = _G.Widgets.Checkbox(
        pane, PAD_X, y, "Dim defeated targets", _G.Settings.highlight_defeated,
        function(value)
            _G.Settings.highlight_defeated = value
            self:Commit()
        end
    )
    y = y + 28

    _G.Widgets.Label(pane, PAD_X, y, 130, 20, "Remove after defeat",
        _G.Theme.font.body, _G.Theme.color.text)
    self.defeatDelayStepper = _G.Widgets.Stepper(pane, PAD_X + 140, y, {
        value = _G.Settings.defeat_auto_remove_delay, min = 0, max = 120, unit = "s",
    })
    y = y + 24
    _G.Widgets.Help(pane, PAD_X, y, BODY_W, "0 keeps them.")
    y = y + 24

    _G.Widgets.Divider(pane, PAD_X, y, BODY_W)
    y = y + 16

    self.moraleCheck = _G.Widgets.Checkbox(
        pane, PAD_X, y, "Show morale bar", _G.Settings.display_morale,
        function(value)
            _G.Settings.display_morale = value
            self:Commit()
        end
    )
    y = y + 28

    _G.Widgets.Label(pane, PAD_X, y, 130, 20, "Turn red under",
        _G.Theme.font.body, _G.Theme.color.text)
    self.moraleWarnStepper = _G.Widgets.Stepper(pane, PAD_X + 140, y, {
        value = _G.Settings.morale_warn_pct, min = 0, max = 100, step = 5, unit = "%",
    })
    y = y + 28

    self.moraleNumberCheck = _G.Widgets.Checkbox(
        pane, PAD_X, y, "Show the percentage as a number", _G.Settings.morale_show_number,
        function(value)
            _G.Settings.morale_show_number = value
            self:Commit()
        end
    )
    y = y + 28

    self.moraleStaleCheck = _G.Widgets.Checkbox(
        pane, PAD_X, y, "Grey out stale morale", _G.Settings.morale_grey_stale,
        function(value)
            _G.Settings.morale_grey_stale = value
            self:Commit()
        end
    )
    y = y + 22

    _G.Widgets.Help(pane, PAD_X, y, BODY_W,
        "Morale only updates while the game sends events for that entity. After")
    _G.Widgets.Help(pane, PAD_X, y + 13, BODY_W,
        "five seconds of silence the bar fades to grey rather than showing a")
    _G.Widgets.Help(pane, PAD_X, y + 26, BODY_W,
        "stale figure as if it were live.")
    y = y + 48

    local preview = _G.Widgets.PreviewCard(pane, PAD_X, y, 200, 52,
        { name = "Cave-claw", state = "npc", bars = true })
    self:RegisterPreview(preview, "npc", true)

    _G.Widgets.Help(pane, PAD_X + 212, y + 8, BODY_W - 212,
        "Both bars fit inside the card")
    _G.Widgets.Help(pane, PAD_X + 212, y + 21, BODY_W - 212,
        "- turning morale on never")
    _G.Widgets.Help(pane, PAD_X + 212, y + 34, BODY_W - 212,
        "changes the height of your HUD.")

    self:AddFooter(pane,
        function()
            _G.Settings.defeat_auto_remove_delay = self.defeatDelayStepper:GetValue()
            _G.Settings.morale_warn_pct = self.moraleWarnStepper:GetValue()
        end,
        function()
            _G.Settings.highlight_defeated = true
            _G.Settings.defeat_auto_remove_delay = 0
            _G.Settings.display_morale = false
            _G.Settings.morale_warn_pct = 25
            _G.Settings.morale_show_number = true
            _G.Settings.morale_grey_stale = true

            self.dimDefeatedCheck:SetChecked(true)
            self.moraleCheck:SetChecked(false)
            self.moraleNumberCheck:SetChecked(true)
            self.moraleStaleCheck:SetChecked(true)
            self.defeatDelayStepper:SetValue(0)
            self.moraleWarnStepper:SetValue(25)
        end
    )

end

---------------------------------------------------------------------------------------------------
-- pane 4 — CC timers

local CC_SKILLS = {
    { key = "blinding_flash",    name = "Blinding Flash",   class = "Lore-master" },
    { key = "riddle",            name = "Riddle",           class = "Burglar" },
    { key = "distracting_shot",  name = "Distracting Shot", class = "Hunter" },
    { key = "thrum_of_the_sea",  name = "Thrum of the Sea", class = "Mariner" },
    { key = "sop_righteousness", name = "SoP: Righteousness", class = "Lore-master" },
}

function OptionPanel:BuildCCPane()

    local pane = self:NewPane("CC timers")
    local y = PAD_TOP + 34

    self.ccEnabledCheck = _G.Widgets.Checkbox(
        pane, PAD_X, y, "Show timers", _G.Settings.display_durations,
        function(value)
            _G.Settings.display_durations = value
            self:Commit()
        end
    )

    _G.Widgets.Label(pane, PAD_X + 200, y, 80, 20, "Warn under",
        _G.Theme.font.body, _G.Theme.color.text)
    self.ccWarnStepper = _G.Widgets.Stepper(pane, PAD_X + 285, y - 1, {
        value = _G.Settings.cc_warning_threshold, min = 1, max = 60, unit = "s",
    })
    y = y + 30

    -- skill table
    local COL_NAME = PAD_X + 30
    local COL_DUR  = PAD_X + 270

    _G.Widgets.Label(pane, COL_NAME, y, 200, 16, "SKILL",
        _G.Theme.font.columnHead, _G.Theme.color.textQuiet)
    _G.Widgets.Label(pane, COL_DUR, y, 80, 16, "DURATION",
        _G.Theme.font.columnHead, _G.Theme.color.textQuiet)
    _G.Widgets.RowSeparator(pane, PAD_X, y + 18, BODY_W, true)
    y = y + 22

    self.ccChecks = {}
    self.ccSteppers = {}

    for _, skill in ipairs(CC_SKILLS) do

        local saved = _G.Settings.cc_skills[skill.key]
        local key = skill.key

        local check = _G.Widgets.Checkbox(pane, PAD_X, y + 3, "", saved.enabled, function(value)
            _G.Settings.cc_skills[key].enabled = value
            self:Commit()
        end)
        check.control:SetSize(20, 18)

        _G.Widgets.Label(pane, COL_NAME, y, 240, 22,
            skill.name .. _G.Theme.sep .. skill.class,
            _G.Theme.font.control, _G.Theme.color.text)

        local stepper = _G.Widgets.Stepper(pane, COL_DUR, y + 1, {
            value = saved.duration, min = 1, max = 300, unit = "s", width = 36,
        })

        _G.Widgets.RowSeparator(pane, PAD_X, y + CC_ROW_H - 1, BODY_W)

        self.ccChecks[key] = check
        self.ccSteppers[key] = stepper

        y = y + CC_ROW_H

    end

    -- custom skills. the five always-visible blank rows are gone: only filled slots render, and
    -- the add button claims the next free one
    self.customRowTop = y
    self.customRows = {}
    self:RebuildCustomRows()

    self:AddFooter(pane,
        function()
            for _, skill in ipairs(CC_SKILLS) do
                _G.Settings.cc_skills[skill.key].duration = self.ccSteppers[skill.key]:GetValue()
            end
            _G.Settings.cc_warning_threshold = self.ccWarnStepper:GetValue()

            for _, row in ipairs(self.customRows) do
                local slot = _G.Settings.cc_custom_skills[row.index]
                slot.name     = row.nameBox:GetText() or ""
                slot.duration = row.stepper:GetValue()
                slot.icon     = tonumber(row.iconBox:GetText()) or slot.icon
                slot.enabled  = (slot.name ~= "")
            end

            -- a row whose name was cleared has just been retired, so redraw the list
            self:RebuildCustomRows()
        end,
        function()
            _G.Settings.display_durations = true
            _G.Settings.cc_warning_threshold = 5
            self.ccEnabledCheck:SetChecked(true)
            self.ccWarnStepper:SetValue(5)

            local defaults = { 30, 30, 35, 25, 15 }
            for i, skill in ipairs(CC_SKILLS) do
                _G.Settings.cc_skills[skill.key].enabled = true
                _G.Settings.cc_skills[skill.key].duration = defaults[i]
                self.ccChecks[skill.key]:SetChecked(true)
                self.ccSteppers[skill.key]:SetValue(defaults[i])
            end
        end
    )

end

function OptionPanel:RebuildCustomRows()

    local pane = self.panes[4]

    -- drop whatever is on screen and redraw from the settings
    for _, row in ipairs(self.customRows) do
        row.container:SetParent(nil)
    end
    self.customRows = {}

    local y = self.customRowTop

    for i, slot in ipairs(_G.Settings.cc_custom_skills) do

        if slot.name ~= nil and slot.name ~= "" and #self.customRows < CC_MAX_CUSTOM then

            local container = Turbine.UI.Control()
            container:SetParent(pane)
            container:SetPosition(0, y)
            container:SetSize(PANE_W, CC_ROW_H)

            local nameBox = Turbine.UI.Lotro.TextBox()
            nameBox:SetParent(container)
            nameBox:SetPosition(PAD_X + 30, 1)
            nameBox:SetSize(160, 20)
            nameBox:SetFont(_G.Theme.font.control)
            nameBox:SetText(slot.name)

            local iconBox = Turbine.UI.Lotro.TextBox()
            iconBox:SetParent(container)
            iconBox:SetPosition(PAD_X + 200, 1)
            iconBox:SetSize(62, 20)
            iconBox:SetFont(_G.Theme.font.help)
            iconBox:SetText(tostring(slot.icon or 1090541222))

            local stepper = _G.Widgets.Stepper(container, PAD_X + 270, 1, {
                value = slot.duration, min = 1, max = 300, unit = "s", width = 36,
            })

            -- clearing the name would do it too, but that only takes effect on Apply
            local index = i
            _G.Widgets.Button(container, PAD_X + 360, 0, "x", function()
                self:RemoveCustomSkill(index)
            end, true)

            _G.Widgets.RowSeparator(container, PAD_X, CC_ROW_H - 1, BODY_W)

            self.customRows[#self.customRows + 1] = {
                index = i, container = container,
                nameBox = nameBox, stepper = stepper, iconBox = iconBox,
            }

            y = y + CC_ROW_H

        end

    end

    if self.addSkillButton ~= nil then
        self.addSkillButton.control:SetParent(nil)
        self.addSkillButton = nil
    end

    if #self.customRows < CC_MAX_CUSTOM then
        self.addSkillButton = _G.Widgets.Button(pane, PAD_X, y + 4, "+ Add a custom skill", function()
            self:AddCustomSkill()
        end, true)
    end

    if self.ccHelp ~= nil then
        self.ccHelp:SetParent(nil)
    end
    self.ccHelp = _G.Widgets.Help(pane, PAD_X, y + 34, BODY_W,
        "Durations are the base skill length - resists and diminishing returns still apply.")

end

function OptionPanel:RemoveCustomSkill(index)

    local slot = _G.Settings.cc_custom_skills[index]

    if slot ~= nil then
        slot.name = ""
        slot.enabled = false
    end

    _G.SaveSettings()
    self:RebuildCustomRows()

end

function OptionPanel:AddCustomSkill()

    if #self.customRows >= CC_MAX_CUSTOM then return end

    -- claim the first free slot, growing the list if they're all taken
    local slot
    for i = 1, #_G.Settings.cc_custom_skills do
        local candidate = _G.Settings.cc_custom_skills[i]
        if candidate.name == nil or candidate.name == "" then
            slot = candidate
            break
        end
    end

    if slot == nil then
        slot = { duration = 30, enabled = false, icon = 1090541222 }
        _G.Settings.cc_custom_skills[#_G.Settings.cc_custom_skills + 1] = slot
    end

    slot.name = "New skill"
    slot.enabled = false

    _G.SaveSettings()
    self:RebuildCustomRows()

end

---------------------------------------------------------------------------------------------------
-- pane 5 — Appearance

local SWATCH_SETS = {
    { key = "color_player",   label = "Players",     tokens = { "green", "swatchTeal", "swatchBrass", "greyRail" } },
    { key = "color_npc",      label = "NPCs",        tokens = { "greyRail", "swatchTeal", "swatchBrass", "green" } },
    { key = "color_item",     label = "Objects",     tokens = { "greyRailDim", "swatchTeal", "swatchBrass", "greyRail" } },
    { key = "color_targeted", label = "Your target", tokens = { "accent", "goldText", "red", "swatchPale" } },
}

function OptionPanel:BuildAppearancePane()

    local pane = self:NewPane("Appearance")
    local y = PAD_TOP + 34

    self.swatchRows = {}

    for _, set in ipairs(SWATCH_SETS) do

        _G.Widgets.Label(pane, PAD_X, y, 90, 20, set.label,
            _G.Theme.font.body, _G.Theme.color.text)

        local row = { key = set.key, swatches = {} }
        local x = PAD_X + 100

        for i, token in ipairs(set.tokens) do

            local color = _G.Theme.color[token]
            local index = i

            local swatch = _G.Widgets.Swatch(pane, x, y, color, false, function()
                _G.Settings[set.key] = { r = color.R, g = color.G, b = color.B }
                for j, other in ipairs(row.swatches) do
                    other:SetSelected(j == index)
                end
                self:Commit()
            end)

            row.swatches[i] = swatch
            x = x + 28

        end

        local target = set
        _G.Widgets.SwatchAdd(pane, x, y, function()
            self:OpenExactColor(target)
        end)

        self.swatchRows[#self.swatchRows + 1] = row
        y = y + 30

    end

    y = y + 6
    _G.Widgets.Help(pane, PAD_X, y, BODY_W, "\"+\" opens the 0-255 boxes if you want an exact value.")
    y = y + 24

    _G.Widgets.Divider(pane, PAD_X, y, BODY_W)
    y = y + 14

    _G.Widgets.Label(pane, PAD_X, y, 80, 22, "Name text",
        _G.Theme.font.body, _G.Theme.color.textMuted)

    self.nameTextSegment = _G.Widgets.Segmented(
        pane, PAD_X + 85, y, { "Outlined", "Plain" },
        (_G.Settings.name_outline == false) and 2 or 1,
        function(index)
            _G.Settings.name_outline = (index == 1)
            self:Commit()
        end
    )

    self.typeLineCheck = _G.Widgets.Checkbox(
        pane, PAD_X + 85 + self.nameTextSegment.width + 16, y + 2, "Show type line",
        _G.Settings.show_type_line,
        function(value)
            _G.Settings.show_type_line = value
            self:Commit()
        end
    )

    -- clears the exact-colour editor, which opens over the space above the previews
    y = EXACT_TOP + EXACT_H + 10

    -- every state visible while you pick
    local states = { "target", "player", "object", "dead" }
    local names  = { "Cave-claw", "Gimli", "Chest", "Warg" }
    local x = PAD_X

    for i, state in ipairs(states) do
        local card = _G.Widgets.PreviewCard(pane, x, y, 196, 44,
            { name = names[i], state = state, bars = false })
        self:RegisterPreview(card, state, false)
        x = x + 204
        if i == 2 then
            x = PAD_X
            y = y + 50
        end
    end

    -- built last so it draws over the previews it covers while open
    self:BuildExactColor(pane)

    self:SyncSwatchSelection()

    self:AddFooter(pane, nil, function()
        _G.Settings.color_player   = { r = _G.Theme.color.green.R,       g = _G.Theme.color.green.G,       b = _G.Theme.color.green.B }
        _G.Settings.color_npc      = { r = _G.Theme.color.greyRail.R,    g = _G.Theme.color.greyRail.G,    b = _G.Theme.color.greyRail.B }
        _G.Settings.color_item     = { r = _G.Theme.color.greyRailDim.R, g = _G.Theme.color.greyRailDim.G, b = _G.Theme.color.greyRailDim.B }
        _G.Settings.color_targeted = { r = _G.Theme.color.accent.R,      g = _G.Theme.color.accent.G,      b = _G.Theme.color.accent.B }
        _G.Settings.name_outline = true
        _G.Settings.show_type_line = true

        self.nameTextSegment:SetSelected(1)
        self.typeLineCheck:SetChecked(true)
        self.exactBox:SetVisible(false)
        self.exactSet = nil
        self:SyncSwatchSelection()
    end)

end

---------------------------------------------------------------------------------------------------
-- exact color
--
-- the "+" at the end of a swatch row. one editor serves all four rows: it opens over the previews,
-- pointed at whichever row asked for it. 0-255 because that's what people have written down, even
-- though Turbine takes floats.

function OptionPanel:BuildExactColor(pane)

    local box = Turbine.UI.Control()
    box:SetParent(pane)
    box:SetPosition(PAD_X, EXACT_TOP)
    box:SetSize(BODY_W, EXACT_H)
    box:SetVisible(false)
    box:SetMouseVisible(true)

    _G.Widgets.Box(box, 0, 0, BODY_W, EXACT_H, _G.Theme.color.card, _G.Theme.color.line)

    self.exactTitle = _G.Widgets.Label(box, 12, 8, 300, 14, "EXACT COLOUR",
        _G.Theme.font.columnHead, _G.Theme.color.textQuiet)

    self.exactPreview = _G.Widgets.Rect(box, 360, 8, 34, 34, _G.Theme.color.greyRail)

    local function channel(label, x)

        _G.Widgets.Label(box, x, 36, 14, 20, label,
            _G.Theme.font.control, _G.Theme.color.textMuted)

        return _G.Widgets.Stepper(box, x + 16, 36, {
            value = 0, min = 0, max = 255,
            onChange = function() self:RefreshExactPreview() end,
        })

    end

    self.exactR = channel("R", 12)
    self.exactG = channel("G", 120)
    self.exactB = channel("B", 228)

    _G.Widgets.Button(box, 12, 66, "Use this", function()
        self:CommitExactColor()
    end)

    _G.Widgets.Button(box, 100, 66, "Cancel", function()
        self.exactBox:SetVisible(false)
        self.exactSet = nil
    end, true)

    self.exactBox = box

end

function OptionPanel:RefreshExactPreview()

    self.exactPreview:SetBackColor(Turbine.UI.Color(
        self.exactR:GetValue() / 255,
        self.exactG:GetValue() / 255,
        self.exactB:GetValue() / 255
    ))

end

function OptionPanel:OpenExactColor(set)

    self.exactSet = set

    local saved = _G.Settings[set.key] or { r = 0, g = 0, b = 0 }

    self.exactTitle:SetText("EXACT COLOUR" .. _G.Theme.sep .. string.upper(set.label))
    self.exactR:SetValue(math.floor(saved.r * 255 + 0.5))
    self.exactG:SetValue(math.floor(saved.g * 255 + 0.5))
    self.exactB:SetValue(math.floor(saved.b * 255 + 0.5))
    self:RefreshExactPreview()

    self.exactBox:SetVisible(true)

end

function OptionPanel:CommitExactColor()

    if self.exactSet == nil then return end

    _G.Settings[self.exactSet.key] = {
        r = self.exactR:GetValue() / 255,
        g = self.exactG:GetValue() / 255,
        b = self.exactB:GetValue() / 255,
    }

    self.exactBox:SetVisible(false)
    self.exactSet = nil

    self:SyncSwatchSelection()
    self:Commit()

end

-- marks whichever swatch matches the saved color
function OptionPanel:SyncSwatchSelection()

    for _, row in ipairs(self.swatchRows) do

        local saved = _G.Settings[row.key]

        for i, swatch in ipairs(row.swatches) do
            local c = swatch.swatch:GetBackColor()
            local match = saved ~= nil
                and math.abs(c.R - saved.r) < 0.01
                and math.abs(c.G - saved.g) < 0.01
                and math.abs(c.B - saved.b) < 0.01
            swatch:SetSelected(match)
        end

    end

end
