
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
    self.entity = entity

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
    self.durationLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    self.durationLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.durationLabel:SetForeColor(Turbine.UI.Color.White)
    self.durationLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.durationLabel:SetMouseVisible(false)
    self.durationLabel:SetVisible(false)

    -- morale bar track
    self.moraleBarTrack = Turbine.UI.Control()
    self.moraleBarTrack:SetParent(self)
    self.moraleBarTrack:SetBackColor(Turbine.UI.Color(0.1, 0.05, 0.05))
    self.moraleBarTrack:SetMouseVisible(false)
    self.moraleBarTrack:SetVisible(false)

    -- morale bar fill (declared after track so it renders on top)
    self.moraleBar = Turbine.UI.Control()
    self.moraleBar:SetParent(self)
    self.moraleBar:SetBackColor(Turbine.UI.Color(0.1, 0.6, 0.15))
    self.moraleBar:SetMouseVisible(false)
    self.moraleBar:SetVisible(false)

    -- morale percent label
    self.moraleLabel = Turbine.UI.Label()
    self.moraleLabel:SetParent(self)
    self.moraleLabel:SetFont(Turbine.UI.Lotro.Font.Verdana12)
    self.moraleLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.moraleLabel:SetForeColor(Turbine.UI.Color.White)
    self.moraleLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.moraleLabel:SetMouseVisible(false)
    self.moraleLabel:SetVisible(false)

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
    local keepUpdating = false

    if self.isDead and self.defeatTime then
        local delay = _G.Settings.defeat_auto_remove_delay
        if delay > 0 and (now - self.defeatTime) >= delay then
            self.parentWindow:RemoveTooltip(self)
            return
        end
        keepUpdating = true
    end

    if self.endTime then
        local timeLeft = self.endTime - now
        if timeLeft <= 0 then
            self.endTime = nil
            self.durationIcon:SetVisible(false)
            self.durationBarTrack:SetVisible(false)
            self.durationBar:SetVisible(false)
            self.durationLabel:SetVisible(false)
        else
            keepUpdating = true
            self.durationBar:SetWidth(timeLeft / self.duration * self.durationBarWidth)
            self.durationLabel:SetText(tostring(math.ceil(timeLeft)) .. "s")
            if timeLeft <= _G.Settings.cc_warning_threshold then
                self.durationBar:SetBackColor(Turbine.UI.Color.Red)
            else
                self.durationBar:SetBackColor(Turbine.UI.Color.Orange)
            end
        end
    end

    if _G.Settings.display_morale and self.lastMoraleUpdateTime then
        local elapsed = now - self.lastMoraleUpdateTime
        if elapsed < 5 then
            keepUpdating = true
        elseif elapsed < 15 then
            keepUpdating = true
            local t = (elapsed - 5) / 10
            self.moraleBar:SetBackColor(Turbine.UI.Color(
                0.1 + 0.4 * t,
                0.6 - 0.1 * t,
                0.15 + 0.35 * t
            ))
        else
            self.moraleBar:SetBackColor(Turbine.UI.Color(0.5, 0.5, 0.5))
        end
    end

    if not keepUpdating then
        self:SetWantsUpdates(false)
    end

end

function PotatoTooltip:UpdateMorale()

    if not (_G.Settings.display_morale and self.entity) then return end
    local ok,  morale    = pcall(function() return self.entity:GetMorale() end)
    local ok2, maxMorale = pcall(function() return self.entity:GetMaxMorale() end)
    if ok and ok2 and maxMorale and maxMorale > 0 then
        local pct = morale / maxMorale
        self.moraleBar:SetWidth(math.floor(pct * self.moraleBarWidth))
        self.moraleLabel:SetText(tostring(math.floor(pct * 100)) .. "%")
        self.moraleBarTrack:SetVisible(true)
        self.moraleBar:SetVisible(true)
        self.moraleLabel:SetVisible(true)
        self.lastMoraleUpdateTime = Turbine.Engine.GetGameTime()
        self.moraleBar:SetBackColor(Turbine.UI.Color(0.1, 0.6, 0.15))
        self:SetWantsUpdates(true)
    else
        self.moraleBarTrack:SetVisible(false)
        self.moraleBar:SetVisible(false)
        self.moraleLabel:SetVisible(false)
    end

end

function PotatoTooltip:DisplayDuration(icon, duration, targetName)

    if targetName == self.name then
        self.durationIcon:SetBackground(icon)
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

    local ccBarH   = _G.Settings.display_durations and _G.Settings.duration_bar_height or 0
    local moraleH  = _G.Settings.display_morale    and _G.Settings.duration_bar_height or 0
    local totalHeight = _G.Settings.tooltip_height
        + ccBarH  + (ccBarH  > 0 and 2 or 0)
        + moraleH + (moraleH > 0 and 2 or 0)

    -- outer card size (spacing on both axes so gap is equal on bottom and right)
    self:SetSize(_G.Settings.width + _G.Settings.tooltip_spacing, totalHeight + _G.Settings.tooltip_spacing)

    -- border frame: full tooltip area (no spacing)
    self.borderFrame:SetPosition(0, 0)
    self.borderFrame:SetSize(_G.Settings.width, totalHeight)

    -- colored background: inset 1px inside border
    self.frame:SetPosition(1, 1)
    self.frame:SetSize(_G.Settings.width - 2, totalHeight - 2)

    -- entity control: inset 2px total (1 border + 1 gap)
    self.entityControl:SetPosition(2, 2)
    self.entityControl:SetSize(_G.Settings.width - 4, totalHeight - 4)

    -- name label
    local labelWidth = _G.Settings.width - (2*_G.Settings.tooltip_label_spacing) - 22
    self.nameLabel:SetPosition(_G.Settings.tooltip_label_spacing, 2)
    self.nameLabel:SetSize(labelWidth, 38)

    -- close button: right-edge, inset to match border
    local closeButtonLeft = _G.Settings.width - 22
    self.closeButton:SetLeft(closeButtonLeft)

    -- duration area sizing: bar sits below the name area, starting at the original tooltip bottom
    local iconBarGap = 2
    self.durationHeight = _G.Settings.duration_bar_height
    self.durationBarWidth = _G.Settings.width - (2*_G.Settings.tooltip_label_spacing) - self.durationHeight - iconBarGap
    local durationTop = _G.Settings.tooltip_height - 2
    local moraleTop   = durationTop + ccBarH + (ccBarH > 0 and 2 or 0)
    local barLeft     = _G.Settings.tooltip_label_spacing + self.durationHeight + iconBarGap

    -- duration icon
    self.durationIcon:SetLeft(_G.Settings.tooltip_label_spacing)
    self.durationIcon:SetTop(durationTop)
    self.durationIcon:SetStretchMode(1)
    self.durationIcon:SetSize(self.durationHeight, self.durationHeight)

    -- duration bar track (full-width background)
    self.durationBarTrack:SetLeft(barLeft)
    self.durationBarTrack:SetTop(durationTop)
    self.durationBarTrack:SetWidth(self.durationBarWidth)
    self.durationBarTrack:SetHeight(self.durationHeight)

    -- duration bar fill
    self.durationBar:SetLeft(barLeft)
    self.durationBar:SetTop(durationTop)
    self.durationBar:SetWidth(self.durationBarWidth)
    self.durationBar:SetHeight(self.durationHeight)

    -- countdown label (overlaid on bar area)
    self.durationLabel:SetLeft(barLeft)
    self.durationLabel:SetTop(durationTop)
    self.durationLabel:SetSize(self.durationBarWidth, self.durationHeight)

    -- morale bar
    local moraleLabelWidth = 38
    self.moraleBarWidth = _G.Settings.width - (2 * _G.Settings.tooltip_label_spacing) - moraleLabelWidth

    self.moraleLabel:SetLeft(_G.Settings.tooltip_label_spacing)
    self.moraleLabel:SetTop(moraleTop)
    self.moraleLabel:SetSize(moraleLabelWidth, self.durationHeight)

    self.moraleBarTrack:SetLeft(_G.Settings.tooltip_label_spacing + moraleLabelWidth)
    self.moraleBarTrack:SetTop(moraleTop)
    self.moraleBarTrack:SetWidth(self.moraleBarWidth)
    self.moraleBarTrack:SetHeight(self.durationHeight)

    self.moraleBar:SetLeft(_G.Settings.tooltip_label_spacing + moraleLabelWidth)
    self.moraleBar:SetTop(moraleTop)
    self.moraleBar:SetWidth(self.moraleBarWidth)
    self.moraleBar:SetHeight(self.durationHeight)

    if _G.Settings.display_morale and self.entity then
        local handler = function(sender, args) self:UpdateMorale() end
        self.moraleHandler = handler
        self.entity.MoraleChanged             = handler
        self.entity.BaseMaxMoraleChanged      = handler
        self.entity.MaxMoraleChanged          = handler
        self.entity.MaxTemporaryMoraleChanged = handler
        self.entity.TemporaryMoraleChanged    = handler
        self:UpdateMorale()
    else
        if self.entity and self.moraleHandler then
            local h = self.moraleHandler
            if self.entity.MoraleChanged             == h then self.entity.MoraleChanged             = nil end
            if self.entity.BaseMaxMoraleChanged      == h then self.entity.BaseMaxMoraleChanged      = nil end
            if self.entity.MaxMoraleChanged          == h then self.entity.MaxMoraleChanged          = nil end
            if self.entity.MaxTemporaryMoraleChanged == h then self.entity.MaxTemporaryMoraleChanged = nil end
            if self.entity.TemporaryMoraleChanged    == h then self.entity.TemporaryMoraleChanged    = nil end
            self.moraleHandler = nil
        end
        self.moraleBarTrack:SetVisible(false)
        self.moraleBar:SetVisible(false)
        self.moraleLabel:SetVisible(false)
    end

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
