hg = hg or {}
hg.UI = hg.UI or {}
local UI = hg.UI

if not LerpFT then
    function LerpFT(frac, a, b)
        return Lerp(1 - math.exp(-frac * 60 * RealFrameTime()), a, b)
    end
end
UI.C = UI.C or {}
for k, v in pairs({
    bg0     = Color(14, 14, 16, 250),   
    bg1     = Color(20, 20, 23, 255),   
    bg2     = Color(28, 28, 32, 255),   
    bg3     = Color(38, 38, 43, 255),  
    line    = Color(255, 255, 255, 22),
    lineHi  = Color(255, 255, 255, 70),
    lineMax = Color(255, 255, 255, 170),
    text    = Color(226, 226, 228),
    textDim = Color(132, 132, 138),
    textMut = Color(84, 84, 90),
    white   = Color(255, 255, 255),
    black   = Color(0, 0, 0),
    warn    = Color(214, 168, 96),      
    bad     = Color(206, 96, 96),       
    good    = Color(150, 196, 160),     
    scrim   = Color(0, 0, 0, 175),
}) do UI.C[k] = v end
local C = UI.C

function UI.U(n)
    return math.floor(n * math.min(ScrW(), ScrH()) / 1000)
end
local U = UI.U

local FONT_BASE = "Bahnschrift"
local function MakeFonts()
    surface.CreateFont("ZUI_Display", { font = FONT_BASE, size = math.max(26, U(44)), weight = 700, extended = true })
    surface.CreateFont("ZUI_Title",   { font = FONT_BASE, size = math.max(18, U(26)), weight = 700, extended = true })
    surface.CreateFont("ZUI_Head",    { font = FONT_BASE, size = math.max(15, U(20)), weight = 600, extended = true })
    surface.CreateFont("ZUI_Body",    { font = FONT_BASE, size = math.max(13, U(17)), weight = 500, extended = true })
    surface.CreateFont("ZUI_Small",   { font = FONT_BASE, size = math.max(11, U(14)), weight = 500, extended = true })
    surface.CreateFont("ZUI_Caps",    { font = FONT_BASE, size = math.max(10, U(12)), weight = 700, extended = true })
    surface.CreateFont("ZUI_Mono",    { font = "Consolas", size = math.max(12, U(15)), weight = 500, extended = true })
    surface.CreateFont("ZUI_MonoBig", { font = "Consolas", size = math.max(18, U(30)), weight = 700, extended = true })
end
MakeFonts()
hook.Add("OnScreenSizeChanged", "ZUI_Fonts", MakeFonts)

function UI.Alpha(c, a) return Color(c.r, c.g, c.b, a) end

function UI.Mix(t, a, b)
    return Color(
        Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b),
        Lerp(t, a.a or 255, b.a or 255)
    )
end

function UI.Smooth(cur, target, speed)
    return Lerp(math.min(1, RealFrameTime() * speed), cur, target)
end

function UI.SndHover() surface.PlaySound("ui/buttonrollover.wav") end
function UI.SndClick() surface.PlaySound("ui/buttonclickrelease.wav") end
function UI.SndDeny()  surface.PlaySound("buttons/button10.wav") end
function UI.SndOk()    surface.PlaySound("buttons/button14.wav") end


function UI.Outline(x, y, w, h, col, t)
    surface.SetDrawColor(col)
    surface.DrawOutlinedRect(x, y, w, h, t or 1)
end


function UI.Brackets(x, y, w, h, col, len, t)
    len, t = len or U(8), t or 1
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, len, t)               surface.DrawRect(x, y, t, len)
    surface.DrawRect(x + w - len, y, len, t)     surface.DrawRect(x + w - t, y, t, len)
    surface.DrawRect(x, y + h - t, len, t)       surface.DrawRect(x, y + h - len, t, len)
    surface.DrawRect(x + w - len, y + h - t, len, t)  surface.DrawRect(x + w - t, y + h - len, t, len)
end

local mat_grad_d = Material("vgui/gradient-d")
local mat_grad_u = Material("vgui/gradient-u")
local scanY = 0

function UI.PaintBackdrop(w, h, strength)
    strength = strength or 1
    surface.SetDrawColor(C.bg0)
    surface.DrawRect(0, 0, w, h)

    local step = U(28)
    surface.SetDrawColor(255, 255, 255, 5 * strength)
    for x = 0, w, step do surface.DrawRect(x, 0, 1, h) end
    for y = 0, h, step do surface.DrawRect(0, y, w, 1) end

    surface.SetDrawColor(0, 0, 0, 90)
    surface.SetMaterial(mat_grad_d)
    surface.DrawTexturedRect(0, h * 0.55, w, h * 0.45)
    surface.SetMaterial(mat_grad_u)
    surface.DrawTexturedRect(0, 0, w, h * 0.25)

    scanY = (scanY + RealFrameTime() * U(60)) % (h + U(80))
    surface.SetDrawColor(255, 255, 255, 5 * strength)
    surface.DrawRect(0, scanY - U(40), w, U(40))
end




function UI.StyleScroll(scroll)
    local vbar = scroll:GetVBar()
    vbar:SetWide(U(5))
    vbar:SetHideButtons(true)
    vbar.Paint = function(_, w, h)
        surface.SetDrawColor(255, 255, 255, 8)
        surface.DrawRect(w / 2 - 1, 0, 2, h)
    end
    vbar.btnGrip.Paint = function(s, w, h)
        surface.SetDrawColor(s:IsHovered() and C.lineMax or C.lineHi)
        surface.DrawRect(w / 2 - 1, 0, 3, h)
    end
    return scroll
end


function UI.SectionLabel(parent, text)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(U(34))
    p:DockMargin(0, U(6), 0, U(2))
    p.Paint = function(_, w, h)
        local up = string.upper(text)
        draw.SimpleText(up, "ZUI_Caps", 0, h / 2, C.textDim, 0, 1)
        surface.SetFont("ZUI_Caps")
        local tw = surface.GetTextSize(up)
        surface.SetDrawColor(C.line)
        surface.DrawRect(tw + U(12), h / 2, w - tw - U(12), 1)
    end
    return p
end


function UI.Cell(parent, opts)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetCursor("hand")
    if not opts.nodock then
        b:Dock(TOP)
        b:DockMargin(opts.indent or 0, 0, 0, U(4))
    end
    b:SetTall(opts.tall or U(50))
    b.Hov, b.Sel = 0, 0
    if opts.tip and opts.tip ~= "" then b:SetTooltip(opts.tip) end

    function b:OnCursorEntered()
        if not (opts.disabled and opts.disabled()) then UI.SndHover() end
        if opts.onHover then opts.onHover() end
    end
    function b:DoClick()
        if opts.disabled and opts.disabled() then UI.SndDeny() return end
        UI.SndClick()
        if opts.onClick then opts.onClick(self) end
    end
    function b:Paint(w, h)
        local on  = opts.selected and opts.selected() or false
        local dis = opts.disabled and opts.disabled() or false
        self.Hov = UI.Smooth(self.Hov, (self:IsHovered() and not dis) and 1 or 0, 14)
        self.Sel = UI.Smooth(self.Sel, on and 1 or 0, 12)

        local lift = math.max(self.Hov * 0.8, self.Sel)
        surface.SetDrawColor(UI.Mix(lift, C.bg1, on and C.bg3 or C.bg2))
        surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, UI.Mix(math.max(self.Hov, self.Sel), C.line, C.lineHi))

        local rail = math.max(self.Sel, self.Hov * 0.55)
        surface.SetDrawColor(C.white)
        surface.DrawRect(0, h * (0.5 - 0.5 * rail), U(2), h * rail)

        local tx = U(16)
        local col = dis and C.textMut or UI.Mix(math.max(self.Hov, self.Sel), C.textDim, C.white)
        if opts.sub then
            draw.SimpleText(opts.title, "ZUI_Body", tx, h / 2 - U(8), col, 0, 1)
            draw.SimpleText(opts.sub, "ZUI_Small", tx, h / 2 + U(11), dis and C.textMut or C.textDim, 0, 1)
        else
            draw.SimpleText(opts.title, "ZUI_Body", tx, h / 2, col, 0, 1)
        end
        if opts.right then
            local r = isfunction(opts.right) and opts.right() or opts.right
            draw.SimpleText(r, "ZUI_Mono", w - U(14), h / 2, dis and C.textMut or C.text, 2, 1)
        end
        if self.Hov > 0.02 and not dis then
            UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 200 * self.Hov), U(7))
        end
        if dis then
            surface.SetDrawColor(0, 0, 0, 120)
            surface.DrawRect(0, 0, w, h)
        end
    end
    return b
end


function UI.Button(parent, label, onClick, style)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetCursor("hand")
    b.Label, b.Style, b.Hov = label, style or "ghost", 0
    function b:DoClick() UI.SndClick() if onClick then onClick(self) end end
    function b:OnCursorEntered() UI.SndHover() end
    function b:Paint(w, h)
        self.Hov = UI.Smooth(self.Hov, self:IsHovered() and 1 or 0, 14)
        if self.Style == "solid" then
            surface.SetDrawColor(UI.Mix(self.Hov, C.text, C.white)) surface.DrawRect(0, 0, w, h)
            draw.SimpleText(self.Label, "ZUI_Body", w / 2, h / 2, C.black, 1, 1)
        elseif self.Style == "danger" then
            surface.SetDrawColor(UI.Mix(self.Hov, C.bg1, UI.Alpha(C.bad, 40))) surface.DrawRect(0, 0, w, h)
            UI.Outline(0, 0, w, h, UI.Mix(self.Hov, C.line, C.bad))
            draw.SimpleText(self.Label, "ZUI_Body", w / 2, h / 2, UI.Mix(self.Hov, C.textDim, C.bad), 1, 1)
        else
            surface.SetDrawColor(UI.Mix(self.Hov, C.bg1, C.bg2)) surface.DrawRect(0, 0, w, h)
            UI.Outline(0, 0, w, h, UI.Mix(self.Hov, C.line, C.lineMax))
            draw.SimpleText(self.Label, "ZUI_Body", w / 2, h / 2, UI.Mix(self.Hov, C.text, C.white), 1, 1)
        end
        if self.Hov > 0.02 and self.Style ~= "solid" then
            UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 180 * self.Hov), U(6))
        end
    end
    return b
end

function UI.TextEntry(parent, font)
    local e = vgui.Create("DTextEntry", parent)
    e:SetFont(font or "ZUI_Mono")
    e:SetUpdateOnType(true)
    e.Foc = 0
    e.Paint = function(s, w, h)
        s.Foc = UI.Smooth(s.Foc, s:HasFocus() and 1 or 0, 12)
        surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, UI.Mix(s.Foc, C.line, C.lineMax))
        s:DrawTextEntryText(C.text, C.white, C.white)
    end
    return e
end


function UI.Switch(parent, getState, onToggle)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetCursor("hand")
    b.T = getState() and 1 or 0
    b.Hov = 0
    function b:DoClick() UI.SndClick() onToggle(not getState()) end
    function b:Paint(w, h)
        local on = getState()
        self.T = UI.Smooth(self.T, on and 1 or 0, 14)
        self.Hov = UI.Smooth(self.Hov, self:IsHovered() and 1 or 0, 14)
        surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, UI.Mix(math.max(self.T, self.Hov), C.line, C.lineMax))
        local kw = w * 0.5 - U(3)
        surface.SetDrawColor(UI.Mix(self.T, C.textMut, C.white))
        surface.DrawRect(U(2) + (w - kw - U(4)) * self.T, U(2), kw, h - U(4))
        draw.SimpleText(on and "ON" or "OFF", "ZUI_Caps",
            on and w * 0.25 or w * 0.75, h / 2, on and C.textDim or C.textMut, 1, 1)
    end
    return b
end


function UI.Slider(parent, get, set, min, max, decimals)
    local s = vgui.Create("DButton", parent)
    s:SetText("")
    s:SetCursor("sizewe")
    s.Drag, s.Hov = false, 0
    local function fracOf() return math.Clamp((get() - min) / math.max(0.0001, max - min), 0, 1) end
    s.Frac = fracOf()

    function s:OnMousePressed(m)
        if m ~= MOUSE_LEFT then return end
        self.Drag = true
        self:MouseCapture(true)
        self:OnCursorMoved(self:CursorPos())
    end
    function s:OnMouseReleased(m)
        if m ~= MOUSE_LEFT then return end
        self.Drag = false
        self:MouseCapture(false)
    end
    function s:OnCursorMoved(x)
        if not self.Drag then return end
        local f = math.Clamp(x / self:GetWide(), 0, 1)
        local v = min + f * (max - min)
        v = (decimals and decimals > 0) and math.Round(v, decimals) or math.Round(v)
        self.Frac = f
        set(v)
    end
    function s:Paint(w, h)
        if not self.Drag then self.Frac = UI.Smooth(self.Frac, fracOf(), 16) end
        self.Hov = UI.Smooth(self.Hov, (self:IsHovered() or self.Drag) and 1 or 0, 14)
        local ty = h / 2
        surface.SetDrawColor(255, 255, 255, 18) surface.DrawRect(0, ty - 1, w, 2)
        surface.SetDrawColor(UI.Mix(self.Hov, C.textDim, C.white)) surface.DrawRect(0, ty - 1, w * self.Frac, 2)
        local kx = math.Clamp(w * self.Frac - U(3), 0, w - U(6))
        surface.SetDrawColor(C.white) surface.DrawRect(kx, ty - U(7), U(6), U(14))
        surface.SetDrawColor(255, 255, 255, 25)
        for i = 0, 10 do surface.DrawRect(math.floor(i * (w - 1) / 10), h - U(5), 1, U(4)) end
    end
    return s
end


function UI.Window(parent, o)
    o = o or {}
    local win = vgui.Create("DPanel", parent)
    win:SetSize(parent:GetWide(), parent:GetTall())
    win:SetPos(0, 0)
    win:SetAlpha(0)
    win:AlphaTo(255, 0.18, 0)
    win.ActiveTab = o.tabs and o.tabs[1] and o.tabs[1].id or nil
    win.Title, win.Hint = o.title or "", o.hint or ""
    win.Born = SysTime()

    win.Paint = function(s, w, h)
        if hg.DrawBlur then hg.DrawBlur(s, 5) end
        UI.PaintBackdrop(w, h)
    end

    local pad   = U(28)
    local topH  = U(88)
    local footH = U(34)


    local top = vgui.Create("DPanel", win)
    top:Dock(TOP)
    top:SetTall(topH)
    top.Paint = function(_, w, h)
        local a = math.Clamp((SysTime() - win.Born) / 0.35, 0, 1)
        local e = 1 - (1 - a) ^ 3

        surface.SetDrawColor(C.line) surface.DrawRect(0, h - 1, w, 1)
        surface.SetDrawColor(C.white) surface.DrawRect(0, h - 1, w * e * 0.06, 1)

        if o.index then
            draw.SimpleText(o.index, "ZUI_Mono", pad, h / 2 - U(2), C.textMut, 0, 1)
        end
        local ix = o.index and (pad + U(34)) or pad
        draw.SimpleText(win.Title, "ZUI_Title", ix, h / 2 - U(9), UI.Alpha(C.white, 255 * e), 0, 1)
        draw.SimpleText(win.Hint, "ZUI_Small", ix, h / 2 + U(16), C.textDim, 0, 1)
    end

    local back = UI.Button(top, "Back", function() if o.onBack then o.onBack() end end)
    back:Dock(RIGHT)
    back:SetWide(U(100))
    back:DockMargin(0, U(26), pad, U(26))
    win.BackButton = back


    win.TabButtons = {}
    if o.tabs then
        local tabsHolder = vgui.Create("DPanel", top)
        tabsHolder:Dock(RIGHT)
        tabsHolder.Paint = function() end
        win.TabsHolder = tabsHolder

        local totalW = 0
        for i, t in ipairs(o.tabs) do
            local tb = vgui.Create("DButton", tabsHolder)
            tb:SetText("")
            tb:SetCursor("hand")
            tb.Hov, tb.Sel = 0, 0
            tb.Id, tb.Label, tb.Idx = t.id, t.label, string.format("%02d", i)
            surface.SetFont("ZUI_Head")
            local tw = surface.GetTextSize(t.label)
            tb:SetWide(tw + U(44))
            tb:Dock(LEFT)
            totalW = totalW + tb:GetWide()
            function tb:DoClick()
                if win.ActiveTab == self.Id then return end
                UI.SndClick()
                win:SetTab(self.Id)
            end
            function tb:OnCursorEntered() UI.SndHover() end
            function tb:Paint(w, h)
                local on = win.ActiveTab == self.Id
                self.Hov = UI.Smooth(self.Hov, self:IsHovered() and 1 or 0, 14)
                self.Sel = UI.Smooth(self.Sel, on and 1 or 0, 12)
                draw.SimpleText(self.Idx, "ZUI_Caps", w / 2, h / 2 - U(14), UI.Mix(self.Sel, C.textMut, C.textDim), 1, 1)
                draw.SimpleText(self.Label, "ZUI_Head", w / 2, h / 2 + U(4),
                    UI.Mix(math.max(self.Sel, self.Hov), C.textDim, C.white), 1, 1)
                local uw = (w - U(24)) * self.Sel
                surface.SetDrawColor(C.white)
                surface.DrawRect((w - uw) / 2, h - U(6), uw, 2)
            end
            win.TabButtons[t.id] = tb
        end
        tabsHolder:SetWide(totalW)
        tabsHolder:DockMargin(0, 0, U(14), 0)
    end

    function win:SetTab(id)
        self.ActiveTab = id
        if o.onTab then o.onTab(id) end
    end
    function win:SetTitle(t) self.Title = t end
    function win:SetHint(t)  self.Hint = t end


    local foot = vgui.Create("DPanel", win)
    foot:Dock(BOTTOM)
    foot:SetTall(footH)
    foot.Paint = function(_, w, h)
        surface.SetDrawColor(C.line) surface.DrawRect(0, 0, w, 1)
        local x = pad
        for _, hnt in ipairs(o.footer or {}) do
            local key, label = string.match(hnt, "^(%S+)%s+(.+)$")
            if key then
                surface.SetFont("ZUI_Caps")
                local kw = surface.GetTextSize(key)
                UI.Outline(x, h / 2 - U(9), kw + U(12), U(18), C.lineHi)
                draw.SimpleText(key, "ZUI_Caps", x + U(6), h / 2, C.text, 0, 1)
                draw.SimpleText(label, "ZUI_Small", x + kw + U(20), h / 2, C.textDim, 0, 1)
                surface.SetFont("ZUI_Small")
                x = x + kw + U(20) + surface.GetTextSize(label) + U(22)
            end
        end
        draw.SimpleText("Z-CITY", "ZUI_Caps", w - pad, h / 2, C.textMut, 2, 1)
    end


    local body = vgui.Create("DPanel", win)
    body:Dock(FILL)
    body:DockMargin(pad, U(18), pad, U(14))
    body.Paint = function() end
    win.Body = body

    return win
end


function UI.CloseToMenu(page)
    if not IsValid(page) then return end
    local luaMenu = page:GetParent()
    page:AlphaTo(0, 0.18, 0, function() if IsValid(page) then page:Remove() end end)
    if not IsValid(luaMenu) then return end
    for _, child in ipairs(luaMenu:GetChildren()) do
        if child ~= page then
            child:SetVisible(true)
            child:AlphaTo(255, 0.2, 0)
        end
    end
    if luaMenu.panelparrent then
        luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
        luaMenu.panelparrent:SetPos(0, 0)
        luaMenu.panelparrent:SetSize(ScrW(), ScrH())
        luaMenu.panelparrent:MoveToFront()
        luaMenu.panelparrent:SetMouseInputEnabled(false)
        luaMenu.panelparrent.Paint = function() end
    end
    if luaMenu.ResetCurrentPanel then luaMenu:ResetCurrentPanel() end
end

function UI.Modal(parent, title, message, buttons)
    local ov = vgui.Create("DButton", parent)
    ov:SetText("")
    ov:SetSize(parent:GetWide(), parent:GetTall())
    ov:SetPos(0, 0)
    ov:MakePopup()
    ov:SetAlpha(0)
    ov:AlphaTo(255, 0.12, 0)
    ov.Paint = function(_, w, h) surface.SetDrawColor(C.scrim) surface.DrawRect(0, 0, w, h) end

    local bw, bh = U(500), U(210)
    local box = vgui.Create("DPanel", ov)
    box:SetSize(bw, bh)
    box:Center()
    box.Paint = function(_, w, h)
        surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, C.lineHi)
        UI.Brackets(0, 0, w, h, C.white, U(10))
        draw.SimpleText(string.upper(title), "ZUI_Head", U(24), U(34), C.white, 0, 1)
        draw.SimpleText(message, "ZUI_Small", U(24), U(64), C.textDim, 0, 1)
    end

    function ov:Dismiss(cb)
        self:AlphaTo(0, 0.1, 0, function()
            if IsValid(self) then self:Remove() end
            if cb then cb() end
        end)
    end

    local n = #buttons
    local gap = U(10)
    local bwid = (bw - U(48) - gap * (n - 1)) / n
    for i, b in ipairs(buttons) do
        local btn = UI.Button(box, b.label, function() ov:Dismiss(b.fn) end, b.style)
        btn:SetPos(U(24) + (i - 1) * (bwid + gap), bh - U(64))
        btn:SetSize(bwid, U(42))
    end
    return ov
end


local PANEL = {}

local ENTER_TIME = 0.4
local EXIT_TIME  = 0.22

function PANEL:Init()
    self.Itensens = {}
    self:SetAlpha(0)
    self:SetTitle("")

    self.DrawBorder  = true
    self.ColorBG     = Color(C.bg0.r, C.bg0.g, C.bg0.b, C.bg0.a)
    self.ColorBR     = Color(255, 255, 255, 40)
    self.BlurStrengh = 2

    timer.Simple(0, function()
        if IsValid(self) and self.First then
            self:First()
        end
    end)
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(self.ColorBG)
    surface.DrawRect(0, 0, w, h)
    if hg.DrawBlur then hg.DrawBlur(self, self.BlurStrengh) end

    if self.DrawBorder then
        UI.Outline(0, 0, w, h, self.ColorBR)
        UI.Brackets(0, 0, w, h, C.lineMax, U(10))
    end
end

function PANEL:SetBorder(bDraw)         self.DrawBorder = bDraw end
function PANEL:SetColorBG(cColor)       self.ColorBG = cColor end
function PANEL:SetColorBR(cColor)       self.ColorBR = cColor end
function PANEL:SetBlurStrengh(floatVal) self.BlurStrengh = floatVal end

function PANEL:First(ply)
    local x, y = self:GetPos()
    self:SetPos(x, y + U(22))
    self:MoveTo(x, y, ENTER_TIME, 0, 0.3)
    self:AlphaTo(255, ENTER_TIME * 0.7, 0)
    if self.PostInit then self:PostInit() end
end

function PANEL:Close()
    if self.Closing then return end
    self.Closing = true

    local x, y = self:GetPos()
    self:MoveTo(x, y + U(22), EXIT_TIME, 0, 2)
    self:AlphaTo(0, EXIT_TIME, 0, function()
        if not IsValid(self) then return end
        if self.OnClose then self:OnClose() end
        self:Remove()
    end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZFrame", PANEL, "DFrame")