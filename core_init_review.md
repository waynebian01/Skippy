# core_init.lua 优化与风险清单

本文档记录 `core_init.lua` 的代码审查项和当前处理状态。目标是在不改变 WeakAuras 光环功能的前提下，减少重复逻辑并修复明显风险。

## 当前状态

已按选择完成以下项目：

- 2. 玩家完整光环刷新同步到 `Skippy.State.auras`
- 3. 平均血量函数字段修正
- 4. 初始治疗吸收盾字段修正
- 6. 合并重复光环查询函数
- 7. 抽出光环来源匹配判断
- 8. 抽出职责过滤逻辑
- 9. 抽出最低血量单位查找框架
- 12. `shapeshiftFormID` 随形态更新同步刷新

仍未处理或需要确认：

- 5. 施法目标查找只覆盖第一层单位
- 10. `UnitCreatureType` 可能无法取得 `creatureID`
- 11. `UI_ERROR_MESSAGE` 视野逻辑可能没有生效

第 1 项原先提到的 `playerAuras` 旧引用问题，当前代码已经移除了 `playerAuras` 局部变量，增量光环更新会直接写入 `Skippy.State.auras`。

## 已处理项目

### 2. 玩家完整光环刷新同步到 `Skippy.State.auras`

位置：

- `core_init.lua:529`

原问题：

`Skippy.UpdateAuraFull("player")` 只更新单位对象的 `obj.auras`，没有同步到 `Skippy.State.auras`。依赖 `Skippy.State.auras` 的玩家光环查询可能拿到旧数据。

处理结果：

当 `unit == "player"` 时，`UpdateAuraFull` 会清空并复用 `Skippy.State.auras`，同时让 `obj.auras` 指向同一张表。这样完整刷新和增量更新都维护同一份玩家光环数据。

### 3. 平均血量函数字段修正

位置：

- `core_init.lua:1352`

原问题：

`Skippy.GetGroupAverageHealthPct()` 使用了不存在的字段：

```lua
data.health
data.maxHealth
```

实际血量字段存放在：

```lua
data.healthInfo.health
data.healthInfo.healthMax
```

处理结果：

函数现在读取 `data.healthInfo.health` 和 `data.healthInfo.healthMax`，并在 `totalMaxHealth == 0` 时返回 `0`，避免除以 0。

### 4. 初始治疗吸收盾字段修正

位置：

- `core_init.lua:504`

原问题：

完整血量初始化时，`healAbsorbs` 使用了 `UnitGetIncomingHeals(unit)`，和事件更新中的 `UnitGetTotalHealAbsorbs` 不一致。

处理结果：

初始化已改为：

```lua
healAbsorbs = UnitGetTotalHealAbsorbs(unit)
```

### 6. 合并重复的光环查询函数

位置：

- `core_init.lua:1214`
- `core_init.lua:1225`
- `core_init.lua:1241`
- `core_init.lua:1249`

原问题：

`getUnitAuraByName`、`getGroupUnitAuraByName`、`getUnitAuraBySpellId` 存在大量重复逻辑。

处理结果：

新增通用内部函数：

```lua
local function getAuraOwner(unit)
local function getUnitAura(unit, key, value, byPlayerOnly)
```

`getUnitAuraByName` 和 `getUnitAuraBySpellId` 现在都复用 `getUnitAura`。`getGroupUnitAuraByName` 已移除。

### 7. 抽出光环来源匹配判断

位置：

- `core_init.lua:1221`

原问题：

`aura.sourceUnit == "player"` 和 `byPlayerOnly` 判断在多个函数中重复。

处理结果：

新增内部函数：

```lua
local function isAuraFromPlayer(aura, byPlayerOnly)
    return not byPlayerOnly or aura.sourceUnit == "player"
end
```

按名称、按 ID、按光环列表查询时都会复用这个判断。

### 8. 抽出职责过滤逻辑

位置：

- `core_init.lua:1264`
- `core_init.lua:1268`

原问题：

`role`、`hasRole` 的默认值和匹配逻辑在 `GetGroupCountByAuraState`、`GetLowestUnitByAuraState` 中重复。

处理结果：

新增内部函数：

```lua
local function normalizeRole(role)
local function matchRole(data, role, hasRole)
```

相关函数现在统一使用 `matchRole` 判断职责条件。

### 9. 抽出最低血量单位查找框架

位置：

- `core_init.lua:1275`

原问题：

多个函数都在遍历 `Skippy.Units.Group`，过滤有效单位，再比较 `healthPercent`，只有筛选条件不同。

处理结果：

新增内部函数：

```lua
local function findLowestGroupUnit(predicate)
```

以下函数已迁移到该通用框架：

- `Skippy.GetLowestUnit`
- `Skippy.GetLowestUnitWithoutUnit`
- `Skippy.GetLowestUnitWithRoles`
- `Skippy.GetLowestUnitByAuraState`
- `Skippy.GetLowestUnitWithAnyAuras`

### 12. `shapeshiftFormID` 随形态更新同步刷新

位置：

- `core_init.lua:847`

原问题：

`Skippy.State.shapeshiftFormID` 只在初始化时赋值，形态切换后可能仍然是旧值，影响 `catStealth` 等判断。

处理结果：

`Skippy.UpdateShapeshiftForm()` 开头现在会执行：

```lua
Skippy.State.shapeshiftFormID = GetShapeshiftFormID() or 0
```

## 待处理项目

### 5. 施法目标只查到第一层单位

位置：

- `core_init.lua:748`
- `core_init.lua:762`
- `core_init.lua:856`

问题：

`Skippy.UpdatePlayerCastTarget` 只遍历 `Skippy.Units` 第一层，因此能查到 `target`、`focus`，但查不到 `Group`、`Boss`、`Nameplate` 中的单位。

后续逻辑也使用：

```lua
Skippy.Units[castTarget]
```

这同样无法访问嵌套单位。

建议：

统一使用现有的 `GetUnitObj(unit)` 获取单位对象。查找施法目标时应遍历 `target`、`focus`、`Group`、`Boss`、`Nameplate`。

### 10. `UnitCreatureType` 可能取不到 `creatureID`

位置：

- `core_init.lua:561`
- `core_init.lua:1379`

问题：

当前代码写法：

```lua
local creatureType, creatureID = UnitCreatureType(unit)
```

但 `UnitCreatureType(unit)` 通常返回生物类型文本，不返回 NPC ID。这样 `creatureID` 大概率一直是 `0`，导致下面的过滤失效：

```lua
data.creatureID ~= 11
```

建议：

如果目的是过滤图腾或特定 NPC，应确认目标规则。可考虑从 `UnitGUID(unit)` 中解析 NPC ID，或使用更适合的 WoW API 判断。

### 11. `UI_ERROR_MESSAGE` 视野逻辑可能没有生效

位置：

- `core_init.lua:853`
- `core_init.lua:1105`

问题：

事件中调用：

```lua
Skippy.updateGroupInsight()
```

但函数开头是：

```lua
if unit ~= "player" then return end
```

因为没有传入 `unit`，这里会直接返回，导致“目标不在视野中”的处理不生效。

建议：

确认该函数到底应由 `UNIT_SPELLCAST_FAILED` 触发，还是也应由 `UI_ERROR_MESSAGE` 触发。如果两者都需要，建议让函数支持无参数调用，或在事件中传入 `"player"`。

## 验证记录

本地环境没有 `lua`、`luac` 或 `luajit` 命令，因此暂未做 Lua 编译检查。

已做的静态检查：

- 搜索确认 `playerAuras` 旧引用已移除
- 搜索确认 `getGroupUnitAuraByName` 已移除
- 搜索确认 `data.health`、`data.maxHealth` 错误字段已不再用于平均血量
- 搜索确认 `healAbsorbs` 初始化已改为 `UnitGetTotalHealAbsorbs`

## 后续建议

下一步优先处理第 5 和第 11 项，因为它们可能影响施法失败、插入技能和视野判断。第 10 项需要先确认 `creatureID ~= 11` 的真实意图，再决定是否从 `UnitGUID` 解析 NPC ID。
