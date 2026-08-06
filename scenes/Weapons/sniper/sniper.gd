extends Weapon
class_name Sniper

## 狙击枪：单发高伤子弹

func _fire(_direction: Vector2, attacker: Character) -> void:
	var fire_dir := _get_fire_direction()
	var damage := weapon_damage if weapon_damage > 0 else attacker.attack
	_spawn_bullet(fire_dir, damage, attacker)
