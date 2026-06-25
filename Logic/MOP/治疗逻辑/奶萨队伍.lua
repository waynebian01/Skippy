if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.updateSpellIndex then return end
if Skippy.State.class ~= "萨满祭司" or Skippy.State.specID ~= 264 then return end
if not Skippy.State.inParty then return end
if not Skippy.macrosReady then return Skippy.updateSpellIndex(nil, nil) end

local SendSpell = Skippy.updateSpellIndex
local state = Skippy.State
local playerAuras = Skippy.GetPlayerAuraByName
local usable = Skippy.IsUsableSpell
local totems = state.totems -- 1:火,2:土,3:水,4:空气

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noRiptide, noRiptideHealth = Skippy.GetLowestUnitByAuraState("激流", false, true)
local noShieldTank = Skippy.GetLowestUnitByAuraState("大地之盾", false, true, "TANK", true)

-- 没有主手附魔时使用[大地生命武器]
if not state.hasMainHandEnchant then
    return SendSpell("spell", "大地生命武器")
end
-- 没有[水之护盾]时使用[水之护盾]
if not playerAuras("水之护盾") then
    return SendSpell("spell", "水之护盾")
end
-- 给没有[大地之盾]的坦克使用[大地之盾]
if usable("大地之盾") and noShieldTank then
    return SendSpell(noShieldTank, "大地之盾")
end
-- 有人受伤且无水图腾时使用[治疗之泉图腾]
if usable("治疗之泉图腾") and state.isCombat and not state.isMoving and lowestUnit and not totems[3] then
    return SendSpell("spell", "治疗之泉图腾")
end
-- 给没有[激流]的单位使用[激流]
if usable("激流") then
    if noRiptide and noRiptideHealth < 95 then
        return SendSpell(noRiptide, "激流")
    end
    if lowestUnit and lowestHealth < 95 then
        return SendSpell(lowestUnit, "激流")
    end
end
-- [元素释放]
if usable("元素释放") and lowestUnit then
    return SendSpell("spell", "元素释放")
end
-- [治疗链]
if usable("治疗链") and Skippy.GetGroupCount(80) >= 3 then
    return SendSpell(lowestUnit, "治疗链")
end

if not state.isMoving then
    if usable("治疗之涌") and lowestUnit and lowestHealth < 50 then
        return SendSpell(lowestUnit, "治疗之涌")
    end
    if usable("强效治疗波") and lowestUnit and lowestHealth < 60 then
        return SendSpell(lowestUnit, "强效治疗波")
    end
    if usable("治疗波") and lowestUnit and lowestHealth < 90 then
        return SendSpell(lowestUnit, "治疗波")
    end
end

return SendSpell(nil, nil)
