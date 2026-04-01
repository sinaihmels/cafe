class_name RunDirector
extends Node

@export_node_path("DemoView") var view_path: NodePath

@onready var _view: DemoView = get_node(view_path) as DemoView

var _content: DemoContentLibrary = DemoContentLibrary.new()
var _run_state: DemoRunState = DemoRunState.new()
var _player_state: DemoPlayerState = DemoPlayerState.new()
var _encounter_state: DemoEncounterState = DemoEncounterState.new()
var _selected_dough: DemoDoughDef

var _food_composer: FoodComposer
var _demand_matcher: DemandMatcher
var _card_engine: CardEngine
var _customer_ai: CustomerAI
var _progression_director: ProgressionDirector
var _encounter_director: EncounterDirector

var _shop_pending_after_reward: bool = false

func _ready() -> void:
	_content.load_all()
	_connect_view()
	_enter_dough_select()

func start_run(dough_id: StringName) -> void:
	var picked_dough: DemoDoughDef = _content.get_dough(dough_id)
	if picked_dough == null:
		_set_status("Dough data is missing.")
		_refresh_view()
		return
	_selected_dough = picked_dough
	_run_state = DemoRunState.new()
	_run_state.run_seed = int(Time.get_unix_time_from_system())
	_run_state.phase = DemoEnums.RunPhase.BOOT
	_run_state.encounter_index = 0
	_run_state.tips = 0
	_run_state.won = false
	_run_state.lost = false
	_run_state.selected_dough_id = dough_id
	_player_state = DemoPlayerState.new()
	_player_state.stress = 16
	_player_state.max_stress = 16
	_player_state.max_mana = 3
	_player_state.mana = 3
	_player_state.equipment_ids.clear()
	_player_state.master_deck_ids = picked_dough.start_deck.duplicate()
	_player_state.deck_state = DemoDeckState.new()
	_encounter_state = DemoEncounterState.new()
	_setup_systems(_run_state.run_seed)
	_set_status("%s selected. The bakery opens for service." % picked_dough.name)
	_start_next_encounter()

func advance_phase() -> void:
	match _run_state.phase:
		DemoEnums.RunPhase.BOSS:
			if _run_state.current_encounter != null:
				_start_encounter(_run_state.current_encounter)
		DemoEnums.RunPhase.SUMMARY, DemoEnums.RunPhase.GAME_OVER:
			_enter_dough_select()
		_:
			pass

func play_card(hand_index: int, target_payload: Dictionary = {}) -> void:
	if _run_state.phase != DemoEnums.RunPhase.ENCOUNTER:
		return
	var result: Dictionary = _encounter_director.play_card(
		hand_index,
		target_payload,
		_player_state,
		_encounter_state,
		_selected_dough.passive_rules
	)
	_run_state.tips += int(result.get("tips_delta", 0))
	_set_status(String(result.get("message", "")))
	_refresh_view()

func end_turn() -> void:
	if _run_state.phase != DemoEnums.RunPhase.ENCOUNTER:
		return
	var result: Dictionary = _encounter_director.resolve_end_turn(
		_player_state,
		_encounter_state,
		_selected_dough.passive_rules
	)
	_set_status(String(result.get("message", "Turn ended.")))
	if _encounter_state.completed:
		_handle_encounter_end(result)
		return
	_refresh_view()

func serve_dish() -> void:
	if _run_state.phase != DemoEnums.RunPhase.ENCOUNTER:
		return
	var result: Dictionary = _encounter_director.serve_dish(_player_state, _encounter_state)
	if bool(result.get("success", false)):
		var scalar: float = 1.0
		if _run_state.current_encounter != null:
			scalar = _run_state.current_encounter.difficulty_scalar
		var tips_gain: int = maxi(1, int(round(float(result.get("tips", 0)) * scalar)))
		_run_state.tips += tips_gain
		_set_status("%s Tips +%d." % [String(result.get("message", "")), tips_gain])
	else:
		_set_status(String(result.get("message", "Serve failed.")))
	_handle_encounter_end(result)

func choose_reward(choice_index: int) -> void:
	if _run_state.phase != DemoEnums.RunPhase.REWARD:
		return
	if choice_index < 0 or choice_index >= _run_state.pending_reward_choices.size():
		return
	var reward: DemoRewardDef = _run_state.pending_reward_choices[choice_index]
	var message: String = _progression_director.apply_reward(reward, _run_state, _player_state)
	_run_state.pending_reward_choices.clear()
	if _shop_pending_after_reward:
		_open_shop_phase("Reward chosen. %s" % message)
		return
	_set_status("Reward chosen. %s" % message)
	_start_next_encounter()

func buy_shop_offer(offer_index: int) -> void:
	if _run_state.phase != DemoEnums.RunPhase.SHOP:
		return
	if offer_index < 0 or offer_index >= _run_state.pending_shop_offers.size():
		return
	var offer: DemoRewardDef = _run_state.pending_shop_offers[offer_index]
	if _run_state.tips < offer.cost:
		_set_status("Not enough tips for %s." % offer.label)
		_refresh_view()
		return
	_run_state.tips -= offer.cost
	var message: String = _progression_director.apply_reward(offer, _run_state, _player_state)
	_run_state.pending_shop_offers.remove_at(offer_index)
	_set_status("Purchased: %s" % message)
	_refresh_view()

func continue_from_shop() -> void:
	if _run_state.phase != DemoEnums.RunPhase.SHOP:
		return
	_set_status("Leaving the shop.")
	_start_next_encounter()

func _connect_view() -> void:
	if _view == null:
		return
	_view.dough_selected.connect(_on_dough_selected)
	_view.card_play_requested.connect(_on_card_play_requested)
	_view.end_turn_requested.connect(_on_end_turn_requested)
	_view.serve_requested.connect(_on_serve_requested)
	_view.reward_selected.connect(_on_reward_selected)
	_view.shop_buy_requested.connect(_on_shop_buy_requested)
	_view.shop_continue_requested.connect(_on_shop_continue_requested)
	_view.advance_phase_requested.connect(_on_advance_phase_requested)
	_view.restart_requested.connect(_on_restart_requested)

func _setup_systems(rng_seed: int) -> void:
	_food_composer = FoodComposer.new()
	_demand_matcher = DemandMatcher.new()
	_card_engine = CardEngine.new(_food_composer)
	_customer_ai = CustomerAI.new()
	_progression_director = ProgressionDirector.new(_content, rng_seed)
	_encounter_director = EncounterDirector.new(
		_card_engine,
		_food_composer,
		_demand_matcher,
		_customer_ai
	)

func _enter_dough_select() -> void:
	_run_state = DemoRunState.new()
	_run_state.phase = DemoEnums.RunPhase.DOUGH_SELECT
	_run_state.status_message = "Choose a dough to start the demo run."
	_player_state = DemoPlayerState.new()
	_encounter_state = DemoEncounterState.new()
	_selected_dough = null
	_shop_pending_after_reward = false
	_refresh_view()

func _start_next_encounter() -> void:
	if _player_state.stress <= 0:
		_finalize_run(false, "Burnout hit zero stress. Run failed.")
		return
	_run_state.encounter_index += 1
	var encounter_def: DemoEncounterDef = _content.get_encounter(_run_state.encounter_index)
	if encounter_def == null:
		_finalize_run(true, "All customers served. Demo complete.")
		return
	_run_state.current_encounter = encounter_def
	if encounter_def.boss:
		_run_state.phase = DemoEnums.RunPhase.BOSS
		_set_status("Final customer incoming. Prepare your best dish.")
		_refresh_view()
		return
	_start_encounter(encounter_def)

func _start_encounter(encounter_def: DemoEncounterDef) -> void:
	var customer_def: DemoCustomerDef = _pick_customer(encounter_def)
	if customer_def == null:
		_finalize_run(false, "No customer definition found for encounter %d." % encounter_def.index)
		return
	_run_state.phase = DemoEnums.RunPhase.ENCOUNTER
	var deck_defs: Array[DemoCardDef] = _build_master_deck_defs()
	_encounter_director.start_encounter(
		encounter_def,
		customer_def,
		_player_state,
		_encounter_state,
		deck_defs,
		_selected_dough.passive_rules
	)
	_set_status(_encounter_state.status_message)
	_refresh_view()

func _pick_customer(encounter_def: DemoEncounterDef) -> DemoCustomerDef:
	if encounter_def == null or encounter_def.customer_pool.is_empty():
		return null
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _run_state.run_seed + encounter_def.index * 997
	var picked_id: StringName = StringName(
		encounter_def.customer_pool[rng.randi_range(0, encounter_def.customer_pool.size() - 1)]
	)
	return _content.get_customer(picked_id)

func _build_master_deck_defs() -> Array[DemoCardDef]:
	var output: Array[DemoCardDef] = []
	for card_id_value in _player_state.master_deck_ids:
		var card_id: StringName = StringName(card_id_value)
		var card_def: DemoCardDef = _content.get_card(card_id)
		if card_def != null:
			output.append(card_def)
	return output

func _handle_encounter_end(result: Dictionary) -> void:
	if _player_state.stress <= 0:
		_finalize_run(false, "Burnout reached zero stress.")
		return
	if _run_state.current_encounter != null and _run_state.current_encounter.boss:
		if _encounter_state.success:
			_finalize_run(true, "You satisfied the final critic.")
		else:
			_finalize_run(false, "The final critic was not impressed.")
		return
	_shop_pending_after_reward = _run_state.current_encounter != null and _run_state.current_encounter.shop_after
	if _encounter_state.success:
		_run_state.phase = DemoEnums.RunPhase.REWARD
		_run_state.pending_reward_choices = _progression_director.get_reward_choices(
			_run_state.encounter_index,
			_player_state
		)
		_set_status("Encounter cleared. Choose one reward.")
		_refresh_view()
		return
	if _shop_pending_after_reward:
		_open_shop_phase("%s Shop is still available." % String(result.get("message", "Encounter failed.")))
		return
	_set_status("%s Moving to next encounter." % String(result.get("message", "Encounter failed.")))
	_start_next_encounter()

func _open_shop_phase(status_message: String) -> void:
	_run_state.phase = DemoEnums.RunPhase.SHOP
	_run_state.pending_shop_offers = _progression_director.get_shop_offers(
		_run_state.encounter_index,
		_player_state
	)
	_shop_pending_after_reward = false
	_set_status(status_message)
	_refresh_view()

func _finalize_run(won: bool, message: String) -> void:
	_run_state.won = won
	_run_state.lost = not won
	_run_state.phase = DemoEnums.RunPhase.SUMMARY if won else DemoEnums.RunPhase.GAME_OVER
	_run_state.summary_message = message
	_set_status(message)
	_refresh_view()

func _set_status(message: String) -> void:
	_run_state.status_message = message
	_encounter_state.status_message = message

func _refresh_view() -> void:
	if _view == null:
		return
	_view.render(_build_view_model())

func _build_view_model() -> Dictionary:
	var dough_choices: Array[Dictionary] = []
	for dough_value in _content.doughs.values():
		var dough: DemoDoughDef = dough_value
		if dough == null:
			continue
		dough_choices.append({
			"id": dough.id,
			"name": dough.name,
			"passive_rules": dough.passive_rules,
			"deck_count": dough.start_deck.size(),
		})
	var hand_cards: Array[Dictionary] = []
	if _player_state.deck_state != null:
		for card_index in range(_player_state.deck_state.hand.size()):
			var card: DemoCardInstance = _player_state.deck_state.hand[card_index]
			if card == null or card.card_def == null:
				continue
			hand_cards.append({
				"index": card_index,
				"id": card.card_def.id,
				"name": card.get_card_name(),
				"cost": card.get_cost(),
				"description": card.get_description(),
				"can_play": _player_state.mana >= card.get_cost(),
			})
	var reward_choices: Array[Dictionary] = []
	for reward_index in range(_run_state.pending_reward_choices.size()):
		var reward: DemoRewardDef = _run_state.pending_reward_choices[reward_index]
		reward_choices.append({
			"index": reward_index,
			"label": reward.label,
			"description": reward.description,
			"cost": reward.cost,
		})
	var shop_offers: Array[Dictionary] = []
	for offer_index in range(_run_state.pending_shop_offers.size()):
		var offer: DemoRewardDef = _run_state.pending_shop_offers[offer_index]
		shop_offers.append({
			"index": offer_index,
			"label": offer.label,
			"description": offer.description,
			"cost": offer.cost,
			"affordable": _run_state.tips >= offer.cost,
		})
	var customer_text: String = "No active customer."
	var active_customer_id: StringName = &""
	if _encounter_state.active_customer != null and _encounter_state.active_customer.customer_def != null:
		active_customer_id = _encounter_state.active_customer.customer_def.id
		customer_text = "%s | Patience: %d | Request: %s" % [
			_encounter_state.active_customer.get_display_name(),
			_encounter_state.active_customer.current_patience,
			_format_demand_text(_encounter_state.active_customer.customer_def.demands),
		]
	var food_text: String = _encounter_state.food_state.describe()
	var oven_text: String = _build_oven_text(_encounter_state.food_state)
	var dish_stage_key: StringName = _build_dish_stage_key(_encounter_state.food_state)
	var oven_stage_key: StringName = _build_oven_stage_key(_encounter_state.food_state)
	var selected_dough_id: StringName = &""
	if _selected_dough != null:
		selected_dough_id = _selected_dough.id
	return {
		"phase": _run_state.phase,
		"phase_name": _phase_name(_run_state.phase),
		"status_message": _run_state.status_message,
		"summary_message": _run_state.summary_message,
		"encounter_index": _run_state.encounter_index,
		"tips": _run_state.tips,
		"stress": _player_state.stress,
		"max_stress": _player_state.max_stress,
		"mana": _player_state.mana,
		"max_mana": _player_state.max_mana,
		"dough_choices": dough_choices,
		"selected_dough_id": selected_dough_id,
		"selected_dough_name": _selected_dough.name if _selected_dough != null else "",
		"active_customer_id": active_customer_id,
		"dish_stage_key": dish_stage_key,
		"oven_stage_key": oven_stage_key,
		"hand_cards": hand_cards,
		"customer_text": customer_text,
		"food_text": food_text,
		"oven_text": oven_text,
		"reward_choices": reward_choices,
		"shop_offers": shop_offers,
		"can_serve": (
			_run_state.phase == DemoEnums.RunPhase.ENCOUNTER
			and not _encounter_state.completed
			and not _encounter_state.food_state.tags.is_empty()
		),
		"can_end_turn": _run_state.phase == DemoEnums.RunPhase.ENCOUNTER and not _encounter_state.completed,
	}

func _phase_name(phase: int) -> String:
	match phase:
		DemoEnums.RunPhase.BOOT:
			return "Boot"
		DemoEnums.RunPhase.DOUGH_SELECT:
			return "Dough Select"
		DemoEnums.RunPhase.ENCOUNTER:
			return "Encounter"
		DemoEnums.RunPhase.REWARD:
			return "Reward"
		DemoEnums.RunPhase.SHOP:
			return "Shop"
		DemoEnums.RunPhase.BOSS:
			return "Boss"
		DemoEnums.RunPhase.SUMMARY:
			return "Summary"
		DemoEnums.RunPhase.GAME_OVER:
			return "Game Over"
		_:
			return "Unknown"

func _format_demand_text(demands: Array[DemoDemandRule]) -> String:
	if demands.is_empty():
		return "Any"
	var rule: DemoDemandRule = demands[0]
	var required: String = _join_packed_strings(rule.required_tags)
	if required == "":
		required = "Any"
	var forbidden: String = _join_packed_strings(rule.forbidden_tags)
	if forbidden == "":
		return required
	return "%s (avoid: %s)" % [required, forbidden]

func _build_oven_text(food_state: DemoFoodState) -> String:
	if food_state == null or food_state.tags.is_empty():
		return "Oven\nStage: Empty\nContents: -\nQuality: 0"
	var ingredient_tags: Array[String] = []
	for raw_tag_value in food_state.tags:
		var raw_tag: String = raw_tag_value
		if raw_tag == "mixed" or raw_tag == "baked":
			continue
		ingredient_tags.append(raw_tag.capitalize())
	var stage: String = "Prep"
	if food_state.has_tag(&"baked"):
		stage = "Ready (Baked)"
	elif food_state.has_tag(&"mixed"):
		stage = "Mixed (Needs Bake)"
	var contents_text: String = "No ingredients"
	if not ingredient_tags.is_empty():
		ingredient_tags.sort()
		contents_text = _join_string_array(ingredient_tags)
	return "Oven\nStage: %s\nContents: %s\nQuality: %d" % [stage, contents_text, food_state.quality]

func _build_dish_stage_key(food_state: DemoFoodState) -> StringName:
	if food_state == null or food_state.tags.is_empty():
		return &"dough_area_empty"
	if food_state.has_tag(&"baked"):
		return &"baked_pastry"
	if food_state.has_tag(&"mixed"):
		return &"formed_pastry"
	return &"dough_with_items"

func _build_oven_stage_key(food_state: DemoFoodState) -> StringName:
	if food_state == null or food_state.tags.is_empty():
		return &"oven_empty"
	if food_state.has_tag(&"baked"):
		return &"oven_ready"
	if food_state.has_tag(&"mixed"):
		return &"oven_needs_bake"
	return &"oven_loaded"

func _join_string_array(values: Array[String]) -> String:
	var output: String = ""
	for index in range(values.size()):
		if index > 0:
			output += ", "
		output += values[index]
	return output

func _join_packed_strings(values: PackedStringArray) -> String:
	var output: String = ""
	for index in range(values.size()):
		if index > 0:
			output += ", "
		output += String(values[index])
	return output

func _on_dough_selected(dough_id: StringName) -> void:
	start_run(dough_id)

func _on_card_play_requested(hand_index: int) -> void:
	play_card(hand_index, {})

func _on_end_turn_requested() -> void:
	end_turn()

func _on_serve_requested() -> void:
	serve_dish()

func _on_reward_selected(choice_index: int) -> void:
	choose_reward(choice_index)

func _on_shop_buy_requested(offer_index: int) -> void:
	buy_shop_offer(offer_index)

func _on_shop_continue_requested() -> void:
	continue_from_shop()

func _on_advance_phase_requested() -> void:
	advance_phase()

func _on_restart_requested() -> void:
	_enter_dough_select()
