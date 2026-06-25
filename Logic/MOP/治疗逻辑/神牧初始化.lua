function aura_env.getChakraCooldown()
    local chakra = { 81209, 81208, 81206 } -- 脉轮：罚, 佑, 静 ; 共享冷却的技能
    local cooldown = 0
    for _, spellID in pairs(chakra) do
        local cd = Skippy.GetSpellCooldown(spellID)
        if cd and cd > cooldown then
            cooldown = cd
        end
    end
    return cooldown
end
