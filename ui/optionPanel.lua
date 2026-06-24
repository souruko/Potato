
OptionPanel = class ( Turbine.UI.Control )

function OptionPanel:Constructor()
    Turbine.UI.Control.Constructor(self)

    self:SetSize(600, 600)

    local top = 0

    self.moveCheckbox = Turbine.UI.Lotro.CheckBox()
    self.moveCheckbox:SetParent(self)
    self.moveCheckbox:SetWidth(600)
    self.moveCheckbox:SetPosition(40, top)
    self.moveCheckbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.moveCheckbox:SetText(" show move anchor")
    self.moveCheckbox.CheckedChanged = function (sender, args)
        _G.ShowAnchor(self.moveCheckbox:IsChecked())
    end

    top = top + 50

    self.line = Turbine.UI.Control()
    self.line:SetParent(self)
    self.line:SetSize(500, 1)
    self.line:SetPosition(20, top)
    self.line:SetBackColor(Turbine.UI.Color.Gray)

    top = top + 10

    self.noSortCheckbox = Turbine.UI.Lotro.CheckBox()
    self.noSortCheckbox:SetParent(self)
    self.noSortCheckbox:SetWidth(600)
    self.noSortCheckbox:SetPosition(40, top)
    self.noSortCheckbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.noSortCheckbox:SetText(" no sort")
    self.noSortCheckbox:SetChecked(_G.Settings.sort == 0)
    self.noSortCheckbox.CheckedChanged = function (sender, args)
        if self.noSortCheckbox:IsChecked() then
            _G.Settings.sort = 0
            _G.SaveSettings()
            self:UpdateSort()
        end
    end

    self.sortByNameCheckbox = Turbine.UI.Lotro.CheckBox()
    self.sortByNameCheckbox:SetParent(self)
    self.sortByNameCheckbox:SetWidth(600)
    self.sortByNameCheckbox:SetPosition(150, top)
    self.sortByNameCheckbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.sortByNameCheckbox:SetText(" sort by name")
    self.sortByNameCheckbox:SetChecked(_G.Settings.sort == 1)
    self.sortByNameCheckbox.CheckedChanged = function (sender, args)
        if self.sortByNameCheckbox:IsChecked() then
            _G.Settings.sort = 1
            _G.SaveSettings()
            self:UpdateSort()
        end
    end

    top = top + 40

    self.horizontalCheckbox = Turbine.UI.Lotro.CheckBox()
    self.horizontalCheckbox:SetParent(self)
    self.horizontalCheckbox:SetSize(600, 20)
    self.horizontalCheckbox:SetPosition(40, top)
    self.horizontalCheckbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.horizontalCheckbox:SetText(" fill tooltips horizontal")
    self.horizontalCheckbox:SetChecked(_G.Settings.horizontal)
    self.horizontalCheckbox.CheckedChanged = function (sender, args)
        _G.Settings.horizontal = self.horizontalCheckbox:IsChecked()
        _G.SaveSettings()
    end

    self.reverseFillCheckbox = Turbine.UI.Lotro.CheckBox()
    self.reverseFillCheckbox:SetParent(self)
    self.reverseFillCheckbox:SetSize(600, 20)
    self.reverseFillCheckbox:SetPosition(220, top)
    self.reverseFillCheckbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.reverseFillCheckbox:SetText(" reverse fill direction")
    self.reverseFillCheckbox:SetChecked(_G.Settings.reverseFill)
    self.reverseFillCheckbox.CheckedChanged = function (sender, args)
        _G.Settings.reverseFill = self.reverseFillCheckbox:IsChecked()
        _G.SaveSettings()
    end


    top = top + 45

    self.line1 = Turbine.UI.Control()
    self.line1:SetParent(self)
    self.line1:SetSize(500, 1)
    self.line1:SetPosition(20, top)
    self.line1:SetBackColor(Turbine.UI.Color.Gray)

    top = top + 25

    self.widthTextbox = Turbine.UI.Lotro.TextBox()
    self.widthTextbox:SetParent(self)
    self.widthTextbox:SetPosition(40, top)
    self.widthTextbox:SetSize(40, 20)
    self.widthTextbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.widthTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.widthTextbox:SetText(_G.Settings.width)

    self.widthLabel = Turbine.UI.Label()
    self.widthLabel:SetParent(self)
    self.widthLabel:SetPosition(85, top)
    self.widthLabel:SetSize(40, 20)
    self.widthLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.widthLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.widthLabel:SetText("width")

    self.heightTextbox = Turbine.UI.Lotro.TextBox()
    self.heightTextbox:SetParent(self)
    self.heightTextbox:SetPosition(150, top)
    self.heightTextbox:SetSize(40, 20)
    self.heightTextbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.heightTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.heightTextbox:SetText(_G.Settings.tooltip_height)

    self.heightLabel = Turbine.UI.Label()
    self.heightLabel:SetParent(self)
    self.heightLabel:SetPosition(195, top)
    self.heightLabel:SetSize(40, 20)
    self.heightLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.heightLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.heightLabel:SetText("height")

    self.spacingTextbox = Turbine.UI.Lotro.TextBox()
    self.spacingTextbox:SetParent(self)
    self.spacingTextbox:SetPosition(260, top)
    self.spacingTextbox:SetSize(40, 20)
    self.spacingTextbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.spacingTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.spacingTextbox:SetText(_G.Settings.tooltip_spacing)

    self.spacingLabel = Turbine.UI.Label()
    self.spacingLabel:SetParent(self)
    self.spacingLabel:SetPosition(305, top)
    self.spacingLabel:SetSize(50, 20)
    self.spacingLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.spacingLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.spacingLabel:SetText("spacing")

    self.toolTipCountTextbox = Turbine.UI.Lotro.TextBox()
    self.toolTipCountTextbox:SetParent(self)
    self.toolTipCountTextbox:SetPosition(370, top)
    self.toolTipCountTextbox:SetSize(40, 20)
    self.toolTipCountTextbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.toolTipCountTextbox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.toolTipCountTextbox:SetText(_G.Settings.max_tooltip_count)

    self.toolTipCountLabel = Turbine.UI.Label()
    self.toolTipCountLabel:SetParent(self)
    self.toolTipCountLabel:SetPosition(415, top -5)
    self.toolTipCountLabel:SetSize(70, 30)
    self.toolTipCountLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.toolTipCountLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    self.toolTipCountLabel:SetText("max tooltip count")

    top = top + 35

    self.updateSizeButton = Turbine.UI.Lotro.Button()
    self.updateSizeButton:SetParent(self)
    self.updateSizeButton:SetText("update size")
    self.updateSizeButton:SetWidth(100)
    self.updateSizeButton:SetPosition(40, top)
    self.updateSizeButton.MouseClick = function (sender, args)
        _G.Settings.width = tonumber(self.widthTextbox:GetText())
        _G.Settings.tooltip_height = tonumber(self.heightTextbox:GetText())
        _G.Settings.max_tooltip_count = tonumber(self.toolTipCountTextbox:GetText())
        _G.Settings.tooltip_spacing = tonumber(self.spacingTextbox:GetText())

        Potato:ApplySettings()
        _G.SaveSettings()
    end

    top = top + 35

    self.line2 = Turbine.UI.Control()
    self.line2:SetParent(self)
    self.line2:SetSize(500, 1)
    self.line2:SetPosition(20, top)
    self.line2:SetBackColor(Turbine.UI.Color.Gray)

    top = top + 25

    self.addButton = Turbine.UI.Lotro.Button()
    self.addButton:SetParent(self)
    self.addButton:SetText("Assign a keybinding to create tooltips")
    self.addButton:SetWidth(300)
    self.addButton:SetPosition(40, top)
    self.addButton.MouseClick = function (sender, args)
        local screenWidth, screenHeight = Turbine.UI.Display:GetSize()

        AddButtonWindow = GetKeybindingWindow()
        AddButtonWindow.KeyDown = function (s, a)

            -- no double assingment
            if AddButtonWindow.assignedAlready == true then
                return
            end

            -- do nothing on mousebuttons
            if a.Action == 92 or a.Action == 19 then
                return
            end

            -- cancel on esc
            if a.Action == 145 then
                AddButtonWindow:SetVisible(false)
                AddButtonWindow:Close()
                return
            end

            _G.Settings.keybinding_add.shift = a.Shift
            _G.Settings.keybinding_add.alt = a.Alt
            _G.Settings.keybinding_add.ctrl = a.Control
            _G.Settings.keybinding_add.action = a.Action
            _G.SaveSettings()
            AddButtonWindow.assignedAlready = true

            AddButtonWindow:SetVisible(false)
            AddButtonWindow:Close()

        end
    end

    top = top + 25

    self.clearButton = Turbine.UI.Lotro.Button()
    self.clearButton:SetParent(self)
    self.clearButton:SetText("Assign a keybinding to clear tooltips")
    self.clearButton:SetWidth(300)
    self.clearButton:SetPosition(40, top)
    self.clearButton.MouseClick = function (sender, args)
        local screenWidth, screenHeight = Turbine.UI.Display:GetSize()

        ClearButtonWindow = GetKeybindingWindow()
        ClearButtonWindow.KeyDown = function (s, a)

            -- no double assingment
            if ClearButtonWindow.assignedAlready == true then
                return
            end

            -- do nothing on mousebuttons
            if a.Action == 92 or a.Action == 19 then
                return
            end

            -- cancel on esc
            if a.Action == 145 then
                ClearButtonWindow:SetVisible(false)
                ClearButtonWindow:Close()
                return
            end

            _G.Settings.keybinding_clear.shift = a.Shift
            _G.Settings.keybinding_clear.alt = a.Alt
            _G.Settings.keybinding_clear.ctrl = a.Control
            _G.Settings.keybinding_clear.action = a.Action
            _G.SaveSettings()
            ClearButtonWindow.assignedAlready = true

            ClearButtonWindow:SetVisible(false)
            ClearButtonWindow:Close()

        end
    end

    top = top + 30


    self.clearCheckbox = Turbine.UI.Lotro.CheckBox()
    self.clearCheckbox:SetParent(self)
    self.clearCheckbox:SetSize(200, 20)
    self.clearCheckbox:SetPosition(40, top)
    self.clearCheckbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.clearCheckbox:SetText(" use clear keybinding")
    self.clearCheckbox:SetChecked(_G.Settings.use_clear_keybinding)
    self.clearCheckbox.CheckedChanged = function (sender, args)
        _G.Settings.use_clear_keybinding = self.clearCheckbox:IsChecked()
        _G.SaveSettings()
    end


    self.onlyDeadCheckbox = Turbine.UI.Lotro.CheckBox()
    self.onlyDeadCheckbox:SetParent(self)
    self.onlyDeadCheckbox:SetSize(200, 20)
    self.onlyDeadCheckbox:SetPosition(200, top)
    self.onlyDeadCheckbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.onlyDeadCheckbox:SetText(" only clear dead tooltips")
    self.onlyDeadCheckbox:SetChecked(_G.Settings.only_clear_dead)
    self.onlyDeadCheckbox.CheckedChanged = function (sender, args)
        _G.Settings.only_clear_dead = self.onlyDeadCheckbox:IsChecked()
        _G.SaveSettings()
    end

    top = top + 45

    self.line3 = Turbine.UI.Control()
    self.line3:SetParent(self)
    self.line3:SetSize(500, 1)
    self.line3:SetPosition(20, top)
    self.line3:SetBackColor(Turbine.UI.Color.Gray)

    top = top + 25


    self.highlightDefeatedCheckbox = Turbine.UI.Lotro.CheckBox()
    self.highlightDefeatedCheckbox:SetParent(self)
    self.highlightDefeatedCheckbox:SetSize(600, 20)
    self.highlightDefeatedCheckbox:SetPosition(40, top)
    self.highlightDefeatedCheckbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.highlightDefeatedCheckbox:SetText(" highlight defeated")
    self.highlightDefeatedCheckbox:SetChecked(_G.Settings.highlight_defeated)
    self.highlightDefeatedCheckbox.CheckedChanged = function (sender, args)
        _G.Settings.highlight_defeated = self.highlightDefeatedCheckbox:IsChecked()
        _G.SaveSettings()
    end

    self.displayDurationsCheckbox = Turbine.UI.Lotro.CheckBox()
    self.displayDurationsCheckbox:SetParent(self)
    self.displayDurationsCheckbox:SetSize(600, 20)
    self.displayDurationsCheckbox:SetPosition(200, top)
    self.displayDurationsCheckbox:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.displayDurationsCheckbox:SetText(" display durations")
    self.displayDurationsCheckbox:SetChecked(_G.Settings.display_durations)
    self.displayDurationsCheckbox.CheckedChanged = function (sender, args)
        _G.Settings.display_durations = self.displayDurationsCheckbox:IsChecked()
        _G.SaveSettings()
    end


end

function OptionPanel:UpdateSort()
    Turbine.Shell.WriteLine(_G.Settings.sort)
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
    info:SetText("potato keybinding")
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
    label:SetText("press the new keybinding or esc to cancle.")

    info:SetVisible(true)
    window:SetVisible(true)

    return window

end