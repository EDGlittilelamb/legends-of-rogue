class_name RoamState
extends AIState

## 漫游状态：在地图上随机移动，每次移动后至少停顿 5 秒
## 发现存活敌人时切换到追击状态

@export_group("NPC 端")

@export var move_speed: float = 120.0
## 单次随机移动的时长范围（秒）
@export var move_time_range := Vector2(0.8, 2.5)
## 移动后的停顿时长范围（秒），下限即"至少停顿 5 秒"
@export var idle_time_range := Vector2(5.0, 8.0)

var _moving := false
var _move_timer := 0.0
var _idle_timer := 0.0
var _direction := Vector2.ZERO
var _last_direction := Vector2.DOWN


func enter() -> void:
	_moving = false
	# 进入状态先停顿一段时间再移动
	_idle_timer = randf_range(idle_time_range.x, idle_time_range.y)


func physics_update(delta: float) -> void:
	# 发现存活敌人 → 追击
	if find_nearest_enemy() != null:
		machine.change_state(machine.chase_state)
		return
	if _moving:
		_move_timer -= delta
		if _move_timer <= 0.0:
			_stop_moving()
		else:
			npc.velocity = _direction * move_speed
			npc.move_and_slide()
			play_move_animation(_direction)
	else:
		_idle_timer -= delta
		npc.velocity = Vector2.ZERO
		if _idle_timer <= 0.0:
			_start_random_move()
		else:
			play_idle_animation(_last_direction)


## 开始一次随机方向的移动
func _start_random_move() -> void:
	_moving = true
	_direction = Vector2.from_angle(randf_range(0.0, TAU))
	_move_timer = randf_range(move_time_range.x, move_time_range.y)


## 结束移动，进入至少 5 秒的停顿
func _stop_moving() -> void:
	_moving = false
	_idle_timer = randf_range(idle_time_range.x, idle_time_range.y)
