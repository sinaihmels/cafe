class_name PastryInstance
extends Resource

@export var dough_id: StringName = &""
@export var display_name: String = ""
@export var art: Texture2D
@export var quality: int = 0
@export var base_satiation: int = 1
@export var bonus_satiation: int = 0
@export var pastry_tags: PackedStringArray = []
@export var pastry_states: Dictionary = {}
@export var zone: StringName = &"active"
@export var turns_in_oven: int = 0
@export var steps_used: int = 0
@export var internal_flags: Dictionary = {}

func get_display_name() -> String:
	return display_name if display_name != "" else String(dough_id)

func get_pastry_tags() -> PackedStringArray:
	return pastry_tags.duplicate()

func get_pastry_states() -> PackedStringArray:
	var states: PackedStringArray = PackedStringArray()
	for raw_state in pastry_states.keys():
		states.append(StringName(raw_state))
	return states

func add_pastry_tag(tag: StringName) -> void:
	if tag == &"" or pastry_tags.has(tag):
		return
	pastry_tags.append(tag)

func remove_pastry_tag(tag: StringName) -> void:
	var index: int = pastry_tags.find(tag)
	if index >= 0:
		pastry_tags.remove_at(index)

func has_pastry_tag(tag: StringName) -> bool:
	return pastry_tags.has(tag)

func add_pastry_state(state: StringName, duration: int = -1) -> void:
	if state == &"":
		return
	pastry_states[state] = duration

func remove_pastry_state(state: StringName) -> void:
	pastry_states.erase(state)

func has_pastry_state(state: StringName) -> bool:
	return pastry_states.has(state)

func get_pastry_state_duration(state: StringName) -> int:
	return int(pastry_states.get(state, -999))

func tick_temporary_states() -> void:
	var expired_states: Array[StringName] = []
	for raw_state in pastry_states.keys():
		var state: StringName = StringName(raw_state)
		var duration: int = int(pastry_states.get(raw_state, -1))
		if duration > 0:
			duration -= 1
			if duration == 0:
				expired_states.append(state)
			else:
				pastry_states[state] = duration
	for state in expired_states:
		pastry_states.erase(state)

func duplicate_pastry() -> PastryInstance:
	return duplicate(true) as PastryInstance

func has_token(token: StringName) -> bool:
	if token == &"quality":
		return quality > 0
	return has_pastry_tag(token) or has_pastry_state(token)
