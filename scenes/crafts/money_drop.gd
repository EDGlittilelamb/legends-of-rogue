class_name MoneyDrop
extends ItemDrop

## 金币掉落物：拾取后直接增加拾取者的金币（money），不进入背包/商店
## 复用 ItemDrop 的抛出动画、浮动与拾取延迟；场景自带金币贴图（不需要 item_scene）

## 这堆金币的价值
@export var amount: int = 10


## 覆写拾取：加金币而非放入背包；死亡角色（尸体）不拾取
func _on_body_entered(body: Node2D) -> void:
	if not _pickup_ready:
		return
	if not (body is Character):
		return
	var player := body as Character
	if player.is_dead:
		return
	player.money += amount
	queue_free()
