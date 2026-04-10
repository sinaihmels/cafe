class_name CardDef
extends Resource

enum CardType {
	INGREDIENT,
	PROCESS,
	TECHNIQUE,
	INTERACTION,
}

const INGREDIENT_BACKGROUND: Texture2D = preload("res://assets/demo/cards/base_card.png")
const PROCESS_BACKGROUND: Texture2D = preload("res://assets/demo/cards/base_card_process.png")
const TECHNIQUE_BACKGROUND: Texture2D = preload("res://assets/demo/cards/base_card_technique.png")
const INTERACTION_BACKGROUND: Texture2D = preload("res://assets/demo/cards/base_card_interaction.png")

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

func get_background_texture() -> Texture2D:
	return background_texture_for_type(card_type)

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

func get_pastry_tag_previews() -> Array[PastryTagPreview]:
	var unconditional_previews: Array[PastryTagPreview] = []
	var conditional_previews: Array[PastryTagPreview] = []
	_collect_pastry_tag_previews(
		effects,
		unconditional_previews,
		conditional_previews,
		PackedStringArray(),
		PackedStringArray(),
		PackedStringArray()
	)
	var ordered_previews: Array[PastryTagPreview] = []
	var guaranteed_tags: Dictionary = {}
	var seen_preview_keys: Dictionary = {}
	for preview in unconditional_previews:
		var preview_key: String = _preview_key(preview)
		if seen_preview_keys.has(preview_key):
			continue
		seen_preview_keys[preview_key] = true
		guaranteed_tags[String(preview.tag_id)] = true
		ordered_previews.append(preview.duplicate_preview())
	for preview in conditional_previews:
		if guaranteed_tags.has(String(preview.tag_id)):
			continue
		var preview_key: String = _preview_key(preview)
		if seen_preview_keys.has(preview_key):
			continue
		seen_preview_keys[preview_key] = true
		ordered_previews.append(preview.duplicate_preview())
	return ordered_previews

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

func _collect_pastry_tag_previews(
	effect_list: Array,
	unconditional_previews: Array[PastryTagPreview],
	conditional_previews: Array[PastryTagPreview],
	required_pastry_tags: PackedStringArray,
	required_pastry_states: PackedStringArray,
	forbidden_pastry_states: PackedStringArray
) -> void:
	for effect_value in effect_list:
		var effect: BaseEffect = effect_value
		if effect == null:
			continue
		if effect is AddPastryTagsEffect:
			var merged_required_tags: PackedStringArray = _merge_pastry_tokens(required_pastry_tags, effect.required_pastry_tags)
			var merged_required_states: PackedStringArray = _merge_pastry_tokens(required_pastry_states, effect.required_pastry_states)
			var merged_forbidden_states: PackedStringArray = _merge_pastry_tokens(forbidden_pastry_states, effect.forbidden_pastry_states)
			var is_conditional: bool = _has_pastry_conditions(merged_required_tags, merged_required_states, merged_forbidden_states)
			var condition_text: String = _build_condition_text(merged_required_tags, merged_required_states, merged_forbidden_states)
			var target_list: Array[PastryTagPreview] = conditional_previews if is_conditional else unconditional_previews
			for raw_tag in effect.tags_to_add:
				var tag_id: StringName = StringName(raw_tag)
				if tag_id == &"":
					continue
				target_list.append(PastryTagPreview.new(tag_id, is_conditional, condition_text))
		elif effect is ConditionalPastryEffect:
			_collect_pastry_tag_previews(
				effect.success_effects,
				unconditional_previews,
				conditional_previews,
				_merge_pastry_tokens(required_pastry_tags, effect.required_pastry_tags),
				_merge_pastry_tokens(required_pastry_states, effect.required_pastry_states),
				_merge_pastry_tokens(forbidden_pastry_states, effect.forbidden_pastry_states)
			)

func _merge_pastry_tokens(base_tokens: PackedStringArray, extra_tokens: PackedStringArray) -> PackedStringArray:
	var merged: PackedStringArray = base_tokens.duplicate()
	for raw_token in extra_tokens:
		var token: StringName = StringName(raw_token)
		if token == &"" or merged.has(token):
			continue
		merged.append(token)
	return merged

func _has_pastry_conditions(
	required_pastry_tags: PackedStringArray,
	required_pastry_states: PackedStringArray,
	forbidden_pastry_states: PackedStringArray
) -> bool:
	return not required_pastry_tags.is_empty() or not required_pastry_states.is_empty() or not forbidden_pastry_states.is_empty()

func _build_condition_text(
	required_pastry_tags: PackedStringArray,
	required_pastry_states: PackedStringArray,
	forbidden_pastry_states: PackedStringArray
) -> String:
	if not _has_pastry_conditions(required_pastry_tags, required_pastry_states, forbidden_pastry_states):
		return ""
	var condition_parts: PackedStringArray = PackedStringArray()
	for raw_tag in required_pastry_tags:
		var tag_id: StringName = StringName(raw_tag)
		if tag_id == &"":
			continue
		condition_parts.append(_humanize_pastry_token(tag_id, true))
	for raw_state in required_pastry_states:
		var state_id: StringName = StringName(raw_state)
		if state_id == &"":
			continue
		condition_parts.append(_humanize_pastry_token(state_id, true))
	for raw_state in forbidden_pastry_states:
		var state_id: StringName = StringName(raw_state)
		if state_id == &"":
			continue
		condition_parts.append("not %s" % _humanize_pastry_token(state_id, true))
	if condition_parts.is_empty():
		return ""
	return "if %s" % " + ".join(condition_parts)

func _humanize_pastry_token(token_id: StringName, lowercase: bool) -> String:
	var words: PackedStringArray = String(token_id).replace("_", " ").split(" ", false)
	var formatted_words: PackedStringArray = PackedStringArray()
	for raw_word in words:
		var word: String = raw_word.strip_edges()
		if word == "":
			continue
		if lowercase:
			formatted_words.append(word.to_lower())
		else:
			formatted_words.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())
	return " ".join(formatted_words)

func _preview_key(preview: PastryTagPreview) -> String:
	if preview == null:
		return ""
	return "%s|%s|%s" % [
		String(preview.tag_id),
		"true" if preview.is_conditional else "false",
		preview.condition_text
	]

static func background_texture_for_type(card_type_value: int) -> Texture2D:
	match card_type_value:
		CardType.PROCESS:
			return PROCESS_BACKGROUND
		CardType.TECHNIQUE:
			return TECHNIQUE_BACKGROUND
		CardType.INTERACTION:
			return INTERACTION_BACKGROUND
		_:
			return INGREDIENT_BACKGROUND

static func is_background_texture(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var texture_path: String = texture.resource_path
	if texture_path != "":
		match texture_path:
			"res://assets/demo/cards/base_card.png", \
			"res://assets/demo/cards/base_card_process.png", \
			"res://assets/demo/cards/base_card_technique.png", \
			"res://assets/demo/cards/base_card_interaction.png":
				return true
			_:
				return false
	return (
		texture == INGREDIENT_BACKGROUND
		or texture == PROCESS_BACKGROUND
		or texture == TECHNIQUE_BACKGROUND
		or texture == INTERACTION_BACKGROUND
	)
