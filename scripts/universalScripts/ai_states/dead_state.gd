class_name DeadState
extends AIState

## 死亡状态：最终态。尸体停留场景中（死亡动画与掉落由 Character._die 处理）

func enter() -> void:
	npc.is_attacking = false
	npc.velocity = Vector2.ZERO


func physics_update(_delta: float) -> void:
	pass
