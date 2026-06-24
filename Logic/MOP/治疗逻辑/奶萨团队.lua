if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.UnitHeal or not Skippy.State.initialization then return end
if Skippy.State.class ~= "萨满祭司" or Skippy.State.specID ~= 264 then return end
if not Skippy.State.inRaid or not Skippy.State.inParty then return Skippy.UnitHeal("Skip", "Skip") end

local currentTime = GetTime()
local state = Skippy.State
local castUnit = state.CastTargetUnit
local group = Skippy.Group
local target = Skippy.Units.target
local targetCanAttack = target.exists and target.canAttack
local isKnown = Skippy.IsSpellKnown
local spell = Skippy.GetSpellInfo
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100
local totem = state.totem -- 1:火,2:土,3:水,4:空气

local count80 = Skippy.GetCount(80)
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noRiptide, noRiptideHealth = Skippy.GetLowestUnitWithoutPlayerAuras("激流")
local hasRiptide, hasRiptideHealth = Skippy.GetLowestUnitWithPlayerAura("激流")
local noShieldTank, noShieldTankHealth = Skippy.GetUnitWithoutAuraAndRole("大地之盾", "TANK")

local WaterShield = Skippy.GetPlayerAuras("水之护盾")

-- ===== 逻辑 =====
-- 没有主手附魔时使用[大地生命武器]
if not state.hasMainHandEnchant then
    return Skippy.UnitHeal("spell", "大地生命武器")
end
-- 没有[水之护盾]光环时使用[水之护盾]
if not WaterShield then
    return Skippy.UnitHeal("spell", "水之护盾")
end
-- 给坦克使用[大地之盾]
if spell("大地之盾").usable and noShieldTank then
    return Skippy.UnitHeal(noShieldTank, "大地之盾")
end
-- 有人受伤时使用[治疗之泉图腾]
if spell("治疗之泉图腾").usable and state.isCombat and not state.isMoving and lowestUnit and not totem[3] then
    return Skippy.UnitHeal("spell", "治疗之泉图腾")
end
-- 给没有[激流]光环的单位使用[激流]
if spell("激流").usable then
    if noRiptide and noRiptideHealth < 95 then
        return Skippy.UnitHeal(noRiptide, "激流")
    end
    if lowestUnit and lowestHealth < 95 then
        return Skippy.UnitHeal(lowestUnit, "激流")
    end
end
-- 使用[元素释放]
if spell("元素释放").usable and lowestUnit then
    return Skippy.UnitHeal("spell", "元素释放")
end
-- 不在移动时
if not state.isMoving then
    if spell("治疗链").usable and hasRiptideHealth < 80 and count80 >= 3 then
        return Skippy.UnitHeal(hasRiptide, "治疗链")
    end
    if spell("治疗之涌").usable and lowestUnit and lowestHealth < 50 then
        return Skippy.UnitHeal(lowestUnit, "治疗之涌")
    end

    if spell("强效治疗波").usable and lowestUnit and lowestHealth < 60 then
        return Skippy.UnitHeal(lowestUnit, "强效治疗波")
    end

    if spell("治疗波").usable and lowestUnit and lowestHealth < 90 then
        return Skippy.UnitHeal(lowestUnit, "治疗波")
    end
end

return Skippy.UnitHeal("None", "None")
