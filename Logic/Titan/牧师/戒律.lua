if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.UnitHeal then return end
if Skippy.State.class ~= "牧师" then return end
if not Skippy.State.inParty then return Skippy.UnitHeal("Skip", "Skip") end

-- ===== 状态 =====
local state = Skippy.State
local target = Skippy.Units.target
local mana = state.power.MANA[1]
local manaMax = state.power.MANA[2]
local percentMana = mana / manaMax * 100

-- ===== 变量 =====
local Cast = Skippy.UnitHeal
local spell = Skippy.IsUsableSpellOnUnit
local cd = Skippy.GetSpellCooldown
local player = Skippy.GetPlayerInfo()
local playerAuras = Skippy.GetPlayerAuras
local lowestUnit, lowestHealth = Skippy.GetLowestUnit()
local noRenewUnit, noRenewHealth = Skippy.GetLowestUnitWithoutPlayerAuras("恢复")
local noRenewTank = Skippy.GetUnitWithoutPlayerAurasAndRole("恢复", "TANK")
local noMendingTank = Skippy.GetUnitWithoutPlayerAurasAndRole("愈合祷言", "TANK")
local shield = aura_env.GetNoShieldUnit()
local bindingUnit, bindingHealth = Skippy.GetLowestUnitWithoutPlayer()
local count75 = Skippy.GetCount(75)
local hasMagicUnit = Skippy.GetUnitHasDebuffWithdispelName("Magic")
local hasDiseaseUnit = Skippy.GetUnitHasDebuffWithdispelName("Disease")
local hasPoisonUnit = Skippy.GetUnitHasDebuffWithdispelName("Poison")
local InnerFocus = playerAuras("心灵专注")
local Borrowed = playerAuras("争分夺秒")
local set = aura_env.config
-- ===== 逻辑 =====
-- 引导或喝水时,什么也不做
if state.channel or playerAuras("饮水") then return Cast("None", "None") end
-- 当施放[治疗祷言]时,设定[心灵专注]为false
if state.cast then
    if state.castInfo.name == "治疗祷言" then
        InnerFocus = false
    end
    Borrowed = false
end
-- 当[绝望祷言]可以施放,玩家生命值低于40%时,施放[绝望祷言]
if spell("绝望祷言") and player and player.percentHealth < 40 then
    return Cast("spell", "绝望祷言")
end
-- 当[心灵专注]激活时
if InnerFocus then
    -- 当正在施放其他法术时,停止施法
    if state.cast and state.castInfo.name ~= "治疗祷言" then
        return Cast("spell", "停止施法")
    end
    -- 当[治疗祷言]可以施放时,施放[治疗祷言]
    if spell("治疗祷言", lowestUnit) then
        return Cast(lowestUnit, "治疗祷言")
    end
    -- 当[心灵专注]可以施放时,生命值低于75%的单位大于3个时,施放[心灵专注]
elseif spell("心灵专注") and count75 >= 3 and not Skippy.State.inRaid then
    return Cast("spell", "心灵专注")
end
-- 当[奥术洪流]可以施放,魔法值低于90%时,施放[奥术洪流]
if state.isCombat and spell("奥术洪流") and percentMana < 90 then
    return Cast("spell", "奥术洪流")
end
-- 当[争分夺秒]激活时
if Borrowed then
    -- 当[苦修]可以施放,生命值低于75%时,施放[苦修]
    if spell("苦修", lowestUnit) and lowestHealth < set["苦修"] then
        return Cast(lowestUnit, "苦修")
    end
    -- 当[快速治疗]可以施放,生命值低于75%时,施放[快速治疗]
    if spell("快速治疗", lowestUnit) and lowestHealth < set["快速治疗"] then
        return Cast(lowestUnit, "快速治疗")
    end
end
-- 当[暗影魔]可以施放,魔法值低于60%,目标生命值大于80%时,施放[暗影魔]
if state.isCombat and spell("暗影魔", "target") and percentMana < 60 and target.percentHealth > 80 then
    return Cast("target", "暗影魔")
end
-- 当[真言术：盾]可以施放,有Debuff的单位时,施放[真言术：盾]
if cd("真言术：盾") <= 1 and shield.hasDebuffUnit then
    return Cast(shield.hasDebuffUnit, "真言术：盾")
end
-- 当[真言术：盾]可以施放,对坦克单位施放[真言术：盾]
if cd("真言术：盾") <= 1 and shield.tankUnit then
    return Cast(shield.tankUnit, "真言术：盾")
end
-- 当[愈合祷言]可以施放,对坦克单位时施放[愈合祷言]
if spell("愈合祷言", noMendingTank) then
    return Cast(noMendingTank, "愈合祷言")
end
-- 当[真言术：盾]可以施放,最低血量单位时,施放[真言术：盾]
if cd("真言术：盾") <= 1 and shield.lowestUnit and shield.lowestHealth < set["真言术：盾"] then
    return Cast(shield.lowestUnit, "真言术：盾")
end
-- 当[苦修]可以施放,坦克生命值低于阈值时,施放[苦修]
if spell("苦修", shield.tankUnit) and shield.tankHealth < set["苦修"] then
    return Cast(shield.tankUnit, "苦修")
end
-- 当[苦修]可以施放,生命值低于阈值时,施放[苦修]
if spell("苦修", lowestUnit) and lowestHealth < set["苦修"] then
    return Cast(lowestUnit, "苦修")
end
-- 当[治疗祷言]可以施放时,生命值低于75%的单位大于4个时,施放[治疗祷言]
if spell("治疗祷言", lowestUnit) and Skippy.GetCount(80) >= 4 and not Skippy.State.inRaid then
    return Cast(lowestUnit, "治疗祷言")
end
-- 当[联结治疗]可以施放,玩家生命值低于75%,联结治疗生命值低于75%时,施放[联结治疗]
if spell("联结治疗", bindingUnit) and player and player.percentHealth < set["联结治疗"] and bindingHealth < set["联结治疗"] then
    return Cast(bindingUnit, "联结治疗")
end
-- 当[快速治疗]可以施放,生命值低于75%时,施放[快速治疗]
if spell("快速治疗", lowestUnit) and lowestHealth < set["快速治疗"] then
    return Cast(lowestUnit, "快速治疗")
end
-- 驱散魔法
if spell("驱散魔法", hasMagicUnit) then
    return Cast(hasMagicUnit, "驱散魔法")
end
-- 驱除疾病
if spell("驱除疾病", hasDiseaseUnit) then
    return Cast(hasDiseaseUnit, "驱除疾病")
end
return Cast("None", "None")
