class_name CardDef
extends Resource

@export var card_id: StringName
@export var display_name: String = ""
@export var art: Texture2D
@export var energy_cost: int = 1
@export var tags: PackedStringArray = []
@export var interaction_traits: PackedStringArray = []
@export var targeting_rules: String = "none"
@export var effects: Array[BaseEffect] = []
@export_multiline var preview_text: String = ""
