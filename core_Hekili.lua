--HEKILI_RECOMMENDATION_UPDATE
function HEKILI(event, event_display, event_ability_id, indicator)
    local rec = HekiliDisplayPrimary and HekiliDisplayPrimary.Recommendations
        and HekiliDisplayPrimary.Recommendations[1]
    if not rec or not event_ability_id then
        Skippy.HekiliSpellName = nil
        return false
    end

    if event_ability_id < 0 then
        Skippy.HekiliSpellName = "饰品"
        return true
    end

    local spellName = Skippy.GetHekiliSpellName(event_ability_id)

    if not spellName then
        Skippy.HekiliSpellName = nil
        return false
    end

    local waitTime = 1

    if rec.delay then
        if rec.delay <= waitTime then
            Skippy.HekiliSpellName = spellName
            return true
        else
            Skippy.HekiliSpellName = spellName
            return true
        end
    end

    Skippy.HekiliSpellName = spellName

    return true
end
