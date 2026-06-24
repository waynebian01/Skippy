if not Skippy or not Skippy.Units or not Skippy.State then return end
if Skippy.State.class ~= "战士" then return end

local player = Skippy.GetPlayerInfo()
local playerAuras = Skippy.GetPlayerAuras
local spell = Skippy.IsUsableSpellOnUnit
local cd = Skippy.GetSpellCooldown
local state = Skippy.State
local rage = state.power.RAGE[1]
local target = Skippy.Units.target
local isHeroicStrike = C_Spell.IsCurrentSpell("英勇打击")
local isCleave = C_Spell.IsCurrentSpell("顺劈斩")
local BattleShoutByPlayer = Skippy.GetPlayerAuras("战斗怒吼") -- 战斗怒吼,自己施放的[战斗怒吼]
local BattleShout = Skippy.GetPlayerAuras("战斗怒吼", false) -- 战斗怒吼,任意单位施放的[战斗怒吼]
local CommandShoutByPlayer = Skippy.GetPlayerAuras("命令怒吼") -- 命令怒吼,自己施放的[命令怒吼]
local CommandShout = Skippy.GetPlayerAuras("命令怒吼", false) -- 命令怒吼,任意单位施放的[命令怒吼]
local Might = Skippy.GetPlayerAuras("力量祝福", false) -- 力量祝福
local GreaterMight = Skippy.GetPlayerAuras("强效力量祝福", false) -- 强效力量祝福
local SwordBoard = Skippy.GetPlayerAuras("剑盾猛攻") -- 剑盾猛攻,盾牌猛击技能结束冷却，并使其消耗的怒气值减少100%
local noSpeedSlowCount = Skippy.AttackSpeedSlow() -- 没有减攻速debuff的敌人数量，有减攻速debuff的敌人数量
local noPowerSlowCount = Skippy.AttackPowerSlow() -- 没有减攻强debuff的敌人数量，有减攻强debuff的敌人数量
local enemyCount = Skippy.GetEnemyCount(10)
local shapeshiftForm = Skippy.State.shapeshiftForm
local freeHeroicStrike = playerAuras("复仇雕文") -- 复仇雕文,使你的英勇打击技能消耗0点怒气
local rend = Skippy.GetTargetAurasByPlayer("撕裂") -- 撕裂


-- 当有[复仇雕文]光环时，使用[英勇打击]
if freeHeroicStrike and not isHeroicStrike then
    return Skippy.PressKey("英勇打击")
end
-- 当有[力量祝福]或[强效力量祝福]时，使用[命令怒吼]
if Might or GreaterMight then
    if spell("命令怒吼") then
        if not CommandShout then
            return Skippy.PressKey("命令怒吼")
        end
        if CommandShout.expirationTime - GetTime() < 5 then
            return Skippy.PressKey("命令怒吼")
        end
    end
else
    if spell("战斗怒吼") and aura_env.Shout == "战斗怒吼" then
        if not BattleShout then
            return Skippy.PressKey("战斗怒吼")
        end
        if BattleShout.expirationTime - GetTime() < 5 then
            return Skippy.PressKey("战斗怒吼")
        end
    end
    if spell("命令怒吼") and aura_env.Shout == "命令怒吼" then
        if not CommandShout then
            return Skippy.PressKey("命令怒吼")
        end
        if CommandShout.expirationTime - GetTime() < 5 then
            return Skippy.PressKey("命令怒吼")
        end
    end
end

if shapeshiftForm["战斗姿态"] and aura_env.SweepingStrikes and cd("横扫攻击") == 0 then
    return Skippy.PressKey("横扫攻击")
end
if not shapeshiftForm["防御姿态"] then
    return Skippy.PressKey("防御姿态")
end
-- 多目标
if enemyCount >= 2 then
    if spell("顺劈斩", "target") and not freeHeroicStrike and not isCleave and rage > 50 then
        return Skippy.PressKey("顺劈斩")
    end
    -- 确保所有敌人都有减攻速debuff
    if spell("雷霆一击") and (noSpeedSlowCount >= 1 or enemyCount >= 3) then
        return Skippy.PressKey("雷霆一击")
    end
    if spell("复仇", "target") and aura_env.useRevenge then
        return Skippy.PressKey("复仇")
    end
    -- 确保所有敌人都有减攻强debuff
    if spell("挫志怒吼") and noPowerSlowCount >= 1 then
        return Skippy.PressKey("挫志怒吼")
    end
    if not shapeshiftForm["战斗姿态"] and aura_env.SweepingStrikes and cd("横扫攻击") == 0 then
        return Skippy.PressKey("战斗姿态")
    end
    if spell("复仇", "target") then
        return Skippy.PressKey("复仇")
    end
    if spell("盾牌猛击", "target") then
        return Skippy.PressKey("盾牌猛击")
    end
    if rage >= 50 then
        if spell("毁灭打击", "target") then
            return Skippy.PressKey("毁灭打击")
        end
        if spell("破甲攻击", "target") then
            return Skippy.PressKey("破甲攻击")
        end
    end
end
-- 单目标
if enemyCount == 1 then
    if spell("英勇打击", "target") and not isHeroicStrike and rage > 50 then
        return Skippy.PressKey("英勇打击")
    end
    if spell("盾牌猛击", "target") then
        return Skippy.PressKey("盾牌猛击")
    end
    -- 确保所有敌人都有减攻速debuff
    if spell("雷霆一击") and (noSpeedSlowCount >= 1 or enemyCount >= 3) then
        return Skippy.PressKey("雷霆一击")
    end
    -- 确保所有敌人都有减攻强debuff
    if spell("挫志怒吼") and not state.isMoving and noPowerSlowCount >= 1 then
        return Skippy.PressKey("挫志怒吼")
    end
    if spell("复仇", "target") then
        return Skippy.PressKey("复仇")
    end
    if spell("震荡波", "target") and not state.isMoving then
        return Skippy.PressKey("震荡波")
    end
    if spell("撕裂", "target") and not rend then
        return Skippy.PressKey("撕裂")
    end
    if rage >= 50 then
        if spell("毁灭打击", "target") then
            return Skippy.PressKey("毁灭打击")
        end
        if spell("破甲攻击", "target") then
            return Skippy.PressKey("破甲攻击")
        end
    end
end

return Skippy.PressKey("None")
