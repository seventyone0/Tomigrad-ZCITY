hg.achievements = hg.achievements or {}
hg.achievements.achievements_data = hg.achievements.achievements_data or {}
hg.achievements.achievements_data.player_achievements = hg.achievements.achievements_data.player_achievements or {}
hg.achievements.achievements_data.created_achevements = hg.achievements.achievements_data.created_achevements or {}

hg.achievements.MenuPanel = hg.achievements.MenuPanel or nil

concommand.Add("hg_achievements", function()
    print('use esc menu')
end)

hg = hg or {}
hg.UI = hg.UI or {}
hg.UI.C = hg.UI.C or {}
local UI = hg.UI
local C  = UI.C
local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end

local curent_panel_ach

local function GetProgress(ach)
    local local_ach = hg.achievements.GetLocalAchievements() or {}
    local val = (local_ach[ach.key] and local_ach[ach.key].value) or ach.start_value or 0
    local need = ach.needed_value or 1
    return val, need, math.Clamp(val / math.max(need, 1), 0, 1)
end

local function IsComplete(ach)
    local val, need = GetProgress(ach)
    return val >= need
end

function hg.DrawAchievmentsMenu(ParentPanel)
    hg.achievements.LoadAchievements()

    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:Remove()
        hg.achievements.MenuPanel = nil
    end
    if not IsValid(ParentPanel) then return end

    ParentPanel:SetAlpha(0)
    ParentPanel.Paint = function(self, w, h)
        if hg.DrawBlur then hg.DrawBlur(self, 5) end
        UI.PaintBackdrop(w, h)
    end
    ParentPanel:AlphaTo(255, 0.15, 0)

    local pad = U(20)
    local root = vgui.Create("DPanel", ParentPanel)
    root:SetPos(pad, pad)
    root:SetSize(ParentPanel:GetWide() - pad * 2, ParentPanel:GetTall() - pad * 2)
    root.Paint = function() end
    hg.achievements.MenuPanel = root

    local head = vgui.Create("DPanel", root)
    head:Dock(TOP)
    head:SetTall(U(56))
    head.Paint = function(_, w, h)
        draw.SimpleText("ACHIEVEMENTS", "ZUI_Title", 0, h / 2 - U(9), C.white, 0, 1)

        local total, done = 0, 0
        for _, ach in pairs(hg.achievements.achievements_data.created_achevements) do
            total = total + 1
            if IsComplete(ach) then done = done + 1 end
        end
        draw.SimpleText(done .. " / " .. total .. " unlocked", "ZUI_Small", 0, h / 2 + U(16), C.textDim, 0, 1)
        surface.SetDrawColor(C.line) surface.DrawRect(0, h - 1, w, 1)
    end

    local body = vgui.Create("DPanel", root)
    body:Dock(FILL)
    body:DockMargin(0, U(14), 0, 0)
    body.Paint = function() end

    local detail = vgui.Create("DPanel", body)
    detail:Dock(RIGHT)
    detail:SetWide(U(300))
    detail:DockMargin(U(16), 0, 0, 0)
    detail.Fade = 0
    detail.Paint = function(s, w, h)
        surface.SetDrawColor(C.bg1) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, C.lineHi)
        UI.Brackets(0, 0, w, h, C.lineHi, U(10))

        local ach = curent_panel_ach
        s.Fade = UI.Smooth(s.Fade, ach and 1 or 0, 8)
        if not ach then
            draw.SimpleText("SELECT AN\nACHIEVEMENT", "ZUI_Caps", w / 2, h / 2, C.textMut, 1, 1)
            return
        end

        local complete = IsComplete(ach)
        local val, need, frac = GetProgress(ach)

        local iw = w - U(40)
        local ih = U(140)
        surface.SetDrawColor(C.bg0) surface.DrawRect(U(20), U(20), iw, ih)
        UI.Outline(U(20), U(20), iw, ih, C.line)
        if ach.img then
            local mat = isstring(ach.img) and Material(ach.img) or ach.img
            surface.SetDrawColor(255, 255, 255, 80 + 175 * s.Fade)
            surface.SetMaterial(mat)
            local sz = math.min(iw, ih) - U(24)
            surface.DrawTexturedRect(U(20) + (iw - sz) / 2, U(20) + (ih - sz) / 2, sz, sz)
        end
        if complete then
            draw.SimpleText("UNLOCKED", "ZUI_Caps", U(28), U(28), C.good, 0, 0)
        end

        local ty = U(20) + ih + U(22)
        draw.SimpleText(ach.name or "", "ZUI_Head", U(20), ty, UI.Alpha(C.white, 255 * s.Fade), 0, 1)
        ty = ty + U(30)

        surface.SetDrawColor(C.line) surface.DrawRect(U(20), ty, w - U(40), 1)
        ty = ty + U(14)

        surface.SetFont("ZUI_Small")
        local desc = (ach.description or ""):gsub("\\n", "\n")
        for _, line in ipairs(string.Explode("\n", desc)) do
            local words, cur = string.Explode(" ", line), ""
            local maxw = w - U(40)
            local out = {}
            for _, word in ipairs(words) do
                local test = cur == "" and word or (cur .. " " .. word)
                if surface.GetTextSize(test) > maxw and cur ~= "" then
                    table.insert(out, cur); cur = word
                else
                    cur = test
                end
            end
            if cur ~= "" then table.insert(out, cur) end
            for _, o in ipairs(out) do
                draw.SimpleText(o, "ZUI_Small", U(20), ty, C.textDim, 0, 1)
                ty = ty + U(18)
            end
        end

        if ach.showpercent and need > 0 then
            ty = ty + U(10)
            draw.SimpleText("PROGRESS", "ZUI_Caps", U(20), ty, C.textMut, 0, 1)
            draw.SimpleText(math.floor(frac * 100) .. "%", "ZUI_Mono", w - U(20), ty, C.text, 2, 1)
            ty = ty + U(20)
            surface.SetDrawColor(255, 255, 255, 18) surface.DrawRect(U(20), ty, w - U(40), U(6))
            surface.SetDrawColor(complete and C.good or C.white) surface.DrawRect(U(20), ty, (w - U(40)) * frac * s.Fade, U(6))
            ty = ty + U(20)
            draw.SimpleText(math.floor(val) .. " / " .. math.floor(need), "ZUI_Small", U(20), ty, C.textDim, 0, 1)
        end
    end

    local listWrap = vgui.Create("DPanel", body)
    listWrap:Dock(FILL)
    listWrap.Paint = function(_, w, h) surface.SetDrawColor(C.line) surface.DrawRect(w - 1, 0, 1, h) end

    local list = vgui.Create("DScrollPanel", listWrap)
    list:Dock(FILL)
    list:DockMargin(0, 0, U(16), 0)
    list.Paint = function() end
    UI.StyleScroll(list)

    root.list = list

    function root:UpdateValues()
        self.list:Clear()
        local rows = {}
        for _, ach in pairs(hg.achievements.achievements_data.created_achevements) do
            rows[#rows + 1] = ach
        end
        table.sort(rows, function(a, b)
            local ca, cb = IsComplete(a), IsComplete(b)
            if ca ~= cb then return ca end
            return (a.name or "") < (b.name or "")
        end)

        if not curent_panel_ach and rows[1] then curent_panel_ach = rows[1] end

        for _, ach in ipairs(rows) do
            local complete = IsComplete(ach)
            local val, need, frac = GetProgress(ach)

            local cell = UI.Cell(self.list, {
                tall = U(64),
                title = ach.name or "",
                sub = ach.showpercent and (math.floor(frac * 100) .. "%  (" .. math.floor(val) .. "/" .. math.floor(need) .. ")") or (complete and "Unlocked" or "Locked"),
                selected = function() return curent_panel_ach == ach end,
                onClick = function()
                    curent_panel_ach = ach
                    for i = 1, 3 do surface.PlaySound("ui/buttonclickrelease.wav") end
                end,
            })

            local basePaint = cell.Paint
            cell.Paint = function(s, w, h)
                basePaint(s, w, h)
                draw.SimpleText(complete and "✓" or "○", "ZUI_Body", w - U(16), h / 2, complete and C.good or C.textMut, 2, 1)
                if ach.showpercent then
                    surface.SetDrawColor(255, 255, 255, 14)
                    surface.DrawRect(0, h - 3, w, 3)
                    surface.SetDrawColor(complete and C.good or C.white)
                    surface.DrawRect(0, h - 3, w * frac, 3)
                end
            end
        end
    end

    root:UpdateValues()
end

local time_wait = 0
function hg.achievements.LoadAchievements()
    if time_wait > CurTime() then return end
    time_wait = CurTime() + 2

    net.Start("req_ach")
    net.SendToServer()
end

function hg.achievements.GetLocalAchievements()
    return hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())]
end

net.Receive("req_ach", function()
    hg.achievements.achievements_data.created_achevements = net.ReadTable()
    hg.achievements.achievements_data.player_achievements[tostring(LocalPlayer():SteamID())] = net.ReadTable()

    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:UpdateValues()
    end
end)

hg.achievements.NewAchievements = hg.achievements.NewAchievements or {}
local AchTable = hg.achievements.NewAchievements

net.Receive("hg_NewAchievement", function()
    local Ach = { time = CurTime() + 7.5, name = net.ReadString(), img = net.ReadString() }
    table.insert(AchTable, 1, Ach)
    surface.PlaySound("buttons/button14.wav")
end)

local function ToastFonts()
    surface.CreateFont("ZUI_ToastTitle", { font = "Bahnschrift", size = math.max(13, U(16)), weight = 700, extended = true })
    surface.CreateFont("ZUI_ToastBody",  { font = "Bahnschrift", size = math.max(15, U(19)), weight = 600, extended = true })
end
ToastFonts()
hook.Add("OnScreenSizeChanged", "ZUI_AchToastFonts", ToastFonts)

hook.Add("HUDPaint", "hg_NewAchievement", function()
    local frametime = RealFrameTime() * 10
    local Ck = UI and UI.C or { bg0 = Color(14, 14, 16, 250), line = Color(255, 255, 255, 22), lineHi = Color(255, 255, 255, 70), white = Color(255, 255, 255), textDim = Color(132, 132, 138) }

    for i = 1, #AchTable do
        local ach = AchTable[i]
        if not ach then continue end

        ach.img = isstring(ach.img) and Material(ach.img) or ach.img
        ach.Lerp = Lerp(frametime, ach.Lerp or 0, math.min(ach.time - CurTime(), 1) * i)

        local U2 = U
        local iconSize = U2(56)
        local wPad, hPad = U2(20), U2(14)
        surface.SetFont("ZUI_ToastBody")
        local wt = surface.GetTextSize("Achievement unlocked")
        surface.SetFont("ZUI_ToastTitle")
        local wt2 = surface.GetTextSize(ach.name or "")

        local boxW = iconSize + wPad * 2 + math.max(wt, wt2) + U2(16)
        local boxH = iconSize + hPad * 2
        local x = U2(24)
        local yTarget = ScrH() - boxH - U2(24)
        local y = yTarget + (1 - math.min(ach.Lerp / i, 1)) * U2(40)
        local alpha = math.Clamp(ach.Lerp, 0, 1) * 255

        surface.SetDrawColor(Ck.bg0.r, Ck.bg0.g, Ck.bg0.b, alpha * (Ck.bg0.a / 255))
        surface.DrawRect(x, y, boxW, boxH)
        surface.SetDrawColor(Ck.lineHi.r, Ck.lineHi.g, Ck.lineHi.b, alpha * 0.7)
        surface.DrawOutlinedRect(x, y, boxW, boxH, 1)
        surface.SetDrawColor(Ck.white.r, Ck.white.g, Ck.white.b, alpha)
        surface.DrawRect(x, y, 2, boxH)

        surface.SetDrawColor(Ck.bg0.r + 6, Ck.bg0.g + 6, Ck.bg0.b + 6, alpha)
        surface.DrawRect(x + hPad, y + hPad, iconSize, iconSize)
        if ach.img then
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.SetMaterial(ach.img)
            surface.DrawTexturedRect(x + hPad + 4, y + hPad + 4, iconSize - 8, iconSize - 8)
        end

        local tx = x + hPad + iconSize + U2(14)
        draw.SimpleText("ACHIEVEMENT UNLOCKED", "ZUI_ToastTitle", tx, y + hPad, Color(Ck.textDim.r, Ck.textDim.g, Ck.textDim.b, alpha), 0, 0)
        draw.SimpleText(ach.name or "", "ZUI_ToastBody", tx, y + hPad + U2(20), Color(Ck.white.r, Ck.white.g, Ck.white.b, alpha), 0, 0)

        if ach.time < CurTime() then
            table.remove(AchTable, i)
        end
    end
end)
