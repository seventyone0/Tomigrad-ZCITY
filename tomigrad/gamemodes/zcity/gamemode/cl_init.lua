zb = zb or {}
include("shared.lua")
include("loader.lua")

if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Enables smooth spectator camera transitions", 0, 1)
end

function CurrentRound()
	return zb.modes[zb.CROUND]
end

zb.ROUND_STATE = 0
local vecZero = Vector(0.2, 0.2, 0.2)
local vecFull = Vector(1, 1, 1)
spect,prevspect,viewmode = nil,nil,1
local hullscale = Vector(0,0,0)
net.Receive("ZB_SpectatePlayer", function(len)
	spect = net.ReadEntity()
	prevspect = net.ReadEntity()
	viewmode = net.ReadInt(4)

	timer.Simple(0.1,function()
		LocalPlayer():SetHull(-hullscale,hullscale)
		LocalPlayer():SetHullDuck(-hullscale,hullscale)

		if viewmode == 3 then
			LocalPlayer():SetMoveType(MOVETYPE_NOCLIP)
		end
	end)
end)

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime",function()
	local time = net.ReadFloat()
	local time2 = net.ReadFloat()
	local time3 = net.ReadFloat()

	zb.ROUND_TIME = time
	zb.ROUND_START = time2
	zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local blursettings = {}
local hg_potatopc
hg = hg or {}
function hg.DrawBlur(panel, amount, passes, alpha)
	if is3d2d then return end
	amount = amount or 5
	hg_potatopc = hg_potatopc or hg.ConVars.potatopc

	if(hg_potatopc:GetBool())then
		surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(0, 0, 0, alpha or 125)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		local x, y = panel:LocalToScreen(0, 0)
		if blursettings and blursettings[1] == amount and blursettings[2] == passes then
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			return
		end
		blursettings = {amount, passes}
		for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end
end

BlurBackground = BlurBackground or hg.DrawBlur

local keydownattack
local keydownattack2
local keydownreload

hook.Add("HG_CalcView", "zzzzzzzUwU", function(ply, pos, angles, fov)
	if not lply:Alive() then
		if lply:KeyDown(IN_ATTACK) then
			if not keydownattack then
				keydownattack = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK,32)
				net.SendToServer()
			end
		else
			keydownattack = false
		end

		if lply:KeyDown(IN_ATTACK2) then
			if not keydownattack2 then
				keydownattack2 = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK2,32)
				net.SendToServer()
			end
		else
			keydownattack2 = false
		end

		if lply:KeyDown(IN_RELOAD) then
			if not keydownreload then
				keydownreload = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_RELOAD,32)
				net.SendToServer()
			end
		else
			keydownreload = false
		end

		local spect = lply:GetNWEntity("spect",spect)
		if not IsValid(spect) then return end

		local viewmode = lply:GetNWInt("viewmode",viewmode)
		
		if viewmode == 3 then
			if lply:GetMoveType()!=MOVETYPE_NOCLIP then
				lply:SetMoveType(MOVETYPE_NOCLIP)
			end
			lply:SetObserverMode(OBS_MODE_ROAMING)
			return
		else
			lply:SetPos(spect:GetPos())
		end
		
		local ent = hg.GetCurrentCharacter(spect)
		if not IsValid(ent) then return end
		
		local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
		local bon = ent:GetBoneMatrix(headBone)
		
		if not bon then 
			local eyePos = ent:EyePos()
			if eyePos and eyePos ~= vector_origin then
				pos = eyePos
				ang = ent:EyeAngles()
			else
				pos = ent:GetPos() + Vector(0, 0, 64)
				ang = ent:GetAngles()
			end
		else
			pos, ang = bon:GetTranslation(), bon:GetAngles()
		end

		local eyePos, eyeAng = lply:EyePos(), lply:EyeAngles()
		
		local tr = {}
		tr.start = pos
		tr.endpos = pos + eyeAng:Forward() * -120
		tr.filter = {ent, lply, spect}
		tr.mins = Vector(-4, -4, -4)
		tr.maxs = Vector(4, 4, 4)
		tr = util.TraceHull(tr)

		if viewmode == 2 then
			pos = tr.HitPos + eyeAng:Forward() * 8
			ang = eyeAng
		elseif viewmode == 1 then
			if ent ~= spect and IsValid(ent) then
				local eyeAtt = ent:GetAttachment(ent:LookupAttachment("eyes"))
				if eyeAtt then
					ang = eyeAtt.Ang
				else
					ang = spect:EyeAngles()
				end
			else
				ang = spect:EyeAngles()
			end
			pos = pos + spect:EyeAngles():Forward() * 8
		else
			pos = eyePos
			ang = eyeAng
		end
		
		ang[3] = 0
		
		local view
		local hg_newspectate = GetConVar("hg_newspectate")
		if hg_newspectate and hg_newspectate:GetBool() then
			if not lply.spectLastPos then
				lply.spectLastPos = pos
				lply.spectLastAng = ang
			end
			
			local lerpFactor = FrameTime() * 10
			lply.spectLastPos = LerpVector(lerpFactor, lply.spectLastPos, pos)
			lply.spectLastAng = LerpAngle(lerpFactor, lply.spectLastAng, ang)

			view = {
				origin = lply.spectLastPos,
				angles = lply.spectLastAng,
				fov = fov,
			}
		else
			view = {
				origin = pos,
				angles = ang,
				fov = fov,
			}
		end

		return view
	else
		lply.spectLastPos = nil
		lply.spectLastAng = nil
		lply:SetObserverMode(OBS_MODE_NONE)
	end
end)

zb.fade = zb.fade or 0

hook.Add("RenderScreenspaceEffects", "huyhuyUwU", function()
	if zb.fade > 0 then
		zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)

		surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end)

zb.ROUND_STATE = 0
net.Receive("RoundInfo", function()
	local rnd = net.ReadString()
	
	hook.Run("RoundInfoCalled", rnd)

	if zb.CROUND ~= rnd then
		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end
	end

	zb.CROUND = rnd

	zb.ROUND_STATE = net.ReadInt(4)
	
	if zb.ROUND_STATE == 0 then
		zb.fade = 7
	end

	if zb.CROUND ~= "" then
		if CurrentRound() then
			if zb.ROUND_STATE == 3 then
				if CurrentRound().EndRound then
					CurrentRound():EndRound()
				end
			elseif zb.ROUND_STATE == 1 then
				if CurrentRound().RoundStart then
					CurrentRound():RoundStart()
				end
			end
		end
	end
end)

if IsValid(scoreBoardMenu) then
	scoreBoardMenu:Remove()
	scoreBoardMenu = nil
end

hook.Add("Player Disconnected","retrymenu",function(data)
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
end)

local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "Change UI text font")
local font = function()
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZB_InterfaceSmall", {
    font = font(),
    size = ScreenScale(6),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_ScrappersMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMediumLarge", {
    font = font(),
    size = 35,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceLarge", {
    font = font(),
    size = ScreenScale(20),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceHumongous", {
    font = font(),
    size = 200,
    weight = 400,
    antialias = true
})

hg.playerInfo = hg.playerInfo or {}

local function addToPlayerInfo(ply, muted, volume)
	hg.playerInfo[ply:SteamID()] = {muted and true or false, volume}

	local json = util.TableToJSON(hg.playerInfo)
	file.Write("zcity_muted.txt", json)

	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end
	end
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "zcityhuy", function(data)
	local ply = Player(data.userid)
	if IsValid(ply) and ply.SetMuted and hg.playerInfo and hg.playerInfo[data.networkid] then
		ply:SetMuted(hg.playerInfo[data.networkid][1])
		ply:SetVoiceVolumeScale(hg.playerInfo[data.networkid][2])
	end
end)

hook.Add("InitPostEntity", "furryhuy", function()
	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end

		if hg.playerInfo then
			for i, ply in player.Iterator() do
				if not istable(hg.playerInfo[ply:SteamID()]) then
					local muted = hg.playerInfo[ply:SteamID()]
					hg.playerInfo[ply:SteamID()] = {}
					hg.playerInfo[ply:SteamID()][1] = muted
					hg.playerInfo[ply:SteamID()][2] = 1
				end

				if hg.playerInfo[ply:SteamID()] then
					ply:SetMuted(hg.playerInfo[ply:SteamID()][1])
					ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
				end
			end	
		end
	end
end)

hg.muteall = false
hg.mutespect = false

hook.Add("Player Getup", "nomorespect", function(ply)
	if not hg.mutespect then return end

	ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
end)

hook.Add("Player_Death", "fixSpectatorVoiceMute", function(ply)
	if not hg.mutespect then return end

	ply:SetVoiceVolumeScale(0)
end)

hook.Add("Player_Death", "fixSpectatorVoiceEffect", function(ply)
	if eightbit and eightbit.EnableEffect and ply.UserID then
		eightbit.EnableEffect(ply:UserID(), 0)
	end
end)

local UI = hg.UI
local C = UI.C
local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end

local function PlayerName(ply)
	if not IsValid(ply) then return "He quited..." end
	return ply:Name() or "He quited..."
end

local function GetMuteIcon(ply)
	return (IsValid(ply) and ply:IsMuted()) and "icon16/sound_mute.png" or "icon16/sound.png"
end

local function OpenPlayerSoundSettingsUI(anchor, ply)
	if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then
		addToPlayerInfo(ply, false, 1)
	end

	local box = vgui.Create("DPanel")
	local bw, bh = U(260), U(150)
	box:SetSize(bw, bh)
	local mx, my = gui.MouseX(), gui.MouseY()
	box:SetPos(math.Clamp(mx, 0, ScrW() - bw), math.Clamp(my, 0, ScrH() - bh))
	box:MakePopup()
	box:SetKeyboardInputEnabled(false)
	box:SetAlpha(0)
	box:AlphaTo(255, 0.1, 0)
	box:SetZPos(32767)
	box.Paint = function(_, w, h)
		surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
		UI.Outline(0, 0, w, h, C.lineHi)
		UI.Brackets(0, 0, w, h, C.white, U(8))
		draw.SimpleText("VOICE", "ZUI_Caps", U(16), U(20), C.textMut, 0, 1)
		draw.SimpleText(string.upper(PlayerName(ply)), "ZUI_Head", U(16), U(42), C.white, 0, 1)
	end

	local function Close()
		if IsValid(box) then
			box:AlphaTo(0, 0.08, 0, function() if IsValid(box) then box:Remove() end end)
		end
	end

	box.Think = function(s)
		if not s:IsHovered() and not s:IsChildHovered() and (input.IsMouseDown(MOUSE_LEFT) or input.IsMouseDown(MOUSE_RIGHT)) then
			Close()
		end
	end

	local muteRow = UI.Cell(box, {
		nodock = true,
		title = "Muted",
		right = function() return ply:IsMuted() and "YES" or "NO" end,
		tall = U(38),
		selected = function() return ply:IsMuted() end,
		disabled = function() return hg.muteall or hg.mutespect end,
		onClick = function()
			ply:SetMuted(not ply:IsMuted())
			addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
			if IsValid(anchor) then anchor.Icon = GetMuteIcon(ply) end
		end,
	})
	muteRow:SetPos(U(14), U(62))
	muteRow:SetSize(bw - U(28), U(38))

	local slider = UI.Slider(box, function()
		return hg.playerInfo[ply:SteamID()][2] * 100
	end, function(v)
		if not IsValid(ply) then return end
		if hg.muteall or (hg.mutespect and not ply:Alive()) then return end
		hg.playerInfo[ply:SteamID()][2] = v / 100
		ply:SetVoiceVolumeScale(v / 100)
		addToPlayerInfo(ply, ply:IsMuted(), v / 100)
	end, 0, 100, 0)
	slider:SetPos(U(14), U(112))
	slider:SetSize(bw - U(28) - U(48), U(28))

	local pct = vgui.Create("DPanel", box)
	pct:SetPos(bw - U(14) - U(44), U(112))
	pct:SetSize(U(44), U(28))
	pct.Paint = function(_, w, h)
		draw.SimpleText(math.Round(hg.playerInfo[ply:SteamID()][2] * 100) .. "%", "ZUI_Mono", w, h / 2, C.text, 2, 1)
	end
end

local function ToggleButton(parent, label, getState, onClick)
	local b = vgui.Create("DButton", parent)
	b:SetText("")
	b:SetCursor("hand")
	b.Hov, b.On = 0, 0
	b.OnCursorEntered = function() UI.SndHover() end
	b.DoClick = function() UI.SndClick() onClick(b) end
	b.Paint = function(s, w, h)
		local on = getState()
		s.Hov = UI.Smooth(s.Hov, s:IsHovered() and 1 or 0, 14)
		s.On = UI.Smooth(s.On, on and 1 or 0, 12)
		surface.SetDrawColor(UI.Mix(math.max(s.Hov * 0.8, s.On), C.bg1, on and C.bg3 or C.bg2))
		surface.DrawRect(0, 0, w, h)
		UI.Outline(0, 0, w, h, UI.Mix(math.max(s.Hov, s.On), C.line, C.lineHi))
		local rail = math.max(s.On, s.Hov * 0.55)
		surface.SetDrawColor(C.white)
		surface.DrawRect(0, h * (0.5 - 0.5 * rail), U(2), h * rail)
		draw.SimpleText(string.upper(label), "ZUI_Caps", U(14), h / 2, UI.Mix(math.max(s.Hov, s.On), C.textDim, C.white), 0, 1)
		draw.SimpleText(on and "ON" or "OFF", "ZUI_Caps", w - U(12), h / 2, on and C.white or C.textMut, 2, 1)
		if s.Hov > 0.02 then UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 180 * s.Hov), U(6)) end
	end
	return b
end

local function BuildPlayerRow(scroll, ply, spectator)
	local row = vgui.Create("DButton", scroll)
	row:Dock(TOP)
	row:SetTall(U(54))
	row:DockMargin(0, 0, U(8), U(4))
	row:SetText("")
	row:SetCursor("hand")
	row.Hov = 0
	row.OnCursorEntered = function() UI.SndHover() end

	row.Paint = function(s, w, h)
		if not IsValid(ply) then return end
		s.Hov = UI.Smooth(s.Hov, s:IsHovered() and 1 or 0, 12)
		local isMe = ply == LocalPlayer()
		local alive = ply:Alive()

		surface.SetDrawColor(UI.Mix(s.Hov, C.bg1, C.bg2)) surface.DrawRect(0, 0, w, h)
		UI.Outline(0, 0, w, h, UI.Mix(s.Hov, C.line, C.lineHi))

		local railA = isMe and 255 or (spectator and 30 or (alive and 110 or 40))
		surface.SetDrawColor(255, 255, 255, railA)
		surface.DrawRect(0, 0, U(2), h)

		local nameCol = UI.Mix(s.Hov, (spectator or not alive) and C.textDim or C.text, C.white)
		local textX = U(70)
		draw.SimpleText(string.upper(PlayerName(ply)), "ZUI_Body", textX, h / 2 - (isMe and U(8) or 0), nameCol, 0, 1)
		if isMe then
			draw.SimpleText("YOU", "ZUI_Caps", textX, h / 2 + U(11), C.textMut, 0, 1)
		end

		if not spectator and not alive then
			draw.SimpleText("DEAD", "ZUI_Caps", w - U(140), h / 2, C.bad, 2, 1)
		end

		draw.SimpleText(ply:Ping() .. " ms", "ZUI_Mono", w - U(64), h / 2, C.textDim, 2, 1)

		if s.Hov > 0.02 then UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 170 * s.Hov), U(7)) end
	end

	local av = vgui.Create("AvatarImage", row)
	av:SetSize(U(36), U(36))
	av:SetPos(U(16), (U(54) - U(36)) / 2)
	av:SetMouseInputEnabled(false)
	if not ply:IsBot() then av:SetPlayer(ply, 64) end
	av.PaintOver = function(_, w, h) UI.Outline(0, 0, w, h, C.lineHi) end

	local snd = vgui.Create("DButton", row)
	snd:SetText("")
	snd:SetCursor("hand")
	snd:SetSize(U(30), U(30))
	snd.Icon = GetMuteIcon(ply)
	snd.Hov = 0
	snd.OnCursorEntered = function() UI.SndHover() end
	snd.DoClick = function(self) UI.SndClick() OpenPlayerSoundSettingsUI(self, ply) end
	snd.Paint = function(s, w, h)
		s.Hov = UI.Smooth(s.Hov, s:IsHovered() and 1 or 0, 14)
		surface.SetDrawColor(UI.Mix(s.Hov, C.bg0, C.bg3)) surface.DrawRect(0, 0, w, h)
		UI.Outline(0, 0, w, h, UI.Mix(s.Hov, C.line, C.lineMax))
		s.Icon = GetMuteIcon(ply)
		surface.SetMaterial(Material(s.Icon))
		surface.SetDrawColor(255, 255, 255, 200 + 55 * s.Hov)
		surface.DrawTexturedRect(w / 2 - U(8), h / 2 - U(8), U(16), U(16))
	end
	ply.soundButton = snd
	row.PerformLayout = function(s, w, h) snd:SetPos(w - U(14) - U(30), (h - U(30)) / 2) end

	row.DoClick = function()
		UI.SndClick()
		if ply:IsBot() then chat.AddText(Color(255, 0, 0), "no, you can't") return end
		gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
	end

	row.DoRightClick = function()
		UI.SndClick()
		local Menu = DermaMenu()
		Menu:AddOption("Account", function() zb.Experience.AccountMenu(ply) end)
		Menu:AddOption("Copy SteamID", function() SetClipboardText(ply:SteamID()) end)
		Menu:Open()
	end

	return row
end

function GM:ScoreboardShow()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end

	scoreBoardMenu = vgui.Create("DPanel")
	local sb = scoreBoardMenu
	sb:SetSize(ScrW(), ScrH())
	sb:SetPos(0, 0)
	sb:MakePopup()
	sb:SetKeyboardInputEnabled(false)
	sb:SetAlpha(0)
	sb:AlphaTo(255, 0.15, 0)
	sb.Born = SysTime()
	sb.Paint = function(s, w, h)
		if hg.DrawBlur then hg.DrawBlur(s, 5) end
		UI.PaintBackdrop(w, h, 0.8)
	end
	sb.Close = function(s)
		if s.Closing then return end
		s.Closing = true
		s:AlphaTo(0, 0.12, 0, function() if IsValid(s) then s:Remove() end end)
	end

	local pad = U(28)
	local ServerName = GetHostName() or "ZCity | Developer Server | #01"

	local top = vgui.Create("DPanel", sb)
	top:Dock(TOP)
	top:SetTall(U(88))
	top.Paint = function(_, w, h)
		local a = math.Clamp((SysTime() - sb.Born) / 0.35, 0, 1)
		local e = 1 - (1 - a) ^ 3
		surface.SetDrawColor(C.line) surface.DrawRect(0, h - 1, w, 1)
		surface.SetDrawColor(C.white) surface.DrawRect(0, h - 1, w * e * 0.06, 1)

		draw.SimpleText("01", "ZUI_Mono", pad, h / 2 - U(2), C.textMut, 0, 1)
		draw.SimpleText(string.upper(ServerName), "ZUI_Title", pad + U(34), h / 2 - U(9), UI.Alpha(C.white, 255 * e), 0, 1)

		local playing, spec = 0, 0
		for _, p in player.Iterator() do
			if p:Team() == TEAM_SPECTATOR then spec = spec + 1 else playing = playing + 1 end
		end
		draw.SimpleText(playing .. " playing   ·   " .. spec .. " spectating", "ZUI_Small", pad + U(34), h / 2 + U(16), C.textDim, 0, 1)

		local tick = math.Round(1 / math.max(engine.ServerFrameTime(), 0.0001))
		local cols = {
			{"TICK", tostring(tick)},
			{"PING", tostring(IsValid(LocalPlayer()) and LocalPlayer():Ping() or 0)},
			{"MAP", string.NiceName(game.GetMap())},
		}
		local x = w - pad
		for i = #cols, 1, -1 do
			local c = cols[i]
			surface.SetFont("ZUI_MonoBig")
			local vw = surface.GetTextSize(c[2])
			surface.SetFont("ZUI_Caps")
			local lw = surface.GetTextSize(c[1])
			local cw = math.max(vw, lw)
			draw.SimpleText(c[1], "ZUI_Caps", x, h / 2 - U(16), C.textMut, 2, 1)
			draw.SimpleText(c[2], "ZUI_MonoBig", x, h / 2 + U(8), C.white, 2, 1)
			x = x - cw - U(28)
			if i > 1 then
				surface.SetDrawColor(C.line)
				surface.DrawRect(x + U(12), U(24), 1, h - U(48))
			end
		end
	end

	local foot = vgui.Create("DPanel", sb)
	foot:Dock(BOTTOM)
	foot:SetTall(U(48))
	foot.Paint = function(_, w, h)
		surface.SetDrawColor(C.line) surface.DrawRect(0, 0, w, 1)
		draw.SimpleText("ZC VERSION  " .. tostring(hg.Version), "ZUI_Caps", pad, h / 2, C.textMut, 0, 1)
		draw.SimpleText("Z-CITY", "ZUI_Caps", w - pad, h / 2, C.textMut, 2, 1)
	end

	local btnRow = vgui.Create("DPanel", foot)
	btnRow:Dock(FILL)
	btnRow:DockMargin(U(200), U(6), U(120), U(6))
	btnRow.Paint = function() end

	local mutespect = ToggleButton(btnRow, "Mute spectators", function() return hg.mutespect end, function()
		hg.mutespect = not hg.mutespect
		for _, ply in player.Iterator() do
			if ply:Alive() then continue end
			if hg.mutespect then
				ply:SetVoiceVolumeScale(0)
			else
				ply:SetVoiceVolumeScale(not hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
			end
		end
	end)
	mutespect:Dock(RIGHT)
	mutespect:SetWide(U(230))
	mutespect:DockMargin(U(8), 0, 0, 0)

	local muteall = ToggleButton(btnRow, "Mute all", function() return hg.muteall end, function()
		hg.muteall = not hg.muteall
		for _, ply in player.Iterator() do
			if hg.muteall then
				ply:SetVoiceVolumeScale(0)
			else
				ply:SetVoiceVolumeScale((not hg.mutespect or ply:Alive()) and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
			end
		end
	end)
	muteall:Dock(RIGHT)
	muteall:SetWide(U(190))

	local body = vgui.Create("DPanel", sb)
	body:Dock(FILL)
	body:DockMargin(pad, U(18), pad, U(14))
	body.Paint = function() end

	local isSpec = LocalPlayer():Team() == TEAM_SPECTATOR

	local function Column(dockSide, title, index)
		local col = vgui.Create("DPanel", body)
		col:Dock(dockSide == "left" and LEFT or FILL)
		col.Paint = function(_, w, h) end

		local head = vgui.Create("DPanel", col)
		head:Dock(TOP)
		head:SetTall(U(44))
		head:DockMargin(0, 0, U(8), U(6))
		head.Count = 0
		head.Paint = function(s, w, h)
			draw.SimpleText(index, "ZUI_Caps", 0, h / 2, C.textMut, 0, 1)
			draw.SimpleText(string.upper(title), "ZUI_Head", U(30), h / 2, C.white, 0, 1)
			draw.SimpleText(string.format("%02d", s.Count), "ZUI_MonoBig", w, h / 2, C.textDim, 2, 1)
			surface.SetDrawColor(C.line) surface.DrawRect(0, h - 1, w, 1)
		end

		local scroll = vgui.Create("DScrollPanel", col)
		scroll:Dock(FILL)
		scroll.Paint = function() end
		UI.StyleScroll(scroll)
		return col, head, scroll
	end

	local colL, headL, scrollL = Column("left", "Players", "A")
	local colR, headR, scrollR = Column("fill", "Spectators", "B")

	local joinBtn = UI.Button(headL, isSpec and "Join" or "Spectate", function()
		net.Start("ZB_SpecMode")
			net.WriteBool(not isSpec and true or false)
		net.SendToServer()
		if IsValid(scoreBoardMenu) then scoreBoardMenu:Remove() scoreBoardMenu = nil end
	end, isSpec and "solid" or "ghost")
	joinBtn:Dock(RIGHT)
	joinBtn:SetWide(U(110))
	joinBtn:DockMargin(0, U(6), U(70), U(6))

	body.PerformLayout = function(s, w, h)
		colL:SetWide(math.floor(w / 2) - U(8))
		colL:DockMargin(0, 0, U(16), 0)
	end

	local disappearance = lply:GetNetVar("disappearance", nil)
	local fear = CurrentRound() and CurrentRound().name == "fear"
	local nPlay, nSpec = 0, 0

	for _, ply in player.Iterator() do
		if fear and not ply:Alive() then continue end
		if disappearance and ply ~= lply then continue end
		if ply:Team() == TEAM_SPECTATOR then
			BuildPlayerRow(scrollR, ply, true)
			nSpec = nSpec + 1
		else
			BuildPlayerRow(scrollL, ply, false)
			nPlay = nPlay + 1
		end
	end
	headL.Count, headR.Count = nPlay, nSpec

	if nPlay == 0 then
		local e = vgui.Create("DLabel", scrollL)
		e:Dock(TOP) e:SetTall(U(44)) e:SetFont("ZUI_Small") e:SetTextColor(C.textMut)
		e:SetContentAlignment(5) e:SetText("NOBODY IS PLAYING")
	end
	if nSpec == 0 then
		local e = vgui.Create("DLabel", scrollR)
		e:Dock(TOP) e:SetTall(U(44)) e:SetFont("ZUI_Small") e:SetTextColor(C.textMut)
		e:SetContentAlignment(5) e:SetText("NO SPECTATORS")
	end

	return true
end

function GM:ScoreboardHide()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Close()
		scoreBoardMenu = nil
	end
end

hook.Add("HUDPaint", "FUCKINGSAMENAMEUSEDINHOOKFUCKME", function()
	if LocalPlayer():Alive() then return end
	local spect = LocalPlayer():GetNWEntity("spect")
	if not IsValid(spect) then return end
	if viewmode == 3 then return end

	local w, h = ScrW(), ScrH()
	local bw, bh = U(420), U(76)
	local x, y = (w - bw) / 2, h - bh - U(60)

	surface.SetDrawColor(C.bg0) surface.DrawRect(x, y, bw, bh)
	UI.Outline(x, y, bw, bh, C.lineHi)
	UI.Brackets(x, y, bw, bh, C.white, U(8))
	surface.SetDrawColor(C.white) surface.DrawRect(x, y, U(2), bh)

	draw.SimpleText("SPECTATING", "ZUI_Caps", x + U(20), y + U(18), C.textMut, 0, 1)
	draw.SimpleText(string.upper(spect:Name()), "ZUI_Title", x + U(20), y + U(42), C.white, 0, 1)
	draw.SimpleText(spect:GetPlayerName() or "", "ZUI_Small", x + U(20), y + U(63), C.textDim, 0, 1)

	local modes = { [1] = "FIRST PERSON", [2] = "THIRD PERSON", [3] = "FREE" }
	draw.SimpleText(modes[viewmode] or "", "ZUI_Caps", x + bw - U(20), y + U(18), C.textDim, 2, 1)
end)

if CLIENT then
	net.Receive("PunishLightningEffect", function()
		local target = net.ReadEntity()
		if not IsValid(target) then return end
		local dlight = DynamicLight(target:EntIndex())
		if dlight then
			dlight.pos = target:GetPos()
			dlight.r = 126
			dlight.g = 139
			dlight.b = 212
			dlight.brightness = 1
			dlight.Decay = 1000
			dlight.Size = 500
			dlight.DieTime = CurTime() + 1
		end
	end)
end

local lightningMaterial = Material("sprites/lgtning")

net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
	if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20,20),math.Rand(-20,20),math.Rand(-20,20))
    end
    hook.Add( "PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255,255,255,255))
        end
        render.EndBeam()
        render.OverrideBlend( false )
    end )
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint( name, delay )
	return false
end

local snakeGameOpen = false

concommand.Add("zb_snake", function()
    if snakeGameOpen then
        print("[Snake Game] Игра уже запущена!")
        return
    end

    local frame = vgui.Create("ZFrame")
    frame:SetTitle("Snake Game")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)  
    snakeGameOpen = true  

    local gridSize = 20
    local gridWidth = 19  
    local gridHeight = 19  
    local snakePanel = vgui.Create("DPanel", frame)
    snakePanel:SetSize(380, 380)
    snakePanel:SetPos(10, 10)

    frame:SetDraggable(true)
    frame:ShowCloseButton(true)

    local snake = {
        {x = 10, y = 10},
    }
	
    local snakeDirection = "RIGHT"
    local food = nil
    local score = 0
    local gameRunning = true

    local function spawnFood()
        local validPosition = false
        while not validPosition do
            local newFood = {
                x = math.random(0, gridWidth - 1), 
                y = math.random(0, gridHeight - 1)
            }
            validPosition = true

            for _, segment in ipairs(snake) do
                if segment.x == newFood.x and segment.y == newFood.y then
                    validPosition = false  
                    break
                end
            end

            if validPosition then
                food = newFood
            end
        end
    end

    local function drawSnake()
        surface.SetDrawColor(0, 255, 0, 255)
        for _, segment in ipairs(snake) do
            surface.DrawRect(segment.x * gridSize, segment.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

    local function drawFood()
        if food then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(food.x * gridSize, food.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

    local function moveSnake()
        if not gameRunning then return end

        local head = table.Copy(snake[1])

        if snakeDirection == "UP" then
            head.y = head.y - 1
        elseif snakeDirection == "DOWN" then
            head.y = head.y + 1
        elseif snakeDirection == "LEFT" then
            head.x = head.x - 1
        elseif snakeDirection == "RIGHT" then
            head.x = head.x + 1
        end

        if head.x < 0 or head.x >= gridWidth or head.y < 0 or head.y >= gridHeight then
            gameRunning = false
        end

        for _, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then
                gameRunning = false
            end
        end

        table.insert(snake, 1, head)

        if food and head.x == food.x and head.y == food.y then
            score = score + 1
            spawnFood()  
        else
            table.remove(snake)
        end
    end

    local function resetGame()
        snake = {{x = 10, y = 10}}
        snakeDirection = "RIGHT"
        score = 0
        gameRunning = true
        spawnFood()  
    end

    function snakePanel:Paint(w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)

        if gameRunning then
            drawSnake()
            drawFood()
        else
            draw.SimpleText("Game Over! Press R to restart", "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText("Score: " .. score, "DermaDefault", 10, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    function frame:OnKeyCodePressed(key)
        if key == KEY_W and snakeDirection ~= "DOWN" then
            snakeDirection = "UP"
        elseif key == KEY_S and snakeDirection ~= "UP" then
            snakeDirection = "DOWN"
        elseif key == KEY_A and snakeDirection ~= "RIGHT" then
            snakeDirection = "LEFT"
        elseif key == KEY_D and snakeDirection ~= "LEFT" then
            snakeDirection = "RIGHT"
        elseif key == KEY_R then
            resetGame()
        end
    end

    timer.Create("SnakeGameTimer", 0.2, 0, function()
        if gameRunning then
            moveSnake()
        end
        snakePanel:InvalidateLayout(true)
    end)

    frame.OnClose = function()
        timer.Remove("SnakeGameTimer")
        snakeGameOpen = false  
    end

    resetGame()
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
	if ply == LocalPlayer() then
		system.FlashWindow()
	end
end)