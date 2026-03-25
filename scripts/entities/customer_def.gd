class_name CustomerDef
extends Resource

@export var customer_id: StringName
@export var display_name: String = ""
@export var order_id: StringName
@export var preferences: PackedStringArray = []
@export var patience: int = 3
@export var reward: int = 10
@export var personality_modifiers: Dictionary = {}
