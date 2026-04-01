class_name CustomerInstance
extends Resource

@export var customer_def: CustomerDef
@export var current_patience: int = 3
@export var mood_flags: Dictionary = {}
@export var turns_waited: int = 0
@export var served: bool = false

func get_display_name() -> String:
	if customer_def == null:
		return "Unknown Customer"
	return customer_def.display_name

func get_preferences() -> PackedStringArray:
	if customer_def == null:
		return PackedStringArray()
	return customer_def.preferences

func get_order_id() -> StringName:
	if customer_def == null:
		return &""
	return customer_def.order_id
