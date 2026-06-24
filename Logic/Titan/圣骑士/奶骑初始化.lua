aura_env.BeaconUnit = nil
aura_env.ShieldUnit = nil
aura_env.healingUnit = nil
aura_env.isCastingHolyLight = false
aura_env.isCastingFlashLight = false
aura_env.Judgement = "圣光审判"
aura_env.seal = { "命令圣印", "腐蚀圣印", "复仇圣印" }

function aura_env.InitConfig()
    aura_env.holyLight = aura_env.config["HL_Party"]
    aura_env.flash = aura_env.config["FL_Party"]
    if Skippy.State.inRaid then
        aura_env.holyLight = aura_env.config["HL_Raid"]
        aura_env.flash = aura_env.config["FL_Raid"]
    end
end

aura_env.InitConfig()

aura_env.HolyLightSpellIds = {
    [635] = true,   -- 等级1
    [639] = true,   -- 等级2
    [647] = true,   -- 等级3
    [1026] = true,  -- 等级4
    [1042] = true,  -- 等级5
    [3472] = true,  -- 等级6
    [10328] = true, -- 等级7
    [10329] = true, -- 等级8
    [25292] = true, -- 等级9
    [27135] = true, -- 等级10
    [27136] = true, -- 等级11
    [48781] = true, -- 等级12
    [48782] = true, -- 等级13
}

aura_env.FlashLightSpellIds = {
    [19750] = true, -- 等级1
    [19939] = true, -- 等级2
    [19940] = true, -- 等级3
    [19941] = true, -- 等级4
    [19942] = true, -- 等级5
    [19943] = true, -- 等级6
    [27137] = true, -- 等级7
    [48784] = true, -- 等级8
    [48785] = true, -- 等级9
}

function aura_env.GetUnitAuraBySpellId(unit, spellId, byPlayerOnly)
    if not Skippy.Group then return nil end
    local data = Skippy.Group[unit]
    if data and data.inRange and data.canAssist and data.inSight and not data.isDead then
        for _, aura in pairs(data.aura) do
            if (byPlayerOnly and aura.sourceUnit == "player") or not byPlayerOnly then
                if aura.spellId == spellId then
                    return aura
                end
            end
        end
    end
    return nil
end

function aura_env.SetUnitByName(name, spellName)
    if not Skippy.Group then return nil end
    for unit, data in pairs(Skippy.Group) do
        if data and data.name == name then
            if spellName == "Beacon" then
                aura_env.BeaconUnit = unit
            end
            if spellName == "Shield" then
                aura_env.ShieldUnit = unit
            end
            if spellName == "Healing" then
                aura_env.healingUnit = unit
            end
        end
    end
end
