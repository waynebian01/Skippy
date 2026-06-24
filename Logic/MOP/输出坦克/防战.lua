if not Skippy or not Skippy.Units or not Skippy.State then return end
if Skippy.State.class ~= "战士" or Skippy.State.specID ~= 73 then return end

local spell = Skippy.GetSpellInfo
local target = Skippy.Units.target
local rage = Skippy.State.power.RAGE[1]
local targetAuras = Skippy.GetTargetAuras
local minRange, maxRange = WeakAuras.GetRange("target")
if not maxRange then maxRange = 30 end
local enemyCount = Skippy.GetEnemyCount(8)
--local noWeakenedCount = Skippy.GetEnemyCountWithoutAura(8, "虚弱打击")
--local noDeepWoundsCount = Skippy.GetEnemyCountWithoutPlayerAura(8, "重伤")
local WeakenedArmor = targetAuras(113746) and targetAuras(113746).applications or 0

if target.exists and not target.isDead and target.canAttack and maxRange <= 8 then
    if spell("盾牌格挡").usable and rage >= 60 then
        return Skippy.PressKey("盾牌格挡")
    end

    if enemyCount >= 3 then
        if spell("雷霆一击").usable then
            return Skippy.PressKey("雷霆一击")
        end
        if spell("巨龙怒吼").usable then
            return Skippy.PressKey("巨龙怒吼")
        end
        if spell("复仇").usable then
            return Skippy.PressKey("复仇")
        end
        if spell("盾牌猛击").usable then
            return Skippy.PressKey("盾牌猛击")
        end
        if spell("盾牌格挡").usable and rage >= 60 then
            return Skippy.PressKey("盾牌格挡")
        end
        if spell("斩杀").usable and rage >= 30 and target.percentHealth < 20 then
            return Skippy.PressKey("斩杀")
        end
        if spell("战斗怒吼").usable then
            return Skippy.PressKey("战斗怒吼")
        end
        if spell("毁灭打击").usable then
            return Skippy.PressKey("毁灭打击")
        end
    end

    if spell("毁灭打击").usable and WeakenedArmor < 3 then
        return Skippy.PressKey("毁灭打击")
    end
    if spell("盾牌猛击").usable then
        return Skippy.PressKey("盾牌猛击")
    end
    if spell("复仇").usable then
        return Skippy.PressKey("复仇")
    end
    if spell("盾牌格挡").usable and rage >= 60 then
        return Skippy.PressKey("盾牌格挡")
    end
    if spell("巨龙怒吼").usable then
        return Skippy.PressKey("巨龙怒吼")
    end
    if spell("斩杀").usable and rage >= 30 and target.percentHealth < 20 then
        return Skippy.PressKey("斩杀")
    end
    if spell("毁灭打击").usable then
        return Skippy.PressKey("毁灭打击")
    end
end

return Skippy.PressKey("None")
