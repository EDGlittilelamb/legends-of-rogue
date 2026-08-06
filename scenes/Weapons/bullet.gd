extends Area2D
class_name Bullet

## 子弹飞行存活时间（秒）
@export var lifetime: float = 2.0

var direction := Vector2.RIGHT
var speed := 600.0
var damage := 1
var attacker: Node2D
## 每秒缩放增量；> 0 时子弹随飞行距离逐渐变大（scale 线性增长）
var grow_rate := 0.0


## 发射时由武器调用，把方向/速度/伤害/攻击者传给子弹
func setup(move_direction: Vector2, move_speed: float, hit_damage: int, shooter: Node2D, p_grow_rate: float = 0.0) -> void:
	direction = move_direction
	speed = move_speed
	damage = hit_damage
	attacker = shooter
	grow_rate = p_grow_rate


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if grow_rate > 0.0:
		scale += Vector2.ONE * grow_rate * delta


func _on_body_entered(body: Node2D) -> void:
	_resolve_hit(body)


func _on_area_entered(area: Area2D) -> void:
	_resolve_hit(area)


## 命中结算：只有命中有效目标（有 take_damage 方法）才结算伤害并销毁；
## 碰到其他子弹/非目标物体时继续飞行
## 敌我过滤：攻击者有明确敌人列表（enemies）时只伤害列表中的目标，避免误伤中立/友军；
## 攻击者没有敌人列表（如玩家）时伤害除自己外的任何目标
func _resolve_hit(target: Node2D) -> void:
	if target == attacker:
		return
	if attacker is Character:
		var char_attacker := attacker as Character
		if not char_attacker.enemies.is_empty() and not char_attacker.is_enemy(target as Character):
			return
	if target.has_method("take_damage"):
		var final_damage := maxi(1, damage - _target_defense(target))
		target.take_damage(final_damage, attacker)
		queue_free()


func _target_defense(target: Node2D) -> int:
	if "defense" in target:
		return int(target.defense)
	return 0


func _on_lifetime_timeout() -> void:
	if not is_queued_for_deletion():
		queue_free()
