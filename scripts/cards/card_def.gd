class_name CardDef
extends Resource

enum CardType {
	INGREDIENT,
	PROCESS,
	TECHNIQUE,
	INTERACTION,
}

@export var card_id: StringName
@export var display_name: String = ""
@export var art: Texture2D
@export var energy_cost: int = 1
@export var card_type: CardType = CardType.INGREDIENT
@export var interaction_traits: PackedStringArray = []
@export var targeting_rules: String = "none"
@export var effects: Array[BaseEffect] = []
@export_multiline var preview_text: String = ""

func get_art_texture() -> Texture2D:
	return art

func get_card_type_label() -> StringName:
	match card_type:
		CardType.INGREDIENT:
			return &"ingredient"
		CardType.PROCESS:
			return &"process"
		CardType.TECHNIQUE:
			return &"technique"
		CardType.INTERACTION:
			return &"interaction"
		_:
			return &"ingredient"

func get_pastry_tags_added() -> PackedStringArray:
	var collected_tags: PackedStringArray = PackedStringArray()
	_collect_pastry_tags_from_effects(effects, collected_tags)
	return collected_tags

func _collect_pastry_tags_from_effects(effect_list: Array, collected_tags: PackedStringArray) -> void:
	for effect_value in effect_list:
		var effect: BaseEffect = effect_value
		if effect == null:
			continue
		if effect is AddPastryTagsEffect:
			for raw_tag in effect.tags_to_add:
				var pastry_tag: StringName = StringName(raw_tag)
				if pastry_tag == &"" or collected_tags.has(pastry_tag):
					continue
				collected_tags.append(pastry_tag)
		elif effect is ConditionalPastryEffect:
			_collect_pastry_tags_from_effects(effect.success_effects, collected_tags)
