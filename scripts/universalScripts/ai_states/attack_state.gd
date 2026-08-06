class_name AttackState
extends AIState

## 攻击状态：攻击攻击范围内的敌人（武器射击或空手近战），持续攻击直到目标离开范围或消失

@export_group("NPC 端")

## 空手近战攻击间隔（秒）
@export var melee_interval: float = 0.8

var _melee_cooldown := 0.0


func enter() -> void:
	npc.is_attacking = true
	_melee_cooldown = 0.0


func exit() -> void:
	npc.is_attacking = false


func physics_update(delta: float) -> void:
	_melee_cooldown = maxf(0.0, _melee_cooldown - delta)
	var target := find_nearest_enemy()
	if target == null:
		machine.change_state(machine.roam_state)
		return
	# 敌人离开攻击范围 → 追击
	if npc.global_position.distance_to(target.global_position) > machine.attack_range:
		machine.change_state(machine.chase_state)
		return
	# 攻击：武器自带冷却控制攻击频率
	var dir := (target.global_position - npc.global_position).normalized()
	if npc.current_weapon:
		npc.current_weapon.attack(dir, npc)
	elif _melee_cooldown <= 0.0:
		_melee_cooldown = melee_interval
		target.take_damage(npc.attack, npc)
