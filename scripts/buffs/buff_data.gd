class_name BuffData
extends Resource

## Buff 静态定义：描述一种效果（属性/数值/时长/层数），可在 Inspector 中配置或代码创建
## 运行时由 BuffController 施加为 BuffInstance
## 使用示例：
##   var data := BuffData.new()
##   data.id = &"berserk"
##   data.type = BuffData.BuffType.ATTACK
##   data.value = 10.0
##   data.duration = 5.0
##   character.apply_buff(data)

enum BuffType {
	ATTACK,           # 攻击力 ±value（按层叠加）
	DEFENSE,          # 防御 ±value（按层叠加）
	MOVE_SPEED,       # 移动速度 ±value（按层叠加）
	HP_REGEN,         # 每秒恢复 value 点生命（按层）
	DAMAGE_OVER_TIME, # 每秒受到 value 点伤害（按层，中毒/燃烧）
}

@export var id: StringName = &"buff"          # 唯一标识：同 id 施加时刷新时间并叠层
@export var display_name: String = "Buff"     # UI 显示名（未来 buff 图标栏用）
@export var type: BuffType = BuffType.ATTACK  # 效果类型
@export var duration: float = 5.0             # 持续时间（秒）；0 = 永久，直到被移除
@export var value: float = 10.0               # 效果数值
@export var max_stacks: int = 1               # 最大叠加层数
