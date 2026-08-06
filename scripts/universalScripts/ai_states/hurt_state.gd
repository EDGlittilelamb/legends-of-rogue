class_name HurtState
extends AIState

## 受击状态：受击僵直（等待 is_hurt 复位，由 Character.take_damage 管理 0.4s），
## 僵直结束后按敌人是否存在回到追击或漫游

func enter() -> void:
	npc.velocity = Vector2.ZERO


func physics_update(_delta: float) -> void:
	# 僵直中：不动
	if npc.is_hurt:
		return
	# 僵直结束：有敌人 → 追击；否则 → 漫游
	if find_nearest_enemy() != null:
		machine.change_state(machine.chase_state)
	else:
		machine.change_state(machine.roam_state)
