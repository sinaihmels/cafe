extends SceneTree

func _init() -> void:
	_test_customer_initialization()
	_test_satisfaction_tiers()
	_test_satiation_rules()
	_test_hunger_flow_and_return_scheduling()
	_test_multi_day_return_scheduling()
	_test_decoration_gifts()
	_test_social_and_unknown_talents()
	_test_day_three_cannot_schedule_boss_return()
	_test_summary_message_includes_satisfaction_and_gifts()
	_test_new_run_resets_loyalty_tracking_but_keeps_owned_decorations()
	quit()

func _new_session() -> Array:
	var session: SessionService = SessionService.new()
	var meta: MetaProfileService = MetaProfileService.new()
	var event_bus: EventBus = EventBus.new()
	var effect_queue: EffectQueueService = EffectQueueService.new()
	session.initialize(meta, event_bus)
	effect_queue.configure(event_bus)
	meta.reset_profile(session.content_library)
	return [session, effect_queue]

func _test_customer_initialization() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	var customer: CustomerInstance = CustomerInstance.new()
	customer.reset_from_def(session.content_library.get_customer(&"sweet_tooth_customer"))
	assert(customer.remaining_hunger == 2, "Sweet Tooth should initialize with 2 hunger.")
	assert(customer.has_talent(&"social"), "Sweet Tooth should carry the Social talent.")
	assert(customer.satisfaction_score == 0, "Customers should begin with 0 satisfaction score.")
	assert(customer.pending_tip_bonus == 0, "Customers should begin with no stored tip bonus.")
	assert(not customer.has_return_scheduled, "Customers should not begin with a scheduled return.")
	assert(customer.get_gift_decoration_ids().has(&"pastry_shelf"), "Sweet Tooth should have an authored decoration gift pool.")

func _test_satisfaction_tiers() -> void:
	var customer: CustomerInstance = CustomerInstance.new()
	customer.satisfaction_score = CustomerInstance.SATISFIED_THRESHOLD
	assert(customer.get_satisfaction_tier() == &"satisfied", "A score of 4 should count as satisfied.")
	assert(customer.get_max_extra_return_visits() == 1, "Satisfied customers should earn 1 future return visit.")
	customer.satisfaction_score = CustomerInstance.VERY_SATISFIED_THRESHOLD
	assert(customer.get_satisfaction_tier() == &"very_satisfied", "A score of 6 should count as very satisfied.")
	assert(customer.get_max_extra_return_visits() == 2, "Very satisfied customers should earn up to 2 future return visits.")
	customer.satisfaction_score = CustomerInstance.EXTREMELY_SATISFIED_THRESHOLD
	assert(customer.get_satisfaction_tier() == &"extremely_satisfied", "A score of 8 should count as extremely satisfied.")
	assert(customer.get_max_extra_return_visits() == 2, "Extremely satisfied customers should still cap at 2 future return visits.")
	assert(customer.is_extremely_satisfied(), "A score of 8 should qualify for decoration gifts.")

func _test_satiation_rules() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	var sweet_pastry: PastryInstance = session._create_pastry_from_dough(&"sweet_dough")
	assert(session._calculate_pastry_satiation(sweet_pastry) == 1, "Sweet Dough pastries should start at 1 satiation.")
	sweet_pastry.add_pastry_tag(&"luxurious")
	assert(session._calculate_pastry_satiation(sweet_pastry) == 2, "Luxurious pastries should add 1 satiation.")
	sweet_pastry.add_pastry_tag(&"airy")
	assert(session._calculate_pastry_satiation(sweet_pastry) == 1, "Airy pastries should reduce satiation by 1.")

	var savory_pastry: PastryInstance = session._create_pastry_from_dough(&"savory_dough")
	savory_pastry.add_pastry_tag(&"salty")
	assert(session._calculate_pastry_satiation(savory_pastry) == 3, "Savory Dough plus salty should reach 3 satiation.")

	var burned_pastry: PastryInstance = session._create_pastry_from_dough(&"sourdough")
	burned_pastry.add_pastry_state(&"burned")
	assert(session._calculate_pastry_satiation(burned_pastry) == 0, "Burned pastries should not provide satiation.")

func _test_hunger_flow_and_return_scheduling() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	var effect_queue: EffectQueueService = setup[1]
	assert(session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should start a run for hunger flow coverage.")
	assert(session.combat_state.active_customers.size() == 1, "Day 1 should begin with a single customer.")
	assert(session.combat_state.active_customers[0].remaining_hunger == 2, "Sweet Tooth should need two sweet pastries.")
	session.player_state.energy = 10
	session.deck_state.draw_pile.clear()
	session.deck_state.discard_pile.clear()
	session.deck_state.hand.clear()
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_bake"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_serve"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_bake"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_serve"))

	var starting_reputation: int = session.player_state.reputation
	var starting_tips: int = session.player_state.tips

	assert(session.play_card_from_hand(0, [], effect_queue), "The first pastry should bake successfully.")
	session.advance_oven()
	assert(session.collect_oven_item(0), "The first pastry should reach the table.")
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
	assert(session.play_card_from_hand(0, serve_targets, effect_queue), "Serve should deliver the first pastry.")
	assert(session.combat_state.active_customers.size() == 1, "The customer should stay after the first accepted pastry.")
	assert(session.combat_state.active_customers[0].remaining_hunger == 1, "The first pastry should reduce remaining hunger to 1.")
	assert(session.combat_state.active_customers[0].satisfaction_score == 3, "Accepted pastries should add base satisfaction plus matched bonus tags.")
	assert(session.combat_state.active_customers[0].pending_tip_bonus == 2, "Accepted pastries should bank bonus tips until the final serve.")
	assert(session.run_state.current_day_satisfaction_score == 3, "Accepted pastries should also increase the current day satisfaction total.")
	assert(session.run_state.run_satisfaction_score == 3, "Accepted pastries should also increase the run satisfaction total.")
	assert(session.player_state.reputation == starting_reputation, "Partial serves should not pay reputation immediately.")
	assert(session.player_state.tips == starting_tips, "Partial serves should not pay tips immediately.")

	assert(session.play_card_from_hand(0, [], effect_queue), "The second pastry should bake successfully.")
	session.advance_oven()
	assert(session.collect_oven_item(0), "The second pastry should reach the table.")
	assert(session.play_card_from_hand(0, serve_targets, effect_queue), "Serve should finish the hungry customer with a second pastry.")
	assert(session.run_state.screen == GameEnums.Screen.REWARD, "Clearing day 1 should route to the reward screen.")
	assert(session.player_state.reputation == starting_reputation + 2, "Final payout should use the final pastry's reputation score.")
	assert(session.player_state.tips == starting_tips + 7, "Final payout should include both the base tips and accumulated satisfaction tips.")
	assert(session.run_state.last_completed_day_satisfaction_score == 6, "Day completion should store the last completed day satisfaction total.")
	assert(int(session.run_state.day_satisfaction_history.get(1, 0)) == 6, "Day history should record the cleared day satisfaction score.")
	assert(session.run_state.run_satisfaction_score == 6, "The run satisfaction total should keep the whole day contribution.")
	assert(session.get_status_message().contains("Satisfaction: 6"), "Day-clear status text should mention the completed day satisfaction total.")
	var scheduled_day_two: PackedStringArray = session._to_packed_strings(session.run_state.scheduled_return_customer_ids_by_day.get(2, []))
	assert(scheduled_day_two.has(&"sweet_tooth_customer"), "High satisfaction should schedule Sweet Tooth to return on day 2.")
	assert(session.run_state.customer_ids_already_scheduled_to_return.has(&"sweet_tooth_customer"), "A customer with any scheduled return should be tracked.")
	assert(int(session.run_state.scheduled_return_visit_counts_by_customer.get(&"sweet_tooth_customer", 0)) == 1, "Sweet Tooth should only earn 1 extra visit because day 3 already includes them in the base roster.")

	assert(session.choose_reward(&"reward_add_chocolate"), "A reward should still be choosable after the hunger encounter.")
	assert(session.start_new_run_with_dough(&"sweet_dough"), "Day 2 should still allow selecting a dough.")
	assert(session.run_state.current_day_satisfaction_score == 0, "Starting a new day should reset the day satisfaction total.")
	assert(session.run_state.run_satisfaction_score == 6, "Starting a new day should keep the accumulated run satisfaction total.")
	assert(session.run_state.current_customer_ids.size() == 3, "Day 2 should include the returning customer alongside the authored roster.")
	var returning_customers: int = 0
	for customer in session.combat_state.active_customers:
		if customer.is_returning_visit():
			returning_customers += 1
	assert(returning_customers == 1, "Exactly one customer on day 2 should be marked as returning.")

func _test_multi_day_return_scheduling() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	session.run_state.day_number = 1

	var loyal_def: CustomerDef = session.content_library.get_customer(&"sweet_tooth_customer").duplicate(true) as CustomerDef
	loyal_def.customer_id = &"loyal_guest"
	loyal_def.display_name = "Loyal Guest"
	session.content_library.customers[loyal_def.customer_id] = loyal_def

	var loyal_customer: CustomerInstance = CustomerInstance.new()
	loyal_customer.reset_from_def(loyal_def)
	loyal_customer.satisfaction_score = CustomerInstance.EXTREMELY_SATISFIED_THRESHOLD
	assert(session._schedule_customer_returns(loyal_customer) == 2, "An extremely satisfied customer with no roster conflicts should be scheduled onto two future days.")
	assert(int(session.run_state.scheduled_return_visit_counts_by_customer.get(&"loyal_guest", 0)) == 2, "Return counts should track both scheduled future visits.")
	var scheduled_day_two: PackedStringArray = session._to_packed_strings(session.run_state.scheduled_return_customer_ids_by_day.get(2, []))
	var scheduled_day_three: PackedStringArray = session._to_packed_strings(session.run_state.scheduled_return_customer_ids_by_day.get(3, []))
	assert(scheduled_day_two.has(&"loyal_guest"), "The earliest available future day should get the first return visit.")
	assert(scheduled_day_three.has(&"loyal_guest"), "The next available future day should get the second return visit.")
	assert(session._schedule_customer_returns(loyal_customer) == 0, "Customers should not exceed the cap of two extra return visits in a run.")

	var regular_customer: CustomerInstance = CustomerInstance.new()
	regular_customer.reset_from_def(session.content_library.get_customer(&"starter_regular"))
	regular_customer.satisfaction_score = CustomerInstance.EXTREMELY_SATISFIED_THRESHOLD
	assert(session._schedule_customer_returns(regular_customer) == 0, "No extra return should be scheduled if every valid future day is already occupied or in the base roster.")

func _test_decoration_gifts() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]

	var gifting_def: CustomerDef = session.content_library.get_customer(&"starter_regular").duplicate(true) as CustomerDef
	gifting_def.customer_id = &"gift_tester"
	gifting_def.display_name = "Gift Tester"
	gifting_def.gift_decoration_ids = PackedStringArray(["counter_flowers", "pastry_shelf"])
	session.content_library.customers[gifting_def.customer_id] = gifting_def

	var gifting_customer: CustomerInstance = CustomerInstance.new()
	gifting_customer.reset_from_def(gifting_def)
	gifting_customer.satisfaction_score = CustomerInstance.EXTREMELY_SATISFIED_THRESHOLD
	assert(session._maybe_grant_customer_decoration_gift(gifting_customer) == &"counter_flowers", "Extremely satisfied customers should grant the first unowned decoration from their pool.")
	assert(session.get_profile_state().owned_decoration_ids.has(&"counter_flowers"), "Gifted decorations should become permanently owned immediately.")
	assert(session.run_state.day_gifted_decoration_ids.has(&"counter_flowers"), "Gifted decorations should be tracked for the current day.")
	assert(session.run_state.gifted_decoration_ids_this_run.has(&"counter_flowers"), "Gifted decorations should also be tracked across the run.")
	assert(session._maybe_grant_customer_decoration_gift(gifting_customer) == &"", "The same customer should only be able to gift once per run.")

	var second_gifter_def: CustomerDef = gifting_def.duplicate(true) as CustomerDef
	second_gifter_def.customer_id = &"gift_tester_two"
	second_gifter_def.display_name = "Gift Tester Two"
	session.content_library.customers[second_gifter_def.customer_id] = second_gifter_def
	var second_gifter: CustomerInstance = CustomerInstance.new()
	second_gifter.reset_from_def(second_gifter_def)
	second_gifter.satisfaction_score = CustomerInstance.EXTREMELY_SATISFIED_THRESHOLD
	assert(session._maybe_grant_customer_decoration_gift(second_gifter) == &"pastry_shelf", "Owned decorations should be skipped in favor of the next valid gift in the pool.")
	assert(session.get_profile_state().owned_decoration_ids.has(&"pastry_shelf"), "Skipping owned gifts should still award the next valid decoration.")

	var exhausted_gifter_def: CustomerDef = gifting_def.duplicate(true) as CustomerDef
	exhausted_gifter_def.customer_id = &"gift_tester_three"
	exhausted_gifter_def.display_name = "Gift Tester Three"
	session.content_library.customers[exhausted_gifter_def.customer_id] = exhausted_gifter_def
	var exhausted_gifter: CustomerInstance = CustomerInstance.new()
	exhausted_gifter.reset_from_def(exhausted_gifter_def)
	exhausted_gifter.satisfaction_score = CustomerInstance.EXTREMELY_SATISFIED_THRESHOLD
	assert(session._maybe_grant_customer_decoration_gift(exhausted_gifter) == &"", "No decoration should be granted once every gift in the pool is already owned.")

func _test_social_and_unknown_talents() -> void:
	var social_setup: Array = _new_session()
	var social_session: SessionService = social_setup[0]
	var social_queue: EffectQueueService = social_setup[1]
	assert(social_session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should start for the Social talent test.")
	social_session.player_state.energy = 10
	social_session.deck_state.draw_pile.clear()
	social_session.deck_state.discard_pile.clear()
	social_session.deck_state.hand.clear()
	social_session.deck_state.hand.append(social_session.content_library.build_card_instance(&"starter_small_talk"))
	var patience_before_talk: int = social_session.combat_state.active_customers[0].current_patience
	assert(social_session.play_card_from_hand(0, [], social_queue), "Small Talk should resolve successfully.")
	assert(social_session.combat_state.active_customers[0].current_patience == patience_before_talk + 1, "Social customers should gain 1 patience when talked to.")

	var unknown_setup: Array = _new_session()
	var unknown_session: SessionService = unknown_setup[0]
	var unknown_queue: EffectQueueService = unknown_setup[1]
	assert(unknown_session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should also start for the unknown talent test.")
	unknown_session.player_state.energy = 10
	unknown_session.deck_state.draw_pile.clear()
	unknown_session.deck_state.discard_pile.clear()
	unknown_session.deck_state.hand.clear()
	unknown_session.deck_state.hand.append(unknown_session.content_library.build_card_instance(&"starter_small_talk"))
	var custom_def: CustomerDef = unknown_session.content_library.get_customer(&"sweet_tooth_customer").duplicate(true) as CustomerDef
	custom_def.talent_ids = PackedStringArray(["mysterious"])
	var custom_customer: CustomerInstance = CustomerInstance.new()
	custom_customer.reset_from_def(custom_def)
	unknown_session.combat_state.active_customers.clear()
	unknown_session.combat_state.active_customers.append(custom_customer)
	unknown_session.combat_state.focused_customer_index = 0
	var unknown_patience_before: int = custom_customer.current_patience
	assert(unknown_session.play_card_from_hand(0, [], unknown_queue), "Cards should still play even when a customer has an unknown talent id.")
	assert(custom_customer.current_patience == unknown_patience_before, "Unknown talents should safely resolve as no-ops.")

func _test_day_three_cannot_schedule_boss_return() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	session.run_state.day_number = 3
	var customer: CustomerInstance = CustomerInstance.new()
	customer.reset_from_def(session.content_library.get_customer(&"starter_regular"))
	customer.satisfaction_score = CustomerInstance.EXTREMELY_SATISFIED_THRESHOLD
	assert(not session._maybe_schedule_customer_return(customer), "Customers should not be scheduled onto the boss day.")
	assert(session.run_state.scheduled_return_customer_ids_by_day.is_empty(), "No future return slots should be filled when only the boss day remains.")
	assert(session.run_state.scheduled_return_visit_counts_by_customer.is_empty(), "The visit-count tracker should remain empty when nothing can be scheduled.")

func _test_summary_message_includes_satisfaction_and_gifts() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	session.run_state.day_number = 2
	session.player_state.reputation = 3
	session.player_state.tips = 5
	session.run_state.run_satisfaction_score = 11
	session.run_state.gifted_decoration_ids_this_run = PackedStringArray(["counter_flowers"])
	session._finish_run(true, "Test complete.")
	assert(session.run_state.summary_message.contains("Satisfaction: 11"), "The summary should mention the total run satisfaction score.")
	assert(session.run_state.summary_message.contains("Counter Flowers"), "The summary should mention gifted decoration names.")

func _test_new_run_resets_loyalty_tracking_but_keeps_owned_decorations() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	assert(session.meta_profile_service.grant_decoration(&"counter_flowers"), "The profile should accept directly granted decorations.")
	session.run_state.scheduled_return_customer_ids_by_day[2] = PackedStringArray(["starter_regular"])
	session.run_state.scheduled_return_visit_counts_by_customer[&"starter_regular"] = 1
	session.run_state.customer_ids_already_scheduled_to_return = PackedStringArray(["starter_regular"])
	session.run_state.customer_ids_who_gifted_decoration_this_run = PackedStringArray(["sweet_tooth_customer"])
	session.run_state.day_gifted_decoration_ids = PackedStringArray(["counter_flowers"])
	session.run_state.gifted_decoration_ids_this_run = PackedStringArray(["counter_flowers"])
	session.run_state.run_satisfaction_score = 9
	session.run_state.run_phase = GameEnums.RunPhase.COMPLETE
	session.run_state.day_number = 4
	assert(session.start_new_run_with_dough(&"sweet_dough"), "A new run should still be able to start after the previous run ends.")
	assert(session.run_state.scheduled_return_customer_ids_by_day.is_empty(), "Starting a new run should clear scheduled return visits.")
	assert(session.run_state.scheduled_return_visit_counts_by_customer.is_empty(), "Starting a new run should clear scheduled return visit counts.")
	assert(session.run_state.customer_ids_already_scheduled_to_return.is_empty(), "Starting a new run should clear the scheduled-customer tracker.")
	assert(session.run_state.customer_ids_who_gifted_decoration_this_run.is_empty(), "Starting a new run should clear the gifted-customer tracker.")
	assert(session.run_state.gifted_decoration_ids_this_run.is_empty(), "Starting a new run should clear the run gift summary.")
	assert(session.run_state.run_satisfaction_score == 0, "Starting a new run should reset the run satisfaction total.")
	assert(session.get_profile_state().owned_decoration_ids.has(&"counter_flowers"), "Owned decorations should persist across runs.")
