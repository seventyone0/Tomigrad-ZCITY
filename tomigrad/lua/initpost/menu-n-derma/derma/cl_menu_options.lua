hg.settings = hg.settings or {}
hg.settings.tbl = hg.settings.tbl or {}

function hg.settings:AddOpt( strCategory, strConVar, strTitle, bDecimals, bString, category )
    self.tbl[strCategory] = self.tbl[strCategory] or {}
    self.tbl[strCategory][strConVar] = { strCategory, strConVar, strTitle, bDecimals or false, bString or false, category }
end
local hg_firstperson_death = CreateClientConVar("hg_firstperson_death", "0", true, false, "Toggle first-person death camera view", 0, 0)
local hg_font_default = "Lora"
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", hg_font_default, true, false, "change every text font to selected because ui customization is cool")
local hg_oldradialmenu = CreateClientConVar("hg_oldradialmenu", "0", true, false, "use the old radial menu style", 0, 1)
local hg_nojogging = CreateClientConVar("hg_nojogging", "0", true, true, "Automatically sprint when holding shift.", 0, 1)
local hg_gollavo_headshot_effect = ConVarExists("hg_gollavo_headshot_effect") and GetConVar("hg_gollavo_headshot_effect") or CreateClientConVar("hg_gollavo_headshot_effect", "1", true, false, "Enable Gollavo headshot effect", 0, 1)
local hg_reduce_screeneffects = ConVarExists("hg_reduce_screeneffects") and GetConVar("hg_reduce_screeneffects") or CreateClientConVar("hg_reduce_screeneffects", "0", true, false, "Reduce screen shader effects by 50%", 0, 1)

local function ForceHGFirstPersonDeath()
    if hg_firstperson_death:GetString() != "0" then
        RunConsoleCommand("hg_firstperson_death", "0")
    end
end

local function ForceHGFont()
    if hg_font:GetString() != hg_font_default then
        RunConsoleCommand("hg_font", hg_font_default)
    end
end

ForceHGFirstPersonDeath()
ForceHGFont()

cvars.AddChangeCallback("hg_firstperson_death", function(_, _, newValue)
    if newValue != "0" then
        RunConsoleCommand("hg_firstperson_death", "0")
    end
end, "hg_firstperson_death_lock")

cvars.AddChangeCallback("hg_font", function(_, _, newValue)
    if newValue != hg_font_default then
        RunConsoleCommand("hg_font", hg_font_default)
    end
end, "hg_font_lock")

hook.Add("InitPostEntity", "hg_font_force_join", function()
    ForceHGFirstPersonDeath()
    ForceHGFont()
    timer.Simple(1, ForceHGFirstPersonDeath)
    timer.Simple(5, ForceHGFirstPersonDeath)
    timer.Simple(1, ForceHGFont)
    timer.Simple(5, ForceHGFont)
end)

local hg_attachment_draw_distance = CreateClientConVar("hg_attachment_draw_distance", 0, true, nil, "distance to draw attachments", 0, 4096)

xbars = 17
ybars = 30

gradient_l = Material("vgui/gradient-l")

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local sw, sh = ScrW(), ScrH()

local function MenuUnit(num)
    return math.floor(num * math.min(ScrW(), ScrH()) / 1000)
end

local SOUND_SETTINGS_CLICK = "ui/rem_click.wav"
local SOUND_TYPEWRITER = "shitty/tap-resonant.wav"
local SOUND_TYPEWRITER_LEVEL = 55
local SOUND_TYPEWRITER_VOLUME = 0.25
local SOUND_TYPEWRITER_PITCH = 102

local function PlayTypewriterSound()
    local ply = LocalPlayer and LocalPlayer()
    if IsValid(ply) then
        ply:EmitSound(SOUND_TYPEWRITER, SOUND_TYPEWRITER_LEVEL, SOUND_TYPEWRITER_PITCH, SOUND_TYPEWRITER_VOLUME)
        return
    end
    surface.PlaySound(SOUND_TYPEWRITER)
end

local settings_header_height = 70

local function CreateSettingsFonts()
    local scale = math.min(ScrW(), ScrH()) / 1000

    surface.CreateFont("ZCity_Menu_Small", {
        font = "Verily Serif Mono",
        size = ScreenScale(20),
        weight = 200,
    })
    surface.CreateFont("ZCity_Menu_Tiny", {
        font = "Verily Serif Mono",
        size = ScreenScale(8),
        weight = 200,
    })
    surface.CreateFont("ZCity_Menu_Settings_Medium", {
        font = "Verily Serif Mono",
        size = math.max(16, math.floor(32 * scale)),
        weight = 300,
    })
    surface.CreateFont("ZCity_Menu_Settings_Small", {
        font = "Verily Serif Mono",
        size = math.max(14, math.floor(22 * scale)),
        weight = 300,
    })
    surface.CreateFont("ZCity_Menu_Settings_Tiny", {
        font = "Verily Serif Mono",
        size = math.max(12, math.floor(16 * scale)),
        weight = 300,
    })
    surface.CreateFont("ZCity_Menu_Settings_Category", {
        font = "Verily Serif Mono",
        size = ScreenScale(15),
        weight = 100
    })
end
hook.Add("OnScreenSizeChanged", "ZCity_Settings_Fonts", CreateSettingsFonts)
CreateSettingsFonts()

---- Настройки

hg.settings:AddOpt("Gameplay","hg_newthoughts", "New thoughts")
hg.settings:AddOpt("Gameplay","hg_showthoughts", "Show thoughts")
hg.settings:AddOpt("Gameplay","hg_hints", "Show hints")
hg.settings:AddOpt("Gameplay","hg_gary", "HG GARY")
hg.settings:AddOpt("Gameplay","hg_deathfadeout", "Death fade out")
hg.settings:AddOpt("Gameplay","deatheffect_death_screen", "Cinematic death screen")
if not game.IsDedicated() then
    hg.settings:AddOpt("Serverside gameplay","hg_toughnpcs", "Tough npcs")
    hg.settings:AddOpt("Serverside gameplay","hg_thirdperson", "Thirdperson (WIP)")
    hg.settings:AddOpt("Serverside gameplay","hg_legacycam", "Legacy camera")
    hg.settings:AddOpt("Serverside gameplay","hg_ragdollcombat", "Ragdoll combat mode")
    hg.settings:AddOpt("Serverside gameplay","hg_movement_stamina_debuff", "Movement stamina debuff")
    hg.settings:AddOpt("Serverside gameplay","hg_furcity", "Furcity")
    hg.settings:AddOpt("Serverside gameplay","hg_appearance_access_for_all", "Appearance full access for all", nil, nil, "bool")
    hg.settings:AddOpt("Serverside gameplay","hg_healanims", "Heal & food animations")
    hg.settings:AddOpt("Serverside gameplay","hg_aimtoshoot", "DarkRP-like shoot system (aim to shoot)")
    hg.settings:AddOpt("Serverside gameplay","hg_slings", "Sling system")
    hg.settings:AddOpt("Serverside gameplay","homicide_traitoramount", "Homicide: Traitor Amount", nil, nil, "int")
end

hg.settings:AddOpt("Debug","hg_show_hitposmuzzle", "Show weapon hitpos")
hg.settings:AddOpt("Debug","hg_setzoompos", "Edit weapon zoompos, check console for results")
hg.settings:AddOpt("Debug","hg_show_hitbox", "Show hitboxes")

hg.settings:AddOpt("Optimization","hg_potatopc", "Potato PC Mode")
hg.settings:AddOpt("Optimization","hg_reduce_screeneffects", "Reduce screen effects 50%")
hg.settings:AddOpt("Optimization","hg_anims_draw_distance", "Animations Draw Distance", true, nil, "int")
hg.settings:AddOpt("Optimization","hg_anim_fps", "Animations FPS", nil, nil, "int")
hg.settings:AddOpt("Optimization","hg_attachment_draw_distance", "Attachment Draw Distance", true, nil, "int")
hg.settings:AddOpt("Optimization","hg_maxsmoketrails", "Maximum Smoke Trails", nil, nil, "int")
hg.settings:AddOpt("Optimization","hg_tpik_distance", "TPIK Render Distance", true, nil, "int")

hg.settings:AddOpt("Blood","hg_blood_draw_distance", "Blood Draw Distance")
hg.settings:AddOpt("Blood","hg_blood_fps", "Blood FPS")
hg.settings:AddOpt("Blood","hg_blood_sprites", "Blood Sprites (DISABLED FOR EVERYONE)")
hg.settings:AddOpt("Blood","hg_old_blood", "Old blood")

hg.settings.tbl["UI"] = hg.settings.tbl["UI"] or {}
hg.settings.tbl["UI"]["hg_font"] = nil

hg.settings:AddOpt("Weapons","hg_weaponshotblur_enable", "Shooting Blur")
hg.settings:AddOpt("Weapons","hg_dynamic_mags", "Dynamic Ammo Inspect")
hg.settings:AddOpt("Weapons","hg_zoomsensitivity", "Scope sensitivity")
hg.settings:AddOpt("Weapons","hg_highpitchgunfire", "Toggle high pitched gunfire sounds inside buildings")
hg.settings:AddOpt("Weapons","hg_gollavo_headshot_effect", "Gollavo headshot effect")

hg.settings:AddOpt("View","hg_fov", "Field Of View")
hg.settings:AddOpt("View","hg_newspectate", "Smooth Spectator Camera")
hg.settings:AddOpt("View","hg_cshs_fake", "C'sHS Ragdoll Camera")
hg.settings:AddOpt("View","hg_gun_cam", "Gun Camera (ADMIN ONLY)")
hg.settings:AddOpt("View","hg_nofovzoom", "Disable/Enable FOV Zoom")
hg.settings:AddOpt("View","hg_realismcam", "Realism camera (shitty)")
hg.settings:AddOpt("View","hg_gopro", "GoPro camera")
hg.settings:AddOpt("View","hg_newfakecam", "New fake camera")
hg.settings:AddOpt("View","hg_leancam_mul", "Lean camera mul", true, nil, "int")
hg.settings:AddOpt("View","hg_gun_cam", "Gun camera (WIP Admin only)")
hg.settings:AddOpt("Sound","hg_dmusic", "Dynamic Music")
hg.settings:AddOpt("Sound","hg_quietshots", "Enable/Disable Quietshoot Sounds")

--- Конец


function hg.CreateCategory(ctgName, ParentPanel, yPos)
    local pppanel = vgui.Create('DPanel', ParentPanel)
    pppanel:SetSize(ParentPanel:GetWide() / 1.05, ParentPanel:GetTall() * 0.07)
    pppanel:SetPos(ParentPanel:GetWide() / 2 -pppanel:GetWide() / 2, yPos)
    pppanel.Paint = function(self,w,h)
        surface.SetDrawColor(60,60,60,145)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(42, 42, 42, 184)
        surface.DrawRect(0, h-5, w, 5)
    
        draw.SimpleText(ctgName, 'ZCity_Menu_Settings_Category', w / 2, h / 2, color3, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    return pppanel
end

function hg.GetConVarType(convar)
    local stringv = convar:GetString()
    local floatVal = convar:GetFloat()
    local intVal = convar:GetInt()
    local boolVal = convar:GetBool()

    if (stringv == '0' and not boolVal) or (stringv == '1' and boolVal) then
        return 'bool'
    end

    if tonumber(stringv) and math.floor(stringv) == floatVal then
        if intVal == floatVal then
            return "int"
        end
    end

    return "string"
end

local function SetConVarValue(convar, value)
    if not convar then
        return
    end

    local name = convar.GetName and convar:GetName()
    if not name or name == "" then
        return
    end

    if isbool(value) then
        RunConsoleCommand(name, value and "1" or "0")
        return
    end

    RunConsoleCommand(name, tostring(value))
end

-- Всякая цветная хуйня

local clr_1 = Color(255,255,255,104)
local clr_2 = Color(122,122,122,104)
local clr_3 = Color(28,28,28)
local clr_4 = Color(0, 0, 0, 30)
local clr_5 = Color(30, 29, 29, 30)
local clr_6 = Color(255, 255, 255, 100)
local clr_7 = Color(255, 255, 255, 200)
local clr_8 = Color(70, 130, 180)

local settings_color_blacky = Color(25,25,30,220)
local settings_color_whitey = Color(255,255,255,240)
local settings_color_dim = Color(60,60,60,180)
local settings_color_text = Color(225,225,225)
local settings_color_text_dim = Color(160,160,160)
local settings_color_accent = Color(192,57,43)

local tex_gradient_d = surface.GetTextureID("vgui/gradient-d")
local tex_gradient_r = surface.GetTextureID("vgui/gradient-r")
local tex_gradient_l = surface.GetTextureID("vgui/gradient-l")
local info_row_gradient = Material("vgui/gradient-l")
local settings_menu_gradient_right = Color(18,18,18,65)
local settings_clr_1 = Color(100,100,100,35)
local settings_clr_verygray = Color(10,10,19,235)

-- Конец

local settings_sw, settings_sh = ScrW(), ScrH()
local settings_active_category = nil
local settings_buttons = {}
local settings_category_buttons = {}
local settings_content_panel = nil
local settings_sidebar_panel = nil
local settings_main_panel = nil
local settings_header_label = nil
local isValidMainMenuPanel = false

local info_sections = {
    {title = "Rank", key = "rank"},
    {title = "Leaderboard", key = "leaderboard"},
    {title = "Credits", key = "credits", disabled = true, disabledColor = Color(105, 105, 105, 180)},
    {title = "Socials", key = "socials"}
}
local info_credit_lines = {
    "PLACEHOLDER",
    "PLACEHOLDER",
    "PLACEHOLDER"
}
local info_fallback_band = {
    icon = Material("vgui/mats_jack_awards/10")
}
local info_fallback_medal = {
    icon = Material("vgui/mats_jack_awards/pt")
}
local info_stat_rows = {
    {"Kills", "Kills"},
    {"Headshots", "Headshots"},
    {"Deaths", "Deaths"},
    {"Suicides", "Suicides"}
}

-- Всякое с ссылочками

local info_social_links = {}

local info_social_icon_size = MenuUnit(24)
local info_social_icon_x = MenuUnit(18)
local info_social_text_x = MenuUnit(54)
local info_social_button_w = MenuUnit(72)
local info_social_button_h = MenuUnit(24)
local info_social_button_right = MenuUnit(18)
local info_judge_logo = Material("vgui/judgelogo.png", "noclamp smooth")
local info_judge_url = ""
local info_active_section = nil
local info_section_buttons = {}
local info_content_panel = nil
local info_header_label = nil

-- Пока не используется

local function InfoGetObtainedAchievements()
    local results = {}
    if not hg or not hg.achievements or not hg.achievements.achievements_data then return results end
    local created = hg.achievements.achievements_data.created_achevements or {}
    local localach = hg.achievements.GetLocalAchievements and hg.achievements.GetLocalAchievements() or {}

    for key, ach in pairs(created) do
        local playerData = localach and localach[key] or nil
        local value = playerData and playerData.value or ach.start_value or 0
        if value >= (ach.needed_value or 1) then
            results[#results + 1] = ach
        end
    end

    table.sort(results, function(a, b)
        return tostring(a.name or "") < tostring(b.name or "")
    end)

    return results
end

local function InfoHasLocalAchievement(key)
    if not hg or not hg.achievements or not hg.achievements.achievements_data then return false end
    local created = hg.achievements.achievements_data.created_achevements or {}
    local ach = created[key]
    if not ach then return false end
    local localach = hg.achievements.GetLocalAchievements and hg.achievements.GetLocalAchievements() or {}
    local playerData = localach and localach[key] or nil
    return (playerData and playerData.value or ach.start_value or 0) >= (ach.needed_value or 1)
end

local info_stat_methods = {
    Kills = "GetKills",
    Deaths = "GetDeaths",
    Suicides = "GetSuicides"
}

local function InfoGetPlayerStat(ply, key)
    if not IsValid(ply) then return 0 end

    local cached = ply.SvDB and ply.SvDB[key]
    if cached ~= nil then
        return tonumber(cached) or 0
    end

    if key == "Headshots" then
        return tonumber(ply:GetNWInt("Headshots", 0)) or 0
    end

    local methodName = info_stat_methods[key]
    local method = methodName and ply[methodName]
    if isfunction(method) then
        return tonumber(method(ply)) or 0
    end

    return 0
end

local INFO_STORED_STAT_NET = "get_svPData"
local INFO_RANK_NET = "zb_xp_get"

local function InfoCanStartNet(messageName)
    return util.NetworkStringToID(messageName) ~= 0
end

local function InfoRequestStoredStat(ply, key)
    if not IsValid(ply) or not InfoCanStartNet(INFO_STORED_STAT_NET) then return end
    net.Start(INFO_STORED_STAT_NET)
        net.WriteEntity(ply)
        net.WriteString(key)
    net.SendToServer()
end

local function InfoRefreshLocalRankData()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if InfoCanStartNet(INFO_RANK_NET) then
        net.Start(INFO_RANK_NET)
            net.WriteEntity(ply)
        net.SendToServer()
    end

    for _, statData in ipairs(info_stat_rows) do
        InfoRequestStoredStat(ply, statData[2])
    end

    if hg and hg.achievements and hg.achievements.LoadAchievements then
        hg.achievements.LoadAchievements()
    end
end

hook.Add("RoundInfoCalled", "InfoRankRoundRefresh", function()
    timer.Simple(0, function()
        if zb and zb.ROUND_STATE == 3 then
            InfoRefreshLocalRankData()
        end
    end)
end)

hg.Leaderboard = hg.Leaderboard or {Rows = {}, NextRequest = 0}

function hg.Leaderboard.Request(limit)
    if not InfoCanStartNet("zb_sql_leaderboard") then return end
    if (hg.Leaderboard.NextRequest or 0) > CurTime() then return end
    hg.Leaderboard.NextRequest = CurTime() + 3

    net.Start("zb_sql_leaderboard")
        net.WriteUInt(math.Clamp(limit or 10, 1, 10), 8)
    net.SendToServer()
end

function hg.Leaderboard.Get(limit)
    hg.Leaderboard.Request(limit)

    local rows = hg.Leaderboard.Rows or {}
    if limit and #rows > limit then
        local trimmed = {}
        for i = 1, limit do
            trimmed[i] = rows[i]
        end
        return trimmed
    end

    return rows
end

function hg.Leaderboard.GetAwards(row)
    if not row or not zb or not zb.Experience or not zb.Experience.GetAwards then return info_fallback_band, info_fallback_medal end
    return zb.Experience.GetAwards({skill = row.skill or 0, exp = row.xp or 0})
end

if not hg.Leaderboard.NetHooked then
    net.Receive("zb_sql_leaderboard", function()
        local count = net.ReadUInt(8)
        local rows = {}

        for i = 1, count do
            rows[i] = {
                steamid = net.ReadString(),
                name = net.ReadString(),
                skill = net.ReadFloat(),
                xp = net.ReadUInt(32),
                kills = net.ReadUInt(16),
                deaths = net.ReadUInt(16),
                kd = net.ReadFloat()
            }
        end

        hg.Leaderboard.Rows = rows
    end)

    hg.Leaderboard.NetHooked = true
end



hg = hg or {}
hg.UI = hg.UI or {}
hg.UI.C = hg.UI.C or {}
local UI = hg.UI
local C  = UI.C
local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end


function SettingsRefreshCategoryButtons() end
function SettingsRefreshContent() end
function KeybindsRefreshContent() end
function InfoRefreshContent() end

local function AddRow(parent, title, help, tall)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(tall or U(64))
    row:DockMargin(0, 0, U(8), U(4))
    row.Hov = 0
    row.Paint = function(s, w, h)
        local cx, cy = s:CursorPos()
        local inside = cx >= 0 and cy >= 0 and cx <= w and cy <= h and vgui.CursorVisible()
        s.Hov = UI.Smooth(s.Hov, inside and 1 or 0, 12)
        local hov = s.Hov
        surface.SetDrawColor(UI.Mix(hov, C.bg1, C.bg2)) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, UI.Mix(hov, C.line, C.lineHi))
        surface.SetDrawColor(C.white)
        surface.DrawRect(0, h * (0.5 - 0.25 * hov), U(2), h * 0.5 * hov)
        draw.SimpleText(title, "ZUI_Body", U(16), h / 2 - (help and help ~= "" and U(9) or 0), C.text, 0, 1)
        if help and help ~= "" then
            local maxw = s.HelpMaxW or (w * 0.5)
            surface.SetFont("ZUI_Small")
            local t = help
            while surface.GetTextSize(t) > maxw and #t > 4 do t = string.sub(t, 1, #t - 2) end
            if t ~= help then t = t .. "…" end
            draw.SimpleText(t, "ZUI_Small", U(16), h / 2 + U(12), C.textDim, 0, 1)
        end
    end
    return row
end

local function MakeScroll(parent)
    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    scroll.Paint = function() end
    UI.StyleScroll(scroll)
    return scroll
end


local function MakeBack(ParentPanel)
    return function()
        UI.SndClick()
        if not IsValid(ParentPanel) then return end
        if IsValid(ParentPanel:GetParent()) then
            UI.CloseToMenu(ParentPanel)
        else
            ParentPanel:Remove()
        end
    end
end


local function BuildSettingsRow(scroll, convarName, settingData, ctrlW)
    if convarName == "hg_gollavo_headshot_effect" and not InfoHasLocalAchievement("gollavo") then return end
    if convarName == "hg_reduce_screeneffects" then
        local pc = GetConVar("hg_potatopc")
        if not (pc and pc:GetBool()) then return end
    end
    local convar = GetConVar(settingData[2])
    if not convar then return end

    local row = AddRow(scroll, settingData[3], convar:GetHelpText() or "")
    local convarType = settingData[6] or hg.GetConVarType(convar)

    if convarType == "bool" then
        local sw = UI.Switch(row, function() return convar:GetBool() end, function(newValue)
            if convar.GetName then RunConsoleCommand(convar:GetName(), newValue and "1" or "0") end
        end)
        row.PerformLayout = function(s, w, h)
            sw:SetSize(U(76), U(28))
            sw:SetPos(w - U(76) - U(16), (h - U(28)) / 2)
            s.HelpMaxW = w - U(76) - U(60)
        end

    elseif convarType == "int" then
        local decimals = settingData[4] and 2 or 0
        local min = convar:GetMin() or 0
        local max = convar:GetMax() or 100
        local function cur() return decimals > 0 and convar:GetFloat() or convar:GetInt() end

        local slider = UI.Slider(row, cur, function(v)
            if convar.GetName then RunConsoleCommand(convar:GetName(), tostring(v)) end
        end, min, max, decimals)

        local entry = UI.TextEntry(row)
        entry:SetNumeric(true)
        entry:SetText(tostring(cur()))
        entry:SetContentAlignment(5)
        entry.OnValueChange = function(s, val)
            local n = tonumber(val)
            if not n then return end
            n = decimals > 0 and math.Round(n, decimals) or math.Round(n)
            RunConsoleCommand(convar:GetName(), tostring(n))
        end
        entry.Think = function(s)
            if not s:HasFocus() then
                local v = tostring(cur())
                if s:GetText() ~= v then s:SetText(v) end
            end
        end

        row.PerformLayout = function(s, w, h)
            local ew, sw_ = U(76), math.min(U(220), w * 0.28)
            entry:SetSize(ew, U(28))
            entry:SetPos(w - ew - U(16), (h - U(28)) / 2)
            slider:SetSize(sw_, U(28))
            slider:SetPos(w - ew - U(16) - sw_ - U(14), (h - U(28)) / 2)
            s.HelpMaxW = w - ew - sw_ - U(80)
        end

    elseif convarType == "string" then
        local entry = UI.TextEntry(row)
        entry:SetText(convar:GetString())
        entry.OnValueChange = function(s, val)
            if convar.GetName then RunConsoleCommand(convar:GetName(), val) end
        end
        row.PerformLayout = function(s, w, h)
            local ew = math.min(U(260), w * 0.34)
            entry:SetSize(ew, U(30))
            entry:SetPos(w - ew - U(16), (h - U(30)) / 2)
            s.HelpMaxW = w - ew - U(60)
        end
    end
end

function hg.DrawSettings(ParentPanel)
    settings_sw, settings_sh = ScrW(), ScrH()
    isValidMainMenuPanel = IsValid(ParentPanel)

    local isSuperAdmin = LocalPlayer():IsSuperAdmin()
    local categories = {}
    for name in SortedPairs(hg.settings.tbl) do
        if (name == "Debug" or name == "Serverside gameplay") and not isSuperAdmin then continue end
        categories[#categories + 1] = { id = name, label = name }
    end

    if not settings_active_category or not hg.settings.tbl[settings_active_category]
        or ((settings_active_category == "Debug" or settings_active_category == "Serverside gameplay") and not isSuperAdmin) then
        settings_active_category = categories[1] and categories[1].id
    end

    ParentPanel:SetAlpha(0)
    ParentPanel.Paint = function() end
    ParentPanel:AlphaTo(255, 0.15, 0)

    local win
    local side, content, scroll

    local function Refresh()
        if not IsValid(content) then return end
        content:Clear()
        settings_content_panel = content

        local cat = settings_active_category
        if not cat or not hg.settings.tbl[cat] then return end

        if IsValid(win) then win:SetHint(cat .. "  ·  " .. table.Count(hg.settings.tbl[cat]) .. " options") end

        scroll = MakeScroll(content)
        for convarName, settingData in SortedPairs(hg.settings.tbl[cat]) do
            BuildSettingsRow(scroll, convarName, settingData)
        end
    end

    win = UI.Window(ParentPanel, {
        index  = "02",
        title  = "SETTINGS",
        hint   = "Preferences.",
        onBack = MakeBack(ParentPanel),
        footer = { "LMB adjust", "Drag slider", "ESC close" },
    })


    local rail = vgui.Create("DPanel", win.Body)
    rail:Dock(LEFT)
    rail:SetWide(U(250))
    rail:DockMargin(0, 0, U(20), 0)
    rail.Paint = function(_, w, h)
        surface.SetDrawColor(C.line) surface.DrawRect(w - 1, 0, 1, h)
    end
    local railScroll = MakeScroll(rail)
    railScroll:DockMargin(0, 0, U(12), 0)
    settings_category_buttons = {}
    for i, cat in ipairs(categories) do
        local cell = UI.Cell(railScroll, {
            title = cat.label,
            right = string.format("%02d", i),
            tall = U(46),
            selected = function() return settings_active_category == cat.id end,
            onClick = function()
                if settings_active_category == cat.id then return end
                settings_active_category = cat.id
                Refresh()
            end,
        })
        settings_category_buttons[#settings_category_buttons + 1] = cell
    end

    content = vgui.Create("DPanel", win.Body)
    content:Dock(FILL)
    content.Paint = function() end
    settings_content_panel = content

    Refresh()
end

local keybinds_content_panel = nil
local keybinds_header_label = nil

local function KeybindsFormatKey(key)
    if not key or key == KEY_NONE or key == -999 then return "NONE" end
    local keyName = input.GetKeyName(key)
    return keyName and string.upper(keyName) or tostring(key)
end

local function KeybindsSetBind(bindName, slot, key)
    hg.Binds.CurrentBinds[bindName] = hg.Binds.CurrentBinds[bindName] or {KEY_NONE, nil}
    hg.Binds.CurrentBinds[bindName][slot] = key == KEY_NONE and nil or key
    hg.Binds.SaveThem()
end

local function KeybindsResetDefaults()
    for bindName, keys in pairs(hg.Binds.StandartBinds or {}) do
        hg.Binds.CurrentBinds[bindName] = {keys[1], keys[2]}
    end
    hg.Binds.SaveThem()
end

local function KeybindsCreateBinder(parent, bindName, slot)
    local binder = vgui.Create("DBinder", parent)
    binder:SetValue((hg.Binds.CurrentBinds[bindName] or {})[slot] or KEY_NONE)
    binder:SetFont("ZUI_Mono")
    binder.Hov = 0
    function binder:Paint(w, h)
        self.Hov = UI.Smooth(self.Hov, (self:IsHovered() or self.Trapping) and 1 or 0, 14)
        surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, UI.Mix(self.Hov, C.line, C.lineMax))
        local txt = self.Trapping and "PRESS A KEY" or KeybindsFormatKey(self:GetValue())
        draw.SimpleText(txt, "ZUI_Mono", w / 2, h / 2, self.Trapping and C.white or C.text, 1, 1)
        if self.Trapping then UI.Brackets(0, 0, w, h, C.white, U(6)) end
        return true
    end
    function binder:OnChange(key)
        KeybindsSetBind(bindName, slot, key)
    end
    return binder
end

function hg.DrawKeybinds(ParentPanel)
    settings_sw, settings_sh = ScrW(), ScrH()

    ParentPanel:SetAlpha(0)
    ParentPanel.Paint = function() end
    ParentPanel:AlphaTo(255, 0.15, 0)

    local win = UI.Window(ParentPanel, {
        index  = "03",
        title  = "KEYBINDS",
        hint   = "If you have the buttons already binded via console you can still use these as alternatives.",
        onBack = MakeBack(ParentPanel),
        footer = { "CLICK rebind", "Clear remove", "ESC cancel" },
    })

    local scrollHolder = win.Body
    local function Build()
        if IsValid(keybinds_content_panel) then keybinds_content_panel:Remove() end
        local holder = vgui.Create("DPanel", scrollHolder)
        holder:Dock(FILL)
        holder.Paint = function() end
        keybinds_content_panel = holder

        local reset = UI.Button(holder, "Reset to defaults", function()
            KeybindsResetDefaults()
            Build()
        end, "danger")
        reset:Dock(BOTTOM)
        reset:SetTall(U(40))
        reset:DockMargin(0, U(8), U(8), 0)

        local scroll = MakeScroll(holder)
        for bindName in SortedPairs(hg.Binds.CurrentBinds or {}) do
            local row = AddRow(scroll, (hg.Binds.Names and hg.Binds.Names[bindName]) or bindName, bindName, U(70))
            local clear = UI.Button(row, "Clear", function()
                hg.Binds.CurrentBinds[bindName] = {KEY_NONE, nil}
                hg.Binds.SaveThem()
                Build()
            end)
            local b1 = KeybindsCreateBinder(row, bindName, 1)
            local b2 = KeybindsCreateBinder(row, bindName, 2)
            row.PerformLayout = function(s, w, h)
                local bh = U(32)
                local y = (h - bh) / 2
                b2:SetSize(U(130), bh) b2:SetPos(w - U(130) - U(16), y)
                b1:SetSize(U(130), bh) b1:SetPos(w - U(130) * 2 - U(24), y)
                clear:SetSize(U(70), bh) clear:SetPos(w - U(130) * 2 - U(24) - U(70) - U(10), y)
                s.HelpMaxW = w - U(130) * 2 - U(180)
            end
        end
    end
    Build()
end


local function StatCell(parent, label)
    local p = vgui.Create("DPanel", parent)
    p.Label, p.Value = label, "0"
    p.Paint = function(s, w, h)
        surface.SetDrawColor(C.bg1) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, C.line)
        UI.Brackets(0, 0, w, h, C.lineHi, U(6))
        draw.SimpleText(string.upper(s.Label), "ZUI_Caps", U(16), U(16), C.textDim, 0, 1)
        draw.SimpleText(s.Value, "ZUI_MonoBig", U(16), h - U(22), C.white, 0, 1)
    end
    return p
end

local function BuildRankSection(content)
    InfoRefreshLocalRankData()

    local scroll = MakeScroll(content)
    scroll:DockMargin(0, 0, U(6), 0)


    local profile = vgui.Create("DPanel", scroll)
    profile:Dock(TOP)
    profile:SetTall(U(210))
    profile:DockMargin(0, 0, U(8), U(14))
    profile.Band, profile.Medal = nil, nil
    profile.Name, profile.Xp, profile.Skill, profile.MedalName, profile.BandName = "", "", "", "", ""
    profile.Paint = function(s, w, h)
        surface.SetDrawColor(C.bg1) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, C.line)
        UI.Brackets(0, 0, w, h, C.lineHi, U(8))

        local ms = h - U(36)
        local mx, my = U(24), U(18)
        surface.SetDrawColor(C.bg0) surface.DrawRect(mx, my, ms, ms)
        UI.Outline(mx, my, ms, ms, C.line)
        if s.Band and s.Band.icon then
            surface.SetMaterial(s.Band.icon) surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(mx + U(6), my + U(6), ms - U(12), ms - U(12))
        end
        if s.Medal and s.Medal.icon then
            surface.SetMaterial(s.Medal.icon) surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(mx + U(6), my + U(6), ms - U(12), ms - U(12))
        end

        local tx = mx + ms + U(28)
        draw.SimpleText("OPERATIVE", "ZUI_Caps", tx, U(30), C.textMut, 0, 1)
        draw.SimpleText(s.Name, "ZUI_Title", tx, U(56), C.white, 0, 1)
        draw.SimpleText(s.Xp, "ZUI_MonoBig", tx, U(104), C.text, 0, 1)
        draw.SimpleText(s.Skill, "ZUI_Body", tx, U(138), C.textDim, 0, 1)
        draw.SimpleText("MEDAL  " .. s.MedalName, "ZUI_Small", tx, U(164), C.textDim, 0, 1)
        draw.SimpleText("BAND   " .. s.BandName, "ZUI_Small", tx, U(184), C.textDim, 0, 1)
    end

    UI.SectionLabel(scroll, "Statistics")

    local grid = vgui.Create("DPanel", scroll)
    grid:Dock(TOP)
    grid:DockMargin(0, 0, U(8), U(14))
    grid.Paint = function() end

    local statCards = {}
    for _, statData in ipairs(info_stat_rows) do
        local p = StatCell(grid, statData[1])
        statCards[#statCards + 1] = { key = statData[2], panel = p }
    end
    local kdPanel = StatCell(grid, "K/D")
    kdPanel.Value = "0.00"

    grid.PerformLayout = function(s, w, h)
        local gap = U(8)
        local cols = w < U(520) and 2 or 5
        local all = {}
        for _, sc in ipairs(statCards) do all[#all + 1] = sc.panel end
        all[#all + 1] = kdPanel
        cols = math.min(cols, #all)
        local cw = math.floor((w - gap * (cols - 1)) / cols)
        local ch = U(84)
        for i, pnl in ipairs(all) do
            local r, c = math.floor((i - 1) / cols), (i - 1) % cols
            pnl:SetPos(c * (cw + gap), r * (ch + gap))
            pnl:SetSize(cw, ch)
        end
        local rows = math.ceil(#all / cols)
        s:SetTall(rows * ch + math.max(0, rows - 1) * gap)
    end

    UI.SectionLabel(scroll, "Obtained achievements")

    local achHolder = vgui.Create("DPanel", scroll)
    achHolder:Dock(TOP)
    achHolder:DockMargin(0, 0, U(8), 0)
    achHolder.Paint = function() end

    local empty = vgui.Create("DLabel", achHolder)
    empty:Dock(TOP)
    empty:SetTall(U(40))
    empty:SetFont("ZUI_Small")
    empty:SetTextColor(C.textMut)
    empty:SetContentAlignment(5)
    empty:SetText("NO ACHIEVEMENTS OBTAINED YET")

    local achRows = {}
    local function RefreshAchievements()
        local obtained = InfoGetObtainedAchievements()
        for _, pnl in ipairs(achRows) do if IsValid(pnl) then pnl:Remove() end end
        achRows = {}
        empty:SetVisible(#obtained == 0)
        achHolder:SetTall(U(40))
        if #obtained == 0 then return end
        local total = 0
        for _, ach in ipairs(obtained) do
            local cell = UI.Cell(achHolder, { title = ach.name or "Achievement", sub = ach.description or "", tall = U(58) })
            cell:SetMouseInputEnabled(false)
            achRows[#achRows + 1] = cell
            total = total + U(58) + U(4)
        end
        achHolder:SetTall(total)
    end

    local statValues = { Kills = 0, Headshots = 0, Deaths = 0, Suicides = 0 }
    local lastExp, lastSkill, lastSig = -1, -1, ""
    scroll.Think = function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local band, medal = info_fallback_band, info_fallback_medal
        if ply.GetAwards then band, medal = ply:GetAwards() end
        band = band or info_fallback_band
        medal = medal or info_fallback_medal
        profile.Band, profile.Medal = band, medal

        local name = ply:GetNWString("PlayerName", "")
        if name == "" then name = ply:Nick() end

        local newExp = math.floor(tonumber(ply.exp) or 0)
        local newSkill = math.Round(tonumber(ply.skill) or 0, 3)
        if lastExp ~= newExp or lastSkill ~= newSkill then
            profile.Name = string.upper(name)
            profile.Xp = newExp .. " XP"
            profile.Skill = newSkill .. " Skill"
            profile.MedalName = string.upper((medal and medal.name) or "UNRANKED")
            profile.BandName = (band and band.name and band.name ~= "") and string.upper(band.name) or "SOON"
            lastExp, lastSkill = newExp, newSkill
        end

        for _, sc in ipairs(statCards) do
            statValues[sc.key] = InfoGetPlayerStat(ply, sc.key)
            sc.panel.Value = tostring(math.floor(statValues[sc.key] or 0))
        end
        local effDeaths = math.max(statValues.Deaths - statValues.Suicides, 0)
        kdPanel.Value = string.format("%.2f", statValues.Kills / math.max(effDeaths, 1))

        local obtained = InfoGetObtainedAchievements()
        local sig = tostring(#obtained)
        for i, ach in ipairs(obtained) do sig = sig .. "|" .. tostring(ach.name or i) end
        if sig ~= lastSig then
            lastSig = sig
            RefreshAchievements()
        end
    end
end

local function BuildLeaderboardSection(content)
    local scroll = MakeScroll(content)
    scroll:DockMargin(0, 0, U(6), 0)

    UI.SectionLabel(scroll, "Top 10 players")

    local rows, lastRefresh = {}, 0
    local function Rebuild()
        for _, r in ipairs(rows) do if IsValid(r) then r:Remove() end end
        rows = {}

        local leaders = hg.Leaderboard.Get(10)
        if #leaders == 0 then
            local e = vgui.Create("DLabel", scroll)
            e:Dock(TOP) e:SetTall(U(44))
            e:SetFont("ZUI_Small") e:SetTextColor(C.textMut)
            e:SetContentAlignment(5) e:SetText("NO SQL LEADERBOARD DATA")
            rows[#rows + 1] = e
            return
        end

        for rank, data in ipairs(leaders) do
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:SetTall(U(66))
            row:DockMargin(0, 0, U(8), U(4))
            row.Hov = 0
            row.Paint = function(s, w, h)
                s.Hov = UI.Smooth(s.Hov, s:IsHovered() and 1 or 0, 12)
                surface.SetDrawColor(UI.Mix(s.Hov, C.bg1, C.bg2)) surface.DrawRect(0, 0, w, h)
                UI.Outline(0, 0, w, h, UI.Mix(s.Hov, C.line, C.lineHi))
                surface.SetDrawColor(UI.Alpha(C.white, rank <= 3 and 255 or 90))
                surface.DrawRect(0, 0, U(2), h)
                draw.SimpleText(string.format("%02d", rank), "ZUI_MonoBig", U(18), h / 2,
                    rank <= 3 and C.white or C.textDim, 0, 1)
                draw.SimpleText(data.name, "ZUI_Body", U(120), h / 2 - U(10), C.text, 0, 1)
                draw.SimpleText(string.format("K/D %.2f", data.kd), "ZUI_Small", U(120), h / 2 + U(12), C.textDim, 0, 1)
                draw.SimpleText("XP " .. data.xp, "ZUI_Mono", w - U(70), h / 2 - U(10), C.text, 2, 1)
                draw.SimpleText("K " .. math.floor(data.kills) .. "   D " .. math.floor(data.deaths), "ZUI_Small",
                    w - U(70), h / 2 + U(12), C.textDim, 2, 1)
                if s.Hov > 0.02 then UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 170 * s.Hov), U(7)) end
            end

            local avatar = vgui.Create("AvatarImage", row)
            avatar:SetSize(U(40), U(40))
            avatar:SetPos(U(66), (U(66) - U(40)) / 2)
            avatar:SetMouseInputEnabled(false)
            avatar:SetSteamID(data.steamid, 64)
            avatar.PaintOver = function(s, w, h) UI.Outline(0, 0, w, h, C.lineHi) end

            local medal = vgui.Create("DPanel", row)
            medal:SetSize(U(34), U(34))
            row.PerformLayout = function(s, w, h) medal:SetPos(w - U(52), (h - U(34)) / 2) end
            medal.Paint = function(s, w, h)
                local band, med = hg.Leaderboard.GetAwards(data)
                band = band or info_fallback_band
                med = med or info_fallback_medal
                if band and band.icon then
                    surface.SetMaterial(band.icon) surface.SetDrawColor(255, 255, 255, 220)
                    surface.DrawTexturedRect(0, 0, w, h)
                end
                if med and med.icon then
                    surface.SetMaterial(med.icon) surface.SetDrawColor(255, 255, 255, 240)
                    surface.DrawTexturedRect(0, 0, w, h)
                end
            end
            rows[#rows + 1] = row
        end
    end

    scroll.Think = function()
        if lastRefresh > CurTime() then return end
        lastRefresh = CurTime() + 2
        Rebuild()
    end
    Rebuild()
end

local function BuildCreditsSection(content)
    local scroll = MakeScroll(content)
    UI.SectionLabel(scroll, "Credits")
    for _, line in ipairs(info_credit_lines) do
        UI.Cell(scroll, { title = line, tall = U(56) }):SetMouseInputEnabled(false)
    end
end

local function BuildSocialsSection(content)
    local holder = vgui.Create("DPanel", content)
    holder:Dock(FILL)
    holder.Paint = function() end


    local bottom = vgui.Create("DPanel", holder)
    bottom:Dock(BOTTOM)
    bottom:SetTall(U(230))
    bottom.Paint = function(_, w, h)
        surface.SetDrawColor(C.line) surface.DrawRect(0, 0, w, 1)
        draw.SimpleText("ALSO CHECK OUT", "ZUI_Caps", w / 2, U(20), C.textDim, 1, 1)
    end

    local judge = vgui.Create("DButton", bottom)
    judge:SetText("")
    judge:SetCursor("hand")
    judge.Hov = 0
    judge.DoClick = function() UI.SndClick() gui.OpenURL(info_judge_url) end
    judge.Paint = function(s, w, h)
        s.Hov = UI.Smooth(s.Hov, s:IsHovered() and 1 or 0, 12)
        local aspect = math.max(1, info_judge_logo:Height()) / math.max(1, info_judge_logo:Width())
        local bw = math.min(w * 0.9, h / aspect)
        local bh = bw * aspect
        local sc = 1 + s.Hov * 0.05
        surface.SetMaterial(info_judge_logo)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect((w - bw * sc) / 2, (h - bh * sc) / 2, bw * sc, bh * sc)
    end
    bottom.PerformLayout = function(s, w, h)
        local aspect = math.max(1, info_judge_logo:Height()) / math.max(1, info_judge_logo:Width())
        local bh = math.min(h - U(50), U(170))
        local bw = math.min(w - U(20), bh / aspect)
        judge:SetSize(bw * 1.06, bh * 1.06)
        judge:SetPos((w - judge:GetWide()) / 2, U(36) + (h - U(36) - judge:GetTall()) / 2)
    end

    local scroll = MakeScroll(holder)
    UI.SectionLabel(scroll, "Communities")
    for _, social in ipairs(info_social_links) do
        local cell = UI.Cell(scroll, {
            title = social.title, sub = social.subtitle, tall = U(70),
            right = "JOIN ›",
            onClick = function() if social.url and social.url ~= "" then gui.OpenURL(social.url) end end,
        })
        local basePaint = cell.Paint
        cell.Paint = function(s, w, h)
            basePaint(s, w, h)
            if social.icon then
                surface.SetMaterial(social.icon)
                surface.SetDrawColor(255, 255, 255, 220)
                surface.DrawTexturedRect(w - U(160), (h - U(28)) / 2, U(28), U(28))
            end
        end
    end
end

function hg.DrawInformation(ParentPanel)
    settings_sw, settings_sh = ScrW(), ScrH()

    ParentPanel:SetAlpha(0)
    ParentPanel.Paint = function() end
    ParentPanel:AlphaTo(255, 0.15, 0)

    info_section_buttons = {}
    if not info_active_section then
        info_active_section = info_sections[1] and info_sections[1].key or "rank"
    end

    local tabs = {}
    for _, s in ipairs(info_sections) do
        if not s.disabled then tabs[#tabs + 1] = { id = s.key, label = s.title } end
    end

    local win, content
    local function Refresh()
        if not IsValid(content) then return end
        content:Clear()
        info_content_panel = content

        local key = info_active_section or "rank"
        for _, sd in ipairs(info_sections) do
            if sd.key == key and sd.disabled then key = "rank" info_active_section = "rank" break end
        end
        for _, sd in ipairs(info_sections) do
            if sd.key == info_active_section and IsValid(win) then win:SetHint(sd.title) end
        end

        if key == "rank" then BuildRankSection(content)
        elseif key == "leaderboard" then BuildLeaderboardSection(content)
        elseif key == "credits" then BuildCreditsSection(content)
        elseif key == "socials" then BuildSocialsSection(content) end
    end

    win = UI.Window(ParentPanel, {
        index  = "04",
        title  = "INFORMATION",
        hint   = "Rank",
        tabs   = tabs,
        onTab  = function(id) info_active_section = id Refresh() end,
        onBack = MakeBack(ParentPanel),
        footer = { "TAB switch section", "ESC close" },
    })
    win.ActiveTab = info_active_section

    content = vgui.Create("DPanel", win.Body)
    content:Dock(FILL)
    content.Paint = function() end
    info_content_panel = content

    Refresh()
end
