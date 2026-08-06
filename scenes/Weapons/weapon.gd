extends Item
class_name Weapon

## 武器动画约定：所有武器都有 "idle"（默认）和 "attack" 两个动画
const IDLE_ANIM := "idle"
const ATTACK_ANIM := "attack"

## 武器自身造成的伤害；小于等于 0 时使用玩家的攻击力
@export var weapon_damage: int = 0
## 两次攻击的最小间隔（秒）
@export var fire_interval: float = 0.6
## 子弹场景与发射参数（近战武器可忽略）
## 默认使用通用子弹；武器需要特殊子弹时可在 Inspector 里覆盖
@export var bullet_scene: PackedScene = preload("res://scenes/Weapons/bullet.tscn")
@export var bullet_speed: float = 600.0
@export var muzzle_offset: float = 22.0

var _fire_cooldown := 0.0
var _attack_token := 0
## 是否被玩家装备在手上；背包里的武器实例为 false，不会瞄准/旋转
var is_equipped := false
## 是否每帧跟随鼠标瞄准；AI 控制时关闭（攻击瞬间仍按传入方向瞄准）
var aim_follows_mouse := true

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var _holder: Node2D = get_parent() as Node2D
@onready var _holder_offset: Vector2 = _holder.position if _holder else Vector2.ZERO


func _ready() -> void:
	# 默认处于 idle 状态
	if animated_sprite:
		animated_sprite.play(IDLE_ANIM)


func _physics_process(delta: float) -> void:
	# 冷却计时始终递减（AI 模式下 aim_follows_mouse=false 也必须恢复冷却，否则只开一枪）
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if not is_equipped or not aim_follows_mouse:
		return
	_aim_at_mouse()


## 攻击入口：统一处理冷却、瞄准与攻击动画，然后交给子类 _fire 实现
func attack(direction: Vector2, attacker: Character) -> void:
	if _fire_cooldown > 0.0:
		return
	_fire_cooldown = fire_interval
	_aim_at(direction)
	play_attack_animation()
	_fire(direction, attacker)


## 由具体武器实现攻击逻辑
func _fire(direction: Vector2, attacker: Character) -> void:
	pass


## 生成一颗子弹（p_grow_rate > 0 时子弹会随飞行距离逐渐变大）
func _spawn_bullet(fire_dir: Vector2, damage: int, attacker: Character, p_grow_rate: float = 0.0) -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + fire_dir * muzzle_offset
	bullet.setup(fire_dir, bullet_speed, damage, attacker, p_grow_rate)


## 播放攻击动画，播完一整轮后自动回到 idle（攻击动画视为循环动画）
func play_attack_animation() -> void:
	if animated_sprite == null:
		return
	_attack_token += 1
	var token := _attack_token
	animated_sprite.play(ATTACK_ANIM)
	var duration := _attack_animation_duration()
	get_tree().create_timer(duration).timeout.connect(_back_to_idle.bind(token))


func _attack_animation_duration() -> float:
	var frames := animated_sprite.sprite_frames.get_frame_count(ATTACK_ANIM)
	var speed := animated_sprite.sprite_frames.get_animation_speed(ATTACK_ANIM)
	if speed <= 0.0:
		return 0.1
	return frames / speed


func _back_to_idle(token: int) -> void:
	# 期间又攻击了一次则不再切回，避免打断新一轮攻击动画
	if token != _attack_token or not is_inside_tree():
		return
	animated_sprite.play(IDLE_ANIM)


## 枪械朝向跟随鼠标
func _aim_at_mouse() -> void:
	_aim_at(get_global_mouse_position() - global_position)


## 让枪口对准 dir 方向：
## 角度限制在 -90°~90°；目标在左侧时通过 flip_h 镜像枪身（枪口视觉角度 = rotation + 180°），
## 因此翻转时 rotation 取负，保证视觉上枪口正好指向目标
func _aim_at(dir: Vector2) -> void:
	var flip := dir.x < 0.0
	rotation = atan2(dir.y, absf(dir.x))
	if flip:
		rotation = -rotation
	if animated_sprite:
		animated_sprite.flip_h = flip
	# 镜像挂点坐标：枪在玩家左侧时，挂点 x 取反，让枪械整体移到玩家左边
	# （单独预览武器场景时没有挂点，跳过）
	if _holder:
		_holder.position = Vector2(
			_holder_offset.x * (-1.0 if flip else 1.0),
			_holder_offset.y
		)


## 当前枪口的实际朝向（已考虑 flip_h 镜像：翻转时视觉方向 = rotation + 180°）
func _get_fire_direction() -> Vector2:
	var dir := Vector2.RIGHT.rotated(rotation)
	if animated_sprite and animated_sprite.flip_h:
		dir = -dir
	return dir
