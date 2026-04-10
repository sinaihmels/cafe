extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_card_preview_extraction()
	_test_tag_catalog_coverage()
	await _test_hand_card_chip_rendering()
	_test_pastry_feedback_events()
	await _test_encounter_overlay_survives_rerender()
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

func _test_card_preview_extraction() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	var chocolate_card: CardDef = session.content_library.get_card(&"reward_chocolate")
	var chocolate_previews: Array[PastryTagPreview] = chocolate_card.get_pastry_tag_previews()
	assert(chocolate_previews.size() == 4, "Chocolate should preview four pastry tag chips.")
	assert(chocolate_previews[0].tag_id == &"sweet" and not chocolate_previews[0].is_conditional, "Chocolate should preview Sweet first as a guaranteed tag.")
	assert(chocolate_previews[1].tag_id == &"chocolaty" and not chocolate_previews[1].is_conditional, "Chocolate should preview Chocolaty as a guaranteed tag.")
	assert(chocolate_previews[2].tag_id == &"luxurious" and not chocolate_previews[2].is_conditional, "Chocolate should preview Luxurious as a guaranteed tag.")
	assert(chocolate_previews[3].tag_id == &"pretty" and not chocolate_previews[3].is_conditional, "Chocolate should preview Pretty as a guaranteed tag.")

	var egg_wash_card: CardDef = session.content_library.get_card(&"starter_egg_wash")
	var egg_wash_previews: Array[PastryTagPreview] = egg_wash_card.get_pastry_tag_previews()
	assert(egg_wash_previews.size() == 2, "Egg Wash should preview one guaranteed and one conditional tag.")
	assert(egg_wash_previews[0].tag_id == &"shiny" and not egg_wash_previews[0].is_conditional, "Egg Wash should always preview Shiny.")
	assert(egg_wash_previews[1].tag_id == &"pretty" and egg_wash_previews[1].is_conditional, "Egg Wash should preview Pretty as a conditional tag.")
	assert(egg_wash_previews[1].condition_text == "if warm", "Egg Wash should label the Pretty preview with the warm condition.")

	var sugar_glaze_card: CardDef = session.content_library.get_card(&"starter_sugar_glaze")
	var sugar_glaze_previews: Array[PastryTagPreview] = sugar_glaze_card.get_pastry_tag_previews()
	assert(sugar_glaze_previews.size() == 5, "Sugar Glaze should preview four guaranteed tags plus one conditional tag.")
	assert(sugar_glaze_previews[4].tag_id == &"sticky" and sugar_glaze_previews[4].is_conditional, "Sugar Glaze should preview Sticky as its conditional tag.")
	assert(sugar_glaze_previews[4].condition_text == "if not warm", "Sugar Glaze should label Sticky with the cold-pastry condition.")

	var focus_card: CardDef = session.content_library.get_card(&"starter_focus")
	assert(focus_card.get_pastry_tag_previews().is_empty(), "Focus should not preview pastry tags.")
	var serve_card: CardDef = session.content_library.get_card(&"starter_serve")
	assert(serve_card.get_pastry_tag_previews().is_empty(), "Serve should not preview pastry tags.")

func _test_tag_catalog_coverage() -> void:
	var expected_tags: PackedStringArray = PackedStringArray([
		"sweet",
		"chocolaty",
		"savory",
		"salty",
		"flaky",
		"shiny",
		"creamy",
		"luxurious",
		"pretty",
		"sticky",
		"fruity",
		"tangy",
		"airy",
	])
	for raw_tag in expected_tags:
		var tag_id: StringName = StringName(raw_tag)
		assert(UiPastryTagCatalog.has_tag_presentation(tag_id), "UiPastryTagCatalog should define an explicit color treatment for %s." % String(tag_id))

func _test_hand_card_chip_rendering() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	var hand_card_scene: PackedScene = load("res://scenes/ui/components/hand_card_view.tscn")
	var hand_card: HandCardView = hand_card_scene.instantiate()
	get_root().add_child(hand_card)
	await process_frame

	hand_card.size = Vector2(154, 214)
	hand_card.configure(session.content_library.build_card_instance(&"starter_sugar_glaze"), true, false)
	await process_frame

	var chip_flow: FlowContainer = hand_card.get_node("CardContent/LowerBody/PastryTagsFlow")
	assert(chip_flow.visible, "Sugar Glaze should show pastry tag chips.")
	assert(chip_flow.get_child_count() == 5, "Sugar Glaze should render five chips on the hand card.")
	var first_chip_label: Label = chip_flow.get_child(0).get_node("Padding/Body/NameLabel")
	assert(first_chip_label.text == "Sweet", "The first Sugar Glaze chip should be Sweet.")
	var last_chip_condition: Label = chip_flow.get_child(4).get_node("Padding/Body/ConditionLabel")
	assert(last_chip_condition.visible and last_chip_condition.text == "if not warm", "The conditional Sugar Glaze chip should show its condition.")

	hand_card.configure(session.content_library.build_card_instance(&"starter_focus"), true, false)
	await process_frame
	assert(chip_flow.get_child_count() == 0, "Focus should clear all pastry tag chips.")
	assert(not chip_flow.visible, "Focus should hide the pastry tag flow when there are no tag previews.")

	hand_card.queue_free()
	await process_frame

func _test_pastry_feedback_events() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	var event_bus: EventBus = setup[2]
	var effect_queue: EffectQueueService = setup[3]
	var feedback_events: Array[PastryFeedbackEvent] = []
	event_bus.pastry_feedback_requested.connect(func(feedback: PastryFeedbackEvent) -> void:
		feedback_events.append(feedback.duplicate_event())
	)

	assert(session.start_new_run_with_dough(&"sourdough"), "Sourdough should start for pastry feedback tests.")
	session.player_state.energy = 10
	session.deck_state.draw_pile.clear()
	session.deck_state.discard_pile.clear()
	session.deck_state.hand.clear()
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_culture"))
	session.deck_state.hand.append(session.content_library.build_card_instance(&"starter_focus"))

	assert(session.play_card_from_hand(0, [], effect_queue), "Feed Starter should play onto the active pastry.")
	assert(feedback_events.size() == 2, "Feed Starter should emit one tag feedback event and one quality feedback event.")
	assert(feedback_events[0].zone == &"prep" and feedback_events[0].index == 0, "Tag feedback should anchor to the active prep pastry.")
	assert(feedback_events[0].added_tags.size() == 1 and feedback_events[0].added_tags[0] == &"tangy", "Feed Starter should emit Tangy as its added tag.")
	assert(feedback_events[1].quality_delta == 1, "Feed Starter should emit a +1 quality feedback event.")

	assert(session.play_card_from_hand(0, [], effect_queue), "Focus should still resolve successfully.")
	assert(feedback_events.size() == 2, "Focus should not emit pastry feedback because it does not affect a pastry.")

	var state_feedback_events: Array[PastryFeedbackEvent] = []
	var state_setup: Array = _new_session()
	var state_session: SessionService = state_setup[0]
	var state_event_bus: EventBus = state_setup[2]
	state_event_bus.pastry_feedback_requested.connect(func(feedback: PastryFeedbackEvent) -> void:
		state_feedback_events.append(feedback.duplicate_event())
	)
	assert(state_session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should start for the state feedback test.")
	assert(state_session.add_states_to_pastry([], PackedStringArray(["decorated"]), -1, 1), "Direct pastry state updates should succeed for the active pastry.")
	assert(state_feedback_events.size() == 1, "Adding a pastry state should emit exactly one feedback payload.")
	assert(state_feedback_events[0].zone == &"prep" and state_feedback_events[0].index == 0, "State feedback should anchor to the active prep pastry.")
	assert(state_feedback_events[0].added_states.size() == 1 and state_feedback_events[0].added_states[0] == &"decorated", "The state feedback should include Decorated.")
	assert(state_feedback_events[0].quality_delta == 1, "State feedback should preserve its bundled quality delta.")

func _test_encounter_overlay_survives_rerender() -> void:
	var setup: Array = _new_session()
	var session: SessionService = setup[0]
	var event_bus: EventBus = setup[2]
	assert(session.start_new_run_with_dough(&"sweet_dough"), "Sweet Dough should start for the encounter overlay test.")

	var encounter_scene: PackedScene = load("res://scenes/ui/screens/encounter_screen_view.tscn")
	var encounter_screen: EncounterScreenView = encounter_scene.instantiate()
	get_root().add_child(encounter_screen)
	await process_frame

	encounter_screen.size = Vector2(1280, 720)
	encounter_screen.configure_event_bus(event_bus)
	encounter_screen.render(session, EncounterInteractionState.new())
	await process_frame

	var overlay: EncounterEffectOverlayView = encounter_screen.get_node("EncounterEffectOverlayView")
	var overlay_id: int = overlay.get_instance_id()
	event_bus.emit_pastry_feedback_requested(PastryFeedbackEvent.new(
		&"prep",
		0,
		PackedStringArray(["sweet"]),
		PackedStringArray(),
		0
	))
	await process_frame
	assert(overlay.active_feedback_count() == 1, "The encounter overlay should spawn a feedback visual for the prep pastry.")

	encounter_screen.render(session, EncounterInteractionState.new())
	await process_frame
	assert(encounter_screen.get_node("EncounterEffectOverlayView").get_instance_id() == overlay_id, "Encounter re-renders should keep the same overlay node alive.")
	assert(overlay.active_feedback_count() == 1, "Encounter re-renders should not destroy active feedback visuals.")

	encounter_screen.queue_free()
	await process_frame
