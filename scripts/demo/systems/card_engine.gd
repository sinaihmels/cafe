class_name CardEngine
extends RefCounted

var _food_composer: FoodComposer

func _init(food_composer: FoodComposer) -> void:
	_food_composer = food_composer

func start_player_turn(player_state: DemoPlayerState, food_state: DemoFoodState) -> void:
	if player_state == null or player_state.deck_state == null:
		return
	player_state.reset_turn_mana()
	_food_composer.start_turn(food_state)
	player_state.deck_state.draw_to_hand_size(player_state.starting_hand_size)

func can_play_card(player_state: DemoPlayerState, hand_index: int) -> bool:
	if player_state == null or player_state.deck_state == null:
		return false
	if hand_index < 0 or hand_index >= player_state.deck_state.hand.size():
		return false
	var card: DemoCardInstance = player_state.deck_state.hand[hand_index]
	if card == null:
		return false
	return player_state.mana >= card.get_cost()

func play_card(
	player_state: DemoPlayerState,
	encounter_state: DemoEncounterState,
	passive_rules: PackedStringArray,
	hand_index: int,
	target_payload: Dictionary = {}
) -> Dictionary:
	if player_state == null or encounter_state == null or player_state.deck_state == null:
		return {"success": false, "message": "Card engine is not ready."}
	if hand_index < 0 or hand_index >= player_state.deck_state.hand.size():
		return {"success": false, "message": "Invalid card index."}
	var card: DemoCardInstance = player_state.deck_state.hand[hand_index]
	if card == null or card.card_def == null:
		return {"success": false, "message": "Card is missing definition."}
	var card_cost: int = card.get_cost()
	if player_state.mana < card_cost:
		return {"success": false, "message": "Not enough mana for %s." % card.get_card_name()}
	player_state.mana -= card_cost
	var tips_delta: int = 0
	encounter_state.turn_phase = DemoEnums.TurnPhase.RESOLVING
	for effect_value in card.card_def.effects:
		var effect: DemoCardEffectDef = effect_value
		if effect == null:
			continue
		match effect.op:
			DemoEnums.EffectOp.ADD_TAG:
				var add_tag_effects: Array[DemoCardEffectDef] = []
				add_tag_effects.append(effect)
				_food_composer.apply_card_effects(encounter_state.food_state, add_tag_effects, passive_rules)
			DemoEnums.EffectOp.ADD_QUALITY:
				var add_quality_effects: Array[DemoCardEffectDef] = []
				add_quality_effects.append(effect)
				_food_composer.apply_card_effects(encounter_state.food_state, add_quality_effects, passive_rules)
			DemoEnums.EffectOp.DRAW_CARDS:
				for _draw_index in range(maxi(0, effect.amount)):
					player_state.deck_state.draw_one()
			DemoEnums.EffectOp.GAIN_MANA:
				player_state.mana += effect.amount
			DemoEnums.EffectOp.MODIFY_PATIENCE:
				if encounter_state.active_customer != null:
					encounter_state.active_customer.current_patience = maxi(
						1,
						encounter_state.active_customer.current_patience + effect.amount
					)
			DemoEnums.EffectOp.HEAL_STRESS:
				player_state.heal_stress(effect.amount)
			DemoEnums.EffectOp.ADD_TIPS:
				tips_delta += maxi(0, effect.amount)
			_:
				continue
	if target_payload.has("tips_delta"):
		tips_delta += int(target_payload.get("tips_delta", 0))
	player_state.deck_state.discard_card_from_hand(hand_index)
	encounter_state.turn_phase = DemoEnums.TurnPhase.PLAYER
	return {
		"success": true,
		"message": "Played %s." % card.get_card_name(),
		"tips_delta": tips_delta,
	}

func end_player_turn_cleanup(player_state: DemoPlayerState) -> void:
	if player_state == null or player_state.deck_state == null:
		return
	player_state.deck_state.discard_hand()
