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
Skippy.iconID = nil
Skippy.HekiliSpellName = nil
Skippy.Go = true
Skippy.SpellInfo = Skippy.SpellInfo or {}
Skippy.SpellBook = Skippy.SpellBook or {}
Skippy.GlyphInfo = Skippy.GlyphInfo or {}
Skippy.TalentInfo = Skippy.TalentInfo or {}
Skippy.InsertSpell = nil
Skippy.InsertTarget = nil
Skippy.Encounter = nil
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
local mounts = {}
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
    -- 战士 (classId 1)：输出/坦克技能均为 /cast 当前目标，全部走 static "spell"
    [1] = {
        unit = {},
        static = {
            { "盾牌格挡" },
            { "雷霆一击" },
            { "巨龙怒吼" },
            { "复仇" },
            { "盾牌猛击" },
            { "斩杀" },
            { "战斗怒吼" },
            { "毁灭打击" },
            { "嗜血" },
            { "巨人打击" },
            { "狂暴之怒" },
            { "风暴之锤" },
            { "怒击" },
            { "英勇打击" },
            { "狂风打击" },
            { "剑刃风暴" },
            { "旋风斩" },
            { "顺劈斩" },
        },
    },
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
            { "清洁术", "target" }, { "圣光术", "target" }, { "圣光闪现", "target" }, { "神圣之光", "target" }, { "神圣震击", "target" },
            { "荣耀圣令", "target" }, { "圣洁护盾", "target" }, { "圣光普照", "target" }, { "黎明圣光" }, { "洞察圣印" },
            { "神圣恳求" }, { "神圣棱镜", "target" }, { "保护之手", "mouseover" }, { "制裁之拳", "target" }, { "公正圣印" },
            { "力量祝福", "player" }, { "十字军打击", "target" }, { "圣佑术" }, { "圣光之速" }, { "圣殿骑士的裁决", "target" },
            { "圣疗术", "player" }, { "圣盾术" }, { "复仇之怒" }, { "审判", "target" }, { "异端裁决" },
            { "愤怒之锤", "target" }, { "拯救之手", "mouseover" }, { "正义之怒" }, { "正义之锤", "target" }, { "正义圣印" },
            { "洞察圣印" }, { "清算", "target" }, { "牺牲之手", "mouseover" }, { "王者祝福", "player" }, { "盲目之光" },
            { "真理圣印" }, { "神圣风暴" }, { "自由之手", "mouseover" }, { "虔诚光环" }, { "责难", "target" },
            { "超度邪恶", "target" }, { "超脱" }, { "远古列王守卫" }, { "驱邪术", "target" }, { "圣光之锤", "player" },
            { "处决宣判", "target" }, { "复仇者之盾", "target" }, { "奉献" }, { "奉献" }, { "正义盾击", "target" },
            { "永恒之火", "player" }, { "炽热防御者" }, { "神圣复仇者" }, { "神圣愤怒" },
        },
    },
    -- 牧师 (classId 5)：戒律(256) + 神圣(257)
    [5] = {
        unit = {
            "纯净术", "恢复", "真言术：盾", "苦修", "愈合祷言", "治疗术",
            "联结治疗", "强效治疗术", "快速治疗", "圣言术：静",
        },
        static = {
            { "绝望祷言" }, { "心灵专注" }, { "治疗祷言" }, { "天使长" },
            { "暗影魔", "target" }, { "神圣之火", "target" }, { "惩击", "target" },
            { "治疗之环", "player" },
        },
    },
    -- 萨满祭司 (classId 7)：恢复(264)
    [7] = {
        unit = {
            "大地之盾", "激流", "治疗链", "治疗之涌", "强效治疗波", "治疗波",
        },
        static = {
            { "大地生命武器" }, { "水之护盾" }, { "治疗之泉图腾" }, { "元素释放" },
        },
    },
    -- 武僧 (classId 10)：踏风/织雾(270)
    [10] = {
        unit = {
            "禅意珠", "复苏之雾", "升腾之雾", "真气波", "抚慰之雾", "氤氲之雾",
        },
        static = {
            { "法力茶" }, { "振魂引" }, { "雷光聚神茶" }, { "移花接木" }, { "真气爆裂" },
            { "真气酒" }, { "神鹤引项踢" },
            { "幻灭踢", "target" }, { "猛虎掌", "target" }, { "贯日击", "target" },
        },
    },
    -- 德鲁伊 (classId 11)：恢复(105)
    [11] = {
        unit = {
            "生命绽放", "愈合", "回春术", "治疗之触", "滋养", "迅捷治愈",
        },
        static = {
            { "野性成长" }, { "自然迅捷" },
        },
    },
}
local travelNumber = {
    [3] = true,  -- 旅行形态
    [4] = true,  -- 水栖形态
    [16] = true, -- 幽灵狼
    [27] = true, -- 飞行形态
    [29] = true, -- 飞行形态
}

local function updateGo()
    local go = true
    local state = Skippy.State
    local travel = travelNumber[state.shapeshiftFormID]
    if state.isMounted or state.isDead or state.isChatOpen or travel or state.stealth or state.isCastingMount then
        go = false
    end
    Skippy.Go = go
end


--==============================================================================
--  宏相关
--==============================================================================
Skippy.SpellMap = {}
local macroText = {}
local macroList = {}
local macroKind = {}
local macroBindingOwner = CreateFrame("Frame", "SkippyMacroBindingOwner", UIParent)
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
            local key = m .. "-" .. k
            macroKind[i] = key
            -- print(i, macroKind[i])
            i = i + 1
        end
    end
end

local UNITS_PER_SPELL = 25

local classSpecMacroConfig = {
    [5] = {
        [256] = {
            unit = {
                "纯净术",
                "治疗术",
                "强效治疗术",
                "快速治疗",
                "恢复",
                "真言术：盾",
                "苦修",
                "愈合祷言",
            },
            static = {
                { "天使长" },
                { "希望圣歌" },
                { "心灵专注" },
                { "心灵之火" },
                { "心灵尖啸" },
                { "心灵意志" },
                { "惩击", "target" },
                { "摧心魔", "target" },
                { "暗言术：灭", "target" },
                { "暗言术：痛", "target" },
                { "束缚亡灵", "target" },
                { "治疗祷言", "player" },
                { "渐隐术" },
                { "漂浮术", "target" },
                { "灵魂护壳" },
                { "痛苦压制", "target" },
                { "痛苦压制", "mouseover" },
                { "真言术：障", "cursor" },
                { "真言术：韧", "player" },
                { "神圣之火", "target" },
                { "精神灼烧", "target" },
                { "绝望祷言" },
                { "群体驱散", "mouseover" },
                { "联结治疗", "target" },
                { "苦修", "target" },
                { "虚空触须" },
                { "防护恐惧结界", "target" },
                { "驱散魔法", "target" },
            },
        },
        [257] = classMacroConfig[5],
        [258] = {
            unit = {
                "恢复", "真言术：盾", "苦修", "愈合祷言", "治疗术",
                "联结治疗", "强效治疗术", "快速治疗", "圣言术：静",
            },
            static = {
                { "绝望祷言" }, { "心灵专注" }, { "治疗祷言" }, { "天使长" },
                { "暗影魔", "target" }, { "神圣之火", "target" }, { "惩击", "target" },
                { "治疗之环", "player" },
            },
        },
    },
    [7] = {
        [264] = classMacroConfig[7],
    },
    [10] = {
        [270] = classMacroConfig[10],
    },
    [11] = {
        [105] = classMacroConfig[11],
    },
}

local function getClassMacroConfig(classId, specID)
    local specConfig = classSpecMacroConfig[classId]
    if specConfig then
        return specConfig[specID] or specConfig.default
    end
    return classMacroConfig[classId]
end

local function clearClassMacroBindings()
    ClearOverrideBindings(macroBindingOwner)
    Skippy.SpellMap = {}
    wipe(macroText)

    for _, btn in pairs(macroList) do
        btn:SetAttribute("macrotext", nil)
    end
end

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
    end

    btn:SetAttribute("macrotext", macro)
    macroText[name] = macro

    if key and key ~= "" then
        SetOverrideBindingClick(macroBindingOwner, false, key, btn:GetName(), "LeftButton")
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
function Skippy.updateSpellIndex(spellName, unit)
    if not spellName then
        Skippy.iconID = nil
        Skippy.index = 0
        return false, "请输入技能"
    end
    if not Skippy.SpellMap then
        Skippy.iconID = nil
        Skippy.index = 0
        return false, "没有宏列表"
    end
    if spellName == "暂停" then
        Skippy.iconID = 134376
        Skippy.index = 0
        return true, "暂停"
    end
    if spellName == "休息" then
        Skippy.iconID = 136090
        Skippy.index = 0
        return true, "休息"
    end
    if not Skippy.SpellMap[spellName] then
        Skippy.iconID = nil
        Skippy.index = 0
        return false, "没有技能宏"
    end
    local spellInfo = Skippy.SpellInfo[spellName]
    if spellInfo then
        Skippy.iconID = spellInfo.spellInfo.iconID
    end
    if unit then
        local index = Skippy.SpellMap[spellName][unit]
        if index then
            Skippy.index = index
            if unit == "spell" then
                return true, "施放: " .. spellName
            else
                return true, "目标: " .. unit .. "\n施放:" .. spellName
            end
        end
    else
        local index = Skippy.SpellMap[spellName]["spell"]
        if index then
            Skippy.index = index
            return true, "施放: " .. spellName
        end
    end
    return false, "没有技能宏"
end

---@param spellName string
---@param unit string
function Skippy.InsertSpellByNameAndUnit(spellName, unit)
    if spellName and Skippy.SpellMap[spellName] then
        if unit then
            local index = Skippy.SpellMap[spellName][unit]
            if index then
                Skippy.InsertSpell = spellName
                Skippy.InsertTarget = unit
                print(Skippy.InsertSpell, Skippy.InsertTarget)
                return true
            end
        end
    end
end

_G["Skippy_InsertSpell"] = function(spellName, unit)
    print(spellName, unit)
end

print("全局函数是否存在:", _G["Skippy_InsertSpell"] ~= nil)

-- 把单位归类到所属容器：返回 容器表, 键, 是否单例(target/focus)
-- 单例存放在 Skippy.Units 顶层、清理时重置为空表；其余存放在对应子表、清理时移除
local function classifyUnit(unit)
    if not unit then return nil end
    if unit == "target" or unit == "focus" then
        return Skippy.Units, unit, true
    elseif unit == "player" or unit:match("^party%d+$") or unit:match("^raid%d+$") then
        return Skippy.Units.Group, unit, false
    elseif unit:match("^boss%d+$") then
        return Skippy.Units.Boss, unit, false
    elseif unit:match("^nameplate%d+$") then
        return Skippy.Units.Nameplate, unit, false
    end
    return nil
end

local function getMountsInfo()
    local numMounts = C_MountJournal.GetNumDisplayedMounts()
    for i = 1, numMounts do
        local _, spellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetDisplayedMountInfo(i)
        if isCollected then
            mounts[spellID] = true
        end
    end
end

local function isPlayerCastingMount(unit, spellId)
    if unit ~= "player" then return end
    local isCastingMounts = mounts[spellId]
    Skippy.State.isCastingMount = isCastingMounts
    updateGo()
end

local function isPlayerStopCastingMount(unit)
    if unit ~= "player" then return end
    Skippy.State.isCastingMount = false
    updateGo()
end

-- 获取单位对象
local function GetUnitObj(unit)
    local container, key = classifyUnit(unit)
    if not container or not key then return nil end
    return container[key]
end

-- 确保单位对象
local function EnsureUnitObj(unit)
    local container, key = classifyUnit(unit)
    if not container or not key then return nil end
    local obj = container[key]
    if not obj then
        obj = {}
        container[key] = obj
    end
    return obj
end

local function ClearUnitObj(unit)
    local container, key, singleton = classifyUnit(unit)
    if not container or not key then return end
    if singleton then
        container[key] = {}
    else
        container[key] = nil
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
        Skippy.GetUnitInfo("boss" .. i, true)
    end
    Skippy.SyncUnitList()
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
    if not spellIdentifier then return nil end
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
            local getName = spellFunc[spellType]
            local spellName = getName and getName(id)
            if spellName then
                Skippy.SpellBook[spellName] = true
            end
        end
    end

    for spellName in pairs(Skippy.SpellBook) do
        addSpellInfo(spellName)
    end
end

-- 判断是否学会某技能（名称或ID）
function Skippy.IsSpellKnown(spellIdentifier)
    local name = C_Spell.GetSpellName(spellIdentifier) or spellIdentifier
    return Skippy.SpellBook[name] == true
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
function Skippy.GetSpellCooldownDuration(spellIdentifier)
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
    if not spellIdentifier then return false end
    local spell = Skippy.GetSpellInfo(spellIdentifier)
    local gcd = getGCD()
    local cd = Skippy.GetSpellCooldownDuration(spellIdentifier)
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
    if not Skippy.SpellMap[spell.spellInfo.name] or not Skippy.SpellMap[spell.spellInfo.name][unit] then
        return false
    end
    local inSpellRange = C_Spell.IsSpellInRange(spellIdentifier, unit)
    return inSpellRange
end

-- 获取Hekili技能列表
local hekiliList = {}
function Skippy.GetHekiliSpellName(event_ability_id)
    if not hekiliList[event_ability_id] then
        local name = C_Spell.GetSpellName(event_ability_id)
        if name then
            hekiliList[event_ability_id] = name
            return name
        else
            return nil
        end
    end
    return hekiliList[event_ability_id]
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

-- 由 healthInfo 计算血量百分比，返回 含预读盾百分比, 真实百分比
local function computeHealthPercent(obj)
    local hi = obj.healthInfo
    if not hi then return 0, 0 end
    local h = hi.health or 0
    local m = hi.healthMax or 0
    local a = hi.healAbsorbs or 0
    local p = hi.healPrediction or 0
    if m <= 0 then return 0, 0 end
    return math.max(0, (h - a + p) / m * 100), math.max(0, (h - a) / m * 100)
end

-- 把血量百分比写回单位对象，player 同步镜像到 State.healthInfo
local function applyHealthPercent(unit, obj)
    obj.healthPercent, obj.realHealthPercent = computeHealthPercent(obj)
    if unit == "player" then
        Skippy.State.healthInfo.healthPercent = obj.healthPercent
        Skippy.State.healthInfo.realHealthPercent = obj.realHealthPercent
    end
end

-- 计算血量百分比
function Skippy.UpdateUnitHealth(unit)
    local obj = GetUnitObj(unit)
    if obj and obj.healthInfo then
        applyHealthPercent(unit, obj)
    end
end

-- 获取单位完整血量信息
function Skippy.GetFullHealth(unit)
    local obj = GetUnitObj(unit)
    if obj then
        local hi = obj.healthInfo
        if not hi then
            hi = {}
            obj.healthInfo = hi
        end
        hi.health = UnitHealth(unit)
        hi.healthMax = UnitHealthMax(unit)
        hi.healAbsorbs = UnitGetTotalHealAbsorbs(unit)
        hi.healPrediction = UnitGetIncomingHeals(unit)
    end
    Skippy.UpdateUnitHealth(unit)
end

-- 更新所有图腾信息
function Skippy.UpdateAllTotem()
    for i = 1, 4 do -- 1:火,2:土,3:水,4:空气
        Skippy.UpdateTotem(i)
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
            if not buff then break end
            obj.auras[buff.auraInstanceID] = buff
        end
        for i = 1, 40 do
            local debuff = C_UnitAuras.GetDebuffDataByIndex(unit, i)
            if not debuff then break end
            obj.auras[debuff.auraInstanceID] = debuff
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
-- skipSync=true 时跳过单位列表同步，供批量循环调用，循环结束后再统一调用一次 SyncUnitList
function Skippy.GetUnitInfo(unit, skipSync)
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
    if not skipSync then
        Skippy.SyncUnitList()
    end
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
        data.canAttack = UnitCanAttack("player", unit)
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

    applyHealthPercent(unit, obj)
end

-- 事件更新 能量信息
function Skippy.UpdatePower(unit, powerType)
    if unit ~= "player" then return end
    local powerIndex = EnumPowerType[powerType]
    if not powerIndex then return end
    -- 复用已有表（避免每次能量跳动新建表造成 GC 抖动）；不存在则建置零表，杜绝下游 nil 索引
    local power = Skippy.State.power[powerType]
    if not power then
        power = { powerValue = 0, powerMax = 0, powerPercent = 0 }
        Skippy.State.power[powerType] = power
    end
    local powerMax = UnitPowerMax(unit, powerIndex)
    local powerValue = UnitPower(unit, powerIndex)
    power.powerValue = powerValue
    power.powerMax = powerMax
    power.powerPercent = powerMax > 0 and (powerValue / powerMax * 100) or 0
end

-- 事件更新 图腾信息
function Skippy.UpdateTotem(i)
    local _, totemName, startTime, duration, _, _, spellID = GetTotemInfo(i)
    if totemName ~= "" then
        local t = Skippy.State.totems[i]
        if not t then
            t = {}
            Skippy.State.totems[i] = t
        end
        t.name = totemName
        t.startTime = startTime
        t.duration = duration
        t.spellID = spellID
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
            local c = obj.castInfo
            if not c then
                c = {}
                obj.castInfo = c
            end
            c.name = name
            c.startTimeMS = startTimeMS
            c.endTimeMS = endTimeMS
            c.spellID = spellId
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
            local c = obj.channelInfo
            if not c then
                c = {}
                obj.channelInfo = c
            end
            c.name = name
            c.startTimeMs = startTimeMs
            c.endTimeMs = endTimeMs
            c.spellID = spellID
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
    Skippy.State.CastTargetUnit = nil
    if not name then return end

    local target = Skippy.Units.target
    if target and target.name == name then
        Skippy.State.CastTargetUnit = "target"
        return
    end
    local focus = Skippy.Units.focus
    if focus and focus.name == name then
        Skippy.State.CastTargetUnit = "focus"
        return
    end
    for unit, obj in pairs(Skippy.Units.Group) do
        if type(obj) == "table" and obj.name == name then
            Skippy.State.CastTargetUnit = unit
            return
        end
    end
end

-- 事件更新 更新光环
function Skippy.UpdateAuraInfo(unit, info)
    local obj = GetUnitObj(unit)
    if not obj then return end

    if info.isFullUpdate then
        Skippy.UpdateAuraFull(unit)
        return
    end

    if not obj.auras then
        -- player 的 auras 与 State.auras 共享同一张表，增量更新只需写一处
        if unit == "player" then
            Skippy.State.auras = Skippy.State.auras or {}
            obj.auras = Skippy.State.auras
        else
            obj.auras = {}
        end
    end

    if info.addedAuras then
        for _, aura in pairs(info.addedAuras) do
            obj.auras[aura.auraInstanceID] = aura
        end
    end

    if info.updatedAuraInstanceIDs then
        for _, id in pairs(info.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
            if aura then
                obj.auras[id] = aura
            end
        end
    end

    if info.removedAuraInstanceIDs then
        for _, id in pairs(info.removedAuraInstanceIDs) do
            obj.auras[id] = nil
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
    updateGo()
end

-- 事件更新 标记当前施法目标暂时不在视野内（1 秒后恢复）
-- 由调用方决定何时触发（玩家施法失败 / "目标不在视野中" 报错）
function Skippy.updateGroupInsight()
    local castTargetUnit = Skippy.State.CastTargetUnit
    if not castTargetUnit then return end
    local obj = GetUnitObj(castTargetUnit)
    if not obj then return end
    obj.inSight = false
    if obj.inSightTimer then
        obj.inSightTimer:Cancel()
    end
    obj.inSightTimer = C_Timer.NewTimer(1, function()
        obj.inSight = true
        obj.inSightTimer = nil
    end)
end

-- 事件更新 获取玩家天赋信息
function Skippy.GetCharacterTalentInfo()
    Skippy.TalentInfo = {}
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    Skippy.State.specIndex = specIndex
    Skippy.State.specID = specID
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
        Skippy.GetUnitInfo(unit, true)
    end
    Skippy.SyncUnitList()
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
        local previousSpecID = Skippy.State.specID
        Skippy.GetCharacterTalentInfo()
        if previousSpecID ~= Skippy.State.specID then
            Skippy.RebuildClassMacros()
        end
    end,
    PLAYER_SPECIALIZATION_CHANGED = function(unit)
        if unit and unit ~= "player" then return end
        local previousSpecID = Skippy.State.specID
        Skippy.GetCharacterTalentInfo()
        if previousSpecID ~= Skippy.State.specID then
            Skippy.RebuildClassMacros()
        end
    end,
    ACTIVE_TALENT_GROUP_CHANGED = function()
        local previousSpecID = Skippy.State.specID
        Skippy.GetCharacterTalentInfo()
        if previousSpecID ~= Skippy.State.specID then
            Skippy.RebuildClassMacros()
        end
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
        updateGo()
    end,
    PLAYER_ALIVE = function()
        Skippy.State.isDead = UnitIsDeadOrGhost("player")
        updateGo()
    end,
    PLAYER_UNGHOST = function()
        Skippy.State.isDead = UnitIsDeadOrGhost("player")
        updateGo()
    end,
    PLAYER_MOUNT_DISPLAY_CHANGED = function()
        Skippy.State.isMounted = IsMounted("player")
        updateGo()
    end,
    UPDATE_STEALTH = function()
        Skippy.State.stealth = C_UnitAuras.GetPlayerAuraBySpellID(5215)
        Skippy.State.vanish = C_UnitAuras.GetPlayerAuraBySpellID(11327)
        Skippy.State.catStealth = Skippy.State.shapeshiftFormID == 1 and Skippy.State.stealth
        updateGo()
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
        isPlayerCastingMount(unit, spellID)
    end,
    UNIT_SPELLCAST_STOP = function(unit, castGUID, spellID, castBarID)
        isPlayerStopCastingMount(unit)
        Skippy.UpdateCastingInfo(unit)
    end,
    UNIT_SPELLCAST_FAILED = function(unit, castGUID, spellID, castBarID)
        isPlayerStopCastingMount(unit)
        if not spellID then return end
        Skippy.UpdateChannelingInfo(unit)
        Skippy.UpdateCastingInfo(unit)
        if unit == "player" then
            Skippy.updateGroupInsight()
        end
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(unit, castGUID, spellID, castBarID)
        isPlayerStopCastingMount(unit)
        if not spellID then return end
        Skippy.UpdateChannelingInfo(unit)
        Skippy.UpdateCastingInfo(unit)
    end,
    UNIT_SPELLCAST_INTERRUPTED = function(unit, castGUID, spellID, interruptedBy, castBarID)
        isPlayerStopCastingMount(unit)
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
        Skippy.Encounter = {
            encounterID = encounterID,
            encounterName = encounterName,
            difficultyID = difficultyID,
            groupSize = groupSize,
        }
        Skippy.InitBossUnit()
    end,
    ENCOUNTER_END = function(encounterID, encounterName, difficultyID, groupSize, success)
        Skippy.Encounter = nil
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
Skippy.State.isCastingMount = false

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
                updateGo()
            end)
            editBox:HookScript("OnEditFocusLost", function()
                Skippy.State.isChatOpen = false
                updateGo()
            end)
        end
    end
end

Skippy.hookChatFrameEditBox()

function Skippy.CreateClassMacros(id)
    local specID = Skippy.State.specID
    local config = getClassMacroConfig(id, specID)
    clearClassMacroBindings()
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

local macroInitFrame = CreateFrame("Frame")
local macroInitPending = false

macroInitFrame:SetScript("OnEvent", function(self)
    macroInitPending = false
    initClassMacros()
    self:UnregisterAllEvents()
end)

function Skippy.RebuildClassMacros()
    if InCombatLockdown() then
        Skippy.macrosReady = false
        if not macroInitPending then
            macroInitPending = true
            macroInitFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
        return false
    end

    initClassMacros()
    return true
end

if InCombatLockdown() then
    Skippy.RebuildClassMacros()
else
    initClassMacros()
end

Skippy.GetUnitInfo("player")    -- 获取玩家信息
Skippy.InitBossUnit()           -- 初始化Boss单位
Skippy.GetCharacterTalentInfo() -- 获取角色天赋信息
Skippy.GetSpellBookInfo()       -- 获取技能书信息
Skippy.GetGlyphInfo()           -- 获取Glyph信息
Skippy.UpdateAllTotem()         -- 更新所有图腾信息
Skippy.UpdateShapeshiftForm()   -- 更新玩家形态信息
Skippy.UpdateGroupUnit()        -- 更新组单位信息
getMountsInfo()                 -- 获取玩家坐骑信息

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

-- 获取目标身上指定光环（按名称或法术ID匹配）
---@param auraKey string|number 光环名称或法术ID
---@param byPlayerOnly boolean|nil 是否只取玩家施放的光环
---@return table|nil 光环信息
function Skippy.GetTargetAura(auraKey, byPlayerOnly)
    local target = Skippy.Units.target
    if not target or not target.auras then return nil end
    for _, aura in pairs(target.auras) do
        if (aura.name == auraKey or aura.spellId == auraKey)
            and (not byPlayerOnly or aura.sourceUnit == "player") then
            return aura
        end
    end
    return nil
end

-- 获取目标身上由玩家施放的指定光环
function Skippy.GetTargetAuraByPlayer(auraKey)
    return Skippy.GetTargetAura(auraKey, true)
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

-- 获取玩家光环（按名称或法术ID匹配）
---@param auraKey string|number 光环名称或法术ID
---@param byPlayerOnly? boolean 是否只返回玩家施放的光环，默认 true
---@return table|nil auraTable 光环信息
function Skippy.GetPlayerAuraByName(auraKey, byPlayerOnly)
    if byPlayerOnly == nil then byPlayerOnly = true end
    local auras = Skippy.State.auras
    if not auras then return nil end
    for _, aura in pairs(auras) do
        if (aura.name == auraKey or aura.spellId == auraKey)
            and (not byPlayerOnly or aura.sourceUnit == "player") then
            return aura
        end
    end
    return nil
end

-- 获取玩家单位对象（healthPercent / auras / power 等）
---@return table|nil
function Skippy.GetPlayerInfo()
    return GetUnitObj("player")
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

---判断当前施法是否已（接近）完成
---@param margin number|nil 容差秒数：未施法或剩余时间 <= margin 时视为已完成
---@return boolean
function Skippy.IsFinishedCasting(margin)
    margin = margin or 0
    local castInfo = Skippy.State.castInfo
    if not castInfo or not castInfo.endTimeMS then return true end
    local remaining = castInfo.endTimeMS / 1000 - GetTime()
    return remaining <= margin
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

-- 攻击速度降低 / 攻强降低 减益名称集（坦克辅助用，原 tankhelper.lua 迁入）
local attackSpeedSlowAuras = {
    ["冰霜疫病"] = true,
    ["雷霆一击"] = true,
    ["正义审判"] = true,
    ["感染伤口"] = true,
}
local attackPowerSlowAuras = {
    ["挫志怒吼"] = true,
    ["辩护"] = true,
    ["挫志咆哮"] = true,
    ["虚弱诅咒"] = true,
}

-- 统计 8 码内是否带有指定减益集的敌人数量（图腾 creatureID==11 除外）
---@return number 无该减益的敌人数量
---@return number 有该减益的敌人数量
local function countNameplateSlow(slowSet)
    local noCount, hasCount = 0, 0
    for _, data in pairs(Skippy.Units.Nameplate) do
        if data and data.exists and data.creatureID ~= 11 and data.auras
            and data.maxRange and data.maxRange <= 8 then
            local has = false
            for _, aura in pairs(data.auras) do
                if slowSet[aura.name] then
                    has = true
                    break
                end
            end
            if has then
                hasCount = hasCount + 1
            else
                noCount = noCount + 1
            end
        end
    end
    return noCount, hasCount
end

-- 攻击速度降低：返回 无减益数量, 有减益数量
function Skippy.AttackSpeedSlow()
    return countNameplateSlow(attackSpeedSlowAuras)
end

-- 攻强降低：返回 无减益数量, 有减益数量
function Skippy.AttackPowerSlow()
    return countNameplateSlow(attackPowerSlowAuras)
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
--  if healthPercent < healthThreshold then
--      count = count + 1
--  end
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
---@param hasAura?  boolean 是否包含光环（true: 有该光环的单位, false: 没有该光环的单位）, 默认是true
---@param byPlayerOnly? boolean 是否只返回玩家施放的光环, 默认是true
---@param role? string|nil 职责，如 "TANK", "HEALER", "DAMAGER"，传 nil 或 "" 表示不限职责
---@param hasRole? boolean 是否包含该职责（true: 必须是该职责的单位, false: 排除该职责的单位）, 默认是true
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
---@param byPlayerOnly? boolean 是否只返回玩家施放的光环，默认是 true
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
        if existsUnit(data) and data.auras then
            for _, aura in pairs(data.auras) do
                if aura.isHarmful and aura.dispelName == dispelName then
                    return unit
                end
            end
        end
    end
    return nil
end
