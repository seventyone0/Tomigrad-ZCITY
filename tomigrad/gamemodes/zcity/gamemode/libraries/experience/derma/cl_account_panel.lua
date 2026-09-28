local PANEL = {}

local UI = hg.UI
local C = UI.C
local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end

local Statics = {
    {"Kills", "Kills"},
    {"Suicides", "Suicides"},
    {"Deaths", "Deaths"},
}

local function StatCard(parent, label)
    local p = vgui.Create("DPanel", parent)
    p.Label, p.Value, p.Shown, p.Target = label, "0", 0, 0
    p.Hov = 0
    p.Paint = function(s, w, h)
        s.Hov = UI.Smooth(s.Hov, s:IsHovered() and 1 or 0, 12)
        s.Shown = UI.Smooth(s.Shown, s.Target, 10)
        surface.SetDrawColor(UI.Mix(s.Hov, C.bg1, C.bg2)) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, UI.Mix(s.Hov, C.line, C.lineHi))
        UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 60 + 140 * s.Hov), U(6))
        draw.SimpleText(string.upper(s.Label), "ZUI_Caps", U(16), U(18), C.textDim, 0, 1)
        draw.SimpleText(tostring(math.Round(s.Shown)), "ZUI_MonoBig", U(16), h - U(24), C.white, 0, 1)
    end
    return p
end

function PANEL:Init()
    self:SetSize(math.max(U(760), ScrW() / 2), math.max(U(520), ScrH() * 0.6))
    self:Center()
    self:SetColorBG(C.bg0)
    self:SetBorder(true)

    self.Cards = {}
    self.Born = SysTime()

    self.Head = vgui.Create("DPanel", self)
    self.Head:Dock(TOP)
    self.Head:SetTall(U(74))
    self.Head.Name = ""
    self.Head.Paint = function(s, w, h)
        local a = math.Clamp((SysTime() - self.Born) / 0.35, 0, 1)
        local e = 1 - (1 - a) ^ 3
        surface.SetDrawColor(C.line) surface.DrawRect(U(20), h - 1, w - U(40), 1)
        surface.SetDrawColor(C.white) surface.DrawRect(U(20), h - 1, (w - U(40)) * e * 0.08, 1)
        draw.SimpleText("ACCOUNT", "ZUI_Caps", U(24), U(22), C.textMut, 0, 1)
        draw.SimpleText(string.upper(s.Name), "ZUI_Title", U(24), U(46), UI.Alpha(C.white, 255 * e), 0, 1)
    end

    self.CloseBtn = UI.Button(self.Head, "Close", function() self:Close() end)
    self.CloseBtn:Dock(RIGHT)
    self.CloseBtn:SetWide(U(96))
    self.CloseBtn:DockMargin(0, U(16), U(20), U(16))

    self.Foot = vgui.Create("DPanel", self)
    self.Foot:Dock(BOTTOM)
    self.Foot:SetTall(U(32))
    self.Foot.Paint = function(_, w, h)
        surface.SetDrawColor(C.line) surface.DrawRect(U(20), 0, w - U(40), 1)
        draw.SimpleText("Z-CITY", "ZUI_Caps", w - U(24), h / 2, C.textMut, 2, 1)
    end

    self.Body = vgui.Create("DPanel", self)
    self.Body:Dock(FILL)
    self.Body:DockMargin(U(20), U(14), U(20), U(8))
    self.Body.Paint = function() end

    self.MainInfo = vgui.Create("ZB_ExpPanel", self.Body)
    self.MainInfo:Dock(LEFT)
    self.MainInfo:SetWide(self:GetWide() * 0.34)
    self.MainInfo:DockMargin(0, 0, U(18), 0)

    self.Divider = vgui.Create("DPanel", self.Body)
    self.Divider:Dock(LEFT)
    self.Divider:SetWide(1)
    self.Divider:DockMargin(0, 0, U(18), 0)
    self.Divider.Paint = function(_, w, h) surface.SetDrawColor(C.line) surface.DrawRect(0, 0, w, h) end

    self.StatPanel = vgui.Create("DScrollPanel", self.Body)
    self.StatPanel:Dock(FILL)
    self.StatPanel.Paint = function() end
    UI.StyleScroll(self.StatPanel)

    self.StatLabel = UI.SectionLabel(self.StatPanel, "Statistics")

    self.Grid = vgui.Create("DPanel", self.StatPanel)
    self.Grid:Dock(TOP)
    self.Grid:DockMargin(0, 0, U(8), 0)
    self.Grid.Paint = function() end
    self.Grid.PerformLayout = function(s, w, h)
        local gap = U(8)
        local cols = w < U(360) and 1 or 2
        local cw = math.floor((w - gap * (cols - 1)) / cols)
        local ch = U(84)
        for i, card in ipairs(self.Cards) do
            local r, c = math.floor((i - 1) / cols), (i - 1) % cols
            card:SetPos(c * (cw + gap), r * (ch + gap))
            card:SetSize(cw, ch)
        end
        local rows = math.ceil(#self.Cards / cols)
        s:SetTall(rows * ch + math.max(0, rows - 1) * gap)
    end
end

function PANEL:EnsureCards()
    if #self.Cards > 0 then return end
    for i, stats in ipairs(Statics) do
        self.Cards[i] = StatCard(self.Grid, stats[1])
    end
    self.Grid:InvalidateLayout(true)
end

function PANEL:SetPlayer(ply)
    self.Ply = ply
    self.MainInfo:SetPlayer(ply)
    self.Head.Name = ply:Nick()

    self:EnsureCards()
    for i, stats in ipairs(Statics) do
        self.Cards[i].Target = tonumber(ply:GetStatVal(stats[2], 0)) or 0
    end
end

function PANEL:Udpate(ply)
    self:EnsureCards()
    for i, stats in ipairs(Statics) do
        self.Cards[i].Target = tonumber(ply.SvDB and ply.SvDB[stats[2]] or 0) or 0
    end
end

function PANEL:Update(ply)
    self:Udpate(ply)
end

function PANEL:Paint(w, h)
    if hg.DrawBlur then hg.DrawBlur(self, 5) end
    surface.SetDrawColor(C.bg0)
    surface.DrawRect(0, 0, w, h)
    local step = U(28)
    surface.SetDrawColor(255, 255, 255, 4)
    for x = 0, w, step do surface.DrawRect(x, 0, 1, h) end
    for y = 0, h, step do surface.DrawRect(0, y, w, 1) end
    UI.Outline(0, 0, w, h, C.lineHi)
    UI.Brackets(0, 0, w, h, C.lineMax, U(10))
end

vgui.Register("ZB_AccountFrame", PANEL, "ZFrame")
