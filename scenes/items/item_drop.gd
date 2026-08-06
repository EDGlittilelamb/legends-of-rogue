extends Area2D
class_name ItemDrop

## 通用掉落物：显示物品图标并上下浮动，玩家靠近后自动拾取进入背包

## 掉落的物品场景（如 res://scenes/Weapons/sniper/sniper.tscn）
@export var item_scene: PackedScene
## 上下浮动幅度与速度（视觉表现）
@export var float_amplitude: float = 3.0
@export var float_speed: float = 2.5

var _base_y := 0.0
var _time := 0.0
var _throwing := false
## 抛出动画落定前不可拾取（防止死亡瞬间被尸体立即捡回）
var _pickup_ready := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_icon()
	_base_y = global_position.y
	# 稍后开启拾取（等抛出动画结束）
	get_tree().create_timer(0.6).timeout.connect(_enable_pickup)


func _enable_pickup() -> void:
	if is_inside_tree():
		_pickup_ready = true


func _process(delta: float) -> void:
	# 抛出动画播放期间不浮动
	if _throwing:
		return
	# 轻微上下浮动，让掉落物更醒目
	_time += delta
	global_position.y = _base_y + sin(_time * float_speed) * float_amplitude


## 从 origin 抛出到 target 的出生动画（死亡掉落/丢弃时使用），落定后恢复浮动
## 全程使用全局坐标，与掉落物挂在哪个节点下无关
func throw_from(origin: Vector2, target: Vector2) -> void:
	_throwing = true
	global_position = origin
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target, 0.4)
	tween.finished.connect(_on_throw_finished.bind(target.y))


func _on_throw_finished(final_y: float) -> void:
	_throwing = false
	_base_y = final_y


## 从物品场景实例里提取 idle 帧作为掉落物图标，并保持物品场景中的实际缩放
## （例如枪械材质 scale=0.5，掉落物图标同样按 0.5 显示，不会恢复成原始尺寸）
func _apply_icon() -> void:
	if item_scene == null:
		return
	var sample := item_scene.instantiate()
	var icon_texture: Texture2D = null
	var effective_scale := 1.0
	var sprite_node := sample.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite_node and sprite_node.sprite_frames:
		icon_texture = sprite_node.sprite_frames.get_frame_texture("idle", 0)
		# 实际显示尺寸 = 纹理 × AnimatedSprite2D.scale × 根节点 scale
		effective_scale = sprite_node.scale.x * sample.scale.x
	sample.free()
	if icon_texture == null:
		return
	var sprite := $Sprite2D
	sprite.texture = icon_texture
	sprite.scale = Vector2.ONE * effective_scale


## 玩家进入拾取范围：实例化物品放入背包，成功则移除掉落物（背包满则保留）
func _on_body_entered(body: Node2D) -> void:
	# 抛出落定前不可拾取
	if not _pickup_ready:
		return
	if not (body is Character):
		return
	var player := body as Character
	# 死亡角色（尸体）不再拾取
	if player.is_dead:
		return
	if item_scene == null:
		return
	var item := item_scene.instantiate() as Item
	if player.add_item_to_inventory(item):
		queue_free()
