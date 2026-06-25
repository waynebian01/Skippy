if not Skippy or not aura_env.init then return end

-- ===== 状态 =====
local state = Skippy.State
local target = Skippy.Units.target
local debuff_magic = Skippy.GetUnitWithdispelName("Magic")
local debuff_disease = Skippy.GetUnitWithdispelName("Disease")
local debuff_poison = Skippy.GetUnitWithdispelName("Poison")
local insight = state.shapeshiftForm["洞察圣印"]
local percentMana = state.power.MANA.powerPercent
local holyPower = state.power.HOLY_POWER.powerValue
local holyPowerMax = state.power.HOLY_POWER.powerMax

-- ===== 变量 =====
local SendSpell = Skippy.updateSpellIndex
local SpellOnUnit = Skippy.IsUsableSpellOnUnit
local Spell = Skippy.IsUsableSpell
local playerAura = Skippy.GetPlayerAuraByName
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local getLowestUnitByAuraState = Skippy.GetLowestUnitByAuraState
local count90 = Skippy.GetGroupCount(90)
local noBeaconUnit, noBeaconHealth = getLowestUnitByAuraState("圣光道标", false, true, nil, false)
local noSacredShieldTank = getLowestUnitByAuraState("圣洁护盾", false, true, "TANK", true)
local DivinePurpose = playerAura("神圣意志", true)
local HolyAvenger = playerAura("神圣复仇者", true)
local SelflessAura = playerAura("无私治愈", true)

-- ===== 逻辑 =====
if not Skippy.Go then
    aura_env.txt = "暂停"
    return SendSpell(nil, nil)
end
-- [洞察圣印]未激活时使用[洞察圣印]
if aura_env.SelflessHealer and not insight then
    aura_env.txt = "洞察圣印"
    return SendSpell("spell", "洞察圣印")
end
-- 驱散魔法
if SpellOnUnit("清洁术", debuff_magic) then
    aura_env.txt = "清洁术"
    return SendSpell(debuff_magic, "清洁术")
end
-- 驱散疾病
if SpellOnUnit("清洁术", debuff_disease) then
    aura_env.txt = "清洁术"
    return SendSpell(debuff_disease, "清洁术")
end
-- 驱散中毒
if SpellOnUnit("清洁术", debuff_poison) then
    aura_env.txt = "清洁术"
    return SendSpell(debuff_poison, "清洁术")
end
-- 魔法值低于85%时使用[神圣恳求]
if Spell("神圣恳求") and percentMana < 85 then
    aura_env.txt = "神圣恳求"
    return SendSpell("spell", "神圣恳求")
end
-- 对没有[圣洁护盾]的坦克使用[圣洁护盾]
if SpellOnUnit("圣洁护盾", noSacredShieldTank) then
    aura_env.txt = "圣洁护盾"
    return SendSpell(noSacredShieldTank, "圣洁护盾")
end
-- 检测到光环[神圣复仇者]且圣能大于等于3，或者光环[神圣意志]
if (HolyAvenger and holyPower >= 3) or DivinePurpose then
    -- 如果没有学会永恒之火，受伤人数大于等于3时使用[黎明圣光]
    if not aura_env.EternalFlame and Spell("黎明圣光") and count90 >= 4 then
        aura_env.txt = "黎明圣光"
        return SendSpell("spell", "黎明圣光")
    end
    -- 否则使用[荣耀圣令]
    if SpellOnUnit("荣耀圣令", lowestUnit) then
        aura_env.txt = "荣耀圣令"
        return SendSpell(lowestUnit, "荣耀圣令")
    end
end
-- 检测到光环[无私治愈]且应用次数为3时使用[圣光普照]或[神圣之光]
if SelflessAura and SelflessAura.applications == 3 then
    if SpellOnUnit("圣光普照", lowestUnit) and count90 >= 3 then
        aura_env.txt = "圣光普照"
        return SendSpell(lowestUnit, "圣光普照")
    elseif SpellOnUnit("神圣之光", lowestUnit) then
        aura_env.txt = "神圣之光"
        return SendSpell(lowestUnit, "神圣之光")
    end
end
-- 圣能等于最大值时使用[荣耀圣令]
if holyPower == holyPowerMax then
    -- 如果没有学会永恒之火，受伤人数大于等于3时使用[黎明圣光]
    if not aura_env.EternalFlame and Spell("黎明圣光") and count90 >= 4 then
        aura_env.txt = "黎明圣光"
        return SendSpell("spell", "黎明圣光")
    end
    -- 否则使用[荣耀圣令]
    if SpellOnUnit("荣耀圣令", lowestUnit) then
        aura_env.txt = "荣耀圣令"
        return SendSpell(lowestUnit, "荣耀圣令")
    end
end
-- 检测到神圣棱镜可用且有治疗目标且圣能大于等于3时使用[神圣棱镜]
if state.isCombat and SpellOnUnit("神圣棱镜", "target") and target.canAttack and count90 >= 3 then
    aura_env.txt = "神圣棱镜"
    return SendSpell("target", "神圣棱镜")
end
-- 检测到神圣震击可用且有治疗目标时使用[神圣震击]
if SpellOnUnit("神圣震击", lowestUnit) then
    aura_env.txt = "神圣震击"
    return SendSpell(lowestUnit, "神圣震击")
end
-- 学会了天赋[无私治愈]，可以攻击目标时使用[审判]
if state.isCombat and aura_env.SelflessHealer and SpellOnUnit("审判", "target") and target.canAttack then
    aura_env.txt = "审判"
    return SendSpell("target", "审判")
end
-- 圣能大于等于3且治疗目标生命值低于70%时使用[荣耀圣令]
if SpellOnUnit("荣耀圣令", lowestUnit) and holyPower >= 3 and lowestHealth < 70 then
    aura_env.txt = "荣耀圣令"
    return SendSpell(lowestUnit, "荣耀圣令")
end
-- 非移动状态时使用[圣光闪现]、[神圣之光]或[圣光术]
if not state.isMoving then
    if SpellOnUnit("圣光闪现", lowestUnit) and lowestHealth < 50 then
        aura_env.txt = "圣光闪现"
        return SendSpell(lowestUnit, "圣光闪现")
    end
    if SpellOnUnit("神圣之光", lowestUnit) and lowestHealth < 60 then
        aura_env.txt = "神圣之光"
        return SendSpell(lowestUnit, "神圣之光")
    end
    -- 使用[圣光术],优先为没有[圣光道标]的单位治疗
    if SpellOnUnit("圣光术", lowestUnit) then
        if noBeaconUnit and noBeaconHealth < 90 then
            aura_env.txt = "圣光术"
            return SendSpell(noBeaconUnit, "圣光术")
        end
        if lowestHealth < 90 then
            aura_env.txt = "圣光术"
            return SendSpell(lowestUnit, "圣光术")
        end
    end
end
-- 战斗中，[十字军打击]可用时使用[十字军打击]
if state.isCombat and SpellOnUnit("十字军打击", "target") and target.canAttack then
    aura_env.txt = "十字军打击"
    return SendSpell("target", "十字军打击")
end
aura_env.txt = "休息..."
return SendSpell(nil, nil)
