class_name SkillController
extends Node

## 技能控制器：持有角色的技能实例，玩家右键或 AI 按条件触发
## 差异化入口：character.skill_scene（根节点 Inspector 配置），不同角色配不同技能场景
## 挂载在 character.tscn 根下（与 PlayerController/AIController 平级），玩家与 AI 共用

@export var skill_scene: PackedScene

## 当前技能实例（未配置技能时为 null）
var skill: Skill
## 所属角色（沿父链查找，_ready 时解析）
var character: Character


func _ready() -> void:
	character = _find_character()
	_setup_skill()


## 实例化技能：优先用角色根节点配置的 skill_scene，其次用本节点配置
func _setup_skill() -> void:
	var scene := character.skill_scene if character and character.skill_scene else skill_scene
	if scene == null:
		return
	skill = scene.instantiate() as Skill
	add_child(skill)
	skill.setup(character)


func _unhandled_input(event: InputEvent) -> void:
	# 仅玩家操控的角色响应鼠标右键（AI 角色的技能由 AI 状态机触发）
	if character == null or character.ai_controlled:
		return
	# 交互型技能（如侮辱）不走右键，改由交互选项触发
	if skill and skill.interaction_option != GameConfig.Interaction.NONE:
		return
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		try_cast()
		get_viewport().set_input_as_handled()


## 施放技能：无技能或冷却中返回 false；aim_direction 为空时自动朝鼠标方向
func try_cast(aim_direction: Vector2 = Vector2.ZERO) -> bool:
	if skill == null or character == null:
		return false
	if aim_direction == Vector2.ZERO:
		aim_direction = (character.get_global_mouse_position() - character.global_position).normalized()
	return skill.try_cast(aim_direction)


## 交互型技能提供的额外互动选项（如侮辱）；无则返回空数组
func get_interaction_options() -> Array[GameConfig.Interaction]:
	var options: Array[GameConfig.Interaction] = []
	if skill and skill.interaction_option != GameConfig.Interaction.NONE:
		options.append(skill.interaction_option)
	return options


## 玩家点击交互选项时转发给技能（仅当选项属于本技能）；返回 true 表示已处理
func try_interaction(interaction: GameConfig.Interaction, target: Character) -> bool:
	if skill == null or skill.interaction_option != interaction:
		return false
	return skill.perform_interaction(target)


func _find_character() -> Character:
	var node := get_parent()
	while node:
		if node is Character:
			return node as Character
		node = node.get_parent()
	return null
