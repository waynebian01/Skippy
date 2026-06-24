if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.UnitHeal then return end
if Skippy.State.class ~= "牧师" or Skippy.State.specID ~= 256 then return end
if not Skippy.State.inParty then return end
if not Skippy.Group or not Skippy.State.initialization then return Skippy.UnitHeal("Skip", "Skip") end

local currentTime = GetTime()
local state = Skippy.State
local target = Skippy.Units.target
local targetInRange = C_Spell.IsSpellInRange(585, "target")
local targetCanAttack = target.exists and target.canAttack and targetInRange
local group = Skippy.Group
local player = Skippy.GetPlayerInfo()
local playerAuras = Skippy.GetPlayerAuras
local isKnown = Skippy.IsSpellKnown
local spell = Skippy.GetSpellInfo
local mana = Skippy.State.power.MANA[1]
local manaMax = Skippy.State.power.MANA[2]
local percentMana = mana / manaMax * 100
local channel = UnitChannelInfo("player")

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noShieldUnit, noShieldHealth = Skippy.GetLowestUnitWithoutAura("虚弱灵魂")
local noShieldTank = Skippy.GetUnitWithoutAuraAndRole("虚弱灵魂", "TANK")
local noMendingTank = Skippy.GetUnitWithoutPlayerAurasAndRole("愈合祷言", "TANK")

if channel then return Skippy.UnitHeal("None", "None") end

if spell("绝望祷言").usable and player and player.percentHealth < 40 then
    return Skippy.UnitHeal("spell", "绝望祷言")
end

if spell("苦修").usable and lowestHealth < 50 then
    return Skippy.UnitHeal(lowestUnit, "苦修")
end

if spell("真言术：盾").usable and noShieldUnit and noShieldHealth < 60 then
    return Skippy.UnitHeal(noShieldUnit, "真言术：盾")
end

if playerAuras(109964) then -- 灵魂护壳
    if playerAuras("福音传播") and playerAuras("福音传播").applications == 5 then
        return Skippy.UnitHeal("spell", "天使长")
    end
    if spell("心灵专注").usable and not playerAuras("心灵专注") then
        return Skippy.UnitHeal("spell", "心灵专注")
    end
    return Skippy.UnitHeal("spell", "治疗祷言")
end

if spell("愈合祷言").usable and noMendingTank then
    return Skippy.UnitHeal(noMendingTank, "愈合祷言")
end

if state.isCombat and targetCanAttack then
    if isKnown(123040) then
        if spell("摧心魔").usable and percentMana < 80 then
            return Skippy.UnitHeal("target", "暗影魔")
        end
    else
        if spell("暗影魔").usable and percentMana < 80 then
            return Skippy.UnitHeal("target", "暗影魔")
        end
    end

    if lowestUnit then
        -- 先用[真言术：盾]获取[争分夺秒]光环
        if spell("苦修").cooldown < 2 and spell("真言术：盾").usable and not playerAuras("争分夺秒") then
            if noShieldUnit then
                return Skippy.UnitHeal(noShieldUnit, "真言术：盾")
            end
            if noShieldTank then
                return Skippy.UnitHeal(noShieldTank, "真言术：盾")
            end
        end

        if spell("苦修").usable then
            return Skippy.UnitHeal("target", "苦修target")
        end

        if spell("神圣之火").usable then
            return Skippy.UnitHeal("target", "神圣之火")
        end

        if spell("惩击").usable and not state.isMoving then
            return Skippy.UnitHeal("target", "惩击")
        end
    end
end

if not state.isCombat then
    if spell("治疗术").usable and lowestUnit and lowestHealth < 80 and not state.isMoving then
        return Skippy.UnitHeal(lowestUnit, "治疗术")
    end

    if spell("恢复").usable and lowestUnit and lowestHealth < 80 then
        return Skippy.UnitHeal(lowestUnit, "恢复")
    end
end

return Skippy.UnitHeal("None", "None")
