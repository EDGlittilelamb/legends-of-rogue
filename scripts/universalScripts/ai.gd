extends Node
class_name AIController

## NPC 状态机：管理漫游/追击/攻击/受击/死亡状态
## 状态节点（AIState 子类）挂在本节点下，由本节点统一注册与切换
## 玩家控制时（character.ai_controlled = false）本节点被禁用

@export_group("NPC 端")

## 攻击范围半径（像素）：Chase/Attack 状态共用的距离判定，也同步到 AttackRange 标注节点
@export var attack_range: float = 48.0

var npc: Character
var current: AIState = null

var roam_state: RoamState
var chase_state: ChaseState
var attack_state: AttackState
var hurt_state: HurtState
var dead_state: DeadState


func _ready() -> void:
	npc = _find_character()
	if npc == null:
		return
	# 注册子状态并注入引用（状态统一放在 States 容器下）
	var states_container := get_node_or_null("States")
	if states_container == null:
		return
	for child in states_container.get_children():
		if child is AIState:
			var state := child as AIState
			state.setup(npc, self)
			_assign_state_ref(state)
	# 同步攻击范围标注（AttackRange 场景节点的圆形形状）
	var range_area := get_node_or_null("AttackRange") as Area2D
	if range_area:
		var shape := range_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape and shape.shape is CircleShape2D:
			(shape.shape as CircleShape2D).radius = attack_range
	# 初始进入漫游
	change_state(roam_state)


func _assign_state_ref(state: AIState) -> void:
	if state is RoamState:
		roam_state = state
	elif state is ChaseState:
		chase_state = state
	elif state is AttackState:
		attack_state = state
	elif state is HurtState:
		hurt_state = state
	elif state is DeadState:
		dead_state = state


func _physics_process(delta: float) -> void:
	if npc == null:
		return
	# 死亡：最终态，任何状态都不再执行
	if npc.is_dead:
		if current != dead_state:
			change_state(dead_state)
		return
	# 受击打断：除死亡外，任何状态受击都切到受击僵直
	if npc.is_hurt and current != hurt_state:
		change_state(hurt_state)
		return
	if current:
		current.physics_update(delta)


func change_state(new_state: AIState) -> void:
	if current == new_state or new_state == null:
		return
	if current:
		current.exit()
	current = new_state
	current.enter()


func _find_character() -> Character:
	var node := get_parent()
	while node:
		if node is Character:
			return node as Character
		node = node.get_parent()
	return null
