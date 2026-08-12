extends Node

## GameRules（Autoload 单例）：全局游戏规则与跨角色判定
##
## 分层约定：
##   - 只影响单个角色的行为 → 写在角色自己的组件/技能里（如 InsultSkill）
##   - 影响多个角色或全局的规则 → 写在这里广播，由各 NPC 组件自行决定反应
##
## 使用示例（未来 NPC 行为）：
##   GameRules.kindness_below_threshold.connect(_on_kindness_below)
##   func _on_kindness_below(character: Character) -> void:
##       if character == 自己:
##           add_enemy(玩家)  # 或停止交易 / 改变对话

## 善良值低于该阈值时 NPC 开始厌恶玩家（具体反应由各 NPC 组件实现）
const KINDNESS_HATE_THRESHOLD := 50

## 任意角色善良值变化时广播（每次 change_kindness 都会触发）
signal kindness_changed(character: Character)
## 善良值首次跌破阈值（>= 阈值 → < 阈值）时广播；回升后再次跌破会重复触发
signal kindness_below_threshold(character: Character)

## 记录各角色是否已处于阈值以下（用于边沿检测）
var _below_threshold := {}


## 由 Character.change_kindness 统一调用：广播变化 + 阈值边沿检测
func notify_kindness_changed(c: Character) -> void:
	if c == null:
		return
	kindness_changed.emit(c)
	var is_below := c.kindness_score < KINDNESS_HATE_THRESHOLD
	var was_below: bool = _below_threshold.get(c, false)
	if is_below and not was_below:
		_below_threshold[c] = true
		kindness_below_threshold.emit(c)
	elif not is_below and was_below:
		_below_threshold[c] = false
