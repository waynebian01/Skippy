--  Skippy
-- 作者：Wayne

if not Skippy then Skippy = {} end
local format = string.format
---@diagnostic disable-next-line: undefined-field
local wipe = table.wipe
local tinsert = table.insert
--==============================================================================
--  基础table
--==============================================================================
Skippy.index = 0
Skippy.SpellInfo = Skippy.SpellInfo or {}
Skippy.SpellBook = Skippy.SpellBook or {}
Skippy.GlyphInfo = Skippy.GlyphInfo or {}
Skippy.TalentInfo = Skippy.TalentInfo or {}
Skippy.InsertSpells = Skippy.InsertSpells or {}

Skippy.State = {
    auras = {}
}

Skippy.Units = {
    ["target"] = {},
    ["focus"] = {},
    Group = {},
    Boss = {},
    Nameplate = {}
}
local spellFunc = {
    SPELL = GetSpellInfo,
    FUTURESPELL = GetSpellInfo,
    FLYOUT = GetFlyoutInfo,
}

local unitList = {}
local EnumPowerType = {
    ["MANA"] = 0,
    ["RAGE"] = 1,
    ["FOCUS"] = 2,
    ["ENERGY"] = 3,
    ["COMBO_POINTS"] = 4,
    ["RUNES"] = 5,
    ["RUNIC_POWER"] = 6,
    ["SOUL_SHARDS"] = 7,
    ["LUNAR_POWER"] = 8,
    ["HOLY_POWER"] = 9,
    ["MAELSTROM"] = 11,
    ["CHI"] = 12,
    ["INSANITY"] = 13,
    ["BURNING_EMBERS"] = 14,
    ["DEMONIC_FURY"] = 15,
    ["ARCANE_CHARGES"] = 16,
    ["FURY"] = 17,
    ["PAIN"] = 18,
    ["ESSENCE"] = 19,
    ["SHADOW_ORBS"] = 28,
}

local classMacroConfig = {
    -- 圣骑士 (classId 2)
    [2] = {
        unit = {
            "清洁术",
            "圣光术",
            "圣光闪现",
            "神圣之光",
            "神圣震击",
            "荣耀圣令",
            "圣洁护盾",
            "圣光普照",
        },
        static = {
            { "清洁术", "target" },
            { "圣光术", "target" },
            { "圣光闪现", "target" },
            { "神圣之光", "target" },
            { "神圣震击", "target" },
            { "荣耀圣令", "target" },
            { "圣洁护盾", "target" },
            { "圣光普照", "target" },
            { "审判", "target" },
            { "十字军打击", "target" },
            { "黎明圣光", "target" },
            { "洞察圣印" },
            { "神圣恳求" },
            { "神圣棱镜", "target" },
        },
    },
}



--==============================================================================
--  宏相关
--==============================================================================
Skippy.SpellMap = {}
local macroText = {}
local macroList = {}
local macroKind = {}
local modifiers = {
    "CTRL", "ALT", "SHIFT",
    "ALT-CTRL", "ALT-SHIFT", "CTRL-SHIFT",
    "ALT-CTRL-SHIFT"
}

local keys = {
    "NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPAD4", "NUMPAD5",
    "NUMPAD6", "NUMPAD7", "NUMPAD8", "NUMPAD9", "NUMPAD0",
    "NUMPADDECIMAL", "NUMPADPLUS", "NUMPADMINUS", "NUMPADMULTIPLY", "NUMPADDIVIDE",
    "F1", "F2", "F3", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
    ",", ".", "/", ";", "'", "[", "]", "\\",
    "7", "8", "9", "0", "="
}

do
    local i = 1
    for _, m in ipairs(modifiers) do
        for _, k in ipairs(keys) do
            macroKind[i] = m .. "-" .. k
            i = i + 1
        end
    end
end

local UNITS_PER_SPELL = 25

local function createMacro(name, key, macro)
    if InCombatLockdown() then
        -- 实际应用中，建议在这里注册一个 PLAYER_REGEN_ENABLED 事件，等出战后再自动调用一次
        return
    end

    local btn = macroList[name]
    if not btn then
        btn = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
        btn:SetAttribute("type", "macro")
        btn:RegisterForClicks("AnyUp", "AnyDown")
        macroList[name] = btn
        SetOverrideBindingClick(UIParent, false, key, name, "LeftButton")
    end

    btn:SetAttribute("macrotext", macro)
    macroText[name] = macro

    if key and key ~= "" then
        ClearOverrideBindings(btn)
        SetOverrideBindingClick(UIParent, false, key, btn:GetName(), "LeftButton")
    end
end

-- 每个技能 25 个槽位，生成 单位 -> 宏索引 映射
local function makeSpellKeyMap(spellIndex)
    local base = (spellIndex - 1) * UNITS_PER_SPELL + 1
    local map = {
        ["player"] = base,
        ["raid1"] = base,
    }
    for i = 1, 4 do
        map["party" .. i] = base + i
        map["raid" .. (i + 1)] = base + i
    end
    for i = 6, 25 do
        map["raid" .. i] = base + i - 1
    end
    return map
end

-- 槽位 1-25 对应的治疗宏文本
local function makeMacroBody(spell, slot)
    if slot == 1 then
        return format(
            "/cast [group:raid,@raid1][group:party,@player][nogroup,@player]%s",
            spell
        )
    elseif slot <= 5 then
        return format(
            "/cast [group:party,@party%d][group:raid,@raid%d]%s",
            slot - 1, slot, spell
        )
    else
        return format("/cast [group:raid,@raid%d]%s", slot, spell)
    end
end

local function makeStaticMacroBody(spell, unit)
    if unit and unit ~= "spell" then
        return format("/cast [@%s]%s", unit, spell)
    end
    return "/cast " .. spell
end

-- unitSpellList: 25 单位宏技能列表
-- staticSpellList: { { "技能名", "target" }, { "技能名", "player" }, ... }
function Skippy.CreateMacros(unitSpellList, staticSpellList)
    unitSpellList = unitSpellList or {}
    staticSpellList = staticSpellList or {}

    Skippy.SpellMap = {}

    for spellIndex, spellName in ipairs(unitSpellList) do
        Skippy.SpellMap[spellName] = makeSpellKeyMap(spellIndex)
        local base = (spellIndex - 1) * UNITS_PER_SPELL + 1

        for slot = 1, UNITS_PER_SPELL do
            local macroIndex = base + slot - 1
            local keyBinding = macroKind[macroIndex]
            if keyBinding then
                createMacro("s" .. macroIndex, keyBinding, makeMacroBody(spellName, slot))
            end
        end
    end

    local index = #unitSpellList * UNITS_PER_SPELL + 1
    for _, entry in ipairs(staticSpellList) do
        local spellName = entry[1]
        local unit = entry[2] or "spell"

        if not Skippy.SpellMap[spellName] then
            Skippy.SpellMap[spellName] = {}
        end
        Skippy.SpellMap[spellName][unit] = index

        local keyBinding = macroKind[index]
        if keyBinding then
            createMacro("s" .. index, keyBinding, makeStaticMacroBody(spellName, unit))
        end
        index = index + 1
    end
    -- for spellName, data in pairs(Skippy.SpellMap) do
    --     for unit, macroIndex in pairs(data) do
    --         local keyBinding = macroKind[macroIndex]
    --         print(spellName ..
    --             " - " .. unit .. " - " .. macroIndex .. " - " .. keyBinding .. " - " .. macroText["s" .. macroIndex])
    --     end
    -- end
end

--==============================================================================
--  函数集
--==============================================================================
function Skippy.updateSpellIndex(unit, spellName)
    if not spellName or not Skippy.SpellMap or not Skippy.SpellMap[spellName] then
        Skippy.index = 0
        return true
    end
    if unit and Skippy.SpellMap[spellName][unit] then
        Skippy.index = Skippy.SpellMap[spellName][unit]
    else
        Skippy.index = Skippy.SpellMap[spellName]["spell"]
    end
    return true
end

-- 获取单位对象
local function GetUnitObj(unit)
    if not unit then return nil end
    return Skippy.Units[unit] or
        Skippy.Units.Group[unit] or
        Skippy.Units.Boss[unit] or
        Skippy.Units.Nameplate[unit]
end

-- 确保单位对象
local function EnsureUnitObj(unit)
    local obj = GetUnitObj(unit)
    if obj then return obj end
    if not unit then return nil end

    if unit == "target" then
        Skippy.Units.target = {}
        obj = Skippy.Units.target
    elseif unit == "focus" then
        Skippy.Units.focus = {}
        obj = Skippy.Units.focus
    elseif unit == "player" or unit:match("^party%d+$") or unit:match("^raid%d+$") then
        Skippy.Units.Group[unit] = {}
        obj = Skippy.Units.Group[unit]
    elseif unit:match("^boss%d+$") then
        Skippy.Units.Boss[unit] = {}
        obj = Skippy.Units.Boss[unit]
    elseif unit:match("^nameplate%d+$") then
        Skippy.Units.Nameplate[unit] = {}
        obj = Skippy.Units.Nameplate[unit]
    else
        return nil
    end
    return obj
end

local function ClearUnitObj(unit)
    if not unit then return end
    if unit == "target" then
        Skippy.Units.target = {}
    elseif unit == "focus" then
        Skippy.Units.focus = {}
    elseif unit == "player" or unit:match("^party%d+$") or unit:match("^raid%d+$") then
        Skippy.Units.Group[unit] = nil
    elseif unit:match("^boss%d+$") then
        Skippy.Units.Boss[unit] = nil
    elseif unit:match("^nameplate%d+$") then
        Skippy.Units.Nameplate[unit] = nil
    end
end

local function appendUnitsFrom(tbl, keys)
    if not tbl then return end
    for unit, obj in pairs(tbl) do
        if type(obj) == "table" then
            keys[#keys + 1] = unit
        end
    end
end

function Skippy.SyncUnitList()
    wipe(unitList)

    if Skippy.Units.target and Skippy.Units.target.exists then
        tinsert(unitList, "target")
    end
    if Skippy.Units.focus and Skippy.Units.focus.exists then
        tinsert(unitList, "focus")
    end

    local groupKeys, bossKeys, nameplateKeys = {}, {}, {}
    appendUnitsFrom(Skippy.Units.Group, groupKeys)
    appendUnitsFrom(Skippy.Units.Boss, bossKeys)
    appendUnitsFrom(Skippy.Units.Nameplate, nameplateKeys)

    table.sort(groupKeys)
    table.sort(bossKeys)
    table.sort(nameplateKeys)

    for _, unit in ipairs(groupKeys) do
        tinsert(unitList, unit)
    end
    for _, unit in ipairs(bossKeys) do
        tinsert(unitList, unit)
    end
    for _, unit in ipairs(nameplateKeys) do
        tinsert(unitList, unit)
    end

    return unitList
end

function Skippy.InitBossUnit()
    Skippy.Units.Boss = {}
    for i = 1, 5 do
        local unit = "boss" .. i
        Skippy.GetUnitInfo(unit)
    end
end

local function addSpellInfo(spellName)
    local spellInfo = C_Spell.GetSpellInfo(spellName)
    local cooldownInfo = C_Spell.GetSpellCooldown(spellName)
    local chargeInfo = C_Spell.GetSpellCharges(spellName)
    local isUsable, sufficientPower = C_Spell.IsSpellUsable(spellName)
    local castCount = C_Spell.GetSpellCastCount(spellName)
    local isHarmful = C_Spell.IsSpellHarmful(spellName)
    local isHelpful = C_Spell.IsSpellHelpful(spellName)
    local isPassive = C_Spell.IsSpellPassive(spellName)
    Skippy.SpellInfo[spellName] = {
        spellInfo = spellInfo,
        cooldownInfo = cooldownInfo,
        chargeInfo = chargeInfo,
        isUsable = isUsable,
        sufficientPower = sufficientPower,
        castCount = castCount,
        isHarmful = isHarmful,
        isHelpful = isHelpful,
        isPassive = isPassive,
    }
end

--  获取技能信息
function Skippy.GetSpellInfo(spellIdentifier)
    local name = C_Spell.GetSpellName(spellIdentifier)
    if not name then return nil end
    if Skippy.SpellInfo[name] then
        return Skippy.SpellInfo[name]
    else
        addSpellInfo(name)
        return Skippy.SpellInfo[name]
    end
end

function Skippy.GetSpellBookInfo()
    Skippy.SpellBook = {}
    for i = 1, GetNumSpellTabs() do
        local _, _, offset, numSlots = GetSpellTabInfo(i)
        for j = offset + 1, offset + numSlots do
            local spellType, id = GetSpellBookItemInfo(j, BOOKTYPE_SPELL)
            local spellName = spellFunc[spellType](id)
            if not Skippy.SpellBook[spellName] then
                Skippy.SpellBook[spellName] = true
            end
        end
    end

    for spellName in pairs(Skippy.SpellBook) do
        addSpellInfo(spellName)
    end
end

-- 公共冷却
local function getGCD()
    local cooldowninfo = C_Spell.GetSpellCooldown(61304)
    if cooldowninfo and cooldowninfo.startTime > 0 and cooldowninfo.duration > 0 then
        return cooldowninfo.startTime + cooldowninfo.duration - GetTime()
    else
        return 0
    end
end

-- 获取技能冷却
function Skippy.GetSpellCooldown(spellIdentifier)
    local spell = Skippy.GetSpellInfo(spellIdentifier)
    if not spell then return nil end
    local cooldowninfo = spell.cooldownInfo
    if not cooldowninfo then return nil end
    if not cooldowninfo.isEnabled then
        return cooldowninfo.duration
    end
    if cooldowninfo.startTime > 0 and cooldowninfo.duration > 0 then
        local cdLeft = cooldowninfo.startTime + cooldowninfo.duration - GetTime()
        if cdLeft < 0 then
            spell.cooldownInfo = C_Spell.GetSpellCooldown(spellIdentifier)
        end
        return cdLeft
    end
    return 0
end

-- 判断技能是否可用
function Skippy.IsUsableSpell(spellIdentifier)
    local spell = Skippy.GetSpellInfo(spellIdentifier)
    local gcd = getGCD()
    local cd = Skippy.GetSpellCooldown(spellIdentifier)
    local isUsable = C_Spell.IsSpellUsable(spellIdentifier)
    if not spell or not cd then return false end
    local cooldownInfo = spell.cooldownInfo
    local charges = spell.chargeInfo and spell.chargeInfo.currentCharges or nil
    if charges == nil then
        charges = (cooldownInfo.duration == 0 or cd <= gcd) and 1 or 0
    end
    local ready = (cooldownInfo.startTime == 0 and not cooldownInfo.isEnabled) or charges > 0
    local active = isUsable and ready
    return active
end

-- 判断技能是否可用在单位上
function Skippy.IsUsableSpellOnUnit(spellIdentifier, unit)
    local spell = Skippy.GetSpellInfo(spellIdentifier)
    local isUsable = Skippy.IsUsableSpell(spellIdentifier)
    if not spell or not isUsable or unit == nil then
        return false
    end
    local inSpellRange = C_Spell.IsSpellInRange(spellIdentifier, unit)
    return inSpellRange
end

-- 获取glyph信息
function Skippy.GetGlyphInfo()
    Skippy.GlyphInfo = {}
    for index = 1, 6 do
        local enabled, glyphType, glyphIndex, glyphSpellID, iconFile, glyphID = GetGlyphSocketInfo(index)
        Skippy.GlyphInfo[index] = {
            enabled = enabled,
            glyphType = glyphType,
            glyphIndex = glyphIndex,
            glyphSpellID = glyphSpellID,
            iconFile = iconFile,
            glyphID = glyphID,
        }
    end
end

-- 计算血量百分比
function Skippy.UpdateUnitHealth(unit)
    local obj = GetUnitObj(unit)
    if obj and obj.healthInfo then
        local h = obj.healthInfo.health or 0
        local m = obj.healthInfo.healthMax or 0
        local a = obj.healthInfo.healAbsorbs or 0
        local p = obj.healthInfo.healPrediction or 0
        obj.healthPercent = m > 0 and math.max(0, ((h - a + p) / m * 100)) or 0
        obj.realHealthPercent = m > 0 and math.max(0, ((h - a) / m * 100)) or 0
        if unit == "player" then
            Skippy.State.healthInfo.healthPercent = obj.healthPercent
            Skippy.State.healthInfo.realHealthPercent = obj.realHealthPercent
        end
    end
end

-- 获取单位完整血量信息
function Skippy.GetFullHealth(unit)
    local obj = GetUnitObj(unit)
    if obj then
        obj.healthInfo = {
            health = UnitHealth(unit),
            healthMax = UnitHealthMax(unit),
            healAbsorbs = UnitGetTotalHealAbsorbs(unit),
            healPrediction = UnitGetIncomingHeals(unit),
        }
    end
    Skippy.UpdateUnitHealth(unit)
end

-- 更新所有图腾信息
function Skippy.UpdateAllTotem()
    for i = 1, 4 do -- 1:火,2:土,3:水,4:空气
        local _, totemName, startTime, duration, _, _, spellID = GetTotemInfo(i)
        if totemName ~= "" then
            Skippy.State.totems[i] = {
                name = totemName,
                startTime = startTime,
                duration = duration,
                spellID = spellID,
            }
        else
            Skippy.State.totems[i] = nil
        end
    end
end

-- 完整刷新光环
function Skippy.UpdateAuraFull(unit)
    local obj = GetUnitObj(unit)
    if obj then
        if unit == "player" then
            Skippy.State.auras = Skippy.State.auras or {}
            wipe(Skippy.State.auras)
            obj.auras = Skippy.State.auras
        else
            obj.auras = {}
        end

        for i = 1, 40 do
            local buff = C_UnitAuras.GetBuffDataByIndex(unit, i)
            local debuff = C_UnitAuras.GetDebuffDataByIndex(unit, i)
            if buff then
                obj.auras[buff.auraInstanceID] = buff
            end
            if debuff then
                obj.auras[debuff.auraInstanceID] = debuff
            end
        end
    end
end

-- 更新单位距离
function Skippy.UpdateMaxAndMinRange(unit)
    local obj = GetUnitObj(unit)
    if obj then
        local minRange, maxRange = WeakAuras.GetRange(unit)
        obj.minRange = minRange
        obj.maxRange = maxRange
    end
end

-- 获取单位完整信息
function Skippy.GetUnitInfo(unit)
    if UnitExists(unit) then
        local obj = EnsureUnitObj(unit)
        if not obj then return end
        local creatureType, creatureID = UnitCreatureType(unit)
        local minRange, maxRange = WeakAuras.GetRange(unit)
        obj.exists = true
        obj.name = GetUnitName(unit, true) or "无目标"
        obj.GUID = UnitGUID(unit)
        obj.creatureType = creatureType or "UNKNOWN"
        obj.creatureID = creatureID or 0
        obj.isDead = UnitIsDeadOrGhost(unit)
        obj.inRange = UnitInRange(unit)
        obj.canAttack = UnitCanAttack("player", unit)
        obj.canAssist = UnitCanAssist("player", unit)
        obj.minRange = minRange
        obj.maxRange = maxRange
        obj.inSight = true
        Skippy.GetFullHealth(unit)  -- 获取完整血量
        Skippy.UpdateAuraFull(unit) -- 更新完整光环
        if UnitIsUnit(unit, "player") then
            obj.inRange = true
        end
    else
        ClearUnitObj(unit)
    end
    Skippy.SyncUnitList()
end

-- 检测单位存活状态
function Skippy.UpdateIsDead(unit)
    local obj = GetUnitObj(unit)
    if obj then
        obj.isDead = UnitIsDeadOrGhost(unit)
    end
end

--==============================================================================
--  每帧更新函数
--==============================================================================


local updateIndex = 1

function Skippy.UpdateUnitInfo()
    local numUnits = #unitList
    if numUnits == 0 then return end

    local unit = unitList[updateIndex]
    local data = unit and GetUnitObj(unit)
    if data then
        local minRange, maxRange = WeakAuras.GetRange(unit)
        data.inRange = UnitInRange(unit)
        data.canAssist = UnitCanAssist("player", unit)
        data.minRange = minRange
        data.maxRange = maxRange
        if UnitIsUnit(unit, "player") then
            data.inRange = true
        end
    end

    updateIndex = updateIndex + 1
    if updateIndex > numUnits then
        updateIndex = 1
    end
end

--==============================================================================
--  事件更新函数
--==============================================================================

-- 事件更新 技能冷却
function Skippy.UpdateSpellCooldown(spellID)
    local spell = Skippy.GetSpellInfo(spellID)
    if spell then
        spell.cooldownInfo = C_Spell.GetSpellCooldown(spellID)
    end
end

-- 事件更新 技能充能
function Skippy.UpdateSpellCharges()
    for spellName, spellData in pairs(Skippy.SpellInfo) do
        if spellData.chargeInfo then
            spellData.chargeInfo = C_Spell.GetSpellCharges(spellName)
        end
    end
end

-- 事件更新 玩家队伍状态
function Skippy.UpdatePlayerInPartyOrRaid()
    Skippy.State.inParty = UnitInParty("player")
    Skippy.State.inRaid = UnitInRaid("player")
end

-- 事件更新 血量（自动计算百分比，吸收盾后血量）
function Skippy.UpdateHealth(unit, key, getter)
    local obj = GetUnitObj(unit)
    if not obj or not key or not getter then return end
    if not obj.healthInfo then
        obj.healthInfo = {}
    end
    obj.healthInfo[key] = getter(unit)

    if obj.isDead then
        obj.isDead = UnitIsDeadOrGhost(unit)
    end

    local h = obj.healthInfo.health or 0
    local m = obj.healthInfo.healthMax or 0
    local a = obj.healthInfo.healAbsorbs or 0
    local p = obj.healthInfo.healPrediction or 0

    obj.healthPercent = m > 0 and math.max(0, ((h - a + p) / m * 100)) or 0
    obj.realHealthPercent = m > 0 and math.max(0, ((h - a) / m * 100)) or 0
end

-- 事件更新 能量信息
function Skippy.UpdatePower(unit, powerType)
    local powerIndex = EnumPowerType[powerType]
    local powerMax = UnitPowerMax(unit, powerIndex)
    if unit == "player" and powerIndex and powerMax > 0 then
        Skippy.State.power[powerType] = {}
        local power = Skippy.State.power[powerType]
        power.powerValue = UnitPower(unit, powerIndex)
        power.powerMax = powerMax
        power.powerPercent = power.powerValue / power.powerMax * 100
    end
end

-- 事件更新 图腾信息
function Skippy.UpdateTotem(i)
    local _, totemName, startTime, duration, _, _, spellID = GetTotemInfo(i)
    if totemName ~= "" then
        Skippy.State.totems[i] = {
            name = totemName,
            startTime = startTime,
            duration = duration,
            spellID = spellID,
        }
    else
        Skippy.State.totems[i] = nil
    end
end

-- 事件更新 单位施法信息
function Skippy.UpdateCastingInfo(unit)
    local obj = GetUnitObj(unit)
    if obj then
        local name, _, _, startTimeMS, endTimeMS, _, _, _, spellId = UnitCastingInfo(unit)
        if name then
            obj.castInfo = {
                name = name,
                startTimeMS = startTimeMS,
                endTimeMS = endTimeMS,
                spellID = spellId,
            }
        else
            obj.castInfo = nil
            Skippy.State.CastTargetName = nil
            Skippy.State.CastTargetUnit = nil
        end
        if unit == "player" then
            Skippy.State.castInfo = obj.castInfo
        end
    end
end

-- 事件更新 单位引导信息
function Skippy.UpdateChannelingInfo(unit)
    local obj = GetUnitObj(unit)
    if obj then
        local name, _, _, startTimeMs, endTimeMs, _, _, spellID = UnitChannelInfo(unit)
        if name then
            obj.channelInfo = {
                name = name,
                startTimeMs = startTimeMs,
                endTimeMs = endTimeMs,
                spellID = spellID,
            }
        else
            obj.channelInfo = nil
            Skippy.State.CastTargetName = nil
            Skippy.State.CastTargetUnit = nil
        end
        if unit == "player" then
            Skippy.State.channelInfo = obj.channelInfo
        end
    end
end

-- 事件更新 玩家的施法目标
function Skippy.UpdatePlayerCastTarget(name)
    Skippy.State.CastTargetName = name
    for k, v in pairs(Skippy.Units) do
        if type(v) == "table" and v.name == name then
            Skippy.State.CastTargetUnit = k
        end
    end
end

-- 事件更新 更新玩家失败法术
function Skippy.UpdateFailedSpell(unit, spellID)
    local spellname = C_Spell.GetSpellName(spellID)
    local castTarget = Skippy.State.CastTargetUnit
    if Skippy.InsertSpells[spellname] or Skippy.InsertSpells[spellID] then
        if Skippy.Units[castTarget] then
            local spellIsUsable = Skippy.IsUsableSpellOnUnit(spellID, castTarget)
            Skippy.InsertSpell = spellID
            Skippy.InsertTarget = castTarget
            if spellIsUsable then
                C_Timer.After(1.5, function()
                    Skippy.InsertSpell = nil
                    Skippy.InsertTarget = nil
                end)
            end
        else
            local spellIsUsable = Skippy.IsUsableSpell(spellID)
            Skippy.InsertSpell = spellID
            if spellIsUsable then
                C_Timer.After(1.5, function()
                    Skippy.InsertSpell = nil
                end)
            end
        end
    end
end

-- 事件更新 更新玩家失败法术
function Skippy.UpdateInsertSpell(spellID)
    if Skippy.InsertSpell and Skippy.InsertSpell == spellID then
        Skippy.InsertSpell = nil
        Skippy.InsertTarget = nil
    end
end

-- 事件更新 更新光环
function Skippy.UpdateAuraInfo(unit, info)
    local obj = GetUnitObj(unit)
    if obj then
        if not obj.auras then
            obj.auras = {}
        end
        if info.isFullUpdate then
            Skippy.UpdateAuraFull(unit)
            return
        end

        if info.addedAuras then
            for _, aura in pairs(info.addedAuras) do
                obj.auras[aura.auraInstanceID] = aura
                if unit == "player" then
                    Skippy.State.auras[aura.auraInstanceID] = aura
                end
            end
        end

        if info.updatedAuraInstanceIDs then
            for _, id in pairs(info.updatedAuraInstanceIDs) do
                local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
                if aura then
                    obj.auras[id] = aura
                    if unit == "player" then
                        Skippy.State.auras[id] = aura
                    end
                end
            end
        end

        if info.removedAuraInstanceIDs then
            for _, id in pairs(info.removedAuraInstanceIDs) do
                if obj.auras[id] then
                    obj.auras[id] = nil
                    if unit == "player" then
                        Skippy.State.auras[id] = nil
                    end
                end
            end
        end
    end
end

-- 事件更新 获取玩家形态
function Skippy.UpdateShapeshiftForm()
    Skippy.State.shapeshiftFormID = GetShapeshiftFormID() or 0
    Skippy.State.shapeshiftForm = {}
    for i = 1, GetNumShapeshiftForms() do
        local _, active, _, spellID = GetShapeshiftFormInfo(i);
        if spellID then
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo then
                Skippy.State.shapeshiftForm[spellInfo.name] = active
            end
        end
    end
end

-- 事件更新 检测单位是否在视野内
function Skippy.updateGroupInsight(unit)
    if unit ~= "player" then return end
    if Skippy.State.CastTargetUnit then
        local obj = Skippy.Units[Skippy.State.CastTargetUnit]
        if obj then
            obj.inSight = false
            if obj.inSightTimer then
                obj.inSightTimer:Cancel()
                obj.inSightTimer = nil
            end
            obj.inSightTimer = C_Timer.NewTimer(1, function()
                obj.inSight = true
                obj.inSightTimer = nil
            end)
        end
    end
end

-- 事件更新 获取玩家天赋信息
function Skippy.GetCharacterTalentInfo()
    Skippy.TalentInfo = {}

    local currentSpec = C_SpecializationInfo.GetSpecialization()
    if not currentSpec or currentSpec == 0 then
        return
    end

    local groupIndex = C_SpecializationInfo.GetActiveSpecGroup()

    for tier = 1, 6 do
        for column = 1, 3 do
            local info = C_SpecializationInfo.GetTalentInfo({
                tier = tier,
                column = column,
                groupIndex = groupIndex,
            })

            if info and info.name then
                Skippy.TalentInfo[info.name] = {
                    talentID = info.talentID,
                    name = info.name,
                    spellID = info.spellID,
                    tier = info.tier,
                    column = info.column,
                    selected = info.selected,
                    rank = info.selected and (info.rank > 0 and info.rank or 1) or 0,
                    maxRank = info.maxRank,
                    icon = info.icon,
                }
            end
        end
    end
end

-- 事件更新 队伍单位(player, party1~4, raid1~40)
local GROUP_UNIT_DEBOUNCE_SEC = 5
local groupUnitLastRun = 0
local groupUnitPending = false
local groupUnitTimer

local function updateGroupUnitNow()
    Skippy.Units.Group = {}
    for unit in WA_IterateGroupMembers() do
        Skippy.GetUnitInfo(unit)
    end
end

local function runGroupUnitTrailing()
    groupUnitTimer = nil
    if not groupUnitPending then return end

    groupUnitPending = false
    groupUnitLastRun = GetTime()
    updateGroupUnitNow()
end

function Skippy.UpdateGroupUnit()
    local now = GetTime()
    local elapsed = now - groupUnitLastRun

    if groupUnitLastRun == 0 or elapsed >= GROUP_UNIT_DEBOUNCE_SEC then
        groupUnitLastRun = now
        groupUnitPending = false
        if groupUnitTimer then
            groupUnitTimer:Cancel()
            groupUnitTimer = nil
        end
        updateGroupUnitNow()
        return
    end

    groupUnitPending = true
    if not groupUnitTimer then
        groupUnitTimer = C_Timer.NewTimer(GROUP_UNIT_DEBOUNCE_SEC - elapsed, runGroupUnitTrailing)
    end
end

--==============================================================================
--  事件更新
--==============================================================================

aura_env.handlers = {
    PLAYER_ENTERING_WORLD = function(isInitialLogin, isReloadingUi)
        Skippy.GetSpellBookInfo()
    end,
    PLAYER_STARTED_MOVING = function()
        Skippy.State.isMoving = true
    end,
    PLAYER_STOPPED_MOVING = function()
        Skippy.State.isMoving = false
    end,
    PLAYER_REGEN_DISABLED = function()
        Skippy.State.isCombat = true
    end,
    PLAYER_REGEN_ENABLED = function()
        Skippy.State.isCombat = false
    end,
    PLAYER_TALENT_UPDATE = function()
        Skippy.GetCharacterTalentInfo()
    end,
    PLAYER_TOTEM_UPDATE = function(totemSlot)
        Skippy.UpdateTotem(totemSlot)
    end,
    PLAYER_TARGET_CHANGED = function()
        Skippy.GetUnitInfo("target")
    end,
    PLAYER_FOCUS_CHANGED = function()
        Skippy.GetUnitInfo("focus")
    end,
    UPDATE_SHAPESHIFT_FORMS = function()
        Skippy.UpdateShapeshiftForm()
    end,
    UPDATE_SHAPESHIFT_FORM = function()
        Skippy.UpdateShapeshiftForm()
    end,
    PLAYER_DEAD = function()
        Skippy.State.isDead = UnitIsDeadOrGhost("player")
    end,
    PLAYER_ALIVE = function()
        Skippy.State.isDead = UnitIsDeadOrGhost("player")
    end,
    PLAYER_UNGHOST = function()
        Skippy.State.isDead = UnitIsDeadOrGhost("player")
    end,
    PLAYER_MOUNT_DISPLAY_CHANGED = function()
        Skippy.State.isMounted = IsMounted("player")
    end,
    UPDATE_STEALTH = function()
        Skippy.State.stealth = C_UnitAuras.GetPlayerAuraBySpellID(5215)
        Skippy.State.vanish = C_UnitAuras.GetPlayerAuraBySpellID(11327)
        Skippy.State.catStealth = Skippy.State.shapeshiftFormID == 1 and Skippy.State.stealth
    end,

    UNIT_HEALTH = function(unit)
        Skippy.UpdateHealth(unit, "health", UnitHealth)
    end,
    UNIT_MAXHEALTH = function(unit)
        Skippy.UpdateHealth(unit, "healthMax", UnitHealthMax)
    end,
    UNIT_HEAL_ABSORB_AMOUNT_CHANGED = function(unit)
        Skippy.UpdateHealth(unit, "healAbsorbs", UnitGetTotalHealAbsorbs)
    end,
    UNIT_HEAL_PREDICTION = function(unit)
        Skippy.UpdateHealth(unit, "healPrediction", UnitGetIncomingHeals)
    end,
    UNIT_POWER_UPDATE = function(unit, powerType)
        Skippy.UpdatePower(unit, powerType)
    end,

    UNIT_AURA = function(unit, updateInfo)
        Skippy.UpdateAuraInfo(unit, updateInfo)
    end,

    UNIT_SPELLCAST_SENT = function(unit, targetName, castGUID, spellID)
        Skippy.UpdatePlayerCastTarget(targetName)
    end,
    UNIT_SPELLCAST_CHANNEL_START = function(unit, castGUID, spellID, castBarID)
        Skippy.UpdateChannelingInfo(unit)
    end,
    UNIT_SPELLCAST_CHANNEL_STOP = function(unit, castGUID, spellID, interruptedBy, castBarID)
        Skippy.UpdateChannelingInfo(unit)
    end,
    UNIT_SPELLCAST_START = function(unit, castGUID, spellID, castBarID)
        Skippy.UpdateCastingInfo(unit)
    end,
    UNIT_SPELLCAST_STOP = function(unit, castGUID, spellID, castBarID)
        Skippy.UpdateCastingInfo(unit)
    end,
    UNIT_SPELLCAST_FAILED = function(unit, castGUID, spellID, castBarID)
        if not spellID then return end
        Skippy.UpdateChannelingInfo(unit)
        Skippy.UpdateCastingInfo(unit)
        Skippy.updateGroupInsight(unit)
        Skippy.UpdateFailedSpell(unit, spellID)
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(unit, castGUID, spellID, castBarID)
        if not spellID then return end
        Skippy.UpdateChannelingInfo(unit)
        Skippy.UpdateCastingInfo(unit)
        Skippy.UpdateInsertSpell(spellID)
    end,
    UNIT_SPELLCAST_INTERRUPTED = function(unit, castGUID, spellID, interruptedBy, castBarID)
        Skippy.UpdateChannelingInfo(unit)
        Skippy.UpdateCastingInfo(unit)
    end,

    UNIT_INVENTORY_CHANGED = function(unit)
        if unit ~= "player" then return end
        Skippy.State.hasMainHandEnchant = GetWeaponEnchantInfo()
    end,

    SPELL_UPDATE_COOLDOWN = function(spellID, baseSpellID, category, startRecoveryCategory)
        if spellID then Skippy.UpdateSpellCooldown(spellID) end
    end,
    SPELL_UPDATE_CHARGES = function()
        Skippy.UpdateSpellCharges()
    end,

    TRAIT_CONFIG_UPDATED = function(configID) end,

    GLYPH_ADDED = function()
        Skippy.GetGlyphInfo()
    end,
    GLYPH_REMOVED = function()
        Skippy.GetGlyphInfo()
    end,
    GLYPH_UPDATED = function()
        Skippy.GetGlyphInfo()
    end,

    NAME_PLATE_UNIT_ADDED = function(unit)
        Skippy.GetUnitInfo(unit)
    end,
    NAME_PLATE_UNIT_REMOVED = function(unit)
        Skippy.Units.Nameplate[unit] = nil
    end,

    ENCOUNTER_START = function(encounterID, encounterName, difficultyID, groupSize)
        Skippy.InitBossUnit()
    end,
    ENCOUNTER_END = function(encounterID, encounterName, difficultyID, groupSize, success)
        Skippy.InitBossUnit()
    end,
    BOSS_KILL = function(encounterID, encounterName)
        Skippy.InitBossUnit()
    end,

    GROUP_ROSTER_UPDATE = function()
        Skippy.UpdatePlayerInPartyOrRaid()
        Skippy.UpdateGroupUnit()
    end,

    UI_ERROR_MESSAGE = function(errorType, message)
        if message == "目标不在视野中" then
            Skippy.updateGroupInsight()
        end
    end,
}

--==============================================================================
--  初始化数据
--==============================================================================
local specIndex = C_SpecializationInfo.GetSpecialization()
local specID = C_SpecializationInfo.GetSpecializationInfo(specIndex)
local className, classFilename, classId = UnitClass("player")
Skippy.State.class = className
Skippy.State.classId = classId
Skippy.State.specIndex = specIndex
Skippy.State.specID = specID
Skippy.State.inParty = UnitInParty("player")
Skippy.State.inRaid = UnitInRaid("player")
Skippy.State.shapeshiftFormID = GetShapeshiftFormID() or 0
Skippy.State.isMoving = false
Skippy.State.isCombat = UnitAffectingCombat("player")
Skippy.State.isChatOpen = false
Skippy.State.isMounted = IsMounted("player")
Skippy.State.isDead = UnitIsDeadOrGhost("player")
Skippy.State.CastTargetName = nil
Skippy.State.CastTargetUnit = nil
Skippy.State.hasMainHandEnchant = GetWeaponEnchantInfo()

Skippy.State.healthInfo = {}
Skippy.State.power = {}
Skippy.State.auras = {}
Skippy.State.totems = {}
Skippy.State.shapeshiftForm = {}

do
    for powerType, _ in pairs(EnumPowerType) do
        Skippy.UpdatePower("player", powerType)
    end
end

-- Hook 所有默认聊天框
function Skippy.hookChatFrameEditBox()
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then
            editBox:HookScript("OnEditFocusGained", function()
                Skippy.State.isChatOpen = true
            end)
            editBox:HookScript("OnEditFocusLost", function()
                Skippy.State.isChatOpen = false
            end)
        end
    end
end

function Skippy.CreateClassMacros(id)
    local config = classMacroConfig[id]
    if not config then
        Skippy.macrosReady = false
        return false
    end
    Skippy.CreateMacros(config.unit, config.static)
    Skippy.macrosReady = true
    return true
end

local function initClassMacros()
    Skippy.CreateClassMacros(Skippy.State.classId)
    WeakAuras.ScanEvents("SKIPPY_INIT_COMPLETE")
end

if InCombatLockdown() then
    local macroInitFrame = CreateFrame("Frame")
    macroInitFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    macroInitFrame:SetScript("OnEvent", function(self)
        initClassMacros()
        self:UnregisterAllEvents()
    end)
else
    initClassMacros()
end

Skippy.GetUnitInfo("player")    -- 获取玩家信息
Skippy.GetCharacterTalentInfo() -- 更新组单位信息
Skippy.InitBossUnit()           -- 初始化Boss单位
Skippy.GetCharacterTalentInfo() -- 获取角色天赋信息
Skippy.GetSpellBookInfo()       -- 获取技能书信息
Skippy.GetGlyphInfo()           -- 获取Glyph信息
Skippy.UpdateAllTotem()         -- 更新所有图腾信息
Skippy.UpdateShapeshiftForm()   -- 更新玩家形态信息
Skippy.UpdateGroupUnit()        -- 更新组单位信息

--==============================================================================
--  查找单位或数量的相关函数
--==============================================================================
-- 判断单位是否有效
local function existsUnit(data)
    return data.inRange and data.canAssist and data.inSight and not data.isDead
end

local function getAuraOwner(unit)
    if unit == "player" then
        return Skippy.State
    end
    return GetUnitObj(unit)
end

local function isAuraFromPlayer(aura, byPlayerOnly)
    return not byPlayerOnly or aura.sourceUnit == "player"
end

local function getUnitAura(unit, key, value, byPlayerOnly)
    local obj = getAuraOwner(unit)
    if not obj or not obj.auras then return nil end

    for _, aura in pairs(obj.auras) do
        if aura[key] == value and isAuraFromPlayer(aura, byPlayerOnly) then
            return aura
        end
    end
    return nil
end

---@param unit string 单位名称，如：party1、raid2...
---@param auraName string 光环名称
---@param byPlayerOnly boolean 是否只返回玩家光环
---@return table|nil auraTable 光环信息
local function getUnitAuraByName(unit, auraName, byPlayerOnly)
    return getUnitAura(unit, "name", auraName, byPlayerOnly)
end

---@param unit string 单位名称，如：party1、raid2...
---@param spellId number 法术ID
---@param byPlayerOnly boolean 是否只返回玩家光环
---@return table|nil auraTable 光环信息
local function getUnitAuraBySpellId(unit, spellId, byPlayerOnly)
    return getUnitAura(unit, "spellId", spellId, byPlayerOnly)
end

-- 创建光环名称集合
---@param auraTable table 光环名称列表
---@return table 光环名称集合
local function makeAuraSet(auraTable)
    local set = {}
    for _, name in ipairs(auraTable or {}) do
        set[name] = true
    end
    return set
end

local function normalizeRole(role)
    return role ~= "" and role or nil
end

local function matchRole(data, role, hasRole)
    role = normalizeRole(role)
    if hasRole == nil then hasRole = true end
    if not role then return true end
    return (data.role == role) == hasRole
end

local function findLowestGroupUnit(predicate)
    local lowestUnit = nil
    local lowestHealth = 100
    local lowestAura = nil

    for unit, data in pairs(Skippy.Units.Group) do
        local healthPercent = data.healthPercent
        if healthPercent and existsUnit(data) then
            local matched, aura = predicate(unit, data, healthPercent)
            if matched and healthPercent < lowestHealth then
                lowestHealth = healthPercent
                lowestUnit = unit
                lowestAura = aura
            end
        end
    end

    return lowestUnit, lowestHealth, lowestAura
end

-- 获取玩家光环
---@param auraName string 光环名称
---@param byPlayerOnly boolean 是否只返回玩家光环
---@return table|nil auraTable 光环信息
function Skippy.GetPlayerAuraByName(auraName, byPlayerOnly)
    if byPlayerOnly == nil then byPlayerOnly = true end
    local aura = getUnitAuraByName("player", auraName, byPlayerOnly)
    return aura
end

---获取当前施法剩余时间Ms
---@param reversed boolean 正序或倒序，默认倒序
---@return number|nil 施法剩余时间(秒)，如果没有在施法中则返回 nil
function Skippy.GetCastingDuration(reversed)
    reversed = reversed or false
    local castInfo = Skippy.State.castInfo
    local currentTime = GetTime()
    if not castInfo then return nil end
    local duration = reversed and castInfo.endTimeMS - currentTime * 1000 or castInfo.startTimeMS - currentTime * 1000
    return duration > 0 and duration or nil
end

---获取当前引导剩余时间Ms
---@param reversed boolean 正序或倒序，默认倒序
---@return number|nil 引导剩余时间(秒)，如果没有在引导中则返回 nil
function Skippy.GetChannelingDuration(reversed)
    reversed = reversed or false
    local channelInfo = Skippy.State.channelInfo
    local currentTime = GetTime()
    if not channelInfo then return nil end
    local duration = reversed and channelInfo.endTimeMs - currentTime * 1000 or
        channelInfo.startTimeMs - currentTime * 1000
    return duration > 0 and duration or nil
end

---判断单位是否可以协助
---@param unit string 单位名称，如：party1、raid2...
---@return boolean 是否可以协助
function Skippy.IsUnitCanAssist(unit)
    local obj = GetUnitObj(unit)
    if not obj then return false end
    return obj.canAssist and obj.inRange and obj.inSight and not obj.isDead
end

---@param auraTable table 光环名称或光环ID
---@return boolean 是否包含光环
function Skippy.GetPlayerAurasByTable(auraTable)
    local auraSet = makeAuraSet(auraTable)
    for _, aura in pairs(Skippy.State.auras) do
        if auraSet[aura.name] or auraSet[aura.spellId] then
            return true
        end
    end
    return false
end

---@return number 所有存活成员的平均血量百分比
function Skippy.GetGroupAverageHealthPct()
    local totalHealth = 0
    local totalMaxHealth = 0
    for unit, data in pairs(Skippy.Units.Group) do
        local healthInfo = data.healthInfo
        if healthInfo and existsUnit(data) then
            totalHealth = totalHealth + (healthInfo.health or 0)
            totalMaxHealth = totalMaxHealth + (healthInfo.healthMax or 0)
        end
    end
    if totalMaxHealth == 0 then return 0 end
    return totalHealth / totalMaxHealth * 100
end

--=========================================
--  查找单位数量相关函数
--=========================================

-- 敌对

---@param range number 范围
---@return number 指定范围内敌人数量（筛选后，图腾不包含在内）
function Skippy.GetEnemyCount(range)
    local count = 0
    local nameplate = Skippy.Units.Nameplate
    if not nameplate then return count end
    for unit, data in pairs(nameplate) do
        if data and data.canAttack and data.creatureID ~= 11 and data.maxRange and data.maxRange <= range then
            count = count + 1
        end
    end
    return count
end

---@param range number 范围
---@param creatureType string 生物类型
---@return number 指定范围内敌人数量
function Skippy.GetEnemyCountWithCreatureType(range, creatureType)
    local count = 0
    local nameplate = Skippy.Units.Nameplate
    if not nameplate then return count end
    for unit, data in pairs(nameplate) do
        if data and data.exists and data.maxRange and data.maxRange <= range and data.creatureType == creatureType then
            count = count + 1
        end
    end
    return count
end

---@param range number 范围
---@param auraName string 光环名称
---@param hasAura boolean 是否包含光环（true: 有该光环的敌人, false: 没有该光环的敌人）
---@param byPlayerOnly boolean 是否只返回玩家施放的光环
---@return number 指定范围内满足条件的敌人数量
function Skippy.GetEnemyCountWithoutAura(range, auraName, hasAura, byPlayerOnly)
    local count = 0
    if hasAura == nil then hasAura = true end
    if byPlayerOnly == nil then byPlayerOnly = true end
    local nameplate = Skippy.Units.Nameplate
    if not nameplate then return count end
    for unit, data in pairs(nameplate) do
        if data and data.maxRange and data.maxRange <= range then
            local aura = getUnitAuraByName(unit, auraName, byPlayerOnly)
            local hasIt = not not aura
            if hasIt == hasAura then
                count = count + 1
            end
        end
    end
    return count
end

-- 友方

---@param healthThreshold number 生命值百分比阈值, 只找到生命值低于这个百分比的单位,默认100
---@return number 符合条件的单位数量
function Skippy.GetGroupCount(healthThreshold)
    healthThreshold = healthThreshold or 100
    local count = 0
    for unit, data in pairs(Skippy.Units.Group) do
        local healthPercent = data.healthPercent
        if existsUnit(data) and healthPercent < healthThreshold then
            count = count + 1
        end
    end
    return count
end

---@param healthThreshold number 生命值百分比阈值, 只统计生命值低于这个百分比的单位, 默认100
---@param auraName string 光环名称，如："恢复"
---@param hasAura boolean 是否包含光环（true: 有该光环的单位, false: 没有该光环的单位）, 默认是true
---@param byPlayerOnly boolean 是否只返回玩家施放的光环, 默认是true
---@param role string|nil 职责，如 "TANK", "HEALER", "DAMAGER"，传 nil 或 "" 表示不限职责
---@param hasRole boolean 是否包含该职责（true: 必须是该职责的单位, false: 排除该职责的单位）, 默认是true
---@return number 符合条件的单位数量
function Skippy.GetGroupCountByAuraState(healthThreshold, auraName, hasAura, byPlayerOnly, role, hasRole)
    healthThreshold = healthThreshold or 100
    if hasAura == nil then hasAura = true end
    if byPlayerOnly == nil then byPlayerOnly = true end
    local count = 0

    for unit, data in pairs(Skippy.Units.Group) do
        local healthPercent = data.healthPercent
        if healthPercent and existsUnit(data) and matchRole(data, role, hasRole) then
            if healthPercent <= healthThreshold then
                local currentAura = getUnitAuraByName(unit, auraName, byPlayerOnly)
                if (not not currentAura) == hasAura then
                    count = count + 1
                end
            end
        end
    end

    return count
end

-- ---@param healthThreshold 生命值百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- ---@param subgroup 小队编号，如1、2、3、4，默认玩家所在小队
-- ---@return 只计算玩家所在小队符合条件的单位数量
-- function Skippy.GetCountInSubGroup(healthThreshold, subgroup)
--     healthThreshold = healthThreshold or 100
--     local count = 0
--     local sub = subgroup or Skippy.Units.player.subgroup
--     for unit, data in pairs(Skippy.Units) do
--         local healthPercent = data.healthPercent
--         if existsUnit(data) and data.subgroup == sub then
--             if healthPercent < healthThreshold then
--                 count = count + 1
--             end
--         end
--     end
--     return count
-- end

--=========================================
--  查找单位相关函数
--=========================================

---@return string|nil 生命值最低的单位
---@return number|nil 生命值百分比
function Skippy.GetLowestUnit()
    local lowestUnit, lowestHealth = findLowestGroupUnit(function()
        return true
    end)
    return lowestUnit, lowestHealth
end

---@param unitId string  单位名称，如：party1、raid2...
---@return string|nil 生命值最低的单位
---@return number|nil 生命值百分比
function Skippy.GetLowestUnitWithoutUnit(unitId)
    local lowestUnit, lowestHealth = findLowestGroupUnit(function(unit)
        return not UnitIsUnit(unit, unitId)
    end)
    return lowestUnit, lowestHealth
end

---@param role1 string 职责，如 "TANK", "HEALER", "DAMAGER"
---@param role2 string 职责，如 "TANK", "HEALER", "DAMAGER"
---@param role3 string 职责，如 "TANK", "HEALER", "DAMAGER"
---@return string|nil 生命值最低的单位
---@return number|nil 生命值百分比
function Skippy.GetLowestUnitWithRoles(role1, role2, role3)
    local lowestUnit, lowestHealth = findLowestGroupUnit(function(_, data)
        local role = data.role
        return (role1 and role == role1) or (role2 and role == role2) or (role3 and role == role3)
    end)
    return lowestUnit, lowestHealth
end

---@param auraName string 光环名称，如："恢复"、"暗言术：痛"
---@param hasAura  boolean 是否包含光环（true: 有该光环的单位, false: 没有该光环的单位）, 默认是true
---@param byPlayerOnly boolean 是否只返回玩家施放的光环, 默认是true
---@param role string|nil 职责，如 "TANK", "HEALER", "DAMAGER"，传 nil 或 "" 表示不限职责
---@param hasRole boolean 是否包含该职责（true: 必须是该职责的单位, false: 排除该职责的单位）, 默认是true
---@return string|nil 生命值最低的单位
---@return number|nil 生命值百分比
---@return table|nil 光环信息
function Skippy.GetLowestUnitByAuraState(auraName, hasAura, byPlayerOnly, role, hasRole)
    if hasAura == nil then hasAura = true end
    if byPlayerOnly == nil then byPlayerOnly = true end

    local lowestUnit, lowestHealth, lowestUnitAura = findLowestGroupUnit(function(unit, data)
        if not matchRole(data, role, hasRole) then return false end
        local currentAura = getUnitAuraByName(unit, auraName, byPlayerOnly)
        return (not not currentAura) == hasAura, currentAura
    end)

    if not lowestUnit then return nil, nil, nil end
    return lowestUnit, lowestHealth, lowestUnitAura
end

---@param auraTable table 光环名称列表，如 { "恢复", "真言术：韧", "牺牲之手" }
---@param byPlayerOnly boolean 是否只返回玩家施放的光环，默认是 true
---@return string|nil 生命值最低的单位
---@return number|nil 生命值百分比
---@return table|nil 光环信息（匹配到的第一个光环的详细数据表）
function Skippy.GetLowestUnitWithAnyAuras(auraTable, byPlayerOnly)
    if not auraTable or #auraTable == 0 then return nil, nil, nil end
    if byPlayerOnly == nil then byPlayerOnly = true end

    local auraSet = makeAuraSet(auraTable)

    local lowestUnit, lowestHealth, lowestUnitAura = findLowestGroupUnit(function(unit)
        local obj = getAuraOwner(unit)
        if not obj or not obj.auras then return false end

        for _, aura in pairs(obj.auras) do
            if auraSet[aura.name] and isAuraFromPlayer(aura, byPlayerOnly) then
                return true, aura
            end
        end

        return false
    end)

    if not lowestUnit then return nil, nil, nil end
    return lowestUnit, lowestHealth, lowestUnitAura
end

---@param dispelName string 驱散名称，如："Curse", "Disease", "Magic", "Poison", and "". "" 是激怒效果.
---@return string|nil 有指定驱散的单位
function Skippy.GetUnitWithdispelName(dispelName)
    for unit, data in pairs(Skippy.Units.Group) do
        if existsUnit(data) then
            for _, aura in pairs(data.auras) do
                if aura.isHarmful and aura.dispelName == dispelName then
                    return unit
                end
            end
        end
    end
    return nil
end
