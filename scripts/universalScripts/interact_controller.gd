extends Node
class_name InteractController

## 交互控制器：检测交互范围内的可交互目标，按 E 键打开/关闭互动选项 UI
## 选择逻辑后续实现

var player: Character
var interaction_area: Area2D
var interaction_ui: InteractionUI
var shop_ui: ShopUI
## 当前打开选项 UI 的目标 NPC（关闭 UI 时需解除其交互冻结）
var _interacting_target: Character = null
## 当前交易中的店主（商店关闭时需解除其交互冻结）
var _shop_target: Character = null


func _ready() -> void:
	# 引用在 _ready 中获取（@onready 阶段 player group 可能还未就绪）
	player = get_tree().get_first_node_in_group("player") as Character
	interaction_area = get_node_or_null("../../InteractionArea") as Area2D
	# InteractionUI 的 _ready（add_to_group）晚于本节点，延迟一帧再获取 UI 引用
	call_deferred("_setup_ui")


func _setup_ui() -> void:
	interaction_ui = get_tree().get_first_node_in_group("interaction_ui") as InteractionUI
	if interaction_ui:
		interaction_ui.option_chosen.connect(_on_option_chosen)
	shop_ui = get_tree().get_first_node_in_group("shop_ui") as ShopUI


func _physics_process(_delta: float) -> void:
	# UI 打开期间：玩家离开交互范围（找不到可交互目标）时自动关闭
	if interaction_ui and interaction_ui.visible and _find_nearest_interactable() == null:
		_close_options()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		# 商店打开时按 E 先关闭商店（不再触发交互选项）
		if shop_ui and shop_ui.is_open:
			_close_shop()
			get_viewport().set_input_as_handled()
			return
		_toggle_options()
		get_viewport().set_input_as_handled()


## 按 E：已打开则关闭；否则找最近的可交互目标并打开其选项
func _toggle_options() -> void:
	if interaction_ui == null:
		return
	if interaction_ui.visible:
		_close_options()
		return
	var target := _find_nearest_interactable()
	if target:
		_interacting_target = target
		target.is_interacting = true
		interaction_ui.show_options(target, _extra_interactions())


## 关闭选项 UI 并解除目标 NPC 的交互冻结（恢复其 AI 自主行为）
func _close_options() -> void:
	if _interacting_target:
		_interacting_target.is_interacting = false
		_interacting_target = null
	interaction_ui.hide_options()


## 玩家点击了某个互动选项：先关选项，再按类型执行对应行为
func _on_option_chosen(interaction: GameConfig.Interaction) -> void:
	var target := _interacting_target
	_close_options()
	match interaction:
		GameConfig.Interaction.TRADE:
			# 商店：交易期间双方冻结（店主 is_interacting，玩家由 move.gd 按商店状态冻结）
			if shop_ui and target:
				_shop_target = target
				target.is_interacting = true
				shop_ui.open_shop(target)
		GameConfig.Interaction.INSULT:
			# 侮辱：转发给玩家的交互型技能（troll 的 InsultSkill）
			var skill_controller := player.get_node_or_null("SkillController") as SkillController
			if skill_controller:
				skill_controller.try_interaction(interaction, target)
		_:
			pass  # TALK/INSPECT 等后续实现


## 玩家交互型技能附加的额外选项（如 troll 的侮辱）
func _extra_interactions() -> Array[GameConfig.Interaction]:
	if player == null:
		return []
	var skill_controller := player.get_node_or_null("SkillController") as SkillController
	if skill_controller:
		return skill_controller.get_interaction_options()
	return []


## 关闭商店并解除店主的交互冻结（恢复其 AI 自主行为）
func _close_shop() -> void:
	if _shop_target:
		_shop_target.is_interacting = false
		_shop_target = null
	shop_ui.close_shop()


## 在交互范围内找最近的可交互角色（有 interactions 且存活）
func _find_nearest_interactable() -> Character:
	if player == null or interaction_area == null:
		return null
	var nearest: Character = null
	var nearest_dist := INF
	for body in interaction_area.get_overlapping_bodies():
		if not (body is Character):
			continue
		var candidate := body as Character
		if candidate.is_dead or candidate.interactions.is_empty():
			continue
		var dist := player.global_position.distance_squared_to(candidate.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = candidate
	return nearest
