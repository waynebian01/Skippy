if not Skippy or not Skippy.Units or not Skippy.State or not Skippy.updateSpellIndex then return end
if Skippy.State.class ~= "战士" or Skippy.State.specID ~= 72 then return end
if not Skippy.macrosReady then return Skippy.updateSpellIndex(nil, nil) end

local SendSpell = Skippy.updateSpellIndex
local enemyCount = Skippy.GetEnemyCount(8)
local target = Skippy.Units.target

if target.exists and target.canAttack then
    aura_env.info()
    local spellName
    if (target.healthPercent or 100) < 20 then
        spellName = aura_env.Execute()
    elseif enemyCount == 1 then
        spellName = aura_env.SingleTarget()
    elseif enemyCount >= 2 then
        spellName = aura_env.MultiTarget()
    end
    return SendSpell(spellName and "spell" or nil, spellName)
end

return SendSpell(nil, nil)
