extends Node

@export_group("玩家端")

@export var move_speed: float = 120.0

const IDLE_DOWN := "idle_down"
const IDLE_LEFT := "idle_left"
const IDLE_RIGHT := "idle_right"
const IDLE_UP := "idle_up"
const MOVE_DOWN := "move_down"
const MOVE_LEFT := "move_left"
const MOVE_RIGHT := "move_right"
const MOVE_UP := "move_up"

var player: CharacterBody2D
var animated_sprite: AnimatedSprite2D

var _last_direction: Vector2 = Vector2.DOWN
## 交互选项 UI 引用（UI 打开时冻结玩家移动）
var _interaction_ui: InteractionUI


func _ready() -> void:
	# 在 _ready 中获取玩家引用（@onready 阶段 player group 可能还未就绪）
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player:
		animated_sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	# InteractionUI 的 _ready 晚于本节点，延迟一帧获取
	call_deferred("_setup_ui")


func _setup_ui() -> void:
	_interaction_ui = get_tree().get_first_node_in_group("interaction_ui") as InteractionUI


func _physics_process(_delta: float) -> void:
	# 纯 AI 场景中可能没有玩家角色
	if player == null:
		return
	# 死亡后不再移动
	if player.get("is_dead"):
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# 交互选项 UI 打开时冻结移动（输入置零，动画自然回到 idle）
	if _interaction_ui and _interaction_ui.visible:
		input_direction = Vector2.ZERO

	player.velocity = input_direction * move_speed
	player.move_and_slide()

	# 空手拳击动画播放期间，不覆盖角色的攻击动画（移动逻辑不受影响）
	if player.get("is_punching"):
		return

	if input_direction != Vector2.ZERO:
		_last_direction = input_direction.normalized()
		_play_move_animation(_last_direction)
	else:
		_play_idle_animation(_last_direction)


func _play_move_animation(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			animated_sprite.play(MOVE_RIGHT)
		else:
			animated_sprite.play(MOVE_LEFT)
	else:
		if direction.y > 0.0:
			animated_sprite.play(MOVE_DOWN)
		else:
			animated_sprite.play(MOVE_UP)


func _play_idle_animation(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			animated_sprite.play(IDLE_RIGHT)
		else:
			animated_sprite.play(IDLE_LEFT)
	else:
		if direction.y > 0.0:
			animated_sprite.play(IDLE_DOWN)
		else:
			animated_sprite.play(IDLE_UP)
