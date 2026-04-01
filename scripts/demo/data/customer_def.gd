class_name DemoCustomerDef
extends Resource

@export var id: StringName = &""
@export var type: int = DemoEnums.CustomerType.REGULAR
@export var display_name: String = ""
@export var patience: int = 5
@export var stress_damage: int = 2
@export var demands: Array[DemoDemandRule] = []
@export var boss_flags: Dictionary = {}
