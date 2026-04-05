extends SceneTree

func _init() -> void:
	var session: SessionService = SessionService.new()
	var meta: MetaProfileService = MetaProfileService.new()
	var event_bus: EventBus = EventBus.new()
	var effect_queue: EffectQueueService = EffectQueueService.new()
	session.initialize(meta, event_bus)
	effect_queue.configure(event_bus)
	meta.reset_profile(session.content_library)

	assert(session.start_new_run_with_dough(&"laminated_dough"), "Laminated Dough should start a run.")
	assert(session.cafe_state.active_pastry != null, "The day should open with one active laminated pastry.")
	assert(session.cafe_state.active_pastry.dough_id == &"laminated_dough", "The active pastry should come from Laminated Dough.")

	session.deck_state.draw_pile.clear()
	session.deck_state.discard_pile.clear()
	session.deck_state.hand.clear()
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_proof"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_bake"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_serve"))

	assert(not session.can_play_card(session.deck_state.hand[1]), "Bake should be blocked until the laminated pastry is proofed.")
	assert(session.play_card_from_hand(0, [], effect_queue), "Proof should move the laminated pastry into the oven.")
	assert(session.cafe_state.active_pastry != null, "Proofing should immediately refill prep with the day's dough.")
	assert(session.cafe_state.active_pastry.dough_id == &"laminated_dough", "The refill pastry should use the selected dough for the day.")
	assert(session.cafe_state.oven_pastry != null, "Proofing should place the pastry in the oven.")
	assert(session.cafe_state.oven_mode == &"proofing", "The oven should enter the proofing stage.")

	session.advance_oven()
	assert(session.cafe_state.oven_pastry != null and session.cafe_state.oven_pastry.has_pastry_state(&"proofed"), "Advancing the oven should finish proofing.")
	assert(session.cafe_state.oven_pastry.has_pastry_tag(&"airy"), "Proofing should add the airy pastry tag.")
	assert(session.cafe_state.oven_mode == &"", "A proofed pastry should wait in the oven for Bake.")

	assert(session.play_card_from_hand(0, [], effect_queue), "Bake should start baking the proofed pastry.")
	assert(session.cafe_state.oven_mode == &"baking", "The oven should switch from proofed to baking.")

	session.advance_oven()
	assert(session.cafe_state.oven_mode == &"ready", "Advancing the oven again should finish the bake.")
	assert(session.cafe_state.oven_pastry != null and session.cafe_state.oven_pastry.has_pastry_state(&"baked"), "The proofed pastry should become baked.")
	assert(session.collect_oven_item(0), "A finished laminated pastry should be collectible from the oven.")
	assert(session.cafe_state.plated_pastries.size() == 1, "Collecting should move the pastry to the table.")
	assert(session.cafe_state.plated_pastries[0].has_pastry_state(&"warm"), "Collecting from the oven should make the pastry warm.")
	assert(session.cafe_state.active_pastry != null, "Plating the pastry should spawn the next pastry in prep.")
	quit()
