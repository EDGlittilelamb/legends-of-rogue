class_name DashSkill
extends Skill

## 示例技能：朝瞄准方向冲刺一段距离（原型实现：Tween 直接位移，无视碰撞）

@export var dash_distance := 60.0
@export var dash_duration := 0.15


func _cast(aim_direction: Vector2) -> void:
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.RIGHT
	var target := character.global_position + aim_direction.normalized() * dash_distance
	var tween := character.create_tween()
	tween.tween_property(character, "global_position", target, dash_duration)
