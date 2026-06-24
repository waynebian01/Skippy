if not Skippy or not Skippy.Units then
    return "Skippy 未加载"
end

local units = Skippy.Units
local lines = {}

local function appendUnit(id, obj)
    if not obj or type(obj) ~= "table" then return end
    if not obj.exists and not obj.name then return end

    local hp = "-"
    if obj.healthInfo and obj.healthInfo.healthMax and obj.healthInfo.healthMax > 0 then
        hp = string.format("%.0f%%", obj.healthInfo.health / obj.healthInfo.healthMax * 100)
    elseif obj.healthPercent then
        hp = string.format("%.0f%%", obj.healthPercent)
    end

    lines[#lines + 1] = string.format(
        "%s | %s | HP:%s | 距离:%s | 存活:%s | 可交互:%s",
        id,
        obj.name or "?",
        hp,
        obj.maxRange and tostring(obj.maxRange) or "-",
        obj.isDead and "否" or "是",
        obj.canAssist and "是" or "否"
    )
end

local function appendGroup(title, tbl)
    if not tbl then return end
    local keys = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys)
    if #keys == 0 then return end

    lines[#lines + 1] = "—— " .. title .. " ——"
    for _, id in ipairs(keys) do
        appendUnit(id, tbl[id])
    end
end

appendUnit("target", units.target)
appendUnit("focus", units.focus)
appendGroup("Group", units.Group)
appendGroup("Boss", units.Boss)
appendGroup("Nameplate", units.Nameplate)

if #lines == 0 then
    return "无单位数据"
end

return table.concat(lines, "\n")
