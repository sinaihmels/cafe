extends SceneTree

func _init() -> void:
	var food_composer: FoodComposer = FoodComposer.new()
	var card_engine: CardEngine = CardEngine.new(food_composer)
	var player: DemoPlayerState = DemoPlayerState.new()
	player.starting_hand_size = 1
	player.max_mana = 3
	player.mana = 3
	var effect_tag: DemoCardEffectDef = DemoCardEffectDef.new()
	effect_tag.op = DemoEnums.EffectOp.ADD_TAG
	effect_tag.tag = &"sweet"
	var effect_quality: DemoCardEffectDef = DemoCardEffectDef.new()
	effect_quality.op = DemoEnums.EffectOp.ADD_QUALITY
	effect_quality.amount = 1
	var card_def: DemoCardDef = DemoCardDef.new()
	card_def.id = &"test_card"
	card_def.name = "Test Card"
	card_def.mana_cost = 1
	card_def.effects = [effect_tag, effect_quality]
	player.deck_state = DemoDeckState.new()
	player.deck_state.reset_from_defs([card_def])
	var encounter_state: DemoEncounterState = DemoEncounterState.new()
	encounter_state.food_state = DemoFoodState.new()
	card_engine.start_player_turn(player, encounter_state.food_state)
	assert(player.deck_state.hand.size() == 1, "Expected one card in hand.")
	var result: Dictionary = card_engine.play_card(
		player,
		encounter_state,
		PackedStringArray(["sweet_first_bonus"]),
		0
	)
	assert(bool(result.get("success", false)), "Expected card play to succeed.")
	assert(encounter_state.food_state.has_tag(&"sweet"), "Expected sweet tag to be applied.")
	assert(encounter_state.food_state.quality == 1, "Expected quality to increase.")
	assert(encounter_state.food_state.score_bonus == 1, "Expected dough passive sweet bonus.")
	assert(player.deck_state.hand.is_empty(), "Expected played card to leave hand.")
	quit()
