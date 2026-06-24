if not Skippy or not Skippy.Units or not Skippy.State then return end
if Skippy.State.class ~= "圣骑士" then return end

local spell = Skippy.IsUsableSpellOnUnit
local state = Skippy.State
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100
local target = Skippy.Units.target
local minRange, maxRange = WeakAuras.GetRange("target")
if not maxRange then maxRange = 30 end
local enemyCount = Skippy.GetEnemyCount(8)
local PlayersLight = Skippy.GetTargetAurasByPlayer("圣光审判")
local PlayersWisdom = Skippy.GetTargetAurasByPlayer("智慧审判")
local Light = Skippy.GetTargetAuras("圣光审判")
local Wisdom = Skippy.GetTargetAuras("智慧审判")
local enemyCount8 = Skippy.GetEnemyCount(8)
local GlyphofReckoning = C_SpellBook.IsSpellKnown(405004) -- 清算符文: 你的清算之手法术不再嘲讽目标，而且可以对无法嘲讽的目标造成伤害。
local WarArt = Skippy.GetPlayerAuraByName(59578)               --战争艺术
local DemonsCount = Skippy.GetEnemyCountWithCreatureType(10, "恶魔")
local UndeadCount = Skippy.GetEnemyCountWithCreatureType(10, "亡灵")

-- 没有检测到[命令圣印]或[复仇圣印]，会释放已经学会的圣印。
if not Skippy.GetPlayerAurasByTable(aura_env.seal) then
    if spell("命令圣印", "player") then
        return Skippy.PressKey("命令圣印")
    end
    if spell("腐蚀圣印", "player") then
        return Skippy.PressKey("腐蚀圣印")
    end
    if spell("复仇圣印", "player") then
        return Skippy.PressKey("复仇圣印")
    end
    return Skippy.PressKey("正义圣印")
end
-- 有目标，目标存活，目标可以攻击
if target.exists and not target.isDead and target.canAttack then
    if spell("清算", "target") and GlyphofReckoning then
        return Skippy.PressKey("清算")
    end

    if spell("奉献", "target") and not state.isMoving then
        if percentMana > 20 and enemyCount8 >= 5 then
            return Skippy.PressKey("奉献")
        end
        if percentMana > 80 and enemyCount8 >= 3 then
            return Skippy.PressKey("奉献")
        end
    end

    if spell("神圣风暴", "target") and enemyCount8 >= 3 then
        return Skippy.PressKey("神圣风暴")
    end

    if spell("愤怒之锤", "target") and target.percentHealth < 20 then
        return Skippy.PressKey("愤怒之锤")
    end

    if spell("十字军打击", "target") and enemyCount8 == 1 then
        return Skippy.PressKey("十字军打击")
    end

    if spell("圣光审判", "target") and spell("智慧审判", "target") then
        if PlayersLight then
            return Skippy.PressKey("圣光审判")
        end
        if PlayersWisdom then
            return Skippy.PressKey("智慧审判")
        end
        if not Wisdom and state.inParty then
            return Skippy.PressKey("智慧审判")
        end
        if not Light then
            return Skippy.PressKey("圣光审判")
        end
        return Skippy.PressKey("智慧审判")
    end

    if spell("奉献", "target") and percentMana > 80 and not state.isMoving and enemyCount8 >= 1 then
        return Skippy.PressKey("奉献")
    end

    if spell("神圣风暴", "target") and enemyCount8 >= 1 then
        return Skippy.PressKey("神圣风暴")
    end

    if spell("神圣愤怒", "target") and (DemonsCount + UndeadCount) >= 3 then
        return Skippy.PressKey("神圣愤怒")
    end

    if spell("十字军打击", "target") then
        return Skippy.PressKey("十字军打击")
    end

    if spell("驱邪术", "target") and WarArt then
        return Skippy.PressKey("驱邪术")
    end

    if spell("神圣愤怒", "target") and (DemonsCount + UndeadCount) >= 1 then
        return Skippy.PressKey("神圣愤怒")
    end
end

if spell("神圣恳求", "player") and percentMana < 40 then
    return Skippy.UnitHeal("spell", "神圣恳求")
end

return Skippy.PressKey("None")
