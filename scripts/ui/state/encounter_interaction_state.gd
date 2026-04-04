class_name EncounterInteractionState
extends RefCounted

var pending_card_index: int = -1
var pending_rule: String = ""
var pending_prompt: String = ""
var focused_customer_index: int = -1
var valid_targets: Array[EncounterTargetRef] = []
var selected_targets: Array[EncounterTargetRef] = []

func selected_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()
	for target in selected_targets:
		indices.append(target.index)
	return indices

func is_target_selected(zone: StringName, index: int) -> bool:
	for target in selected_targets:
		if target.matches(zone, index):
			return true
	return false

func is_zone_targetable(zone: StringName, index: int) -> bool:
	if pending_rule == "":
		return false
	if not valid_targets.is_empty():
		for target in valid_targets:
			if target.matches(zone, index):
				return true
		return false
	match pending_rule:
		"select_two_prep_items":
			if zone != &"prep":
				return false
			return not selected_indices().has(index)
		"select_one_prep_item", "select_one_proof_target":
			return zone == &"prep"
		"select_one_baked_item":
			return zone == &"table"
		"select_one_customer_and_one_table_item":
			for selected_target in selected_targets:
				if selected_target.zone == zone:
					return selected_target.index == index
			return zone == &"customer" or zone == &"table"
		"select_one_item", "select_one_bake_target":
			return zone == &"prep" or zone == &"oven"
		"select_one_customer":
			return zone == &"customer"
		_:
			return false

func duplicate_ref() -> EncounterInteractionState:
	var copied_state: EncounterInteractionState = EncounterInteractionState.new()
	copied_state.pending_card_index = pending_card_index
	copied_state.pending_rule = pending_rule
	copied_state.pending_prompt = pending_prompt
	copied_state.focused_customer_index = focused_customer_index
	for target in valid_targets:
		copied_state.valid_targets.append(target.duplicate_ref())
	for target in selected_targets:
		copied_state.selected_targets.append(target.duplicate_ref())
	return copied_state
