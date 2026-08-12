class_name GameConfig
extends Object

## 游戏配置：角色类型与互动类型等全局枚举配置
## 使用方式：GameConfig.CharacterType.BANDIT / GameConfig.Interaction.TALK

## 角色类型：标注角色属于什么类型
enum CharacterType {
	NONE = 0,     ## 未指定
	BANDIT,       ## 匪帮
	COURIER,      ## 快递员
	POLICE,       ## 警察
	SHOPKEEPER,   ## 店主
}

## 互动类型：NPC 声明自己支持的互动选项，玩家端据此渲染
enum Interaction {
	NONE = 0,     ## 无
	TALK,         ## 对话
	TRADE,        ## 交易
	ATTACK,       ## 攻击/敌对
	INSPECT,      ## 查看
	INSULT,       ## 侮辱（troll 角色的交互型技能选项）
}

## 互动选项在 UI 上显示的名称
static func get_interaction_label(type: Interaction) -> String:
	match type:
		Interaction.TALK:
			return "对话"
		Interaction.TRADE:
			return "交易"
		Interaction.ATTACK:
			return "攻击"
		Interaction.INSPECT:
			return "查看"
		Interaction.INSULT:
			return "侮辱"
		_:
			return "未知"
