extends Node2D
class_name InteractionUI

## 交互选项 UI：显示目标角色的互动选项列表（竖排），由 InteractController 触发
## 挂在玩家端 CanvasLayer 下（Node2D），容器（VBoxContainer）由脚本动态创建

const OPTION_SCENE := preload("res://scenes/ui/interaction_option.tscn")

## 玩家选择了某个互动选项（TALK/TRADE 等），InteractController 监听后执行对应行为
signal option_chosen(interaction: GameConfig.Interaction)

var option_container: VBoxContainer
## 跟随的玩家角色（在 _ready 中缓存）
var _player: Character


func _ready() -> void:
	# 注册 group 供 InteractController 查找（场景属性 + 代码双保险）
	add_to_group("interaction_ui")
	_player = get_tree().get_first_node_in_group("player") as Character
	# 创建竖排选项容器（Control 作为本节点子节点，位置跟随 InteractionUI）
	option_container = VBoxContainer.new()
	option_container.name = "OptionContainer"
	option_container.add_theme_constant_override("separation", 4)
	add_child(option_container)
	visible = false


## 显示指定目标的互动选项（清空旧选项后按 interactions 重建）
## extra_options：玩家交互型技能附加的额外选项（如侮辱）
func show_options(target: Character, extra_options: Array = []) -> void:
	_clear_options()
	if target == null or (target.interactions.is_empty() and extra_options.is_empty()):
		visible = false
		return
	# 打开时定位：玩家屏幕位置右侧 10px（UI 打开期间玩家冻结，位置不会变化）
	if _player:
		position = _player.get_global_transform_with_canvas().origin + Vector2(10, 0)
	for interaction in target.interactions:
		_create_option(interaction)
	for interaction in extra_options:
		_create_option(interaction)
	visible = true


func _create_option(interaction: GameConfig.Interaction) -> void:
	var option := OPTION_SCENE.instantiate() as InteractionOption
	# 先加入场景树（触发 @onready 初始化），再设置文本与互动类型
	option_container.add_child(option)
	option.set_option_text(GameConfig.get_interaction_label(interaction))
	option.interaction_type = interaction
	option.option_selected.connect(_on_option_selected)


func _on_option_selected(interaction: GameConfig.Interaction) -> void:
	option_chosen.emit(interaction)


## 隐藏并清空选项
func hide_options() -> void:
	visible = false
	_clear_options()


func _clear_options() -> void:
	for child in option_container.get_children():
		child.queue_free()
