local usable = Skippy.IsUsableSpell
local playerAuras = Skippy.GetPlayerAuraByName
local targetAuras = Skippy.GetTargetAuraByPlayer

function aura_env.info()
    aura_env.RagingBlowCharges = playerAuras(131116) and playerAuras(131116).applications or 0 -- 怒击充能
    aura_env.enrage = playerAuras(12880)                                                       -- 狂暴之怒
    aura_env.Bloodsurge = playerAuras(46916)                                                   -- 血脉喷张
    aura_env.MeatCleaver = playerAuras(85739) and playerAuras(85739).applications or 0         -- 绞肉机
    aura_env.ColossusSmash = targetAuras(86346)                                                -- 巨人打击
    aura_env.rage = Skippy.State.power.RAGE.powerValue
end

function aura_env.SingleTarget()
    if usable("嗜血") and aura_env.RagingBlowCharges < 2 then
        return "嗜血"
    end

    if usable("巨龙怒吼") and not aura_env.ColossusSmash then
        return "巨龙怒吼"
    end

    if usable("巨人打击") then
        return "巨人打击"
    end

    if usable("狂暴之怒") and aura_env.ColossusSmash and aura_env.RagingBlowCharges < 2 then -- 巨人打击
        return "狂暴之怒"
    end

    if usable("风暴之锤") then
        return "风暴之锤"
    end

    if aura_env.ColossusSmash then -- 巨人打击
        if usable("怒击") and aura_env.RagingBlowCharges >= 1 and aura_env.rage > 10 then
            return "怒击"
        end

        if usable("英勇打击") and aura_env.rage > 50 then
            return "英勇打击"
        end
    else
        if usable("怒击") and aura_env.RagingBlowCharges == 2 and aura_env.rage > 10 then
            return "怒击"
        end

        if usable("狂暴之怒") and not aura_env.enrage then
            return "狂暴之怒"
        end
    end

    if usable("狂风打击") and aura_env.Bloodsurge then
        return "狂风打击"
    end

    if usable("剑刃风暴") then
        return "剑刃风暴"
    end

    if usable("狂风打击") then
        return "狂风打击"
    end

    if usable("战斗怒吼") and aura_env.rage < 90 then
        return "战斗怒吼"
    end

    if usable("英勇打击") and aura_env.rage > 90 then
        return "英勇打击"
    end
end

function aura_env.Execute()
    if usable("嗜血") and not aura_env.enrage then
        return "嗜血"
    end

    if usable("巨龙怒吼") and not aura_env.ColossusSmash then
        return "巨龙怒吼"
    end

    if usable("巨人打击") then
        return "巨人打击"
    end

    if usable("狂暴之怒") and not aura_env.enrage then -- 巨人打击
        return "狂暴之怒"
    end

    if aura_env.ColossusSmash then -- 巨人打击
        if usable("斩杀") and aura_env.rage > 30 then
            return "斩杀"
        end

        if usable("怒击") and aura_env.RagingBlowCharges >= 1 and aura_env.rage > 10 then
            return "怒击"
        end

        if usable("英勇打击") and aura_env.rage > 80 then
            return "英勇打击"
        end
    end

    if usable("嗜血") then
        return "嗜血"
    end

    if not aura_env.ColossusSmash then
        if usable("斩杀") and aura_env.rage > 50 then
            return "斩杀"
        end
    end

    if usable("怒击") and aura_env.RagingBlowCharges >= 1 and aura_env.rage > 10 then
        return "怒击"
    end

    if usable("狂风打击") and aura_env.Bloodsurge then
        return "狂风打击"
    end

    if usable("剑刃风暴") then
        return "剑刃风暴"
    end

    if usable("战斗怒吼") and aura_env.rage < 90 then
        return "战斗怒吼"
    end

    if usable("英勇打击") and aura_env.rage > 90 then
        return "英勇打击"
    end
end

function aura_env.MultiTarget()
    -- Cast  狂暴之怒 if  激怒 is missing.
    if usable("狂暴之怒") and not aura_env.enrage then
        return "狂暴之怒"
    end
    -- Cast  剑刃风暴 along with  鲁莽,  颅骨战旗, and  战斗怒吼.
    if usable("剑刃风暴") then
        return "剑刃风暴"
    end
    -- Cast  巨龙怒吼.
    if usable("巨龙怒吼") then
        return "巨龙怒吼"
    end
    -- Cast  嗜血 unless you have 2 charges of  怒击.
    if usable("嗜血") and aura_env.RagingBlowCharges < 2 then
        return "嗜血"
    end
    -- Cast  旋风斩 until you have an adequate amount of  绞肉机 stacks.
    if usable("旋风斩") and aura_env.rage > 30 and aura_env.MeatCleaver < 3 then
        return "旋风斩"
    end
    -- Cast  巨人打击.
    if usable("巨人打击") then
        return "巨人打击"
    end
    -- Cast  怒击.
    if usable("怒击") and aura_env.RagingBlowCharges >= 1 and aura_env.rage > 10 then
        return "怒击"
    end
    -- Cast  狂风打击 with  血脉贲张.
    if usable("狂风打击") and aura_env.Bloodsurge then
        return "狂风打击"
    end
    -- Cast  旋风斩 on 3+ targets for damage if you already have an adequate amount of  绞肉机 stacks.
    if usable("旋风斩") and aura_env.rage > 30 and aura_env.MeatCleaver >= 3 and Skippy.GetEnemyCount(8) >= 3 then
        return "旋风斩"
    end
    -- Cast  战斗怒吼.
    if usable("战斗怒吼") and aura_env.rage < 90 then
        return "战斗怒吼"
    end
    -- Cast  顺劈斩 if Rage will get capped.
    if usable("顺劈斩") and aura_env.rage > 90 then
        return "顺劈斩"
    end
end
