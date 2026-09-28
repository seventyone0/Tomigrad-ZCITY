local PANEL = {}

local UI = hg.UI
local C = UI.C
local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end

local fallbackBand = { icon = Material("vgui/mats_jack_awards/10") }
local fallbackMedal = { icon = Material("vgui/mats_jack_awards/pt") }

function PANEL:Init()
    self.Player = nil
    self.Band = nil
    self.Medal = nil
    self.ShownXp = 0
    self.Hov = 0
    self.Born = SysTime()
    self.LastExp = -1
    self.LastSkill = -1
end

function PANEL:SetPlayer(ply)
    self.Player = ply
    self:Refresh(true)
end

function PANEL:Refresh(force)
    local ply = self.Player
    if not IsValid(ply) then return end

    local exp = math.floor(tonumber(ply.exp) or 0)
    local skill = math.Round(tonumber(ply.skill) or 0, 3)

    if force or exp ~= self.LastExp or skill ~= self.LastSkill then
        local band, medal
        if ply.GetAwards then band, medal = ply:GetAwards() end
        self.Band = band or fallbackBand
        self.Medal = medal or fallbackMedal
        self.LastExp, self.LastSkill = exp, skill
    end
end

function PANEL:Think()
    self:Refresh(false)
end

function PANEL:Paint(w, h)
    self.Hov = UI.Smooth(self.Hov, self:IsHovered() and 1 or 0, 10)
    local a = math.Clamp((SysTime() - self.Born) / 0.4, 0, 1)
    local e = 1 - (1 - a) ^ 3

    surface.SetDrawColor(UI.Mix(self.Hov, C.bg1, C.bg2))
    surface.DrawRect(0, 0, w, h)
    UI.Outline(0, 0, w, h, UI.Mix(self.Hov, C.line, C.lineHi))
    UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 90 + 110 * self.Hov), U(8))

    local ply = self.Player
    if not IsValid(ply) then return end

    draw.SimpleText("OPERATIVE", "ZUI_Caps", U(18), U(22), C.textMut, 0, 1)

    local name = string.upper(ply:Nick())
    surface.SetFont("ZUI_Head")
    local maxW = w - U(36)
    local nw = surface.GetTextSize(name)
    while nw > maxW and #name > 3 do
        name = string.sub(name, 1, #name - 1)
        nw = surface.GetTextSize(name .. "…")
    end
    if name ~= string.upper(ply:Nick()) then name = name .. "…" end
    draw.SimpleText(name, "ZUI_Head", U(18), U(46), UI.Alpha(C.white, 255 * e), 0, 1)

    surface.SetDrawColor(C.line) surface.DrawRect(U(18), U(64), w - U(36), 1)
    surface.SetDrawColor(C.white) surface.DrawRect(U(18), U(64), (w - U(36)) * 0.12 * e, 1)

    local footH = U(96)
    local areaY = U(78)
    local areaH = h - areaY - footH - U(8)
    local side = math.max(0, math.min(w - U(36), areaH))
    local mx = (w - side) / 2
    local my = areaY + (areaH - side) / 2

    surface.SetDrawColor(C.bg0) surface.DrawRect(mx, my, side, side)
    UI.Outline(mx, my, side, side, C.line)

    local pad = U(8)
    if self.Band and self.Band.icon then
        surface.SetMaterial(self.Band.icon)
        surface.SetDrawColor(255, 255, 255, 255 * e)
        surface.DrawTexturedRect(mx + pad, my + pad, side - pad * 2, side - pad * 2)
    end
    if self.Medal and self.Medal.icon then
        surface.SetMaterial(self.Medal.icon)
        surface.SetDrawColor(255, 255, 255, 255 * e)
        surface.DrawTexturedRect(mx + pad, my + pad, side - pad * 2, side - pad * 2)
    end

    local exp = math.floor(tonumber(ply.exp) or 0)
    local skill = math.Round(tonumber(ply.skill) or 0, 3)
    self.ShownXp = UI.Smooth(self.ShownXp, exp, 8)

    local fy = h - footH
    surface.SetDrawColor(C.line) surface.DrawRect(U(18), fy, w - U(36), 1)

    draw.SimpleText("EXPERIENCE", "ZUI_Caps", U(18), fy + U(20), C.textMut, 0, 1)
    draw.SimpleText(tostring(math.Round(self.ShownXp)) .. " XP", "ZUI_MonoBig", U(18), fy + U(46), C.white, 0, 1)
    draw.SimpleText("SKILL  " .. skill, "ZUI_Small", U(18), fy + U(74), C.textDim, 0, 1)

    local medalName = self.Medal and self.Medal.name and self.Medal.name ~= "" and string.upper(self.Medal.name) or nil
    if medalName then
        draw.SimpleText(medalName, "ZUI_Caps", w - U(18), fy + U(74), C.textDim, 2, 1)
    end
end

vgui.Register("ZB_ExpPanel", PANEL, "DPanel")
