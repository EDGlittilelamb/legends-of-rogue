class_name AIState
extends Node

## NPC 状态基类：作为状态机（AIController）的子节点，由状态机注入 npc/machine
## 子类实现 enter / exit / physics_update

const IDLE_DOWN := "idle_down"
const IDLE_LEFT := "idle_left"
const IDLE_RIGHT := "idle_right"
const IDLE_UP := "idle_up"
const MOVE_DOWN := "move_down"
const MOVE_LEFT := "move_left"
const MOVE_RIGHT := "move_right"
const MOVE_UP := "move_up"

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
	if absf(direction.x) > absf(direction.y):
		animated_sprite.play(MOVE_RIGHT if direction.x > 0.0 else MOVE_LEFT)
	else:
		animated_sprite.play(MOVE_DOWN if direction.y > 0.0 else MOVE_UP)


func play_idle_animation(direction: Vector2) -> void:
	if animated_sprite == null:
		return
	if absf(direction.x) > absf(direction.y):
		animated_sprite.play(IDLE_RIGHT if direction.x > 0.0 else IDLE_LEFT)
	else:
		animated_sprite.play(IDLE_DOWN if direction.y > 0.0 else IDLE_UP)
