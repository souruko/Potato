
-- PotatoWindow
-- 
-- the main ui element containing all tooltips
-- 
-- - also handels sorting
-- - and key events
---------------------------------------------------------------------------------------------------

import "Potato.ui.potatoTooltip"


PotatoWindow = class( Turbine.UI.Window )

function PotatoWindow:Constructor()
    Turbine.UI.Window.Constructor(self)

    -- self
    self:SetMouseVisible(false)
    self:SetWantsKeyEvents(true)

    -- listbox
    self.listbox = Turbine.UI.ListBox()
    self.listbox:SetParent(self)
    self.listbox:SetMouseVisible(false)

    -- move anchor
    self.moveAnchor = Turbine.UI.Control()
    self.moveAnchor:SetParent(self)
    self.moveAnchor:SetSize(20, 20)
    self.moveAnchor:SetPosition(0, 0)
    self.moveAnchor:SetBackColor(Turbine.UI.Color.Green)
    self.moveAnchor:SetVisible(false)
    self.moveAnchor:SetZOrder(1000)

    self.moveAnchorLabel = Turbine.UI.Label()
    self.moveAnchorLabel:SetParent(self.moveAnchor)
    self.moveAnchorLabel:SetSize(20, 20)
    self.moveAnchorLabel:SetPosition(0, 0)
    self.moveAnchorLabel:SetText("+")
    self.moveAnchorLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.moveAnchorLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.moveAnchorLabel:SetForeColor(Turbine.UI.Color.White)
    self.moveAnchorLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.moveAnchorLabel:SetMouseVisible(false)

    -- mouse interaction
    self.dragging = false
    self.dragStartX = 0
    self.dragStartY = 0

    self.moveAnchor.MouseDown = function (sender, args)

        -- only allow move with leftclick and movemode
        if args.Button == Turbine.UI.MouseButton.Left then

            -- set state to dragging and save start positions
            self.dragging = true
            self.dragStartX = args.X
            self.dragStartY = args.Y

        end

    end

    self.moveAnchor.MouseMove = function (sender, args)

        if self.dragging == true then
            
            local x, y = self:GetPosition()
            
            -- calculate the new position
			x = x + ( args.X - self.dragStartX )
            y = y + ( args.Y - self.dragStartY )

            -- set new position
            self:SetPosition( x, y )

        end

    end

    self.moveAnchor.MouseUp = function (sender, args)

        if args.Button == Turbine.UI.MouseButton.Left then
            
            -- stop dragging
            self.dragging = false

            local x, y = self:GetPosition()
            
            _G.Settings.left = x
            _G.Settings.top = y

            _G.SaveSettings()

        end

    end

    self:ApplySettings()
    self:SetVisible(true)

end

function PotatoWindow:DisplayDuration(icon, duration, targetName)
    
    for i = 1, self.listbox:GetItemCount(), 1 do
        self.listbox:GetItem(i):DisplayDuration(icon, duration, targetName)
    end

end

function PotatoWindow:TargetChanged(targetName)

    for i = 1, self.listbox:GetItemCount(), 1 do
        self.listbox:GetItem(i):TargetChanged(targetName)
    end

end

function PotatoWindow:DefeatTooltip(targetName)

    for i = 1, self.listbox:GetItemCount(), 1 do
        self.listbox:GetItem(i):DefeatTooltip(targetName)
    end

end

function PotatoWindow:ShowAnchor(value)

    self.moveAnchor:SetVisible(value)

end

function PotatoWindow.KeyDown(sender, args)

    -- find key with this
    -- Turbine.Shell.WriteLine(args.Action)

    -- add tooltip on "j"
    if args.Shift == _G.Settings.keybinding_add.shift
        and args.Alt == _G.Settings.keybinding_add.alt
        and args.Control == _G.Settings.keybinding_add.ctrl
        and args.Action == _G.Settings.keybinding_add.action then

        return Potato:AddTooltip()
    end

    -- remove dead tooltips on ctrl "j"
    if _G.Settings.use_clear_keybinding == true
        and args.Shift == _G.Settings.keybinding_clear.shift
        and args.Alt == _G.Settings.keybinding_clear.alt
        and args.Control == _G.Settings.keybinding_clear.ctrl
        and args.Action == _G.Settings.keybinding_clear.action then

        return Potato:ClearDeadTooltips()
    end


end

function PotatoWindow:AddTooltip()

    local localPlayer = Turbine.Gameplay.LocalPlayer:GetInstance()
    local target = localPlayer:GetTarget()
    local _ = localPlayer:GetTarget()  -- second GetTarget() call required; first call may return stale entity

    -- return if player has no target
    if target == nil then
        return
    end

    local entityType = 1
    if target.GetLevel == nil then
        entityType = 2
    elseif target.GetAlignment == nil then
        entityType = 3
    end

    local targetName = target:GetName()

    if entityType ~= 2 and targetName ~= localPlayer:GetName() then
        entityType = self:CheckPartyForType(localPlayer:GetParty(), targetName)
    end

    self.listbox:AddItem(ui.PotatoTooltip(targetName, target, entityType, self))

    -- sort alphabeticly
    if _G.Settings.sort == 1 then
        self.listbox:Sort(
            function (a, b)
                if a.name < b.name then
                    return true
                end
                return false
            end
        )
    end

end

function PotatoWindow:CheckPartyForType(party, targetName)
    
    if party == nil then
        return 3
    end

    for i = 1, party:GetMemberCount(), 1 do
        local member = party:GetMember(i)
        if member:GetName() == targetName then
            return 1
        end
    end

    return 3

end

function PotatoWindow:ClearDeadTooltips()
    
    for i = self.listbox:GetItemCount(), 1, -1 do
        self.listbox:GetItem(i):ClearDeadTooltips()
    end

end

function PotatoWindow:RemoveTooltip(tooltip)
    
    self.listbox:RemoveItem(tooltip)

end

function PotatoWindow:ApplySettings()
    
    -- position
    self:SetPosition(_G.Settings.left, _G.Settings.top)

    -- size
    local height = (_G.Settings.tooltip_height + _G.Settings.tooltip_spacing) * _G.Settings.max_tooltip_count
    local width = _G.Settings.width + _G.Settings.tooltip_spacing
    if _G.Settings.horizontal then
        height = _G.Settings.tooltip_height
        width = (_G.Settings.width + _G.Settings.tooltip_spacing) * _G.Settings.max_tooltip_count
        self.listbox:SetMaxItemsPerLine(1)
    else
        self.listbox:SetMaxItemsPerLine()
    end
    self.listbox:SetReverseFill(_G.Settings.reverseFill)
    self:SetSize(width, height)
    self.listbox:SetSize(width, height)

    for i = self.listbox:GetItemCount(), 1, -1 do
        self.listbox:GetItem(i):ApplySettings()
    end


end
