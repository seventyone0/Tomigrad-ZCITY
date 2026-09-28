hg.Appearance = hg.Appearance or {}
local APmodule = hg.Appearance
local PANEL = {}

hg = hg or {}
hg.UI = hg.UI or {}
hg.UI.C = hg.UI.C or {}
local UI = hg.UI
local C  = UI.C
local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end


local presetsDir = "zcity/appearances/presets/"
local SOUND_APPEARANCE_SUCCESS = "buttons/button14.wav"

local function SavePreset(strName, tblAppearance)
    file.CreateDir(presetsDir)
    file.Write(presetsDir .. strName .. ".json", util.TableToJSON(tblAppearance, true))
end

local function LoadPreset(strName)
    if not file.Exists(presetsDir .. strName .. ".json", "DATA") then return nil end
    return util.JSONToTable(file.Read(presetsDir .. strName .. ".json", "DATA"))
end

local function GetPresetList()
    file.CreateDir(presetsDir)
    local files = file.Find(presetsDir .. "*.json", "DATA")
    local presets = {}
    for _, f in ipairs(files or {}) do
        table.insert(presets, string.StripExtension(f))
    end
    return presets
end

local function DeletePreset(strName)
    if file.Exists(presetsDir .. strName .. ".json", "DATA") then
        file.Delete(presetsDir .. strName .. ".json")
        return true
    end
    return false
end

hg.Appearance.SavePreset    = SavePreset
hg.Appearance.LoadPreset    = LoadPreset
hg.Appearance.GetPresetList = GetPresetList
hg.Appearance.DeletePreset  = DeletePreset

local modelsPrecached = false
local function PrecacheAccessoryModels()
    if modelsPrecached then return end
    modelsPrecached = true

    timer.Simple(0.1, function()
        if APmodule.PlayerModels then
            for _, sexModels in SortedPairs(APmodule.PlayerModels) do
                for _, modelData in SortedPairs(sexModels) do
                    if modelData.mdl then util.PrecacheModel(modelData.mdl) end
                end
            end
        end
        if hg.Accessories then
            for _, accessory in SortedPairs(hg.Accessories) do
                if accessory.model then util.PrecacheModel(accessory.model) end
            end
        end
    end)
end

hook.Add("InitPostEntity", "HG_PrecacheAppearanceModels", function()
    timer.Simple(5, PrecacheAccessoryModels)
end)
hg.Appearance.PrecacheModels = PrecacheAccessoryModels

local function Normalize(t)
    t = table.Copy(t or {})
    t.AAttachments = t.AAttachments or {"none", "none", "none"}
    for i = 1, 3 do
        if t.AAttachments[i] == nil or t.AAttachments[i] == "" then t.AAttachments[i] = "none" end
    end
    t.AClothes    = t.AClothes or {}
    t.ABodygroups = t.ABodygroups or {}
    if istable(t.AColor) and not IsColor(t.AColor) then
        t.AColor = Color(t.AColor.r or t.AColor[1] or 255, t.AColor.g or t.AColor[2] or 255, t.AColor.b or t.AColor[3] or 255, t.AColor.a or 255)
    end
    t.AColor = t.AColor or Color(255, 255, 255)
    return t
end

local function Comparable(t)
    t = Normalize(t)
    t.AColor = { r = t.AColor.r, g = t.AColor.g, b = t.AColor.b }
    return t
end

local function DeepEqual(a, b)
    if istable(a) and istable(b) then
        for k, v in pairs(a) do if not DeepEqual(v, b[k]) then return false end end
        for k, v in pairs(b) do if not DeepEqual(v, a[k]) then return false end end
        return true
    end
    return a == b
end

local function GetModelData(app)
    if not app then return end
    return APmodule.PlayerModels[1][app.AModel] or APmodule.PlayerModels[2][app.AModel]
end

local STAGE = {}

function STAGE:Init()
    self:SetFOV(28)
    self:SetAmbientLight(Color(80, 80, 88))
    self:SetDirectionalLight(BOX_TOP,   Color(255, 255, 255))
    self:SetDirectionalLight(BOX_FRONT, Color(200, 200, 210))
    self:SetDirectionalLight(BOX_RIGHT, Color(150, 150, 165))
    self:SetDirectionalLight(BOX_LEFT,  Color(120, 120, 130))

    self.Yaw, self.TargetYaw = 200, 200
    self.Zoom, self.TargetZoom = 1, 1
    self.AutoSpin = false
    self.Dragging = false
    self.Extras = {}
    self.PlayerColorVec = Vector(1, 1, 1)
    self:SetCursor("sizewe")
end

function STAGE:LayoutEntity(ent)
    if self.AutoSpin and not self.Dragging then
        self.TargetYaw = self.TargetYaw + RealFrameTime() * 26
    end
    self.Yaw  = UI.Smooth(self.Yaw,  self.TargetYaw,  10)
    self.Zoom = UI.Smooth(self.Zoom, self.TargetZoom, 8)

    ent:SetAngles(Angle(0, self.Yaw, 0))
    ent:SetPos(vector_origin)

    ent:FrameAdvance(RealFrameTime())

    local mins, maxs = ent:GetRenderBounds()
    local height = math.max(maxs.z - mins.z, 1)
    local z = Lerp(self.Zoom - 1, height * 0.5, height * 0.86)
    local dist = Lerp(self.Zoom - 1, height * 2.1, height * 0.85)
    self:SetLookAt(Vector(0, 0, z))
    self:SetCamPos(Vector(dist, 0, z + height * 0.02))
end

function STAGE:OnMousePressed(code)
    if code == MOUSE_LEFT then
        self.Dragging = true
        self.LastX = gui.MouseX()
        self:MouseCapture(true)
    end
end

function STAGE:OnMouseReleased()
    self.Dragging = false
    self:MouseCapture(false)
end

function STAGE:Think()
    if self.Dragging then
        local x = gui.MouseX()
        self.TargetYaw = self.TargetYaw + (x - (self.LastX or x)) * 0.6
        self.LastX = x
    end
end

function STAGE:OnMouseWheeled(delta)
    self.TargetZoom = math.Clamp(self.TargetZoom + delta * 0.18, 1, 1.9)
    return true
end

function STAGE:SetFront(front)
    local base = math.floor(self.TargetYaw / 360) * 360
    self.TargetYaw = base + (front and 200 or 20)
end

function STAGE:ClearExtras()
    for _, m in pairs(self.Extras) do
        if IsValid(m) then m:Remove() end
    end
    self.Extras = {}
    self.LastAccSig = nil
end

function STAGE:OnRemove()
    self:ClearExtras()
end

function STAGE:ApplyAppearance(app)
    self.AppRef = app
    local mdlData = GetModelData(app)
    if not mdlData then return end

    if self.CurrentMdl ~= mdlData.mdl then
        self.CurrentMdl = mdlData.mdl
        self:SetModel(mdlData.mdl)
        local e = self:GetEntity()
        if IsValid(e) then
            for _, name in ipairs({"idle_all_01", "idle_all", "idle"}) do
                local seq = e:LookupSequence(name)
                if seq and seq > 0 then e:ResetSequence(seq) break end
            end
        end
        self:ClearExtras()
    end

    local ent = self:GetEntity()
    if not IsValid(ent) then return end

    local clr = app.AColor or color_white
    local vec = Vector(clr.r / 255, clr.g / 255, clr.b / 255)
    self.PlayerColorVec = vec
    ent.GetPlayerColor = function() return vec end

    ent:SetSubMaterial()
    local mats = ent:GetMaterials()
    local sexIdx = mdlData.sex and 2 or 1
    local clothesSet = APmodule.Clothes[sexIdx] or {}

    for key, matName in pairs(mdlData.submatSlots or {}) do
        local slot
        for i = 1, #mats do
            if mats[i] == matName then slot = i - 1 break end
        end
        if slot then
            local pick = app.AClothes and app.AClothes[key] or "normal"
            local mat = clothesSet[pick] or clothesSet["normal"]
            if mat then ent:SetSubMaterial(slot, mat) end
        end
    end

    local face = app.AFacemap or "Default"
    for i = 1, #mats do
        local set = APmodule.FacemapsSlots[mats[i]]
        local fm = set and set[face]
        if fm and fm ~= "" then ent:SetSubMaterial(i - 1, fm) end
    end

    ent:SetBodyGroups(string.rep("0", 20))
    for k, bg in ipairs(ent:GetBodyGroups()) do
        local pick = bg.name and app.ABodygroups and app.ABodygroups[bg.name]
        local reg = pick and APmodule.Bodygroups[bg.name] and APmodule.Bodygroups[bg.name][sexIdx]
        local entry = reg and reg[pick]
        if entry then
            for i = 0, #bg.submodels do
                if bg.submodels[i] == entry[1] then ent:SetBodygroup(k - 1, i) end
            end
        end
    end

    self:BuildAccessories(app, ent, mdlData)
end

function STAGE:BuildAccessories(app, ent, mdlData)
    local sig = (mdlData.mdl or "") .. "|" .. table.concat(app.AAttachments or {}, ",")
    if sig == self.LastAccSig then return end
    self:ClearExtras()
    self.LastAccSig = sig

    local fem = mdlData.sex and true or false
    for slot, key in ipairs(app.AAttachments or {}) do
        local data = key ~= "none" and hg.Accessories and hg.Accessories[key]
        if data and data.model then
            local m = ClientsideModel(fem and (data.femmodel or data.model) or data.model, RENDERGROUP_OTHER)
            if IsValid(m) then
                m:SetNoDraw(true)
                local place = data[fem and "fempos" or "malepos"]
                m:SetModelScale(place and place[3] or 1)
                if data.bodygroups then m:SetBodyGroups(data.bodygroups) end
                if data.SubMat then m:SetSubMaterial(0, data.SubMat) end
                local skin = data.skin
                if isfunction(skin) then skin = skin(ent) end
                m:SetSkin(skin or 0)
                m.AccData = data
                self.Extras[slot] = m
            end
        end
    end
end

function STAGE:PostDrawModel(ent)
    local fem = (GetModelData(self.AppRef) or {}).sex and true or false
    for _, m in pairs(self.Extras) do
        if not IsValid(m) then continue end
        local data = m.AccData
        if not data then continue end
        local bone = ent:LookupBone(data.bone or "ValveBiped.Bip01_Head1")
        if not bone then continue end
        local matrix = ent:GetBoneMatrix(bone)
        local place = data[fem and "fempos" or "malepos"]
        if not matrix or not place then continue end

        local pos, ang = LocalToWorld(place[1], place[2], matrix:GetTranslation(), matrix:GetAngles())
        m:SetRenderOrigin(pos)
        m:SetRenderAngles(ang)
        m:SetupBones()

        if data.bSetColor then
            local c = data.vecColorOveride or self.PlayerColorVec
            render.SetColorModulation(c[1], c[2], c[3])
        end
        m:DrawModel()
        if data.bSetColor then render.SetColorModulation(1, 1, 1) end
    end
end

vgui.Register("ZUI_AppearanceStage", STAGE, "DModelPanel")

function PANEL:SetAppearance(t) self.AppearanceTable = t end
function PANEL:CallbackAppearance() end
function PANEL:GetCurrentModelData() return GetModelData(self.AppearanceTable) end

function PANEL:Paint(w, h) end

function PANEL:First()
    self:AlphaTo(255, 0.15, 0)
    if self.PostInit then self:PostInit() end
end

function PANEL:ReturnToMenu()
    local parent  = self:GetParent()
    local luaMenu = IsValid(parent) and parent:GetParent()
    if IsValid(luaMenu) and luaMenu.UseDefaultMenuMusic then luaMenu:UseDefaultMenuMusic() end

    if IsValid(parent) then
        parent:AlphaTo(0, 0.2, 0, function()
            if IsValid(parent) then parent:Remove() end
        end)
    end
    if IsValid(luaMenu) then
        for _, child in ipairs(luaMenu:GetChildren()) do
            if child ~= parent then
                child:SetVisible(true)
                child:AlphaTo(255, 0.2, 0)
            end
        end
        if luaMenu.ResetCurrentPanel then luaMenu:ResetCurrentPanel() end
    end
end

function PANEL:PostInit()
    local main = self
    self:SetBorder(false)
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    if IsValid(self.btnClose) then
        self.btnClose:SetVisible(false)
        self.btnClose:SetMouseInputEnabled(false)
    end

    local parent  = self:GetParent()
    local luaMenu = IsValid(parent) and parent:GetParent()
    if IsValid(luaMenu) and luaMenu.UseAppearanceMenuMusic then luaMenu:UseAppearanceMenuMusic() end

    self.AppearanceTable = Normalize(self.AppearanceTable
        or hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString())
        or APmodule.GetRandomAppearance())

    local savedSnapshot = Comparable(self.AppearanceTable)
    local activeTab
    local stage, nameEntry, listScroll, win
    local unsavedOverlay

    local function HasUnsaved()
        return not DeepEqual(savedSnapshot, Comparable(main.AppearanceTable))
    end

    local function Refresh()
        if IsValid(stage) then stage:ApplyAppearance(main.AppearanceTable) end
    end

    local function ChangeApp(fn)
        fn(main.AppearanceTable)
        Refresh()
    end

    local tabs = {
        { id = "Model",  label = "Body"     },
        { id = "Face",   label = "Face"     },
        { id = "Hat",    label = "Head"     },
        { id = "Glass",  label = "Eyes"     },
        { id = "Torso",  label = "Torso"    },
        { id = "Jacket", label = "Jacket"   },
        { id = "Pants",  label = "Pants"    },
        { id = "Boots",  label = "Boots"    },
        { id = "Gloves", label = "Hands"    },
    }

    win = UI.Window(self, {
        index  = "06",
        title  = "CLOTHING",
        hint   = "How you look.",
        tabs   = tabs,
        onBack = function() main:Close() end,
        footer = { "DRAG rotate", "WHEEL zoom", "APPLY save", "ESC back" },
    })
    self.Win = win

    local function DoApply()
        hg.Appearance.CreateAppearanceFile(hg.Appearance.SelectedAppearance:GetString(), main.AppearanceTable)
        net.Start("OnlyGet_Appearance")
            net.WriteTable(main.AppearanceTable)
        net.SendToServer()
        savedSnapshot = Comparable(main.AppearanceTable)
        surface.PlaySound(SOUND_APPEARANCE_SUCCESS)
    end

    local body = win.Body

    local left = vgui.Create("DPanel", body)
    left:Dock(LEFT)
    left:SetWide(U(250))
    left:DockMargin(0, 0, U(16), 0)
    left.Paint = function(_, w, h) surface.SetDrawColor(C.line) surface.DrawRect(w - 1, 0, 1, h) end

    local dirty = vgui.Create("DPanel", left)
    dirty:Dock(TOP)
    dirty:SetTall(U(44))
    dirty:DockMargin(0, 0, U(14), U(10))
    dirty.T = 0
    dirty.Paint = function(s, w, h)
        local d = HasUnsaved()
        s.T = UI.Smooth(s.T, d and 1 or 0, 8)
        surface.SetDrawColor(C.bg1) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, UI.Mix(s.T, C.line, C.warn))
        local dot = U(7)
        local pulse = d and (0.5 + 0.5 * math.sin(CurTime() * 5)) or 1
        surface.SetDrawColor(UI.Mix(s.T, C.textMut, UI.Alpha(C.warn, 120 + 135 * pulse)))
        surface.DrawRect(U(14), h / 2 - dot / 2, dot, dot)
        draw.SimpleText(d and "UNSAVED CHANGES" or "ALL CHANGES SAVED", "ZUI_Caps", U(30), h / 2,
            d and C.warn or C.textDim, 0, 1)
    end

    local apply = UI.Button(left, "Apply", DoApply, "solid")
    apply:Dock(TOP)
    apply:SetTall(U(44))
    apply:DockMargin(0, 0, U(14), U(6))

    local function SavePresetDialog()
        Derma_StringRequest("Save preset", "Preset name", main.AppearanceTable.AName or "", function(txt)
            if not isstring(txt) then return end
            txt = string.gsub(string.Trim(txt), "[^%w%s_-]", "")
            if #txt < 2 then
                UI.SndDeny()
                notification.AddLegacy("Enter a preset name (min 2 chars)", NOTIFY_ERROR, 3)
                return
            end
            SavePreset(txt, main.AppearanceTable)
            UI.SndOk()
            notification.AddLegacy("Preset '" .. txt .. "' saved!", NOTIFY_GENERIC, 3)
        end)
    end

    local function LoadPresetDialog()
        local list = GetPresetList()
        if #list == 0 then
            UI.SndDeny()
            notification.AddLegacy("No presets saved yet!", NOTIFY_ERROR, 3)
            return
        end

        local ov = vgui.Create("DButton", main)
        ov:SetText("")
        ov:SetSize(main:GetWide(), main:GetTall())
        ov:MakePopup()
        ov:SetAlpha(0)
        ov:AlphaTo(255, 0.12, 0)
        ov.Paint = function(_, w, h) surface.SetDrawColor(C.scrim) surface.DrawRect(0, 0, w, h) end
        ov.DoClick = function() ov:Remove() end

        local box = vgui.Create("DPanel", ov)
        box:SetSize(U(460), U(500))
        box:Center()
        box.Paint = function(_, w, h)
            surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
            UI.Outline(0, 0, w, h, C.lineHi)
            UI.Brackets(0, 0, w, h, C.white, U(10))
            draw.SimpleText("LOAD PRESET", "ZUI_Head", U(24), U(34), C.white, 0, 1)
            draw.SimpleText("Right-click a preset to delete it", "ZUI_Small", U(24), U(60), C.textDim, 0, 1)
        end

        local sc = vgui.Create("DScrollPanel", box)
        sc:Dock(FILL)
        sc:DockMargin(U(20), U(84), U(14), U(20))
        sc.Paint = function() end
        UI.StyleScroll(sc)

        for _, name in SortedPairs(list) do
            local cell = UI.Cell(sc, {
                title = name, tall = U(48),
                onClick = function()
                    local loaded = LoadPreset(name)
                    if loaded then
                        main.AppearanceTable = Normalize(loaded)
                        if IsValid(nameEntry) then nameEntry:SetText(main.AppearanceTable.AName or "") end
                        Refresh()
                        if activeTab then win:SetTab(activeTab) end
                        UI.SndOk()
                        notification.AddLegacy("Preset '" .. name .. "' loaded!", NOTIFY_GENERIC, 3)
                    else
                        UI.SndDeny()
                        notification.AddLegacy("Failed to load preset!", NOTIFY_ERROR, 3)
                    end
                    ov:Remove()
                end,
            })
            cell.DoRightClick = function(s)
                DeletePreset(name)
                surface.PlaySound("buttons/button15.wav")
                notification.AddLegacy("Preset deleted!", NOTIFY_HINT, 2)
                s:Remove()
            end
        end
    end

    local function DeletePresetDialog()
        Derma_StringRequest("Delete preset", "Preset name", main.AppearanceTable.AName or "", function(txt)
            if not isstring(txt) then return end
            txt = string.Trim(txt)
            if txt == "" then
                UI.SndDeny()
                notification.AddLegacy("Enter preset name to delete", NOTIFY_ERROR, 3)
                return
            end
            if DeletePreset(txt) then
                surface.PlaySound("buttons/button15.wav")
                notification.AddLegacy("Preset '" .. txt .. "' deleted!", NOTIFY_HINT, 3)
            else
                UI.SndDeny()
                notification.AddLegacy("Preset not found!", NOTIFY_ERROR, 3)
            end
        end)
    end

    UI.SectionLabel(left, "Presets")
    local savePresetBtn = UI.Button(left, "Save preset", SavePresetDialog)
    savePresetBtn:Dock(TOP) savePresetBtn:SetTall(U(40)) savePresetBtn:DockMargin(0, 0, U(14), U(6))
    local loadPresetBtn = UI.Button(left, "Load preset", LoadPresetDialog)
    loadPresetBtn:Dock(TOP) loadPresetBtn:SetTall(U(40)) loadPresetBtn:DockMargin(0, 0, U(14), U(6))
    local delPresetBtn = UI.Button(left, "Delete preset", DeletePresetDialog, "danger")
    delPresetBtn:Dock(TOP) delPresetBtn:SetTall(U(40)) delPresetBtn:DockMargin(0, 0, U(14), U(6))

    local right = vgui.Create("DPanel", body)
    right:Dock(RIGHT)
    right:SetWide(U(400))
    right:DockMargin(U(16), 0, 0, 0)
    right.Paint = function(_, w, h) surface.SetDrawColor(C.line) surface.DrawRect(0, 0, 1, h) end

    listScroll = vgui.Create("DScrollPanel", right)
    listScroll:Dock(FILL)
    listScroll:DockMargin(U(16), 0, U(4), 0)
    listScroll.Paint = function() end
    UI.StyleScroll(listScroll)

    local center = vgui.Create("DPanel", body)
    center:Dock(FILL)
    center.Paint = function(_, w, h)
        local cx, cy = w / 2, h * 0.88
        surface.SetDrawColor(255, 255, 255, 30)
        UI.Brackets(0, 0, w, h, C.lineHi, U(16))
    end

    stage = vgui.Create("ZUI_AppearanceStage", center)
    stage:Dock(FILL)
    stage:DockMargin(U(2), U(2), U(2), U(2))

    local plate = vgui.Create("DPanel", center)
    plate:SetSize(U(340), U(54))
    plate.Paint = function(_, w, h)
        surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, C.line)
        draw.SimpleText("NAME", "ZUI_Caps", U(12), U(12), C.textMut, 0, 1)
    end
    nameEntry = UI.TextEntry(plate, "ZUI_Body")
    nameEntry:SetPos(U(10), U(22))
    nameEntry:SetSize(U(320), U(26))
    nameEntry:SetText(main.AppearanceTable.AName or "")
    nameEntry.Paint = function(s, w, h)
        s:DrawTextEntryText(C.white, C.white, C.white)
        surface.SetDrawColor(UI.Mix(s:HasFocus() and 1 or 0, C.line, C.lineMax))
        surface.DrawRect(0, h - 1, w, 1)
    end
    nameEntry.OnValueChange = function(_, val) main.AppearanceTable.AName = val end

    local ctrl = vgui.Create("DPanel", center)
    ctrl:SetSize(U(360), U(40))
    ctrl.Paint = function(_, w, h)
        surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, C.line)
    end
    local function ViewBtn(text, fn, isOn)
        local b = vgui.Create("DButton", ctrl)
        b:SetText("") b:SetCursor("hand") b:Dock(LEFT) b:SetWide(U(90))
        b.Hov = 0
        b.DoClick = function() UI.SndClick() fn() end
        b.Paint = function(s, w, h)
            s.Hov = UI.Smooth(s.Hov, s:IsHovered() and 1 or 0, 14)
            local on = isOn and isOn()
            if on then surface.SetDrawColor(255, 255, 255, 18) surface.DrawRect(0, 0, w, h) end
            draw.SimpleText(text, "ZUI_Small", w / 2, h / 2, on and C.white or UI.Mix(s.Hov, C.textDim, C.white), 1, 1)
            if on then surface.SetDrawColor(C.white) surface.DrawRect(U(12), h - 2, w - U(24), 2) end
        end
    end
    ViewBtn("Front", function() stage.AutoSpin = false stage:SetFront(true) end)
    ViewBtn("Back",  function() stage.AutoSpin = false stage:SetFront(false) end)
    ViewBtn("Spin",  function() stage.AutoSpin = not stage.AutoSpin end, function() return stage.AutoSpin end)
    ViewBtn("Zoom",  function() stage.TargetZoom = stage.TargetZoom > 1.3 and 1 or 1.75 end, function() return stage.TargetZoom > 1.3 end)

    center.PerformLayout = function(s, w, h)
        plate:SetPos((w - plate:GetWide()) / 2, U(14))
        ctrl:SetPos((w - ctrl:GetWide()) / 2, h - ctrl:GetTall() - U(14))
    end

    local function SetHint(t) if IsValid(win) then win:SetHint(t) end end

    local function AddOption(label, isActive, onPick, tip, sub)
        return UI.Cell(listScroll, {
            title = label, sub = sub, tall = sub and U(54) or U(46),
            selected = isActive, tip = tip,
            right = function() return isActive() and "●" or "" end,
            onClick = function() onPick() end,
        })
    end

    local function AddAccessoryTile(key, data, isActive, onPick)
        local cell = UI.Cell(listScroll, {
            title = string.NiceName(data.name or key),
            sub = string.upper(data.placement or ""),
            tall = U(88),
            selected = isActive,
            onClick = function() onPick() end,
        })
        local basePaint = cell.Paint
        cell.Paint = function(s, w, h)
            local m = Matrix()
            m:Translate(Vector(U(84), 0, 0))
            cam.PushModelMatrix(m)
            basePaint(s, w - U(84), h)
            cam.PopModelMatrix()
            surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, U(84), h)
            UI.Outline(0, 0, U(84), h, C.line)
        end

        local icon = vgui.Create("DModelPanel", cell)
        icon:SetPos(U(4), U(4))
        icon:SetSize(U(76), U(80))
        icon:SetMouseInputEnabled(false)
        icon:SetModel(data.model or "models/error.mdl")
        icon:SetFOV(18)
        icon:SetLookAt(data.vpos or vector_origin)
        icon.Spin = math.random(0, 360)
        function icon:LayoutEntity(ent)
            self.Spin = self.Spin + (cell:IsHovered() and 90 or 24) * RealFrameTime()
            ent:SetAngles(Angle(0, self.Spin, 0))
            local skin = data.skin
            if isfunction(skin) then skin = skin() end
            ent:SetSkin(skin or 0)
            if data.bodygroups then ent:SetBodyGroups(data.bodygroups) end
            if data.SubMat then ent:SetSubMaterial(0, data.SubMat) end
        end
        function icon:PreDrawModel()
            if data.bSetColor then
                local c = data.vecColorOveride or (LocalPlayer().GetPlayerColor and LocalPlayer():GetPlayerColor()) or Vector(1, 1, 1)
                render.SetColorModulation(c[1], c[2], c[3])
            end
            return true
        end
        function icon:PostDrawModel()
            if data.bSetColor then render.SetColorModulation(1, 1, 1) end
        end
        return cell
    end

    local function ModelList()
        SetHint("Choose a body")
        local all = {}
        for k, v in pairs(APmodule.PlayerModels[1] or {}) do all[k] = v end
        for k, v in pairs(APmodule.PlayerModels[2] or {}) do all[k] = v end
        for name, data in SortedPairs(all) do
            AddOption(name, function() return main.AppearanceTable.AModel == name end, function()
                ChangeApp(function(a)
                    a.AModel = name
                    local md = GetModelData(a)
                    local fk = md and APmodule.FacemapsModels and APmodule.FacemapsModels[md.mdl]
                    local fs = fk and APmodule.FacemapsSlots[fk]
                    if not (fs and fs[a.AFacemap]) then a.AFacemap = "Default" end
                end)
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
            end, nil, data.sex and "Female" or "Male")
        end
    end

    local function AccessoryList(slot, title, placements)
        SetHint("Select " .. string.lower(title))
        AddOption("None", function()
            local v = main.AppearanceTable.AAttachments[slot]
            return v == "none" or v == "" or v == nil
        end, function()
            ChangeApp(function(a) a.AAttachments[slot] = "none" end)
            surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
        end)
        local ply = LocalPlayer()
        for key, data in SortedPairs(hg.Accessories or {}) do
            if not data.placement or not placements[data.placement] then continue end
            if data.bPointShop and ply.PS_HasItem and not ply:PS_HasItem(key) and not APmodule.GetAccessToAll(ply) then continue end
            AddAccessoryTile(key, data, function()
                return main.AppearanceTable.AAttachments[slot] == key
            end, function()
                ChangeApp(function(a) a.AAttachments[slot] = key end)
                surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
            end)
        end
    end

    local function ClothesList(key, title, withColor)
        local md = main:GetCurrentModelData()
        if not md then return end
        SetHint("Select " .. string.lower(title))
        local set = APmodule.Clothes[md.sex and 2 or 1] or {}
        for name in SortedPairs(set) do
            local desc = APmodule.ClothesDesc[name] and APmodule.ClothesDesc[name].desc
            local cell = AddOption(name, function()
                return (main.AppearanceTable.AClothes[key] or "normal") == name
            end, function()
                ChangeApp(function(a) a.AClothes[key] = name end)
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
            end, desc)
            local link = APmodule.ClothesDesc[name] and APmodule.ClothesDesc[name].link
            if link then
                cell.DoRightClick = function() gui.OpenURL(link) end
            end
        end

        if withColor then
            UI.SectionLabel(listScroll, "Color")
            local a0 = main.AppearanceTable.AColor
            if not IsColor(a0) or (a0.r == 255 and a0.g == 0 and a0.b == 0) then
                main.AppearanceTable.AColor = Color(255, 255, 255)
            end
            local mixer = vgui.Create("DColorMixer", listScroll)
            mixer:Dock(TOP)
            mixer:SetTall(U(200))
            mixer:DockMargin(0, 0, U(8), U(10))
            mixer:SetPalette(true)
            mixer:SetAlphaBar(false)
            mixer:SetWangs(true)
            mixer:SetColor(main.AppearanceTable.AColor)
            function mixer:ValueChanged(clr)
                main.AppearanceTable.AColor = Color(clr.r, clr.g, clr.b)
                Refresh()
            end
        end
    end

    local function GlovesList()
        local md = main:GetCurrentModelData()
        if not md then return end
        SetHint("Hands and fingers")
        local set = APmodule.Bodygroups["HANDS"] and APmodule.Bodygroups["HANDS"][md.sex and 2 or 1] or {}
        local ply = LocalPlayer()
        for name, v in SortedPairs(set) do
            if v[2] and ply.PS_HasItem and not ply:PS_HasItem(v.ID) and not APmodule.GetAccessToAll(ply) then continue end
            AddOption(name, function()
                return (main.AppearanceTable.ABodygroups["HANDS"] or "None") == name
            end, function()
                ChangeApp(function(a) a.ABodygroups["HANDS"] = name end)
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
            end)
        end
    end

    local function FacemapList()
        local md = main:GetCurrentModelData()
        if not md then return end
        local fk = APmodule.FacemapsModels and APmodule.FacemapsModels[md.mdl]
        local fs = fk and APmodule.FacemapsSlots[fk]
        if not fs then
            SetHint("This model has no alternative faces")
            AddOption("No alternatives", function() return false end, function() end)
            return
        end
        SetHint("Select a face")
        for name in SortedPairs(fs) do
            AddOption(name, function()
                return (main.AppearanceTable.AFacemap or "Default") == name
            end, function()
                ChangeApp(function(a) a.AFacemap = name end)
                surface.PlaySound("player/weapon_draw_0" .. math.random(2, 5) .. ".wav")
            end)
        end
    end

    local builders = {
        Model  = ModelList,
        Face   = FacemapList,
        Hat    = function() AccessoryList(1, "Headwear", { head = true, ears = true }) end,
        Glass  = function() AccessoryList(2, "Eyewear",  { face = true }) end,
        Torso  = function() AccessoryList(3, "Torso",    { torso = true, spine = true }) end,
        Jacket = function() ClothesList("main", "Jacket", true) end,
        Pants  = function() ClothesList("pants", "Pants") end,
        Boots  = function() ClothesList("boots", "Boots") end,
        Gloves = GlovesList,
    }

    win.SetTab = function(s, id)
        s.ActiveTab = id
        activeTab = id
        listScroll:Clear()
        listScroll:GetVBar():SetScroll(0)
        if builders[id] then builders[id]() end
        listScroll:SetAlpha(0)
        listScroll:AlphaTo(255, 0.15, 0)
    end

    local function CloseUnsaved(cb)
        if not IsValid(unsavedOverlay) then return end
        local o = unsavedOverlay
        unsavedOverlay = nil
        o:Dismiss(cb)
    end

    local function ShowUnsaved()
        if IsValid(unsavedOverlay) then return end
        unsavedOverlay = UI.Modal(main, "Unsaved changes", "You have edits that haven't been applied yet.", {
            { label = "Save & leave", style = "solid", fn = function() DoApply() unsavedOverlay = nil main:ReturnToMenu() end },
            { label = "Discard", style = "danger", fn = function() unsavedOverlay = nil main:ReturnToMenu() end },
            { label = "Stay", fn = function() unsavedOverlay = nil end },
        })
    end

    function self:Close()
        if HasUnsaved() then ShowUnsaved() return end
        self:ReturnToMenu()
    end

    timer.Simple(0, function()
        if not IsValid(main) or not IsValid(stage) then return end
        Refresh()
        win:SetTab("Model")
    end)

    self:CallbackAppearance()
end

vgui.Register("HG_AppearanceMenu", PANEL, "ZFrame")

concommand.Add("hg_appearance_menu", function()
    print("use esc menu")
end)

function hg.CreateApperanceMenu(ParentPanel)
    if hg.Appearance.PrecacheModels then
        hg.Appearance.PrecacheModels()
    end

    hg.PointShop:SendNET("SendPointShopVars", nil, function(data)
        if IsValid(zpan) then
            zpan:Close()
        end
        zpan = vgui.Create("HG_AppearanceMenu", ParentPanel)
        zpan:SetSize(ParentPanel:GetWide(), ParentPanel:GetTall())
        zpan:SetPos(0, 0)
    end)
end