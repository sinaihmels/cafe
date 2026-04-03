extends SceneTree

func _init() -> void:
	var session: SessionService = SessionService.new()
	var meta: MetaProfileService = MetaProfileService.new()
	var event_bus: EventBus = EventBus.new()
	var effect_queue: EffectQueueService = EffectQueueService.new()
	session.initialize(meta, event_bus)
	effect_queue.configure(event_bus)
	meta.reset_profile(session.content_library)
	session.start_new_run_with_dough(&"sweet_dough")
	session.deck_state.draw_pile.clear()
	session.deck_state.discard_pile.clear()
	session.deck_state.hand.clear()
	session.deck_state.hand.append(session.content_library.build_card_instance(&"reward_cinnamon"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_bake"))
	var dough_targets: Array[Dictionary] = [{
		"zone": &"prep",
		"index": 0,
	}]
	assert(session.cafe_state.prep_items.size() == 1, "The chosen dough should already be prepped at the start of the day.")
	var valid_targets: Array[Dictionary] = session.get_valid_targets(session.deck_state.hand[0])
	assert(valid_targets.size() == 1, "Cinnamon should have exactly one legal target when the day starts with one dough in prep.")
	var energy_before_play: int = session.player_state.energy
	assert(session.play_card_from_hand(0, dough_targets, effect_queue), "Cinnamon should play successfully from hand onto the prepped dough.")
	assert(session.player_state.energy == energy_before_play - 1, "Playing Cinnamon should spend its energy cost.")
	assert(session.deck_state.hand.size() == 1, "Played cards should leave the hand.")
	assert(session.cafe_state.prep_items[0].has_tag(&"cinnamon"), "Cinnamon should modify the existing dough instead of spawning a loose ingredient.")
	assert(session.play_card_from_hand(0, dough_targets, effect_queue), "Bake should play successfully on the modified dough.")
	assert(session.cafe_state.oven_slots[0].item != null, "Baking should move the dough into the oven.")
	assert(session.cafe_state.oven_slots[0].remaining_turns == 1, "Normal baking should take one full turn before the item is ready.")
	assert(not session.cafe_state.oven_slots[0].item.has_tag(&"baked"), "Items should not be baked immediately when they enter the oven.")
	session.advance_oven()
	assert(session.cafe_state.oven_slots[0].item != null and session.cafe_state.oven_slots[0].item.has_tag(&"baked"), "Advancing the oven should finish the bake on the next turn.")
	assert(session.add_player_buff(&"second_wind_buff", &"test", &"second_wind"), "Should be able to add a temporary run buff.")
	var base_energy: int = session.player_state.max_energy
	session.begin_player_turn()
	assert(session.player_state.energy == base_energy + 1, "Second Wind should grant extra energy at turn start.")
	assert(session.add_player_buff(&"focused_service_buff", &"test", &"focus"), "Should be able to add a draw buff.")
	var hand_before: int = session.deck_state.hand.size()
	session.begin_player_turn()
	assert(session.deck_state.hand.size() >= hand_before, "Focused Service should not reduce hand size at turn start.")
	assert(session.purchase_shop_upgrade(&"tip_jar_upgrade"), "Should be able to buy a permanent upgrade with default tokens.")
	assert(meta.profile_state.purchased_shop_upgrade_ids.has(&"tip_jar_upgrade"), "Purchased upgrade should persist in profile.")
	quit()
