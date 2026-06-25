if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.updateSpellIndex then return end
if Skippy.State.class ~= "牧师" or Skippy.State.specID ~= 256 then return end
if not Skippy.State.inParty then return end
if not Skippy.macrosReady then return Skippy.updateSpellIndex(nil, nil) end

local SendSpell = Skippy.updateSpellIndex
local state = Skippy.State
local target = Skippy.Units.target
local targetInRange = C_Spell.IsSpellInRange(585, "target")
local targetCanAttack = target.exists and target.canAttack and targetInRange
local player = Skippy.GetPlayerInfo()
local playerAuras = Skippy.GetPlayerAuraByName
local isKnown = Skippy.IsSpellKnown
local usable = Skippy.IsUsableSpell
local cd = Skippy.GetSpellCooldown
local channel = UnitChannelInfo("player")
local mana = state.power.MANA.powerValue
local manaMax = state.power.MANA.powerMax
local percentMana = mana / manaMax * 100

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noShieldUnit, noShieldHealth = Skippy.GetLowestUnitByAuraState("虚弱灵魂", false, true)
local noShieldTank = Skippy.GetLowestUnitByAuraState("虚弱灵魂", false, true, "TANK", true)
local noMendingTank = Skippy.GetLowestUnitByAuraState("愈合祷言", false, true, "TANK", true)

if channel then return SendSpell(nil, nil) end

if usable("绝望祷言") and player and (player.healthPercent or 100) < 40 then
    return SendSpell("spell", "绝望祷言")
end

if usable("苦修") and lowestHealth < 50 then
    return SendSpell(lowestUnit, "苦修")
end

if usable("真言术：盾") and noShieldUnit and noShieldHealth < 60 then
    return SendSpell(noShieldUnit, "真言术：盾")
end

if playerAuras("灵魂护壳") then -- 109964 灵魂护壳
    if playerAuras("福音传播") and playerAuras("福音传播").applications == 5 then
        return SendSpell("spell", "天使长")
    end
    if usable("心灵专注") and not playerAuras("心灵专注") then
        return SendSpell("spell", "心灵专注")
    end
    return SendSpell("spell", "治疗祷言")
end

if usable("愈合祷言") and noMendingTank then
    return SendSpell(noMendingTank, "愈合祷言")
end

if state.isCombat and targetCanAttack then
    if isKnown(123040) then
        if usable("摧心魔") and percentMana < 80 then
            return SendSpell("target", "暗影魔")
        end
    else
        if usable("暗影魔") and percentMana < 80 then
            return SendSpell("target", "暗影魔")
        end
    end

    if lowestUnit then
        -- 先用[真言术：盾]获取[争分夺秒]光环
        if (cd("苦修") or 0) < 2 and usable("真言术：盾") and not playerAuras("争分夺秒") then
            if noShieldUnit then
                return SendSpell(noShieldUnit, "真言术：盾")
            end
            if noShieldTank then
                return SendSpell(noShieldTank, "真言术：盾")
            end
        end

        if usable("苦修") then
            return SendSpell("target", "苦修")
        end

        if usable("神圣之火") then
            return SendSpell("target", "神圣之火")
        end

        if usable("惩击") and not state.isMoving then
            return SendSpell("target", "惩击")
        end
    end
end

if not state.isCombat then
    if usable("治疗术") and lowestUnit and lowestHealth < 80 and not state.isMoving then
        return SendSpell(lowestUnit, "治疗术")
    end

    if usable("恢复") and lowestUnit and lowestHealth < 80 then
        return SendSpell(lowestUnit, "恢复")
    end
end

return SendSpell(nil, nil)
