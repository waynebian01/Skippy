function aura_env.getChakraCooldown()
    local chakra = { 81209, 81208, 81206 } -- 脉轮：罚, 佑, 静 ; 共享冷却的技能
    local cooldown = 0
    for _, spellID in pairs(chakra) do
        local cd = Skippy.GetSpellCooldownDuration(spellID)
        if cd and cd > cooldown then
            cooldown = cd
        end
    end
    return cooldown
end

---@diagnostic disable-next-line: duplicate-set-field
function aura_env.SendSpell(spellName, unit)
    local spell, text = Skippy.updateSpellIndex(spellName, unit)
    aura_env.txt = text
    return spell
end

C_Timer.After(2, function()
    aura_env.init = true
end)
