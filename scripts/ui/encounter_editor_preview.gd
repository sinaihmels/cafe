@tool
class_name EncounterEditorPreview
extends RefCounted

const PREVIEW_HAND_CARD_IDS: Array[StringName] = [
	&"starter_butter",
	&"starter_focus",
	&"starter_small_talk",
	&"starter_decorate",
	&"starter_serve",
]
const PREVIEW_DRAW_CARD_IDS: Array[StringName] = [
	&"starter_vanilla",
	&"starter_strawberry",
	&"starter_lemon",
	&"reward_chocolate",
	&"reward_cinnamon",
	&"starter_second_wind",
]
const PREVIEW_DISCARD_CARD_IDS: Array[StringName] = [
	&"starter_mini_cookies",
	&"starter_egg_wash",
	&"starter_proof",
]
const PREVIEW_SELECTED_CARD_INDEX: int = 4

static var _content_library_cache: ContentLibrary

static func build_session() -> SessionService:
	var session: SessionService = SessionService.new()
	session.content_library = _content_library()
	session.player_state.deck_state = session.deck_state
	session.run_state.screen = GameEnums.Screen.ENCOUNTER
	session.run_state.day_number = 2
	session.combat_state.turn_number = 3
	session.combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN
	session.combat_state.focused_customer_index = 2
	session.player_state.max_energy = 3
	session.player_state.energy = 3
	session.player_state.max_stress = 16
	session.player_state.stress = 6
	session.player_state.tips = 12
	session.deck_state.hand = _build_card_instances(PREVIEW_HAND_CARD_IDS)
	session.deck_state.draw_pile = _build_card_instances(PREVIEW_DRAW_CARD_IDS)
	session.deck_state.discard_pile = _build_card_instances(PREVIEW_DISCARD_CARD_IDS)
	session.cafe_state.active_pastry = _build_pastry(
		&"sweet_dough",
		1,
		PackedStringArray(["sweet", "vanilla"]),
		PackedStringArray(["formed"]),
		&"prep"
	)
	session.cafe_state.oven_pastry = _build_pastry(
		&"sweet_dough",
		2,
		PackedStringArray(["sweet", "warm"]),
		PackedStringArray(["proofed", "baked"]),
		&"oven"
	)
	session.cafe_state.oven_mode = &"ready"
	session.cafe_state.oven_turns_remaining = 0
	session.cafe_state.plated_pastries = [
		_build_pastry(
			&"sweet_dough",
			2,
			PackedStringArray(["sweet", "vanilla"]),
			PackedStringArray(["baked", "decorated"]),
			&"table"
		),
		_build_pastry(
			&"laminated_dough",
			1,
			PackedStringArray(["buttery", "warm"]),
			PackedStringArray(["baked"]),
			&"table"
		),
	]
	session.combat_state.active_customers = _build_customers()
	return session

static func build_interaction_state(session: SessionService) -> EncounterInteractionState:
	var interaction_state: EncounterInteractionState = EncounterInteractionState.new()
	interaction_state.focused_customer_index = session.combat_state.focused_customer_index
	if PREVIEW_SELECTED_CARD_INDEX < 0 or PREVIEW_SELECTED_CARD_INDEX >= session.deck_state.hand.size():
		return interaction_state
	var selected_card: CardInstance = session.deck_state.hand[PREVIEW_SELECTED_CARD_INDEX]
	if selected_card == null or selected_card.card_def == null:
		return interaction_state
	interaction_state.pending_card_index = PREVIEW_SELECTED_CARD_INDEX
	interaction_state.pending_rule = selected_card.card_def.targeting_rules
	interaction_state.pending_prompt = session.get_target_prompt(selected_card)
	for raw_target in session.get_valid_targets(selected_card):
		var target_dict: Dictionary = raw_target
		interaction_state.valid_targets.append(EncounterTargetRef.from_dictionary(target_dict.duplicate(true)))
	interaction_state.selected_targets.append(
		EncounterTargetRef.new(&"customer", interaction_state.focused_customer_index)
	)
	return interaction_state

static func build_dialogue_state() -> DialoguePresentationState:
	return DialoguePresentationState.new()

static func _content_library() -> ContentLibrary:
	if _content_library_cache == null:
		_content_library_cache = ContentLibrary.new()
		_content_library_cache.load_all()
	return _content_library_cache

static func _build_card_instances(card_ids: Array[StringName]) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for card_id in card_ids:
		var card: CardInstance = _content_library().build_card_instance(card_id)
		if card != null:
			cards.append(card)
	return cards

static func _build_customers() -> Array[CustomerInstance]:
	var customers: Array[CustomerInstance] = []
	var preview_values: Array[Dictionary] = [
		{
			"id": &"starter_regular",
			"patience": 3,
			"hunger": 1,
			"satisfaction": 1,
		},
		{
			"id": &"sweet_tooth_customer",
			"patience": 2,
			"hunger": 2,
			"satisfaction": 4,
			"returning": true,
		},
		{
			"id": &"fast_customer",
			"patience": 1,
			"hunger": 1,
			"satisfaction": 0,
		},
	]
	for preview_value in preview_values:
		var customer_id: StringName = StringName(preview_value.get("id", &""))
		var customer_def: CustomerDef = _content_library().get_customer(customer_id)
		if customer_def == null:
			continue
		var customer: CustomerInstance = CustomerInstance.new()
		customer.reset_from_def(customer_def)
		customer.current_patience = int(preview_value.get("patience", customer.current_patience))
		customer.remaining_hunger = int(preview_value.get("hunger", customer.remaining_hunger))
		customer.satisfaction_score = int(preview_value.get("satisfaction", customer.satisfaction_score))
		customer.has_return_scheduled = bool(preview_value.get("returning", false))
		if customer.has_return_scheduled:
			customer.mood_flags[&"returning_customer"] = true
		customers.append(customer)
	return customers

static func _build_pastry(
	dough_id: StringName,
	quality: int,
	tags: PackedStringArray,
	states: PackedStringArray,
	zone: StringName
) -> PastryInstance:
	var pastry: PastryInstance = PastryInstance.new()
	var dough: DoughDef = _content_library().get_dough(dough_id)
	pastry.dough_id = dough_id
	pastry.display_name = dough.pastry_display_name if dough != null and dough.pastry_display_name != "" else String(dough_id)
	pastry.art = dough.art if dough != null else null
	pastry.quality = quality
	pastry.base_satiation = dough.base_satiation if dough != null else 1
	pastry.zone = zone
	for raw_tag in tags:
		pastry.add_pastry_tag(StringName(raw_tag))
	for raw_state in states:
		pastry.add_pastry_state(StringName(raw_state))
	return pastry
