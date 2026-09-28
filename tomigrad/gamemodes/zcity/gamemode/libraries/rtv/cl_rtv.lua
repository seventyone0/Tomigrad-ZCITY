-- Values
local maps = {}
local time = 0
local votes = {}
local winmap = ""
local rtvStarted = false
local rtvEnded = false

local VoteCD = 0

-- RTV CL Functions
local BlurBackground = hg.BlurBackground

function zb.RTVMenu()
    system.FlashWindow()

    local RTVMenu = vgui.Create("ZB_RTVMenu")
    RTVMenu:SetSize(ScrW() / 2.0, ScrH() / 1.05)
    RTVMenu:Center()
    RTVMenu:SetTitle("")
    RTVMenu:SetBackgroundBlur(true)
    RTVMenu:ShowCloseButton(false)
    RTVMenu:SetDraggable(false)
    RTVMenu:MakePopup()
    RTVMenu:SetKeyboardInputEnabled(false)

    -- Main menu background
    function RTVMenu:Paint(w, h)
        BlurBackground(self)

        surface.SetDrawColor(35, 35, 35, 235)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(130, 130, 130, 160)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end

    local MAPSPanel = vgui.Create("DPanel", RTVMenu)
    MAPSPanel:Dock(FILL)
    MAPSPanel:DockMargin(5, ScrH() * 0.04, 5, ScrH() * 0.01)

    function MAPSPanel.Paint()
    end

    for k, v in ipairs(maps) do
        local MapButton = vgui.Create("ZB_RTVButton", MAPSPanel)

        MapButton:Dock(TOP)
        MapButton:DockMargin(0, 5, 0, 0)
        MapButton:SetSize(0, ScrH() * 0.06)

        if v == "random" then
            MapButton:SetText("Random Map")
            MapButton.Map = "random"
            MapButton.MapIcon = Material("icon64/random.png")

            if MapButton.MapIcon:IsError() then
                MapButton.MapIcon = Material("icon64/tool.png")
            end
        else
            local txt = v

            txt = string.Explode("_", txt)
            table.remove(txt, 1)

            txt[1] = string.upper(string.Left(txt[1], 1)) ..
                string.sub(txt[1], 2)

            MapButton:SetText(table.concat(txt, " "))

            MapButton.Map = v
            MapButton.MapIcon = Material(
                "maps/thumb/" .. MapButton.Map .. ".png"
            )

            if MapButton.MapIcon:IsError() then
                MapButton.MapIcon = Material("icon64/tool.png")
            end
        end

        function MapButton:Think()
            self.Votes = votes[self.Map] or 0

            if self.Map ~= "random" and self.Map == winmap then
                self.Win = true
            else
                self.Win = false
            end
        end

        function MapButton:DoClick()
            if VoteCD > CurTime() then return end

            net.Start("ZB_RockTheVote_vote")
                net.WriteString(self.Map)
            net.SendToServer()

            VoteCD = CurTime() + 1
        end

        -- Override the default red RTV button painting
        MapButton.Paint = function(self, w, h)
            local bgColor = Color(45, 45, 45, 235)
            local outlineColor = Color(130, 130, 130, 180)
            local textColor = Color(220, 220, 220, 255)

            if self:IsHovered() then
                bgColor = Color(65, 65, 65, 245)
                outlineColor = Color(180, 180, 180, 220)
            end

            if self.Win then
                bgColor = Color(80, 80, 80, 245)
                outlineColor = Color(210, 210, 210, 255)
            end

            surface.SetDrawColor(
                bgColor.r,
                bgColor.g,
                bgColor.b,
                bgColor.a
            )

            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(
                outlineColor.r,
                outlineColor.g,
                outlineColor.b,
                outlineColor.a
            )

            surface.DrawOutlinedRect(0, 0, w, h, 2)

            if self.MapIcon then
                surface.SetMaterial(self.MapIcon)
                surface.SetDrawColor(255, 255, 255, 255)

                surface.DrawTexturedRect(
                    5,
                    5,
                    h - 10,
                    h - 10
                )
            end

            surface.SetFont("HomigradFont")

            local txt = self:GetText() or ""

            local tw, th = surface.GetTextSize(txt)

            surface.SetTextColor(
                textColor.r,
                textColor.g,
                textColor.b,
                textColor.a
            )

            surface.SetTextPos(
                h + 10,
                h / 2 - th / 2
            )

            surface.DrawText(txt)

            if self.Votes and self.Votes > 0 then
                local voteText = tostring(self.Votes)

                local vw, vh = surface.GetTextSize(voteText)

                surface.SetTextPos(
                    w - vw - 15,
                    h / 2 - vh / 2
                )

                surface.DrawText(voteText)
            end
        end
    end

    -- Exit button
    local button = vgui.Create("DButton", RTVMenu)

    button:SetPos(
        ScrW() / 2.0 - ScreenScale(25),
        ScreenScale(5)
    )

    button:SetSize(
        ScreenScale(20),
        ScreenScale(10)
    )

    button:SetText("")

    function button:Paint(w, h)
        BlurBackground(self)

        local bgColor = Color(40, 40, 40, 230)
        local outlineColor = Color(130, 130, 130, 180)

        if self:IsHovered() then
            bgColor = Color(65, 65, 65, 240)
            outlineColor = Color(190, 190, 190, 220)
        end

        surface.SetDrawColor(
            bgColor.r,
            bgColor.g,
            bgColor.b,
            bgColor.a
        )

        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(
            outlineColor.r,
            outlineColor.g,
            outlineColor.b,
            outlineColor.a
        )

        surface.DrawOutlinedRect(
            0,
            0,
            w,
            h,
            2.5
        )

        local x, y = w / 2, h / 2
        local txt = "Exit"

        surface.SetFont("HomigradFont")
        surface.SetTextColor(230, 230, 230, 255)

        local tw, th = surface.GetTextSize(txt)

        surface.SetTextPos(
            x - tw / 2,
            y - th / 2
        )

        surface.DrawText(txt)
    end

    function button:DoClick()
        if IsValid(RTVMenu) then
            RTVMenu:Remove()
        end
    end
end

function zb.StartRTV()
    maps = net.ReadTable()
    time = net.ReadFloat()

    zb.RTVMenu()

    rtvStarted = true
end

net.Receive("RTVMenu", function()
    zb.RTVMenu()
end)

function zb.RTVregVote()
    votes = net.ReadTable()
end

function zb.EndRTV()
    winmap = net.ReadString()
    rtvEnded = true
end

-- NETWORKING

net.Receive("ZB_RockTheVote_start", zb.StartRTV)
net.Receive("ZB_RockTheVote_voteCLreg", zb.RTVregVote)
net.Receive("ZB_RockTheVote_end", zb.EndRTV)