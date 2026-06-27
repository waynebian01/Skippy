if not Skippy or not aura_env.init or Skippy.State.specID ~= 65 then return false end

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
    return aura_env.SendSpell("暂停")
end
-- [洞察圣印]未激活时使用[洞察圣印]
if aura_env.SelflessHealer and not insight then
    return aura_env.SendSpell("洞察圣印", "spell")
end
-- 驱散魔法
if SpellOnUnit("清洁术", debuff_magic) then
    return aura_env.SendSpell("清洁术", debuff_magic)
end
-- 驱散疾病
if SpellOnUnit("清洁术", debuff_disease) then
    return aura_env.SendSpell("清洁术", debuff_disease)
end
-- 驱散中毒
if SpellOnUnit("清洁术", debuff_poison) then
    return aura_env.SendSpell("清洁术", debuff_poison)
end
-- 魔法值低于85%时使用[神圣恳求]
if Spell("神圣恳求") and percentMana < 85 then
    return aura_env.SendSpell("神圣恳求", "spell")
end
-- 对没有[圣洁护盾]的坦克使用[圣洁护盾]
if SpellOnUnit("圣洁护盾", noSacredShieldTank) then
    return aura_env.SendSpell("圣洁护盾", noSacredShieldTank)
end
-- 检测到光环[神圣复仇者]且圣能大于等于3，或者光环[神圣意志]
if (HolyAvenger and holyPower >= 3) or DivinePurpose then
    -- 如果没有学会永恒之火，受伤人数大于等于3时使用[黎明圣光]
    if not aura_env.EternalFlame and Spell("黎明圣光") and count90 >= 4 then
        return aura_env.SendSpell("黎明圣光", "spell")
    end
    -- 否则使用[荣耀圣令]
    if SpellOnUnit("荣耀圣令", lowestUnit) then
        return aura_env.SendSpell("荣耀圣令", lowestUnit)
    end
end
-- 检测到光环[无私治愈]且应用次数为3时使用[圣光普照]或[神圣之光]
if SelflessAura and SelflessAura.applications == 3 then
    if SpellOnUnit("圣光普照", lowestUnit) and count90 >= 3 then
        return aura_env.SendSpell("圣光普照", lowestUnit)
    elseif SpellOnUnit("神圣之光", lowestUnit) then
        return aura_env.SendSpell("神圣之光", lowestUnit)
    end
end
-- 圣能等于最大值时使用[荣耀圣令]
if holyPower == holyPowerMax then
    -- 如果没有学会永恒之火，受伤人数大于等于3时使用[黎明圣光]
    if not aura_env.EternalFlame and Spell("黎明圣光") and count90 >= 4 then
        return aura_env.SendSpell("黎明圣光", "spell")
    end
    -- 否则使用[荣耀圣令]
    if SpellOnUnit("荣耀圣令", lowestUnit) then
        return aura_env.SendSpell("荣耀圣令", lowestUnit)
    end
end
-- 检测到神圣棱镜可用且有治疗目标且圣能大于等于3时使用[神圣棱镜]
if state.isCombat and SpellOnUnit("神圣棱镜", "target") and target.canAttack and count90 >= 3 then
    return aura_env.SendSpell("神圣棱镜", "target")
end
-- 检测到神圣震击可用且有治疗目标时使用[神圣震击]
if SpellOnUnit("神圣震击", lowestUnit) then
    return aura_env.SendSpell("神圣震击", lowestUnit)
end
-- 学会了天赋[无私治愈]，可以攻击目标时使用[审判]
if state.isCombat and aura_env.SelflessHealer and SpellOnUnit("审判", "target") and target.canAttack then
    return aura_env.SendSpell("审判", "target")
end
-- 圣能大于等于3且治疗目标生命值低于70%时使用[荣耀圣令]
if SpellOnUnit("荣耀圣令", lowestUnit) and holyPower >= 3 and lowestHealth < 70 then
    return aura_env.SendSpell("荣耀圣令", lowestUnit)
end
-- 非移动状态时使用[圣光闪现]、[神圣之光]或[圣光术]
if not state.isMoving then
    if SpellOnUnit("圣光闪现", lowestUnit) and lowestHealth < 50 then
        return aura_env.SendSpell("圣光闪现", lowestUnit)
    end
    if SpellOnUnit("神圣之光", lowestUnit) and lowestHealth < 60 then
        return aura_env.SendSpell("神圣之光", lowestUnit)
    end
    -- 使用[圣光术],优先为没有[圣光道标]的单位治疗
    if SpellOnUnit("圣光术", lowestUnit) then
        if noBeaconUnit and noBeaconHealth < 90 then
            return aura_env.SendSpell("圣光术", noBeaconUnit)
        end
        if lowestHealth < 90 then
            return aura_env.SendSpell("圣光术", lowestUnit)
        end
    end
end
-- 战斗中，[十字军打击]可用时使用[十字军打击]
if state.isCombat and SpellOnUnit("十字军打击", "target") and target.canAttack then
    return aura_env.SendSpell("十字军打击", "target")
end

return aura_env.SendSpell("休息")
