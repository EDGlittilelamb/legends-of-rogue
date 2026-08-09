extends Node2D
class_name ShopUI

## 商店 UI：展示店主背包货物与价格（仅展示，购买交互后续实现）
## 挂在玩家端 CanvasLayer 下，由 InteractController 打开/关闭
## 布局：屏幕右下角一行 5 格（对应 NPC 背包上限），价格标注在格子右上角

const MAX_SLOTS := 5
const SLOT_SIZE := 34.0
const SLOT_GAP := 2.0
const MARGIN := 8.0
## 物品显示最长边（像素）
const ITEM_FIT_SIZE := 26.0

const SLOT_COLOR := Color(0.45, 0.45, 0.45, 0.55)
const PANEL_BG := Color(0.0, 0.0, 0.0, 0.3)
const PRICE_COLOR := Color(1.0, 0.9, 0.3, 1.0)
const PRICE_FONT_SIZE := 10

## 当前展示的店主（null 表示商店关闭）
var shopkeeper: Character
var is_open := false


func _ready() -> void:
	# 注册 group 供 InteractController 查找（场景属性 + 代码双保险）
	add_to_group("shop_ui")
	visible = false


## 打开商店并读取店主背包渲染（店铺数据只读，不修改店主背包）
func open_shop(keeper: Character) -> void:
	if keeper == null:
		return
	shopkeeper = keeper
	is_open = true
	visible = true
	# 定位：店主头顶上方居中（店主被交互冻结，位置不会变化）
	var keeper_screen := keeper.get_global_transform_with_canvas().origin
	var grid_width := MAX_SLOTS * SLOT_SIZE + (MAX_SLOTS - 1) * SLOT_GAP
	position = keeper_screen + Vector2(-grid_width / 2.0, -SLOT_SIZE - 12.0)
	_refresh_items()
	queue_redraw()


## 关闭商店：把展示中的物品实例归还（remove_child，不销毁）
func close_shop() -> void:
	is_open = false
	visible = false
	_refresh_items()
	shopkeeper = null
	queue_redraw()


func _draw() -> void:
	if not is_open or shopkeeper == null:
		return
	var grid_size := Vector2(
		MAX_SLOTS * SLOT_SIZE + (MAX_SLOTS - 1) * SLOT_GAP,
		SLOT_SIZE
	)
	# 面板：以本节点为左上角（节点已定位在店主头顶上方）
	draw_rect(Rect2(Vector2.ZERO, grid_size), PANEL_BG)
	# 格子 + 价格角标
	var font := ThemeDB.fallback_font
	for i in MAX_SLOTS:
		var rect := _slot_rect(i, Vector2.ZERO)
		draw_rect(rect, SLOT_COLOR)
		var item: Item = shopkeeper.inventory[i] if i < shopkeeper.inventory.size() else null
		if item == null or item.cost <= 0:
			continue
		var text := "%d$" % item.cost
		var pos := Vector2(rect.end.x - 2.0, rect.position.y + PRICE_FONT_SIZE + 2.0)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_RIGHT, -1, PRICE_FONT_SIZE, 3, Color.BLACK)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_RIGHT, -1, PRICE_FONT_SIZE, PRICE_COLOR)


## 摆放店主物品：先归还旧实例（remove_child 不销毁），再把当前店主物品挂到本节点对应格子
func _refresh_items() -> void:
	for child in get_children():
		if child is Item:
			remove_child(child)
	if shopkeeper == null:
		return
	# 面板以本节点为原点（节点已定位在店主头顶）
	var origin := Vector2.ZERO
	for i in mini(shopkeeper.inventory.size(), MAX_SLOTS):
		var item := shopkeeper.inventory[i]
		if item == null:
			continue
		add_child(item)
		item.position = _slot_rect(i, origin).get_center()
		_fit_item(item)


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


func _slot_rect(idx: int, origin: Vector2) -> Rect2:
	var x := origin.x + idx * (SLOT_SIZE + SLOT_GAP)
	return Rect2(x, origin.y, SLOT_SIZE, SLOT_SIZE)
