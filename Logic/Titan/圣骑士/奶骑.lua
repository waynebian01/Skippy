if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.UnitHeal then return end
if Skippy.State.class ~= "圣骑士" then return end
if not Skippy.State.inParty then return Skippy.UnitHeal("Skip", "Skip") end

-- ===== 状态 =====
local e = aura_env
local state = Skippy.State
local castInfo = state.castInfo
local target = Skippy.Units.target
local targetCanAttack = target.exists and target.canAttack and not target.isDead
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100

-- ===== 变量 =====
local UnitHeal = Skippy.UnitHeal
local spell = Skippy.IsUsableSpellOnUnit
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local judgement = Skippy.GetTargetAurasByPlayer(aura_env.Judgement)
local noBeaconUnit, noBeaconHealth = Skippy.GetLowestUnitWithoutPlayerAuras("圣光道标")
local hasBeaconUnit = Skippy.GetUnitWithPlayerAura("圣光道标")
local SealofWisdom = Skippy.GetPlayerAuraByName("智慧圣印")
local InfusionofLight = Skippy.GetPlayerAuraByName("圣光灌注")
local DivineFavor = Skippy.GetPlayerAuraByName("神恩术")
local HealingTrance = Skippy.GetPlayerAuraByName(60513) -- [治疗入定],[护魂者]饰品特效，减少800蓝耗.
local hasMagicUnit = Skippy.disperse.magic
local hasDiseaseUnit = Skippy.disperse.disease
local hasPoisonUnit = Skippy.disperse.poison

-- ===== 逻辑 =====
-- 当正在治疗的单位真实生命值为100%，将会在最后0.2秒停止施法
if state.cast and castInfo then
    -- 当有[治疗入定]和正在施放[圣光闪现]时,中断圣光闪现
    if HealingTrance and e.isCastingFlashLight then
        return UnitHeal("spell", "停止施法")
    end
    -- 当施放[圣光术]时,设定[治疗入定]为false
    if e.isCastingHolyLight then
        HealingTrance = false
    end
    -- 当正在施放[圣光术]或[圣光闪现]时,检查是否需要停止施法
    if e.healingUnit and (e.isCastingHolyLight or e.isCastingFlashLight) then
        local finishTime = e.CastingEndTime - GetTime() -- 施法剩余时间
        local stopCastTime = 0.5                        -- 停止施法时间

        -- 如果施法剩余时间大于stopCastTime，则什么也不做
        if finishTime > stopCastTime then
            return UnitHeal("None", "None")
        end
        -- 施法目标的实际生命值
        local castTargetRealHealth = UnitHealth(e.healingUnit) / UnitHealthMax(e.healingUnit)
        if hasBeaconUnit then
            -- 有[圣光道标]的单位的实际生命值
            local hasBeaconUnitRealHealth = UnitHealth(hasBeaconUnit) / UnitHealthMax(hasBeaconUnit)
            -- 当有[圣光道标]时,检查施法目标和有[圣光道标]的单位是否需要停止施法
            if hasBeaconUnitRealHealth == 1 and castTargetRealHealth == 1 then
                return UnitHeal("spell", "停止施法")
            end
        else
            -- 当没有[圣光道标]时,只检查施法目标是否需要停止施法
            if not hasBeaconUnit and castTargetRealHealth and castTargetRealHealth == 1 then
                return UnitHeal("spell", "停止施法")
            end
        end
    end
end

-- [智慧圣印]未激活时使用[智慧圣印]
if spell("智慧圣印") and not SealofWisdom then
    return UnitHeal("spell", "智慧圣印")
end
-- 魔法值低于85%时使用[神圣恳求]
if spell("神圣恳求") and percentMana < 85 and not state.isCombat then
    return UnitHeal("spell", "神圣恳求")
end
-- 圣光道标即将消失时使用[圣光道标]
if spell("圣光道标", e.BeaconUnit) and Skippy.IsUnitCanAssist(e.BeaconUnit) then
    local aura = e.GetUnitAuraBySpellId(e.BeaconUnit, 53563, true)
    if not aura then
        return UnitHeal(e.BeaconUnit, "圣光道标")
    end
    if aura.expirationTime - GetTime() < 3 then
        return UnitHeal(e.BeaconUnit, "圣光道标")
    end
end
-- 圣洁护盾即将消失时使用[圣洁护盾]
if spell("圣洁护盾", e.ShieldUnit) and Skippy.IsUnitCanAssist(e.ShieldUnit) then
    local aura = e.GetUnitAuraBySpellId(e.ShieldUnit, 53601, false)
    if not aura then
        return UnitHeal(e.ShieldUnit, "圣洁护盾")
    end
    if aura.expirationTime - GetTime() < 3 then
        return UnitHeal(e.ShieldUnit, "圣洁护盾")
    end
end
-- 可以攻击目标时，且目标没有来自于玩家的[圣光审判]或[智慧审判]时使用[圣光审判]或[智慧审判]
if state.isCombat and spell(aura_env.Judgement, "target") and targetCanAttack and not judgement then
    return UnitHeal("target", aura_env.Judgement)
end
-- 神恩术，当有单位生命值低于50%时使用[神恩术]
if spell("神恩术") and lowestHealth < 50 and not DivineFavor then
    return UnitHeal("spell", "神恩术")
end
-- 有[圣光道标]时对没有[圣光道标]的单位使用[神圣震击]、[圣光闪现]、[圣光术]
if hasBeaconUnit and noBeaconUnit then
    if spell("神圣震击", noBeaconUnit) and lowestHealth < aura_env.config["HolyShock"] then
        return UnitHeal(noBeaconUnit, "神圣震击")
    end
    -- 有[治疗入定]或单位生命值低于60%时,施放[圣光术]
    if spell("圣光术", noBeaconUnit) and not state.isMoving and (lowestHealth < aura_env.holyLight or HealingTrance) then
        return UnitHeal(noBeaconUnit, "圣光术")
    end
    -- 有[圣光灌注]时,施放[圣光闪现]
    if InfusionofLight and lowestHealth < aura_env.flash then
        return UnitHeal(noBeaconUnit, "圣光闪现")
    end
    -- 驱散疾病、中毒
    if spell("纯净术", hasDiseaseUnit) then
        return UnitHeal(hasDiseaseUnit, "纯净术")
    end
    if spell("纯净术", hasPoisonUnit) then
        return UnitHeal(hasPoisonUnit, "纯净术")
    end
    -- 驱散魔法
    if spell("清洁术", hasMagicUnit) then
        return UnitHeal(hasMagicUnit, "清洁术")
    end
    -- 施放[圣光闪现]
    if spell("圣光闪现", noBeaconUnit) and lowestHealth < aura_env.flash and not state.isMoving then
        return UnitHeal(noBeaconUnit, "圣光闪现")
    end
end

-- 没有[圣光道标]时对所有单位使用[神圣震击]、[圣光闪现]、[圣光术]
if lowestUnit then
    if spell("神圣震击", lowestUnit) and lowestHealth < aura_env.config["HolyShock"] then
        return UnitHeal(lowestUnit, "神圣震击")
    end
    -- 有[治疗入定]或单位生命值低于60%时,施放[圣光术]
    if spell("圣光术", lowestUnit) and not state.isMoving and (lowestHealth < aura_env.holyLight or HealingTrance) then
        return UnitHeal(lowestUnit, "圣光术")
    end
    -- 有[圣光灌注]时,施放[圣光闪现]
    if InfusionofLight and lowestHealth < aura_env.flash then
        return UnitHeal(lowestUnit, "圣光闪现")
    end
    -- 驱散疾病、中毒
    if spell("纯净术", hasDiseaseUnit) then
        return UnitHeal(hasDiseaseUnit, "纯净术")
    end
    if spell("纯净术", hasPoisonUnit) then
        return UnitHeal(hasPoisonUnit, "纯净术")
    end
    -- 驱散魔法
    if spell("清洁术", hasMagicUnit) then
        return UnitHeal(hasMagicUnit, "清洁术")
    end
    -- 施放[圣光闪现]
    if spell("圣光闪现", lowestUnit) and lowestHealth < aura_env.flash and not state.isMoving then
        return UnitHeal(lowestUnit, "圣光闪现")
    end
end
-- 可以攻击目标时使用[圣光审判]或[智慧审判]
if state.isCombat and spell(aura_env.Judgement, "target") then
    return UnitHeal("target", aura_env.Judgement)
end
return UnitHeal("None", "None")
