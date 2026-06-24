if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.UnitHeal then return end
if Skippy.State.class ~= "武僧" or Skippy.State.specID ~= 270 then return end
if not Skippy.State.inParty then return end
if not Skippy.Group or not Skippy.State.initialization then return Skippy.UnitHeal("Skip", "Skip") end

local state = Skippy.State
local target = Skippy.Units.target
local targetCanAttack = target.exists and target.canAttack and C_Spell.IsSpellInRange("猛虎掌", "target")
local playerAuras = Skippy.GetPlayerAuras
local isKnown = Skippy.IsSpellKnown
local spell = Skippy.GetSpellInfo
local channeling = UnitChannelInfo("player")
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100
local enemyCount = Skippy.GetEnemyCount(8)
local chi = state.power.CHI[1]
local chiMax = state.power.CHI[2]
local BlackoutKick = isKnown(100784) and chi >= 2

local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noZenUnit = Skippy.GetLowestUnitWithoutPlayerAuras("禅意珠")
local noZenTank = Skippy.GetUnitWithoutAuraAndRole("禅意珠", "TANK")
local SoothingUnit, SoothingHealth = Skippy.GetUnitWithPlayerAura("抚慰之雾")
local vital = playerAuras("活力之雾") and playerAuras("活力之雾").applications == 5
local ManaTeaCount = playerAuras("法力茶") and playerAuras("法力茶").applications or 0
local noRenewingUnit = Skippy.GetLowestUnitWithoutPlayerAuras("复苏之雾")
local RenewingCount = Skippy.GetCountWithPlayerAura(80, "复苏之雾")
local noRenewing = Skippy.GetUnitWithoutPlayerAura("复苏之雾")

if channeling and channeling == "法力茶" then
    if percentMana >= 95 then
        return Skippy.UnitHeal("spell", "stopcasting")
    end
    return Skippy.UnitHeal("None", "None")
end

if spell("法力茶").usable and ManaTeaCount == 20 and percentMana < 10 then
    return Skippy.UnitHeal("spell", "法力茶")
end

if spell("禅意珠").usable then
    if noZenTank then
        return Skippy.UnitHeal(noZenTank, "禅意珠")
    end
    if noZenUnit then
        return Skippy.UnitHeal(noZenUnit, "禅意珠")
    end
end

if spell("振魂引").usable and chi >= 2 and RenewingCount >= 3 then
    if spell("雷光聚神茶").usable and chi >= 3 then
        return Skippy.UnitHeal("spell", "雷光聚神茶")
    end
    return Skippy.UnitHeal("spell", "振魂引")
end

-- 常规补充真气技能,非战斗情况下也会使用
if chi < chiMax then
    if spell("移花接木").usable then
        return Skippy.UnitHeal("spell", "移花接木")
    end
    if spell("复苏之雾").usable and noRenewingUnit then
        return Skippy.UnitHeal(noRenewingUnit, "复苏之雾")
    end
    if spell("升腾之雾").usable and lowestUnit and vital then
        return Skippy.UnitHeal(lowestUnit, "升腾之雾")
    end
end

if state.isCombat then
    if spell("真气波").usable and lowestUnit then
        return Skippy.UnitHeal(lowestUnit, "真气波")
    end
    if spell("真气爆裂").usable then
        return Skippy.UnitHeal("spell", "真气爆裂")
    end
end

if channeling and channeling == "抚慰之雾" then
    if SoothingUnit and SoothingHealth < 90 then
        if spell("氤氲之雾").usable and chi >= 3 then
            return Skippy.UnitHeal(SoothingUnit, "氤氲之雾")
        end
        if spell("升腾之雾").usable then
            return Skippy.UnitHeal(SoothingUnit, "升腾之雾")
        end
    end
end

if targetCanAttack and state.isCombat then
    -- 对生命值低于50%的单位使用[抚慰之雾]
    if spell("抚慰之雾").usable and lowestUnit and lowestHealth < 50 then
        return Skippy.UnitHeal(lowestUnit, "抚慰之雾")
    end

    -- 真气满时，使用[幻灭踢]或[猛虎掌]消耗真气
    if chi == chiMax then
        if BlackoutKick and (not playerAuras("青龙之忱") or enemyCount >= 3) then
            return Skippy.UnitHeal("target", "幻灭踢")
        end
        return Skippy.UnitHeal("target", "猛虎掌")
    end

    -- 没有[熟能生巧] 或 [青龙之忱]且真气小于1或为0时，使用[神鹤引项踢]或[贯日击]
    if not playerAuras("熟能生巧") or (not playerAuras("青龙之忱") and chi <= 1) or chi == 0 then
        if spell("神鹤引项踢").usable and enemyCount >= 3 then
            return Skippy.UnitHeal("spell", "神鹤引项踢")
        else
            return Skippy.UnitHeal("target", "贯日击")
        end
    end

    -- 真气小于2时，使用[真气酒]补充真气
    if spell("真气酒").usable and chi < 2 then
        return Skippy.UnitHeal("spell", "真气酒")
    end

    -- 没有[猛虎之力]时，使用[猛虎掌]
    if not playerAuras("猛虎之力") then
        return Skippy.UnitHeal("target", "猛虎掌")
    end

    -- 没有[青龙之忱]或敌人大于等于3时，使用[幻灭踢]
    if BlackoutKick and (not playerAuras("青龙之忱") or enemyCount >= 3) then
        return Skippy.UnitHeal("target", "幻灭踢")
    end

    -- [活力之雾]为5层时，使用[升腾之雾],否则使用[猛虎掌]
    if vital then
        return Skippy.UnitHeal("player", "升腾之雾")
    else
        return Skippy.UnitHeal("target", "猛虎掌")
    end
end

-- 对没有[复苏之雾]的满血单位使用[复苏之雾]
if spell("复苏之雾").usable and not noRenewingUnit and noRenewing then
    return Skippy.UnitHeal(noRenewing, "复苏之雾")
end

-- 非战斗中对生命值低于80%的单位使用[抚慰之雾]
if spell("抚慰之雾").usable and lowestUnit and lowestHealth < 80 then
    return Skippy.UnitHeal(lowestUnit, "抚慰之雾")
end

if spell("法力茶").usable and ManaTeaCount == 20 and percentMana < 80 then
    return Skippy.UnitHeal("spell", "法力茶")
end

return Skippy.UnitHeal("None", "None")
