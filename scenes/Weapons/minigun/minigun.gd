extends Weapon
class_name Minigun

## 加特林：每次攻击沿瞄准方向连续射出多颗子弹，形成一条弹线

## 每次攻击射出的子弹数量
@export var bullet_count: int = 5
## 每发子弹之间的间隔（秒）
@export var burst_interval: float = 0.05

var _burst_index := 0


func _init() -> void:
	# 一轮连射总时长 = (bullet_count - 1) * burst_interval，间隔需大于它
	fire_interval = 0.3


func _fire(_direction: Vector2, attacker: Character) -> void:
	_burst_index = 0
	# 固定本轮的发射方向，5 发子弹严格沿同一条直线
	var fire_dir := _get_fire_direction()
	_spawn_burst_shot(fire_dir, attacker)


func _spawn_burst_shot(fire_dir: Vector2, attacker: Character) -> void:
	if not is_inside_tree() or _burst_index >= bullet_count:
		return
	_burst_index += 1
	var damage := weapon_damage if weapon_damage > 0 else attacker.attack
	_spawn_bullet(fire_dir, damage, attacker)
	if _burst_index < bullet_count:
		get_tree().create_timer(burst_interval).timeout.connect(_spawn_burst_shot.bind(fire_dir, attacker))
