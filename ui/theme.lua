
-- Theme
--
-- design tokens for the Nocturne redesign — see docs/redesign/HANDOFF.md
--
-- - colors   the palette, pre-built as Turbine.UI.Color
-- - fonts    design sizes resolved to fonts the game actually ships
-- - metrics  the two card presets and shared control sizes
--
-- everything the ui files draw reads its colors and sizes from here, so a token
-- changes in one place instead of three
---------------------------------------------------------------------------------------------------

import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.Theme = {}

local Color = Turbine.UI.Color

-- the separator the design uses between a label and its suffix (NPC · YOUR TARGET).
-- UTF-8 U+00B7; kept in one place in case the game's font renders it badly.
_G.Theme.sep = " \194\183 "

-- glyphs, together so a font that renders one of them badly is a one-line fix. only characters the
-- game's fonts actually carry belong here: anything outside Latin-1 draws as a "?", which is why
-- the checkbox tick is an image rather than U+2713.
_G.Theme.glyph = {
    minus = "-",
    plus  = "+",
    close = "x",
}

-- 32x32 32-bit TGAs, drawn at the size the control wants via SetStretchMode. the colour is baked
-- in, since SetBackColor fills the control behind a background image rather than tinting it.
_G.Theme.image = {
    check = "Potato/check.tga",  -- accentPale #d2cefd on transparent
}

---------------------------------------------------------------------------------------------------
-- colors
--
-- hex values are the design's; the floats are what Turbine takes

_G.Theme.color = {

    -- surfaces
    ground      = Color(0.086, 0.094, 0.149),  -- #161826  panel background
    card        = Color(0.110, 0.118, 0.169),  -- #1c1e2b  card fill, at rest
    cardHover   = Color(0.129, 0.141, 0.192),  -- #212431  card fill on mouse over
    cardTarget  = Color(0.165, 0.153, 0.251),  -- #2a2740  card fill when it's your target
    cardDead    = Color(0.098, 0.102, 0.125),  -- #191a20  card fill when defeated
    cardWarn    = Color(0.141, 0.110, 0.133),  -- #241c22  card fill when CC is breaking
    surface     = Color(0.137, 0.145, 0.196),  -- #232532  selected tab, raised rows
    surfaceSunk = Color(0.071, 0.078, 0.122),  -- #12141f  tab rail background
    well        = Color(0.063, 0.071, 0.110),  -- #10121c  stepper value box, icon slot
    barTrack    = Color(0.059, 0.063, 0.094),  -- #0f1018  empty part of any bar

    -- lines
    line        = Color(0.247, 0.259, 0.302),  -- #3f424d  1px borders
    lineQuiet   = Color(0.129, 0.137, 0.184),  -- #21232f  row separators
    lineDead    = Color(0.161, 0.169, 0.192),  -- #292b31  border of a defeated card
    lineStrong  = Color(0.349, 0.365, 0.424),  -- #595d6c  checkbox / key-cap border

    -- text
    text        = Color(0.914, 0.914, 0.929),  -- #e9e9ed  names, labels
    textBright  = Color(0.961, 0.957, 1.000),  -- #f5f4ff  name on a targeted card
    textDim     = Color(0.698, 0.714, 0.792),  -- #b2b6ca  object names, body copy
    textMuted   = Color(0.576, 0.592, 0.671),  -- #9397ab  secondary labels
    textQuiet   = Color(0.459, 0.475, 0.549),  -- #75798c  type line, help text
    textFaint   = Color(0.349, 0.365, 0.424),  -- #595d6c  defeated type line

    -- accent — target state and the CC bar
    accent      = Color(0.569, 0.518, 0.851),  -- #9184d9
    accentLight = Color(0.710, 0.671, 0.988),  -- #b5abfc  accent text, CC bar on target fill
    accentPale  = Color(0.824, 0.808, 0.992),  -- #d2cefd  CC seconds number
    accentTint  = Color(0.259, 0.227, 0.416),  -- #423a6a  checked checkbox, active segment
    accentPanel = Color(0.169, 0.153, 0.255),  -- #2b2741  drained CC fill (direction 1b only)
    accentText  = Color(0.906, 0.898, 0.996),  -- #e7e5fe  active tab / key cap text

    -- morale
    green       = Color(0.294, 0.561, 0.369),  -- #4b8f5e  player rail, morale bar
    greenLight  = Color(0.561, 0.749, 0.620),  -- #8fbf9e  morale percentage text

    -- the only red in the system — CC breaking and low morale
    red         = Color(0.851, 0.518, 0.561),  -- #d9848f
    redLight    = Color(0.933, 0.725, 0.757),  -- #eeb9c1  CC breaking number
    redLine     = Color(0.427, 0.271, 0.314),  -- #6d4550  border of a breaking card
    redText     = Color(0.878, 0.639, 0.678),  -- #e0a3ad  "BREAKING" label

    -- rails
    greyRail    = Color(0.459, 0.475, 0.549),  -- #75798c  NPC rail
    greyRailDim = Color(0.247, 0.259, 0.302),  -- #3f424d  object rail, defeated rail

    -- LotRO header band, kept from the current build
    goldBand    = Color(0.220, 0.161, 0.051),  -- #38290d
    goldText    = Color(0.902, 0.749, 0.349),  -- #e6bf59

    -- hover dismiss column. translucent so the card reads through it — the alpha rides on the
    -- fill only, so the glyph over it stays crisp
    dismiss      = Color(0.88, 0.169, 0.184, 0.239), -- #2b2f3d at 88%  column back
    dismissGlyph = Color(0.812, 0.827, 0.898),       -- #cfd3e5         the "x", also DRAG

    -- alternate swatches offered in the Appearance pane
    swatchTeal  = Color(0.239, 0.498, 0.588),  -- #3d7f96
    swatchBrass = Color(0.561, 0.478, 0.294),  -- #8f7a4b
    swatchPale  = Color(0.894, 0.906, 0.961),  -- #e4e7f5
    swatchInk   = Color(0.031, 0.035, 0.055),  -- #08090e  near-black card background

}

---------------------------------------------------------------------------------------------------
-- fonts
--
-- the design calls for Verdana 9.5, 11 and 15, which the game does not ship. every design size is
-- resolved to the nearest font that exists, once, here — so nothing downstream has to know which
-- sizes are real. Resolve() also survives an enum member being missing at runtime, since the
-- available set can only be confirmed in-game.

local function Resolve(...)

    local names = { ... }

    for i = 1, #names do
        local font = Turbine.UI.Lotro.Font[ names[i] ]
        if font ~= nil then
            return font
        end
    end

    return Turbine.UI.Lotro.Font.Verdana12

end

_G.Theme.font = {

    -- tracker card
    name         = Resolve("Verdana16"),               -- design 16, comfortable
    nameCompact  = Resolve("Verdana14"),               -- design 14, compact
    typeLine     = Resolve("Verdana10"),               -- design 9.5
    ccSeconds    = Resolve("Verdana14", "Verdana16"),  -- design 15
    ccSuffix     = Resolve("Verdana10"),               -- design 10, the trailing "s"
    moralePct    = Resolve("Verdana12"),               -- design 12
    dismiss      = Resolve("Verdana13", "Verdana12"),  -- design 13, the "x" glyph
    dragHandle   = Resolve("Verdana10"),               -- design 8

    -- options panel
    title        = Resolve("Verdana16"),               -- design 16, pane titles
    band         = Resolve("Verdana13", "Verdana12"),  -- design 13, the gold brand band
    body         = Resolve("Verdana13", "Verdana12"),  -- design 13, labels and checkbox text
    control      = Resolve("Verdana12"),               -- design 12, steppers and segments
    keyCap       = Resolve("Verdana13", "Verdana12"),  -- design 13
    columnHead   = Resolve("Verdana10"),               -- design 10, uppercase table headers
    help         = Resolve("Verdana10"),               -- design 11, kept quieter than body

}

---------------------------------------------------------------------------------------------------
-- metrics
--
-- both card presets are a fixed height regardless of what is showing: the name and type line
-- occupy the top 40px and the bars live in the bottom 12px that used to be dead space. turning
-- morale on must never move the HUD.

_G.Theme.preset = {

    comfortable = {
        width       = 260,
        height      = 52,
        nameFont    = _G.Theme.font.name,
        nameLeft    = 14,
        nameTop     = 7,
        nameHeight  = 20,
        typeLine    = true,
        typeTop     = 30,
        typeHeight  = 12,
        strikeTop   = 20,
        ccTop       = 26,   -- the seconds, right-aligned
        ccHeight    = 16,
        moraleTop   = 28,   -- the percentage, right-aligned, when no CC is running
        moraleHeight = 12,
        barHeight   = 5,    -- when both bars show
        soloBar     = 6,    -- when only one does
    },

    compact = {
        width       = 200,
        height      = 30,
        nameFont    = _G.Theme.font.nameCompact,
        nameLeft    = 11,
        nameTop     = 5,
        nameHeight  = 18,
        typeLine    = false,
        typeTop     = nil,
        typeHeight  = 0,
        strikeTop   = 17,
        ccTop       = 4,
        ccHeight    = 16,
        moraleTop   = 6,
        moraleHeight = 12,
        barHeight   = 3,
        soloBar     = 3,
    },

}

_G.Theme.metrics = {

    railWidth       = 3,   -- thickens to 5 when the card is your target
    railTargetWidth = 5,
    borderWidth     = 1,   -- 2 when the card is your target
    borderTarget    = 2,
    dismissWidth    = 22,  -- hover-only column on the right
    cardGap         = 2,   -- was 5
    barGap          = 1,   -- between the morale and CC bars

    dragHandleWidth  = 40,
    dragHandleHeight = 10,

    -- options panel
    panelWidth   = 600,
    panelHeight  = 470,
    tabRailWidth = 150,
    tabHeight    = 34,
    paneFootHeight = 50,

}

---------------------------------------------------------------------------------------------------
-- helpers

-- the card metrics in force, resolved from Settings.size_preset. "custom" keeps the comfortable
-- preset's typography and takes its dimensions from the user's own width / height / spacing.
-- both the card and the window that stacks them size themselves from this.
function _G.Theme.CardMetrics()

    local base = _G.Theme.preset[ _G.Settings.size_preset ]
    local m = {}

    if base == nil then

        -- custom
        for key, value in pairs(_G.Theme.preset.comfortable) do m[key] = value end

        m.width  = _G.Settings.width
        m.height = _G.Settings.tooltip_height
        m.gap    = _G.Settings.tooltip_spacing

        -- a short card has no room for a type line under the name
        if m.height < 44 then
            m.typeLine = false
            m.nameFont = _G.Theme.font.nameCompact
            m.nameLeft = 11
            m.nameTop  = 5
            m.ccTop    = 4
            m.moraleTop = 6
        end

        -- keep the bars proportionate on a very short card
        if m.height < 30 then
            m.barHeight = 3
            m.soloBar   = 3
        end

    else

        for key, value in pairs(base) do m[key] = value end
        m.gap = _G.Theme.metrics.cardGap

    end

    -- the type line can also be switched off outright
    if _G.Settings.show_type_line == false then
        m.typeLine = false
    end

    return m

end

---------------------------------------------------------------------------------------------------
-- card colors
--
-- the card's fill is a user setting (Appearance ▸ Card background), and every other fill the card
-- can take — hover, target, defeated, CC breaking — is a step away from it. rather than ask the
-- user to pick five colors, they pick the one and the rest are derived here.
--
-- while the setting is still the design's own #1c1e2b the derived values are bypassed and the
-- handoff tokens are returned verbatim, so the default look stays pixel-exact.

local White = Color(1, 1, 1)
local Black = Color(0, 0, 0)

-- t of the way from a to b
function _G.Theme.Mix(a, b, t)

    return Color(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )

end

-- perceived brightness, 0-1 — decides whether the card is carrying light or dark text
function _G.Theme.Luminance(color)

    return (color.R * 0.3) + (color.G * 0.59) + (color.B * 0.11)

end

local function Same(a, b)

    return math.abs(a.R - b.R) < 0.005
       and math.abs(a.G - b.G) < 0.005
       and math.abs(a.B - b.B) < 0.005

end

local function SettingColor(t, fallback)

    if t == nil then return fallback end

    return Color(t.r, t.g, t.b)

end

-- the card's fill at rest, as the user has set it
function _G.Theme.BaseColor()

    return SettingColor(_G.Settings and _G.Settings.color_card, _G.Theme.color.card)

end

-- the frame and rail color of a targeted card
function _G.Theme.TargetColor()

    return SettingColor(_G.Settings and _G.Settings.color_targeted, _G.Theme.color.accent)

end

-- state = "rest" | "hover" | "target" | "dead" | "warn"
function _G.Theme.CardFill(state)

    local color = _G.Theme.color
    local base  = _G.Theme.BaseColor()
    local stock = Same(base, color.card)

    if state == "hover" then

        if stock then return color.cardHover end

        -- lifting a light card by lightening it further has nowhere to go, so hover moves whichever
        -- way the card has room
        if _G.Theme.IsLightCard() then
            return _G.Theme.Mix(base, Black, 0.05)
        end

        return _G.Theme.Mix(base, White, 0.022)

    elseif state == "target" then

        local target = _G.Theme.TargetColor()
        if stock and Same(target, color.accent) then return color.cardTarget end
        return _G.Theme.Mix(base, target, 0.13)

    elseif state == "dead" then

        if stock then return color.cardDead end

        -- half the colour drained out, then darkened a shade
        local lum = _G.Theme.Luminance(base)
        return _G.Theme.Mix(_G.Theme.Mix(base, Color(lum, lum, lum), 0.5), Black, 0.15)

    elseif state == "warn" then

        if stock then return color.cardWarn end
        return _G.Theme.Mix(base, color.redLine, 0.22)

    end

    return base

end

-- the card's border at rest, and the quieter one a defeated card takes
function _G.Theme.BorderColor(state)

    local color = _G.Theme.color
    local base  = _G.Theme.BaseColor()

    if Same(base, color.card) then
        if state == "dead"  then return color.lineDead   end
        if state == "hover" then return color.lineStrong end
        return color.line
    end

    -- a light card needs a darker frame than a dark one, so the border is a step further from the
    -- fill in whichever direction has room
    local away = _G.Theme.IsLightCard() and Black or White

    if state == "dead" then
        return _G.Theme.Mix(_G.Theme.CardFill("dead"), away, 0.12)
    elseif state == "hover" then
        return _G.Theme.Mix(base, away, 0.32)
    end

    return _G.Theme.Mix(base, away, 0.2)

end

-- the empty part of a bar. always darker than the card it sits on, so a drained bar reads as empty
function _G.Theme.TrackColor(isTarget)

    local color = _G.Theme.color
    local base  = _G.Theme.BaseColor()

    if Same(base, color.card) then
        return isTarget and color.ground or color.barTrack
    end

    -- a light card can't sink a track by darkening a near-black one, so the amount scales with how
    -- much room there is below the fill
    local depth = _G.Theme.IsLightCard() and 0.65 or 0.4

    return _G.Theme.Mix(base, Black, isTarget and (depth - 0.1) or depth)

end

-- true while the card background is light enough that the design's light text would disappear
function _G.Theme.IsLightCard()

    return _G.Theme.Luminance(_G.Theme.BaseColor()) > 0.5

end

-- any text or glyph drawn on the card passes through here. on the default dark card it is the
-- identity; on a light one each token is re-lit to the brightness it would need on that card,
-- keeping its hue and its place in the hierarchy — the CC seconds stay violet, a low morale figure
-- stays red, and the quiet type line stays quieter than the name.
function _G.Theme.Ink(color)

    if not _G.Theme.IsLightCard() then
        return color
    end

    local lum = _G.Theme.Luminance(color)
    if lum < 0.02 then return color end

    -- the brightest tokens end up the darkest, since those are the ones carrying the most weight
    local scale = (0.85 - (lum * 0.75)) / lum

    local function channel(value)
        value = value * scale
        if value > 1 then return 1 end
        return value
    end

    return Color(channel(color.R), channel(color.G), channel(color.B))

end

-- a "#rrggbb" string for a token, for use in label markup — Turbine labels take one ForeColor,
-- so inline two-tone text (BLINDING FLASH · 68%) has to go through markup
function _G.Theme.Markup(color)

    return string.format(
        "#%02x%02x%02x",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )

end

-- the rail color for an entity type, matching potatoWindow's duck-typed codes
-- 1 = player / fellowship, 2 = object / item, anything else = NPC
function _G.Theme.RailColor(entityType)

    local s = _G.Settings

    if entityType == 1 then
        return SettingColor(s and s.color_player, _G.Theme.color.green)
    elseif entityType == 2 then
        return SettingColor(s and s.color_item, _G.Theme.color.greyRailDim)
    end

    return SettingColor(s and s.color_npc, _G.Theme.color.greyRail)

end

-- the name color for an entity type — objects read one step quieter than the rest
function _G.Theme.NameColor(entityType)

    if entityType == 2 then
        return _G.Theme.Ink(_G.Theme.color.textDim)
    end

    return _G.Theme.Ink(_G.Theme.color.text)

end

-- the type line's text for an entity type
function _G.Theme.TypeName(entityType)

    if entityType == 1 then
        return "FELLOWSHIP"
    elseif entityType == 2 then
        return "OBJECT"
    end

    return "NPC"

end
