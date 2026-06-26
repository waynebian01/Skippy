C_Timer.After(2, function()
    aura_env.EternalFlame = Skippy.SpellBook["永恒之火"] -- 是否学会[永恒之火]
    aura_env.SealofInsight = Skippy.SpellBook["洞察圣印"] -- 是否学会[洞察圣印]
    aura_env.SelflessHealer = Skippy.SpellBook["无私治愈"] -- 是否学会[无私治愈]
    aura_env.init = true
end)

function aura_env.SendSpell(spellName, unit)
    local spell, text = Skippy.updateSpellIndex(spellName, unit)
    aura_env.txt = text
    return spell
end
