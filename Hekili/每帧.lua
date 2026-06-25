--HEKILI_RECOMMENDATION_UPDATE
function HEKILI(event, event_display, event_ability_id, indicator, empower_to)
    if event_display == nil or event_ability_id == nil then
        Wa1Key.Prop.HekiliCode = 0
        return false
    end

    local channel = UnitChannelInfo("player")

    local rec = HekiliDisplayPrimary and HekiliDisplayPrimary.Recommendations
        and HekiliDisplayPrimary.Recommendations[1]
    if not rec then
        Wa1Key.Prop.HekiliCode = 0
        return false
    end

    local assistedID = C_AssistedCombat.GetNextCastSpell()
    local keybind = aura_env.keymap and aura_env.keymap[rec.keybind]

    local waitTime = 1

    if channel then
        waitTime = 0.2
    end

    if not channel then
        if event_ability_id < 0 then
            Wa1Key.Prop.HekiliCode = 254 -- 饰品
            return true
        end
        if assistedID and aura_env.assisted and aura_env.assisted[assistedID] then
            Wa1Key.Prop.HekiliCode = 253 -- 一键辅助
            return true
        end
    end

    if keybind and rec.delay then
        if rec.delay <= waitTime then
            Wa1Key.Prop.HekiliCode = keybind
            return true
        else
            Wa1Key.Prop.HekiliCode = 0
            return true
        end
    end

    Wa1Key.Prop.HekiliCode = 0

    return true
end
