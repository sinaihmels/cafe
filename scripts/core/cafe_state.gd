class_name CafeState
extends Resource

@export var serving_table_capacity: int = 3
@export var prep_space_capacity: int = 1
@export var oven_capacity: int = 1
@export var active_pastry: PastryInstance
@export var oven_pastry: PastryInstance
@export var plated_pastries: Array[PastryInstance] = []
@export var oven_mode: StringName = &""
@export var oven_turns_remaining: int = 0
@export var table_items: Array[ItemInstance] = []
@export var prep_items: Array[ItemInstance] = []
@export var oven_slots: Array[OvenSlotState] = []
