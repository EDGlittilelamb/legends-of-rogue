extends Area2D
class_name Item

## 物品基类：武器、消耗品等所有装备道具都继承自该类

## 物品名称
@export var item_name: String = ""
## 物品描述
@export var item_description: String = ""
## 物品价值（金币）；商店展示价格用
@export var cost: int = 0
## 是否为消耗品（按 Q 可使用的物品；武器等非消耗品为 false）
@export var consumable := false


## 使用物品（消耗品覆写此方法，如药水回血）。
## 由玩家按 Q 触发，传入使用者；基类默认无效果（非消耗品直接跳过）
func use(_user: Character) -> void:
	pass
