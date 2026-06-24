if not Skippy then return end

-- ===== 状态 =====
local state = Skippy.State
local target = Skippy.Units.target
local disperse = Skippy.disperse
local targetCanAttack = target.exists and target.canAttack
local insight = state.shapeshiftForm["洞察圣印"]
local percentMana = state.power.MANA.powerPercent
local holyPower = state.power.HOLY_POWER.powerValue
local holyPowerMax = state.power.HOLY_POWER.powerMax

-- ===== 变量 =====
local UnitHeal = Skippy.UnitHeal
local spell = Skippy.IsUsableSpellOnUnit
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local count90 = Skippy.GetCount(90)
local noBeaconUnit, noBeaconHealth = Skippy.GetLowestUnitWithoutPlayerAuras("圣光道标")
local noSacredShieldTank = Skippy.GetUnitWithoutPlayerAurasAndRole("圣洁护盾", "TANK")
local DivinePurpose = Skippy.GetPlayerAuras("神圣意志")
local HolyAvenger = Skippy.GetPlayerAuras("神圣复仇者")
local SelflessAura = Skippy.GetPlayerAuras("无私治愈")
local EternalFlame = Skippy.SpellBook["永恒之火"] -- 是否学会[永恒之火]
local SealofInsight = Skippy.SpellBook["洞察圣印"] -- 是否学会[洞察圣印]
local SelflessHealer = Skippy.SpellBook["无私治愈"] -- 是否学会[无私治愈]

-- ===== 逻辑 =====
-- [洞察圣印]未激活时使用[洞察圣印]
if SealofInsight and not insight then
    return UnitHeal("spell", "洞察圣印")
end
-- 驱散魔法
if spell("清洁术", disperse.magic) then
    return UnitHeal(disperse.magic, "清洁术")
end
-- 驱散疾病
if spell("清洁术", disperse.disease) then
    return UnitHeal(disperse.disease, "清洁术")
end
-- 驱散中毒
if spell("清洁术", disperse.poison) then
    return UnitHeal(disperse.poison, "清洁术")
end
-- 魔法值低于85%时使用[神圣恳求]
if spell("神圣恳求") and percentMana < 85 then
    return UnitHeal("spell", "神圣恳求")
end
-- 对没有[圣洁护盾]的坦克使用[圣洁护盾]
if spell("圣洁护盾", noSacredShieldTank) then
    return UnitHeal(noSacredShieldTank, "圣洁护盾")
end
-- 检测到光环[神圣复仇者]且圣能大于等于3，或者光环[神圣意志]
if (HolyAvenger and holyPower >= 3) or DivinePurpose then
    -- 如果没有学会永恒之火，受伤人数大于等于3时使用[黎明圣光]
    if not EternalFlame and spell("黎明圣光") and count90 >= 4 then
        return UnitHeal("spell", "黎明圣光")
    end
    -- 否则使用[荣耀圣令]
    if spell("荣耀圣令", lowestUnit) then
        return UnitHeal(lowestUnit, "荣耀圣令")
    end
end
-- 检测到光环[无私治愈]且应用次数为3时使用[圣光普照]或[神圣之光]
if SelflessAura and SelflessAura.applications == 3 then
    if spell("圣光普照", lowestUnit) and count90 >= 3 then
        return UnitHeal(lowestUnit, "圣光普照")
    elseif spell("神圣之光", lowestUnit) then
        return UnitHeal(lowestUnit, "神圣之光")
    end
end
-- 圣能等于最大值时使用[荣耀圣令]
if holyPower == holyPowerMax then
    -- 如果没有学会永恒之火，受伤人数大于等于3时使用[黎明圣光]
    if not EternalFlame and spell("黎明圣光") and count90 >= 4 then
        return UnitHeal("spell", "黎明圣光")
    end
    -- 否则使用[荣耀圣令]
    if spell("荣耀圣令", lowestUnit) then
        return UnitHeal(lowestUnit, "荣耀圣令")
    end
end
-- 检测到神圣棱镜可用且有治疗目标且圣能大于等于3时使用[神圣棱镜]
if state.isCombat and spell("神圣棱镜", "target") and targetCanAttack and count90 >= 3 then
    return UnitHeal("target", "神圣棱镜")
end
-- 检测到神圣震击可用且有治疗目标时使用[神圣震击]
if spell("神圣震击", lowestUnit) then
    return UnitHeal(lowestUnit, "神圣震击")
end
-- 学会了天赋[无私治愈]，可以攻击目标时使用[审判]
if state.isCombat and SelflessHealer and spell("审判", "target") and targetCanAttack then
    return UnitHeal("target", "审判")
end
-- 圣能大于等于3且治疗目标生命值低于70%时使用[荣耀圣令]
if spell("荣耀圣令", lowestUnit) and holyPower >= 3 and lowestHealth < 70 then
    return UnitHeal(lowestUnit, "荣耀圣令")
end
-- 非移动状态时使用[圣光闪现]、[神圣之光]或[圣光术]
if not state.isMoving then
    if spell("圣光闪现", lowestUnit) and lowestHealth < 50 then
        return UnitHeal(lowestUnit, "圣光闪现")
    end
    if spell("神圣之光", lowestUnit) and lowestHealth < 60 then
        return UnitHeal(lowestUnit, "神圣之光")
    end
    -- 使用[圣光术],优先为没有[圣光道标]的单位治疗
    if spell("圣光术", lowestUnit) then
        if noBeaconUnit and noBeaconHealth < 90 then
            return UnitHeal(noBeaconUnit, "圣光术")
        end
        if lowestHealth < 90 then
            return UnitHeal(lowestUnit, "圣光术")
        end
    end
end
-- 战斗中，[十字军打击]可用时使用[十字军打击]
if state.isCombat and spell("十字军打击", "target") and targetCanAttack then
    return UnitHeal("target", "十字军打击")
end

return UnitHeal("None", "None")
