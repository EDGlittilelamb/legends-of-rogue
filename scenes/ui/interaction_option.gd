extends PanelContainer
class_name InteractionOption

## 交互选项框：长方形面板 + 选项名称（如"对话"、"交易"）
## 由 InteractionUI 实例化并设置文本；选择逻辑后续实现

@onready var label: Label = $Label


## 设置选项显示文本
func set_option_text(text: String) -> void:
	label.text = text
