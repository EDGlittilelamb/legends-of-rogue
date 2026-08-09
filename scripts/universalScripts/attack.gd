extends Node
class_name AttackController

## 攻击组件：负责监听左键、分发武器/空手攻击、播放攻击动画
## 与 MoveController 对称，挂载在角色根节点下；数据从根节点（Player）读取

const PUNCH_LEFT := "punch_left"
const PUNCH_RIGHT := "punch_right"
const PUNCH_UP := "punch_up"
const PUNCH_DOWN := "punch_down"

var player: Character
var animated_sprite: AnimatedSprite2D
## 交互选项 UI 引用（打开时禁止攻击，点击用于操作 UI）
var _interaction_ui: InteractionUI
## 商店 UI 引用（打开时禁止攻击）
var _shop_ui: ShopUI


func _ready() -> void:
	# 在 _ready 中获取玩家引用（@onready 阶段 player group 可能还未就绪）
	player = get_tree().get_first_node_in_group("player") as Character
	if player:
		animated_sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	# UI 的 _ready 晚于本节点，延迟一帧获取
	call_deferred("_setup_ui")


func _setup_ui() -> void:
	_interaction_ui = get_tree().get_first_node_in_group("interaction_ui") as InteractionUI
	_shop_ui = get_tree().get_first_node_in_group("shop_ui") as ShopUI


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		try_attack()


## 发起攻击：有武器交给武器实现，空手走拳击
func try_attack() -> void:
	if player == null or player.is_dead:
		return
	# 交互选项/商店 UI 打开时不攻击（此时点击用于操作 UI）
	if (_interaction_ui and _interaction_ui.visible) or (_shop_ui and _shop_ui.is_open):
		return
	var aim_direction := (player.get_global_mouse_position() - player.global_position).normalized()
	if player.current_weapon:
		player.current_weapon.attack(aim_direction, player)
	else:
		_fist_attack(aim_direction)


## 空手时的拳击：在鼠标方向前方一定范围内寻找敌人，并按朝向播放拳击动画
func _fist_attack(direction: Vector2) -> void:
	_play_punch_animation(direction)
	var space_state := player.get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 26.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, player.global_position + direction * 20.0)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	for hit in space_state.intersect_shape(query, 8):
		var target: Node2D = hit.collider
		if target == player:
			continue
		if target.has_method("take_damage"):
			target.take_damage(player.attack, player)
			break


## 根据攻击方向选择拳击动画，播放完后自动结束（move.gd 恢复动画控制）
func _play_punch_animation(direction: Vector2) -> void:
	player.is_punching = true
	var anim := _punch_animation_for(direction)
	animated_sprite.play(anim)
	var frames := animated_sprite.sprite_frames.get_frame_count(anim)
	var speed := animated_sprite.sprite_frames.get_animation_speed(anim)
	var duration := frames / speed if speed > 0.0 else 0.1
	get_tree().create_timer(duration).timeout.connect(_on_punch_animation_finished)


func _on_punch_animation_finished() -> void:
	if is_inside_tree():
		player.is_punching = false


func _punch_animation_for(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return PUNCH_RIGHT if direction.x > 0.0 else PUNCH_LEFT
	return PUNCH_DOWN if direction.y > 0.0 else PUNCH_UP
