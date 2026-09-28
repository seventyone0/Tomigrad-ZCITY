MODE.name = "tdm"

local MODE = MODE

net.Receive("tdm_start",function()
    surface.PlaySound("csgo_round.wav")
	zb.rtype = net.ReadString()
	hg.DynaMusic:Start( "swat4" )
	zb.RemoveFade()
end)

local teams = {
	[0] = {
		objective = "",
		name = "a Terrorist",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},
	[1] = {
		objective = "",
		name = "a Counter Terrorist",
		color1 = Color(0,120,190),
		color2 = Color(0,120,190)
	},
}

hook.Add( "StartCommand", "TDM_DisallowMoveOrShoting", function( ply, mv )
	if zb.CROUND == "tdm" and (zb.ROUND_START or 0) + 20 > CurTime() then 
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
	end
end)

function MODE:RenderScreenspaceEffects()
    local StartTime = zb.ROUND_START or CurTime()

	if StartTime + 7.5 < CurTime() then return end

    local fade = math.Clamp(StartTime + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

local function tdm_ease_out(x)
	return 1 - (1 - x) ^ 3
end

function MODE:HUDPaint()
    local StartTime = zb.ROUND_START or CurTime()

	self:AddHudPaint()

	local t = CurTime() - StartTime

	if StartTime + 20 > CurTime() then
		draw.SimpleText(
			string.FormattedTime(
				StartTime + 20 - CurTime(),
				"%02i:%02i:%02i"
			),
			"ZB_HomicideMedium",
			sw * 0.5,
			sh * 0.95,
			Color(255,255,255),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)

		draw.SimpleText(
			"Press F3 to open buymenu",
			"ZB_HomicideMedium",
			sw * 0.5,
			sh * 0.9,
			Color(255,255,255),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)
	else
		local time = string.FormattedTime(
			math.max(
				StartTime + (zb.ROUND_TIME or 400) - CurTime(),
				0
			),
			"%02i:%02i:%02i"
		)

		draw.SimpleText(
			time,
			"ZB_HomicideMedium",
			sw * 0.5,
			sh * 0.95,
			ColorObj,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)
	end

    if StartTime + 20 < CurTime() then return end

	if not lply:Alive() then return end

	zb.RemoveFade()

	local fade = math.Clamp(StartTime + 8 - CurTime(),0,1)
	local team_ = lply:Team()

	local teamData = teams[team_]

	if not teamData then return end

	local elements = {}

	local function add(text, font, color, x, y, delay, notilt)
		elements[#elements + 1] = {
			text = text,
			font = font,
			r = color.r,
			g = color.g,
			b = color.b,
			x = x,
			y = y,
			delay = delay or 0,
			notilt = notilt
		}
	end

	add(
		"ZBattle | "..(self.PrintName or "Team Deathmatch"),
		"ZB_HomicideMediumLarge",
		Color(0,162,255),
		sw * 0.5,
		sh * 0.1,
		0
	)

	add(
		"You are "..teamData.name,
		"ZB_HomicideMediumLarge",
		teamData.color1,
		sw * 0.5,
		sh * 0.5,
		0.7
	)

	add(
		teamData.objective,
		"ZB_HomicideMedium",
		teamData.color2,
		sw * 0.5,
		sh * 0.9,
		1.4
	)

	if hg.PluvTown.Active then
		add(
			"SOMEWHERE IN PLUVTOWN",
			"ZB_ScrappersLarge",
			Color(0,0,0),
			sw / 2,
			sh * 0.44 - ScreenScale(2),
			1.4
		)
	end

	for i, el in ipairs(elements) do
		local appear = tdm_ease_out(
			math.Clamp((t - el.delay) / 1.5, 0, 1)
		)

		local alpha = 255 * appear * fade

		if alpha > 1 then
			local slide = 1 - appear

			local x = el.x
			local y = el.y

			y = y - slide * ScreenScale(120)

			draw.SimpleText(
				el.text,
				el.font,
				x,
				y,
				Color(
					el.r,
					el.g,
					el.b,
					alpha
				),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER
			)
		end
	end

	if hg.PluvTown.Active then
		local appear = tdm_ease_out(
			math.Clamp((t - 1.4) / 1.5, 0, 1)
		)

		local imageFade = 255 * appear * fade

		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(
			255,
			255,
			255,
			math.random(175, 255) * imageFade / 255 / 2
		)

		surface.DrawTexturedRect(
			sw * 0.25,
			sh * 0.44 - ScreenScale(15),
			sw / 2,
			ScreenScale(30)
		)
	end
end

function MODE:AddHudPaint()
end

local CreateEndMenu

net.Receive("tdm_roundend",function()
    CreateEndMenu()
end)

local colGray = Color(85,85,85,255)
local colRed = Color(130,10,10)
local colRedUp = Color(160,30,30)

local colBlue = Color(10,10,160)
local colBlueUp = Color(40,40,160)
local col = Color(255,255,255,255)

local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(255,255,255)

local colorBG = Color(55,55,55,255)
local colorBGBlacky = Color(40,40,40,255)

local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")

    surface.PlaySound("ambient/alarms/warningbell1.wav")

	local sizeX,sizeY = ScrW() / 2.5 ,ScrH() / 1.2
	local posX,posY = ScrW() / 1.3 - sizeX / 2,ScrH() / 2 - sizeY / 2

	hmcdEndMenu:SetPos(posX,posY)
	hmcdEndMenu:SetSize(sizeX,sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton",hmcdEndMenu)

	closebutton:SetPos(5,5)
	closebutton:SetSize(ScrW() / 20,ScrH() / 30)
	closebutton:SetText("")
	
	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self,w,h)
		surface.SetDrawColor(122,122,122,255)
        surface.DrawOutlinedRect(0,0,w,h,2.5)

		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r,col.g,col.b,col.a)

		local lengthX,lengthY = surface.GetTextSize("Close")

		surface.SetTextPos(lengthX - lengthX/1.1,4)
		surface.DrawText("Close")
	end

    hmcdEndMenu.Paint = function(self,w,h)
		BlurBackground(self)

		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r,col.g,col.b,col.a)

		local lengthX,lengthY = surface.GetTextSize("Players:")

		surface.SetTextPos(w / 2 - lengthX/2,20)
		surface.DrawText("Players:")

		surface.SetDrawColor(255,0,0,128)
        surface.DrawOutlinedRect(0,0,w,h,2.5)
	end

	local DScrollPanel = vgui.Create("DScrollPanel",hmcdEndMenu)

	DScrollPanel:SetPos(10,80)
	DScrollPanel:SetSize(sizeX - 20,sizeY - 90)

	function DScrollPanel:Paint(w,h)
		BlurBackground(self)

		surface.SetDrawColor(255,0,0,128)
        surface.DrawOutlinedRect(0,0,w,h,2.5)
	end

	for i,ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local but = vgui.Create("DButton",DScrollPanel)

		but:SetSize(100,50)
		but:Dock(TOP)
		but:DockMargin(8,6,8,-1)
		but:SetText("")

		but.Paint = function(self,w,h)
            local col1 = (ply:Alive() and colRed) or colGray
            local col2 = (ply:Alive() and colRedUp) or colSpect1

			surface.SetDrawColor(col1.r,col1.g,col1.b,col1.a)
			surface.DrawRect(0,0,w,h)

			surface.SetDrawColor(col2.r,col2.g,col2.b,col2.a)
			surface.DrawRect(0,h/2,w,h/2)

            local col = ply:GetPlayerColor():ToColor()

			surface.SetFont("ZB_InterfaceMediumLarge")

			local lengthX,lengthY = surface.GetTextSize(
				ply:GetPlayerName() or "He quited..."
			)
			
			surface.SetTextColor(0,0,0,255)
			surface.SetTextPos(
				w / 2 + 1,
				h/2 - lengthY/2 + 1
			)

			surface.DrawText(
				ply:GetPlayerName() or "He quited..."
			)

			surface.SetTextColor(col.r,col.g,col.b,col.a)

			surface.SetTextPos(
				w / 2,
				h/2 - lengthY/2
			)

			surface.DrawText(
				ply:GetPlayerName() or "He quited..."
			)

            local col = colSpect2

			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r,col.g,col.b,col.a)

			local lengthX,lengthY = surface.GetTextSize(
				ply:GetPlayerName() or "He quited..."
			)

			surface.SetTextPos(
				15,
				h/2 - lengthY/2
			)

			surface.DrawText(
				(ply:Name() .. (not ply:Alive() and " - died" or "")) or "He quited..."
			)

			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r,col.g,col.b,col.a)

			local lengthX,lengthY = surface.GetTextSize(
				ply:Frags() or "He quited..."
			)

			surface.SetTextPos(
				w - lengthX - 15,
				h/2 - lengthY/2
			)

			surface.DrawText(
				ply:Frags() or "He quited..."
			)
		end

		function but:DoClick()
			if ply:IsBot() then
				chat.AddText(Color(255,0,0),"no, you can't")
				return
			end

			gui.OpenURL(
				"https://steamcommunity.com/profiles/"..ply:SteamID64()
			)
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end

surface.CreateFont("ZB_TDM_MENU", {
    font = "Bahnschrift",
    size = ScreenScale(12),
    extended = true,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_TDM_DESC", {
    font = "Bahnschrift",
    size = ScreenScale(7),
    extended = true,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_TDM_CATEGORY", {
    font = "Bahnschrift",
    size = ScreenScale(6),
    extended = true,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_TDM_DESCSMALL", {
    font = "Bahnschrift",
    size = ScreenScale(5),
    extended = true,
    weight = 400,
    antialias = true
})

local function BuyFit(text, font, maxW)
	surface.SetFont(font)
	if surface.GetTextSize(text) <= maxW then return text end
	while #text > 1 and surface.GetTextSize(text .. "…") > maxW do
		text = string.sub(text, 1, #text - 1)
	end
	return text .. "…"
end

local function BuyIconPath(weapon, ent)
	if weapon ~= nil then
		local ico = weapon.WepSelectIcon2
		if type(ico) == "IMaterial" and ico:GetName() then
			return ico:GetName() .. ".png"
		end
		if isstring(weapon.IconOverride) and weapon.IconOverride ~= "" then
			return weapon.IconOverride
		end
	end
	if ent and ent.t and isstring(ent.t.IconOverride) and ent.t.IconOverride ~= "" then
		return ent.t.IconOverride
	end
end

local function BuyAmmoInfo(weapon)
	if not weapon then return end

	local primary = weapon.Primary
	local ammo = primary and primary.Ammo ~= "none" and primary.Ammo or weapon.Ammo

	if not ammo then
		local base = weapon.Base and weapons.GetStored(weapon.Base)
		ammo = base and base.Primary and base.Primary.Ammo
	end

	if not ammo or not hg.ammotypeshuy or not hg.ammotypeshuy[ammo] then return end

	local ammoClass = "ent_ammo_" .. hg.ammotypeshuy[ammo].name
	local ammoItems = MODE.BuyItems and MODE.BuyItems["Ammo"]
	if not istable(ammoItems) then return end

	for itemName, ammoItem in pairs(ammoItems) do
		if istable(ammoItem) and ammoItem.ItemClass == ammoClass then
			return ammo, itemName
		end
	end
end

local function BuyPurchase(tbl)
	net.Start("tdm_buyitem")
		net.WriteTable(tbl)
	net.SendToServer()
end

local function OpenBuyMenu()
	if IsValid(TDM_OpenedBuyMenu) then
		TDM_OpenedBuyMenu:Remove()
	end
	TDM_OpenedBuyMenu = nil

	local StartTime = zb.ROUND_START or CurTime()

	if not LocalPlayer():Alive() or StartTime + 40 < CurTime() then
		return
	end

	local UI = hg.UI
	local C = UI.C
	local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end

	local pad = U(22)
	local headH = U(88)
	local footH = U(34)

	local Frame = vgui.Create("ZFrame")
	TDM_OpenedBuyMenu = Frame

	Frame:SetSize(math.min(math.max(ScrW() * 0.35, U(620)), ScrW() - U(40)), ScrH() * 0.85)
	Frame:Center()
	Frame:MakePopup()
	Frame:SetTitle("")
	Frame:ShowCloseButton(false)
	Frame:SetDraggable(false)
	Frame:DockPadding(0, 0, 0, 0)
	Frame.Born = SysTime()

	Frame.Paint = function(s, w, h)
		if hg.DrawBlur then hg.DrawBlur(s, 5) end
		surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
		local step = U(28)
		surface.SetDrawColor(255, 255, 255, 4)
		for x = 0, w, step do surface.DrawRect(x, 0, 1, h) end
		for y = 0, h, step do surface.DrawRect(0, y, w, 1) end
		UI.Outline(0, 0, w, h, C.lineHi)
		UI.Brackets(0, 0, w, h, C.lineMax, U(10))
	end

	local baseThink = Frame.Think
	Frame.Think = function(s)
		if baseThink then baseThink(s) end
		if not LocalPlayer():Alive() or StartTime + 40 < CurTime() then
			s:Close()
		end
	end

	local head = vgui.Create("DPanel", Frame)
	head:Dock(TOP)
	head:SetTall(headH)
	head.Paint = function(_, w, h)
		local a = math.Clamp((SysTime() - Frame.Born) / 0.35, 0, 1)
		local e = 1 - (1 - a) ^ 3

		surface.SetDrawColor(C.line) surface.DrawRect(0, h - 1, w, 1)
		surface.SetDrawColor(C.white) surface.DrawRect(0, h - 1, w * e * 0.06, 1)

		draw.SimpleText("BUY MENU", "ZUI_Title", pad, h / 2 - U(9), UI.Alpha(C.white, 255 * e), 0, 1)
		draw.SimpleText("Spend your cash before the timer runs out.", "ZUI_Small", pad, h / 2 + U(16), C.textDim, 0, 1)

		local timeLeft = math.max(StartTime + 40 - CurTime(), 0)
		local cash = LocalPlayer():GetNWInt("TDM_Money", 0)
		local timeStr = string.format("%02i:%02i", math.floor(timeLeft / 60), math.floor(timeLeft % 60))

		local rx = w - pad - U(96) - U(26)
		draw.SimpleText("TIME LEFT", "ZUI_Caps", rx, h / 2 - U(16), C.textMut, 2, 1)
		draw.SimpleText(timeStr, "ZUI_MonoBig", rx, h / 2 + U(8), timeLeft < 10 and C.warn or C.white, 2, 1)

		surface.SetFont("ZUI_MonoBig")
		local tw = surface.GetTextSize("00:00")
		local cx = rx - tw - U(30)
		surface.SetDrawColor(C.line)
		surface.DrawRect(cx + U(15), U(24), 1, h - U(48))
		draw.SimpleText("CASH", "ZUI_Caps", cx, h / 2 - U(16), C.textMut, 2, 1)
		draw.SimpleText("$" .. cash, "ZUI_MonoBig", cx, h / 2 + U(8), C.good, 2, 1)
	end

	local closeBtn = UI.Button(head, "Close", function() Frame:Close() end)
	closeBtn:Dock(RIGHT)
	closeBtn:SetWide(U(96))
	closeBtn:DockMargin(0, U(26), pad, U(26))

	local foot = vgui.Create("DPanel", Frame)
	foot:Dock(BOTTOM)
	foot:SetTall(footH)
	foot.Paint = function(_, w, h)
		surface.SetDrawColor(C.line) surface.DrawRect(0, 0, w, 1)
		local x = pad
		local hints = { { "LMB", "buy" } }
		for _, hnt in ipairs(hints) do
			surface.SetFont("ZUI_Caps")
			local kw = surface.GetTextSize(hnt[1])
			UI.Outline(x, h / 2 - U(9), kw + U(12), U(18), C.lineHi)
			draw.SimpleText(hnt[1], "ZUI_Caps", x + U(6), h / 2, C.text, 0, 1)
			draw.SimpleText(hnt[2], "ZUI_Small", x + kw + U(20), h / 2, C.textDim, 0, 1)
			surface.SetFont("ZUI_Small")
			x = x + kw + U(20) + surface.GetTextSize(hnt[2]) + U(22)
		end
		draw.SimpleText("Z-CITY", "ZUI_Caps", w - pad, h / 2, C.textMut, 2, 1)
	end

	local body = vgui.Create("DPanel", Frame)
	body:Dock(FILL)
	body:DockMargin(pad, U(14), pad, U(10))
	body.Paint = function() end

	local tabBar = vgui.Create("DPanel", body)
	tabBar:Dock(TOP)
	tabBar:SetTall(U(50))
	tabBar:DockMargin(0, 0, 0, U(10))
	tabBar.Paint = function(_, w, h)
		surface.SetDrawColor(C.line) surface.DrawRect(0, h - 1, w, 1)
	end

	local tabButtons, panels = {}, {}
	local active

	local function SetActive(idx)
		if active == idx then return end
		active = idx
		for i, pnl in ipairs(panels) do
			local on = i == idx
			pnl:SetVisible(on)
			if on then
				pnl:SetAlpha(0)
				pnl:AlphaTo(255, 0.15, 0)
			end
		end
	end

	tabBar.PerformLayout = function(s, w, h)
		local n = #tabButtons
		if n == 0 then return end
		local cw = math.floor(w / n)
		for i, b in ipairs(tabButtons) do
			b:SetPos((i - 1) * cw, 0)
			b:SetSize(i == n and (w - (n - 1) * cw) or cw, h)
		end
	end

	local function MakeChip(parent, w, h, paintFn, onClick, tip)
		local b = vgui.Create("DButton", parent)
		b:SetText("")
		b:SetCursor("hand")
		b:SetSize(w, h)
		b.Hov = 0
		if tip then b:SetTooltip(tip) end
		b.OnCursorEntered = function() UI.SndHover() end
		b.DoClick = function() UI.SndClick() onClick() end
		b.Paint = function(s, bw, bh)
			s.Hov = UI.Smooth(s.Hov, s:IsHovered() and 1 or 0, 14)
			surface.SetDrawColor(UI.Mix(s.Hov, C.bg0, C.bg3)) surface.DrawRect(0, 0, bw, bh)
			UI.Outline(0, 0, bw, bh, UI.Mix(s.Hov, C.line, C.lineMax))
			paintFn(s, bw, bh)
			if s.Hov > 0.02 then
				UI.Brackets(0, 0, bw, bh, UI.Alpha(C.white, 180 * s.Hov), U(5))
			end
		end
		return b
	end

	local function BuildRow(scroll, catName, itemName, Item)
		local weapon = weapons.GetStored(Item.ItemClass)
		local ent = scripted_ents.GetStored(Item.ItemClass)
		local iconPath = BuyIconPath(weapon, ent)
		local iconMat = iconPath and Material(iconPath) or nil
		local boxed = (ent and ent.t and ent.t.IconOverride and true) or (weapon ~= nil and weapon.WepSelectIcon2box and true) or false
		local price = tonumber(Item.Price) or 0
		local nameText = string.upper(tostring(itemName))
		local textX = U(152)

		local row = vgui.Create("DPanel", scroll)
		row:Dock(TOP)
		row:SetTall(U(100))
		row:DockMargin(0, 0, U(8), U(6))
		row.Hov = 0
		row.Subs = {}

		row.Paint = function(s, w, h)
			local cx, cy = s:CursorPos()
			local inside = cx >= 0 and cy >= 0 and cx <= w and cy <= h and vgui.CursorVisible()
			s.Hov = UI.Smooth(s.Hov, inside and 1 or 0, 12)
			local hv = s.Hov
			local cash = LocalPlayer():GetNWInt("TDM_Money", 0)

			surface.SetDrawColor(UI.Mix(hv, C.bg1, C.bg2)) surface.DrawRect(0, 0, w, h)
			UI.Outline(0, 0, w, h, UI.Mix(hv, C.line, C.lineHi))
			surface.SetDrawColor(C.white)
			surface.DrawRect(0, h * (0.5 - 0.5 * hv), U(2), h * hv)

			local bx, by, bw, bh = U(10), U(10), U(124), h - U(20)
			surface.SetDrawColor(C.bg0) surface.DrawRect(bx, by, bw, bh)
			UI.Outline(bx, by, bw, bh, C.line)

			if iconMat and not iconMat:IsError() then
				local ix, iy, iw, ih = bx + U(6), by + U(6), bw - U(12), bh - U(12)
				surface.SetMaterial(iconMat)
				surface.SetDrawColor(255, 255, 255, 225 + 30 * hv)
				if boxed then
					local side = math.min(iw, ih)
					surface.DrawTexturedRect(ix + (iw - side) / 2, iy + (ih - side) / 2, side, side)
				else
					surface.DrawTexturedRect(ix, iy, iw, ih)
				end
			else
				draw.SimpleText("NO ICON", "ZUI_Caps", bx + bw / 2, by + bh / 2, C.textMut, 1, 1)
			end

			local shown = BuyFit(nameText, "ZUI_Head", w - textX - U(120))
			draw.SimpleText(shown, "ZUI_Head", textX, U(24), UI.Mix(hv, C.text, C.white), 0, 1)

			draw.SimpleText("PRICE", "ZUI_Caps", textX, U(46), C.textMut, 0, 1)
			surface.SetFont("ZUI_Caps")
			local pw = surface.GetTextSize("PRICE")
			draw.SimpleText("$" .. price, "ZUI_Mono", textX + pw + U(10), U(46), cash >= price and C.good or C.bad, 0, 1)

			if hv > 0.02 then
				UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 170 * hv), U(7))
			end
		end

		local buy = UI.Button(row, "Buy", function()
			if LocalPlayer():GetNWInt("TDM_Money", 0) < price then UI.SndDeny() end
			BuyPurchase({catName, itemName})
		end, "solid")
		buy:SetSize(U(92), U(36))
		buy.Think = function(s)
			s.Style = LocalPlayer():GetNWInt("TDM_Money", 0) >= price and "solid" or "danger"
		end

		local ammoName, ammoItem = BuyAmmoInfo(weapon)
		if ammoName and ammoItem then
			local label = "+ " .. string.upper(tostring(ammoName))
			surface.SetFont("ZUI_Caps")
			local tw = surface.GetTextSize(label)
			local chip = MakeChip(row, tw + U(24), U(28), function(s, bw, bh)
				draw.SimpleText(label, "ZUI_Caps", bw / 2, bh / 2, UI.Mix(s.Hov, C.textDim, C.white), 1, 1)
			end, function()
				BuyPurchase({"Ammo", ammoItem})
			end, "Buy ammo")
			row.Subs[#row.Subs + 1] = chip
		end

		if istable(Item.Attachments) and #Item.Attachments > 0 then
			for _, attachName in ipairs(Item.Attachments) do
				local ico = hg.attachmentsIcons and hg.attachmentsIcons[attachName]
				local mat = ico and Material(ico) or nil
				local chip = MakeChip(row, U(28), U(28), function(s, bw, bh)
					if mat and not mat:IsError() then
						surface.SetMaterial(mat)
						surface.SetDrawColor(255, 255, 255, 200 + 55 * s.Hov)
						surface.DrawTexturedRect(U(3), U(3), bw - U(6), bh - U(6))
					else
						draw.SimpleText("?", "ZUI_Caps", bw / 2, bh / 2, C.textDim, 1, 1)
					end
				end, function()
					BuyPurchase({catName, itemName, attachName})
				end, tostring(attachName))
				row.Subs[#row.Subs + 1] = chip
			end
		end

		row.PerformLayout = function(s, w, h)
			buy:SetPos(w - U(14) - U(92), (h - U(36)) / 2)
			local x = textX
			local y = h - U(38)
			for _, chip in ipairs(s.Subs) do
				chip:SetPos(x, y)
				x = x + chip:GetWide() + U(6)
			end
		end

		return row
	end

	local cats = {}
	local buyItems = MODE.BuyItems or {}
	for catName, catData in pairs(buyItems) do
		if istable(catData) then
			cats[#cats + 1] = { name = catName, data = catData, prio = tonumber(catData.Priority) or 0 }
		end
	end
	table.sort(cats, function(a, b)
		if a.prio == b.prio then return tostring(a.name) < tostring(b.name) end
		return a.prio < b.prio
	end)

	for idx, cat in ipairs(cats) do
		local scroll = vgui.Create("DScrollPanel", body)
		scroll:Dock(FILL)
		scroll.Paint = function() end
		UI.StyleScroll(scroll)
		scroll:SetVisible(false)
		panels[idx] = scroll

		local list = {}
		for itemName, Item in pairs(cat.data) do
			if itemName ~= "Priority" and istable(Item) then
				list[#list + 1] = { name = itemName, item = Item }
			end
		end
		table.sort(list, function(a, b)
			local pa, pb = tonumber(a.item.Price) or 0, tonumber(b.item.Price) or 0
			if pa == pb then return tostring(a.name) < tostring(b.name) end
			return pa < pb
		end)

		if #list == 0 then
			scroll.Paint = function(_, w, h)
				draw.SimpleText("NO ITEMS", "ZUI_Small", w / 2, U(40), C.textMut, 1, 1)
			end
		end

		for _, entry in ipairs(list) do
			BuildRow(scroll, cat.name, entry.name, entry.item)
		end

		local tb = vgui.Create("DButton", tabBar)
		tb:SetText("")
		tb:SetCursor("hand")
		tb.Idx = idx
		tb.Label = string.upper(tostring(cat.name))
		tb.Hov, tb.Sel = 0, 0
		tb.OnCursorEntered = function() UI.SndHover() end
		tb.DoClick = function(s)
			if active == s.Idx then return end
			UI.SndClick()
			SetActive(s.Idx)
		end
		tb.Paint = function(s, w, h)
			local on = active == s.Idx
			s.Hov = UI.Smooth(s.Hov, s:IsHovered() and 1 or 0, 14)
			s.Sel = UI.Smooth(s.Sel, on and 1 or 0, 12)
			draw.SimpleText(string.format("%02d", s.Idx), "ZUI_Caps", w / 2, h / 2 - U(12), UI.Mix(s.Sel, C.textMut, C.textDim), 1, 1)
			local shown = BuyFit(s.Label, "ZUI_Small", w - U(12))
			draw.SimpleText(shown, "ZUI_Small", w / 2, h / 2 + U(6), UI.Mix(math.max(s.Sel, s.Hov), C.textDim, C.white), 1, 1)
			local uw = (w - U(20)) * s.Sel
			surface.SetDrawColor(C.white)
			surface.DrawRect((w - uw) / 2, h - 2, uw, 2)
		end
		tabButtons[idx] = tb
	end

	if #cats == 0 then
		body.Paint = function(_, w, h)
			draw.SimpleText("NOTHING TO BUY", "ZUI_Small", w / 2, h / 2, C.textMut, 1, 1)
		end
	else
		SetActive(1)
	end

	tabBar:InvalidateLayout(true)
end

net.Receive("tdm_open_buymenu",function()
	OpenBuyMenu()
end)

TDM_OpenedBuyMenu = TDM_OpenedBuyMenu or nil