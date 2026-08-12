class_name InsultSkill
extends Skill

## troll 的侮辱技能：交互型技能（右键不施放），玩家按 E 与目标互动时附加"侮辱"选项
## 判定：成功概率 = (100 - kindness_score) / 100（善良值越低越致命）
## 每次使用 kindness_score -20（下限 0）；使用后附近 100px 的 NPC 记恨玩家

## 记恨范围半径（像素）
const HATER_RADIUS := 100.0
## 每次使用扣除的善良值
const KINDNESS_COST := 20


func _init() -> void:
	interaction_option = GameConfig.Interaction.INSULT


## 点击"侮辱"选项时触发：判定 → 扣善良值 → 附近记恨 → 成功则目标死亡
func perform_interaction(target: Character) -> bool:
	if character == null or target == null:
		return false
	# 判定：善良值越低成功率越高（0 善良必成功，100 善良必失败）
	var success := randf() < (100.0 - character.kindness_score) / 100.0
	# 每次使用都降低善良值（统一入口，会广播 GameRules）
	character.change_kindness(-KINDNESS_COST)
	# 让附近 NPC 记恨玩家（厌恶逻辑后续实现，先填充 haters）
	_add_haters_nearby()
	if success:
		target.take_damage(99999, character)
	return true


## 把玩家加入半径内所有存活 NPC 的 haters（被记恨者）
func _add_haters_nearby() -> void:
	for node in get_tree().get_nodes_in_group("characters"):
		var npc := node as Character
		if npc == character or npc.is_dead:
			continue
		if npc.global_position.distance_to(character.global_position) <= HATER_RADIUS:
			npc.haters.append(character)
