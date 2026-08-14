
-- PotatoWindow
--
-- the main ui element containing all tooltips
--
-- - also handels sorting
-- - and key events
--
-- there can be several of these, each with its own complete copy of the settings — its own place on
-- screen, size, colours, keybindings and CC skills. the settings table it was handed is the one it
-- reads and writes; it never looks at _G.Settings itself.
---------------------------------------------------------------------------------------------------

import "Potato.ui.theme"
import "Potato.ui.potatoTooltip"


PotatoWindow = class( Turbine.UI.Window )

function PotatoWindow:Constructor(settings, index)
    Turbine.UI.Window.Constructor(self)

    self.settings = settings
    self.index = index

    _G.Theme.Use(self.settings)

    -- self
    self:SetMouseVisible(false)

    -- only the first window listens: one keypress should be handled once, by whichever window the
    -- key belongs to, and the game gives no guarantee about which of several listening windows would
    -- get it. KeyDown below does the routing.
    self:SetWantsKeyEvents(index == 1)

    -- listbox
    self.listbox = Turbine.UI.ListBox()
    self.listbox:SetParent(self)
    self.listbox:SetMouseVisible(false)

    -- drag handle. it used to be a green 20x20 square sitting on top of the first card, covering
    -- its name; it's now a strip above the stack so it never obscures anything
    self.moveAnchor = Turbine.UI.Control()
    self.moveAnchor:SetParent(self)
    self.moveAnchor:SetSize(_G.Theme.metrics.dragHandleWidth, _G.Theme.metrics.dragHandleHeight)
    self.moveAnchor:SetPosition(0, 0)
    self.moveAnchor:SetBackColor(_G.Theme.color.line)
    self.moveAnchor:SetVisible(false)
    self.moveAnchor:SetZOrder(1000)

    self.moveAnchorLabel = Turbine.UI.Label()
    self.moveAnchorLabel:SetParent(self.moveAnchor)
    self.moveAnchorLabel:SetSize(_G.Theme.metrics.dragHandleWidth, _G.Theme.metrics.dragHandleHeight)
    self.moveAnchorLabel:SetPosition(0, 0)
    self.moveAnchorLabel:SetText("DRAG")
    self.moveAnchorLabel:SetFont(_G.Theme.font.dragHandle)
    self.moveAnchorLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.moveAnchorLabel:SetForeColor(_G.Theme.color.dismissGlyph)
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

            self.settings.left = x
            self.settings.top = y

            _G.SaveSettings()

        end

    end

    self:ApplySettings()
    self:SetVisible(true)

end

function PotatoWindow:DisplayDuration(icon, duration, targetName, skillName)

    _G.Theme.Use(self.settings)

    for i = 1, self.listbox:GetItemCount(), 1 do
        self.listbox:GetItem(i):DisplayDuration(icon, duration, targetName, skillName)
    end

end

function PotatoWindow:TargetChanged(targetName)

    _G.Theme.Use(self.settings)

    for i = 1, self.listbox:GetItemCount(), 1 do
        self.listbox:GetItem(i):TargetChanged(targetName)
    end

end

function PotatoWindow:DefeatTooltip(targetName)

    _G.Theme.Use(self.settings)

    for i = 1, self.listbox:GetItemCount(), 1 do
        self.listbox:GetItem(i):DefeatTooltip(targetName)
    end

end

function PotatoWindow:ShowAnchor(value)

    self.settings.show_drag_handle = value
    self:ApplySettings()

end

-- find key with this
-- Turbine.Shell.WriteLine(args.Action)
local function Matches(args, binding)

    return binding ~= nil
       and args.Shift   == binding.shift
       and args.Alt     == binding.alt
       and args.Control == binding.ctrl
       and args.Action  == binding.action

end

-- only window 1 listens (see the constructor), so this is the plugin's single key handler: it walks
-- the windows and gives the press to every one that claims it, rather than stopping at the first.
-- sharing a key between windows is a setup, not a mistake: one key that clears every window at once
-- is the obvious thing to want, and so is one that pins the same target into two of them.
--
-- windows added from the options panel still start unbound, so a new window does not begin
-- duplicating the pins of the one it was copied from until you say so.
function PotatoWindow.KeyDown(sender, args)

    local handled = false

    for _, window in ipairs(_G.PotatoWindows) do

        local s = window.settings

        -- add tooltip on "j"
        if s.use_add_keybinding ~= false and Matches(args, s.keybinding_add) then

            window:AddTooltip()
            handled = true

        -- remove dead tooltips on ctrl "j". a window that has been given the same key for both
        -- pins rather than clears, which is the order these have always been checked in.
        elseif s.use_clear_keybinding == true and Matches(args, s.keybinding_clear) then

            window:ClearDeadTooltips()
            handled = true

        end

    end

    return handled

end

function PotatoWindow:AddTooltip()

    _G.Theme.Use(self.settings)

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
    if self.settings.sort_order == "name" then
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

    _G.Theme.Use(self.settings)

    for i = self.listbox:GetItemCount(), 1, -1 do
        self.listbox:GetItem(i):ClearDeadTooltips()
    end

end

-- the window is going away: either it was removed from the options panel, or the whole list is
-- being rebuilt after loading the global copy. the cards have to be told, so their per-frame updates
-- stop and their morale handlers come off the entity — an orphaned card left holding those would go
-- on firing for the rest of the session.
function PotatoWindow:Destroy()

    for i = self.listbox:GetItemCount(), 1, -1 do
        self.listbox:GetItem(i):Destroy()
    end

    self.listbox:ClearItems()

    self:SetWantsKeyEvents(false)
    self:SetVisible(false)
    self:SetParent(nil)

end

function PotatoWindow:RemoveTooltip(tooltip)

    for i = 1, self.listbox:GetItemCount(), 1 do
        if self.listbox:GetItem(i) == tooltip then
            self.listbox:RemoveItem(tooltip)
            return
        end
    end

end

function PotatoWindow:ApplySettings()

    _G.Theme.Use(self.settings)

    -- position
    self:SetPosition(self.settings.left, self.settings.top)

    -- size. the card is a fixed height now — the bars live inside it, so turning morale or CC on
    -- no longer grows either the card or the stack
    local m = _G.Theme.CardMetrics()
    local height = (m.height + m.gap) * self.settings.max_tooltip_count
    local width = m.width + m.gap
    if self.settings.horizontal then
        height = m.height + m.gap
        width = (m.width + m.gap) * self.settings.max_tooltip_count
        self.listbox:SetMaxItemsPerLine(1)
    else
        self.listbox:SetMaxItemsPerLine()
    end
    self.listbox:SetReverseFill(self.settings.reverseFill)

    -- the handle takes its own strip above the cards, so the window grows to make room for it.
    -- toggling it shifts the stack down by its height, which is fine — you turn it on precisely
    -- when you're about to reposition the HUD anyway
    local handleH = self.settings.show_drag_handle and _G.Theme.metrics.dragHandleHeight or 0

    self.moveAnchor:SetVisible(self.settings.show_drag_handle == true)
    self:SetSize(width, height + handleH)
    self.listbox:SetPosition(0, handleH)
    self.listbox:SetSize(width, height)

    for i = self.listbox:GetItemCount(), 1, -1 do
        self.listbox:GetItem(i):ApplySettings()
    end


end
