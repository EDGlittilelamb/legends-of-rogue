extends Node
class_name InteractController

## 交互控制器：检测交互范围内的可交互目标，按 E 键打开/关闭互动选项 UI
## 选择逻辑后续实现

var player: Character
var interaction_area: Area2D
var interaction_ui: InteractionUI
## 当前打开选项 UI 的目标 NPC（关闭 UI 时需解除其交互冻结）
var _interacting_target: Character = null


func _ready() -> void:
	# 引用在 _ready 中获取（@onready 阶段 player group 可能还未就绪）
	player = get_tree().get_first_node_in_group("player") as Character
	interaction_area = get_node_or_null("../../InteractionArea") as Area2D
	# InteractionUI 的 _ready（add_to_group）晚于本节点，延迟一帧再获取 UI 引用
	call_deferred("_setup_ui")


func _setup_ui() -> void:
	interaction_ui = get_tree().get_first_node_in_group("interaction_ui") as InteractionUI


func _physics_process(_delta: float) -> void:
	# UI 打开期间：玩家离开交互范围（找不到可交互目标）时自动关闭
	if interaction_ui and interaction_ui.visible and _find_nearest_interactable() == null:
		_close_options()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_toggle_options()
		get_viewport().set_input_as_handled()


## 按 E：已打开则关闭；否则找最近的可交互目标并打开其选项
func _toggle_options() -> void:
	if interaction_ui == null:
		return
	if interaction_ui.visible:
		_close_options()
		return
	var target := _find_nearest_interactable()
	if target:
		_interacting_target = target
		target.is_interacting = true
		interaction_ui.show_options(target)


## 关闭选项 UI 并解除目标 NPC 的交互冻结（恢复其 AI 自主行为）
func _close_options() -> void:
	if _interacting_target:
		_interacting_target.is_interacting = false
		_interacting_target = null
	interaction_ui.hide_options()


## 在交互范围内找最近的可交互角色（有 interactions 且存活）
func _find_nearest_interactable() -> Character:
	if player == null or interaction_area == null:
		return null
	var nearest: Character = null
	var nearest_dist := INF
	for body in interaction_area.get_overlapping_bodies():
		if not (body is Character):
			continue
		var candidate := body as Character
		if candidate.is_dead or candidate.interactions.is_empty():
			continue
		var dist := player.global_position.distance_squared_to(candidate.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = candidate
	return nearest
