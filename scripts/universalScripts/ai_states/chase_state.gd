class_name ChaseState
extends AIState

## 追击状态：走向最近的敌人，直到进入攻击范围切换到攻击状态；
## 敌人死亡/消失则回到漫游

@export_group("NPC 端")

@export var chase_speed: float = 120.0


func physics_update(_delta: float) -> void:
	var target := find_nearest_enemy()
	if target == null:
		machine.change_state(machine.roam_state)
		return
	# 已进入攻击范围 → 攻击
	if npc.global_position.distance_to(target.global_position) <= machine.attack_range:
		machine.change_state(machine.attack_state)
		return
	# 朝敌人移动
	var dir := (target.global_position - npc.global_position).normalized()
	npc.velocity = dir * chase_speed
	npc.move_and_slide()
	play_move_animation(dir)
