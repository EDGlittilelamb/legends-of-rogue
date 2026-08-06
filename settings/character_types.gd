class_name CharacterTypes
extends Object

## 角色类型配置：标注角色属于什么类型
## 使用方式：CharacterTypes.Type.BANDIT

## 角色类型枚举（可按需扩展）
enum Type {
	NONE = 0,     ## 未指定
	BANDIT,       ## 匪帮
	COURIER,      ## 快递员
	POLICE,       ## 警察
	SHOPKEEPER,   ## 店主
}
