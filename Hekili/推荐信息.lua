-- WeakAuras 自定义文本：仅显示 HekiliDisplayPrimary.Recommendations[1]

local RED = "|cffff0000"
local RESET = "|r"

local lines = {}

local function add(line)
    lines[#lines + 1] = line
end

local function formatScalar(v)
    local t = type(v)
    if t == "nil" then return "nil" end
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then
        if math.floor(v) == v then return tostring(v) end
        return string.format("%.3f", v)
    end
    if t == "string" then
        if v == "" then return '""' end
        return v
    end
    return tostring(v)
end

local function sortedKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b)
        if type(a) == "number" and type(b) == "number" then return a < b end
        return tostring(a) < tostring(b)
    end)
    return keys
end

local function dumpTable(tbl, indent, depth, maxDepth)
    indent = indent or ""
    depth = depth or 0
    maxDepth = maxDepth or 2

    for _, k in ipairs(sortedKeys(tbl)) do
        local v = tbl[k]
        local key = tostring(k)

        if type(v) == "table" and depth < maxDepth then
            add(indent .. key .. ":")
            dumpTable(v, indent .. "  ", depth + 1, maxDepth)
        elseif type(v) == "table" then
            local parts = {}
            for sk, sv in pairs(v) do
                if type(sv) ~= "table" then
                    parts[#parts + 1] = tostring(sk) .. "=" .. formatScalar(sv)
                end
            end
            table.sort(parts)
            add(indent .. key .. ": {" .. (#parts > 0 and table.concat(parts, ", ") or "table") .. "}")
        else
            add(indent .. key .. ": " .. formatScalar(v))
        end
    end
end

local rec = HekiliDisplayPrimary
    and HekiliDisplayPrimary.Recommendations
    and HekiliDisplayPrimary.Recommendations[1]

if not rec or not next(rec) then
    return RED .. "Recommendations[1] 无数据" .. RESET
end

dumpTable(rec, "", 0, 2)

local text = table.concat(lines, "\n")
if aura_env then
    aura_env.txt = text
end
return text
