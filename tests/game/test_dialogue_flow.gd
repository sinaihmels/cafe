extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_order_dialogue_shows_once_per_customer()
	_test_interaction_branching_targets_the_focused_customer()
	_test_departure_dialogue_blocks_removal_until_finished()
	await _test_dialogue_overlay_smoke()
	quit()

func _new_setup() -> Array:
	var session: SessionService = SessionService.new()
	var meta: MetaProfileService = MetaProfileService.new()
	var event_bus: EventBus = EventBus.new()
	var effect_queue: EffectQueueService = EffectQueueService.new()
	var dialogue_service: DialogueService = DialogueService.new()
	get_root().add_child(dialogue_service)
	session.initialize(meta, event_bus)
	effect_queue.configure(event_bus)
	meta.reset_profile(session.content_library)
	dialogue_service.configure(session, event_bus)
	return [session, meta, event_bus, effect_queue, dialogue_service]

func _cleanup_setup(setup: Array) -> void:
	var dialogue_service: DialogueService = setup[4]
	if dialogue_service != null:
		dialogue_service.clear_dialogue()
		dialogue_service.queue_free()

func _drain_dialogue(dialogue_service: DialogueService, response_indices: Array = []) -> void:
	var safety: int = 0
	var response_cursor: int = 0
	while dialogue_service != null and dialogue_service.has_active_dialogue():
		var state: DialoguePresentationState = dialogue_service.get_presentation_state()
		if state.has_responses():
			var selected_index: int = 0
			if response_cursor < response_indices.size():
				selected_index = response_indices[response_cursor]
			assert(
				selected_index >= 0 and selected_index < state.responses.size(),
				"Selected response index %d should exist for the active dialogue." % selected_index
			)
			dialogue_service.choose_response(selected_index)
			response_cursor += 1
		else:
			dialogue_service.advance_dialogue()
		safety += 1
		assert(safety < 16, "Dialogue should resolve within a small number of steps.")

func _test_order_dialogue_shows_once_per_customer() -> void:
	var setup: Array = _new_setup()
	var session: SessionService = setup[0]
	var dialogue_service: DialogueService = setup[4]

	assert(session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should start for the dialogue order test.")
	var day_one_state: DialoguePresentationState = dialogue_service.get_presentation_state()
	assert(day_one_state.visible, "Encounter start should immediately show an order dialogue.")
	assert(day_one_state.cue == &"order_intro", "Encounter start dialogue should use the order_intro cue.")
	assert(day_one_state.responses.size() == 3, "Sweet Tooth should present three opening responses.")
	_drain_dialogue(dialogue_service, [0])

	var first_customer: CustomerInstance = session.combat_state.active_customers[0]
	assert(bool(first_customer.dialogue_flags.get(&"shared_sweet_tooth", false)), "The selected order response should be remembered on the customer.")
	assert(not session.request_customer_order_dialogue(0), "The same customer should not repeat their order dialogue during the same encounter.")

	session._enter_day(2)
	assert(session.combat_state.active_customers.size() == 2, "Day 2 should spawn two customers for the multi-customer dialogue test.")
	_drain_dialogue(dialogue_service, [0])

	assert(session.request_customer_order_dialogue(1), "A newly focused second customer should be able to show their order dialogue once.")
	var second_customer_state: DialoguePresentationState = dialogue_service.get_presentation_state()
	assert(
		second_customer_state.customer_runtime_id == session.combat_state.active_customers[1].runtime_id,
		"The requested order dialogue should belong to the second customer."
	)
	_drain_dialogue(dialogue_service, [0])
	assert(not session.request_customer_order_dialogue(1), "The second customer should only present their order dialogue once.")

	_cleanup_setup(setup)

func _test_interaction_branching_targets_the_focused_customer() -> void:
	var setup: Array = _new_setup()
	var session: SessionService = setup[0]
	var dialogue_service: DialogueService = setup[4]

	assert(session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should start for the interaction dialogue test.")
	_drain_dialogue(dialogue_service, [0])
	session._enter_day(2)
	_drain_dialogue(dialogue_service, [0])
	assert(session.request_customer_order_dialogue(1), "The second customer should be able to introduce their order.")
	_drain_dialogue(dialogue_service, [0])

	var customer_zero: CustomerInstance = session.combat_state.active_customers[0]
	var customer_one: CustomerInstance = session.combat_state.active_customers[1]
	var patience_zero_before: int = customer_zero.current_patience
	var patience_one_before: int = customer_one.current_patience

	session.combat_state.focused_customer_index = 1
	var small_talk: CardInstance = session.content_library.build_card_instance(&"starter_small_talk")
	session.after_card_played(small_talk, [])

	var interaction_state: DialoguePresentationState = dialogue_service.get_presentation_state()
	assert(interaction_state.visible, "Playing an interaction card should queue dialogue.")
	assert(interaction_state.cue == &"interaction", "Interaction cards should use the interaction cue.")
	assert(interaction_state.customer_runtime_id == customer_one.runtime_id, "The focused customer should speak for untargeted interaction cards.")
	assert(
		interaction_state.text.find("actual update") != -1,
		"The fast customer should branch into their promised-speed interaction line."
	)
	_drain_dialogue(dialogue_service, [0])

	assert(customer_zero.current_patience == patience_zero_before, "The non-focused customer should not receive the dialogue outcome.")
	assert(customer_one.current_patience == patience_one_before + 1, "The chosen response should apply its outcome to the focused customer.")

	_cleanup_setup(setup)

func _test_departure_dialogue_blocks_removal_until_finished() -> void:
	var setup: Array = _new_setup()
	var session: SessionService = setup[0]
	var dialogue_service: DialogueService = setup[4]

	assert(session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should start for the departure dialogue test.")
	_drain_dialogue(dialogue_service, [0])
	session._enter_day(2)
	_drain_dialogue(dialogue_service, [0])

	session.combat_state.active_customers[0].current_patience = 1
	session.combat_state.active_customers[1].current_patience = 3
	assert(session.combat_state.turn_number == 1, "The turn should start on turn 1 before ending the turn.")

	session.end_player_turn()

	var leave_state: DialoguePresentationState = dialogue_service.get_presentation_state()
	assert(leave_state.visible and leave_state.cue == &"leave", "A leaving customer should speak before being removed.")
	assert(not session.is_customer_targetable(0), "A departing customer should stop being targetable immediately.")
	assert(session.combat_state.active_customers.size() == 2, "The departing customer should remain visible until their dialogue finishes.")
	assert(session.combat_state.turn_number == 1, "The turn should not advance until departure dialogue resolves.")

	_drain_dialogue(dialogue_service)

	assert(session.combat_state.active_customers.size() == 1, "The departing customer should be removed after their leave dialogue finishes.")
	assert(session.combat_state.active_customers[0].customer_def.customer_id == &"fast_customer", "The remaining customer should still be in the encounter.")
	assert(session.combat_state.turn_number == 2, "The next player turn should only begin after departure dialogue resolves.")
	assert(session.combat_state.turn_state == GameEnums.TurnState.PLAYER_TURN, "The encounter should return to the player turn after departure dialogue clears.")

	_cleanup_setup(setup)

func _test_dialogue_overlay_smoke() -> void:
	var setup: Array = _new_setup()
	var session: SessionService = setup[0]
	var event_bus: EventBus = setup[2]
	var dialogue_service: DialogueService = setup[4]

	assert(session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should start for the dialogue overlay smoke test.")

	var encounter_scene: PackedScene = load("res://scenes/ui/screens/encounter_screen_view.tscn")
	var encounter_screen: EncounterScreenView = encounter_scene.instantiate()
	get_root().add_child(encounter_screen)
	await process_frame

	encounter_screen.size = Vector2(1280, 720)
	encounter_screen.configure_event_bus(event_bus)
	encounter_screen.render(session, EncounterInteractionState.new(), dialogue_service.get_presentation_state())
	await process_frame

	var overlay: EncounterDialogueOverlayView = encounter_screen.get_node("EncounterDialogueOverlayView")
	var modal_backdrop: ColorRect = overlay.get_node("ModalBackdrop")
	assert(overlay.visible, "The dialogue overlay should render the opening modal dialogue.")
	assert(modal_backdrop != null and modal_backdrop.visible, "Order dialogue should render through the modal presenter.")

	_drain_dialogue(dialogue_service, [0])
	assert(session.begin_customer_departure(0, &"patience_expired"), "The smoke test should be able to begin a departure dialogue.")
	encounter_screen.render(session, EncounterInteractionState.new(), dialogue_service.get_presentation_state())
	await process_frame

	var bubble_panel: PanelContainer = overlay.get_node("BubblePanel")
	var overlay_id: int = overlay.get_instance_id()
	var customer_lane: CustomerLaneView = encounter_screen.get_node("CustomerLaneView")
	var customer_spot: Control = customer_lane.get_customer_spot_control(0)
	assert(bubble_panel.visible, "Departure dialogue should use the anchored bubble presenter.")
	assert(customer_spot != null, "The customer lane should expose the current speaker anchor.")
	assert(
		bubble_panel.position.y + bubble_panel.size.y <= customer_spot.position.y + customer_spot.size.y,
		"The dialogue bubble should anchor at or above the speaking customer."
	)

	encounter_screen.render(session, EncounterInteractionState.new(), dialogue_service.get_presentation_state())
	await process_frame
	assert(overlay.get_instance_id() == overlay_id, "Encounter rerenders should keep the same dialogue overlay alive.")
	assert(bubble_panel.visible, "Encounter rerenders should preserve active dialogue bubbles.")

	encounter_screen.queue_free()
	await process_frame
	_cleanup_setup(setup)
