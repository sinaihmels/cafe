class_name ShopUpgradeDef
extends Resource

@export var upgrade_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 0
@export var passive_modifier_ids: PackedStringArray = []
@export var unlocked_by_default: bool = false
