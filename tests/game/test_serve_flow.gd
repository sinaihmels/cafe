extends SceneTree

func _init() -> void:
	var session: SessionService = SessionService.new()
	var meta: MetaProfileService = MetaProfileService.new()
	var event_bus: EventBus = EventBus.new()
	var effect_queue: EffectQueueService = EffectQueueService.new()
	session.initialize(meta, event_bus)
	effect_queue.configure(event_bus)
	meta.reset_profile(session.content_library)
	assert(session.start_new_run_with_dough(&"sweet_dough"), "A run should start with Sweet Dough.")
	session.deck_state.draw_pile.clear()
	session.deck_state.discard_pile.clear()
	session.deck_state.hand.clear()
	session.deck_state.hand.append(session.content_library.build_card_instance(&"reward_cinnamon"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_bake"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_serve"))
	var prep_target: Array[Dictionary] = [{
		"zone": &"prep",
		"index": 0,
	}]
	assert(session.play_card_from_hand(0, prep_target, effect_queue), "Cinnamon should play onto the day dough.")
	assert(session.play_card_from_hand(0, prep_target, effect_queue), "Bake should move the pastry into the oven.")
	session.advance_oven()
	assert(session.collect_oven_item(0), "A finished pastry should be collectible from the oven.")
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
	assert(session.play_card_from_hand(0, serve_targets, effect_queue), "Serve should deliver the plated pastry to the customer.")
	assert(session.cafe_state.table_items.is_empty(), "Serving should remove the pastry from the table.")
	assert(session.run_state.screen == GameEnums.Screen.REWARD, "Serving the last customer on day 1 should clear the encounter and route to reward.")
	quit()
