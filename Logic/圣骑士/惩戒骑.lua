if not Skippy or not aura_env.init or Skippy.State.specID ~= 70 then return false end

-- ===== 状态 =====
local state = Skippy.State
local target = Skippy.Units.target

-- ===== 变量 =====
local Spell = Skippy.IsUsableSpell
local SpellOnUnit = Skippy.IsUsableSpellOnUnit
local spellName = Skippy.HekiliSpellName

-- ===== 逻辑 =====
if not Skippy.Go then
    return aura_env.SendSpell("暂停")
end

if state.isCombat then
    if SpellOnUnit(spellName, "target") then
        return aura_env.SendSpell(spellName, "target")
    end
    if Spell(spellName) then
        if aura_env.SendSpell(spellName, "player") then
            return aura_env.SendSpell(spellName, "player")
        end
        if aura_env.SendSpell(spellName, "spell") then
            return aura_env.SendSpell(spellName, "spell")
        end
    end
end

return aura_env.SendSpell("休息")
