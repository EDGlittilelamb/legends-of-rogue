extends Node2D
class_name BackpackUI

## 背包 UI：屏幕左下角 4x5 格子
## - 默认只显示第一行（5 格），按 B 键展开/收起完整网格
## - 未打开时鼠标滚轮在 5 格间切换选中（高亮）
## - 打开时鼠标左键拖动物品换位
## - 所有输入在 _input 阶段处理，不影响玩家移动与攻击

const GRID_COLS := 5
const GRID_ROWS := 4
const SLOT_SIZE := 34.0
const SLOT_GAP := 2.0
const MARGIN := 8.0
## 背包内物品显示最长边（像素）
const ITEM_FIT_SIZE := 26.0

const SLOT_COLOR := Color(0.45, 0.45, 0.45, 0.55)
const SLOT_COLOR_SELECTED := Color(1.0, 0.85, 0.3, 0.95)
const PANEL_BG := Color(0.0, 0.0, 0.0, 0.3)

var player: Player
var is_open := false
var selected_index := 0
var _drag_source := -1
var _dragging := false
var _drag_item: Item = null


func _ready() -> void:
	# 玩家引用改为 group 查找（节点树结构调整后不再依赖固定父子层级）
	player = get_tree().get_first_node_in_group("player") as Player
	# 背包内容变化（拾取/丢弃）时自动刷新物品摆放
	player.inventory_changed.connect(_refresh_item_placement)
	# 延迟一帧摆放物品：避免 _ready 阶段 add_child 的物品首帧未进入渲染队列
	call_deferred("_refresh_item_placement")
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		is_open = not is_open
		_refresh_item_placement()
		queue_redraw()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		if event.pressed:
			# 未打开时：滚轮在默认行 5 格之间切换选中，并同步装备选中的武器
			if not is_open and event.button_index == MOUSE_BUTTON_WHEEL_UP:
				selected_index = (selected_index + GRID_COLS - 1) % GRID_COLS
				_equip_selected()
				queue_redraw()
				get_viewport().set_input_as_handled()
				return
			if not is_open and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				selected_index = (selected_index + 1) % GRID_COLS
				_equip_selected()
				queue_redraw()
				get_viewport().set_input_as_handled()
				return
			# 打开时：左键按下格子上的物品 -> 开始拖拽（拦截事件，避免触发攻击）
			if is_open and event.button_index == MOUSE_BUTTON_LEFT:
				var slot := _slot_at(event.position)
				if slot >= 0 and player.inventory[slot] != null:
					_drag_source = slot
					_drag_item = player.inventory[slot]
					_dragging = true
					get_viewport().set_input_as_handled()
					return
		else:
			# 松开左键：完成拖拽并换位
			if event.button_index == MOUSE_BUTTON_LEFT and _dragging:
				var target := _slot_at(event.position)
				if target >= 0 and target != _drag_source:
					_swap_items(_drag_source, target)
				else:
					_refresh_item_placement()
				_dragging = false
				_drag_item = null
				_drag_source = -1
				get_viewport().set_input_as_handled()
				return

	if event is InputEventMouseMotion and _dragging and _drag_item:
		# 拖拽中的物品跟随鼠标
		_drag_item.position = event.position


func _draw() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var visible_rows := GRID_ROWS if is_open else 1
	var grid_size := Vector2(
		GRID_COLS * SLOT_SIZE + (GRID_COLS - 1) * SLOT_GAP,
		visible_rows * SLOT_SIZE + (visible_rows - 1) * SLOT_GAP
	)
	# 背景面板（左下角）
	var bg_rect := Rect2(Vector2(MARGIN, viewport_size.y - MARGIN - grid_size.y), grid_size)
	draw_rect(bg_rect, PANEL_BG)
	# 格子
	for row in visible_rows:
		for col in GRID_COLS:
			var idx := row * GRID_COLS + col
			var color := SLOT_COLOR_SELECTED if idx == selected_index else SLOT_COLOR
			draw_rect(_slot_rect(row, col), color)


## 装备当前选中格子里的武器（换到玩家手上）
func _equip_selected() -> void:
	player.equip_from_inventory(selected_index)


## 交换背包中两个格子的物品并刷新显示
func _swap_items(a: int, b: int) -> void:
	var tmp: Item = player.inventory[a]
	player.inventory[a] = player.inventory[b]
	player.inventory[b] = tmp
	_refresh_item_placement()


## 把背包中的物品实例挂到 UI 下并放到对应格子中心
func _refresh_item_placement() -> void:
	for i in player.inventory.size():
		var item := player.inventory[i]
		if item == null:
			continue
		if item.get_parent() != self:
			add_child(item)
		# 未打开时只显示第一行（行 0），其余隐藏
		item.visible = is_open or (i / GRID_COLS == 0)
		item.position = _slot_center(i)
		_fit_item(item)
		item.queue_redraw()


## 物品显示缩放：最长边不超过 ITEM_FIT_SIZE（只缩小不放大）
func _fit_item(item: Node2D) -> void:
	var sprite := item.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return
	var tex := sprite.sprite_frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var display_size := tex.get_size() * sprite.scale
	var longest := maxf(display_size.x, display_size.y)
	if longest <= 0.0:
		return
	item.scale = Vector2.ONE * minf(ITEM_FIT_SIZE / longest, 1.0)


## 格子矩形（行从下往上：第 0 行在最底部贴近屏幕下边缘）
func _slot_rect(row: int, col: int) -> Rect2:
	var viewport_size := get_viewport().get_visible_rect().size
	var row_step := SLOT_SIZE + SLOT_GAP
	var x := MARGIN + col * row_step
	var y := viewport_size.y - MARGIN - SLOT_SIZE - row * row_step
	return Rect2(x, y, SLOT_SIZE, SLOT_SIZE)


func _slot_center(idx: int) -> Vector2:
	return _slot_rect(idx / GRID_COLS, idx % GRID_COLS).get_center()


## 根据视口坐标找到对应格子索引；不在任何可见格子上返回 -1
func _slot_at(pos: Vector2) -> int:
	var visible_rows := GRID_ROWS if is_open else 1
	for row in visible_rows:
		for col in GRID_COLS:
			if _slot_rect(row, col).has_point(pos):
				return row * GRID_COLS + col
	return -1
