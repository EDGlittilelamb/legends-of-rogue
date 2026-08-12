class_name InstigatorSkill
extends Skill

## instigator（挑拨者）技能：右键标记 NPC，再右键另一个 NPC 使其互相敌对
## 第一次右键：标记鼠标指向的 NPC（视觉：目标变黄）
## 第二次右键：被标记者与新目标互相加入 enemies（双向敌对），并清除标记
## 对同一 NPC 再次右键：取消标记

## 目标检测圆半径（像素）
const TARGET_RADIUS := 26.0
## 检测中心相对玩家的前移距离
const DETECT_OFFSET := 24.0
## 标记视觉颜色
const MARK_COLOR := Color(1.0, 1.0, 0.4, 1.0)
## 每次使用扣除的善良值
const KINDNESS_COST := 20

## 当前被标记的 NPC（null = 无标记）
var _marked: Character = null


func _init() -> void:
	cooldown = 0.5


func _cast(aim_direction: Vector2) -> void:
	if character == null:
		return
	var target := _find_target_npc(aim_direction)
	if target == null:
		return
	# 每次成功使用（命中目标）都会降低善良值（统一入口，会广播 GameRules）
	character.change_kindness(-KINDNESS_COST)
	if _marked == null:
		# 第一次右键：打标记
		_marked = target
		target.modulate = MARK_COLOR
	else:
		if target == _marked:
			# 右键同一个 NPC：取消标记
			_clear_mark()
		else:
			# 第二次右键：双方互相敌对，然后清除标记
			_marked.add_enemy(target)
			target.add_enemy(_marked)
			_clear_mark()


func _process(delta: float) -> void:
	# 父类负责冷却递减
	super(delta)
	# 被标记者死亡/销毁时自动清除标记
	if _marked and (not is_instance_valid(_marked) or _marked.is_dead):
		_clear_mark()


func _clear_mark() -> void:
	if is_instance_valid(_marked):
		_marked.modulate = Color.WHITE
	_marked = null


## 在鼠标方向前方寻找最近的存活 NPC（物理查询，与拳击判定同款）
func _find_target_npc(aim_direction: Vector2) -> Character:
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.RIGHT
	var space := character.get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = TARGET_RADIUS
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, character.global_position + aim_direction.normalized() * DETECT_OFFSET)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	for hit in space.intersect_shape(query, 8):
		var collider := hit.collider as Node2D
		if collider is Character and collider != character and not collider.is_dead:
			return collider as Character
	return null
