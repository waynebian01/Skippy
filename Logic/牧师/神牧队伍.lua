if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.updateSpellIndex then return end
if Skippy.State.class ~= "牧师" or Skippy.State.specID ~= 257 then return end
if not Skippy.State.inParty then return end
if not Skippy.macrosReady then return Skippy.updateSpellIndex(nil, nil) end

local SendSpell = Skippy.updateSpellIndex
local playerAuras = Skippy.GetPlayerAuraByName
local usable = Skippy.IsUsableSpell
local player = Skippy.GetPlayerInfo()

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local lowestUnitWithoutPlayer, lowestHealthWithoutPlayer = Skippy.GetLowestUnitWithoutUnit("player")
local noRenewTank = Skippy.GetLowestUnitByAuraState("恢复", false, true, "TANK", true)
local noRenewUnit, noRenewHealth = Skippy.GetLowestUnitByAuraState("恢复", false, true)
local noMendingTank = Skippy.GetLowestUnitByAuraState("愈合祷言", false, true, "TANK", true)

if not Skippy.IsFinishedCasting(0.4) then return end

if usable("恢复") and noRenewTank then
    return SendSpell(noRenewTank, "恢复")
end

if usable("神圣之星") and lowestUnit then
    return SendSpell(lowestUnit, "神圣之星")
end

if usable("治疗之环") and Skippy.GetGroupCount(90) >= 3 then
    return SendSpell("player", "治疗之环")
end

if usable(88684) and playerAuras("脉轮：静") and lowestHealth < 70 then
    return SendSpell(lowestUnit, "圣言术：静")
end

if usable("联结治疗") and player and (player.healthPercent or 100) < 70 and lowestHealthWithoutPlayer < 70 then
    return SendSpell(lowestUnitWithoutPlayer, "联结治疗")
end

if usable("强效治疗术") and lowestHealth < 70 then
    if playerAuras("妙手回春") and playerAuras("妙手回春").applications == 2 then
        return SendSpell(lowestUnit, "强效治疗术")
    end
end

if usable("快速治疗") and lowestHealth < 70 then
    return SendSpell(lowestUnit, "快速治疗")
end

if usable("愈合祷言") and noMendingTank then
    return SendSpell(noMendingTank, "愈合祷言")
end

if usable("恢复") and noRenewHealth and noRenewHealth < 90 then
    return SendSpell(noRenewUnit, "恢复")
end

if usable("强效治疗术") and lowestHealth < 60 then
    return SendSpell(lowestUnit, "强效治疗术")
end

if usable("治疗术") and lowestHealth < 85 then
    return SendSpell(lowestUnit, "治疗术")
end

return SendSpell(nil, nil)
