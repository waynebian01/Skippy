-- CLEU:UNIT_DIED, CLEU:SPELL_MISSED
function CLEU(event, timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
              destName, destFlags, destRaidFlags, ...)
    -- 处理单位死亡
    if subEvent == "UNIT_DIED" then
        for k, v in pairs(Skippy.Units.Group) do
            if v.GUID == destGUID then
                v.isDead = UnitIsDeadOrGhost(k)
            end
        end
    end
end
