
-- PotatoTooltip
--
-- one tracker card per pinned entity
--
-- - a rail down the left edge carrying the entity type, thickened when it's your target
-- - name, type line, and a dismiss column that only appears on hover
-- - CC and morale bars along the bottom edge
--
-- the card is a fixed height whatever is showing: the name and type line own the top of it and
-- the bars live in the bottom strip, so turning morale on never moves the HUD
---------------------------------------------------------------------------------------------------

import "Potato.ui.theme"


PotatoTooltip = class( Turbine.UI.Control )

-- a plain rectangle — the redesign is built almost entirely out of these
local function Rect(parent, color)

    local rect = Turbine.UI.Control()
    rect:SetParent(parent)
    rect:SetMouseVisible(false)
    if color ~= nil then
        rect:SetBackColor(color)
    end

    return rect

end

function PotatoTooltip:Constructor(name, entity, entityType, parentWindow)
	Turbine.UI.Control.Constructor( self )

    self.name = name
    self.entity = entity
    self.entityType = entityType
    self.parentWindow = parentWindow

    self.isDead = false
    self.isTarget = true
    self.isHover = false
    self.ccBreaking = false
    self.moraleVisible = false
    self.moraleStale = false
    self.moraleFraction = 0

    self:SetMouseVisible(true)

    -- card fill. this is the game's own EntityControl rather than a plain rect: it carries the
    -- state fill as its back color, and being the bottom layer across the whole card it also keeps
    -- the click-to-target and right-click context menu the game gives us for free. everything
    -- drawn over it is mouse-invisible, so those events still reach it.
    self.entityControl = Turbine.UI.Lotro.EntityControl()
    self.entityControl:SetParent(self)
    self.entityControl:SetPosition(0, 0)
    self.entityControl:SetEntity(entity)
    self.entityControl.MouseEnter = function(sender, args)
        self:SetHover(true)
    end
    self.entityControl.MouseLeave = function(sender, args)
        self:SetHover(false)
    end

    -- border, four rects so the target state can thicken it from 1px to 2px
    self.borderTop    = Rect(self)
    self.borderBottom = Rect(self)
    self.borderLeft   = Rect(self)
    self.borderRight  = Rect(self)

    -- type rail, drawn after the border so it covers the left edge
    self.rail = Rect(self)

    -- name
    self.nameLabel = Turbine.UI.Label()
    self.nameLabel:SetParent(self)
    self.nameLabel:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.nameLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.nameLabel:SetMouseVisible(false)
    self.nameLabel:SetText(name)

    -- struck through the name once defeated
    self.strikeLine = Rect(self)
    self.strikeLine:SetVisible(false)

    -- type line — entity type, or the skill name while a CC timer runs
    self.typeLabel = Turbine.UI.Label()
    self.typeLabel:SetParent(self)
    self.typeLabel:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    self.typeLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.typeLabel:SetFont(_G.Theme.font.typeLine)
    self.typeLabel:SetMarkupEnabled(true)
    self.typeLabel:SetMouseVisible(false)

    -- CC seconds, as a number and a smaller trailing "s"
    self.ccSeconds = Turbine.UI.Label()
    self.ccSeconds:SetParent(self)
    self.ccSeconds:SetTextAlignment(Turbine.UI.ContentAlignment.BottomRight)
    self.ccSeconds:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.ccSeconds:SetFont(_G.Theme.font.ccSeconds)
    self.ccSeconds:SetForeColor(_G.Theme.color.accentPale)
    self.ccSeconds:SetMouseVisible(false)
    self.ccSeconds:SetVisible(false)

    self.ccSuffix = Turbine.UI.Label()
    self.ccSuffix:SetParent(self)
    self.ccSuffix:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    self.ccSuffix:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.ccSuffix:SetFont(_G.Theme.font.ccSuffix)
    self.ccSuffix:SetForeColor(_G.Theme.color.textMuted)
    self.ccSuffix:SetText("s")
    self.ccSuffix:SetMouseVisible(false)
    self.ccSuffix:SetVisible(false)

    -- morale percentage, when the right edge isn't taken by the seconds
    self.moralePct = Turbine.UI.Label()
    self.moralePct:SetParent(self)
    self.moralePct:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)
    self.moralePct:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.moralePct:SetFont(_G.Theme.font.moralePct)
    self.moralePct:SetForeColor(_G.Theme.color.greenLight)
    self.moralePct:SetMouseVisible(false)
    self.moralePct:SetVisible(false)

    -- bars, bottom-up: morale then CC. fills are created after their tracks so they draw on top
    self.moraleTrack = Rect(self, _G.Theme.color.barTrack)
    self.moraleTrack:SetVisible(false)
    self.moraleFill = Rect(self, _G.Theme.color.green)
    self.moraleFill:SetVisible(false)

    self.ccTrack = Rect(self, _G.Theme.color.barTrack)
    self.ccTrack:SetVisible(false)
    self.ccFill = Rect(self, _G.Theme.color.accent)
    self.ccFill:SetVisible(false)

    -- dismiss column, hover only. the permanent red X is gone
    self.dismissCol = Turbine.UI.Control()
    self.dismissCol:SetParent(self)
    self.dismissCol:SetBackColor(_G.Theme.color.dismiss)
    -- the back color carries an alpha, and the default blend mode composites it into everything
    -- drawn behind rather than over it. AlphaBlend keeps the translucency on this fill alone.
    self.dismissCol:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self.dismissCol:SetVisible(false)
    self.dismissCol.MouseClick = function(sender, args)
        self.parentWindow:RemoveTooltip(self)
    end
    self.dismissCol.MouseEnter = function(sender, args)
        self:SetHover(true)
    end
    self.dismissCol.MouseLeave = function(sender, args)
        self:SetHover(false)
    end

    self.dismissLabel = Turbine.UI.Label()
    self.dismissLabel:SetParent(self.dismissCol)
    self.dismissLabel:SetPosition(0, 0)
    self.dismissLabel:SetText("x")
    self.dismissLabel:SetFont(_G.Theme.font.dismiss)
    self.dismissLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.dismissLabel:SetForeColor(_G.Theme.color.dismissGlyph)
    self.dismissLabel:SetFontStyle(Turbine.UI.FontStyle.Outline)
    self.dismissLabel:SetMouseVisible(false)

    self.MouseEnter = function(sender, args)
        self:SetHover(true)
    end
    self.MouseLeave = function(sender, args)
        self:SetHover(false)
    end

    self:ApplySettings()

end

---------------------------------------------------------------------------------------------------
-- state

-- hover only shows through on a card that isn't already carrying a louder state
function PotatoTooltip:SetHover(value)

    -- with the dismiss column switched off the card is cleared by the keybinding instead, so the
    -- hover fill still changes but nothing is drawn over the name
    self.dismissCol:SetVisible(value and _G.Settings.show_dismiss ~= false)

    if self.isHover ~= value then
        self.isHover = value
        self:ApplyState()
    end

end

-- resolves every state cue at once — fill, border, rail, name and type line — from the card's
-- current flags, so there's one place that decides what a card looks like.
--
-- precedence, following the half-second read the design is built around: your target beats
-- everything, then CC breaking, then defeated, then plain hover. a card that is both your target
-- and breaking keeps the target frame and still says BREAKING on its type line and in its bar,
-- so neither signal is lost.
function PotatoTooltip:ApplyState()

    local color = _G.Theme.color

    local fill    = color.card
    local border  = color.line
    local rail    = _G.Theme.RailColor(self.entityType)
    local nameCol = _G.Theme.NameColor(self.entityType)
    local railW   = _G.Theme.metrics.railWidth
    local borderW = _G.Theme.metrics.borderWidth

    if self.isDead then

        fill    = color.cardDead
        border  = color.lineDead
        rail    = color.greyRailDim
        nameCol = color.textQuiet

    elseif self.ccBreaking then

        fill   = color.cardWarn
        border = color.redLine

    elseif self.isHover then

        fill   = color.cardHover
        border = color.lineStrong

    end

    if self.isTarget then

        fill    = color.cardTarget
        border  = color.accent
        rail    = color.accent
        railW   = _G.Theme.metrics.railTargetWidth
        borderW = _G.Theme.metrics.borderTarget

        if not self.isDead then
            nameCol = color.textBright
        end

    end

    self.entityControl:SetBackColor(fill)
    self.nameLabel:SetForeColor(nameCol)
    self.strikeLine:SetBackColor(nameCol)
    self.strikeLine:SetVisible(self.isDead)

    local m = self.metrics
    self.borderTop:SetBackColor(border)
    self.borderTop:SetSize(m.width, borderW)
    self.borderTop:SetPosition(0, 0)
    self.borderBottom:SetBackColor(border)
    self.borderBottom:SetSize(m.width, borderW)
    self.borderBottom:SetPosition(0, m.height - borderW)
    self.borderLeft:SetBackColor(border)
    self.borderLeft:SetSize(borderW, m.height)
    self.borderLeft:SetPosition(0, 0)
    self.borderRight:SetBackColor(border)
    self.borderRight:SetSize(borderW, m.height)
    self.borderRight:SetPosition(m.width - borderW, 0)

    self.rail:SetBackColor(rail)
    self.rail:SetSize(railW, m.height)
    self.rail:SetPosition(0, 0)

    -- kept for the dismiss column, which insets itself by the border
    self.borderWidth = borderW

    self:LayoutBars()
    self:RefreshTypeLine()

end

-- the type line carries the most useful word available: the skill holding the target, or how long
-- a defeated card has left, or just what the thing is
function PotatoTooltip:RefreshTypeLine()

    local m = self.metrics

    if m.typeLine == false then
        self.typeLabel:SetVisible(false)
        return
    end

    local color = _G.Theme.color
    local text, textColor

    if self.endTime ~= nil and self.ccBreaking then

        text      = "BREAKING"
        textColor = color.redText

    elseif self.endTime ~= nil and self.ccSkillName ~= nil then

        text      = string.upper(self.ccSkillName)
        textColor = color.textMuted

    elseif self.isDead then

        text      = "DEFEATED"
        textColor = color.textFaint

        local delay = _G.Settings.defeat_auto_remove_delay
        if delay > 0 and self.defeatTime ~= nil then
            local left = math.ceil(delay - (Turbine.Engine.GetGameTime() - self.defeatTime))
            if left > 0 then
                text = "DEFEATED" .. _G.Theme.sep .. left .. "s"
            end
        end

    else

        text      = _G.Theme.TypeName(self.entityType)
        textColor = color.textQuiet

    end

    -- one suffix at most. being your target is the louder fact, so it wins the slot; the morale
    -- figure only moves inline here when the seconds have taken the card's right edge
    local suffix, suffixColor

    if self.isTarget then

        suffix      = _G.Theme.sep .. "YOUR TARGET"
        suffixColor = color.accentLight

    elseif self.endTime ~= nil and self.moraleVisible and _G.Settings.morale_show_number ~= false then

        suffix      = _G.Theme.sep .. math.floor(self.moraleFraction * 100) .. "%"
        suffixColor = self:MoraleTextColor()

    end

    local markup = "<rgb=" .. _G.Theme.Markup(textColor) .. ">" .. text .. "</rgb>"
    if suffix ~= nil then
        markup = markup .. "<rgb=" .. _G.Theme.Markup(suffixColor) .. ">" .. suffix .. "</rgb>"
    end

    self.typeLabel:SetText(markup)
    self.typeLabel:SetVisible(true)

end

function PotatoTooltip:MoraleTextColor()

    if self.moraleStale then
        return _G.Theme.color.textFaint
    end

    if self.moraleFraction * 100 <= (_G.Settings.morale_warn_pct or 25) then
        return _G.Theme.color.redLight
    end

    return _G.Theme.color.greenLight

end

function PotatoTooltip:MoraleFillColor()

    if self.moraleStale then
        return _G.Theme.color.line
    end

    if self.moraleFraction * 100 <= (_G.Settings.morale_warn_pct or 25) then
        return _G.Theme.color.red
    end

    return _G.Theme.color.green

end

---------------------------------------------------------------------------------------------------
-- bars

-- how much of the card's bottom edge the bars are currently occupying
function PotatoTooltip:BarStripHeight()

    local m = self.metrics
    local ccOn     = self.endTime ~= nil
    local moraleOn = self.moraleVisible

    if ccOn and moraleOn then
        return (m.barHeight * 2) + _G.Theme.metrics.barGap
    elseif ccOn or moraleOn then
        return m.soloBar
    end

    return 0

end

-- the dismiss column clears both the frame and whatever bars are showing, so it never covers a
-- timer or a morale figure. it is laid out from LayoutBars rather than ApplySettings because both
-- of its insets move at runtime: the border thickens on a targeted card, and the bar strip grows
-- as CC and morale come and go.
function PotatoTooltip:LayoutDismiss()

    local m = self.metrics
    local borderW = self.borderWidth or _G.Theme.metrics.borderWidth
    local barStrip = self:BarStripHeight()

    local width  = _G.Theme.metrics.dismissWidth
    local bottom = (barStrip > 0) and barStrip or borderW
    local height = m.height - borderW - bottom

    self.dismissCol:SetSize(width, height)
    self.dismissCol:SetPosition(m.width - borderW - width, borderW)
    self.dismissLabel:SetSize(width, height)

end

-- both bars sit in the bottom strip of the card. when only one is showing it is a touch taller and
-- owns the bottom edge on its own; when both are, CC is always the outer one, because it's the bar
-- that turns red.
function PotatoTooltip:LayoutBars()

    local m = self.metrics
    local color = _G.Theme.color

    local ccOn     = self.endTime ~= nil
    local moraleOn = self.moraleVisible
    local both     = ccOn and moraleOn

    -- a thickened rail pushes the bars clear of it
    local left = self.isTarget and _G.Theme.metrics.railTargetWidth or 0
    local width = m.width - left
    self.barWidth = width

    -- a targeted card's fill is light enough that the bars need a darker track under them
    local track = self.isTarget and color.ground or color.barTrack
    self.moraleTrack:SetBackColor(track)
    self.ccTrack:SetBackColor(track)

    local ccHeight     = both and m.barHeight or m.soloBar
    local moraleHeight = both and m.barHeight or m.soloBar
    local ccTop        = m.height - ccHeight
    local moraleTop    = both
        and (ccTop - moraleHeight - _G.Theme.metrics.barGap)
        or  (m.height - moraleHeight)

    self.moraleTrack:SetPosition(left, moraleTop)
    self.moraleTrack:SetSize(width, moraleHeight)
    self.moraleFill:SetPosition(left, moraleTop)
    self.moraleFill:SetSize(math.floor(width * self.moraleFraction), moraleHeight)
    self.moraleTrack:SetVisible(moraleOn)
    self.moraleFill:SetVisible(moraleOn and not self.isDead)

    self.ccTrack:SetPosition(left, ccTop)
    self.ccTrack:SetSize(width, ccHeight)
    self.ccFill:SetPosition(left, ccTop)
    self.ccFill:SetSize(math.floor(width * (self.ccFraction or 1)), ccHeight)
    self.ccTrack:SetVisible(ccOn)
    self.ccFill:SetVisible(ccOn)

    if ccOn then
        self.ccFill:SetBackColor(self:CCFillColor())
    end

    -- the percentage only gets the right edge when the seconds aren't using it, and a compact
    -- card drops it entirely once a timer is running
    local showPct = moraleOn
        and _G.Settings.morale_show_number ~= false
        and not ccOn

    self.moralePct:SetVisible(showPct)
    self.ccSeconds:SetVisible(ccOn)
    self.ccSuffix:SetVisible(ccOn)

    self:LayoutDismiss()

end

function PotatoTooltip:CCFillColor()

    if self.ccBreaking then
        return _G.Theme.color.red
    end

    -- lightened so it still separates from a targeted card's lifted fill
    if self.isTarget then
        return _G.Theme.color.accentLight
    end

    return _G.Theme.color.accent

end

---------------------------------------------------------------------------------------------------
-- events

function PotatoTooltip:ClearDeadTooltips()

    if _G.Settings.only_clear_dead == false or self.isDead then
        self.parentWindow:RemoveTooltip(self)
    end

end

function PotatoTooltip:TargetChanged(targetName)

    if targetName == self.name and self.isTarget == false then
        self.isTarget = true
        self:ApplyState()
    elseif targetName ~= self.name and self.isTarget == true then
        self.isTarget = false
        self:ApplyState()
    end

end

function PotatoTooltip:DisplayDuration(icon, duration, targetName, skillName)

    if targetName ~= self.name then
        return
    end

    self.duration    = duration
    self.startTime   = Turbine.Engine.GetGameTime()
    self.endTime     = self.startTime + duration
    self.ccSkillName = skillName or "CC"
    self.ccIcon      = icon
    self.ccFraction  = 1
    self.ccBreaking  = duration <= _G.Settings.cc_warning_threshold

    self.ccSeconds:SetText(tostring(math.ceil(duration)))
    self.ccSeconds:SetForeColor(self.ccBreaking and _G.Theme.color.redLight or _G.Theme.color.accentPale)

    self:SetWantsUpdates(true)
    self:ApplyState()

end

function PotatoTooltip:DefeatTooltip(targetName)

    if targetName == self.name and self.isDead == false then

        self.isDead = true

        if _G.Settings.defeat_auto_remove_delay > 0 then
            self.defeatTime = Turbine.Engine.GetGameTime()
            self:SetWantsUpdates(true)
        end

        self:ApplyState()

    end

end

function PotatoTooltip:UpdateMorale()

    if not (_G.Settings.display_morale and self.entity) then return end

    local ok,  morale    = pcall(function() return self.entity:GetMorale() end)
    local ok2, maxMorale = pcall(function() return self.entity:GetMaxMorale() end)

    if ok and ok2 and maxMorale and maxMorale > 0 then

        self.moraleFraction = morale / maxMorale
        self.moraleVisible = true
        self.moraleStale = false
        self.lastMoraleUpdateTime = Turbine.Engine.GetGameTime()

        self.moraleFill:SetBackColor(self:MoraleFillColor())
        self.moralePct:SetForeColor(self:MoraleTextColor())
        self.moralePct:SetText(tostring(math.floor(self.moraleFraction * 100)) .. "%")

        self:LayoutBars()
        self:RefreshTypeLine()
        self:SetWantsUpdates(true)

    else

        self.moraleVisible = false
        self:LayoutBars()

    end

end

function PotatoTooltip:Update()

    local now = Turbine.Engine.GetGameTime()
    local keepUpdating = false

    -- defeated cards count down to their own removal on the type line
    if self.isDead and self.defeatTime then

        local delay = _G.Settings.defeat_auto_remove_delay
        if delay > 0 and (now - self.defeatTime) >= delay then
            self.parentWindow:RemoveTooltip(self)
            return
        end

        keepUpdating = true
        self:RefreshTypeLine()

    end

    if self.endTime then

        local timeLeft = self.endTime - now

        if timeLeft <= 0 then

            self.endTime = nil
            self.ccSkillName = nil
            self.ccBreaking = false
            self:ApplyState()

        else

            keepUpdating = true

            -- kept on the card so a relayout mid-drain (hover, target change) doesn't snap the
            -- bar back to full width for a frame
            self.ccFraction = timeLeft / self.duration
            self.ccFill:SetWidth(math.floor(self.barWidth * self.ccFraction))
            self.ccSeconds:SetText(tostring(math.ceil(timeLeft)))

            -- the warning colors are set on the crossing, not on every frame
            local breaking = timeLeft <= _G.Settings.cc_warning_threshold
            if breaking ~= self.ccBreaking then
                self.ccBreaking = breaking
                self.ccSeconds:SetForeColor(breaking and _G.Theme.color.redLight or _G.Theme.color.accentPale)
                self:ApplyState()
            end

        end

    end

    -- morale only updates while the game sends events for the entity. after five seconds of
    -- silence the bar greys out rather than showing a stale figure as if it were live.
    if self.moraleVisible and self.lastMoraleUpdateTime and _G.Settings.morale_grey_stale ~= false then

        if (now - self.lastMoraleUpdateTime) < 5 then
            keepUpdating = true
        elseif not self.moraleStale then
            self.moraleStale = true
            self.moraleFill:SetBackColor(self:MoraleFillColor())
            self.moralePct:SetForeColor(self:MoraleTextColor())
            self:RefreshTypeLine()
        end

    end

    if not keepUpdating then
        self:SetWantsUpdates(false)
    end

end

---------------------------------------------------------------------------------------------------

function PotatoTooltip:ApplySettings()

    local m = _G.Theme.CardMetrics()
    self.metrics = m

    -- the listbox spaces its items by their own size, so the gap rides on the control
    self:SetSize(m.width + m.gap, m.height + m.gap)
    self.entityControl:SetSize(m.width, m.height)

    -- name. the right-hand column is left clear for the hover dismiss and the seconds
    local textWidth = m.width - m.nameLeft - 46

    self.nameLabel:SetFont(m.nameFont)
    self.nameLabel:SetPosition(m.nameLeft, m.nameTop)
    self.nameLabel:SetSize(textWidth, m.nameHeight)
    self.nameLabel:SetFontStyle(
        _G.Settings.name_outline == false
            and Turbine.UI.FontStyle.None
            or  Turbine.UI.FontStyle.Outline
    )

    self.strikeLine:SetPosition(m.nameLeft, m.strikeTop)
    self.strikeLine:SetSize(math.min(100, textWidth), 1)

    if m.typeLine then
        self.typeLabel:SetPosition(m.nameLeft, m.typeTop)
        self.typeLabel:SetSize(textWidth, m.typeHeight)
    end

    -- the seconds and their smaller "s" share a baseline at the card's right edge
    local suffixWidth = 8
    self.ccSuffix:SetSize(suffixWidth, m.ccHeight)
    self.ccSuffix:SetPosition(m.width - 11 - suffixWidth, m.ccTop)
    self.ccSeconds:SetSize(44, m.ccHeight)
    self.ccSeconds:SetPosition(m.width - 11 - suffixWidth - 44, m.ccTop)

    self.moralePct:SetSize(40, m.moraleHeight)
    self.moralePct:SetPosition(m.width - 11 - 40, m.moraleTop)

    -- the dismiss column is positioned in ApplyState, since its inset tracks the border width.
    -- switching it off while a card is hovered has to take effect now rather than on the next
    -- mouse leave.
    if _G.Settings.show_dismiss == false then
        self.dismissCol:SetVisible(false)
    end

    -- morale events
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

        self.moraleVisible = false

    end

    self:ApplyState()

end
