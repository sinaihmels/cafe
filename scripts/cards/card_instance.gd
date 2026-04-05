class_name CardInstance
extends Resource

@export var card_def: CardDef
@export var runtime_cost_override: int = -1
@export var upgrades: int = 0
@export var temporary_tags: PackedStringArray = []
@export var temporary_flags: Dictionary = {}

func get_cost() -> int:
	if runtime_cost_override >= 0:
		return runtime_cost_override
	if card_def == null:
		return 0
	return card_def.energy_cost

func get_display_name() -> String:
	if card_def == null:
		return "Unknown Card"
	return card_def.display_name

func get_preview_text() -> String:
	if card_def == null:
		return ""
	return card_def.preview_text

func get_art_texture() -> Texture2D:
	if card_def == null:
		return null
	return card_def.get_art_texture()

func get_pastry_tags_added() -> PackedStringArray:
	if card_def == null:
		return PackedStringArray()
	return card_def.get_pastry_tags_added()

func get_card_type() -> int:
	if card_def == null:
		return CardDef.CardType.INGREDIENT
	return card_def.card_type

func get_card_type_label() -> StringName:
	if card_def == null:
		return &"unknown"
	return card_def.get_card_type_label()

func get_all_tags() -> PackedStringArray:
	var merged: PackedStringArray = PackedStringArray()
	var card_type_label: StringName = get_card_type_label()
	if card_type_label != &"" and card_type_label != &"unknown":
		merged.append(card_type_label)
	for tag in temporary_tags:
		if not merged.has(tag):
			merged.append(tag)
	return merged
