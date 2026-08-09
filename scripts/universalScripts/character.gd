extends CharacterBody2D
class_name Character

## 角色数据中枢：保存属性/身份/背包/装备状态与对外接口，
## 行为逻辑由子节点组件负责（玩家：PlayerController；AI：AIController）

## ===== 玩家端 =====
@export_group("玩家端")

## 基础属性
@export var max_hp: int = 100
@export var defense: int = 0
@export var attack: int = 10
@export var money: int = 100
@export var initial_weapon_scene: PackedScene = preload("res://scenes/Weapons/minigun/minigun.tscn")
## 控制模式：true = AI 控制（禁用 PlayerController），false = 玩家控制（禁用 AIController）
@export var ai_controlled := false

## ===== NPC 端 =====
@export_group("NPC 端")

## 角色类型（GameConfig.CharacterType：匪帮/快递员/警察等），在 Inspector 下拉中选择
@export var type: GameConfig.CharacterType = GameConfig.CharacterType.NONE
## 该角色支持的互动选项（对话/交易等），Inspector 中勾选；玩家按 E 时据此生成选项
@export var interactions: Array[GameConfig.Interaction] = []

## 背包初始武器（放入前三个格子）
const STARTING_WEAPONS: Array[PackedScene] = [
	preload("res://scenes/Weapons/sniper/sniper.tscn"),
	preload("res://scenes/Weapons/minigun/minigun.tscn"),
	preload("res://scenes/Weapons/pistol/pistol.tscn"),
]
## NPC（AI 控制）背包格数上限：店主等 NPC 最多持有这么多物品
const NPC_INVENTORY_SIZE := 5

var hp: int
var current_weapon: Weapon
## 背包数据：固定 20 格（4 行 x 5 列），null 表示空格
var inventory: Array[Item] = []
## 背包内容变化时发出（拾取、丢弃等），背包 UI 监听后自动刷新
signal inventory_changed
## 空手拳击动画播放中（move.gd 在此期间不覆盖动画）
var is_punching := false
## 角色已死亡（不再响应移动/攻击/受击）
var is_dead := false
## 攻击中（AI 攻击会打断移动）
var is_attacking := false
## 受击中（受击会打断移动）
var is_hurt := false
## 互动中（预留：E 键交互会打断移动）
var is_interacting := false

## 实例级敌人列表：如店主敌视"进入私密空间的这个玩家"，
## 但不会对玩家所属的角色类型（type）为敌
var enemies: Array[Character] = []

## 死亡动画（测试阶段只播放这一个）
const DIE_ANIM := "die_left"
## 掉落物场景（死亡时掉落背包物品用）
const ITEM_DROP_SCENE := preload("res://scenes/items/item_drop.tscn")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_holder: Node2D = $weapon


func _enter_tree() -> void:
	# 只有玩家操控的角色加入 "player" group（AI 角色不进，避免玩家组件拿错目标）
	if not ai_controlled:
		add_to_group("player")


func _ready() -> void:
	hp = max_hp
	# NPC 背包上限 5 格，玩家 20 格
	inventory.resize(NPC_INVENTORY_SIZE if ai_controlled else 20)
	for i in STARTING_WEAPONS.size():
		inventory[i] = STARTING_WEAPONS[i].instantiate() as Item
	# 初始装备背包第 1 格武器（与默认选中一致）
	if inventory[0] is Weapon:
		equip_from_inventory(0)
	else:
		_equip_weapon(initial_weapon_scene)
	# 按控制模式启用对应控制器（禁用会停掉子树全部处理，含输入/动画/背包 UI）
	if ai_controlled:
		$PlayerController.process_mode = Node.PROCESS_MODE_DISABLED
		$AIController.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		$AIController.process_mode = Node.PROCESS_MODE_DISABLED


func _equip_weapon(weapon_scene: PackedScene) -> void:
	if not weapon_scene:
		return
	if current_weapon:
		current_weapon.queue_free()
	current_weapon = weapon_scene.instantiate() as Weapon
	current_weapon.is_equipped = true
	# AI 控制时武器不跟随鼠标瞄准（攻击瞬间仍按攻击方向瞄准）
	current_weapon.aim_follows_mouse = not ai_controlled
	weapon_holder.add_child(current_weapon)
	current_weapon.position = Vector2.ZERO


## 装备背包指定格子的武器（按其场景克隆新实例，背包数据不变）；
## 格子为空或非武器时卸下当前武器（空手拳击）
func equip_from_inventory(index: int) -> void:
	var item := inventory[index]
	if item is Weapon:
		var weapon := item as Weapon
		if weapon.scene_file_path.is_empty():
			return
		var packed := load(weapon.scene_file_path) as PackedScene
		if packed:
			_equip_weapon(packed)
	else:
		_unequip_weapon()


## 卸下当前武器（回到空手状态）
func _unequip_weapon() -> void:
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null


## 尝试把物品放入背包第一个空格；成功返回 true，背包满返回 false
func add_item_to_inventory(item: Item) -> bool:
	for i in inventory.size():
		if inventory[i] == null:
			inventory[i] = item
			inventory_changed.emit()
			return true
	return false


## 是否视 target 为敌人（实例级判定，与角色类型无关）
func is_enemy(target: Character) -> bool:
	return target in enemies


## 把 target 标记为敌人（如店主因玩家闯入私密空间而敌视该玩家实例）
func add_enemy(target: Character) -> void:
	if target and not enemies.has(target):
		enemies.append(target)


func remove_enemy(target: Character) -> void:
	enemies.erase(target)


## 施加 buff（便捷方法：转发给根下的 BuffController）
func apply_buff(data: BuffData, stacks := 1, source: Node = null) -> void:
	var controller := get_node_or_null("BuffController") as BuffController
	if controller:
		controller.apply_buff(data, stacks, source)


func take_damage(amount: int, attacker: Node2D = null) -> void:
	if is_dead:
		return
	# NPC 端：受到伤害就把攻击者列入敌人（之后会攻击反击）
	if ai_controlled and attacker is Character:
		add_enemy(attacker as Character)
	var final_damage := maxi(1, amount - defense)
	hp -= final_damage
	# 受击视觉反馈：短暂闪红
	modulate = Color(1.0, 0.35, 0.35)
	get_tree().create_timer(0.12).timeout.connect(_on_hit_flash_finished)
	# 受击会打断低优先级的 AI 移动
	is_hurt = true
	get_tree().create_timer(0.4).timeout.connect(_on_hurt_finished)
	if hp <= 0:
		hp = 0
		_die()


func _on_hit_flash_finished() -> void:
	if is_inside_tree():
		modulate = Color.WHITE


func _on_hurt_finished() -> void:
	if is_inside_tree():
		is_hurt = false


## 死亡：掉落背包所有物品，播放死亡动画，播完后停留在最后一帧（尸体留在场景中）
func _die() -> void:
	if is_dead:
		return
	is_dead = true
	# 隐藏尸体手上的武器
	if current_weapon:
		current_weapon.is_equipped = false
		current_weapon.visible = false
	_drop_all_inventory()
	animated_sprite.play(DIE_ANIM)
	var frames := animated_sprite.sprite_frames.get_frame_count(DIE_ANIM)
	var speed := animated_sprite.sprite_frames.get_animation_speed(DIE_ANIM)
	var duration := frames / speed if speed > 0.0 else 0.5
	get_tree().create_timer(duration).timeout.connect(_on_death_animation_finished)


## 把背包中所有物品作为掉落物，从角色中心抛出，均匀散落在角色周围
func _drop_all_inventory() -> void:
	var drops: Array[ItemDrop] = []
	for i in inventory.size():
		var item := inventory[i]
		if item == null:
			continue
		# 从背包 UI 中移除旧实例，避免残留显示
		if item.get_parent():
			item.get_parent().remove_child(item)
		item.queue_free()
		# 生成通用掉落物（初始在角色中心，由抛出动画散开）
		var packed := load(item.scene_file_path) as PackedScene
		if packed:
			var drop := ITEM_DROP_SCENE.instantiate() as ItemDrop
			drop.item_scene = packed
			get_tree().current_scene.add_child(drop)
			drops.append(drop)
		inventory[i] = null
	inventory_changed.emit()
	_throw_drops(drops)


## 掉落物从角色中心向四周抛出：角度均匀分布（带随机抖动），半径贴合角色周围
func _throw_drops(drops: Array[ItemDrop]) -> void:
	if drops.is_empty():
		return
	var center := global_position
	var angle_step := TAU / drops.size()
	for i in drops.size():
		var angle := angle_step * i + randf_range(-0.25, 0.25)
		var distance := randf_range(18.0, 28.0)
		var target := center + Vector2.from_angle(angle) * distance
		drops[i].throw_from(center, target)


func _on_death_animation_finished() -> void:
	if not is_inside_tree():
		return
	# 死亡动画是循环的：播完一轮后停住，角色保持在最后一帧留在场景中
	animated_sprite.stop()
	animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(DIE_ANIM) - 1
