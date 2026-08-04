extends Weapon
class_name Pistol

## 手枪：单发子弹，子弹会随飞行距离逐渐变大

## 子弹每秒的缩放增量（scale 每秒增加这么多）
@export var grow_rate: float = 3.0


func _init() -> void:
	fire_interval = 0.4


func _fire(_direction: Vector2, attacker: Player) -> void:
	var fire_dir := _get_fire_direction()
	var damage := weapon_damage if weapon_damage > 0 else attacker.attack
	_spawn_bullet(fire_dir, damage, attacker, grow_rate)
