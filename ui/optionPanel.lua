
-- Section header band: dark amber background, gold outlined title
local HEADER_H  = 24
local HEADER_BG = Turbine.UI.Color(0.22, 0.16, 0.05)
local HEADER_FG = Turbine.UI.Color(0.9, 0.75, 0.35)

local function makeHeader(parent, y, text)
    local bg = Turbine.UI.Control()
    bg:SetParent(parent)
    bg:SetPosition(0, y)
    bg:SetSize(560, HEADER_H)
    bg:SetBackColor(HEADER_BG)

    local lbl = Turbine.UI.Label()
    lbl:SetParent(bg)
    lbl:SetPosition(10, 0)
    lbl:SetSize(540, HEADER_H)
    lbl:SetFont(Turbine.UI.Lotro.Font.Verdana16)
    lbl:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    lbl:SetForeColor(HEADER_FG)
    lbl:SetFontStyle(Turbine.UI.FontStyle.Outline)
    lbl:SetText(text)
end

---------------------------------------------------------------------------------------------------

OptionPanel = class ( Turbine.UI.Control )

function OptionPanel:Constructor()
    Turbine.UI.Control.Constructor(self)
    self:SetSize(600, 760)

    local top = 0
    local INDENT = 50
    local BODY_FONT = Turbine.UI.Lotro.Font.Verdana14
    local MUTED = Turbine.UI.Color(0.5, 0.5, 0.5)
    local BOUND = Turbine.UI.Color(0.6, 0.8, 0.6)

    ---------------------------------------------------------------------------------------------------
    -- POSITION
    ---------------------------------------------------------------------------------------------------
    makeHeader(self, top, "Position")
    top = top + HEADER_H + 6

    self.moveCheckbox = Turbine.UI.Lotro.CheckBox()
    self.moveCheckbox:SetParent(self)
    self.moveCheckbox:SetWidth(400)
    self.moveCheckbox:SetPosition(INDENT, top)
    self.moveCheckbox:SetFont(BODY_FONT)
    self.moveCheckbox:SetText(" show drag handle")
    self.moveCheckbox.CheckedChanged = function(sender, args)
        _G.ShowAnchor(self.moveCheckbox:IsChecked())
    end

    top = top + 40 + 10

    ---------------------------------------------------------------------------------------------------
    -- LAYOUT
    ---------------------------------------------------------------------------------------------------
    makeHeader(self, top, "Layout")
    top = top + HEADER_H + 8

    local COL2 = INDENT + 160

    self.noSortCheckbox = Turbine.UI.Lotro.CheckBox()
    self.noSortCheckbox:SetParent(self)
    self.noSortCheckbox:SetWidth(150)
    self.noSortCheckbox:SetPosition(INDENT, top)
    self.noSortCheckbox:SetFont(BODY_FONT)
    self.noSortCheckbox:SetText(" no sort")
    self.noSortCheckbox:SetChecked(_G.Settings.sort == 0)
    self.noSortCheckbox.CheckedChanged = function(sender, args)
        if self.noSortCheckbox:IsChecked() then
            _G.Settings.sort = 0
            _G.SaveSettings()
            self:UpdateSort()
        end
    end

    self.sortByNameCheckbox = Turbine.UI.Lotro.CheckBox()
    self.sortByNameCheckbox:SetParent(self)
    self.sortByNameCheckbox:SetWidth(150)
    self.sortByNameCheckbox:SetPosition(COL2, top)
    self.sortByNameCheckbox:SetFont(BODY_FONT)
    self.sortByNameCheckbox:SetText(" sort by name")
    self.sortByNameCheckbox:SetChecked(_G.Settings.sort == 1)
    self.sortByNameCheckbox.CheckedChanged = function(sender, args)
        if self.sortByNameCheckbox:IsChecked() then
            _G.Settings.sort = 1
            _G.SaveSettings()
            self:UpdateSort()
        end
    end

    top = top + 20 + 12

    self.horizontalCheckbox = Turbine.UI.Lotro.CheckBox()
    self.horizontalCheckbox:SetParent(self)
    self.horizontalCheckbox:SetSize(150, 20)
    self.horizontalCheckbox:SetPosition(INDENT, top)
    self.horizontalCheckbox:SetFont(BODY_FONT)
    self.horizontalCheckbox:SetText(" fill horizontal")
    self.horizontalCheckbox:SetChecked(_G.Settings.horizontal)
    self.horizontalCheckbox.CheckedChanged = function(sender, args)
        _G.Settings.horizontal = self.horizontalCheckbox:IsChecked()
        _G.SaveSettings()
    end

    self.reverseFillCheckbox = Turbine.UI.Lotro.CheckBox()
    self.reverseFillCheckbox:SetParent(self)
    self.reverseFillCheckbox:SetSize(150, 20)
    self.reverseFillCheckbox:SetPosition(COL2, top)
    self.reverseFillCheckbox:SetFont(BODY_FONT)
    self.reverseFillCheckbox:SetText(" reverse fill")
    self.reverseFillCheckbox:SetChecked(_G.Settings.reverseFill)
    self.reverseFillCheckbox.CheckedChanged = function(sender, args)
        _G.Settings.reverseFill = self.reverseFillCheckbox:IsChecked()
        _G.SaveSettings()
    end

    top = top + 20 + 14

    ---------------------------------------------------------------------------------------------------
    -- TOOLTIP SIZE
    ---------------------------------------------------------------------------------------------------
    makeHeader(self, top, "Tooltip size")
    top = top + HEADER_H + 10

    -- row: [200] width  [90] height  [5] spacing  [5] max
    self.widthTextbox = Turbine.UI.Lotro.TextBox()
    self.widthTextbox:SetParent(self)
    self.widthTextbox:SetPosition(INDENT, top)
    self.widthTextbox:SetSize(44, 20)
    self.widthTextbox:SetFont(BODY_FONT)
    self.widthTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.widthTextbox:SetText(_G.Settings.width)

    self.widthLabel = Turbine.UI.Label()
    self.widthLabel:SetParent(self)
    self.widthLabel:SetPosition(INDENT + 48, top)
    self.widthLabel:SetSize(46, 20)
    self.widthLabel:SetFont(BODY_FONT)
    self.widthLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.widthLabel:SetForeColor(MUTED)
    self.widthLabel:SetText("width")

    self.heightTextbox = Turbine.UI.Lotro.TextBox()
    self.heightTextbox:SetParent(self)
    self.heightTextbox:SetPosition(INDENT + 100, top)
    self.heightTextbox:SetSize(44, 20)
    self.heightTextbox:SetFont(BODY_FONT)
    self.heightTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.heightTextbox:SetText(_G.Settings.tooltip_height)

    self.heightLabel = Turbine.UI.Label()
    self.heightLabel:SetParent(self)
    self.heightLabel:SetPosition(INDENT + 148, top)
    self.heightLabel:SetSize(46, 20)
    self.heightLabel:SetFont(BODY_FONT)
    self.heightLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.heightLabel:SetForeColor(MUTED)
    self.heightLabel:SetText("height")

    self.spacingTextbox = Turbine.UI.Lotro.TextBox()
    self.spacingTextbox:SetParent(self)
    self.spacingTextbox:SetPosition(INDENT + 200, top)
    self.spacingTextbox:SetSize(34, 20)
    self.spacingTextbox:SetFont(BODY_FONT)
    self.spacingTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.spacingTextbox:SetText(_G.Settings.tooltip_spacing)

    self.spacingLabel = Turbine.UI.Label()
    self.spacingLabel:SetParent(self)
    self.spacingLabel:SetPosition(INDENT + 238, top)
    self.spacingLabel:SetSize(52, 20)
    self.spacingLabel:SetFont(BODY_FONT)
    self.spacingLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.spacingLabel:SetForeColor(MUTED)
    self.spacingLabel:SetText("spacing")

    self.toolTipCountTextbox = Turbine.UI.Lotro.TextBox()
    self.toolTipCountTextbox:SetParent(self)
    self.toolTipCountTextbox:SetPosition(INDENT + 300, top)
    self.toolTipCountTextbox:SetSize(34, 20)
    self.toolTipCountTextbox:SetFont(BODY_FONT)
    self.toolTipCountTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.toolTipCountTextbox:SetText(_G.Settings.max_tooltip_count)

    self.toolTipCountLabel = Turbine.UI.Label()
    self.toolTipCountLabel:SetParent(self)
    self.toolTipCountLabel:SetPosition(INDENT + 338, top - 4)
    self.toolTipCountLabel:SetSize(80, 30)
    self.toolTipCountLabel:SetFont(BODY_FONT)
    self.toolTipCountLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.toolTipCountLabel:SetForeColor(MUTED)
    self.toolTipCountLabel:SetText("max trackers")

    top = top + 20 + 8

    self.updateSizeButton = Turbine.UI.Lotro.Button()
    self.updateSizeButton:SetParent(self)
    self.updateSizeButton:SetText("apply size")
    self.updateSizeButton:SetWidth(90)
    self.updateSizeButton:SetPosition(INDENT, top)
    self.updateSizeButton.MouseClick = function(sender, args)
        _G.Settings.width             = tonumber(self.widthTextbox:GetText())          or _G.Settings.width
        _G.Settings.tooltip_height    = tonumber(self.heightTextbox:GetText())         or _G.Settings.tooltip_height
        _G.Settings.max_tooltip_count = tonumber(self.toolTipCountTextbox:GetText())   or _G.Settings.max_tooltip_count
        _G.Settings.tooltip_spacing   = tonumber(self.spacingTextbox:GetText())        or _G.Settings.tooltip_spacing

        Potato:ApplySettings()
        _G.SaveSettings()

        self.widthTextbox:SetText(_G.Settings.width)
        self.heightTextbox:SetText(_G.Settings.tooltip_height)
        self.toolTipCountTextbox:SetText(_G.Settings.max_tooltip_count)
        self.spacingTextbox:SetText(_G.Settings.tooltip_spacing)
    end

    self.updateSizeHint = Turbine.UI.Label()
    self.updateSizeHint:SetParent(self)
    self.updateSizeHint:SetPosition(INDENT + 96, top + 2)
    self.updateSizeHint:SetSize(200, 18)
    self.updateSizeHint:SetFont(BODY_FONT)
    self.updateSizeHint:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.updateSizeHint:SetForeColor(MUTED)
    self.updateSizeHint:SetText("changes apply on click")

    top = top + 20 + 14

    ---------------------------------------------------------------------------------------------------
    -- KEYBINDINGS
    ---------------------------------------------------------------------------------------------------
    makeHeader(self, top, "Keybindings")
    top = top + HEADER_H + 14

    self.addButton = Turbine.UI.Lotro.Button()
    self.addButton:SetParent(self)
    self.addButton:SetText("Set key: add tracker")
    self.addButton:SetWidth(200)
    self.addButton:SetPosition(INDENT, top)
    self.addButton.MouseClick = function(sender, args)
        AddButtonWindow = GetKeybindingWindow()
        AddButtonWindow.KeyDown = function(s, a)
            if AddButtonWindow.assignedAlready == true then return end
            if a.Action == 92 or a.Action == 19 then return end
            if a.Action == 145 then
                AddButtonWindow:SetVisible(false)
                AddButtonWindow:Close()
                return
            end
            _G.Settings.keybinding_add.shift  = a.Shift
            _G.Settings.keybinding_add.alt    = a.Alt
            _G.Settings.keybinding_add.ctrl   = a.Control
            _G.Settings.keybinding_add.action = a.Action
            _G.SaveSettings()
            self.addKeybindingLabel:SetText("bound to  " .. FormatKeybinding(_G.Settings.keybinding_add))
            AddButtonWindow.assignedAlready = true
            AddButtonWindow:SetVisible(false)
            AddButtonWindow:Close()
        end
    end

    top = top + 20 + 4

    self.addKeybindingLabel = Turbine.UI.Label()
    self.addKeybindingLabel:SetParent(self)
    self.addKeybindingLabel:SetPosition(INDENT + 4, top)
    self.addKeybindingLabel:SetSize(350, 18)
    self.addKeybindingLabel:SetFont(BODY_FONT)
    self.addKeybindingLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.addKeybindingLabel:SetForeColor(BOUND)
    self.addKeybindingLabel:SetText("bound to  " .. FormatKeybinding(_G.Settings.keybinding_add))

    top = top + 18 + 10

    self.clearButton = Turbine.UI.Lotro.Button()
    self.clearButton:SetParent(self)
    self.clearButton:SetText("Set key: clear trackers")
    self.clearButton:SetWidth(200)
    self.clearButton:SetPosition(INDENT, top)
    self.clearButton.MouseClick = function(sender, args)
        ClearButtonWindow = GetKeybindingWindow()
        ClearButtonWindow.KeyDown = function(s, a)
            if ClearButtonWindow.assignedAlready == true then return end
            if a.Action == 92 or a.Action == 19 then return end
            if a.Action == 145 then
                ClearButtonWindow:SetVisible(false)
                ClearButtonWindow:Close()
                return
            end
            _G.Settings.keybinding_clear.shift  = a.Shift
            _G.Settings.keybinding_clear.alt    = a.Alt
            _G.Settings.keybinding_clear.ctrl   = a.Control
            _G.Settings.keybinding_clear.action = a.Action
            _G.SaveSettings()
            self.clearKeybindingLabel:SetText("bound to  " .. FormatKeybinding(_G.Settings.keybinding_clear))
            ClearButtonWindow.assignedAlready = true
            ClearButtonWindow:SetVisible(false)
            ClearButtonWindow:Close()
        end
    end

    top = top + 20 + 4

    self.clearKeybindingLabel = Turbine.UI.Label()
    self.clearKeybindingLabel:SetParent(self)
    self.clearKeybindingLabel:SetPosition(INDENT + 4, top)
    self.clearKeybindingLabel:SetSize(350, 18)
    self.clearKeybindingLabel:SetFont(BODY_FONT)
    self.clearKeybindingLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.clearKeybindingLabel:SetForeColor(BOUND)
    self.clearKeybindingLabel:SetText("bound to  " .. FormatKeybinding(_G.Settings.keybinding_clear))

    top = top + 18 + 12

    self.clearCheckbox = Turbine.UI.Lotro.CheckBox()
    self.clearCheckbox:SetParent(self)
    self.clearCheckbox:SetSize(200, 20)
    self.clearCheckbox:SetPosition(INDENT, top)
    self.clearCheckbox:SetFont(BODY_FONT)
    self.clearCheckbox:SetText(" enable clear key")
    self.clearCheckbox:SetChecked(_G.Settings.use_clear_keybinding)
    self.clearCheckbox.CheckedChanged = function(sender, args)
        _G.Settings.use_clear_keybinding = self.clearCheckbox:IsChecked()
        _G.SaveSettings()
    end

    self.onlyDeadCheckbox = Turbine.UI.Lotro.CheckBox()
    self.onlyDeadCheckbox:SetParent(self)
    self.onlyDeadCheckbox:SetSize(220, 20)
    self.onlyDeadCheckbox:SetPosition(INDENT + 180, top)
    self.onlyDeadCheckbox:SetFont(BODY_FONT)
    self.onlyDeadCheckbox:SetText(" only clear defeated")
    self.onlyDeadCheckbox:SetChecked(_G.Settings.only_clear_dead)
    self.onlyDeadCheckbox.CheckedChanged = function(sender, args)
        _G.Settings.only_clear_dead = self.onlyDeadCheckbox:IsChecked()
        _G.SaveSettings()
    end

    top = top + 20 + 14

    ---------------------------------------------------------------------------------------------------
    -- COMBAT TRACKING
    ---------------------------------------------------------------------------------------------------
    makeHeader(self, top, "Combat tracking")
    top = top + HEADER_H + 10

    self.highlightDefeatedCheckbox = Turbine.UI.Lotro.CheckBox()
    self.highlightDefeatedCheckbox:SetParent(self)
    self.highlightDefeatedCheckbox:SetSize(200, 20)
    self.highlightDefeatedCheckbox:SetPosition(INDENT, top)
    self.highlightDefeatedCheckbox:SetFont(BODY_FONT)
    self.highlightDefeatedCheckbox:SetText(" highlight defeated")
    self.highlightDefeatedCheckbox:SetChecked(_G.Settings.highlight_defeated)
    self.highlightDefeatedCheckbox.CheckedChanged = function(sender, args)
        _G.Settings.highlight_defeated = self.highlightDefeatedCheckbox:IsChecked()
        _G.SaveSettings()
    end

    self.displayDurationsCheckbox = Turbine.UI.Lotro.CheckBox()
    self.displayDurationsCheckbox:SetParent(self)
    self.displayDurationsCheckbox:SetSize(200, 20)
    self.displayDurationsCheckbox:SetPosition(INDENT + 180, top)
    self.displayDurationsCheckbox:SetFont(BODY_FONT)
    self.displayDurationsCheckbox:SetText(" show CC timers")
    self.displayDurationsCheckbox:SetChecked(_G.Settings.display_durations)
    self.displayDurationsCheckbox.CheckedChanged = function(sender, args)
        _G.Settings.display_durations = self.displayDurationsCheckbox:IsChecked()
        _G.SaveSettings()
    end

    self.displayMoraleCheckbox = Turbine.UI.Lotro.CheckBox()
    self.displayMoraleCheckbox:SetParent(self)
    self.displayMoraleCheckbox:SetSize(200, 20)
    self.displayMoraleCheckbox:SetPosition(INDENT + 180, top + 20)
    self.displayMoraleCheckbox:SetFont(BODY_FONT)
    self.displayMoraleCheckbox:SetText(" show morale bar")
    self.displayMoraleCheckbox:SetChecked(_G.Settings.display_morale)
    self.displayMoraleCheckbox.CheckedChanged = function(sender, args)
        _G.Settings.display_morale = self.displayMoraleCheckbox:IsChecked()
        Potato:ApplySettings()
        _G.SaveSettings()
    end

    top = top + 40 + 10

    -- bar height for CC timers
    self.barHeightTextbox = Turbine.UI.Lotro.TextBox()
    self.barHeightTextbox:SetParent(self)
    self.barHeightTextbox:SetPosition(INDENT, top)
    self.barHeightTextbox:SetSize(34, 20)
    self.barHeightTextbox:SetFont(BODY_FONT)
    self.barHeightTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.barHeightTextbox:SetText(_G.Settings.duration_bar_height)

    self.barHeightLabel = Turbine.UI.Label()
    self.barHeightLabel:SetParent(self)
    self.barHeightLabel:SetPosition(INDENT + 38, top)
    self.barHeightLabel:SetSize(160, 20)
    self.barHeightLabel:SetFont(BODY_FONT)
    self.barHeightLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.barHeightLabel:SetForeColor(MUTED)
    self.barHeightLabel:SetText("px bar height")

    top = top + 20 + 10

    -- CC warning threshold
    self.ccThresholdTextbox = Turbine.UI.Lotro.TextBox()
    self.ccThresholdTextbox:SetParent(self)
    self.ccThresholdTextbox:SetPosition(INDENT, top)
    self.ccThresholdTextbox:SetSize(34, 20)
    self.ccThresholdTextbox:SetFont(BODY_FONT)
    self.ccThresholdTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.ccThresholdTextbox:SetText(_G.Settings.cc_warning_threshold)

    self.ccThresholdLabel = Turbine.UI.Label()
    self.ccThresholdLabel:SetParent(self)
    self.ccThresholdLabel:SetPosition(INDENT + 38, top)
    self.ccThresholdLabel:SetSize(200, 20)
    self.ccThresholdLabel:SetFont(BODY_FONT)
    self.ccThresholdLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.ccThresholdLabel:SetForeColor(MUTED)
    self.ccThresholdLabel:SetText("s CC warning (bar turns red)")

    -- auto-remove defeated delay
    self.defeatDelayTextbox = Turbine.UI.Lotro.TextBox()
    self.defeatDelayTextbox:SetParent(self)
    self.defeatDelayTextbox:SetPosition(INDENT + 260, top)
    self.defeatDelayTextbox:SetSize(34, 20)
    self.defeatDelayTextbox:SetFont(BODY_FONT)
    self.defeatDelayTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.defeatDelayTextbox:SetText(_G.Settings.defeat_auto_remove_delay)

    self.defeatDelayLabel = Turbine.UI.Label()
    self.defeatDelayLabel:SetParent(self)
    self.defeatDelayLabel:SetPosition(INDENT + 298, top)
    self.defeatDelayLabel:SetSize(220, 20)
    self.defeatDelayLabel:SetFont(BODY_FONT)
    self.defeatDelayLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.defeatDelayLabel:SetForeColor(MUTED)
    self.defeatDelayLabel:SetText("s auto-remove defeated (0=off)")

    top = top + 20 + 6

    self.updateCombatButton = Turbine.UI.Lotro.Button()
    self.updateCombatButton:SetParent(self)
    self.updateCombatButton:SetText("apply")
    self.updateCombatButton:SetWidth(70)
    self.updateCombatButton:SetPosition(INDENT, top)
    self.updateCombatButton.MouseClick = function(sender, args)
        _G.Settings.cc_warning_threshold     = tonumber(self.ccThresholdTextbox:GetText())  or _G.Settings.cc_warning_threshold
        _G.Settings.defeat_auto_remove_delay = tonumber(self.defeatDelayTextbox:GetText())  or _G.Settings.defeat_auto_remove_delay
        _G.Settings.duration_bar_height      = tonumber(self.barHeightTextbox:GetText())    or _G.Settings.duration_bar_height
        Potato:ApplySettings()
        _G.SaveSettings()
        self.ccThresholdTextbox:SetText(_G.Settings.cc_warning_threshold)
        self.defeatDelayTextbox:SetText(_G.Settings.defeat_auto_remove_delay)
        self.barHeightTextbox:SetText(_G.Settings.duration_bar_height)
    end

    local updateCombatHint = Turbine.UI.Label()
    updateCombatHint:SetParent(self)
    updateCombatHint:SetPosition(INDENT + 76, top + 2)
    updateCombatHint:SetSize(200, 18)
    updateCombatHint:SetFont(BODY_FONT)
    updateCombatHint:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    updateCombatHint:SetForeColor(MUTED)
    updateCombatHint:SetText("changes apply on click")

    top = top + 20 + 14

    ---------------------------------------------------------------------------------------------------
    -- APPEARANCE
    ---------------------------------------------------------------------------------------------------
    makeHeader(self, top, "Appearance")
    top = top + HEADER_H + 10

    local COLOR_BOX_W = 34
    local COLOR_LABEL_W = 80
    local COLOR_COL_W = COLOR_BOX_W * 3 + 14 + COLOR_LABEL_W

    local function makeColorRow(parentTop, labelText, colorTable)
        local lbl = Turbine.UI.Label()
        lbl:SetParent(self)
        lbl:SetPosition(INDENT, parentTop)
        lbl:SetSize(COLOR_LABEL_W, 20)
        lbl:SetFont(BODY_FONT)
        lbl:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        lbl:SetForeColor(MUTED)
        lbl:SetText(labelText)

        local rBox = Turbine.UI.Lotro.TextBox()
        rBox:SetParent(self)
        rBox:SetPosition(INDENT + COLOR_LABEL_W, parentTop)
        rBox:SetSize(COLOR_BOX_W, 20)
        rBox:SetFont(BODY_FONT)
        rBox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        rBox:SetText(math.floor(colorTable.r * 255 + 0.5))

        local rLbl = Turbine.UI.Label()
        rLbl:SetParent(self)
        rLbl:SetPosition(INDENT + COLOR_LABEL_W + COLOR_BOX_W + 2, parentTop)
        rLbl:SetSize(14, 20)
        rLbl:SetFont(BODY_FONT)
        rLbl:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        rLbl:SetForeColor(MUTED)
        rLbl:SetText("R")

        local gBox = Turbine.UI.Lotro.TextBox()
        gBox:SetParent(self)
        gBox:SetPosition(INDENT + COLOR_LABEL_W + COLOR_BOX_W + 16, parentTop)
        gBox:SetSize(COLOR_BOX_W, 20)
        gBox:SetFont(BODY_FONT)
        gBox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        gBox:SetText(math.floor(colorTable.g * 255 + 0.5))

        local gLbl = Turbine.UI.Label()
        gLbl:SetParent(self)
        gLbl:SetPosition(INDENT + COLOR_LABEL_W + COLOR_BOX_W*2 + 18, parentTop)
        gLbl:SetSize(14, 20)
        gLbl:SetFont(BODY_FONT)
        gLbl:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        gLbl:SetForeColor(MUTED)
        gLbl:SetText("G")

        local bBox = Turbine.UI.Lotro.TextBox()
        bBox:SetParent(self)
        bBox:SetPosition(INDENT + COLOR_LABEL_W + COLOR_BOX_W*2 + 32, parentTop)
        bBox:SetSize(COLOR_BOX_W, 20)
        bBox:SetFont(BODY_FONT)
        bBox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        bBox:SetText(math.floor(colorTable.b * 255 + 0.5))

        local bLbl = Turbine.UI.Label()
        bLbl:SetParent(self)
        bLbl:SetPosition(INDENT + COLOR_LABEL_W + COLOR_BOX_W*3 + 34, parentTop)
        bLbl:SetSize(14, 20)
        bLbl:SetFont(BODY_FONT)
        bLbl:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
        bLbl:SetForeColor(MUTED)
        bLbl:SetText("B")

        return rBox, gBox, bBox
    end

    local playerR, playerG, playerB = makeColorRow(top, "player color", _G.Settings.color_player)
    top = top + 20 + 6
    local npcR, npcG, npcB = makeColorRow(top, "npc color", _G.Settings.color_npc)
    top = top + 20 + 6
    local itemR, itemG, itemB = makeColorRow(top, "item color", _G.Settings.color_item)
    top = top + 20 + 8

    self.applyColorsButton = Turbine.UI.Lotro.Button()
    self.applyColorsButton:SetParent(self)
    self.applyColorsButton:SetText("apply colors")
    self.applyColorsButton:SetWidth(110)
    self.applyColorsButton:SetPosition(INDENT, top)
    self.applyColorsButton.MouseClick = function(sender, args)
        local function parseColorRow(settingKey, tooltipKey, rBox, gBox, bBox)
            local r = math.max(0, math.min(255, tonumber(rBox:GetText()) or 0)) / 255
            local g = math.max(0, math.min(255, tonumber(gBox:GetText()) or 0)) / 255
            local b = math.max(0, math.min(255, tonumber(bBox:GetText()) or 0)) / 255
            _G.Settings[settingKey]  = {r=r, g=g, b=b}
            _G.Settings[tooltipKey]  = Turbine.UI.Color(r, g, b)
            rBox:SetText(math.floor(r * 255 + 0.5))
            gBox:SetText(math.floor(g * 255 + 0.5))
            bBox:SetText(math.floor(b * 255 + 0.5))
        end
        parseColorRow("color_player", "tooltip_color_player", playerR, playerG, playerB)
        parseColorRow("color_npc",    "tooltip_color_npc",    npcR,    npcG,    npcB)
        parseColorRow("color_item",   "tooltip_color_item",   itemR,   itemG,   itemB)
        _G.SaveSettings()
        Potato:ApplySettings()
    end

    local applyColorsHint = Turbine.UI.Label()
    applyColorsHint:SetParent(self)
    applyColorsHint:SetPosition(INDENT + 116, top + 2)
    applyColorsHint:SetSize(220, 18)
    applyColorsHint:SetFont(BODY_FONT)
    applyColorsHint:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    applyColorsHint:SetForeColor(MUTED)
    applyColorsHint:SetText("values 0-255, changes apply on click")

end

---------------------------------------------------------------------------------------------------

function OptionPanel:UpdateSort()
    self.noSortCheckbox:SetChecked(_G.Settings.sort == 0)
    self.sortByNameCheckbox:SetChecked(_G.Settings.sort == 1)
end

function GetKeybindingWindow()
    local screenWidth, screenHeight = Turbine.UI.Display:GetSize()

    local window = Turbine.UI.Window()
    window:SetSize(screenWidth, screenHeight)
    window:SetBackColor(Turbine.UI.Color.Black)
    window:SetOpacity(0.5)
    window:SetMouseVisible(false)
    window:SetWantsKeyEvents(true)
    window:SetZOrder(9998)
    window.assignedAlready = false

    local info = Turbine.UI.Lotro.GoldWindow()
    info:SetParent(window)
    info:SetSize(300, 100)
    info:SetText("Potato keybinding")
    info:SetPosition(screenWidth/2 - 150, screenHeight/2 - 50)
    function info:Closing()
        window.assignedAlready = true
        window:SetVisible(false)
        window:Close()
    end

    local label = Turbine.UI.Label()
    label:SetParent(info)
    label:SetPosition(20, 40)
    label:SetSize(260, 50)
    label:SetFont(Turbine.UI.Lotro.Font.Verdana16)
    label:SetText("press the new key, or esc to cancel.")

    info:SetVisible(true)
    window:SetVisible(true)

    return window
end

function FormatKeybinding(kb)
    local parts = {}
    if kb.shift then parts[#parts+1] = "Shift" end
    if kb.alt   then parts[#parts+1] = "Alt"   end
    if kb.ctrl  then parts[#parts+1] = "Ctrl"  end
    parts[#parts+1] = tostring(kb.action)
    return table.concat(parts, "+")
end
