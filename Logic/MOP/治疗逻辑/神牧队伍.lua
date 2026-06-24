if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.UnitHeal then return end
if Skippy.State.class ~= "牧师" or Skippy.State.specID ~= 257 then return end
if not Skippy.State.inParty then return end
if not Skippy.Group or not Skippy.State.initialization then return Skippy.UnitHeal("Skip", "Skip") end

local currentTime = GetTime()
local state = Skippy.State
local castUnit = state.CastTargetUnit
local group = Skippy.Group
local playerAuras = Skippy.GetPlayerAuras
local isKnown = Skippy.IsSpellKnown
local spell = Skippy.GetSpellInfo
local chakra_cooldown = aura_env.getChakraCooldown() -- 脉轮：罚, 佑, 静 ; 冷却时间
local mana = Skippy.State.power.MANA[1]
local manaMax = Skippy.State.power.MANA[2]
local percentMana = mana / manaMax * 100
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local lowestUnitWithoutPlayer, lowestHealthWithoutPlayer = Skippy.GetLowestUnitWithoutPlayer()
local noRenewTank, noRenewHealthTank = Skippy.GetUnitWithoutPlayerAurasAndRole("恢复", "TANK")
local noRenewUnit, noRenewHealth = Skippy.GetLowestUnitWithoutPlayerAuras("恢复")
local noMendingTank = Skippy.GetUnitWithoutPlayerAurasAndRole("愈合祷言", "TANK")

if not Skippy.IsFinishedCasting(0.4) then return end

if spell("恢复").usable and noRenewTank then
    return Skippy.UnitHeal(noRenewTank, "恢复")
end

if spell("神圣之星").usable and lowestUnit then
    return Skippy.UnitHeal(lowestUnit, "神圣之星")
end

if spell("治疗之环").usable and Skippy.GetCount(90) >= 3 then
    return Skippy.UnitHeal("spell", "治疗之环")
end

if spell(88684).usable and playerAuras("脉轮：静") and lowestHealth < 70 then
    return Skippy.UnitHeal(lowestUnit, "圣言术：静")
end

if spell("联结治疗").usable and group.player.percentHealth < 70 and lowestHealthWithoutPlayer < 70 then
    return Skippy.UnitHeal(lowestUnitWithoutPlayer, "联结治疗")
end

if spell("强效治疗术").usable and lowestHealth < 70 then
    if playerAuras("妙手回春") and playerAuras("妙手回春").applications == 2 then
        return Skippy.UnitHeal(lowestUnit, "强效治疗术")
    end
end

if spell("快速治疗").usable and lowestHealth < 70 then
    return Skippy.UnitHeal(lowestUnit, "快速治疗")
end

if spell("愈合祷言").usable and noMendingTank then
    return Skippy.UnitHeal(noMendingTank, "愈合祷言")
end

if spell("恢复").usable and noRenewHealth < 90 then
    return Skippy.UnitHeal(noRenewUnit, "恢复")
end

if spell("强效治疗术").usable and lowestHealth < 60 then
    return Skippy.UnitHeal(lowestUnit, "强效治疗术")
end

if spell("治疗术").usable and lowestHealth < 85 then
    return Skippy.UnitHeal(lowestUnit, "治疗术")
end

return Skippy.UnitHeal("None", "None")
