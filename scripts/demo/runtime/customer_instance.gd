class_name DemoCustomerInstance
extends Resource

@export var customer_def: DemoCustomerDef
@export var current_patience: int = 0
@export var turns_waited: int = 0

func reset_from_def(definition: DemoCustomerDef) -> void:
	customer_def = definition
	if definition == null:
		current_patience = 0
		turns_waited = 0
		return
	current_patience = definition.patience
	turns_waited = 0

func get_display_name() -> String:
	if customer_def == null:
		return "Unknown Customer"
	return customer_def.display_name

func get_type() -> int:
	if customer_def == null:
		return DemoEnums.CustomerType.REGULAR
	return customer_def.type

func get_demands() -> Array[DemoDemandRule]:
	if customer_def == null:
		return []
	return customer_def.demands
