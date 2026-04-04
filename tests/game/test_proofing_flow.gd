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
	assert(session.cafe_state.prep_items.size() == 1, "The morning-prepped laminated dough should start in Prep.")
	assert(session.cafe_state.prep_items[0].get_item_id() == &"laminated_dough", "Laminated Dough should be the prepped item.")

	session.deck_state.draw_pile.clear()
	session.deck_state.discard_pile.clear()
	session.deck_state.hand.clear()
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_bake"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_proof"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_serve"))

	var prep_target: Array[Dictionary] = [{
		"zone": &"prep",
		"index": 0,
	}]
	assert(session.get_valid_targets(session.deck_state.hand[0]).is_empty(), "Bake should have no target before a laminated dough is proofed.")
	assert(session.play_card_from_hand(1, prep_target, effect_queue), "Proof should move the laminated dough into the oven.")
	assert(session.cafe_state.prep_items.is_empty(), "Proofing should remove the dough from Prep.")
	assert(session.cafe_state.oven_slots[0].item != null, "Proofing should place the dough in the oven.")
	assert(session.cafe_state.oven_slots[0].stage == &"proofing", "The oven slot should enter the proofing stage.")

	session.advance_oven()
	assert(session.cafe_state.oven_slots[0].stage == &"proofed", "Advancing the oven should finish proofing.")

	var bake_target: Array[Dictionary] = [{
		"zone": &"oven",
		"index": 0,
	}]
	assert(session.play_card_from_hand(0, bake_target, effect_queue), "Bake should finish a proofed dough in the oven.")
	assert(session.cafe_state.oven_slots[0].stage == &"baking", "The slot should switch from proofed to baking.")

	session.advance_oven()
	assert(session.cafe_state.oven_slots[0].stage == &"ready", "Advancing the oven again should finish the bake.")
	assert(session.cafe_state.oven_slots[0].item != null and session.cafe_state.oven_slots[0].item.has_tag(&"baked"), "The proofed dough should become a baked item.")
	assert(session.collect_oven_item(0), "A finished laminated pastry should be collectible from the oven.")
	assert(session.cafe_state.table_items.size() == 1, "Collecting should move the pastry to the table.")
	quit()
