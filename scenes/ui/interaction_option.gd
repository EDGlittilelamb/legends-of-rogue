extends PanelContainer
class_name InteractionOption

## 交互选项框：长方形面板 + 选项名称（如"对话"、"交易"）
## 由 InteractionUI 实例化并设置文本；点击后通过 option_selected 上报互动类型

signal option_selected(interaction: GameConfig.Interaction)

## 本选项对应的互动类型（由 InteractionUI 在创建时设置）
var interaction_type: GameConfig.Interaction = GameConfig.Interaction.NONE

@onready var label: Label = $Label


func _ready() -> void:
	gui_input.connect(_on_gui_input)


## 设置选项显示文本
func set_option_text(text: String) -> void:
	label.text = text


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		option_selected.emit(interaction_type)
		accept_event()
