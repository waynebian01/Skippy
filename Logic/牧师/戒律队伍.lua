if not Skippy or not aura_env.init or Skippy.State.specID ~= 256 then return false end
-- ===== 函数 =====
local playerAuras = Skippy.GetPlayerAuraByName
local SpellOnUnit = Skippy.IsUsableSpellOnUnit
local isKnown = Skippy.IsSpellKnown
local usable = Skippy.IsUsableSpell
local cd = Skippy.GetSpellCooldownDuration

-- ===== 状态 =====
local state = Skippy.State
local target = Skippy.Units.target
local targetInRange = C_Spell.IsSpellInRange(585, "target")
local targetCanAttack = target.exists and target.canAttack and targetInRange
local playerRealHealthPercent = Skippy.State.healthInfo.realHealthPercent

local channel = state.channelInfo
local percentMana = state.power.MANA.powerPercent

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noShieldUnit, noShieldHealth = Skippy.GetLowestUnitByAuraState("虚弱灵魂", false, true)
local noShieldTank = Skippy.GetLowestUnitByAuraState("虚弱灵魂", false, true, "TANK", true)
local noMendingTank = Skippy.GetLowestUnitByAuraState("愈合祷言", false, true, "TANK", true)

-- ===== 逻辑 =====
if not Skippy.Go then
    return aura_env.SendSpell("暂停")
end

if channel then
    return aura_env.SendSpell("暂停")
end

if usable("绝望祷言") and playerRealHealthPercent < 40 then
    return aura_env.SendSpell("绝望祷言", "spell")
end

if SpellOnUnit("苦修", lowestUnit) and lowestHealth < 50 then
    return aura_env.SendSpell("苦修", lowestUnit)
end

if SpellOnUnit("真言术：盾", noShieldUnit) and noShieldHealth < 60 then
    return aura_env.SendSpell("真言术：盾", noShieldUnit)
end

if playerAuras("灵魂护壳") then -- 109964 灵魂护壳
    if playerAuras("福音传播") and playerAuras("福音传播").applications == 5 then
        return aura_env.SendSpell("天使长", "spell")
    end
    if usable("心灵专注") and not playerAuras("心灵专注") then
        return aura_env.SendSpell("心灵专注", "spell")
    end
    return aura_env.SendSpell("治疗祷言", "player")
end

if SpellOnUnit("愈合祷言", noMendingTank) then
    return aura_env.SendSpell("愈合祷言", noMendingTank)
end

if state.isCombat and targetCanAttack then
    if isKnown(123040) then
        if SpellOnUnit("摧心魔", "target") and percentMana < 80 then
            return aura_env.SendSpell("暗影魔", "target")
        end
    else
        if SpellOnUnit("暗影魔", "target") and percentMana < 80 then
            return aura_env.SendSpell("暗影魔", "target")
        end
    end

    if lowestUnit then
        -- 先用[真言术：盾]获取[争分夺秒]光环
        if cd("苦修") < 2 and not playerAuras("争分夺秒") then
            if SpellOnUnit("真言术：盾", noShieldUnit) then
                return aura_env.SendSpell("真言术：盾", noShieldUnit)
            end
            if SpellOnUnit("真言术：盾", noShieldTank) then
                return aura_env.SendSpell("真言术：盾", noShieldTank)
            end
        end

        if SpellOnUnit("苦修", "target") then
            return aura_env.SendSpell("苦修", "target")
        end

        if SpellOnUnit("神圣之火", "target") then
            return aura_env.SendSpell("神圣之火", "target")
        end

        if SpellOnUnit("惩击", "target") and not state.isMoving then
            return aura_env.SendSpell("惩击", "target")
        end
    end
end

if not state.isCombat then
    if SpellOnUnit("治疗术", lowestUnit) and lowestHealth < 80 and not state.isMoving then
        return aura_env.SendSpell("治疗术", lowestUnit)
    end

    if SpellOnUnit("恢复", lowestUnit) and lowestHealth < 80 then
        return aura_env.SendSpell("恢复", lowestUnit)
    end
end

return aura_env.SendSpell("休息")
