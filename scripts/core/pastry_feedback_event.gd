class_name PastryFeedbackEvent
extends RefCounted

var zone: StringName = &""
var index: int = -1
var added_tags: PackedStringArray = PackedStringArray()
var added_states: PackedStringArray = PackedStringArray()
var quality_delta: int = 0

func _init(
	zone_value: StringName = &"",
	index_value: int = -1,
	added_tags_value: PackedStringArray = PackedStringArray(),
	added_states_value: PackedStringArray = PackedStringArray(),
	quality_delta_value: int = 0
) -> void:
	zone = zone_value
	index = index_value
	added_tags = added_tags_value.duplicate()
	added_states = added_states_value.duplicate()
	quality_delta = quality_delta_value

func has_visible_feedback() -> bool:
	return not added_tags.is_empty() or not added_states.is_empty() or quality_delta != 0

func duplicate_event() -> PastryFeedbackEvent:
	return PastryFeedbackEvent.new(zone, index, added_tags, added_states, quality_delta)
