extends SceneTree

const CLASSIFICATION_TAGS := {
	"ingredient": true,
	"process": true,
	"technique": true,
	"interaction": true,
	"utility": true,
}

func _init() -> void:
	_test_card_tag_migration()
	_test_double_batch_flow()
	_test_interaction_and_timing_cards()
	quit()

func _new_session() -> Array:
	var session: SessionService = SessionService.new()
	var meta: MetaProfileService = MetaProfileService.new()
	var event_bus: EventBus = EventBus.new()
	var effect_queue: EffectQueueService = EffectQueueService.new()
	session.initialize(meta, event_bus)
	effect_queue.configure(event_bus)
	meta.reset_profile(session.content_library)
	return [session, meta, event_bus, effect_queue]

func _test_card_tag_migration() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	for card_value in session.content_library.cards.values():
		var card: CardDef = card_value
		assert(card != null, "Card resources should load.")
		for raw_tag in card.tags:
			assert(CLASSIFICATION_TAGS.has(String(raw_tag)), "CardDef.tags should only contain classification tags. Offending card: %s" % String(card.card_id))
	for customer_value in session.content_library.customers.values():
		var customer: CustomerDef = customer_value
		assert(customer != null, "Customer resources should load.")
		var all_tokens: PackedStringArray = PackedStringArray()
		for token in customer.required_tags:
			all_tokens.append(token)
		for token in customer.bonus_tags:
			all_tokens.append(token)
		for token in customer.forbidden_tags:
			all_tokens.append(token)
		for raw_token in all_tokens:
			var token_text: String = String(raw_token)
			assert(token_text != "chocolate", "Canonical content should use 'chocolaty' instead of legacy 'chocolate'.")
			assert(token_text != "burnt", "Canonical content should use 'burned' instead of legacy 'burnt'.")
			assert(token_text != "failed", "Canonical content should not use the old failed-item token.")

func _test_double_batch_flow() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	var effect_queue: EffectQueueService = setup[3]
	assert(session.start_new_run_with_dough(&"laminated_dough"), "Laminated Dough should start a run.")
	session.player_state.energy = 10
	session.deck_state.draw_pile.clear()
	session.deck_state.discard_pile.clear()
	session.deck_state.hand.clear()
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_double_batch"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_proof"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_bake"))
	assert(session.play_card_from_hand(0, [], effect_queue), "Double Batch should arm the next plated pastry duplication.")
	assert(session.play_card_from_hand(0, [], effect_queue), "Proof should move the laminated pastry into the oven.")
	session.advance_oven()
	assert(session.play_card_from_hand(0, [], effect_queue), "Bake should begin once the pastry is proofed.")
	session.advance_oven()
	assert(session.collect_oven_item(0), "The baked laminated pastry should be collectible.")
	assert(session.cafe_state.plated_pastries.size() == 2, "Double Batch should duplicate the next plated pastry.")

func _test_interaction_and_timing_cards() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	var effect_queue: EffectQueueService = setup[3]
	assert(session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should start a run.")
	session.player_state.energy = 10
	var patience_before: Array[int] = []
	for customer in session.combat_state.active_customers:
		patience_before.append(customer.current_patience)
	session.deck_state.draw_pile.clear()
	session.deck_state.discard_pile.clear()
	session.deck_state.hand.clear()
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_mini_cookies"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_small_talk"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_bake"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_perfect_timing"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_serve"))
	assert(session.play_card_from_hand(0, [], effect_queue), "Mini Cookies should increase patience for every active customer.")
	for index in range(session.combat_state.active_customers.size()):
		assert(session.combat_state.active_customers[index].current_patience == patience_before[index] + 1, "Mini Cookies should grant +1 patience to each customer.")
	assert(session.play_card_from_hand(0, [], effect_queue), "Small Talk should queue patience protection for the next customer turn.")
	var patience_after_small_talk: int = session.combat_state.active_customers[0].current_patience
	assert(patience_after_small_talk == patience_before[0] + 2, "Small Talk should also trigger the Social talent on the focused customer.")
	session.combat_state.turn_state = GameEnums.TurnState.CUSTOMER_TURN
	session._process_customer_turn()
	session.combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN
	assert(session.combat_state.active_customers[0].current_patience == patience_after_small_talk, "Small Talk should prevent patience loss during the next customer turn.")

	assert(session.play_card_from_hand(0, [], effect_queue), "Bake should send the sweet pastry into the oven.")
	session.advance_oven()
	assert(session.collect_oven_item(0), "The baked sweet pastry should be plated.")
	assert(session.play_card_from_hand(0, [], effect_queue), "Perfect Timing should arm the next warm serve bonus.")
	session.combat_state.active_customers[0].remaining_hunger = 1
	var reputation_before_serve: int = session.player_state.reputation
	var tips_before_serve: int = session.player_state.tips
	var serve_targets: Array[Dictionary] = [
		{
			"zone": &"customer",
			"index": 0,
		},
		{
			"zone": &"table",
			"index": 0,
		},
	]
	assert(session.play_card_from_hand(0, serve_targets, effect_queue), "Serve should deliver the warm pastry.")
	assert(session.player_state.reputation == reputation_before_serve + 3, "Perfect Timing should add +1 reputation to the final successful warm serve.")
	assert(session.player_state.tips == tips_before_serve + 6, "Final payout should include the warm-serve tip bonus and accumulated satisfaction tips.")
