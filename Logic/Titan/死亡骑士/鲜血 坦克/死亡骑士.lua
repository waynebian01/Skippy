if not Skippy or not Skippy.Units or not Skippy.State then return end
if Skippy.State.class ~= "死亡骑士" then return end

-- ===== 状态 =====
local state = Skippy.State
local player = Skippy.GetPlayerInfo()
local healthPct = player and player.percentHealth or 100
local runic = state.power.RUNIC_POWER[1]
local runicMax = state.power.RUNIC_POWER[2]
local target = Skippy.Units.target
local FrostPresence = state.shapeshiftForm["冰霜灵气"]
local spell = Skippy.IsUsableSpellOnUnit
local cd = Skippy.GetSpellCooldown

-- ===== 变量 =====
local enemyCount = Skippy.GetEnemyCount(10)
local GlyphofDisease = C_SpellBook.IsSpellKnown(63334) -- 疾病雕文,你的传染技能可以使你的主要目标身上的疾病效果持续时间、疾病附加效果持续时间刷新到起始状态。
local runes = aura_env.RuneCount()
local canUseBloodSkill = true -- 是否可以使用[鲜血符文]技能
local useDeathCount = 0 -- 灵界打击使用[死亡符文]的数量
local canUseDeathStrike = true -- 是否可以使用[灵界打击]
local isRuneStrike = C_Spell.IsCurrentSpell("符文打击")
local BloodGorged = Skippy.GetPlayerAuraByName("啜血") -- 啜血,减少枯萎凋零的消耗

-- 疾病效果
local plagueInfo = aura_env.PlagueInfo()
local noPlagueCount, hasPlagueCount = aura_env.PlagueCount()

local DeathAndDecayCD = aura_env.DecayExpirationTime - GetTime() --死亡凋零CD

-- ===== 逻辑 =====
-- 当[冰霜灵气]不存在时,施放[冰霜灵气]
if not FrostPresence then
    return Skippy.PressKey("冰霜灵气")
end
-- 如果有疾病雕文,用传染延迟疾病的时间,使疾病时间刷新到起始状态
if GlyphofDisease and plagueInfo.FrostFever and plagueInfo.BloodPlague then
    -- 如果任意一个疾病时间小于3秒，则释放传染
    if plagueInfo.ShortestPlague <= 3 then
        if runes.BloodRunes_Count + runes.DeathRunes_Count >= 1 or
            runes.DeathRunes_CD <= 3 or
            runes.BloodRunes_CD <= 3 then
            return Skippy.PressKey("传染")
        end
    end
    -- 计算施放[灵界打击]需要的死亡符文数量
    if runes.UnholyRunes_Count == 0 then
        useDeathCount = useDeathCount + 1
    end
    if runes.FrostRunes_Count == 0 then
        useDeathCount = useDeathCount + 1
    end
    -- 当[鲜血符文]和[死亡符文]CD > 最短[疾病]持续时间时
    if (runes.BloodRunes_CD > plagueInfo.ShortestPlague and
            runes.DeathRunes_CD > plagueInfo.ShortestPlague) then
        -- 当[鲜血]和[死亡]符文总数等于1时,不可以使用[鲜血符文]技能
        if runes.BloodRunes_Count + runes.DeathRunes_Count <= 1 then
            canUseBloodSkill = false
        end
        -- 当[灵界打击]需要的全部[死亡符文]数量时,不可以使用[灵界打击]
        if runes.DeathRunes_Count <= useDeathCount then
            canUseDeathStrike = false
        end
    end
end
-- 当[符文打击]可以施放时,施放[符文打击]
if spell("符文打击", "target") and not isRuneStrike then
    return Skippy.PressKey("符文打击")
end
-- 当[灵界打击]可以施放,生命值低于40%时,施放[灵界打击]
if spell("灵界打击", "target") and healthPct < 40 then
    return Skippy.PressKey("灵界打击")
end
if spell("符文分流") then
    -- 当[鲜血]符文数量为2时,生命值低于70%时,施放[符文分流]
    if runes.BloodRunes_Count == 2 and healthPct < 70 then
        return Skippy.PressKey("符文分流")
    end
    -- 当生命值低于50%时,施放[符文分流]
    if healthPct < 50 then
        return Skippy.PressKey("符文分流")
    end
end
-- 当敌人数量大于等一1时
if enemyCount >= 1 then
    -- 当[血液沸腾]可以施放,死亡凋零CD小于3秒,没有[啜血]时,施放[血液沸腾]
    if spell("血液沸腾") and DeathAndDecayCD <= 3 and not BloodGorged and canUseBloodSkill then
        return Skippy.PressKey("血液沸腾")
    end
    -- 当[啜血]存在,死亡凋零CD小于1.5秒时,施放[枯萎凋零]
    if BloodGorged and DeathAndDecayCD <= 1.5 then
        return Skippy.PressKey("枯萎凋零")
    end
    -- 当[活力分流]可以施放,[鲜血符文]数量为0时,施放[活力分流]
    if spell("活力分流") and runes.BloodRunes_Count == 0 then
        return Skippy.PressKey("活力分流")
    end
end
-- 当[传染]可以施放,敌人数量大于等于2,目标有疾病,没有疾病单位大于等于1时,施放[传染]
if spell("传染", "target") and enemyCount >= 2 and plagueInfo.ShortestPlague and noPlagueCount >= 1 then
    return Skippy.PressKey("传染")
end
if hasPlagueCount == 0 then
    -- 当[冰冷触摸]可以施放,目标没有[冰霜疫病]时,施放[冰冷触摸]
    if spell("冰冷触摸", "target") and not plagueInfo.FrostFever then
        return Skippy.PressKey("冰冷触摸")
    end
    -- 当[暗影打击]可以施放,目标没有[血之疫病]时,施放[暗影打击]
    if spell("暗影打击", "target") and not plagueInfo.BloodPlague then
        return Skippy.PressKey("暗影打击")
    end
end
-- 当[血液沸腾]可以施放,敌人数量大于等于3,可以使用[鲜血符文]技能,施放[血液沸腾]
if spell("血液沸腾", "target") and enemyCount >= 3 and canUseBloodSkill then
    return Skippy.PressKey("血液沸腾")
end
-- 当[灵界打击]可以施放,生命值低于80%时,施放[灵界打击]
if spell("灵界打击", "target") and healthPct < 80 then
    -- 当[鲜血]和[冰霜]符文都存在时,施放[灵界打击]
    if runes.UnholyRunes_Count > 0 and runes.FrostRunes_Count > 0 then
        return Skippy.PressKey("灵界打击")
    end
    -- 当[鲜血]和[冰霜]符文都不存在时,[死亡]符文可用时又不影响使用[传染]时,施放[灵界打击]
    if canUseDeathStrike then
        return Skippy.PressKey("灵界打击")
    end
end
-- 当[凋零缠绕]可以施放,符能缺口小于等于20时,施放[凋零缠绕]
if spell("凋零缠绕", "target") and runicMax - runic <= 20 then
    return Skippy.PressKey("凋零缠绕")
end
-- 当[灵界打击]可以施放,[鲜血]和[冰霜]符文都存在时,施放[灵界打击]
if spell("灵界打击", "target") and runes.UnholyRunes_Count > 0 and runes.FrostRunes_Count > 0 then
    return Skippy.PressKey("灵界打击")
end
-- 当[心脏打击]可以施放,可以使用[鲜血符文]技能时,施放[心脏打击]
if spell("心脏打击", "target") and canUseBloodSkill then
    return Skippy.PressKey("心脏打击")
end
-- 当[鲜血打击]可以施放,可以使用[鲜血符文]技能时,施放[鲜血打击]
if spell("鲜血打击", "target") and canUseBloodSkill then
    return Skippy.PressKey("鲜血打击")
end
-- 当[寒冬号角]可以施放时,施放[寒冬号角]
if spell("寒冬号角") then
    return Skippy.PressKey("寒冬号角")
end
-- 当没有目标时,施放[None]
return Skippy.PressKey("None")
