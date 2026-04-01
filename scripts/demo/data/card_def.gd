class_name DemoCardDef
extends Resource

@export var id: StringName = &""
@export var name: String = ""
@export var category: int = DemoEnums.CardCategory.INGREDIENT
@export var mana_cost: int = 1
@export var target_rule: int = DemoEnums.TargetRule.NONE
@export var effects: Array[DemoCardEffectDef] = []
@export var rarity: int = 0
@export var tags: PackedStringArray = []
@export_multiline var description: String = ""
