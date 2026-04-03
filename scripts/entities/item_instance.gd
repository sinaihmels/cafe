class_name ItemInstance
extends Resource

@export var item_def: ItemDef
@export var quality: int = 0
@export var statuses: PackedStringArray = []
@export var custom_tags: PackedStringArray = []
@export var zone: StringName = &"prep"
@export var created_turn: int = 0
@export var steps_used: int = 0
@export var active_statuses: Array[ModifierInstance] = []

func get_item_id() -> StringName:
	if item_def == null:
		return &""
	return item_def.item_id

func get_display_name() -> String:
	if item_def == null:
		return "Unknown Item"
	return item_def.display_name

func get_all_tags() -> PackedStringArray:
	var merged: PackedStringArray = PackedStringArray()
	if item_def != null:
		for tag in item_def.tags:
			merged.append(tag)
	for tag in custom_tags:
		if not merged.has(tag):
			merged.append(tag)
	return merged

func has_tag(tag: StringName) -> bool:
	return get_all_tags().has(tag)

func add_tag(tag: StringName) -> void:
	if not custom_tags.has(tag):
		custom_tags.append(tag)
