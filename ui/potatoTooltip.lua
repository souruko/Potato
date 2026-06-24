
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

    -- thin border around the whole card
    self.borderFrame = Turbine.UI.Control()
    self.borderFrame:SetParent(self)
    self.borderFrame:SetBackColor(Turbine.UI.Color(0.3, 0.3, 0.3))
    self.borderFrame:SetMouseVisible(false)

    -- colored background (inset 1px inside borderFrame)
    self.frame = Turbine.UI.Control()
    self.frame:SetParent(self)

    -- entity control
    self.entityControl = Turbine.UI.Lotro.EntityControl()
    self.entityControl:SetParent(self)
    self.entityControl:SetEntity(entity)

    -- name label
    self.nameLabel = Turbine.UI.Label()
    self.nameLabel:SetParent(self)
    self.nameLabel:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.nameLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.nameLabel:SetFont(Turbine.UI.Lotro.Font.Verdana18)
    self.nameLabel:SetMouseVisible(false)
    self.nameLabel:SetText(name)

    -- close button
    self.closeButton = Turbine.UI.Control()
    self.closeButton:SetParent(self)
    self.closeButton:SetBackColor(Turbine.UI.Color.Red)
    self.closeButton:SetSize(20, 20)
    self.closeButton:SetTop(2)
    self.closeButton.MouseClick = function (sender, args)
        self.parentWindow:RemoveTooltip(self)
    end
    self.closeButton.MouseEnter = function(sender, args)
        self.closeButton:SetBackColor(Turbine.UI.Color(0.75, 0.0, 0.0))
    end
    self.closeButton.MouseLeave = function(sender, args)
        self.closeButton:SetBackColor(Turbine.UI.Color.Red)
    end

    -- "X" label on the close button
    self.closeButtonLabel = Turbine.UI.Label()
    self.closeButtonLabel:SetParent(self.closeButton)
    self.closeButtonLabel:SetSize(20, 20)
    self.closeButtonLabel:SetPosition(0, 0)
    self.closeButtonLabel:SetText("X")
    self.closeButtonLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.closeButtonLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.closeButtonLabel:SetForeColor(Turbine.UI.Color.White)
    self.closeButtonLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.closeButtonLabel:SetMouseVisible(false)

    -- duration bar background track
    self.durationBarTrack = Turbine.UI.Control()
    self.durationBarTrack:SetParent(self)
    self.durationBarTrack:SetBackColor(Turbine.UI.Color(0.15, 0.1, 0.05))
    self.durationBarTrack:SetMouseVisible(false)
    self.durationBarTrack:SetVisible(false)

    -- duration bar fill (declared after track so it renders on top)
    self.durationBar = Turbine.UI.Control()
    self.durationBar:SetParent(self)
    self.durationBar:SetBackColor(Turbine.UI.Color.Orange)
    self.durationBar:SetMouseVisible(false)
    self.durationBar:SetVisible(false)

    -- duration icon
    self.durationIcon = Turbine.UI.Control()
    self.durationIcon:SetParent(self)
    self.durationIcon:SetSize(32, 32)
    self.durationIcon:SetMouseVisible(false)
    self.durationIcon:SetVisible(false)

    -- countdown text label
    self.durationLabel = Turbine.UI.Label()
    self.durationLabel:SetParent(self)
    self.durationLabel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    self.durationLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.durationLabel:SetForeColor(Turbine.UI.Color.White)
    self.durationLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.durationLabel:SetMouseVisible(false)
    self.durationLabel:SetVisible(false)

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

    local now = Turbine.Engine.GetGameTime()

    if self.isDead and self.defeatTime then
        local delay = _G.Settings.defeat_auto_remove_delay
        if delay > 0 and (now - self.defeatTime) >= delay then
            self.parentWindow:RemoveTooltip(self)
            return
        end
    end

    if not self.endTime then return end
    local timeLeft = self.endTime - now

    -- end the duration display
    if timeLeft <= 0 then
        self.endTime = nil
        if not (self.isDead and self.defeatTime) then
            self:SetWantsUpdates(false)
        end
        self.durationIcon:SetVisible(false)
        self.durationBarTrack:SetVisible(false)
        self.durationBar:SetVisible(false)
        self.durationLabel:SetVisible(false)
        return
    end

    local currentBarWidth = timeLeft / self.duration * self.durationBarWidth
    self.durationBar:SetWidth(currentBarWidth)
    self.durationLabel:SetText(tostring(math.ceil(timeLeft)) .. "s")

    if timeLeft <= _G.Settings.cc_warning_threshold then
        self.durationBar:SetBackColor(Turbine.UI.Color.Red)
    else
        self.durationBar:SetBackColor(Turbine.UI.Color.Orange)
    end

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
        self.durationBarTrack:SetVisible(true)
        self.durationBar:SetVisible(true)
        self.durationLabel:SetVisible(true)
        self.durationLabel:SetText(tostring(math.ceil(self.duration)) .. "s")
    end

end

function PotatoTooltip:DefeatTooltip(targetName)

    if targetName == self.name and self.isDead == false then
        self.isDead = true
        self.frame:SetBackColor(_G.Settings.tooltip_defeated_color)
        self.entityControl:SetBackColor(_G.Settings.tooltip_defeated_color)
        self.nameLabel:SetForeColor(_G.Settings.tooltip_defeated_text_color)
        if _G.Settings.defeat_auto_remove_delay > 0 then
            self.defeatTime = Turbine.Engine.GetGameTime()
            self:SetWantsUpdates(true)
        end
    end

end

function PotatoTooltip:ApplySettings()

    -- outer card size (includes spacing gap)
    local selfHeight = _G.Settings.tooltip_height + _G.Settings.tooltip_spacing
    local selfWidth = _G.Settings.width
    if _G.Settings.horizontal then
        selfHeight = _G.Settings.tooltip_height
        selfWidth = _G.Settings.width + _G.Settings.tooltip_spacing
    end
    self:SetSize(selfWidth, selfHeight)

    -- border frame: full tooltip area (no spacing)
    self.borderFrame:SetPosition(0, 0)
    self.borderFrame:SetSize(_G.Settings.width, _G.Settings.tooltip_height)

    -- colored background: inset 1px inside border
    self.frame:SetPosition(1, 1)
    self.frame:SetSize(_G.Settings.width - 2, _G.Settings.tooltip_height - 2)

    -- entity control: inset 2px total (1 border + 1 gap)
    local innerHeight = _G.Settings.tooltip_height - 4
    self.entityControl:SetPosition(2, 2)
    self.entityControl:SetSize(_G.Settings.width - 4, innerHeight)

    -- name label
    local labelWidth = _G.Settings.width - (2*_G.Settings.tooltip_label_spacing) - 22
    self.nameLabel:SetPosition(_G.Settings.tooltip_label_spacing, 2)
    self.nameLabel:SetSize(labelWidth, 38)

    -- close button: right-edge, inset to match border
    local closeButtonLeft = _G.Settings.width - 22
    self.closeButton:SetLeft(closeButtonLeft)

    -- duration area sizing
    self.durationHeight = 32
    if (innerHeight - 38) < 32 then
        self.durationHeight = innerHeight - 38
    end

    self.durationBarWidth = _G.Settings.width - (2*_G.Settings.tooltip_label_spacing) - self.durationHeight
    local durationTop = (math.max((innerHeight - 38 - 32), 0) /2) + 38

    -- duration icon
    self.durationIcon:SetLeft(_G.Settings.tooltip_label_spacing)
    self.durationIcon:SetTop(durationTop)

    -- duration bar track (full-width background)
    self.durationBarTrack:SetLeft(self.durationHeight + _G.Settings.tooltip_label_spacing)
    self.durationBarTrack:SetTop(durationTop)
    self.durationBarTrack:SetWidth(self.durationBarWidth)
    self.durationBarTrack:SetHeight(self.durationHeight)

    -- duration bar fill
    self.durationBar:SetLeft(self.durationHeight + _G.Settings.tooltip_label_spacing)
    self.durationBar:SetTop(durationTop)
    self.durationBar:SetWidth(self.durationBarWidth)
    self.durationBar:SetHeight(self.durationHeight)

    -- countdown label (overlaid on bar area)
    self.durationLabel:SetLeft(self.durationHeight + _G.Settings.tooltip_label_spacing)
    self.durationLabel:SetTop(durationTop)
    self.durationLabel:SetSize(self.durationBarWidth, self.durationHeight)

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
