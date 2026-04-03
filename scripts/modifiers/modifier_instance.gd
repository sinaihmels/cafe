class_name ModifierInstance
extends Resource

@export var modifier_id: StringName = &""
@export var remaining_turns: int = 0
@export var stacks: int = 1
@export var source_kind: StringName = &""
@export var source_id: StringName = &""
@export var applied_turn: int = 0
@export var state: Dictionary = {}

func is_expired() -> bool:
	return remaining_turns == 0
