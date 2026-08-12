extends Node

@export_group("玩家端")

@export var move_speed: float = 120.0

const IDLE_LEFT := "idle_left"
const IDLE_RIGHT := "idle_right"
const MOVE_LEFT := "move_left"
const MOVE_RIGHT := "move_right"

var player: CharacterBody2D
var animated_sprite: AnimatedSprite2D

## 交互选项 UI 引用（UI 打开时冻结玩家移动）
var _interaction_ui: InteractionUI
## 商店 UI 引用（商店打开时同样冻结玩家移动）
var _shop_ui: ShopUI


func _ready() -> void:
	# 在 _ready 中获取玩家引用（@onready 阶段 player group 可能还未就绪）
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player:
		animated_sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	# InteractionUI 的 _ready 晚于本节点，延迟一帧获取
	call_deferred("_setup_ui")


func _setup_ui() -> void:
	_interaction_ui = get_tree().get_first_node_in_group("interaction_ui") as InteractionUI
	_shop_ui = get_tree().get_first_node_in_group("shop_ui") as ShopUI


func _physics_process(_delta: float) -> void:
	# 纯 AI 场景中可能没有玩家角色
	if player == null:
		return
	# 死亡后不再移动
	if player.get("is_dead"):
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# 交互选项/商店 UI 打开时冻结移动（输入置零，动画自然回到 idle）
	if (_interaction_ui and _interaction_ui.visible) or (_shop_ui and _shop_ui.is_open):
		input_direction = Vector2.ZERO

	player.velocity = input_direction * move_speed
	player.move_and_slide()

	# 空手拳击动画播放期间，不覆盖角色的攻击动画（移动逻辑不受影响）
	if player.get("is_punching"):
		return

	if input_direction != Vector2.ZERO:
		# 只有左右动画：水平输入更新朝向，垂直移动沿用当前朝向
		if input_direction.x != 0.0:
			player.facing_right = input_direction.x > 0.0
		_play_move_animation(player.facing_right)
	else:
		_play_idle_animation(player.facing_right)


func _play_move_animation(facing_right: bool) -> void:
	animated_sprite.play(MOVE_RIGHT if facing_right else MOVE_LEFT)


func _play_idle_animation(facing_right: bool) -> void:
	animated_sprite.play(IDLE_RIGHT if facing_right else IDLE_LEFT)
