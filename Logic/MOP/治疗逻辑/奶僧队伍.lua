if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.updateSpellIndex then return end
if Skippy.State.class ~= "武僧" or Skippy.State.specID ~= 270 then return end
if not Skippy.State.inParty then return end
if not Skippy.macrosReady then return Skippy.updateSpellIndex(nil, nil) end

local SendSpell = Skippy.updateSpellIndex
local state = Skippy.State
local target = Skippy.Units.target
local targetCanAttack = target.exists and target.canAttack and C_Spell.IsSpellInRange("猛虎掌", "target")
local playerAuras = Skippy.GetPlayerAuraByName
local isKnown = Skippy.IsSpellKnown
local usable = Skippy.IsUsableSpell
local channeling = UnitChannelInfo("player")
local mana = state.power.MANA.powerValue
local manaMax = state.power.MANA.powerMax
local percentMana = mana / manaMax * 100
local enemyCount = Skippy.GetEnemyCount(8)
local chi = state.power.CHI.powerValue
local chiMax = state.power.CHI.powerMax
local BlackoutKick = isKnown(100784) and chi >= 2

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noZenUnit = Skippy.GetLowestUnitByAuraState("禅意珠", false, true)
local noZenTank = Skippy.GetLowestUnitByAuraState("禅意珠", false, true, "TANK", true)
local SoothingUnit, SoothingHealth = Skippy.GetLowestUnitByAuraState("抚慰之雾", true, true)
local vital = playerAuras("活力之雾") and playerAuras("活力之雾").applications == 5
local ManaTeaCount = playerAuras("法力茶") and playerAuras("法力茶").applications or 0
local noRenewingUnit = Skippy.GetLowestUnitByAuraState("复苏之雾", false, true)
local RenewingCount = Skippy.GetGroupCountByAuraState(80, "复苏之雾", true, true)
local noRenewing = Skippy.GetLowestUnitByAuraState("复苏之雾", false, true)

if channeling and channeling == "法力茶" then
    if percentMana >= 95 then
        return SendSpell(nil, nil) -- 停止引导（新宏模型无停止施法指令，退化为空闲）
    end
    return SendSpell(nil, nil)
end

if usable("法力茶") and ManaTeaCount == 20 and percentMana < 10 then
    return SendSpell("spell", "法力茶")
end

if usable("禅意珠") then
    if noZenTank then
        return SendSpell(noZenTank, "禅意珠")
    end
    if noZenUnit then
        return SendSpell(noZenUnit, "禅意珠")
    end
end

if usable("振魂引") and chi >= 2 and RenewingCount >= 3 then
    if usable("雷光聚神茶") and chi >= 3 then
        return SendSpell("spell", "雷光聚神茶")
    end
    return SendSpell("spell", "振魂引")
end

-- 常规补充真气技能,非战斗情况下也会使用
if chi < chiMax then
    if usable("移花接木") then
        return SendSpell("spell", "移花接木")
    end
    if usable("复苏之雾") and noRenewingUnit then
        return SendSpell(noRenewingUnit, "复苏之雾")
    end
    if usable("升腾之雾") and lowestUnit and vital then
        return SendSpell(lowestUnit, "升腾之雾")
    end
end

if state.isCombat then
    if usable("真气波") and lowestUnit then
        return SendSpell(lowestUnit, "真气波")
    end
    if usable("真气爆裂") then
        return SendSpell("spell", "真气爆裂")
    end
end

if channeling and channeling == "抚慰之雾" then
    if SoothingUnit and SoothingHealth < 90 then
        if usable("氤氲之雾") and chi >= 3 then
            return SendSpell(SoothingUnit, "氤氲之雾")
        end
        if usable("升腾之雾") then
            return SendSpell(SoothingUnit, "升腾之雾")
        end
    end
end

if targetCanAttack and state.isCombat then
    -- 对生命值低于50%的单位使用[抚慰之雾]
    if usable("抚慰之雾") and lowestUnit and lowestHealth < 50 then
        return SendSpell(lowestUnit, "抚慰之雾")
    end

    -- 真气满时，使用[幻灭踢]或[猛虎掌]消耗真气
    if chi == chiMax then
        if BlackoutKick and (not playerAuras("青龙之忱") or enemyCount >= 3) then
            return SendSpell("target", "幻灭踢")
        end
        return SendSpell("target", "猛虎掌")
    end

    -- 没有[熟能生巧] 或 [青龙之忱]且真气小于1或为0时，使用[神鹤引项踢]或[贯日击]
    if not playerAuras("熟能生巧") or (not playerAuras("青龙之忱") and chi <= 1) or chi == 0 then
        if usable("神鹤引项踢") and enemyCount >= 3 then
            return SendSpell("spell", "神鹤引项踢")
        else
            return SendSpell("target", "贯日击")
        end
    end

    -- 真气小于2时，使用[真气酒]补充真气
    if usable("真气酒") and chi < 2 then
        return SendSpell("spell", "真气酒")
    end

    -- 没有[猛虎之力]时，使用[猛虎掌]
    if not playerAuras("猛虎之力") then
        return SendSpell("target", "猛虎掌")
    end

    -- 没有[青龙之忱]或敌人大于等于3时，使用[幻灭踢]
    if BlackoutKick and (not playerAuras("青龙之忱") or enemyCount >= 3) then
        return SendSpell("target", "幻灭踢")
    end

    -- [活力之雾]为5层时，使用[升腾之雾],否则使用[猛虎掌]
    if vital then
        return SendSpell("player", "升腾之雾")
    else
        return SendSpell("target", "猛虎掌")
    end
end

-- 对没有[复苏之雾]的满血单位使用[复苏之雾]
if usable("复苏之雾") and not noRenewingUnit and noRenewing then
    return SendSpell(noRenewing, "复苏之雾")
end

-- 非战斗中对生命值低于80%的单位使用[抚慰之雾]
if usable("抚慰之雾") and lowestUnit and lowestHealth < 80 then
    return SendSpell(lowestUnit, "抚慰之雾")
end

if usable("法力茶") and ManaTeaCount == 20 and percentMana < 80 then
    return SendSpell("spell", "法力茶")
end

return SendSpell(nil, nil)
