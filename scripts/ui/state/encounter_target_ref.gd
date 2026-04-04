class_name EncounterTargetRef
extends RefCounted

var zone: StringName = &""
var index: int = -1

func _init(target_zone: StringName = &"", target_index: int = -1) -> void:
	zone = target_zone
	index = target_index

func matches(other_zone: StringName, other_index: int) -> bool:
	return zone == other_zone and index == other_index

func duplicate_ref() -> EncounterTargetRef:
	return EncounterTargetRef.new(zone, index)

func to_dictionary() -> Dictionary:
	return {
		"zone": zone,
		"index": index,
	}

static func from_dictionary(raw_target: Dictionary) -> EncounterTargetRef:
	return EncounterTargetRef.new(
		StringName(raw_target.get("zone", "")),
		int(raw_target.get("index", -1))
	)
