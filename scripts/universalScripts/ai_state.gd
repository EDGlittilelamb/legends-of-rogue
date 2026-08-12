class_name AIState
extends Node

## NPC 状态基类：作为状态机（AIController）的子节点，由状态机注入 npc/machine
## 子类实现 enter / exit / physics_update

const IDLE_LEFT := "idle_left"
const IDLE_RIGHT := "idle_right"
const MOVE_LEFT := "move_left"
const MOVE_RIGHT := "move_right"

var npc: Character
var machine: AIController
var animated_sprite: AnimatedSprite2D


## 由状态机在 _ready 时注入角色与状态机引用
func setup(p_npc: Character, p_machine: AIController) -> void:
	npc = p_npc
	machine = p_machine
	animated_sprite = npc.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(delta: float) -> void:
	pass


## 从角色 enemies 列表找最近的存活敌人（全局感知，不限于攻击范围）
func find_nearest_enemy() -> Character:
	if npc == null:
		return null
	var nearest: Character = null
	var nearest_dist := INF
	for enemy in npc.enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue
		var dist := npc.global_position.distance_squared_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func play_move_animation(direction: Vector2) -> void:
	if animated_sprite == null:
		return
	# 只有左右动画：水平移动更新朝向，垂直移动沿用当前朝向
	if direction.x != 0.0:
		npc.facing_right = direction.x > 0.0
	animated_sprite.play(MOVE_RIGHT if npc.facing_right else MOVE_LEFT)


func play_idle_animation(direction: Vector2) -> void:
	if animated_sprite == null:
		return
	var facing_right := direction.x > 0.0 if direction.x != 0.0 else npc.facing_right
	animated_sprite.play(IDLE_RIGHT if facing_right else IDLE_LEFT)
