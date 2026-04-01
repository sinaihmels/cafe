class_name CafeState
extends Resource

@export var serving_table_capacity: int = 3
@export var prep_space_capacity: int = 99
@export var oven_capacity: int = 2
@export var table_items: Array[ItemInstance] = []
@export var prep_items: Array[ItemInstance] = []
@export var oven_slots: Array[OvenSlotState] = []
