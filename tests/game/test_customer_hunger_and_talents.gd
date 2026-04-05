extends SceneTree

func _init() -> void:
	_test_customer_initialization()
	_test_satiation_rules()
	_test_hunger_flow_and_return_scheduling()
	_test_social_and_unknown_talents()
	_test_day_three_cannot_schedule_boss_return()
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
	assert(session.player_state.reputation == starting_reputation, "Partial serves should not pay reputation immediately.")
	assert(session.player_state.tips == starting_tips, "Partial serves should not pay tips immediately.")

	assert(session.play_card_from_hand(0, [], effect_queue), "The second pastry should bake successfully.")
	session.advance_oven()
	assert(session.collect_oven_item(0), "The second pastry should reach the table.")
	assert(session.play_card_from_hand(0, serve_targets, effect_queue), "Serve should finish the hungry customer with a second pastry.")
	assert(session.run_state.screen == GameEnums.Screen.REWARD, "Clearing day 1 should route to the reward screen.")
	assert(session.player_state.reputation == starting_reputation + 2, "Final payout should use the final pastry's reputation score.")
	assert(session.player_state.tips == starting_tips + 7, "Final payout should include both the base tips and accumulated satisfaction tips.")
	var scheduled_day_two: PackedStringArray = session._to_packed_strings(session.run_state.scheduled_return_customer_ids_by_day.get(2, []))
	assert(scheduled_day_two.has(&"sweet_tooth_customer"), "High satisfaction should schedule Sweet Tooth to return on day 2.")
	assert(session.run_state.customer_ids_already_scheduled_to_return.has(&"sweet_tooth_customer"), "A customer should only be scheduled to return once per run.")

	assert(session.choose_reward(&"reward_add_chocolate"), "A reward should still be choosable after the hunger encounter.")
	assert(session.start_new_run_with_dough(&"sweet_dough"), "Day 2 should still allow selecting a dough.")
	assert(session.run_state.current_customer_ids.size() == 3, "Day 2 should include the returning customer alongside the authored roster.")
	var returning_customers: int = 0
	for customer in session.combat_state.active_customers:
		if customer.is_returning_visit():
			returning_customers += 1
	assert(returning_customers == 1, "Exactly one customer on day 2 should be marked as returning.")

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
	customer.satisfaction_score = 4
	assert(not session._maybe_schedule_customer_return(customer), "Customers should not be scheduled onto the boss day.")
	assert(session.run_state.scheduled_return_customer_ids_by_day.is_empty(), "No future return slots should be filled when only the boss day remains.")
