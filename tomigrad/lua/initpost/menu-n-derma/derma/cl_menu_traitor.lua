if not hg then return end

local function MenuUnit(num)
    return math.floor(num * math.min(ScrW(), ScrH()) / 1000)
end

local TRAITOR_MENU_FONT = "ZCity_Traitor_Loadout"
local TRAITOR_POINTS_FONT = "ZCity_Traitor_Points"
local TRAITOR_PRESET_BUTTON_HEIGHT = 34
local TRAITOR_LIST_BUTTON_HEIGHT = 38
local TRAITOR_ADDON_BUTTON_HEIGHT = 32
local TRAITOR_BUTTON_SPACING = 4
local TRAITOR_LIST_WIDTH = 0.6
local TRAITOR_HEADER_HEIGHT = 70
local TRAITOR_LIST_SLIDE_SPEED = 10
local TRAITOR_PREVIEW_SLIDE_SPEED = 10
local TRAITOR_CONTENT_FADE_SPEED = 12
local TRAITOR_LIST_START_OFFSET = 80
local TRAITOR_PREVIEW_START_OFFSET = 80

local function CreateTraitorMenuFonts()
    surface.CreateFont(TRAITOR_MENU_FONT, {
        font = "Verily Serif Mono",
        size = ScreenScale(10),
        weight = 400,
        antialias = true
    })

    surface.CreateFont(TRAITOR_POINTS_FONT, {
        font = "Verily Serif Mono",
        size = ScreenScale(12),
        weight = 400,
        antialias = true
    })
end

hook.Add("OnScreenSizeChanged", "ZCity_TraitorLoadout_Fonts", CreateTraitorMenuFonts)
CreateTraitorMenuFonts()

local color_whitey = Color(225, 225, 225, 255)
local clr_verygray = Color(10, 10, 19, 235)
local menu_gradient_right = Color(18, 18, 18, 65)
local clr_1 = Color(100, 100, 100, 35)

local tex_gradient_r = Material("vgui/gradient-r")
local tex_gradient_l = Material("vgui/gradient-l")
local tex_gradient_d = Material("vgui/gradient-d")

local SOUND_TYPEWRITER = "shitty/tap-resonant.wav"
local SOUND_TYPEWRITER_LEVEL = 55
local SOUND_TYPEWRITER_VOLUME = 0.25
local SOUND_TYPEWRITER_PITCH = 102
local SOUND_SETTINGS_CLICK = "ui/rem_click.wav"
local SOUND_MENU_SELECT = "ui/rem_select.wav"

local function PlayTypewriterSound()
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply:EmitSound(SOUND_TYPEWRITER, SOUND_TYPEWRITER_LEVEL, SOUND_TYPEWRITER_PITCH, SOUND_TYPEWRITER_VOLUME)
        return
    end
    surface.PlaySound(SOUND_TYPEWRITER)
end

local function SetupAnimatedLabel(lbl, text, delay, charSpeed)
    lbl:SetText(string.rep("#", #text))
    lbl:SetMouseInputEnabled(true)
    lbl:SizeToContents()
    lbl.OpenTime = CurTime() + (delay or 0)
    lbl.HoverLerp = 0
    lbl.LineLerp = 0
    lbl.HoverScale = 0.008
    lbl.LabelText = text
    lbl.CharSpeed = charSpeed or 15
end

local function ThinkAnimatedLabel(self)
    local isHovered = self:IsHovered()
    self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, isHovered and 1 or 0)
    self.LineLerp = LerpFT(0.2, self.LineLerp or 0, isHovered and 1 or 0)

    local elapsed = CurTime() - (self.OpenTime or CurTime())
    local charsToShow = math.floor(math.max(elapsed, 0) * (self.CharSpeed or 15))
    local target = self.LabelText or ""
    local len = #target
    if charsToShow > len then charsToShow = len end

    if self.TypewriterTarget ~= target then
        self.TypewriterTarget = target
        self.LastTypewriterChars = 0
    end

    if charsToShow > 0 and charsToShow > (self.LastTypewriterChars or 0) then
        PlayTypewriterSound()
    end

    self.LastTypewriterChars = charsToShow

    local ntxt = ""
    for i = 1, len do
        if i <= charsToShow then
            ntxt = ntxt .. target:sub(i, i)
        else
            ntxt = ntxt .. "#"
        end
    end

    if self:GetText() ~= ntxt then
        self:SetText(ntxt)
        self:SizeToContents()
    end
end

local function PaintAnimatedLabel(self, w, h)
    local isHovered = self:IsHovered()
    local flash = isHovered and (0.5 + 0.5 * math.sin(CurTime() * 10)) or 0
    local textColor = color_whitey
    local outlineColor = Color(0, 0, 0, 255)

    if isHovered then
        local v = flash * 255
        textColor = Color(v, v, v, 255)
        local inv = 255 - v
        outlineColor = Color(inv, inv, inv, 255)
    end

    surface.SetFont(self:GetFont())
    local tw, th = surface.GetTextSize(self:GetText())
    local scale = 1 + (self.HoverLerp or 0) * (self.HoverScale or 0.02)
    local matrix = Matrix()
    matrix:Translate(Vector(0, h * (1 - scale) * 0.5, 0))
    matrix:Scale(Vector(scale, scale, 1))
    cam.PushModelMatrix(matrix)
    draw.SimpleTextOutlined(self:GetText(), self:GetFont(), 0, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, outlineColor)
    if self.LineLerp and self.LineLerp > 0.01 then
        surface.SetDrawColor(255, 255, 255, 255 * self.LineLerp)
        surface.DrawRect(0, h / 2 + th / 2, tw * self.LineLerp, math.max(1, MenuUnit(1)))
    end
    cam.PopModelMatrix()
    return true
end

CreateClientConVar("hmcd_traitor_loadout", "", true, true, "Saved traitor loadout")
CreateClientConVar("hmcd_hero_loadout", "", true, true, "Saved hero loadout")

local RoleConfigs = {
    traitor = {
        title = "TRAITOR",
        buttonTitle = "Traitor",
        maxPoints = 30,
        convar = "hmcd_traitor_loadout",
        saveFile = "zcity_traitor_loadout.txt",
        presetFile = "zcity_traitor_presets.txt",
        skillsets = {
            ["none"] = {cost = 0, name = "None", desc = "You spent time collecting supplies and weapons instead of building a real specialty."},
            ["infiltrator"] = {cost = 15, name = "Infiltrator", desc = "Break necks and disguise as victims."},
            ["assassin"] = {cost = 15, name = "Assassin", desc = "Better gun control and more endurance."},
            ["damned"] = {cost = 30, name = "Damned", desc = "You start with nothing."},
            ["chemist"] = {cost = 10, name = "Chemist", desc = "Detect chemicals in the air."}
        },
        items = {
            ["weapon_p22"] = {cost = 6, name = "Walther P22"},
            ["weapon_taser"] = {cost = 6, name = "Taser"},
            ["weapon_buck200knife"] = {cost = 2, name = "Buck 200 Knife"},
            ["weapon_sogknife"] = {cost = 2, name = "SOG Knife"},
            ["weapon_hg_rgd_tpik"] = {cost = 4, name = "RGD-5 Grenade"},
            ["weapon_adrenaline"] = {cost = 3, name = "Epipen"},
            ["weapon_hg_shuriken"] = {cost = 1, name = "Shuriken"},
            ["weapon_hg_smokenade_tpik"] = {cost = 2, name = "Smoke Grenade"},
            ["weapon_traitor_ied"] = {cost = 5, name = "IED"},
            ["weapon_traitor_poison1"] = {cost = 2, name = "Tetrodotoxin Syringe"},
            ["weapon_traitor_poison2"] = {cost = 2, name = "VX vial"},
            ["weapon_traitor_poison3"] = {cost = 4, name = "Cyanide Canister"},
            ["weapon_traitor_poison4"] = {cost = 2, name = "Curare vial"},
            ["weapon_traitor_poison_consumable"] = {cost = 3, name = "Potassium Cyanide Powder"},
            ["weapon_traitor_suit"] = {cost = 1, name = "Traitor Suit"},
            ["weapon_hg_jam"] = {cost = 1, name = "Door Jam"},
            ["weapon_walkie_talkie"] = {cost = 1, name = "Walkie-Talkie"}
        },
        addons = {
            ["weapon_p22_silencer"] = {cost = 2, name = "P22 Silencer", parent = "weapon_p22"},
            ["weapon_p22_ammo"] = {cost = 2, name = "P22 Extra Ammo", parent = "weapon_p22", desc = "Start with an extra magazine."}
        },
        addonOrder = {
            ["weapon_p22"] = {"weapon_p22_silencer", "weapon_p22_ammo"}
        },
        exclusions = {
            ["weapon_buck200knife"] = {["weapon_sogknife"] = true},
            ["weapon_sogknife"] = {["weapon_buck200knife"] = true}
        },
        defaultPresets = {
            {
                name = "Legacy",
                loadout = {
                    skillset = "none",
                    weapons = {
                        "weapon_p22",
                        "weapon_p22_silencer",
                        "weapon_buck200knife",
                        "weapon_hg_rgd_tpik",
                        "weapon_adrenaline",
                        "weapon_hg_shuriken",
                        "weapon_hg_smokenade_tpik",
                        "weapon_traitor_ied",
                        "weapon_traitor_poison1",
                        "weapon_traitor_suit",
                        "weapon_hg_jam",
                        "weapon_walkie_talkie"
                    }
                }
            },
            {
                name = "Infiltrator",
                loadout = {
                    skillset = "infiltrator",
                    weapons = {
                        "weapon_sogknife",
                        "weapon_adrenaline",
                        "weapon_hg_smokenade_tpik"
                    }
                }
            },
            {
                name = "Assassin",
                loadout = {
                    skillset = "assassin",
                    weapons = {
                        "weapon_p22",
                        "weapon_p22_silencer",
                        "weapon_sogknife",
                        "weapon_adrenaline"
                    }
                }
            },
            {
                name = "Chemist",
                loadout = {
                    skillset = "chemist",
                    weapons = {
                        "weapon_sogknife",
                        "weapon_adrenaline",
                        "weapon_traitor_poison1",
                        "weapon_traitor_poison2",
                        "weapon_traitor_poison3",
                        "weapon_traitor_poison4",
                        "weapon_traitor_poison_consumable"
                    }
                }
            }
        }
    },
    hero = {
        title = "HERO",
        buttonTitle = "Hero",
        maxPoints = 16,
        convar = "hmcd_hero_loadout",
        saveFile = "zcity_hero_loadout.txt",
        presetFile = "zcity_hero_presets.txt",
        items = {
            ["weapon_px4beretta"] = {cost = 4, name = "Beretta PX4", desc = "Reliable sidearm with room for ammo or a suppressor."},
            ["weapon_glock17"] = {cost = 5, name = "Glock 17", desc = "Flexible pistol with strong attachment options."},
            ["weapon_hk_usp"] = {cost = 5, name = "HK USP", desc = "Steady .45 pistol with suppressor support."},
            ["weapon_remington870"] = {cost = 8, name = "Remington 870", desc = "Close range stopper with extra shell support."},
            ["weapon_kar98"] = {cost = 8, name = "Karabiner 98k", desc = "Heavy marksman pick that can take a scope and extra rounds."},
            ["ent_armor_vest3"] = {cost = 4, name = "Kevlar IIIA Vest", icon = "vgui/icons/armor01.png", desc = "Body armor that soaks torso hits."},
            ["ent_armor_helmet1"] = {cost = 2, name = "ACH Helmet III", icon = "vgui/icons/helmet.png", desc = "Ballistic helmet that protects the head."},
            ["ent_armor_helmet7"] = {cost = 2, name = "SSh-68 Helmet", icon = "entities/ent_jack_gmod_ezarmor_ssh68.png", desc = "Steel helmet that protects the head."},
            ["ent_armor_mask1"] = {cost = 2, name = "Ballistic Mask", icon = "vgui/icons/ballisticmask", desc = "Face armor that shields against hits."},
            ["ent_armor_mask2"] = {cost = 2, name = "M40 Gas Mask", icon = "vgui/icons/gasmask", desc = "Face mask offering light protection."},
            ["ent_armor_mask3"] = {cost = 2, name = "Welding Mask", icon = "entities/ent_jack_gmod_ezarmor_weldingkill.png", desc = "Face mask that soaks some hits."},
            ["weapon_remington870_long"] = {cost = 10, name = "Remington 870 Long Barrel", desc = "Long barrel pump-action shotgun."},
            ["weapon_remington870_sawed_off"] = {cost = 6, name = "Remington 870 Sawed-off", desc = "Compact sawed-off pump-action shotgun."},
            ["weapon_vpo209"] = {cost = 12, name = "VPO-209", desc = "Semi-auto carbine chambered in .366 TKM."},
            ["weapon_vpo136"] = {cost = 12, name = "VPO-136", desc = "Semi-auto carbine chambered in 7.62x39mm."},
            ["weapon_mosin"] = {cost = 8, name = "Mosin-Nagant M38", desc = "Bolt-action rifle chambered in 7.62x54mm."}
        },
        addons = {
            ["hero_px4_silencer"] = {cost = 2, name = "PX4 Suppressor", parent = "weapon_px4beretta", attachment = "supressor4", desc = "Keep the PX4 quieter."},
            ["hero_px4_ammo"] = {cost = 2, name = "PX4 Extra Ammo", parent = "weapon_px4beretta", desc = "Start with extra magazine."},
            ["hero_glock_silencer"] = {cost = 2, name = "Glock Suppressor", parent = "weapon_glock17", attachment = "supressor4", desc = "Suppress the Glock 17."},
            ["hero_glock_rmr"] = {cost = 2, name = "Glock RMR", parent = "weapon_glock17", attachment = "holo16", desc = "Adds a compact red dot."},
            ["hero_glock_laser"] = {cost = 1, name = "Glock Laser", parent = "weapon_glock17", attachment = "laser3", desc = "Adds a visible aiming laser."},
            ["hero_glock_ammo"] = {cost = 2, name = "Glock Extra Ammo", parent = "weapon_glock17", desc = "Start with extra magazine."},
            ["hero_usp_silencer"] = {cost = 2, name = "USP Suppressor", parent = "weapon_hk_usp", attachment = "supressor4", desc = "Suppress the USP."},
            ["hero_usp_ammo"] = {cost = 2, name = "USP Extra Ammo", parent = "weapon_hk_usp", desc = "Start with extra magazine."},
            ["hero_remington_ammo"] = {cost = 2, name = "870 Extra Shells", parent = "weapon_remington870", desc = "Start with extra shells."},
            ["hero_kar98_scope"] = {cost = 2, name = "Kar98 Scope", parent = "weapon_kar98", attachment = "optic12", desc = "Adds the Kar98 scope."},
            ["hero_kar98_ammo"] = {cost = 2, name = "Kar98 Extra Ammo", parent = "weapon_kar98", desc = "Start with extra rifle rounds."},
            ["hero_remington_sight"] = {cost = 2, name = "870 Sight", parent = "weapon_remington870", attachment = "holo16", desc = "Adds a sight to the Remington 870."},
            ["hero_remington_long_ammo"] = {cost = 2, name = "870 Long Extra Shells", parent = "weapon_remington870_long", desc = "Start with extra shells."},
            ["hero_remington_long_sight"] = {cost = 2, name = "870 Long Sight", parent = "weapon_remington870_long", attachment = "holo16", desc = "Adds a sight to the long barrel 870."},
            ["hero_remington_sawedoff_ammo"] = {cost = 2, name = "870 Sawed-off Extra Shells", parent = "weapon_remington870_sawed_off", desc = "Start with extra shells."},
            ["hero_remington_sawedoff_sight"] = {cost = 2, name = "870 Sawed-off Sight", parent = "weapon_remington870_sawed_off", attachment = "holo16", desc = "Adds a sight to the sawed-off 870."},
            ["hero_vpo209_silencer"] = {cost = 2, name = "VPO-209 Suppressor", parent = "weapon_vpo209", attachment = "supressor1", desc = "Suppress the VPO-209."},
            ["hero_vpo209_optic"] = {cost = 2, name = "VPO-209 Red Dot", parent = "weapon_vpo209", attachment = "holo16", desc = "Adds a red dot sight to the VPO-209."},
            ["hero_vpo209_ammo"] = {cost = 2, name = "VPO-209 Extra Ammo", parent = "weapon_vpo209", desc = "Start with extra magazine."},
            ["hero_vpo136_silencer"] = {cost = 2, name = "VPO-136 Suppressor", parent = "weapon_vpo136", attachment = "supressor1", desc = "Suppress the VPO-136."},
            ["hero_vpo136_optic"] = {cost = 2, name = "VPO-136 Red Dot", parent = "weapon_vpo136", attachment = "holo16", desc = "Adds a red dot sight to the VPO-136."},
            ["hero_vpo136_ammo"] = {cost = 2, name = "VPO-136 Extra Ammo", parent = "weapon_vpo136", desc = "Start with extra magazine."},
            ["hero_mosin_silencer"] = {cost = 2, name = "Mosin Suppressor", parent = "weapon_mosin", attachment = "supressor1", desc = "Suppress the Mosin."},
            ["hero_mosin_scope"] = {cost = 2, name = "Mosin Scope", parent = "weapon_mosin", attachment = "optic12", desc = "Adds a scope to the Mosin."},
            ["hero_mosin_ammo"] = {cost = 2, name = "Mosin Extra Ammo", parent = "weapon_mosin", desc = "Start with extra rounds."}
        },
        addonOrder = {
            ["weapon_px4beretta"] = {"hero_px4_silencer", "hero_px4_ammo"},
            ["weapon_glock17"] = {"hero_glock_silencer", "hero_glock_rmr", "hero_glock_laser", "hero_glock_ammo"},
            ["weapon_hk_usp"] = {"hero_usp_silencer", "hero_usp_ammo"},
            ["weapon_remington870"] = {"hero_remington_sight", "hero_remington_ammo"},
            ["weapon_remington870_long"] = {"hero_remington_long_sight", "hero_remington_long_ammo"},
            ["weapon_remington870_sawed_off"] = {"hero_remington_sawedoff_sight", "hero_remington_sawedoff_ammo"},
            ["weapon_kar98"] = {"hero_kar98_scope", "hero_kar98_ammo"},
            ["weapon_vpo209"] = {"hero_vpo209_silencer", "hero_vpo209_optic", "hero_vpo209_ammo"},
            ["weapon_vpo136"] = {"hero_vpo136_silencer", "hero_vpo136_optic", "hero_vpo136_ammo"},
            ["weapon_mosin"] = {"hero_mosin_silencer", "hero_mosin_scope", "hero_mosin_ammo"}
        },
        exclusions = {},
        defaultPresets = {
            {
                name = "Street Cop",
                loadout = {
                    weapons = {
                        "weapon_glock17",
                        "hero_glock_rmr",
                        "hero_glock_laser",
                        "hero_glock_ammo"
                    }
                }
            },
            {
                name = "Shotgunner",
                loadout = {
                    weapons = {
                        "weapon_remington870",
                        "hero_remington_ammo",
                        "weapon_walkie_talkie"
                    }
                }
            },
            {
                name = "Hunter",
                loadout = {
                    weapons = {
                        "weapon_kar98",
                        "hero_kar98_scope",
                        "hero_kar98_ammo"
                    }
                }
            }
        }
    }
}

RoleConfigs.hero.items["weapon_walkie_talkie"] = {cost = 1, name = "Walkie-Talkie", desc = "Coordinate with the rest of the round."}

do
    local heroWeaponIds = {
        "weapon_px4beretta",
        "weapon_glock17",
        "weapon_hk_usp",
        "weapon_remington870",
        "weapon_remington870_long",
        "weapon_remington870_sawed_off",
        "weapon_kar98",
        "weapon_vpo209",
        "weapon_vpo136",
        "weapon_mosin"
    }

    for _, weaponId in ipairs(heroWeaponIds) do
        RoleConfigs.hero.exclusions[weaponId] = RoleConfigs.hero.exclusions[weaponId] or {}
        for _, otherId in ipairs(heroWeaponIds) do
            if otherId ~= weaponId then
                RoleConfigs.hero.exclusions[weaponId][otherId] = true
            end
        end
    end

    local armorSlots = {
        {"ent_armor_helmet1", "ent_armor_helmet7"},
        {"ent_armor_mask1", "ent_armor_mask2", "ent_armor_mask3"}
    }

    for _, slot in ipairs(armorSlots) do
        for _, armorId in ipairs(slot) do
            RoleConfigs.hero.exclusions[armorId] = RoleConfigs.hero.exclusions[armorId] or {}
            for _, otherId in ipairs(slot) do
                if otherId ~= armorId then
                    RoleConfigs.hero.exclusions[armorId][otherId] = true
                end
            end
        end
    end
end

local function IsArmorItem(id)
    return isstring(id) and string.StartWith(id, "ent_armor_")
end

local function GetSortedIdsByCost(sourceTable)
    local ids = {}
    for id in pairs(sourceTable or {}) do
        table.insert(ids, id)
    end
    table.sort(ids, function(a, b)
        local aInfo = sourceTable[a]
        local bInfo = sourceTable[b]
        if aInfo.cost == bInfo.cost then
            return aInfo.name < bInfo.name
        end
        return aInfo.cost > bInfo.cost
    end)
    return ids
end

for _, config in pairs(RoleConfigs) do
    config.itemOrder = GetSortedIdsByCost(config.items)
    config.skillsetOrder = GetSortedIdsByCost(config.skillsets)
end

local function HasWeaponConflict(config, selectedWeapons, weaponId)
    local exclusions = config.exclusions and config.exclusions[weaponId]
    if exclusions then
        for _, selectedId in ipairs(selectedWeapons) do
            if selectedId ~= weaponId and exclusions[selectedId] then
                return true
            end
        end
    end

    for _, selectedId in ipairs(selectedWeapons) do
        if selectedId ~= weaponId then
            local selectedExclusions = config.exclusions and config.exclusions[selectedId]
            if selectedExclusions and selectedExclusions[weaponId] then
                return true
            end
        end
    end

    return false
end

local function ReadSavedLoadout(config)
    if config.saveFile then
        local data = file.Read(config.saveFile, "DATA")
        if data and data ~= "" then
            local ok, parsed = pcall(util.JSONToTable, data)
            if ok and istable(parsed) then
                return parsed
            end
        end
    end
    local savedData = GetConVar(config.convar):GetString()
    if savedData and savedData ~= "" then
        local ok, parsed = pcall(util.JSONToTable, savedData)
        if ok and istable(parsed) then
            return parsed
        end
    end
    return {}
end

local function SanitizeLoadout(config, rawLoadout)
    local normalizedLoadout = {weapons = {}}
    if config.skillsets then
        normalizedLoadout.skillset = "none"
    end

    if type(rawLoadout) ~= "table" then
        rawLoadout = {}
    end

    if config.skillsets and type(rawLoadout.skillset) == "string" and config.skillsets[rawLoadout.skillset] then
        normalizedLoadout.skillset = rawLoadout.skillset
    end

    local totalPoints = 0
    if config.skillsets and config.skillsets[normalizedLoadout.skillset] then
        totalPoints = config.skillsets[normalizedLoadout.skillset].cost
    end

    local usedWeapons = {}
    local rawWeaponIds = {}
    if type(rawLoadout.weapons) == "table" then
        for k, v in pairs(rawLoadout.weapons) do
            local weaponId
            if type(v) == "string" then
                weaponId = v
            elseif type(k) == "string" and v == true then
                weaponId = k
            end

            if weaponId and not usedWeapons[weaponId] and (config.items[weaponId] or config.addons[weaponId]) then
                usedWeapons[weaponId] = true
                table.insert(rawWeaponIds, weaponId)
            end
        end
    end

    usedWeapons = {}
    for _, weaponId in ipairs(rawWeaponIds) do
        local baseInfo = config.items[weaponId]
        if baseInfo and not usedWeapons[weaponId] and not HasWeaponConflict(config, normalizedLoadout.weapons, weaponId) then
            local weaponCost = baseInfo.cost
            if totalPoints + weaponCost <= config.maxPoints then
                usedWeapons[weaponId] = true
                table.insert(normalizedLoadout.weapons, weaponId)
                totalPoints = totalPoints + weaponCost
            end
        end
    end

    for _, weaponId in ipairs(rawWeaponIds) do
        local addonInfo = config.addons[weaponId]
        if addonInfo and not usedWeapons[weaponId] and usedWeapons[addonInfo.parent] then
            local weaponCost = addonInfo.cost
            if totalPoints + weaponCost <= config.maxPoints then
                usedWeapons[weaponId] = true
                table.insert(normalizedLoadout.weapons, weaponId)
                totalPoints = totalPoints + weaponCost
            end
        end
    end

    return normalizedLoadout
end

local function GetLoadoutPoints(config, loadout)
    local currentPoints = 0

    for _, wep in pairs(loadout.weapons or {}) do
        if config.items[wep] then
            currentPoints = currentPoints + config.items[wep].cost
        elseif config.addons[wep] then
            currentPoints = currentPoints + config.addons[wep].cost
        end
    end

    if config.skillsets and config.skillsets[loadout.skillset] then
        currentPoints = currentPoints + config.skillsets[loadout.skillset].cost
    end

    return currentPoints
end

local RoleState = {}

for roleId, config in pairs(RoleConfigs) do
    RoleState[roleId] = {
        loadout = SanitizeLoadout(config, ReadSavedLoadout(config))
    }
end

local function SaveLoadout(roleId)
    local config = RoleConfigs[roleId]
    local state = RoleState[roleId]
    state.loadout = SanitizeLoadout(config, state.loadout)
    local dataStr = util.TableToJSON(state.loadout)
    if not isstring(dataStr) or dataStr == "" then
        dataStr = "{\"weapons\":[]}"
        if config.skillsets then
            dataStr = "{\"weapons\":[],\"skillset\":\"none\"}"
        end
    end

    if config.saveFile then
        file.Write(config.saveFile, dataStr)
    end

    local cv = GetConVar(config.convar)
    if cv then
        cv:SetString(dataStr)
    end
end

for roleId in pairs(RoleConfigs) do
    SaveLoadout(roleId)
end

local function CloseToMainMenu(panel)
    if not IsValid(panel) then return end

    local luaMenu = panel:GetParent()
    panel:AlphaTo(0, 0.2, 0, function()
        if IsValid(panel) then
            panel:Remove()
        end
    end)

    if not IsValid(luaMenu) then
        return
    end

    for _, child in ipairs(luaMenu:GetChildren()) do
        if child ~= panel then
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

    if luaMenu.ResetCurrentPanel then
        luaMenu:ResetCurrentPanel()
    end
end


hg = hg or {}
hg.UI = hg.UI or {}
hg.UI.C = hg.UI.C or {}
local UI = hg.UI
local C  = UI.C
local function U(n) return math.floor(n * math.min(ScrW(), ScrH()) / 1000) end
local function SndSelect() if UI then UI.SndClick() else surface.PlaySound(SOUND_MENU_SELECT) end end
local function SndDeny()   if UI then UI.SndDeny()  else surface.PlaySound("buttons/button10.wav") end end

local function PointsGauge(parent, getPoints, getMax)
    local g = vgui.Create("DPanel", parent)
    g.Shown = 0
    g.Flash = 0
    g.LastPts = getPoints()
    g.Paint = function(s, w, h)
        local pts, max = getPoints(), getMax()
        if pts ~= s.LastPts then s.Flash = 1 s.LastPts = pts end
        s.Flash = UI.Smooth(s.Flash, 0, 5)
        s.Shown = UI.Smooth(s.Shown, pts, 12)

        draw.SimpleText("BUDGET", "ZUI_Caps", 0, U(10), C.textMut, 0, 1)
        draw.SimpleText(pts .. " / " .. max, "ZUI_MonoBig", w, U(12), UI.Mix(s.Flash, C.white, C.warn), 2, 1)

        local top = U(34)
        local segH = U(14)
        local gap = 2
        local segW = math.max(2, (w - gap * (max - 1)) / max)
        for i = 1, max do
            local x = (i - 1) * (segW + gap)
            surface.SetDrawColor(255, 255, 255, 14)
            surface.DrawRect(x, top, segW, segH)
            local fill = math.Clamp(s.Shown - (i - 1), 0, 1)
            if fill > 0 then
                surface.SetDrawColor(UI.Mix(s.Flash, C.text, C.warn))
                surface.DrawRect(x, top, segW * fill, segH)
            end
        end
        local left = max - pts
        draw.SimpleText(left .. " points remaining", "ZUI_Small", 0, top + segH + U(14), left == 0 and C.warn or C.textDim, 0, 1)
    end
    return g
end


local OpenRoleEditor  

function hg.DrawLoadoutMenu(parentPanel)
    parentPanel:SetAlpha(0)
    parentPanel.Paint = function() end
    parentPanel:AlphaTo(255, 0.15, 0)

    local win = UI.Window(parentPanel, {
        index  = "05",
        title  = "LOADOUT",
        hint   = "Choose which side you want to configure.",
        onBack = function()
            UI.SndClick()
            CloseToMainMenu(parentPanel)
        end,
        footer = { "LMB open", "ESC close" },
    })

    local cardData = {
        { roleId = "hero",    code = "A", title = "GUNMAN",  desc = "Pick the gunner weapon",   points = 16 },
        { roleId = "traitor", code = "B", title = "TRAITOR", desc = "Pick the traitor weapon",  points = 30 },
    }

    local area = vgui.Create("DPanel", win.Body)
    area:Dock(FILL)
    area.Paint = function() end

    local cards = {}
    for i, info in ipairs(cardData) do
        local card = vgui.Create("DButton", area)
        card:SetText("")
        card:SetCursor("hand")
        card.Hov = 0
        card.Born = SysTime() + (i - 1) * 0.08
        card.Info = info

        function card:OnCursorEntered() UI.SndHover() end
        function card:DoClick()
            SndSelect()
            OpenRoleEditor(parentPanel, info.roleId, parentPanel)
        end
        function card:Paint(w, h)
            local a = math.Clamp((SysTime() - self.Born) / 0.35, 0, 1)
            local e = 1 - (1 - a) ^ 3
            self.Hov = UI.Smooth(self.Hov, self:IsHovered() and 1 or 0, 12)
            local hv = self.Hov

            local m = Matrix()
            m:Translate(Vector(0, (1 - e) * U(30), 0))
            cam.PushModelMatrix(m)

            surface.SetDrawColor(UI.Mix(hv, C.bg1, C.bg2)) surface.DrawRect(0, 0, w, h)
            UI.Outline(0, 0, w, h, UI.Mix(hv, C.line, C.lineMax))

            draw.SimpleText(info.code, "ZUI_Display", w - U(30), h * 0.16, UI.Alpha(C.white, 8 + 14 * hv), 2, 1)
            surface.SetFont("ZUI_Display")

            draw.SimpleText("ROLE " .. info.code, "ZUI_Caps", U(30), U(34), C.textMut, 0, 1)
            draw.SimpleText(info.title, "ZUI_Display", U(30), U(90), UI.Mix(hv, C.text, C.white), 0, 1)
            surface.SetDrawColor(C.line) surface.DrawRect(U(30), U(130), w - U(60), 1)
            surface.SetDrawColor(C.white) surface.DrawRect(U(30), U(130), (w - U(60)) * (0.15 + 0.85 * hv), 1)

            draw.SimpleText(info.desc, "ZUI_Body", U(30), U(164), C.textDim, 0, 1)

            local bx, by = U(30), h - U(86)
            draw.SimpleText("BUDGET", "ZUI_Caps", bx, by - U(14), C.textMut, 0, 1)
            draw.SimpleText(info.points .. " PTS", "ZUI_MonoBig", w - U(30), by - U(12), C.white, 2, 1)
            local n = info.points
            local segW = math.max(2, (w - U(60) - (n - 1) * 2) / n)
            for s = 1, n do
                surface.SetDrawColor(255, 255, 255, 18 + 40 * hv)
                surface.DrawRect(bx + (s - 1) * (segW + 2), by + U(6), segW, U(10))
            end

            draw.SimpleText("OPEN  ›", "ZUI_Caps", U(30), h - U(30), UI.Mix(hv, C.textMut, C.white), 0, 1)
            if hv > 0.02 then UI.Brackets(0, 0, w, h, UI.Alpha(C.white, 200 * hv), U(12)) end

            cam.PopModelMatrix()
        end
        cards[i] = card
    end

    area.PerformLayout = function(s, w, h)
        local gap = U(24)
        local cw = math.min(U(560), math.floor((w - gap) / 2))
        local ch = math.min(U(420), h - U(40))
        local totalW = cw * 2 + gap
        local x0 = (w - totalW) / 2
        local y0 = (h - ch) / 2
        for i, c in ipairs(cards) do
            c:SetSize(cw, ch)
            c:SetPos(x0 + (i - 1) * (cw + gap), y0)
        end
    end
end

hg.DrawTraitorLoadout = hg.DrawLoadoutMenu

OpenRoleEditor = function(parentPanel, roleId, returnPanel)
    local host = IsValid(parentPanel:GetParent()) and parentPanel:GetParent() or parentPanel
    local config = RoleConfigs[roleId]
    local state = RoleState[roleId]

    local editorPanel = vgui.Create("DPanel", host)
    editorPanel:SetPos(0, 0)
    editorPanel:SetSize(ScrW(), ScrH())
    editorPanel:MoveToFront()
    editorPanel.ReturnToPanel = returnPanel
    editorPanel.Paint = function() end
    editorPanel:SetMouseInputEnabled(true)
    returnPanel:SetVisible(false)
    returnPanel:SetAlpha(0)

    local UpdateUI

    local function GoBack()
        UI.SndClick()
        if IsValid(editorPanel.ReturnToPanel) then
            local rp = editorPanel.ReturnToPanel
            editorPanel:AlphaTo(0, 0.18, 0, function()
                if IsValid(editorPanel) then editorPanel:Remove() end
            end)
            rp:SetVisible(true)
            rp:AlphaTo(255, 0.18, 0)
            return
        end
        CloseToMainMenu(editorPanel)
    end

    local win = UI.Window(editorPanel, {
        index  = "05",
        title  = config.title,
        hint   = "Spend your points. Hover an item for details.",
        onBack = GoBack,
        footer = { "LMB toggle", "HOVER details", "ESC back" },
    })

    local left = vgui.Create("DPanel", win.Body)
    left:Dock(LEFT)
    left:SetWide(U(280))
    left:DockMargin(0, 0, U(18), 0)
    left.Paint = function(_, w, h) surface.SetDrawColor(C.line) surface.DrawRect(w - 1, 0, 1, h) end

    local clearBtn = UI.Button(left, "Clear all", function()
        local empty = { weapons = {} }
        if config.skillsets then empty.skillset = "none" end
        state.loadout = SanitizeLoadout(config, empty)
        SaveLoadout(roleId)
        if UpdateUI then UpdateUI() end
    end, "danger")
    clearBtn:Dock(BOTTOM)
    clearBtn:SetTall(U(40))
    clearBtn:DockMargin(0, U(8), U(14), 0)

    local presetsScroll = vgui.Create("DScrollPanel", left)
    presetsScroll:Dock(FILL)
    presetsScroll:DockMargin(0, 0, U(6), 0)
    presetsScroll.Paint = function() end
    UI.StyleScroll(presetsScroll)

    local function LoadUserPresets()
        local data = file.Read(config.presetFile, "DATA")
        if data then return util.JSONToTable(data) or {} end
        return {}
    end
    local function SaveUserPresets(presets)
        file.Write(config.presetFile, util.TableToJSON(presets))
    end

    local function ApplyPreset(preset)
        state.loadout = SanitizeLoadout(config, table.Copy(preset.loadout or {}))
        SaveLoadout(roleId)
        UpdateUI()
    end

    local function RefreshPresetsUI()
        presetsScroll:Clear()

        UI.SectionLabel(presetsScroll, "Default presets")
        for _, preset in ipairs(config.defaultPresets or {}) do
            local nWeapons = #(preset.loadout and preset.loadout.weapons or {})
            UI.Cell(presetsScroll, {
                title = preset.name,
                sub = nWeapons .. " items",
                tall = U(50),
                onClick = function() ApplyPreset(preset) end,
            })
        end

        UI.SectionLabel(presetsScroll, "Custom presets")
        local userPresets = LoadUserPresets()

        local create = UI.Button(presetsScroll, "+  Save current as preset", function()
            Derma_StringRequest("New Preset", "Enter a name for the new preset:", "Custom Preset " .. (#userPresets + 1), function(text)
                table.insert(userPresets, { name = text, loadout = table.Copy(state.loadout) })
                SaveUserPresets(userPresets)
                RefreshPresetsUI()
                SndSelect()
            end)
        end)
        create:Dock(TOP)
        create:SetTall(U(40))
        create:DockMargin(0, 0, 0, U(6))

        for i, preset in ipairs(userPresets) do
            local row = vgui.Create("DPanel", presetsScroll)
            row:Dock(TOP)
            row:SetTall(U(46))
            row:DockMargin(0, 0, 0, U(4))
            row.Paint = function(s, w, h)
                surface.SetDrawColor(C.bg1) surface.DrawRect(0, 0, w, h)
                UI.Outline(0, 0, w, h, C.line)
                draw.SimpleText(preset.name, "ZUI_Body", U(14), h / 2, C.text, 0, 1)
            end

            local del = UI.Button(row, "✕", function()
                table.remove(userPresets, i)
                SaveUserPresets(userPresets)
                RefreshPresetsUI()
                SndSelect()
            end, "danger")
            del:Dock(RIGHT) del:SetWide(U(40)) del:DockMargin(0, U(4), U(4), U(4))

            local load = UI.Button(row, "Load", function() ApplyPreset(preset) SndSelect() end)
            load:Dock(RIGHT) load:SetWide(U(64)) load:DockMargin(0, U(4), U(4), U(4))
        end
    end
    RefreshPresetsUI()

    local right = vgui.Create("DPanel", win.Body)
    right:Dock(RIGHT)
    right:SetWide(U(380))
    right:DockMargin(U(18), 0, 0, 0)
    right.Paint = function(_, w, h) surface.SetDrawColor(C.line) surface.DrawRect(0, 0, 1, h) end

    local gauge = PointsGauge(right, function() return GetLoadoutPoints(config, state.loadout) end, function() return config.maxPoints end)
    gauge:Dock(BOTTOM)
    gauge:SetTall(U(96))
    gauge:DockMargin(U(18), 0, 0, U(6))

    local previewIconMat = nil
    local previewName, previewCost, previewDesc = "Hover over an item", nil, ""
    local previewFade = 0

    local inspector = vgui.Create("DPanel", right)
    inspector:Dock(FILL)
    inspector:DockMargin(U(18), 0, 0, U(10))
    inspector.Paint = function(s, w, h)
        previewFade = UI.Smooth(previewFade, 1, 10)

        surface.SetDrawColor(C.bg1) surface.DrawRect(0, 0, w, h)
        UI.Outline(0, 0, w, h, C.line)
        UI.Brackets(0, 0, w, h, C.lineHi, U(8))

        local ih = U(190)
        surface.SetDrawColor(C.bg0) surface.DrawRect(U(14), U(14), w - U(28), ih)
        UI.Outline(U(14), U(14), w - U(28), ih, C.line)
        if previewIconMat then
            surface.SetDrawColor(255, 255, 255, 255 * previewFade)
            surface.SetMaterial(previewIconMat)
            local mw, mh = math.max(previewIconMat:Width(), 1), math.max(previewIconMat:Height(), 1)
            local sc = math.min((w - U(48)) / mw, (ih - U(20)) / mh)
            surface.DrawTexturedRect((w - mw * sc) / 2, U(14) + (ih - mh * sc) / 2, mw * sc, mh * sc)
        else
            draw.SimpleText("NO PREVIEW", "ZUI_Caps", w / 2, U(14) + ih / 2, C.textMut, 1, 1)
        end

        local ty = U(14) + ih + U(28)
        draw.SimpleText(previewName, "ZUI_Head", U(16), ty, UI.Alpha(C.white, 255 * previewFade), 0, 1)
        if previewCost then
            draw.SimpleText(previewCost .. " PTS", "ZUI_Mono", w - U(16), ty, C.text, 2, 1)
        end
        surface.SetDrawColor(C.line) surface.DrawRect(U(16), ty + U(16), w - U(32), 1)
    end

    local descLabel = vgui.Create("DLabel", inspector)
    descLabel:SetFont("ZUI_Body")
    descLabel:SetTextColor(C.textDim)
    descLabel:SetWrap(true)
    descLabel:SetAutoStretchVertical(true)
    descLabel:SetContentAlignment(7)
    descLabel:SetText("")
    inspector.PerformLayout = function(s, w, h)
        descLabel:SetPos(U(16), U(14) + U(190) + U(28) + U(30))
        descLabel:SetWide(w - U(32))
    end

    local function UpdatePreview(id, isSkill)
        previewIconMat = nil
        previewFade = 0

        if isSkill then
            local info = config.skillsets[id]
            if info then
                previewName, previewCost = info.name, info.cost
                descLabel:SetText(info.desc or "")
            end
            return
        end

        local info = config.items[id] or config.addons[id]
        if not info then return end
        previewName, previewCost = info.name, info.cost

        local desc = info.desc or "No description available."
        local swep = weapons.GetStored(id)
        if swep then
            if isstring(swep.Instructions) and swep.Instructions ~= "" then desc = swep.Instructions end
            if swep.WepSelectIcon then
                if isstring(swep.WepSelectIcon) and swep.WepSelectIcon ~= "" then
                    previewIconMat = Material(swep.WepSelectIcon)
                elseif type(swep.WepSelectIcon) == "IMaterial" then
                    previewIconMat = swep.WepSelectIcon
                end
            end
            if not previewIconMat and isstring(swep.IconOverride) and swep.IconOverride ~= "" then
                previewIconMat = Material(swep.IconOverride)
            end
        elseif info.attachment and hg.attachmentsIcons and hg.attachmentsIcons[info.attachment] then
            previewIconMat = Material(hg.attachmentsIcons[info.attachment])
        end

        if not previewIconMat and isstring(info.icon) and info.icon ~= "" then
            previewIconMat = Material(info.icon)
        end
        descLabel:SetText(desc)
    end

    local center = vgui.Create("DPanel", win.Body)
    center:Dock(FILL)
    center.Paint = function() end

    local loadoutScroll = vgui.Create("DScrollPanel", center)
    loadoutScroll:Dock(FILL)
    loadoutScroll.Paint = function() end
    UI.StyleScroll(loadoutScroll)

    UpdateUI = function()
        loadoutScroll:Clear()
        state.loadout = SanitizeLoadout(config, state.loadout)
        local currentPoints = GetLoadoutPoints(config, state.loadout)

        if config.skillsets and next(config.skillsets) then
            UI.SectionLabel(loadoutScroll, "Skillsets")
            for _, id in ipairs(config.skillsetOrder) do
                local info = config.skillsets[id]
                UI.Cell(loadoutScroll, {
                    title = info.name,
                    right = info.cost .. " pts",
                    tall = U(46),
                    selected = function() return state.loadout.skillset == id end,
                    onHover = function() UpdatePreview(id, true) end,
                    onClick = function()
                        local old = state.loadout.skillset
                        local oldCost = config.skillsets[old] and config.skillsets[old].cost or 0
                        if currentPoints + (info.cost - oldCost) > config.maxPoints then
                            SndDeny()
                            return
                        end
                        state.loadout.skillset = id
                        SaveLoadout(roleId)
                        UpdateUI()
                    end,
                })
            end
        end

        local function AddItem(id)
            local info = config.items[id]
            local function selected() return table.HasValue(state.loadout.weapons, id) end

            UI.Cell(loadoutScroll, {
                title = info.name,
                right = info.cost .. " pts",
                tall = U(46),
                selected = selected,
                disabled = function() return not selected() and HasWeaponConflict(config, state.loadout.weapons, id) end,
                onHover = function() UpdatePreview(id, false) end,
                onClick = function()
                    if selected() then
                        table.RemoveByValue(state.loadout.weapons, id)
                        local addonOrder = config.addonOrder[id]
                        if addonOrder then
                            for _, addonId in ipairs(addonOrder) do
                                table.RemoveByValue(state.loadout.weapons, addonId)
                            end
                        end
                    else
                        if currentPoints + info.cost > config.maxPoints then
                            SndDeny()
                            return
                        end
                        table.insert(state.loadout.weapons, id)
                    end
                    SaveLoadout(roleId)
                    UpdateUI()
                end,
            })

            local addonOrder = config.addonOrder[id]
            if addonOrder and selected() then
                for _, addonId in ipairs(addonOrder) do
                    local addonInfo = config.addons[addonId]
                    if addonInfo then
                        UI.Cell(loadoutScroll, {
                            title = "↳  " .. addonInfo.name,
                            right = addonInfo.cost .. " pts",
                            tall = U(38),
                            indent = U(22),
                            selected = function() return table.HasValue(state.loadout.weapons, addonId) end,
                            onHover = function() UpdatePreview(addonId, false) end,
                            onClick = function()
                                if not table.HasValue(state.loadout.weapons, id) then
                                    SndDeny()
                                    return
                                end
                                if table.HasValue(state.loadout.weapons, addonId) then
                                    table.RemoveByValue(state.loadout.weapons, addonId)
                                else
                                    if currentPoints + addonInfo.cost > config.maxPoints then
                                        SndDeny()
                                        return
                                    end
                                    table.insert(state.loadout.weapons, addonId)
                                end
                                SaveLoadout(roleId)
                                UpdateUI()
                            end,
                        })
                    end
                end
            end
        end

        UI.SectionLabel(loadoutScroll, "Weapons & items")
        for _, id in ipairs(config.itemOrder) do
            if not IsArmorItem(id) then AddItem(id) end
        end

        local hasArmor = false
        for _, id in ipairs(config.itemOrder) do
            if IsArmorItem(id) then hasArmor = true break end
        end
        if hasArmor then
            UI.SectionLabel(loadoutScroll, "Armor")
            for _, id in ipairs(config.itemOrder) do
                if IsArmorItem(id) then AddItem(id) end
            end
        end
    end

    UpdateUI()
end
