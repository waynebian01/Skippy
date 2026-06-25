# Skippy 自定义函数使用说明

本文档介绍 `core_init.lua` 中常用的 `Skippy.*` 自定义函数如何在 WeakAuras 中调用。重点覆盖查询类函数、目标选择函数、数量统计函数和技能状态函数。

## 基础约定

### 常用单位 ID

可传入的 `unit` 通常是 WoW 单位 ID：

- `player`
- `target`
- `focus`
- `party1` 到 `party4`
- `raid1` 到 `raid40`
- `boss1` 到 `boss5`
- `nameplate1` 到 `nameplate40`

### 光环来源参数 `byPlayerOnly`

多个函数都有 `byPlayerOnly` 参数：

- `true`：只匹配玩家自己施放的光环
- `false`：匹配任意来源的光环
- 不传：多数函数默认等同 `true`

示例：

```lua
-- 只查自己施放的恢复
local aura = Skippy.GetPlayerAuraByName("恢复")

-- 查任意来源的恢复
local aura = Skippy.GetPlayerAuraByName("恢复", false)
```

### 职责参数 `role`

职责字符串一般使用：

- `TANK`
- `HEALER`
- `DAMAGER`

`role` 为 `nil` 或空字符串 `""` 时表示不限职责。

`hasRole` 表示是否包含该职责：

- `true`：只匹配该职责
- `false`：排除该职责
- 不传：默认 `true`

注意：职责过滤依赖单位数据里的 `data.role` 字段。如果当前脚本没有为队伍单位写入 `role`，职责过滤函数不会匹配到对应职责。

## 技能与宏相关

### `Skippy.updateSpellIndex(unit, spellName)`

根据单位和技能名更新 `Skippy.index`，通常用于光环里输出当前应该按哪个宏索引。

参数：

- `unit`：目标单位，如 `"raid3"`、`"target"`
- `spellName`：技能名，如 `"圣光术"`

返回：

- 固定返回 `true`
- 同时更新 `Skippy.index`

示例：

```lua
local unit = Skippy.GetLowestUnit()
Skippy.updateSpellIndex(unit, "圣光术")
return true
```

如果技能不在 `Skippy.SpellMap` 中，`Skippy.index` 会被设为 `0`。

### `Skippy.GetSpellInfo(spellIdentifier)`

获取缓存后的技能信息。

参数：

- `spellIdentifier`：技能名或技能 ID

返回：

- 技能信息表，或 `nil`

示例：

```lua
local info = Skippy.GetSpellInfo("圣光术")
if info and info.isHelpful then
    return true
end
```

返回表常见字段：

- `spellInfo`
- `cooldownInfo`
- `chargeInfo`
- `isUsable`
- `sufficientPower`
- `castCount`
- `isHarmful`
- `isHelpful`
- `isPassive`

### `Skippy.GetSpellCooldown(spellIdentifier)`

获取技能剩余冷却时间。

参数：

- `spellIdentifier`：技能名或技能 ID

返回：

- `0`：技能无冷却或已可用
- `number`：剩余冷却秒数
- `nil`：技能信息不存在

示例：

```lua
return Skippy.GetSpellCooldown("神圣震击") == 0
```

### `Skippy.IsUsableSpell(spellIdentifier)`

判断技能当前是否可用，包含冷却、充能和资源可用性。

参数：

- `spellIdentifier`：技能名或技能 ID

返回：

- `true` 或 `false`

示例：

```lua
if Skippy.IsUsableSpell("神圣震击") then
    return true
end
```

### `Skippy.IsUsableSpellOnUnit(spellIdentifier, unit)`

判断技能是否可用，并且目标是否在技能范围内。

参数：

- `spellIdentifier`：技能名或技能 ID
- `unit`：单位 ID

返回：

- `true` 或 `false`

示例：

```lua
local unit = Skippy.GetLowestUnit()
if unit and Skippy.IsUsableSpellOnUnit("圣光术", unit) then
    Skippy.updateSpellIndex(unit, "圣光术")
    return true
end
```

## 玩家状态查询

### `Skippy.GetPlayerAuraByName(auraName, byPlayerOnly)`

查询玩家身上的指定光环。

参数：

- `auraName`：光环名称
- `byPlayerOnly`：是否只查玩家自己施放的光环，默认 `true`

返回：

- 光环信息表，或 `nil`

示例：

```lua
local aura = Skippy.GetPlayerAuraByName("圣盾术", false)
return aura ~= nil
```

### `Skippy.GetPlayerAurasByTable(auraTable)`

判断玩家是否拥有列表中的任意一个光环。

参数：

- `auraTable`：光环名称或光环 ID 列表

返回：

- `true` 或 `false`

示例：

```lua
return Skippy.GetPlayerAurasByTable({
    "圣盾术",
    "保护之手",
    642,
})
```

### `Skippy.GetCastingDuration(reversed)`

获取玩家当前施法时间。

参数：

- `reversed`：
  - `true`：返回距离施法结束的剩余毫秒
  - `false` 或不传：返回从施法开始到当前的差值逻辑，按当前代码可能多用于内部判断

返回：

- `number`：毫秒
- `nil`：当前没有施法，或计算结果不大于 0

示例：

```lua
local remainMs = Skippy.GetCastingDuration(true)
return remainMs and remainMs < 500
```

### `Skippy.GetChannelingDuration(reversed)`

获取玩家当前引导时间。

参数和返回值同 `Skippy.GetCastingDuration`。

示例：

```lua
local remainMs = Skippy.GetChannelingDuration(true)
return remainMs and remainMs < 800
```

## 单位有效性与血量

### `Skippy.IsUnitCanAssist(unit)`

判断单位是否可协助、在范围内、在视野内且未死亡。

参数：

- `unit`：单位 ID

返回：

- `true` 或 `false`

示例：

```lua
return Skippy.IsUnitCanAssist("target")
```

### `Skippy.GetGroupAverageHealthPct()`

获取当前有效队伍成员的平均血量百分比。

返回：

- `number`：平均血量百分比
- 没有有效成员时返回 `0`

示例：

```lua
return Skippy.GetGroupAverageHealthPct() < 75
```

### `Skippy.GetGroupCount(healthThreshold)`

统计有效队伍成员中，血量低于指定百分比的人数。

参数：

- `healthThreshold`：血量百分比阈值，默认 `100`

返回：

- `number`

示例：

```lua
-- 血量低于 80% 的友方数量
return Skippy.GetGroupCount(80)
```

### `Skippy.GetGroupCountByAuraState(healthThreshold, auraName, hasAura, byPlayerOnly, role, hasRole)`

统计符合血量、光环和职责条件的有效队伍成员数量。

参数：

- `healthThreshold`：血量百分比阈值，默认 `100`
- `auraName`：光环名称
- `hasAura`：
  - `true`：统计有该光环的单位
  - `false`：统计没有该光环的单位
  - 不传：默认 `true`
- `byPlayerOnly`：是否只检查玩家施放的光环，默认 `true`
- `role`：职责过滤，如 `"TANK"`，不传表示不限
- `hasRole`：是否包含该职责，默认 `true`

返回：

- `number`

示例：

```lua
-- 统计 90% 血以下、没有自己施放的圣洁护盾的友方数量
local count = Skippy.GetGroupCountByAuraState(90, "圣洁护盾", false, true)
return count >= 2
```

```lua
-- 统计 80% 血以下、没有自己施放恢复、并且是坦克的数量
local count = Skippy.GetGroupCountByAuraState(80, "恢复", false, true, "TANK", true)
return count > 0
```

## 查找友方单位

### `Skippy.GetLowestUnit()`

获取有效队伍成员中血量最低的单位。

返回：

- `unit`：单位 ID，可能为 `nil`
- `healthPercent`：血量百分比，可能为 `nil`

示例：

```lua
local unit, hp = Skippy.GetLowestUnit()
if unit and hp < 80 then
    Skippy.updateSpellIndex(unit, "圣光术")
    return true
end
```

### `Skippy.GetLowestUnitWithoutUnit(unitId)`

获取血量最低的有效队伍成员，但排除指定单位。

参数：

- `unitId`：要排除的单位，如 `"target"`、`"player"`

返回：

- `unit`
- `healthPercent`

示例：

```lua
local unit, hp = Skippy.GetLowestUnitWithoutUnit("player")
return unit and hp < 70
```

### `Skippy.GetLowestUnitWithRoles(role1, role2, role3)`

获取指定职责中血量最低的有效队伍成员。

参数：

- `role1`、`role2`、`role3`：最多三个职责字符串

返回：

- `unit`
- `healthPercent`

示例：

```lua
local unit, hp = Skippy.GetLowestUnitWithRoles("TANK")
if unit and hp < 85 then
    Skippy.updateSpellIndex(unit, "圣光闪现")
    return true
end
```

### `Skippy.GetLowestUnitByAuraState(auraName, hasAura, byPlayerOnly, role, hasRole)`

按光环状态和职责筛选后，获取血量最低的有效队伍成员。

参数：

- `auraName`：光环名称
- `hasAura`：
  - `true`：找有该光环的单位
  - `false`：找没有该光环的单位
  - 不传：默认 `true`
- `byPlayerOnly`：是否只检查玩家施放的光环，默认 `true`
- `role`：职责过滤，不传表示不限
- `hasRole`：是否包含该职责，默认 `true`

返回：

- `unit`
- `healthPercent`
- `aura`：匹配到的光环信息；当 `hasAura == false` 时通常为 `nil`

示例：

```lua
-- 找一个血量最低、没有自己圣洁护盾的友方
local unit, hp = Skippy.GetLowestUnitByAuraState("圣洁护盾", false, true)
if unit and hp < 95 then
    Skippy.updateSpellIndex(unit, "圣洁护盾")
    return true
end
```

```lua
-- 找一个血量最低、没有自己恢复、且不是坦克的友方
local unit, hp = Skippy.GetLowestUnitByAuraState("恢复", false, true, "TANK", false)
return unit and hp < 90
```

### `Skippy.GetLowestUnitWithAnyAuras(auraTable, byPlayerOnly)`

获取拥有列表中任意光环的最低血量有效队伍成员。

参数：

- `auraTable`：光环名称列表
- `byPlayerOnly`：是否只检查玩家施放的光环，默认 `true`

返回：

- `unit`
- `healthPercent`
- `aura`：匹配到的第一个光环信息

示例：

```lua
local unit, hp, aura = Skippy.GetLowestUnitWithAnyAuras({
    "牺牲之手",
    "保护之手",
}, false)

return unit and hp < 60
```

### `Skippy.GetUnitWithdispelName(dispelName)`

查找有效队伍成员中，第一个带有指定可驱散类型负面光环的单位。

参数：

- `dispelName`：驱散类型，如 `"Curse"`、`"Disease"`、`"Magic"`、`"Poison"`；空字符串 `""` 表示激怒效果

返回：

- `unit` 或 `nil`

示例：

```lua
local unit = Skippy.GetUnitWithdispelName("Magic")
if unit then
    Skippy.updateSpellIndex(unit, "清洁术")
    return true
end
```

## 敌人数量统计

### `Skippy.GetEnemyCount(range)`

统计指定范围内可攻击敌人的数量。

参数：

- `range`：距离范围，例如 `8`、`10`、`30`

返回：

- `number`

示例：

```lua
-- 8 码内敌人数量不少于 3
return Skippy.GetEnemyCount(8) >= 3
```

### `Skippy.GetEnemyCountWithCreatureType(range, creatureType)`

统计指定范围内、指定生物类型的敌人数量。

参数：

- `range`：距离范围
- `creatureType`：生物类型，如 `"恶魔"`、`"亡灵"`、`"人型生物"`

返回：

- `number`

示例：

```lua
return Skippy.GetEnemyCountWithCreatureType(30, "亡灵") > 0
```

### `Skippy.GetEnemyCountWithoutAura(range, auraName, hasAura, byPlayerOnly)`

统计指定范围内，符合光环条件的敌人数量。函数名包含 `WithoutAura`，但实际可以通过 `hasAura` 控制查“有”或“没有”。

参数：

- `range`：距离范围
- `auraName`：光环名称
- `hasAura`：
  - `true`：统计有该光环的敌人
  - `false`：统计没有该光环的敌人
  - 不传：默认 `true`
- `byPlayerOnly`：是否只检查玩家施放的光环，默认 `true`

返回：

- `number`

示例：

```lua
-- 30 码内没有自己审判 debuff 的敌人数量
local count = Skippy.GetEnemyCountWithoutAura(30, "审判", false, true)
return count > 0
```

## 常见组合示例

### 低血量治疗

```lua
local unit, hp = Skippy.GetLowestUnit()
if unit and hp < 75 and Skippy.IsUsableSpellOnUnit("圣光闪现", unit) then
    Skippy.updateSpellIndex(unit, "圣光闪现")
    return true
end
```

### 给最低血量且没有 Buff 的目标补 Buff

```lua
local unit, hp = Skippy.GetLowestUnitByAuraState("圣洁护盾", false, true)
if unit and hp < 100 and Skippy.IsUsableSpellOnUnit("圣洁护盾", unit) then
    Skippy.updateSpellIndex(unit, "圣洁护盾")
    return true
end
```

### 群体治疗判断

```lua
local injured = Skippy.GetGroupCount(85)
if injured >= 3 and Skippy.IsUsableSpell("圣光普照") then
    Skippy.updateSpellIndex("target", "圣光普照")
    return true
end
```

### 驱散判断

```lua
local unit = Skippy.GetUnitWithdispelName("Magic")
if unit and Skippy.IsUsableSpellOnUnit("清洁术", unit) then
    Skippy.updateSpellIndex(unit, "清洁术")
    return true
end
```

## 不建议手动调用的更新函数

以下函数主要由事件系统或初始化流程调用，一般不需要在普通技能逻辑中手动调用：

- `Skippy.GetSpellBookInfo`
- `Skippy.GetGlyphInfo`
- `Skippy.GetCharacterTalentInfo`
- `Skippy.GetUnitInfo`
- `Skippy.GetFullHealth`
- `Skippy.UpdateHealth`
- `Skippy.UpdatePower`
- `Skippy.UpdateAuraInfo`
- `Skippy.UpdateAuraFull`
- `Skippy.UpdateCastingInfo`
- `Skippy.UpdateChannelingInfo`
- `Skippy.UpdateGroupUnit`
- `Skippy.UpdateUnitInfo`
- `Skippy.UpdateAllTotem`
- `Skippy.UpdateTotem`
- `Skippy.UpdateShapeshiftForm`

只有在明确知道缓存数据需要立即刷新时，才建议手动调用这些函数。

## 调试建议

可以在 WeakAuras 自定义代码里临时打印返回值：

```lua
local unit, hp = Skippy.GetLowestUnit()
print("lowest", unit, hp)
```

调试宏索引：

```lua
local unit, hp = Skippy.GetLowestUnit()
Skippy.updateSpellIndex(unit, "圣光术")
print("index", Skippy.index, unit, hp)
return true
```

调试光环：

```lua
local aura = Skippy.GetPlayerAuraByName("圣盾术", false)
if aura then
    print(aura.name, aura.spellId, aura.sourceUnit)
end
```
