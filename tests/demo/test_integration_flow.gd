extends SceneTree

func _init() -> void:
	var content: DemoContentLibrary = DemoContentLibrary.new()
	content.load_all()
	var dough: DemoDoughDef = content.get_dough(&"sweet_dough")
	assert(dough != null, "Sweet dough definition should load.")
	var encounter_def: DemoEncounterDef = content.get_encounter(1)
	assert(encounter_def != null, "Encounter 1 should load.")
	var customer_def: DemoCustomerDef = content.get_customer(&"customer_regular_guest")
	assert(customer_def != null, "Regular customer should load.")
	var player: DemoPlayerState = DemoPlayerState.new()
	player.max_mana = 3
	player.mana = 3
	player.stress = 16
	player.max_stress = 16
	player.master_deck_ids = dough.start_deck.duplicate()
	player.deck_state = DemoDeckState.new()
	var encounter_state: DemoEncounterState = DemoEncounterState.new()
	var food_composer: FoodComposer = FoodComposer.new()
	var matcher: DemandMatcher = DemandMatcher.new()
	var card_engine: CardEngine = CardEngine.new(food_composer)
	var customer_ai: CustomerAI = CustomerAI.new()
	var encounter_director: EncounterDirector = EncounterDirector.new(
		card_engine,
		food_composer,
		matcher,
		customer_ai
	)
	var deck_defs: Array[DemoCardDef] = []
	for card_id in player.master_deck_ids:
		var card_def: DemoCardDef = content.get_card(StringName(card_id))
		if card_def != null:
			deck_defs.append(card_def)
	encounter_director.start_encounter(
		encounter_def,
		customer_def,
		player,
		encounter_state,
		deck_defs,
		dough.passive_rules
	)
	assert(encounter_state.turn_number == 1, "Encounter should start on turn 1.")
	assert(player.mana == player.max_mana, "Player mana should reset at turn start.")
	assert(player.deck_state.hand.size() > 0, "Encounter start should draw a hand.")
	var end_turn_result: Dictionary = encounter_director.resolve_end_turn(player, encounter_state, dough.passive_rules)
	assert(end_turn_result.has("message"), "End turn result should include feedback.")
	assert(player.stress > 0, "Player should remain alive after first enemy step.")
	quit()
