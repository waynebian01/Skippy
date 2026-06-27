if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.updateSpellIndex then return end
if Skippy.State.class ~= "德鲁伊" or Skippy.State.specID ~= 105 then return end
if not Skippy.State.inParty then return Skippy.updateSpellIndex(nil, nil) end

local SendSpell = Skippy.updateSpellIndex
local currentTime = GetTime()
local playerAuras = Skippy.GetPlayerAuraByName
local spell = Skippy.IsUsableSpellOnUnit
local usable = Skippy.IsUsableSpell
local cd = Skippy.GetSpellCooldownDuration

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noLifebloomTank = Skippy.GetLowestUnitByAuraState("生命绽放", false, true, "TANK", true)
local hasLifebloomUnit, _, hasLifebloomAura = Skippy.GetLowestUnitByAuraState("生命绽放", true, true)
local canSwiftmendUnit, canSwiftmendHealth = Skippy.GetLowestUnitWithAnyAuras({ "回春术", "愈合" }, true)
local noRejuvenation, noRejuvenationHealth = Skippy.GetLowestUnitByAuraState("回春术", false, true)

local Forest = playerAuras("丛林之魂")
local clearCast = playerAuras("节能施法")

-- 受伤人数 >= 2 时使用[野性成长]
if usable("野性成长") and Skippy.GetGroupCount(90) >= 2 then
    return SendSpell("spell", "野性成长")
end

-- 维持坦克[生命绽放]，或在丛林之魂/即将到期时刷新
if usable("生命绽放") then
    if noLifebloomTank then
        return SendSpell(noLifebloomTank, "生命绽放")
    end
    if hasLifebloomUnit and hasLifebloomAura then
        if Forest or hasLifebloomAura.expirationTime - currentTime < 3 then
            return SendSpell(hasLifebloomUnit, "生命绽放")
        end
    end
end

-- 有人低于 50% 时[自然迅捷]
if cd("自然迅捷") == 0 and not playerAuras("自然迅捷") and lowestUnit and lowestHealth < 50 then
    return SendSpell("spell", "自然迅捷")
end

-- 有[回春术]/[愈合]的单位低于 85% 时[迅捷治愈]
if cd("迅捷治愈") <= 1 and canSwiftmendUnit and canSwiftmendHealth < 85 then
    return SendSpell(canSwiftmendUnit, "迅捷治愈")
end

if spell("愈合", lowestUnit) then
    if lowestHealth < 50 or (clearCast and lowestHealth < 70) then
        return SendSpell(lowestUnit, "愈合")
    end
end

if spell("回春术", noRejuvenation) and noRejuvenationHealth < 90 then
    return SendSpell(noRejuvenation, "回春术")
end

if spell("治疗之触", lowestUnit) and lowestHealth < 60 then
    return SendSpell(lowestUnit, "治疗之触")
end

if spell("滋养", lowestUnit) and lowestHealth < 70 then
    return SendSpell(lowestUnit, "滋养")
end

if spell("生命绽放", hasLifebloomUnit) and hasLifebloomAura and hasLifebloomAura.applications < 3 then
    return SendSpell(hasLifebloomUnit, "生命绽放")
end

return SendSpell(nil, nil)
