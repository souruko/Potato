
-- PotatoTooltip
-- 
-- the tooltip ui element
-- 
-- - name
-- - entity
-- - cc duration
---------------------------------------------------------------------------------------------------

PotatoTooltip = class( Turbine.UI.Control )

function PotatoTooltip:Constructor(name, entity, entityType, parentWindow)
	Turbine.UI.Control.Constructor( self )

    self.name = name
    self.entityType = entityType
    self.parentWindow = parentWindow

    self.isDead = false
    self.isTarget = true

    -- self
    self:SetMouseVisible(true)

    self.frame = Turbine.UI.Control()
    self.frame:SetParent(self)

    -- entity control
    self.entityControl = Turbine.UI.Lotro.EntityControl()
    self.entityControl:SetParent(self)
    self.entityControl:SetPosition(1, 1)
    self.entityControl:SetEntity(entity)

    -- name label
    self.nameLabel = Turbine.UI.Label()
    self.nameLabel:SetParent(self)
    -- self.nameLabel:SetMultiline(false)
    self.nameLabel:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.nameLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.nameLabel:SetFont(Turbine.UI.Lotro.Font.Verdana18)
    self.nameLabel:SetPosition(_G.Settings.tooltip_label_spacing, 1)
    self.nameLabel:SetMouseVisible(false)
    self.nameLabel:SetText(name)

    -- close button
    self.closeButton = Turbine.UI.Control()
    self.closeButton:SetParent(self)
    self.closeButton:SetBackColor(Turbine.UI.Color.Red)
    self.closeButton:SetSize(20, 20)
    self.closeButton:SetTop(1)
    self.closeButton.MouseClick = function (sender, args)
        self.parentWindow:RemoveTooltip(self)
    end

    self.durationIcon = Turbine.UI.Control()
    self.durationIcon:SetParent(self)
    self.durationIcon:SetSize(32, 32)
    self.durationIcon:SetLeft(_G.Settings.tooltip_label_spacing)
    self.durationIcon:SetMouseVisible(false)
    self.durationIcon:SetVisible(false)

    self.durationBar = Turbine.UI.Control()
    self.durationBar:SetParent(self)
    self.durationBar:SetHeight(32)
    self.durationBar:SetBackColor(Turbine.UI.Color.Orange)
    self.durationBar:SetMouseVisible(false)
    self.durationBar:SetVisible(false)

    self:ApplySettings()

end

function PotatoTooltip:ClearDeadTooltips()
    if _G.Settings.only_clear_dead == false or self.isDead then
        self.parentWindow:RemoveTooltip(self)
    end
end

function PotatoTooltip:TargetChanged(targetName)

    if targetName == self.name and self.isTarget == false then
        self.isTarget = true
        self.frame:SetBackColor(_G.Settings.tooltip_targeted_color)
    elseif targetName ~= self.name and self.isTarget == true then
        self.isTarget = false
        if self.isDead then
            self.frame:SetBackColor(_G.Settings.tooltip_defeated_color)
        else
            
            if self.entityType == 1 then
                self.frame:SetBackColor(_G.Settings.tooltip_color_player)
            elseif self.entityType == 2 then
                self.frame:SetBackColor(_G.Settings.tooltip_color_item)
            else
                self.frame:SetBackColor(_G.Settings.tooltip_color_npc)
            end

        end
    end

end

function PotatoTooltip:Update()
    
    local timeLeft = self.endTime - Turbine.Engine.GetGameTime()

    -- end the duration display
    if timeLeft <= 0 then
        self:SetWantsUpdates(false)
        self.durationIcon:SetVisible(false)
        self.durationBar:SetVisible(false)
        return
    end

    local currentBarWidth = timeLeft / self.duration * self.durationBarWidth
    self.durationBar:SetWidth(currentBarWidth)

end

function PotatoTooltip:DisplayDuration(icon, duration, targetName)

    if targetName == self.name then
        self.durationIcon:SetSize(32 , 32 )
        self.durationIcon:SetBackground(icon)
        if self.durationHeight ~= 32 then
            self.durationIcon:SetStretchMode(1)
            self.durationIcon:SetSize(self.durationHeight, self.durationHeight)
        end
        self.duration = duration
        self.startTime = Turbine.Engine.GetGameTime()
        self.endTime = self.startTime + self.duration
        self:SetWantsUpdates(true)

        self.durationIcon:SetVisible(true)
        self.durationBar:SetVisible(true)
    end

end

function PotatoTooltip:DefeatTooltip(targetName)

    if targetName == self.name and self.isDead == false then
        self.isDead = true
        self.frame:SetBackColor(_G.Settings.tooltip_defeated_color)
        self.entityControl:SetBackColor(_G.Settings.tooltip_defeated_color)
        self.nameLabel:SetForeColor(_G.Settings.tooltip_defeated_text_color)
    end

end

function PotatoTooltip:ApplySettings()

    -- size
    local selfHeight = _G.Settings.tooltip_height + _G.Settings.tooltip_spacing
    local selfWidth = _G.Settings.width
    if _G.Settings.horizontal then    
        selfHeight = _G.Settings.tooltip_height 
        selfWidth = _G.Settings.width + _G.Settings.tooltip_spacing
    end
    
    self:SetSize(selfWidth, selfHeight)
    self.frame:SetSize(_G.Settings.width , _G.Settings.tooltip_height)
    local innerHeight = _G.Settings.tooltip_height -2
    self.entityControl:SetSize(_G.Settings.width -2 , innerHeight)
    local lableWidth = _G.Settings.width - (2*_G.Settings.tooltip_label_spacing) - 21
    self.nameLabel:SetSize(lableWidth, 38)



    -- positioning
    local closeButtonLeft = _G.Settings.width - 21
    self.closeButton:SetLeft(closeButtonLeft)


    self.durationHeight = 32
    if (innerHeight - 38) < 32 then
        self.durationHeight = innerHeight - 38
    end 

    self.durationBarWidth = _G.Settings.width - (2*_G.Settings.tooltip_label_spacing) - self.durationHeight
    self.durationBar:SetWidth(self.durationBarWidth)
    self.durationBar:SetLeft(self.durationHeight + _G.Settings.tooltip_label_spacing)

    local durationTop = (math.max((innerHeight - 38 - 32), 0) /2) + 38

    self.durationIcon:SetTop(durationTop)
    self.durationBar:SetTop(durationTop)
    self.durationBar:SetHeight(self.durationHeight)

    -- color
    self.frame:SetBackColor(_G.Settings.tooltip_targeted_color)
            
    if self.entityType == 1 then
        self.entityControl:SetBackColor(_G.Settings.tooltip_color_player)
    elseif self.entityType == 2 then
        self.entityControl:SetBackColor(_G.Settings.tooltip_color_item)
    else
        self.entityControl:SetBackColor(_G.Settings.tooltip_color_npc)
    end

end