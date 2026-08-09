class_name BuffInstance
extends RefCounted

## 运行时 Buff 实例：BuffData 定义 + 剩余时间 + 层数 + 来源
## 由 BuffController 创建与销毁，外部只读

var data: BuffData
var remaining: float
var stacks: int
var source: Node
## 持续效果（回血/中毒）的按秒结算累计器
var tick_accum := 0.0


func _init(p_data: BuffData, p_stacks: int, p_source: Node) -> void:
	data = p_data
	stacks = clampi(p_stacks, 1, p_data.max_stacks)
	remaining = p_data.duration
	source = p_source
