class_name ModifierDef
extends Resource

@export var modifier_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var default_duration_turns: int = 1
@export var max_stacks: int = 1
@export var stackable: bool = true
@export var stat_modifiers: Dictionary = {}
@export var on_apply_effects: Array[BaseEffect] = []
@export var on_turn_start_effects: Array[BaseEffect] = []
@export var on_turn_end_effects: Array[BaseEffect] = []
@export var on_card_played_effects: Array[BaseEffect] = []
@export var on_customer_served_effects: Array[BaseEffect] = []
@export var on_item_baked_effects: Array[BaseEffect] = []
@export var on_expire_effects: Array[BaseEffect] = []
