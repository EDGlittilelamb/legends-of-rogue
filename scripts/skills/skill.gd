class_name Skill
extends Node

## 技能基类：具体技能继承并覆写 _cast（如冲刺、火球）
## 由 SkillController 实例化并注入持有者（character）
## 内置冷却：try_cast 在冷却中/施放中返回 false；无消耗资源

@export var skill_name: String = "Skill"
@export var cooldown: float = 3.0

## 技能持有者（SkillController 注入）
var character: Character
## 施放中（子类可在持续技能中置位，期间不可重复施放）
var is_casting := false

var _cd_remaining := 0.0


## 注入持有者（SkillController 在 add_child 后调用）
func setup(p_character: Character) -> void:
	character = p_character


## 尝试施放：冷却中或施放中返回 false；成功则执行 _cast 并进入冷却
func try_cast(aim_direction: Vector2) -> bool:
	if character == null or is_casting or _cd_remaining > 0.0:
		return false
	_cast(aim_direction)
	if cooldown > 0.0:
		_cd_remaining = cooldown
	return true


## 当前是否处于冷却
func is_on_cooldown() -> bool:
	return _cd_remaining > 0.0


## 冷却剩余比例（0~1，未来 UI 用）
func cooldown_ratio() -> float:
	if cooldown <= 0.0:
		return 0.0
	return clampf(_cd_remaining / cooldown, 0.0, 1.0)


func _process(delta: float) -> void:
	if _cd_remaining > 0.0:
		_cd_remaining = maxf(0.0, _cd_remaining - delta)


## 子类覆写：技能的实际效果（aim_direction 为瞄准方向，已归一化）
func _cast(_aim_direction: Vector2) -> void:
	pass
