extends CharacterBody2D
class_name Player

## 玩家基础属性
@export var max_hp: int = 100
@export var defense: int = 0
@export var attack: int = 10
@export var initial_weapon_scene: PackedScene = preload("res://scenes/Weapons/minigun/minigun.tscn")

var hp: int
var current_weapon: Weapon

@onready var weapon_holder: Node2D = $weapon


func _ready() -> void:
	hp = max_hp
	_equip_weapon(initial_weapon_scene)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		try_attack()


## 玩家只负责发起攻击，具体实现交给当前武器
func try_attack() -> void:
	var aim_direction := (get_global_mouse_position() - global_position).normalized()
	if current_weapon:
		current_weapon.attack(aim_direction, self)
	else:
		_fist_attack(aim_direction)


func _equip_weapon(weapon_scene: PackedScene) -> void:
	if not weapon_scene:
		return
	if current_weapon:
		current_weapon.queue_free()
	current_weapon = weapon_scene.instantiate() as Weapon
	weapon_holder.add_child(current_weapon)
	current_weapon.position = Vector2.ZERO


## 空手时的拳击：在鼠标方向前方一定范围内寻找敌人
func _fist_attack(direction: Vector2) -> void:
	var space_state := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 26.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + direction * 20.0)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	for hit in space_state.intersect_shape(query, 8):
		var target: Node2D = hit.collider
		if target == self:
			continue
		if target.has_method("take_damage"):
			target.take_damage(attack, self)
			break


func take_damage(amount: int, attacker: Node2D = null) -> void:
	var final_damage := maxi(1, amount - defense)
	hp -= final_damage
	if hp <= 0:
		hp = 0
		_die()


func _die() -> void:
	queue_free()
