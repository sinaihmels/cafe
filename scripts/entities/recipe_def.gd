class_name RecipeDef
extends Resource

@export var recipe_id: StringName
@export var input_item_ids: PackedStringArray = []
@export var output_item_id: StringName
@export var station: StringName = &"prep"
@export var required_tags: PackedStringArray = []
@export var added_tags: PackedStringArray = []
@export var quality_delta: int = 0
