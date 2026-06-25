if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.updateSpellIndex then return end
if Skippy.State.class ~= "战士" or Skippy.State.specID ~= 73 then return end
if not Skippy.macrosReady then return Skippy.updateSpellIndex(nil, nil) end

local SendSpell = Skippy.updateSpellIndex
local usable = Skippy.IsUsableSpell
local target = Skippy.Units.target
local rage = Skippy.State.power.RAGE.powerValue
local _, maxRange = WeakAuras.GetRange("target")
if not maxRange then maxRange = 30 end
local enemyCount = Skippy.GetEnemyCount(8)
local weakenedArmorAura = Skippy.GetTargetAura(113746)
local WeakenedArmor = weakenedArmorAura and weakenedArmorAura.applications or 0

if target.exists and not target.isDead and target.canAttack and maxRange <= 8 then
    if usable("盾牌格挡") and rage >= 60 then
        return SendSpell("spell", "盾牌格挡")
    end

    if enemyCount >= 3 then
        if usable("雷霆一击") then
            return SendSpell("spell", "雷霆一击")
        end
        if usable("巨龙怒吼") then
            return SendSpell("spell", "巨龙怒吼")
        end
        if usable("复仇") then
            return SendSpell("spell", "复仇")
        end
        if usable("盾牌猛击") then
            return SendSpell("spell", "盾牌猛击")
        end
        if usable("盾牌格挡") and rage >= 60 then
            return SendSpell("spell", "盾牌格挡")
        end
        if usable("斩杀") and rage >= 30 and (target.healthPercent or 100) < 20 then
            return SendSpell("spell", "斩杀")
        end
        if usable("战斗怒吼") then
            return SendSpell("spell", "战斗怒吼")
        end
        if usable("毁灭打击") then
            return SendSpell("spell", "毁灭打击")
        end
    end

    if usable("毁灭打击") and WeakenedArmor < 3 then
        return SendSpell("spell", "毁灭打击")
    end
    if usable("盾牌猛击") then
        return SendSpell("spell", "盾牌猛击")
    end
    if usable("复仇") then
        return SendSpell("spell", "复仇")
    end
    if usable("盾牌格挡") and rage >= 60 then
        return SendSpell("spell", "盾牌格挡")
    end
    if usable("巨龙怒吼") then
        return SendSpell("spell", "巨龙怒吼")
    end
    if usable("斩杀") and rage >= 30 and (target.healthPercent or 100) < 20 then
        return SendSpell("spell", "斩杀")
    end
    if usable("毁灭打击") then
        return SendSpell("spell", "毁灭打击")
    end
end

return SendSpell(nil, nil)
