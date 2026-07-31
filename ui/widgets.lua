
-- Widgets
--
-- the options panel's shared controls, drawn from rectangles instead of the LotRO widget skins
--
-- - Checkbox, Stepper, Segmented, KeyCap, Swatch, Button
-- - Label, Help, Divider, Row, PreviewCard
--
-- each returns a table wrapping its root control, so a pane can hold on to it and read or set its
-- value later. everything here reads its colors and fonts from Theme.
---------------------------------------------------------------------------------------------------

import "Turbine.UI"
import "Turbine.UI.Lotro"
import "Potato.ui.theme"

_G.Widgets = {}

---------------------------------------------------------------------------------------------------
-- primitives

-- a plain filled rectangle
function _G.Widgets.Rect(parent, x, y, w, h, color)

    local rect = Turbine.UI.Control()
    rect:SetParent(parent)
    rect:SetPosition(x, y)
    rect:SetSize(w, h)
    rect:SetMouseVisible(false)
    if color ~= nil then
        rect:SetBackColor(color)
    end

    return rect

end

-- a 1px-bordered box: a border rect with the fill inset inside it
function _G.Widgets.Box(parent, x, y, w, h, fill, border)

    local box = {}

    box.border = _G.Widgets.Rect(parent, x, y, w, h, border)
    box.fill   = _G.Widgets.Rect(parent, x + 1, y + 1, w - 2, h - 2, fill)

    function box:SetColors(fillColor, borderColor)
        self.fill:SetBackColor(fillColor)
        self.border:SetBackColor(borderColor)
    end

    function box:SetVisible(value)
        self.border:SetVisible(value)
        self.fill:SetVisible(value)
    end

    return box

end

function _G.Widgets.Label(parent, x, y, w, h, text, font, color, align)

    local label = Turbine.UI.Label()
    label:SetParent(parent)
    label:SetPosition(x, y)
    label:SetSize(w, h)
    label:SetText(text)
    label:SetFont(font or _G.Theme.font.body)
    label:SetForeColor(color or _G.Theme.color.text)
    label:SetFontStyle(Turbine.UI.FontStyle.Outline)
    label:SetTextAlignment(align or Turbine.UI.ContentAlignment.MiddleLeft)
    label:SetMouseVisible(false)

    return label

end

-- help text sits directly under the control it explains, at that control's left edge
function _G.Widgets.Help(parent, x, y, w, text)

    return _G.Widgets.Label(
        parent, x, y, w, 14, text,
        _G.Theme.font.help, _G.Theme.color.textQuiet,
        Turbine.UI.ContentAlignment.TopLeft
    )

end

-- a section divider that fades out at both ends. Turbine can't gradient a 1px line, so it's three
-- segments at 30% / 100% / 30% alpha
function _G.Widgets.Divider(parent, x, y, w)

    local c = _G.Theme.color.line
    local faded = Turbine.UI.Color(0.3, c.R, c.G, c.B)
    local fade = 30

    local left = _G.Widgets.Rect(parent, x, y, fade, 1, faded)
    left:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)

    _G.Widgets.Rect(parent, x + fade, y, w - (fade * 2), 1, c)

    local right = _G.Widgets.Rect(parent, x + w - fade, y, fade, 1, faded)
    right:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)

end

---------------------------------------------------------------------------------------------------
-- checkbox

function _G.Widgets.Checkbox(parent, x, y, text, checked, onChange)

    local w = {}
    w.checked = checked and true or false
    w.enabled = true

    w.control = Turbine.UI.Control()
    w.control:SetParent(parent)
    w.control:SetPosition(x, y)
    w.control:SetSize(320, 18)
    w.control:SetMouseVisible(true)

    w.box = _G.Widgets.Box(w.control, 0, 1, 16, 16, _G.Theme.color.lineQuiet, _G.Theme.color.lineStrong)

    -- an image, not a glyph: the game's fonts have no checkmark and draw U+2713 as a "?". the tga
    -- is 32x32, so it's sized up, told to stretch, then sized down to the 12px it's drawn at.
    w.tick = Turbine.UI.Control()
    w.tick:SetParent(w.control)
    w.tick:SetPosition(2, 3)
    w.tick:SetSize(32, 32)
    w.tick:SetBackground(_G.Theme.image.check)
    w.tick:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    w.tick:SetStretchMode(1)
    w.tick:SetSize(12, 12)
    w.tick:SetMouseVisible(false)
    w.tick:SetVisible(false)

    w.label = _G.Widgets.Label(
        w.control, 25, 0, 295, 18, text,
        _G.Theme.font.body, _G.Theme.color.text
    )

    function w:Refresh()

        if self.checked then
            self.box:SetColors(_G.Theme.color.accentTint, _G.Theme.color.accent)
        else
            self.box:SetColors(_G.Theme.color.lineQuiet, _G.Theme.color.lineStrong)
        end

        self.tick:SetVisible(self.checked)

        self.label:SetForeColor(self.enabled and _G.Theme.color.text or _G.Theme.color.textQuiet)

    end

    function w:IsChecked() return self.checked end

    function w:SetChecked(value)
        self.checked = value and true or false
        self:Refresh()
    end

    function w:SetEnabled(value)
        self.enabled = value and true or false
        self:Refresh()
    end

    w.control.MouseClick = function(sender, args)
        if not w.enabled then return end
        w:SetChecked(not w.checked)
        if onChange then onChange(w.checked) end
    end

    w:Refresh()

    return w

end

---------------------------------------------------------------------------------------------------
-- stepper
--
-- replaces every free-text number box: click to step, hold to repeat, clamped to a sane range so
-- there's no more typing anything into a box

function _G.Widgets.Stepper(parent, x, y, opts)

    local w = {}
    w.value   = opts.value or 0
    w.min     = opts.min or 0
    w.max     = opts.max or 999
    w.step    = opts.step or 1
    w.unit    = opts.unit or ""
    w.enabled = true

    local buttonW = 20
    local valueW  = opts.width or 42
    local height  = 20

    w.control = Turbine.UI.Control()
    w.control:SetParent(parent)
    w.control:SetPosition(x, y)
    w.control:SetSize((buttonW * 2) + valueW, height)

    w.width = (buttonW * 2) + valueW

    local function makeButton(bx, glyph, delta)

        local box = _G.Widgets.Box(w.control, bx, 0, buttonW, height, _G.Theme.color.card, _G.Theme.color.line)

        local hit = Turbine.UI.Control()
        hit:SetParent(w.control)
        hit:SetPosition(bx, 0)
        hit:SetSize(buttonW, height)
        hit:SetMouseVisible(true)

        local label = _G.Widgets.Label(
            w.control, bx, 0, buttonW, height, glyph,
            _G.Theme.font.control, _G.Theme.color.dismissGlyph,
            Turbine.UI.ContentAlignment.MiddleCenter
        )

        hit.MouseDown = function(sender, args)
            if not w.enabled then return end
            w:Step(delta)
            w.holding = delta
            w.holdStart = Turbine.Engine.GetGameTime()
            w.nextRepeat = w.holdStart + 0.4
            w.control:SetWantsUpdates(true)
        end

        local stop = function(sender, args)
            w.holding = nil
            w.control:SetWantsUpdates(false)
        end
        hit.MouseUp = stop
        hit.MouseLeave = stop

        return box, label

    end

    w.minusBox, w.minusLabel = makeButton(0, _G.Theme.glyph.minus, -1)

    w.valueBox = _G.Widgets.Box(w.control, buttonW, 0, valueW, height, _G.Theme.color.well, _G.Theme.color.line)
    w.valueLabel = _G.Widgets.Label(
        w.control, buttonW, 0, valueW, height, "",
        _G.Theme.font.control, _G.Theme.color.text,
        Turbine.UI.ContentAlignment.MiddleCenter
    )

    w.plusBox, w.plusLabel = makeButton(buttonW + valueW, _G.Theme.glyph.plus, 1)

    -- holding a button repeats after a short delay
    w.control.Update = function(sender, args)

        if w.holding == nil then
            w.control:SetWantsUpdates(false)
            return
        end

        local now = Turbine.Engine.GetGameTime()
        if now >= w.nextRepeat then
            w:Step(w.holding)
            w.nextRepeat = now + 0.08
        end

    end

    function w:Refresh()

        self.valueLabel:SetText(tostring(self.value) .. self.unit)

        local textColor = self.enabled and _G.Theme.color.text or _G.Theme.color.textQuiet
        local glyphColor = self.enabled and _G.Theme.color.dismissGlyph or _G.Theme.color.textFaint
        self.valueLabel:SetForeColor(textColor)
        self.minusLabel:SetForeColor(glyphColor)
        self.plusLabel:SetForeColor(glyphColor)

    end

    function w:Step(delta)

        local next = self.value + (delta * self.step)
        if next < self.min then next = self.min end
        if next > self.max then next = self.max end

        if next ~= self.value then
            self.value = next
            self:Refresh()
            if opts.onChange then opts.onChange(self.value) end
        end

    end

    function w:GetValue() return self.value end

    function w:SetValue(value)
        self.value = math.max(self.min, math.min(self.max, value or self.min))
        self:Refresh()
    end

    function w:SetEnabled(value)
        self.enabled = value and true or false
        self:Refresh()
    end

    w:Refresh()

    return w

end

---------------------------------------------------------------------------------------------------
-- segmented control

function _G.Widgets.Segmented(parent, x, y, options, selected, onChange)

    local w = {}
    w.selected = selected or 1
    w.segments = {}

    local height = 22
    local padding = 12

    w.control = Turbine.UI.Control()
    w.control:SetParent(parent)
    w.control:SetPosition(x, y)

    -- Turbine can't measure text, so segments are sized from their character count
    local cursor = 1
    for i, option in ipairs(options) do

        local segWidth = (string.len(option) * 7) + (padding * 2)

        local seg = {}
        seg.fill = _G.Widgets.Rect(w.control, cursor, 1, segWidth, height - 2, _G.Theme.color.card)
        seg.label = _G.Widgets.Label(
            w.control, cursor, 0, segWidth, height, option,
            _G.Theme.font.control, _G.Theme.color.textMuted,
            Turbine.UI.ContentAlignment.MiddleCenter
        )

        seg.hit = Turbine.UI.Control()
        seg.hit:SetParent(w.control)
        seg.hit:SetPosition(cursor, 0)
        seg.hit:SetSize(segWidth, height)
        seg.hit:SetMouseVisible(true)

        local index = i
        seg.hit.MouseClick = function(sender, args)
            if not w.enabled then return end
            w:SetSelected(index)
            if onChange then onChange(index) end
        end

        w.segments[i] = seg
        cursor = cursor + segWidth

    end

    w.width = cursor + 1
    w.control:SetSize(w.width, height)
    w.enabled = true

    -- one box around the whole group
    w.frameTop    = _G.Widgets.Rect(w.control, 0, 0, w.width, 1, _G.Theme.color.lineStrong)
    w.frameBottom = _G.Widgets.Rect(w.control, 0, height - 1, w.width, 1, _G.Theme.color.lineStrong)
    w.frameLeft   = _G.Widgets.Rect(w.control, 0, 0, 1, height, _G.Theme.color.lineStrong)
    w.frameRight  = _G.Widgets.Rect(w.control, w.width - 1, 0, 1, height, _G.Theme.color.lineStrong)

    function w:Refresh()

        for i, seg in ipairs(self.segments) do
            if i == self.selected then
                seg.fill:SetBackColor(_G.Theme.color.accentTint)
                seg.label:SetForeColor(self.enabled and _G.Theme.color.accentText or _G.Theme.color.textQuiet)
            else
                seg.fill:SetBackColor(_G.Theme.color.card)
                seg.label:SetForeColor(self.enabled and _G.Theme.color.textMuted or _G.Theme.color.textFaint)
            end
        end

    end

    function w:GetSelected() return self.selected end

    function w:SetSelected(index)
        self.selected = index
        self:Refresh()
    end

    function w:SetEnabled(value)
        self.enabled = value and true or false
        self:Refresh()
    end

    w:Refresh()

    return w

end

---------------------------------------------------------------------------------------------------
-- key cap

-- maxWidth stops a long binding — an unmapped code formats as its raw number — from growing the
-- cap into whatever sits to its right
function _G.Widgets.KeyCap(parent, x, y, text, maxWidth)

    local w = {}

    text = text or ""
    w.maxWidth = maxWidth

    local height = 26

    w.control = Turbine.UI.Control()
    w.control:SetParent(parent)
    w.control:SetPosition(x, y)

    w.box = _G.Widgets.Box(w.control, 0, 0, 30, height, _G.Theme.color.lineQuiet, _G.Theme.color.lineStrong)

    -- a 2px inset along the bottom so it reads as a key rather than a box
    w.lip = _G.Widgets.Rect(w.control, 1, height - 3, 28, 2, _G.Theme.color.well)

    w.label = _G.Widgets.Label(
        w.control, 0, 0, 30, height - 2, text,
        _G.Theme.font.keyCap, _G.Theme.color.accentText,
        Turbine.UI.ContentAlignment.MiddleCenter
    )

    function w:SetText(value)

        value = value or ""

        local width = math.max(30, (string.len(value) * 8) + 18)

        if self.maxWidth ~= nil and width > self.maxWidth then
            width = self.maxWidth
        end

        self.control:SetSize(width, height)
        self.box.border:SetSize(width, height)
        self.box.fill:SetSize(width - 2, height - 2)
        self.lip:SetSize(width - 2, 2)
        self.label:SetSize(width, height - 2)
        self.label:SetText(value)
        self.width = width

    end

    function w:SetAccent(value)
        self.box:SetColors(
            _G.Theme.color.lineQuiet,
            value and _G.Theme.color.accent or _G.Theme.color.lineStrong
        )
        self.label:SetForeColor(value and _G.Theme.color.accentLight or _G.Theme.color.accentText)
    end

    w:SetText(text)

    return w

end

---------------------------------------------------------------------------------------------------
-- color swatch

function _G.Widgets.Swatch(parent, x, y, color, selected, onClick)

    local w = {}

    w.control = Turbine.UI.Control()
    w.control:SetParent(parent)
    w.control:SetPosition(x - 3, y - 3)
    w.control:SetSize(26, 26)
    w.control:SetMouseVisible(true)

    -- selection ring: a 26 accent square, a 24 ground square, then the 20 swatch
    w.ring   = _G.Widgets.Rect(w.control, 0, 0, 26, 26, _G.Theme.color.accent)
    w.gap    = _G.Widgets.Rect(w.control, 1, 1, 24, 24, _G.Theme.color.ground)
    w.swatch = _G.Widgets.Rect(w.control, 3, 3, 20, 20, color)

    w.control.MouseClick = function(sender, args)
        if onClick then onClick() end
    end

    function w:SetSelected(value)
        self.ring:SetVisible(value)
        self.gap:SetVisible(value)
    end

    function w:SetColor(value)
        self.swatch:SetBackColor(value)
    end

    w:SetSelected(selected)

    return w

end

-- the "+" that ends each swatch row and opens the exact 0-255 boxes
function _G.Widgets.SwatchAdd(parent, x, y, onClick)

    local w = {}

    w.control = Turbine.UI.Control()
    w.control:SetParent(parent)
    w.control:SetPosition(x, y)
    w.control:SetSize(20, 20)
    w.control:SetMouseVisible(true)

    w.box = _G.Widgets.Box(w.control, 0, 0, 20, 20, _G.Theme.color.ground, _G.Theme.color.lineStrong)
    w.label = _G.Widgets.Label(
        w.control, 0, 0, 20, 20, _G.Theme.glyph.plus,
        _G.Theme.font.control, _G.Theme.color.textMuted,
        Turbine.UI.ContentAlignment.MiddleCenter
    )

    w.control.MouseClick = function(sender, args)
        if onClick then onClick() end
    end

    return w

end

---------------------------------------------------------------------------------------------------
-- button
--
-- never a filled button: 1px accent border, accent text, transparent back

function _G.Widgets.Button(parent, x, y, text, onClick, quiet)

    local w = {}

    local height = 26
    local width = (string.len(text) * 7) + 36

    w.control = Turbine.UI.Control()
    w.control:SetParent(parent)
    w.control:SetPosition(x, y)
    w.control:SetSize(width, height)
    w.control:SetMouseVisible(true)
    w.width = width

    if not quiet then
        w.top    = _G.Widgets.Rect(w.control, 0, 0, width, 1, _G.Theme.color.accent)
        w.bottom = _G.Widgets.Rect(w.control, 0, height - 1, width, 1, _G.Theme.color.accent)
        w.left   = _G.Widgets.Rect(w.control, 0, 0, 1, height, _G.Theme.color.accent)
        w.right  = _G.Widgets.Rect(w.control, width - 1, 0, 1, height, _G.Theme.color.accent)
    end

    w.label = _G.Widgets.Label(
        w.control, 0, 0, width, height, text,
        _G.Theme.font.body,
        quiet and _G.Theme.color.textQuiet or _G.Theme.color.accentLight,
        Turbine.UI.ContentAlignment.MiddleCenter
    )

    w.control.MouseClick = function(sender, args)
        if onClick then onClick() end
    end

    return w

end

---------------------------------------------------------------------------------------------------
-- data row

function _G.Widgets.RowSeparator(parent, x, y, w, strong)

    return _G.Widgets.Rect(
        parent, x, y, w, 1,
        strong and _G.Theme.color.line or _G.Theme.color.lineQuiet
    )

end

---------------------------------------------------------------------------------------------------
-- preview card
--
-- a static miniature of a tracker card, so a pane can show the result of a setting without the
-- user having to close the panel. it mirrors potatoTooltip's state colors but draws nothing live.

function _G.Widgets.PreviewCard(parent, x, y, width, height, opts)

    local w = {}
    local color = _G.Theme.color

    w.control = Turbine.UI.Control()
    w.control:SetParent(parent)
    w.control:SetPosition(x, y)
    w.control:SetSize(width, height)

    w.fill = _G.Widgets.Rect(w.control, 0, 0, width, height, color.card)

    w.borderTop    = _G.Widgets.Rect(w.control, 0, 0, width, 1, color.line)
    w.borderBottom = _G.Widgets.Rect(w.control, 0, height - 1, width, 1, color.line)
    w.borderLeft   = _G.Widgets.Rect(w.control, 0, 0, 1, height, color.line)
    w.borderRight  = _G.Widgets.Rect(w.control, width - 1, 0, 1, height, color.line)

    w.rail = _G.Widgets.Rect(w.control, 0, 0, 3, height, color.greyRail)

    w.name = _G.Widgets.Label(
        w.control, 12, 5, width - 60, 16, opts.name or "Target",
        _G.Theme.font.control, color.text,
        Turbine.UI.ContentAlignment.TopLeft
    )

    w.type = _G.Widgets.Label(
        w.control, 12, 21, width - 40, 12, opts.type or "NPC",
        _G.Theme.font.typeLine, color.textQuiet,
        Turbine.UI.ContentAlignment.TopLeft
    )

    w.moraleTrack = _G.Widgets.Rect(w.control, 0, height - 11, width, 5, color.barTrack)
    w.moraleFill  = _G.Widgets.Rect(w.control, 0, height - 11, math.floor(width * 0.68), 5, color.green)
    w.ccTrack     = _G.Widgets.Rect(w.control, 0, height - 5, width, 5, color.barTrack)
    w.ccFill      = _G.Widgets.Rect(w.control, 0, height - 5, math.floor(width * 0.55), 5, color.accent)

    -- state: "npc" | "player" | "object" | "target" | "dead"
    function w:SetState(state, showBars)

        local fill    = color.card
        local border  = color.line
        local rail    = color.greyRail
        local nameCol = color.text
        local typeCol = color.textQuiet
        local typeTxt = "NPC"

        if state == "player" then
            rail = color.green
            typeTxt = "FELLOWSHIP"
        elseif state == "object" then
            rail = color.greyRailDim
            nameCol = color.textDim
            typeTxt = "OBJECT"
        elseif state == "target" then
            fill = color.cardTarget
            border = color.accent
            rail = color.accent
            nameCol = color.textBright
            typeCol = color.accentLight
            typeTxt = "NPC" .. _G.Theme.sep .. "YOUR TARGET"
        elseif state == "dead" then
            fill = color.cardDead
            border = color.lineDead
            rail = color.greyRailDim
            nameCol = color.textQuiet
            typeCol = color.textFaint
            typeTxt = "DEFEATED"
        end

        self.fill:SetBackColor(fill)
        self.borderTop:SetBackColor(border)
        self.borderBottom:SetBackColor(border)
        self.borderLeft:SetBackColor(border)
        self.borderRight:SetBackColor(border)
        self.rail:SetBackColor(rail)
        self.rail:SetWidth(state == "target" and 5 or 3)
        self.name:SetForeColor(nameCol)
        self.type:SetForeColor(typeCol)
        self.type:SetText(typeTxt)

        local bars = showBars ~= false
        self.moraleTrack:SetVisible(bars)
        self.moraleFill:SetVisible(bars and state ~= "dead")
        self.ccTrack:SetVisible(bars)
        self.ccFill:SetVisible(bars)

    end

    w:SetState(opts.state or "npc", opts.bars)

    return w

end
