class_name BuffController
extends Node

## Buff 管理器：挂在角色（Character）根下
## 负责施加/刷新/移除 buff，并在 _process 中结算持续效果（DOT/回血）与倒计时
## 属性型 buff（攻击/防御/移速）施加时直接增减目标属性，移除时还原

signal buff_added(buff: BuffInstance)
signal buff_removed(buff: BuffInstance)

## 所属角色（沿父链查找，_ready 时解析）
var character: Character

var _buffs: Array[BuffInstance] = []


func _ready() -> void:
	character = _find_character()


## 施加 buff：同 id 已存在则刷新剩余时间并叠层（不超过 max_stacks）
func apply_buff(data: BuffData, stacks := 1, source: Node = null) -> void:
	if data == null or character == null:
		return
	for buff in _buffs:
		if buff.data.id == data.id:
			buff.remaining = data.duration
			var old_stacks := buff.stacks
			buff.stacks = mini(buff.stacks + stacks, data.max_stacks)
			_apply_stat_change(buff, buff.stacks - old_stacks, true)
			return
	var buff := BuffInstance.new(data, stacks, source)
	_buffs.append(buff)
	_apply_stat_change(buff, buff.stacks, true)
	buff_added.emit(buff)


## 按 id 移除 buff（不存在则无操作）
func remove_buff(id: StringName) -> void:
	for i in _buffs.size():
		if _buffs[i].data.id == id:
			var buff := _buffs[i]
			_buffs.remove_at(i)
			_apply_stat_change(buff, buff.stacks, false)
			buff_removed.emit(buff)
			return


## 是否持有指定 id 的 buff
func has_buff(id: StringName) -> bool:
	for buff in _buffs:
		if buff.data.id == id:
			return true
	return false


## 获取指定 id 的层数（无则 0）
func get_stacks(id: StringName) -> int:
	for buff in _buffs:
		if buff.data.id == id:
			return buff.stacks
	return 0


## 移除全部 buff
func clear_all_buffs() -> void:
	while not _buffs.is_empty():
		var buff := _buffs.pop_back()
		_apply_stat_change(buff, buff.stacks, false)
		buff_removed.emit(buff)


func _process(delta: float) -> void:
	if character == null:
		return
	# 倒序遍历，循环内移除安全
	for i in range(_buffs.size() - 1, -1, -1):
		var buff := _buffs[i]
		_tick_continuous(buff, delta)
		# 倒计时（duration <= 0 为永久 buff）
		if buff.data.duration > 0.0:
			buff.remaining -= delta
			if buff.remaining <= 0.0:
				_buffs.remove_at(i)
				_apply_stat_change(buff, buff.stacks, false)
				buff_removed.emit(buff)


## 持续效果：回血/中毒按秒结算（每秒一跳，避免每帧触发受击反馈）
func _tick_continuous(buff: BuffInstance, delta: float) -> void:
	if buff.data.type != BuffData.BuffType.HP_REGEN and buff.data.type != BuffData.BuffType.DAMAGE_OVER_TIME:
		return
	buff.tick_accum += delta
	while buff.tick_accum >= 1.0:
		buff.tick_accum -= 1.0
		match buff.data.type:
			BuffData.BuffType.HP_REGEN:
				character.hp = mini(character.hp + int(buff.data.value * buff.stacks), character.max_hp)
			BuffData.BuffType.DAMAGE_OVER_TIME:
				character.take_damage(maxi(1, int(buff.data.value * buff.stacks)), buff.source)


## 属性增减：stacks 为本次变化量（施加/移除/叠层差），apply=true 增加、false 还原
func _apply_stat_change(buff: BuffInstance, stacks: int, apply: bool) -> void:
	var sign := 1.0 if apply else -1.0
	var amount := int(buff.data.value * stacks)
	match buff.data.type:
		BuffData.BuffType.ATTACK:
			character.attack += int(sign * amount)
		BuffData.BuffType.DEFENSE:
			character.defense += int(sign * amount)
		BuffData.BuffType.MOVE_SPEED:
			_apply_move_speed(sign * buff.data.value * stacks)


## 移动速度：修改玩家端 MoveController.move_speed（AI 漫游速度如需受 buff 影响，在 roam_state 中读取）
func _apply_move_speed(amount: float) -> void:
	var move_controller := character.get_node_or_null("PlayerController/MoveController")
	if move_controller and "move_speed" in move_controller:
		move_controller.move_speed = maxf(0.0, move_controller.move_speed + amount)


func _find_character() -> Character:
	var node := get_parent()
	while node:
		if node is Character:
			return node as Character
		node = node.get_parent()
	return null
