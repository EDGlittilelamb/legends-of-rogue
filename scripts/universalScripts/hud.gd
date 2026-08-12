extends Node2D
class_name HUD

## 玩家 HUD：屏幕左上角显示条形血条 + 金币图标与数量
## 挂在玩家端 CanvasLayer 下；值变化时才重绘（_process 检测）

const HP_BAR_SIZE := Vector2(100, 12)
const MARGIN := 8.0
const COIN_ATLAS := preload("res://assets/16x16.png")
## 金币图标在图集中的区域（与金币掉落物 money.tscn 同一枚金币）
const COIN_REGION := Rect2(32, 128, 16, 16)

const BAR_BG := Color(0.1, 0.1, 0.1, 0.8)
const BAR_FRAME := Color(0.0, 0.0, 0.0, 1.0)
const HP_HIGH := Color(0.85, 0.2, 0.2, 1.0)
const HP_LOW := Color(1.0, 0.85, 0.2, 1.0)
const TEXT_COLOR := Color.WHITE

var player: Character

var _last_hp := -1
var _last_max := -1
var _last_money := -1
var _coin_texture: AtlasTexture


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Character
	if player == null:
		visible = false
		return
	_coin_texture = AtlasTexture.new()
	_coin_texture.atlas = COIN_ATLAS
	_coin_texture.region = COIN_REGION
	queue_redraw()


func _process(_delta: float) -> void:
	if player == null:
		return
	# 数值变化时才重绘
	if player.hp != _last_hp or player.max_hp != _last_max or player.money != _last_money:
		_last_hp = player.hp
		_last_max = player.max_hp
		_last_money = player.money
		queue_redraw()


func _draw() -> void:
	if player == null:
		return
	_draw_hp_bar()
	_draw_money()


## 条形血条：深色底 + 红/黄填充 + 黑色描边
func _draw_hp_bar() -> void:
	var bar_rect := Rect2(MARGIN, MARGIN, HP_BAR_SIZE.x, HP_BAR_SIZE.y)
	draw_rect(bar_rect, BAR_BG)
	if player.max_hp > 0:
		var ratio := clampf(float(player.hp) / float(player.max_hp), 0.0, 1.0)
		var fill := Rect2(
			MARGIN + 1.0, MARGIN + 1.0,
			(HP_BAR_SIZE.x - 2.0) * ratio, HP_BAR_SIZE.y - 2.0
		)
		draw_rect(fill, HP_HIGH if ratio > 0.3 else HP_LOW)
	draw_rect(bar_rect, BAR_FRAME, false, 1.0)


## 金币：图标 + 黑色描边的白色数量文字
func _draw_money() -> void:
	var icon_pos := Vector2(MARGIN, MARGIN + HP_BAR_SIZE.y + 6.0)
	draw_texture(_coin_texture, icon_pos)
	var font := ThemeDB.fallback_font
	var text := str(player.money)
	var text_pos := icon_pos + Vector2(20.0, 13.0)
	draw_string_outline(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT_COLOR)
