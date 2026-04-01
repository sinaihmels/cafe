class_name FoodComposer
extends RefCounted

var _sweet_bonus_used_this_turn: bool = false

func reset_for_encounter(food_state: DemoFoodState) -> void:
	if food_state == null:
		return
	food_state.reset()
	_sweet_bonus_used_this_turn = false

func start_turn(food_state: DemoFoodState) -> void:
	if food_state == null:
		return
	food_state.times_modified_this_turn = 0
	_sweet_bonus_used_this_turn = false

func apply_card_effects(
	food_state: DemoFoodState,
	effects: Array[DemoCardEffectDef],
	passive_rules: PackedStringArray
) -> void:
	if food_state == null:
		return
	for effect_value in effects:
		var effect: DemoCardEffectDef = effect_value
		_apply_food_effect(food_state, effect, passive_rules)

func _apply_food_effect(
	food_state: DemoFoodState,
	effect: DemoCardEffectDef,
	passive_rules: PackedStringArray
) -> void:
	if effect == null:
		return
	match effect.op:
		DemoEnums.EffectOp.ADD_TAG:
			var tags_to_add: PackedStringArray = effect.tags
			if tags_to_add.is_empty() and effect.tag != &"":
				tags_to_add = PackedStringArray([String(effect.tag)])
			for raw_tag_value in tags_to_add:
				var raw_tag: String = raw_tag_value
				var tag: StringName = StringName(raw_tag)
				food_state.add_tag(tag)
				if (
					tag == &"sweet"
					and passive_rules.has("sweet_first_bonus")
					and not _sweet_bonus_used_this_turn
				):
					food_state.score_bonus += 1
					_sweet_bonus_used_this_turn = true
			food_state.times_modified_this_turn += 1
		DemoEnums.EffectOp.ADD_QUALITY:
			food_state.quality = maxi(0, food_state.quality + effect.amount)
			food_state.times_modified_this_turn += 1
		_:
			return
