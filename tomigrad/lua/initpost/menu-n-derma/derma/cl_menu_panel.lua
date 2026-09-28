

local PANEL = {}
local curent_panel

hg = hg or {}
hg.UI = hg.UI or {}
hg.UI.C = hg.UI.C or {}
local UI = hg.UI
local C  = UI.C
local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end


DISCORD_URL = "https://discord.gg/tomigrad"
RULES_URL   = "https://docs.google.com/document/d/1lPovV02HmggoEevKwU13l2Wia4chxDjdhegr26C0T4Q/edit?tab=t.klnxxtntjd9o"

local function MenuUnit(num)
    return math.floor(num * math.min(ScrW(), ScrH()) / 1000)
end


local MENU_FONT = "Bahnschrift"
local function CreateMainMenuFonts()
    surface.CreateFont("TomiMenu_Tiny",  { font = MENU_FONT, size = ScreenScale(8),  weight = 200, extended = true })
    surface.CreateFont("TomiMenu_Small", { font = MENU_FONT, size = ScreenScale(20), weight = 200, extended = true })
    surface.CreateFont("ZC_MM_Title",    { font = MENU_FONT, size = ScreenScale(40), weight = 800, antialias = true, extended = true })
    surface.CreateFont("ZC_MM_Item",     { font = MENU_FONT, size = math.max(20, MenuUnit(34)), weight = 600, extended = true })
    surface.CreateFont("ZC_MM_Index",    { font = "Consolas", size = math.max(12, MenuUnit(16)), weight = 500, extended = true })
    surface.CreateFont("ZC_MM_Meta",     { font = MENU_FONT, size = math.max(11, MenuUnit(14)), weight = 500, extended = true })
    surface.CreateFont("ZC_MM_MetaBig",  { font = "Consolas", size = math.max(16, MenuUnit(26)), weight = 700, extended = true })
end
hook.Add("OnScreenSizeChanged", "ZCity_MainMenu_Fonts", CreateMainMenuFonts)
CreateMainMenuFonts()

local MENU_CLOSE_TIME = 0.7
local PAGE_FADE_TIME  = 0.2


local SOUND_MENU_SELECT = "ui/click.wav"
local SOUND_MENU_HOVER  = "ui/hover.wav"


local function BuildRoleChoice(luaMenu, pp)
    local boxW = MenuUnit(420)
    local boxH = MenuUnit(230)

    local box = vgui.Create("DPanel", pp)
    box:SetSize(boxW, boxH)
    box:SetPos(math.floor((pp:GetWide() - boxW) / 2), math.floor((pp:GetTall() - boxH) / 2))
    box.Paint = function(_, w, h)
        surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, C.lineHi)
        UI.Brackets(0, 0, w, h, C.white, MenuUnit(10))
        draw.SimpleText("CHOOSE YOUR ROLE", "ZUI_Caps", MenuUnit(20), MenuUnit(24), C.textDim, 0, 1)
    end

    local function AddChoice(label, sub, role, y)
        local cell = UI.Cell(box, {
            title = label, sub = sub, tall = MenuUnit(64), nodock = true,
            onClick = function()
                luaMenu:Close()
                hg.SelectPlayerRole(nil, role)
            end,
        })
        cell:SetPos(MenuUnit(20), y)
        cell:SetSize(boxW - MenuUnit(40), MenuUnit(64))
    end

    AddChoice("STD", "Standard traitor", "standard", MenuUnit(48))
    AddChoice("SOE", "Special operations", "soe", MenuUnit(122))
end


local Selects = {
    {Title = "Disconnect", Action = true, Func = function(luaMenu) RunConsoleCommand("disconnect") end},
    {Title = "Main Menu", Action = true, Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Achievements", FullScreen = true, Func = function(luaMenu, pp)
        if hg.DrawAchievmentsMenu then
            hg.DrawAchievmentsMenu(pp)
        end
    end},
    {Title = "Rules", Action = true, Func = function(luaMenu) luaMenu:Close() gui.OpenURL(RULES_URL) end},
    {Title = "Settings", FullScreen = true, Func = function(luaMenu, pp) hg.DrawSettings(pp) end},
    {Title = "Clothing", FullScreen = true, Func = function(luaMenu, pp) hg.CreateApperanceMenu(pp) end},
    {Title = "Return", Action = true, Func = function(luaMenu) luaMenu:Close() end},
    {Title = "Loadout",
        GamemodeOnly = true,
        FullScreen = true,
        Func = function(luaMenu, pp)
            hg.DrawLoadoutMenu(pp)
        end
    },
}

local splasheh = {
    'TOMIGRADERSSS',
}

local Pluv = Material("pluv/pluvkid.jpg")
local LogoMat = Material("tomithings/tomilogo.png", "noclamp smooth")

function PANEL:InitializeSplash()
    local mapname = game.GetMap()
    local prefix = string.find(mapname, "_")
    if prefix then
        mapname = string.sub(mapname, prefix + 1)
    end
    self.MapNice = string.NiceName(mapname)
    local gm = splasheh[math.random(#splasheh)] .. " | " .. self.MapNice

    if hg.PluvTown and hg.PluvTown.Active then
        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)
    end

    return gm
end

function PANEL:GetLiveMouse()
    local mx, my = gui.MouseX(), gui.MouseY()
    if mx <= 0 and my <= 0 then
        mx = ScrW() * 0.5
        my = ScrH() * 0.5
    end
    local nx = math.Clamp((mx / ScrW() - 0.5) * 2, -1, 1)
    local ny = math.Clamp((my / ScrH() - 0.5) * 2, -1, 1)
    return mx, my, nx, ny
end

function PANEL:GetLiveOffset(xAmount, yAmount)
    local _, _, nx, ny = self:GetLiveMouse()
    return nx * xAmount, ny * yAmount
end

function PANEL:GetLiveShake(seedX, seedY, xAmount, yAmount)
    local t = RealTime()
    return math.sin(t * 1.8 + seedX) * xAmount, math.cos(t * 2.4 + seedY) * yAmount
end

function PANEL:Think()
    self.LiveLerp = LerpFT(0.08, self.LiveLerp or 0, 1)
    self.LogoHoverLerp = LerpFT(0.12, self.LogoHoverLerp or 0, IsValid(self.logoPanel) and self.logoPanel:IsHovered() and 1 or 0)
end

function PANEL:CreatePageParent(fullscreen)
    if IsValid(self.panelparrent) then
        self.panelparrent:Remove()
    end

    local page = vgui.Create("DPanel", self)
    if fullscreen then
        page:SetPos(0, 0)
        page:SetSize(ScrW(), ScrH())
        page:MoveToFront()
    else
        page:SetPos(self.PageX, 0)
        page:SetSize(self.PageW, ScrH())
        page:MoveToBack()
    end
    page.Paint = function(this, w, h) end
    page.FullScreen = fullscreen and true or false

    self.panelparrent = page
    return page
end

function PANEL:FadeMenu(faded, except)
    self.MenuFaded = faded
    for _, child in ipairs(self:GetChildren()) do
        if child ~= except then
            child:AlphaTo(faded and 0 or 255, PAGE_FADE_TIME, 0)
        end
    end
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:ShowCloseButton(false)
    curent_panel = nil
    self.Splash = self:InitializeSplash()
    self.LiveLerp = 0
    self.LogoHoverLerp = 0
    self.Born = SysTime()

    timer.Simple(0, function()
        if IsValid(self) and self.First then
            self:First()
        end
    end)

    self.IndexW = MenuUnit(430)
    self.PageX = self.IndexW + MenuUnit(20)
    self.PageW = ScrW() - self.PageX

    self.lDock = vgui.Create("DPanel", self)
    local lDock = self.lDock
    lDock:Dock(LEFT)
    lDock:SetWide(self.IndexW)
    lDock:DockPadding(MenuUnit(36), MenuUnit(120), MenuUnit(10), MenuUnit(120))
    lDock.Paint = function(this, w, h)
        surface.SetDrawColor(C.line)
        surface.DrawRect(w - 1, 0, 1, h)
        draw.SimpleText("COMMANDS", "ZUI_Caps", MenuUnit(36), MenuUnit(96), C.textMut, 0, 1)

        if hg.PluvTown and hg.PluvTown.Active then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(self.SelectedPluv or Pluv)
            surface.DrawTexturedRect(w - MenuUnit(70), MenuUnit(20), MenuUnit(50), MenuUnit(38))
        end
    end

    self.Buttons = {}
    for k, v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        self:AddSelect(lDock, v.Title, v)
    end

    local right = vgui.Create("DPanel", self)
    self.rightBlock = right
    right:SetSize(ScrW() - self.IndexW, ScrH() - MenuUnit(150))
    right:SetPos(self.IndexW, MenuUnit(20))
    right:SetMouseInputEnabled(false)
    right.Paint = function() end

    local logoPanel = vgui.Create("DPanel", self)
    local logoAspect = math.max(1, LogoMat:Height()) / math.max(1, LogoMat:Width())
    self.logoPanel = logoPanel
    logoPanel:SetMouseInputEnabled(true)
    logoPanel:SetCursor("hand")
    logoPanel.OnMousePressed = function(this, code)
        if code ~= MOUSE_LEFT then return end
        gui.OpenURL(DISCORD_URL)
    end
    logoPanel.PerformLayout = function(this)
        local w = math.min(MenuUnit(560), ScrW() - self.IndexW - MenuUnit(120))
        this:SetSize(w, w * logoAspect + MenuUnit(64))
        this:SetPos(self.IndexW + (ScrW() - self.IndexW - w) / 2, ScrH() * 0.5 - this:GetTall() * 0.62)
    end
    logoPanel.Paint = function(this, w, h)
        local a = math.Clamp((SysTime() - self.Born) / 0.6, 0, 1)
        local e = 1 - (1 - a) ^ 3
        local scale = 1 + (self.LogoHoverLerp or 0) * 0.035
        local logoH = w * logoAspect
        local dw, dh = w * scale, logoH * scale

        surface.SetDrawColor(255, 255, 255, 255 * e)
        surface.SetMaterial(LogoMat)
        surface.DrawTexturedRect((w - dw) / 2, MenuUnit(6) - (dh - logoH) / 2, dw, dh)

        surface.SetDrawColor(C.line)
        surface.DrawRect(0, logoH + MenuUnit(20), w, 1)
        surface.SetDrawColor(C.white)
        surface.DrawRect(0, logoH + MenuUnit(20), w * 0.12 * e, 1)
        draw.SimpleText(self.Splash or "", "ZC_MM_Meta", 0, logoH + MenuUnit(38), C.textDim, 0, 1)
    end
    logoPanel:InvalidateLayout(true)

    local status = vgui.Create("DPanel", self)
    self.statusCard = status
    local sw_, sh_ = MenuUnit(560), MenuUnit(96)
    status:SetSize(sw_, sh_)
    status:SetPos(ScrW() - sw_ - MenuUnit(48), ScrH() - sh_ - MenuUnit(74))
    status:SetMouseInputEnabled(false)
    status.Paint = function(this, w, h)
        surface.SetDrawColor(C.bg1) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, C.line)
        UI.Brackets(0, 0, w, h, C.lineHi, MenuUnit(8))

        local cols = {
            {"MAP",     self.MapNice or game.GetMap()},
            {"PLAYERS", player.GetCount() .. " / " .. game.MaxPlayers()},
            {"PING",    tostring(IsValid(LocalPlayer()) and LocalPlayer():Ping() or 0) .. " ms"},
            {"TIME",    os.date("%H:%M")},
        }
        local cw = w / #cols
        for i, c in ipairs(cols) do
            local x = (i - 1) * cw + MenuUnit(20)
            if i > 1 then
                surface.SetDrawColor(C.line)
                surface.DrawRect((i - 1) * cw, MenuUnit(16), 1, h - MenuUnit(32))
            end
            draw.SimpleText(c[1], "ZUI_Caps", x, h / 2 - MenuUnit(16), C.textMut, 0, 1)
            local txt = c[2]
            surface.SetFont("ZC_MM_MetaBig")
            while surface.GetTextSize(txt) > cw - MenuUnit(28) and #txt > 3 do
                txt = string.sub(txt, 1, #txt - 2)
            end
            draw.SimpleText(txt, "ZC_MM_MetaBig", x, h / 2 + MenuUnit(12), C.text, 0, 1)
        end
    end


    local bottomDock = vgui.Create("DPanel", self)
    self.bottomDock = bottomDock
    bottomDock:SetPos(MenuUnit(36), ScrH() - MenuUnit(74))
    bottomDock:SetSize(self.IndexW - MenuUnit(50), MenuUnit(56))
    bottomDock:SetMouseInputEnabled(false)
    bottomDock.Paint = function(this, w, h)
        surface.SetDrawColor(C.line) surface.DrawRect(0, 0, w, 1)
        draw.SimpleText("Z-City authors: uzelezz, Sadsalat, Mr.Point, Zac90, Deka, Mannytko", "ZC_MM_Meta", 0, MenuUnit(12), C.textMut, 0, 1)
        draw.SimpleText("Version 1.03   ·   Server author: 71", "ZC_MM_Meta", 0, MenuUnit(32), C.textMut, 0, 1)
    end

    self:CreatePageParent()
end

function PANEL:First(ply)
    self:AlphaTo(255, 0.12, 0, nil)
end


function PANEL:Paint(w, h)
    if hg.DrawBlur then hg.DrawBlur(self, 5) end
    UI.PaintBackdrop(w, h)
    -- soft edge lines
    surface.SetDrawColor(C.line)
    surface.DrawRect(0, MenuUnit(72), w, 1)
    surface.DrawRect(0, h - MenuUnit(84), w, 1)
    draw.SimpleText("Z-CITY  //  MAIN MENU", "ZUI_Caps", MenuUnit(36), MenuUnit(36), C.textDim, 0, 1)
    draw.SimpleText("[ ESC ] close", "ZUI_Caps", w - MenuUnit(36), MenuUnit(36), C.textMut, 2, 1)
end

function PANEL:ResetCurrentPanel()
    curent_panel = nil
    self.MenuFaded = false
end

function PANEL:AddSelect(pParent, strTitle, tbl)
    local id = #self.Buttons + 1
    local lowerTitle = string.lower(strTitle)
    local fullscreen = tbl.FullScreen and true or false
    local luaMenu = self

    local btn = vgui.Create("DButton", pParent)
    self.Buttons[id] = btn
    btn:SetText("")
    btn:SetCursor("hand")
    btn:SetTall(MenuUnit(60))
    btn:Dock(TOP)
    btn:DockMargin(0, 0, 0, MenuUnit(6))
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    btn.Hov, btn.Sel = 0, 0
    btn.Born = SysTime() + id * 0.045

    function btn:DoClick()
        if luaMenu.SwitchingPanel then return end
        surface.PlaySound(SOUND_MENU_SELECT)

        if tbl.Action then
            btn.Func(luaMenu)
            return
        end

        local closing = (curent_panel == lowerTitle)
        if closing then
            curent_panel = nil          
        else
            curent_panel = lowerTitle
        end
        luaMenu.SwitchingPanel = true

        for i = 1, 3 do
            surface.PlaySound(closing and "shitty/tap_release.wav" or "shitty/tap_depress.wav")
        end

        local function swap()
            if not IsValid(luaMenu) then return end
            local openFull = fullscreen and not closing
            local page = luaMenu:CreatePageParent(openFull)
            luaMenu.SwitchingPanel = false

            if openFull then
                luaMenu:FadeMenu(true, page)
            elseif luaMenu.MenuFaded then
                luaMenu:FadeMenu(false, page)
            end

            if not closing then
                page:SetAlpha(0)
                page:AlphaTo(255, PAGE_FADE_TIME, 0)
                btn.Func(luaMenu, page)
            end
        end

        local oldPanel = luaMenu.panelparrent
        if IsValid(oldPanel) and #oldPanel:GetChildren() > 0 then
            oldPanel:AlphaTo(0, PAGE_FADE_TIME, 0, swap)
        else
            swap()
        end
    end

    function btn:OnCursorEntered()
        surface.PlaySound(SOUND_MENU_HOVER)
    end

    function btn:Paint(w, h)
        local a = math.Clamp((SysTime() - self.Born) / 0.3, 0, 1)
        local e = 1 - (1 - a) ^ 3

        local hovered = self:IsHovered()
        local active  = (curent_panel == lowerTitle)
        self.Hov = UI.Smooth(self.Hov, hovered and 1 or 0, 14)
        self.Sel = UI.Smooth(self.Sel, active and 1 or 0, 12)

        local lift = math.max(self.Hov * 0.9, self.Sel)
        local slide = (1 - e) * -MenuUnit(24) + self.Hov * MenuUnit(6)

        local m = Matrix()
        m:Translate(Vector(slide, 0, 0))
        cam.PushModelMatrix(m)

        surface.SetDrawColor(UI.Mix(lift, Color(20, 20, 23, 0), self.Sel > 0.5 and C.bg3 or C.bg2))
        surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, UI.Alpha(C.white, 12 + 55 * lift))

     
        local rail = math.max(self.Sel, self.Hov * 0.6)
        surface.SetDrawColor(C.white)
        surface.DrawRect(0, h * (0.5 - 0.5 * rail), MenuUnit(2), h * rail)

        draw.SimpleText(string.format("%02d", id), "ZC_MM_Index", MenuUnit(20), h / 2, UI.Mix(lift, C.textMut, C.textDim), 0, 1)

 
        draw.SimpleText(string.upper(strTitle), "ZC_MM_Item", MenuUnit(68), h / 2,
            UI.Mix(lift, C.textDim, C.white), 0, 1)

        local marker = tbl.Action and "↵" or (active and "●" or "›")
        draw.SimpleText(marker, "ZC_MM_Item", w - MenuUnit(20), h / 2, UI.Mix(lift, C.textMut, C.white), 2, 1)

        if self.Hov > 0.02 then
            UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 190 * self.Hov), MenuUnit(8))
        end

        cam.PopModelMatrix()
        return true
    end
end

function PANEL:Close()
    self:AlphaTo(0, MENU_CLOSE_TIME, 0, function()
        if IsValid(self) then
            self:Remove()
        end
    end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow", "OpenMainMenu", function()
    local run = hook.Run("OnShowZCityPause")
    if run != nil then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    return false
end)