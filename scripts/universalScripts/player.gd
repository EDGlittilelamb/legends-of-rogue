extends CharacterBody2D
class_name Player

## 玩家数据中枢：只保存属性/背包/装备状态与对外接口，
## 行为逻辑由子节点组件负责（MoveController 移动、AttackController 攻击）

## 玩家基础属性
@export var max_hp: int = 100
@export var defense: int = 0
@export var attack: int = 10
@export var initial_weapon_scene: PackedScene = preload("res://scenes/Weapons/minigun/minigun.tscn")

## 背包初始武器（放入前三个格子）
const STARTING_WEAPONS: Array[PackedScene] = [
	preload("res://scenes/Weapons/sniper/sniper.tscn"),
	preload("res://scenes/Weapons/minigun/minigun.tscn"),
	preload("res://scenes/Weapons/pistol/pistol.tscn"),
]

var hp: int
var current_weapon: Weapon
## 背包数据：固定 20 格（4 行 x 5 列），null 表示空格
var inventory: Array[Item] = []
## 空手拳击动画播放中（move.gd 在此期间不覆盖动画）
var is_punching := false

@onready var weapon_holder: Node2D = $weapon


func _ready() -> void:
	hp = max_hp
	inventory.resize(20)
	for i in STARTING_WEAPONS.size():
		inventory[i] = STARTING_WEAPONS[i].instantiate() as Item
	# 初始装备背包第 1 格武器（与默认选中一致）
	if inventory[0] is Weapon:
		equip_from_inventory(0)
	else:
		_equip_weapon(initial_weapon_scene)


func _equip_weapon(weapon_scene: PackedScene) -> void:
	if not weapon_scene:
		return
	if current_weapon:
		current_weapon.queue_free()
	current_weapon = weapon_scene.instantiate() as Weapon
	current_weapon.is_equipped = true
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


func take_damage(amount: int, attacker: Node2D = null) -> void:
	var final_damage := maxi(1, amount - defense)
	hp -= final_damage
	if hp <= 0:
		hp = 0
		_die()


func _die() -> void:
	queue_free()
