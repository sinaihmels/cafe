class_name CustomerInstance
extends Resource

@export var customer_def: CustomerDef
@export var current_patience: int = 3
@export var mood_flags: Dictionary = {}
@export var turns_waited: int = 0
@export var served: bool = false
@export var active_statuses: Array[ModifierInstance] = []

func reset_from_def(definition: CustomerDef) -> void:
	customer_def = definition
	current_patience = definition.patience if definition != null else 0
	mood_flags.clear()
	turns_waited = 0
	served = false
	active_statuses.clear()

func get_display_name() -> String:
	if customer_def == null:
		return "Unknown Customer"
	return customer_def.display_name

func get_preferences() -> PackedStringArray:
	if customer_def == null:
		return PackedStringArray()
	if not customer_def.required_tags.is_empty():
		return customer_def.required_tags
	return customer_def.preferences

func get_bonus_tags() -> PackedStringArray:
	if customer_def == null:
		return PackedStringArray()
	return customer_def.bonus_tags

func get_forbidden_tags() -> PackedStringArray:
	if customer_def == null:
		return PackedStringArray()
	return customer_def.forbidden_tags

func get_minimum_quality() -> int:
	if customer_def == null:
		return 0
	return customer_def.minimum_quality

func get_base_reputation() -> int:
	if customer_def == null:
		return 1
	return customer_def.base_reputation

func get_base_tips() -> int:
	if customer_def == null:
		return 0
	return customer_def.reward

func get_bonus_reputation_per_match() -> int:
	if customer_def == null:
		return 1
	return customer_def.bonus_reputation_per_match

func get_bonus_tips_per_match() -> int:
	if customer_def == null:
		return 1
	return customer_def.bonus_tips_per_match

func get_order_id() -> StringName:
	if customer_def == null:
		return &""
	return customer_def.order_id

func get_customer_type() -> int:
	if customer_def == null:
		return GameEnums.CustomerType.REGULAR
	return customer_def.customer_type
