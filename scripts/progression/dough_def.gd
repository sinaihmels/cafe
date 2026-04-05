class_name DoughDef
extends Resource

@export var dough_id: StringName = &""
@export var prep_item_id: StringName = &""
@export var display_name: String = ""
@export var art: Texture2D
@export_multiline var description: String = ""
@export var starting_deck_ids: PackedStringArray = []
@export var passive_modifier_ids: PackedStringArray = []
@export var unlocked_by_default: bool = true
@export var pastry_display_name: String = ""
@export var starting_pastry_tags: PackedStringArray = []
@export var requires_proofing: bool = false
@export var base_satiation: int = 1
