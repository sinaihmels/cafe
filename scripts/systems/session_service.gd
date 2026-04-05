class_name SessionService
extends Node

const DEFAULT_HAND_SIZE: int = 5
const BASE_STRESS: int = 16
const BASE_ENERGY: int = 3
const BASE_PREP_CAPACITY: int = 4
const BASE_TABLE_CAPACITY: int = 3
const BASE_OVEN_CAPACITY: int = 1
const ENCOUNTER_CUSTOMERS: Dictionary = {
	1: [&"sweet_tooth_customer"],
	2: [&"starter_regular", &"fast_customer"],
	3: [&"sweet_tooth_customer", &"quality_customer"],
	4: [&"critic_boss"],
}
const DAY_REWARD_IDS: Dictionary = {
	1: [&"reward_add_chocolate", &"reward_flash_bake", &"reward_focus_buff"],
}
const DAY_SHOP_OFFER_IDS: Dictionary = {
	2: [&"offer_chocolate", &"offer_cinnamon", &"offer_second_wind_buff"],
}
const DECORATION_SLOT_NAMES: Array[String] = ["wall", "counter", "floor", "shelf", "exterior"]

var content_library: ContentLibrary = ContentLibrary.new()
var meta_profile_service: MetaProfileService
var event_bus: EventBus

var run_state: RunState = RunState.new()
var combat_state: CombatState = CombatState.new()
var player_state: PlayerState = PlayerState.new()
var cafe_state: CafeState = CafeState.new()
var deck_state: DeckState = DeckState.new()

var _last_status_message: String = ""

func initialize(profile_service: MetaProfileService, event_bus_ref: EventBus) -> void:
	meta_profile_service = profile_service
	event_bus = event_bus_ref
	content_library.load_all()
	if meta_profile_service != null:
		meta_profile_service.load_or_create(content_library)
	_reset_runtime_state()
	go_to_title()

func _reset_runtime_state() -> void:
	run_state = RunState.new()
	combat_state = CombatState.new()
	player_state = PlayerState.new()
	cafe_state = CafeState.new()
	deck_state = DeckState.new()
	player_state.deck_state = deck_state
	player_state.equipped_equipment_ids = PackedStringArray()
	_last_status_message = ""

func go_to_title() -> void:
	run_state.screen = GameEnums.Screen.TITLE
	run_state.run_phase = GameEnums.RunPhase.IDLE
	run_state.day_number = 0
	run_state.pending_day_number = 0
	run_state.pending_reward_ids.clear()
	run_state.pending_shop_offer_ids.clear()
	run_state.summary_message = ""
	run_state.status_message = ""
	_set_status_message("Welcome back to the bakery. Continue to the cafe hub when you're ready.")

func continue_from_title() -> void:
	open_cafe_hub()

func open_cafe_hub() -> void:
	run_state.screen = GameEnums.Screen.CAFE_HUB
	run_state.run_phase = GameEnums.RunPhase.IDLE
	run_state.pending_day_number = 0
	_set_status_message("Manage the cafe, decorate the shop, equip gear, and start a new run.")

func open_decoration_screen() -> void:
	run_state.screen = GameEnums.Screen.DECORATION
	_set_status_message("Place owned decorations into each cafe slot.")

func close_decoration_screen() -> void:
	open_cafe_hub()

func open_dough_select() -> void:
	_open_dough_select_for_day(1)

func _open_dough_select_for_day(day_number: int) -> void:
	run_state.screen = GameEnums.Screen.DOUGH_SELECT
	run_state.run_phase = GameEnums.RunPhase.PREPARE_RUN
	run_state.pending_day_number = maxi(1, day_number)
	run_state.current_customer_ids.clear()
	_set_status_message("Choose the dough to prep for day %d." % run_state.pending_day_number)

func reset_profile() -> void:
	if meta_profile_service != null:
		meta_profile_service.reset_profile(content_library)
	_reset_runtime_state()
	go_to_title()

func get_profile_state() -> MetaProfileState:
	if meta_profile_service == null:
		return MetaProfileState.new()
	return meta_profile_service.profile_state

func get_available_doughs() -> Array:
	var output: Array = []
	for dough in content_library.doughs.values():
		output.append(dough)
	return output

func get_available_equipment() -> Array:
	var output: Array = []
	for equipment in content_library.equipment.values():
		output.append(equipment)
	return output

func get_available_decorations() -> Array:
	var output: Array = []
	for decoration in content_library.decorations.values():
		output.append(decoration)
	return output

func get_available_shop_upgrades() -> Array:
	var output: Array = []
	for upgrade in content_library.shop_upgrades.values():
		if upgrade != null and upgrade.upgrade_id != &"oven_slot_upgrade" and upgrade.upgrade_id != &"prep_counter_upgrade":
			output.append(upgrade)
	return output

func get_pending_rewards() -> Array:
	var output: Array = []
	for reward_id in run_state.pending_reward_ids:
		var reward: RewardDef = content_library.get_reward(StringName(reward_id))
		if reward != null:
			output.append(reward)
	return output

func get_pending_shop_offers() -> Array:
	var output: Array = []
	for offer_id in run_state.pending_shop_offer_ids:
		var offer: CardOfferDef = content_library.get_offer(StringName(offer_id))
		if offer != null:
			output.append(offer)
	return output

func start_new_run_with_dough(dough_id: StringName) -> bool:
	var profile: MetaProfileState = get_profile_state()
	if not profile.unlocked_dough_ids.has(dough_id):
		_set_status_message("That dough is still locked.")
		return false
	var dough: DoughDef = content_library.get_dough(dough_id)
	if dough == null:
		_set_status_message("Could not load the selected dough.")
		return false
	var next_day_number: int = maxi(1, run_state.pending_day_number)
	var is_new_run: bool = run_state.day_number <= 0 or is_run_over() or run_state.run_phase == GameEnums.RunPhase.IDLE
	if is_new_run:
		_reset_runtime_state()
		run_state.pending_day_number = next_day_number
		_initialize_run_from_dough(dough, profile)
	run_state.selected_dough_id = dough_id
	run_state.run_phase = GameEnums.RunPhase.PREPARE_RUN
	_replace_dough_passives(dough)
	_enter_day(next_day_number)
	return true

func _initialize_run_from_dough(dough: DoughDef, profile: MetaProfileState) -> void:
	player_state.max_stress = BASE_STRESS
	player_state.stress = BASE_STRESS
	player_state.max_energy = BASE_ENERGY
	player_state.energy = BASE_ENERGY
	player_state.starting_hand_size = DEFAULT_HAND_SIZE
	player_state.reputation = 0
	player_state.max_reputation = 0
	player_state.tips = 2
	player_state.master_deck_ids = dough.starting_deck_ids.duplicate()
	player_state.equipped_equipment_ids = profile.equipped_equipment_ids.duplicate()
	cafe_state.serving_table_capacity = BASE_TABLE_CAPACITY
	cafe_state.prep_space_capacity = 1
	cafe_state.oven_capacity = 1
	_reset_cafe_pastry_state()
	_apply_profile_passives(profile)

func _apply_profile_passives(profile: MetaProfileState) -> void:
	for equipment_id in profile.equipped_equipment_ids:
		var equipment: EquipmentDef = content_library.get_equipment(StringName(equipment_id))
		if equipment == null:
			continue
		for modifier_id in equipment.passive_modifier_ids:
			add_passive_modifier(modifier_id, &"equipment", equipment.equipment_id)
	for upgrade_id in profile.purchased_shop_upgrade_ids:
		var upgrade: ShopUpgradeDef = content_library.get_shop_upgrade(StringName(upgrade_id))
		if upgrade == null or upgrade.upgrade_id == &"oven_slot_upgrade" or upgrade.upgrade_id == &"prep_counter_upgrade":
			continue
		for modifier_id in upgrade.passive_modifier_ids:
			if modifier_id == &"oven_mastery_buff" or modifier_id == &"prep_station_buff":
				continue
			add_passive_modifier(modifier_id, &"shop_upgrade", upgrade.upgrade_id)

func _apply_dough_passives(dough: DoughDef) -> void:
	for modifier_id in dough.passive_modifier_ids:
		if modifier_id == &"oven_mastery_buff" or modifier_id == &"prep_station_buff":
			continue
		add_passive_modifier(modifier_id, &"dough", dough.dough_id)

func _replace_dough_passives(dough: DoughDef) -> void:
	_remove_passive_modifiers_by_source_kind(&"dough")
	_apply_dough_passives(dough)

func add_passive_modifier(modifier_id: StringName, source_kind: StringName, source_id: StringName) -> bool:
	return _add_modifier_to_collection(
		player_state.passive_modifiers,
		GameEnums.ModifierTarget.PLAYER,
		modifier_id,
		source_kind,
		source_id,
		-1
	)

func _remove_passive_modifiers_by_source_kind(source_kind: StringName) -> void:
	for index in range(player_state.passive_modifiers.size() - 1, -1, -1):
		var instance: ModifierInstance = player_state.passive_modifiers[index]
		if instance == null or instance.source_kind != source_kind:
			continue
		var modifier_def: ModifierDef = content_library.get_modifier(instance.modifier_id)
		if modifier_def != null:
			_revert_modifier_stats(instance, modifier_def, GameEnums.ModifierTarget.PLAYER)
		player_state.passive_modifiers.remove_at(index)

func _enter_day(day_number: int) -> void:
	var dough: DoughDef = content_library.get_dough(run_state.selected_dough_id)
	if dough == null:
		_set_status_message("Choose a dough before starting the day.")
		return
	var day_customer_roster: Dictionary = _build_day_customer_roster(day_number)
	var day_customer_ids: PackedStringArray = day_customer_roster.get("customer_ids", PackedStringArray())
	var returning_customer_ids: PackedStringArray = day_customer_roster.get("returning_customer_ids", PackedStringArray())
	run_state.day_number = day_number
	run_state.pending_day_number = 0
	run_state.encounter_index = maxi(0, day_number - 1)
	run_state.current_customer_ids = day_customer_ids
	run_state.pending_reward_ids.clear()
	run_state.pending_shop_offer_ids.clear()
	run_state.current_day_satisfaction_score = 0
	run_state.day_gifted_decoration_ids.clear()
	run_state.screen = GameEnums.Screen.ENCOUNTER
	run_state.run_phase = GameEnums.RunPhase.ENCOUNTER
	combat_state.turn_number = 1
	combat_state.turn_state = GameEnums.TurnState.IDLE
	combat_state.focused_customer_index = 0
	combat_state.next_plated_pastry_duplications = 0
	combat_state.skip_next_customer_patience_loss = false
	combat_state.next_warm_serve_bonus = false
	_reset_cafe_pastry_state()
	_rebuild_deck_from_master_ids()
	if not _spawn_fresh_active_pastry():
		return
	combat_state.active_customers = _create_customers(run_state.current_customer_ids, returning_customer_ids)
	begin_player_turn(true)
	var opening_message: String = "Day %d begins with %s ready to shape. Build one pastry at a time and serve each customer before patience runs out." % [day_number, dough.display_name]
	if dough.requires_proofing:
		opening_message = "Day %d begins with %s ready to shape. Proof it, bake it, plate it, and keep the line moving one pastry at a time." % [day_number, dough.display_name]
	_set_status_message(opening_message)

func _build_day_customer_roster(day_number: int) -> Dictionary:
	var customer_ids: PackedStringArray = _to_packed_strings(ENCOUNTER_CUSTOMERS.get(day_number, []))
	var returning_customer_ids: PackedStringArray = PackedStringArray()
	if day_number >= 4:
		return {
			"customer_ids": customer_ids,
			"returning_customer_ids": returning_customer_ids,
		}
	var scheduled_customer_ids: PackedStringArray = _to_packed_strings(run_state.scheduled_return_customer_ids_by_day.get(day_number, []))
	for scheduled_customer_id in scheduled_customer_ids:
		var customer_id: StringName = StringName(scheduled_customer_id)
		if customer_ids.has(customer_id):
			continue
		customer_ids.append(customer_id)
		returning_customer_ids.append(customer_id)
	return {
		"customer_ids": customer_ids,
		"returning_customer_ids": returning_customer_ids,
	}

func _reset_cafe_pastry_state() -> void:
	cafe_state.active_pastry = null
	cafe_state.oven_pastry = null
	cafe_state.plated_pastries.clear()
	cafe_state.oven_mode = &""
	cafe_state.oven_turns_remaining = 0
	cafe_state.prep_items.clear()
	cafe_state.table_items.clear()
	cafe_state.oven_slots.clear()
	_rebuild_oven_slots()

func _spawn_fresh_active_pastry() -> bool:
	if run_state.selected_dough_id == &"":
		return false
	if cafe_state.active_pastry != null:
		return true
	var pastry: PastryInstance = _create_pastry_from_dough(run_state.selected_dough_id)
	if pastry == null:
		_set_status_message("Could not prepare the next pastry.")
		return false
	pastry.zone = &"prep"
	cafe_state.active_pastry = pastry
	return true

func _current_dough_def() -> DoughDef:
	return content_library.get_dough(run_state.selected_dough_id)

func _create_pastry_from_dough(dough_id: StringName) -> PastryInstance:
	var dough: DoughDef = content_library.get_dough(dough_id)
	if dough == null:
		return null
	var pastry: PastryInstance = PastryInstance.new()
	pastry.dough_id = dough.dough_id
	pastry.display_name = dough.pastry_display_name if dough.pastry_display_name != "" else dough.display_name
	pastry.art = dough.art
	pastry.base_satiation = maxi(1, dough.base_satiation)
	pastry.bonus_satiation = 0
	pastry.pastry_tags = dough.starting_pastry_tags.duplicate()
	if dough.requires_proofing:
		pastry.internal_flags[&"requires_proofing"] = true
	return pastry

func _rebuild_deck_from_master_ids() -> void:
	var cards: Array[CardInstance] = []
	for card_id in player_state.master_deck_ids:
		var instance: CardInstance = content_library.build_card_instance(StringName(card_id))
		if instance != null:
			cards.append(instance)
	deck_state.reset_from_cards(cards)

func _create_customers(customer_ids: PackedStringArray, returning_customer_ids: PackedStringArray = PackedStringArray()) -> Array[CustomerInstance]:
	var output: Array[CustomerInstance] = []
	for customer_id in customer_ids:
		var customer_def: CustomerDef = content_library.get_customer(StringName(customer_id))
		if customer_def == null:
			continue
		var customer: CustomerInstance = CustomerInstance.new()
		customer.reset_from_def(customer_def)
		if returning_customer_ids.has(customer_def.customer_id):
			customer.mood_flags[&"returning_customer"] = true
		for status_id in customer_def.starting_status_ids:
			_add_modifier_to_collection(
				customer.active_statuses,
				GameEnums.ModifierTarget.CUSTOMER,
				StringName(status_id),
				&"customer",
				customer_def.customer_id,
				-1
			)
		output.append(customer)
	return output

func begin_player_turn(is_new_day: bool = false) -> void:
	if run_state.screen != GameEnums.Screen.ENCOUNTER:
		return
	combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN
	player_state.reset_turn_energy()
	_tick_pastry_states_turn_start()
	if not is_new_day:
		advance_oven()
	_trigger_player_modifier_hooks(&"turn_start")
	deck_state.draw_to_hand_size(player_state.starting_hand_size)
	if event_bus != null:
		event_bus.emit_turn_started(combat_state.turn_number)

func end_player_turn() -> void:
	if run_state.screen != GameEnums.Screen.ENCOUNTER:
		return
	if combat_state.turn_state != GameEnums.TurnState.PLAYER_TURN:
		return
	combat_state.turn_state = GameEnums.TurnState.CUSTOMER_TURN
	deck_state.discard_all_hand()
	_trigger_player_modifier_hooks(&"turn_end")
	combat_state.next_plated_pastry_duplications = 0
	_process_customer_turn()
	_tick_all_temporary_modifiers()
	if event_bus != null:
		event_bus.emit_turn_ended(combat_state.turn_number)
	if run_state.screen != GameEnums.Screen.ENCOUNTER:
		return
	if player_state.stress <= 0:
		_finish_run(false, "The bakery became too stressful to continue.")
		return
	combat_state.turn_number += 1
	begin_player_turn()

func can_play_card(card: CardInstance) -> bool:
	if card == null:
		return false
	if run_state.screen != GameEnums.Screen.ENCOUNTER:
		return false
	if combat_state.turn_state != GameEnums.TurnState.PLAYER_TURN:
		return false
	if player_state.energy < card.get_cost():
		return false
	return _card_has_required_context(card)

func _card_has_required_context(card: CardInstance) -> bool:
	if card == null or card.card_def == null:
		return false
	match String(card.card_def.card_id):
		"starter_fold":
			return cafe_state.active_pastry != null and not _active_pastry_is_locked_in_oven() and (
				_pastry_matches_token(cafe_state.active_pastry, "laminated_dough")
				or _pastry_matches_token(cafe_state.active_pastry, "butter_applied")
			)
		"reward_chocolate", "reward_cinnamon", "starter_cheese", "starter_culture", "starter_herbs", "starter_tomato_sauce", "starter_vanilla", "starter_strawberry", "starter_lemon", "starter_butter":
			return cafe_state.active_pastry != null and not _active_pastry_is_locked_in_oven()
		"starter_proof":
			return cafe_state.active_pastry != null and _pastry_requires_proofing(cafe_state.active_pastry) and cafe_state.oven_pastry == null
		"starter_bake":
			return _can_bake_current_pastry()
		"reward_flash_bake":
			return _can_flash_bake_current_pastry()
		"starter_decorate", "starter_sugar_glaze", "starter_egg_wash":
			return not cafe_state.plated_pastries.is_empty()
		"starter_serve":
			return not cafe_state.plated_pastries.is_empty() and not combat_state.active_customers.is_empty()
		_:
			return true

func _active_pastry_is_locked_in_oven() -> bool:
	return cafe_state.active_pastry == null or cafe_state.active_pastry.zone != &"prep"

func _pastry_requires_proofing(pastry: PastryInstance) -> bool:
	return pastry != null and bool(pastry.internal_flags.get(&"requires_proofing", false)) and not pastry.has_pastry_state(&"proofed")

func _can_bake_current_pastry() -> bool:
	if cafe_state.active_pastry != null:
		return not _pastry_requires_proofing(cafe_state.active_pastry) and cafe_state.oven_pastry == null
	return cafe_state.oven_pastry != null and cafe_state.oven_mode == &"" and cafe_state.oven_pastry.has_pastry_state(&"proofed")

func _can_flash_bake_current_pastry() -> bool:
	if cafe_state.active_pastry != null:
		return not _pastry_requires_proofing(cafe_state.active_pastry)
	return cafe_state.oven_pastry != null and cafe_state.oven_mode == &"" and cafe_state.oven_pastry.has_pastry_state(&"proofed")

func spend_energy(amount: int) -> void:
	player_state.energy = maxi(0, player_state.energy - amount)

func apply_reputation_delta(amount: int) -> void:
	player_state.reputation = maxi(0, player_state.reputation + amount)
	player_state.max_reputation = maxi(player_state.max_reputation, player_state.reputation)

func is_run_over() -> bool:
	return run_state.run_phase == GameEnums.RunPhase.COMPLETE or run_state.run_phase == GameEnums.RunPhase.FAILED

func build_effect_context(source_card: CardInstance = null, targets: Array = [], source_modifier: ModifierInstance = null) -> EffectContext:
	var context: EffectContext = EffectContext.new()
	context.run_state = run_state
	context.combat_state = combat_state
	context.player_state = player_state
	context.cafe_state = cafe_state
	context.deck_state = deck_state
	context.event_bus = event_bus
	context.session_service = self
	context.content_library = content_library
	context.meta_profile_service = meta_profile_service
	context.source_card = source_card
	context.source_modifier = source_modifier
	context.targets = targets.duplicate(true)
	return context

func get_required_target_count(card: CardInstance) -> int:
	if card == null or card.card_def == null:
		return 0
	match card.card_def.targeting_rules:
		"select_one_customer_and_one_plated_pastry":
			return 2
		"select_one_plated_pastry", "select_one_customer":
			return 1
		_:
			return 0

func get_target_prompt(card: CardInstance) -> String:
	if card == null or card.card_def == null:
		return ""
	match card.card_def.targeting_rules:
		"select_one_customer_and_one_plated_pastry":
			return "Select 1 customer and 1 plated pastry."
		"select_one_plated_pastry":
			return "Select 1 plated pastry."
		"select_one_customer":
			return "Select 1 customer."
		_:
			return ""

func is_valid_target(card: CardInstance, zone: StringName, index: int) -> bool:
	if card == null or card.card_def == null:
		return false
	match card.card_def.targeting_rules:
		"select_one_customer_and_one_plated_pastry":
			if zone == &"customer":
				return index >= 0 and index < combat_state.active_customers.size()
			if zone == &"table":
				return index >= 0 and index < cafe_state.plated_pastries.size()
			return false
		"select_one_plated_pastry":
			return zone == &"table" and index >= 0 and index < cafe_state.plated_pastries.size()
		"select_one_customer":
			return zone == &"customer" and index >= 0 and index < combat_state.active_customers.size()
		_:
			return false

func get_valid_targets(card: CardInstance) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if card == null or card.card_def == null:
		return targets
	match card.card_def.targeting_rules:
		"select_one_customer_and_one_plated_pastry":
			for customer_index in range(combat_state.active_customers.size()):
				if is_valid_target(card, &"customer", customer_index):
					targets.append({
						"zone": &"customer",
						"index": customer_index,
					})
			for table_index in range(cafe_state.plated_pastries.size()):
				if is_valid_target(card, &"table", table_index):
					targets.append({
						"zone": &"table",
						"index": table_index,
					})
		"select_one_plated_pastry":
			for table_index in range(cafe_state.plated_pastries.size()):
				if is_valid_target(card, &"table", table_index):
					targets.append({
						"zone": &"table",
						"index": table_index,
					})
		"select_one_customer":
			for customer_index in range(combat_state.active_customers.size()):
				if is_valid_target(card, &"customer", customer_index):
					targets.append({
						"zone": &"customer",
						"index": customer_index,
					})
	return targets

func notify_no_valid_targets_for_card(card: CardInstance) -> void:
	if card == null or card.card_def == null:
		return
	_set_status_message("No valid targets for %s right now." % card.get_display_name())

func play_card_from_hand(card_index: int, targets: Array[Dictionary], effect_queue: EffectQueueService) -> bool:
	if effect_queue == null:
		return false
	if card_index < 0 or card_index >= deck_state.hand.size():
		return false
	var card: CardInstance = deck_state.hand[card_index]
	if card == null or card.card_def == null:
		return false
	if not can_play_card(card):
		return false
	var required_target_count: int = get_required_target_count(card)
	if required_target_count != targets.size():
		return false
	for target in targets:
		var zone: StringName = StringName(target.get("zone", ""))
		var index: int = int(target.get("index", -1))
		if not is_valid_target(card, zone, index):
			return false
	spend_energy(card.get_cost())
	if event_bus != null:
		event_bus.emit_energy_changed(player_state.energy, -card.get_cost())
	var context: EffectContext = build_effect_context(card, targets)
	effect_queue.enqueue_all(card.card_def.effects, context)
	effect_queue.resolve_all()
	deck_state.discard_from_hand(card)
	after_card_played(card, targets)
	return true

func add_tags_to_pastry(
	targets: Array,
	tags_to_add: PackedStringArray,
	required_pastry_tags: PackedStringArray = [],
	required_pastry_states: PackedStringArray = [],
	forbidden_pastry_states: PackedStringArray = []
) -> bool:
	var pastry: PastryInstance = _resolve_pastry_target(targets)
	if pastry == null:
		_set_status_message("There is no pastry to season right now.")
		return false
	if not _pastry_meets_conditions(pastry, required_pastry_tags, required_pastry_states, forbidden_pastry_states):
		_set_status_message("%s is not in the right state for that card." % pastry.get_display_name())
		return false
	var changed: bool = false
	for raw_tag in tags_to_add:
		var tag_name: StringName = StringName(raw_tag)
		if tag_name == &"" or pastry.has_pastry_tag(tag_name):
			continue
		pastry.add_pastry_tag(tag_name)
		changed = true
	if not changed:
		_set_status_message("%s already has those traits." % pastry.get_display_name())
		return false
	pastry.steps_used += 1
	_set_status_message("%s gained %s." % [pastry.get_display_name(), UiTextFormatter.join_packed(tags_to_add)])
	return true

func add_states_to_pastry(targets: Array, states_to_add: PackedStringArray, duration: int = -1, quality_delta: int = 0) -> bool:
	var pastry: PastryInstance = _resolve_pastry_target(targets)
	if pastry == null:
		_set_status_message("There is no pastry to update.")
		return false
	var changed: bool = false
	for raw_state in states_to_add:
		var state_name: StringName = StringName(raw_state)
		if state_name == &"":
			continue
		pastry.add_pastry_state(state_name, duration)
		changed = true
	if quality_delta != 0:
		pastry.quality = maxi(0, pastry.quality + quality_delta)
		changed = true
	if not changed:
		return false
	pastry.steps_used += 1
	_set_status_message("%s was updated." % pastry.get_display_name())
	return true

func selected_pastry_meets_conditions(
	targets: Array,
	required_pastry_tags: PackedStringArray = [],
	required_pastry_states: PackedStringArray = [],
	forbidden_pastry_states: PackedStringArray = []
) -> bool:
	var pastry: PastryInstance = _resolve_pastry_target(targets)
	return _pastry_meets_conditions(pastry, required_pastry_tags, required_pastry_states, forbidden_pastry_states)

func change_selected_pastry_quality(targets: Array, amount: int) -> void:
	var pastry: PastryInstance = _resolve_pastry_target(targets)
	if pastry == null:
		return
	pastry.quality = maxi(0, pastry.quality + amount)
	_set_status_message("%s quality is now %d." % [pastry.get_display_name(), pastry.quality])

func set_selected_pastry_flag(targets: Array, flag_name: StringName, flag_value: bool) -> void:
	var pastry: PastryInstance = _resolve_pastry_target(targets)
	if pastry == null or flag_name == &"":
		return
	pastry.internal_flags[flag_name] = flag_value

func set_encounter_flag(flag_name: StringName, amount: int) -> void:
	match flag_name:
		&"next_plated_pastry_duplications":
			combat_state.next_plated_pastry_duplications = maxi(0, combat_state.next_plated_pastry_duplications + amount)
			_set_status_message("The next plated pastry will be duplicated.")
		&"skip_next_customer_patience_loss":
			combat_state.skip_next_customer_patience_loss = amount > 0
			_set_status_message("The next customer turn will not reduce patience.")
		&"next_warm_serve_bonus":
			combat_state.next_warm_serve_bonus = amount > 0
			_set_status_message("Your next warm serve will impress extra.")

func modify_all_customers_patience(amount: int) -> void:
	for customer in combat_state.active_customers:
		if customer != null:
			customer.current_patience = maxi(0, customer.current_patience + amount)
	if amount != 0:
		_set_status_message("Customer patience changed by %d." % amount)

func proof_active_pastry() -> bool:
	var pastry: PastryInstance = cafe_state.active_pastry
	if pastry == null:
		_set_status_message("There is no pastry ready to proof.")
		return false
	if not _pastry_requires_proofing(pastry):
		_set_status_message("%s does not need proofing." % pastry.get_display_name())
		return false
	if cafe_state.oven_pastry != null:
		_set_status_message("The oven is already occupied.")
		return false
	pastry.zone = &"oven"
	pastry.turns_in_oven = 0
	pastry.steps_used += 1
	cafe_state.oven_pastry = pastry
	cafe_state.active_pastry = null
	cafe_state.oven_mode = &"proofing"
	cafe_state.oven_turns_remaining = 1
	_spawn_fresh_active_pastry()
	_set_status_message("%s is proofing in the oven." % pastry.get_display_name())
	return true

func bake_active_pastry() -> bool:
	if cafe_state.active_pastry != null:
		var pastry: PastryInstance = cafe_state.active_pastry
		if _pastry_requires_proofing(pastry):
			_set_status_message("%s needs proofing before baking." % pastry.get_display_name())
			return false
		if cafe_state.oven_pastry != null:
			_set_status_message("The oven is already occupied.")
			return false
		pastry.zone = &"oven"
		pastry.turns_in_oven = 0
		pastry.steps_used += 1
		cafe_state.oven_pastry = pastry
		cafe_state.active_pastry = null
		cafe_state.oven_mode = &"baking"
		cafe_state.oven_turns_remaining = 1
		_spawn_fresh_active_pastry()
		_set_status_message("%s is baking." % pastry.get_display_name())
		return true
	if cafe_state.oven_pastry != null and cafe_state.oven_mode == &"" and cafe_state.oven_pastry.has_pastry_state(&"proofed"):
		cafe_state.oven_pastry.steps_used += 1
		cafe_state.oven_mode = &"baking"
		cafe_state.oven_turns_remaining = 1
		_set_status_message("%s is now baking." % cafe_state.oven_pastry.get_display_name())
		return true
	_set_status_message("There is nothing ready to bake.")
	return false

func flash_bake_pastry(burn_chance: float) -> bool:
	if cafe_state.plated_pastries.size() >= cafe_state.serving_table_capacity:
		_set_status_message("Table is full.")
		return false
	var pastry: PastryInstance = null
	if cafe_state.active_pastry != null:
		if _pastry_requires_proofing(cafe_state.active_pastry):
			_set_status_message("%s needs proofing before flash baking." % cafe_state.active_pastry.get_display_name())
			return false
		pastry = cafe_state.active_pastry
		cafe_state.active_pastry = null
	elif cafe_state.oven_pastry != null and cafe_state.oven_mode == &"" and cafe_state.oven_pastry.has_pastry_state(&"proofed"):
		pastry = cafe_state.oven_pastry
		_clear_oven_pastry()
	else:
		_set_status_message("There is no pastry ready for Flash Bake.")
		return false
	pastry.steps_used += 1
	if randf() < burn_chance:
		pastry.remove_pastry_state(&"warm")
		pastry.add_pastry_state(&"burned")
		_plate_pastry(pastry, false)
		_set_status_message("%s was flash baked too hard and burned." % pastry.get_display_name())
		return true
	pastry.add_pastry_state(&"baked")
	_plate_pastry(pastry, true)
	_notify_item_baked(pastry, [{"zone": &"table", "index": maxi(0, cafe_state.plated_pastries.size() - 1)}])
	_set_status_message("%s was flash baked onto the table." % pastry.get_display_name())
	return true

func spawn_item_in_prep(_item_id: StringName) -> bool:
	_set_status_message("This run now uses pastry cards instead of spawning prep items.")
	return false

func mix_selected_prep_items(_targets: Array) -> bool:
	_set_status_message("Mixing prep items is no longer part of the pastry flow.")
	return false

func proof_selected_prep_item(_targets: Array) -> bool:
	return proof_active_pastry()

func bake_selected_item(_targets: Array) -> bool:
	return bake_active_pastry()

func flash_bake_selected_item(_targets: Array, burn_chance: float) -> bool:
	return flash_bake_pastry(burn_chance)

func decorate_selected_table_item(targets: Array) -> bool:
	return add_states_to_pastry(targets, PackedStringArray(["decorated"]), -1, 1)

func remove_selected_item(targets: Array) -> bool:
	if targets.size() != 1:
		return false
	var zone: StringName = StringName(targets[0].get("zone", ""))
	var index: int = int(targets[0].get("index", -1))
	if zone == &"prep" and cafe_state.active_pastry != null and index == 0:
		_set_status_message("%s was discarded from prep." % cafe_state.active_pastry.get_display_name())
		cafe_state.active_pastry = null
		_spawn_fresh_active_pastry()
		return true
	if zone == &"oven" and cafe_state.oven_pastry != null and index == 0:
		_set_status_message("%s was removed from the oven." % cafe_state.oven_pastry.get_display_name())
		_clear_oven_pastry()
		_spawn_fresh_active_pastry()
		return true
	if zone == &"table" and index >= 0 and index < cafe_state.plated_pastries.size():
		var removed_pastry: PastryInstance = cafe_state.plated_pastries[index]
		cafe_state.plated_pastries.remove_at(index)
		_set_status_message("%s was cleared from the table." % removed_pastry.get_display_name())
		return true
	return false

func can_collect_oven_item(slot_index: int) -> bool:
	return slot_index == 0 and cafe_state.oven_pastry != null and cafe_state.oven_mode == &"ready"

func collect_oven_item(slot_index: int) -> bool:
	if not can_collect_oven_item(slot_index):
		return false
	var pastry: PastryInstance = cafe_state.oven_pastry
	_clear_oven_pastry()
	var should_add_warm: bool = not pastry.has_pastry_state(&"burned")
	if not _plate_pastry(pastry, should_add_warm):
		cafe_state.oven_pastry = pastry
		cafe_state.oven_mode = &"ready"
		cafe_state.oven_turns_remaining = 0
		return false
	_set_status_message("%s moved from the oven to the table." % pastry.get_display_name())
	return true

func serve_item_to_customer(customer_index: int, item_index: int) -> bool:
	if customer_index < 0 or customer_index >= combat_state.active_customers.size():
		return false
	if item_index < 0 or item_index >= cafe_state.plated_pastries.size():
		return false
	var customer: CustomerInstance = combat_state.active_customers[customer_index]
	var pastry: PastryInstance = cafe_state.plated_pastries[item_index]
	var outcome: Dictionary = _score_pastry_for_customer(pastry, customer)
	cafe_state.plated_pastries.remove_at(item_index)
	if not bool(outcome.get("accepted", false)):
		customer.current_patience = maxi(0, customer.current_patience - 1)
		var failed_message: String = "%s %s lost 1 patience." % [
			String(outcome.get("message", "The pastry was rejected.")),
			customer.get_display_name(),
		]
		if customer.current_patience <= 0:
			var stress_damage: int = customer.customer_def.stress_damage if customer.customer_def != null else 2
			player_state.lose_stress(stress_damage)
			combat_state.active_customers.remove_at(customer_index)
			_set_status_message("%s They left upset. Stress -%d." % [failed_message, stress_damage])
			if player_state.stress <= 0:
				_finish_run(false, "The bakery became too stressful to continue.")
				return true
		else:
			_set_status_message(failed_message)
		_clamp_focused_customer_index()
		if combat_state.active_customers.is_empty():
			_advance_after_encounter_clear()
		return true

	var matched_bonus_tags: int = int(outcome.get("matched_bonus_tags", 0))
	var satiation: int = _calculate_pastry_satiation(pastry)
	customer.remaining_hunger = maxi(0, customer.remaining_hunger - satiation)
	var satisfaction_gain: int = 2 + matched_bonus_tags
	_apply_customer_satisfaction(customer, satisfaction_gain)
	customer.pending_tip_bonus += 1 + matched_bonus_tags
	if customer.remaining_hunger > 0:
		_set_status_message("%s %s is still hungry (%d hunger left)." % [
			String(outcome.get("message", "The pastry was accepted.")),
			customer.get_display_name(),
			customer.remaining_hunger,
		])
		combat_state.focused_customer_index = clampi(customer_index, 0, combat_state.active_customers.size() - 1)
		return true

	var reputation_delta: int = int(outcome.get("reputation_delta", 0))
	var tips_delta: int = int(outcome.get("tips", 0))
	var final_message: String = String(outcome.get("message", "Served a customer."))
	if combat_state.next_warm_serve_bonus and pastry.has_pastry_state(&"warm") and reputation_delta > 0:
		reputation_delta += 1
		tips_delta += 1
		combat_state.next_warm_serve_bonus = false
		final_message = "%s caught the pastry at the perfect moment." % customer.get_display_name()
	tips_delta += customer.pending_tip_bonus
	customer.pending_tip_bonus = 0
	apply_reputation_delta(reputation_delta)
	player_state.gain_tips(tips_delta)
	customer.served = true
	var scheduled_return_count: int = _schedule_customer_returns(customer)
	var gifted_decoration_id: StringName = _maybe_grant_customer_decoration_gift(customer)
	combat_state.active_customers.remove_at(customer_index)
	_notify_customer_served(customer, pastry)
	if scheduled_return_count == 1:
		final_message += " They may come back on another day."
	elif scheduled_return_count > 1:
		final_message += " They may come back on later days."
	if gifted_decoration_id != &"":
		final_message += " They gifted %s." % _get_decoration_display_name(gifted_decoration_id)
	_set_status_message(final_message)
	_clamp_focused_customer_index()
	if combat_state.active_customers.is_empty():
		_advance_after_encounter_clear()
	return true

func serve_targets(targets: Array[Dictionary]) -> bool:
	var customer_index: int = -1
	var pastry_index: int = -1
	for target in targets:
		var zone: StringName = StringName(target.get("zone", ""))
		var index: int = int(target.get("index", -1))
		if zone == &"customer":
			customer_index = index
		elif zone == &"table":
			pastry_index = index
	if customer_index == -1 or pastry_index == -1:
		_set_status_message("Serve needs 1 customer and 1 plated pastry.")
		return false
	return serve_item_to_customer(customer_index, pastry_index)

func _calculate_pastry_satiation(pastry: PastryInstance) -> int:
	if pastry == null:
		return 0
	if pastry.has_pastry_state(&"burned"):
		return 0
	var satiation: int = pastry.base_satiation + pastry.bonus_satiation
	if pastry.has_pastry_tag(&"luxurious"):
		satiation += 1
	if pastry.has_pastry_tag(&"salty"):
		satiation += 1
	if pastry.has_pastry_tag(&"airy"):
		satiation -= 1
	return maxi(1, satiation)

func _apply_customer_satisfaction(customer: CustomerInstance, satisfaction_gain: int) -> void:
	if customer == null or satisfaction_gain <= 0:
		return
	customer.satisfaction_score += satisfaction_gain
	run_state.current_day_satisfaction_score += satisfaction_gain
	run_state.run_satisfaction_score += satisfaction_gain

func _schedule_customer_returns(customer: CustomerInstance) -> int:
	if customer == null or customer.customer_def == null:
		return 0
	var customer_id: StringName = customer.customer_def.customer_id
	if customer_id == &"critic_boss":
		return 0
	var max_return_visits: int = customer.get_max_extra_return_visits()
	if max_return_visits <= 0:
		return 0
	var already_scheduled_visits: int = int(run_state.scheduled_return_visit_counts_by_customer.get(customer_id, 0))
	var remaining_visits_to_schedule: int = max_return_visits - already_scheduled_visits
	if remaining_visits_to_schedule <= 0:
		return 0
	var scheduled_now: int = 0
	for future_day in range(run_state.day_number + 1, 4):
		if scheduled_now >= remaining_visits_to_schedule:
			break
		var base_customer_ids: PackedStringArray = _to_packed_strings(ENCOUNTER_CUSTOMERS.get(future_day, []))
		if base_customer_ids.has(customer_id):
			continue
		var scheduled_ids: PackedStringArray = _to_packed_strings(run_state.scheduled_return_customer_ids_by_day.get(future_day, []))
		if scheduled_ids.has(customer_id) or not scheduled_ids.is_empty():
			continue
		scheduled_ids.append(customer_id)
		run_state.scheduled_return_customer_ids_by_day[future_day] = scheduled_ids
		scheduled_now += 1
	if scheduled_now <= 0:
		return 0
	run_state.scheduled_return_visit_counts_by_customer[customer_id] = already_scheduled_visits + scheduled_now
	if not run_state.customer_ids_already_scheduled_to_return.has(customer_id):
		run_state.customer_ids_already_scheduled_to_return.append(customer_id)
	customer.has_return_scheduled = true
	return scheduled_now

func _maybe_schedule_customer_return(customer: CustomerInstance) -> bool:
	return _schedule_customer_returns(customer) > 0

func _maybe_grant_customer_decoration_gift(customer: CustomerInstance) -> StringName:
	if customer == null or customer.customer_def == null or meta_profile_service == null:
		return &""
	if not customer.is_extremely_satisfied():
		return &""
	var customer_id: StringName = customer.customer_def.customer_id
	if customer_id == &"" or run_state.customer_ids_who_gifted_decoration_this_run.has(customer_id):
		return &""
	var profile: MetaProfileState = get_profile_state()
	for raw_decoration_id in customer.get_gift_decoration_ids():
		var decoration_id: StringName = StringName(raw_decoration_id)
		if decoration_id == &"":
			continue
		var decoration: DecorationDef = content_library.get_decoration(decoration_id)
		if decoration == null or profile.owned_decoration_ids.has(decoration_id):
			continue
		if not meta_profile_service.grant_decoration(decoration_id):
			continue
		run_state.customer_ids_who_gifted_decoration_this_run.append(customer_id)
		if not run_state.day_gifted_decoration_ids.has(decoration_id):
			run_state.day_gifted_decoration_ids.append(decoration_id)
		if not run_state.gifted_decoration_ids_this_run.has(decoration_id):
			run_state.gifted_decoration_ids_this_run.append(decoration_id)
		return decoration_id
	return &""

func _complete_day_satisfaction_tracking() -> void:
	run_state.last_completed_day_satisfaction_score = run_state.current_day_satisfaction_score
	run_state.day_satisfaction_history[run_state.day_number] = run_state.current_day_satisfaction_score

func _build_day_completion_message(next_step_message: String) -> String:
	var message: String = "Day %d complete. Satisfaction: %d." % [
		run_state.day_number,
		run_state.last_completed_day_satisfaction_score,
	]
	if not run_state.day_gifted_decoration_ids.is_empty():
		message += " Gifts: %s." % _format_decoration_name_list(run_state.day_gifted_decoration_ids)
	if next_step_message != "":
		message += " %s" % next_step_message
	return message

func _format_decoration_name_list(decoration_ids: PackedStringArray) -> String:
	var decoration_names: Array[String] = []
	for raw_decoration_id in decoration_ids:
		decoration_names.append(_get_decoration_display_name(StringName(raw_decoration_id)))
	return UiTextFormatter.join_strings(decoration_names) if not decoration_names.is_empty() else "none"

func _get_decoration_display_name(decoration_id: StringName) -> String:
	var decoration: DecorationDef = content_library.get_decoration(decoration_id)
	if decoration != null and decoration.display_name != "":
		return decoration.display_name
	return String(decoration_id)

func _clamp_focused_customer_index() -> void:
	if combat_state.active_customers.is_empty():
		combat_state.focused_customer_index = 0
		return
	combat_state.focused_customer_index = clampi(
		combat_state.focused_customer_index,
		0,
		combat_state.active_customers.size() - 1
	)

func _resolve_pastry_target(targets: Array) -> PastryInstance:
	for target_value in targets:
		var target: Dictionary = target_value
		var pastry_from_target: PastryInstance = _get_pastry_from_target(target)
		if pastry_from_target != null:
			return pastry_from_target
	if cafe_state.active_pastry != null:
		return cafe_state.active_pastry
	if cafe_state.oven_pastry != null:
		return cafe_state.oven_pastry
	if not cafe_state.plated_pastries.is_empty():
		return cafe_state.plated_pastries[0]
	return null

func _get_pastry_from_target(target: Dictionary) -> PastryInstance:
	var zone: StringName = StringName(target.get("zone", ""))
	var index: int = int(target.get("index", -1))
	if zone == &"prep" and cafe_state.active_pastry != null and index == 0:
		return cafe_state.active_pastry
	if zone == &"oven" and cafe_state.oven_pastry != null and index == 0:
		return cafe_state.oven_pastry
	if zone == &"table" and index >= 0 and index < cafe_state.plated_pastries.size():
		return cafe_state.plated_pastries[index]
	return null

func _pastry_meets_conditions(
	pastry: PastryInstance,
	required_pastry_tags: PackedStringArray = [],
	required_pastry_states: PackedStringArray = [],
	forbidden_pastry_states: PackedStringArray = []
) -> bool:
	if pastry == null:
		return false
	for required_tag in required_pastry_tags:
		if not _pastry_matches_token(pastry, String(required_tag)):
			return false
	for required_state in required_pastry_states:
		if not _pastry_matches_token(pastry, String(required_state)):
			return false
	for forbidden_state in forbidden_pastry_states:
		if _pastry_matches_token(pastry, String(forbidden_state)):
			return false
	return true

func _clear_oven_pastry() -> void:
	cafe_state.oven_pastry = null
	cafe_state.oven_mode = &""
	cafe_state.oven_turns_remaining = 0

func _plate_pastry(pastry: PastryInstance, add_warm: bool) -> bool:
	if pastry == null:
		return false
	if cafe_state.plated_pastries.size() >= cafe_state.serving_table_capacity:
		_set_status_message("Table is full.")
		return false
	pastry.zone = &"table"
	if add_warm:
		pastry.add_pastry_state(&"warm", 1)
	cafe_state.plated_pastries.append(pastry)
	var duplicate_count: int = combat_state.next_plated_pastry_duplications
	combat_state.next_plated_pastry_duplications = 0
	for _dup_index in range(duplicate_count):
		if cafe_state.plated_pastries.size() >= cafe_state.serving_table_capacity:
			break
		var pastry_copy: PastryInstance = pastry.duplicate_pastry()
		pastry_copy.zone = &"table"
		cafe_state.plated_pastries.append(pastry_copy)
	if cafe_state.active_pastry == null:
		_spawn_fresh_active_pastry()
	return true

func choose_reward(reward_id: StringName) -> bool:
	if run_state.screen != GameEnums.Screen.REWARD:
		return false
	if not run_state.pending_reward_ids.has(reward_id):
		return false
	var reward: RewardDef = content_library.get_reward(reward_id)
	if reward == null:
		return false
	_apply_reward(reward)
	run_state.pending_reward_ids.clear()
	_open_dough_select_for_day(run_state.day_number + 1)
	return true

func buy_offer(offer_id: StringName) -> bool:
	if run_state.screen != GameEnums.Screen.RUN_SHOP:
		return false
	if not run_state.pending_shop_offer_ids.has(offer_id):
		return false
	var offer: CardOfferDef = content_library.get_offer(offer_id)
	if offer == null:
		return false
	if not player_state.spend_tips(offer.cost):
		_set_status_message("Not enough run tips to buy %s." % offer.display_name)
		return false
	match offer.offer_type:
		GameEnums.OfferType.RUN_CARD:
			_add_card_to_run_deck(offer.payload_id)
			_set_status_message("Bought %s for this run." % offer.display_name)
		GameEnums.OfferType.RUN_BUFF:
			add_player_buff(offer.payload_id, &"shop_offer", offer.offer_id)
			_set_status_message("Bought %s for this run." % offer.display_name)
	run_state.pending_shop_offer_ids.erase(offer_id)
	return true

func continue_after_shop() -> void:
	if run_state.screen != GameEnums.Screen.RUN_SHOP:
		return
	_open_dough_select_for_day(run_state.day_number + 1)

func open_boss_intro() -> void:
	run_state.screen = GameEnums.Screen.BOSS_INTRO
	run_state.run_phase = GameEnums.RunPhase.BOSS_INTRO
	run_state.current_customer_ids = _to_packed_strings([&"critic_boss"])
	_set_status_message(_build_day_completion_message("The Final Critic is waiting. Choose the dough you want to prep for the boss day."))

func start_boss_encounter() -> void:
	_open_dough_select_for_day(4)

func return_to_hub() -> void:
	_reset_runtime_state()
	open_cafe_hub()

func purchase_shop_upgrade(upgrade_id: StringName) -> bool:
	var upgrade: ShopUpgradeDef = content_library.get_shop_upgrade(upgrade_id)
	if upgrade == null or meta_profile_service == null:
		return false
	if meta_profile_service.purchase_upgrade(upgrade_id, upgrade.cost):
		_set_status_message("Purchased permanent upgrade: %s." % upgrade.display_name)
		return true
	_set_status_message("Could not purchase %s." % upgrade.display_name)
	return false

func purchase_decoration(decoration_id: StringName) -> bool:
	var decoration: DecorationDef = content_library.get_decoration(decoration_id)
	if decoration == null or meta_profile_service == null:
		return false
	if meta_profile_service.purchase_decoration(decoration_id, decoration.cost):
		_set_status_message("Purchased decoration: %s." % decoration.display_name)
		return true
	_set_status_message("Could not purchase %s." % decoration.display_name)
	return false

func toggle_equipment(equipment_id: StringName, equipped: bool) -> bool:
	var equipment: EquipmentDef = content_library.get_equipment(equipment_id)
	if equipment == null:
		return false
	var profile: MetaProfileState = get_profile_state()
	if equipped and not profile.owned_equipment_ids.has(equipment_id):
		if meta_profile_service == null or not meta_profile_service.purchase_equipment(equipment_id, equipment.cost):
			_set_status_message("Could not buy %s." % equipment.display_name)
			return false
	if meta_profile_service == null:
		return false
	meta_profile_service.equip_equipment(equipment_id, equipped)
	_set_status_message("%s %s." % [equipment.display_name, "equipped" if equipped else "unequipped"])
	return true

func place_decoration(slot_name: String, decoration_id: StringName) -> bool:
	if not DECORATION_SLOT_NAMES.has(slot_name):
		return false
	if meta_profile_service == null:
		return false
	var decoration: DecorationDef = content_library.get_decoration(decoration_id)
	if decoration_id != &"" and decoration == null:
		return false
	if decoration != null and get_decoration_slot_name(decoration.slot) != slot_name:
		_set_status_message("That decoration does not fit the %s slot." % slot_name)
		return false
	if meta_profile_service.place_decoration(slot_name, decoration_id):
		_set_status_message("Updated the %s decoration slot." % slot_name)
		return true
	return false

func get_decoration_slot_name(slot: int) -> String:
	if slot < 0 or slot >= DECORATION_SLOT_NAMES.size():
		return "wall"
	return DECORATION_SLOT_NAMES[slot]

func add_player_buff(modifier_id: StringName, source_kind: StringName = &"", source_id: StringName = &"", duration_override: int = -999) -> bool:
	return _add_modifier_to_collection(
		player_state.active_buffs,
		GameEnums.ModifierTarget.PLAYER,
		modifier_id,
		source_kind,
		source_id,
		duration_override
	)

func add_status_to_target_customer(targets: Array, modifier_id: StringName, source_kind: StringName = &"", source_id: StringName = &"", duration_override: int = -999) -> bool:
	var customer_indices: Array = _collect_customer_indices(targets)
	if customer_indices.is_empty() and not combat_state.active_customers.is_empty():
		customer_indices.append(0)
	var applied: bool = false
	for customer_index in customer_indices:
		if customer_index < 0 or customer_index >= combat_state.active_customers.size():
			continue
		var customer: CustomerInstance = combat_state.active_customers[customer_index]
		applied = _add_modifier_to_collection(
			customer.active_statuses,
			GameEnums.ModifierTarget.CUSTOMER,
			modifier_id,
			source_kind,
			source_id,
			duration_override
		) or applied
	return applied

func add_status_to_target_item(targets: Array, modifier_id: StringName, source_kind: StringName = &"", source_id: StringName = &"", duration_override: int = -999) -> bool:
	var applied: bool = false
	for target in targets:
		var item: ItemInstance = _get_item_from_target(target)
		if item == null:
			continue
		applied = _add_modifier_to_collection(
			item.active_statuses,
			GameEnums.ModifierTarget.ITEM,
			modifier_id,
			source_kind,
			source_id,
			duration_override
		) or applied
	return applied

func modify_target_customer_patience(targets: Array, amount: int) -> void:
	var customer_indices: Array = _collect_customer_indices(targets)
	for customer_index in customer_indices:
		if customer_index < 0 or customer_index >= combat_state.active_customers.size():
			continue
		if amount < 0 and combat_state.turn_state == GameEnums.TurnState.CUSTOMER_TURN and combat_state.skip_next_customer_patience_loss:
			continue
		var customer: CustomerInstance = combat_state.active_customers[customer_index]
		customer.current_patience = maxi(0, customer.current_patience + amount)

func modify_selected_prep_item(
	targets: Array,
	replacement_item_id: StringName = &"",
	required_source_item_ids: PackedStringArray = [],
	required_source_tags: PackedStringArray = [],
	added_tags: PackedStringArray = [],
	quality_delta: int = 0
) -> bool:
	if targets.size() != 1:
		_set_status_message("Select exactly 1 prep item.")
		return false
	var index: int = int(targets[0].get("index", -1))
	if index < 0 or index >= cafe_state.prep_items.size():
		return false
	var source_item: ItemInstance = cafe_state.prep_items[index]
	if source_item == null:
		return false
	if not _item_matches_requirements(source_item, required_source_item_ids, required_source_tags):
		_set_status_message("%s cannot be modified that way." % source_item.get_display_name())
		return false
	var modified_item: ItemInstance = _create_modified_item(source_item, replacement_item_id, added_tags, quality_delta)
	if modified_item == null:
		_set_status_message("Could not modify %s." % source_item.get_display_name())
		return false
	modified_item.zone = &"prep"
	cafe_state.prep_items[index] = modified_item
	if modified_item.get_display_name() != source_item.get_display_name():
		_set_status_message("%s is now %s." % [source_item.get_display_name(), modified_item.get_display_name()])
	else:
		_set_status_message("Updated %s." % modified_item.get_display_name())
	return true

func create_item_instance(item_id: StringName) -> ItemInstance:
	var item_def: ItemDef = content_library.get_item(item_id)
	if item_def == null:
		return null
	var instance: ItemInstance = ItemInstance.new()
	instance.item_def = item_def
	instance.created_turn = combat_state.turn_number
	return instance

func _create_prepped_day_dough(dough: DoughDef) -> bool:
	if dough == null:
		return false
	var prep_item_id: StringName = dough.prep_item_id
	if prep_item_id == &"":
		prep_item_id = dough.dough_id
	var prepared_dough: ItemInstance = create_item_instance(prep_item_id)
	if prepared_dough == null:
		_set_status_message("Could not prep %s for the day." % dough.display_name)
		return false
	prepared_dough.zone = &"prep"
	cafe_state.prep_items.append(prepared_dough)
	return true

func _item_matches_requirements(
	item: ItemInstance,
	required_source_item_ids: PackedStringArray,
	required_source_tags: PackedStringArray
) -> bool:
	if item == null:
		return false
	if not required_source_item_ids.is_empty() and not required_source_item_ids.has(item.get_item_id()):
		return false
	for required_tag in required_source_tags:
		if not item.has_tag(StringName(required_tag)):
			return false
	return true

func _create_modified_item(
	source_item: ItemInstance,
	replacement_item_id: StringName,
	added_tags: PackedStringArray,
	quality_delta: int
) -> ItemInstance:
	if source_item == null:
		return null
	var target_item_id: StringName = replacement_item_id if replacement_item_id != &"" else source_item.get_item_id()
	var modified_item: ItemInstance = create_item_instance(target_item_id)
	if modified_item == null:
		return null
	modified_item.zone = source_item.zone
	modified_item.created_turn = source_item.created_turn
	modified_item.steps_used = source_item.steps_used
	modified_item.quality = source_item.quality + quality_delta
	modified_item.active_statuses = source_item.active_statuses.duplicate(true)
	modified_item.custom_tags = source_item.custom_tags.duplicate()
	for added_tag in added_tags:
		modified_item.add_tag(StringName(added_tag))
	return modified_item

func advance_oven() -> void:
	if cafe_state.oven_pastry == null:
		return
	if cafe_state.oven_turns_remaining > 0:
		cafe_state.oven_turns_remaining -= 1
	cafe_state.oven_pastry.turns_in_oven += 1
	if cafe_state.oven_turns_remaining > 0:
		return
	match cafe_state.oven_mode:
		&"proofing":
			cafe_state.oven_pastry.add_pastry_state(&"proofed")
			cafe_state.oven_pastry.add_pastry_tag(&"airy")
			cafe_state.oven_mode = &""
			_set_status_message("%s is proofed and ready to bake." % cafe_state.oven_pastry.get_display_name())
		&"baking":
			cafe_state.oven_pastry.add_pastry_state(&"baked")
			cafe_state.oven_pastry.remove_pastry_state(&"burned")
			cafe_state.oven_mode = &"ready"
			_notify_item_baked(cafe_state.oven_pastry, [{"zone": &"oven", "index": 0}])
			_set_status_message("%s is ready in the oven." % cafe_state.oven_pastry.get_display_name())
		&"ready":
			if not cafe_state.oven_pastry.has_pastry_state(&"burned"):
				cafe_state.oven_pastry.add_pastry_state(&"burned")
				_set_status_message("%s was left in the oven and burned." % cafe_state.oven_pastry.get_display_name())
		_:
			pass

func _tick_pastry_states_turn_start() -> void:
	if cafe_state.active_pastry != null:
		cafe_state.active_pastry.tick_temporary_states()
	if cafe_state.oven_pastry != null:
		cafe_state.oven_pastry.tick_temporary_states()
	for pastry in cafe_state.plated_pastries:
		if pastry != null:
			pastry.tick_temporary_states()

func pop_status_message() -> String:
	var message: String = _last_status_message
	_last_status_message = ""
	return message

func get_status_message() -> String:
	return run_state.status_message
func _process_customer_turn() -> void:
	var remaining_customers: Array[CustomerInstance] = []
	var unhappy_departures: int = 0
	var total_stress_loss: int = 0
	var patience_loss_prevented: bool = combat_state.skip_next_customer_patience_loss
	for customer_index in range(combat_state.active_customers.size()):
		var customer: CustomerInstance = combat_state.active_customers[customer_index]
		if customer == null:
			continue
		_trigger_customer_modifier_hooks(customer_index, &"turn_end")
		customer.turns_waited += 1
		if not patience_loss_prevented:
			customer.current_patience -= 1
		if customer.current_patience <= 0:
			var stress_damage: int = customer.customer_def.stress_damage if customer.customer_def != null else 2
			player_state.lose_stress(stress_damage)
			total_stress_loss += stress_damage
			unhappy_departures += 1
			continue
		remaining_customers.append(customer)
	combat_state.active_customers = remaining_customers
	combat_state.skip_next_customer_patience_loss = false
	_clamp_focused_customer_index()
	if patience_loss_prevented:
		_set_status_message("Small Talk kept the whole line patient for a turn.")
	if unhappy_departures > 0:
		_set_status_message("%d customer(s) left upset. Stress -%d." % [unhappy_departures, total_stress_loss])
	if player_state.stress <= 0:
		_finish_run(false, "The bakery became too stressful to continue.")
		return
	if combat_state.active_customers.is_empty():
		_advance_after_encounter_clear()

func _advance_after_encounter_clear() -> void:
	_complete_day_satisfaction_tracking()
	match run_state.day_number:
		1:
			run_state.screen = GameEnums.Screen.REWARD
			run_state.run_phase = GameEnums.RunPhase.REWARD
			run_state.pending_reward_ids = _to_packed_strings(DAY_REWARD_IDS.get(1, []))
			_set_status_message(_build_day_completion_message("Choose a reward for the run."))
		2:
			run_state.screen = GameEnums.Screen.RUN_SHOP
			run_state.run_phase = GameEnums.RunPhase.RUN_SHOP
			run_state.pending_shop_offer_ids = _to_packed_strings(DAY_SHOP_OFFER_IDS.get(2, []))
			_set_status_message(_build_day_completion_message("Spend your run tips in the shop."))
		3:
			open_boss_intro()
		4:
			_finish_run(true, "The Final Critic left impressed.")

func _apply_reward(reward: RewardDef) -> void:
	match reward.reward_type:
		GameEnums.RewardType.ADD_CARD_TO_RUN_DECK:
			_add_card_to_run_deck(reward.payload_id)
			_set_status_message("Reward added: %s." % reward.display_name)
		GameEnums.RewardType.ADD_RUN_BUFF:
			add_player_buff(reward.payload_id, &"reward", reward.reward_id)
			_set_status_message("Reward gained: %s." % reward.display_name)
		GameEnums.RewardType.ADD_META_UNLOCK:
			_apply_meta_unlock(reward.payload_id)
			_set_status_message("Unlocked: %s." % String(reward.payload_id))
		GameEnums.RewardType.ADD_META_CURRENCY:
			if meta_profile_service != null:
				meta_profile_service.grant_meta_currency(reward.amount)
			run_state.meta_currency_earned += reward.amount
			_set_status_message("Earned %d cafe tokens." % reward.amount)
		GameEnums.RewardType.ADD_EQUIPMENT_OWNERSHIP:
			if meta_profile_service != null:
				meta_profile_service.grant_equipment(reward.payload_id)
			_set_status_message("Equipment unlocked: %s." % String(reward.payload_id))
		GameEnums.RewardType.ADD_SHOP_UPGRADE_OWNERSHIP:
			if meta_profile_service != null:
				meta_profile_service.purchase_upgrade(reward.payload_id, 0)
			_set_status_message("Shop upgrade unlocked: %s." % String(reward.payload_id))
		GameEnums.RewardType.HEAL_STRESS:
			player_state.heal_stress(reward.amount)
			_set_status_message("Recovered %d stress." % reward.amount)
		GameEnums.RewardType.INCREASE_MAX_STRESS:
			player_state.max_stress += reward.amount
			player_state.heal_stress(reward.amount)
			_set_status_message("Max stress increased by %d." % reward.amount)
		GameEnums.RewardType.INCREASE_MAX_ENERGY:
			player_state.max_energy += reward.amount
			_set_status_message("Max energy increased by %d." % reward.amount)

func _apply_meta_unlock(payload_id: StringName) -> void:
	if meta_profile_service == null:
		return
	var text_id: String = String(payload_id)
	if text_id.begins_with("card:"):
		meta_profile_service.unlock_card(StringName(text_id.trim_prefix("card:")))
	elif text_id.begins_with("customer:"):
		meta_profile_service.unlock_customer(StringName(text_id.trim_prefix("customer:")))
	elif text_id.begins_with("equipment:"):
		meta_profile_service.grant_equipment(StringName(text_id.trim_prefix("equipment:")))

func _add_card_to_run_deck(card_id: StringName) -> void:
	player_state.master_deck_ids.append(card_id)
	var card: CardInstance = content_library.build_card_instance(card_id)
	if card != null:
		deck_state.add_to_discard(card)
	if meta_profile_service != null:
		meta_profile_service.unlock_card(card_id)

func _notify_customer_served(customer: CustomerInstance, _pastry: PastryInstance) -> void:
	if event_bus != null and customer != null and customer.customer_def != null:
		event_bus.emit_customer_served(customer.customer_def.customer_id)
	_trigger_player_modifier_hooks(&"customer_served")

func _notify_item_baked(pastry: PastryInstance, targets: Array) -> void:
	if event_bus != null and pastry != null:
		event_bus.emit_item_baked(pastry.dough_id)
	_run_modifier_effects_from_collection(player_state.passive_modifiers, &"item_baked", targets)
	_run_modifier_effects_from_collection(player_state.active_buffs, &"item_baked", targets)

func _trigger_player_modifier_hooks(trigger_name: StringName) -> void:
	_run_modifier_effects_from_collection(player_state.passive_modifiers, trigger_name)
	_run_modifier_effects_from_collection(player_state.active_buffs, trigger_name)

func _trigger_customer_modifier_hooks(customer_index: int, trigger_name: StringName) -> void:
	if customer_index < 0 or customer_index >= combat_state.active_customers.size():
		return
	var customer: CustomerInstance = combat_state.active_customers[customer_index]
	var targets: Array = [{"zone": &"customer", "index": customer_index}]
	_run_modifier_effects_from_collection(customer.active_statuses, trigger_name, targets)

func _tick_item_statuses_turn_start() -> void:
	for prep_index in range(cafe_state.prep_items.size()):
		_run_modifier_effects_from_collection(cafe_state.prep_items[prep_index].active_statuses, &"turn_start", [{"zone": &"prep", "index": prep_index}])
	for slot_index in range(cafe_state.oven_slots.size()):
		var slot: OvenSlotState = cafe_state.oven_slots[slot_index]
		if slot != null and slot.item != null:
			_run_modifier_effects_from_collection(slot.item.active_statuses, &"turn_start", [{"zone": &"oven", "index": slot_index}])
	for table_index in range(cafe_state.table_items.size()):
		_run_modifier_effects_from_collection(cafe_state.table_items[table_index].active_statuses, &"turn_start", [{"zone": &"table", "index": table_index}])

func _tick_all_temporary_modifiers() -> void:
	_tick_modifier_collection(player_state.active_buffs, GameEnums.ModifierTarget.PLAYER)
	for customer_index in range(combat_state.active_customers.size()):
		_tick_modifier_collection(combat_state.active_customers[customer_index].active_statuses, GameEnums.ModifierTarget.CUSTOMER, [{"zone": &"customer", "index": customer_index}])
	for prep_index in range(cafe_state.prep_items.size()):
		_tick_modifier_collection(cafe_state.prep_items[prep_index].active_statuses, GameEnums.ModifierTarget.ITEM, [{"zone": &"prep", "index": prep_index}])
	for slot_index in range(cafe_state.oven_slots.size()):
		var slot: OvenSlotState = cafe_state.oven_slots[slot_index]
		if slot != null and slot.item != null:
			_tick_modifier_collection(slot.item.active_statuses, GameEnums.ModifierTarget.ITEM, [{"zone": &"oven", "index": slot_index}])
	for table_index in range(cafe_state.table_items.size()):
		_tick_modifier_collection(cafe_state.table_items[table_index].active_statuses, GameEnums.ModifierTarget.ITEM, [{"zone": &"table", "index": table_index}])

func _tick_modifier_collection(collection: Array, _target_kind: int, targets: Array = []) -> void:
	for index in range(collection.size() - 1, -1, -1):
		var instance: ModifierInstance = collection[index]
		if instance == null:
			collection.remove_at(index)
			continue
		if instance.remaining_turns > 0:
			instance.remaining_turns -= 1
		if instance.remaining_turns == 0:
			var modifier_def: ModifierDef = content_library.get_modifier(instance.modifier_id)
			if modifier_def != null and not modifier_def.on_expire_effects.is_empty():
				_run_effects(modifier_def.on_expire_effects, instance, targets)
			collection.remove_at(index)

func _run_modifier_effects_from_collection(collection: Array, trigger_name: StringName, targets: Array = []) -> void:
	for instance_value in collection:
		var instance: ModifierInstance = instance_value
		if instance == null:
			continue
		var modifier_def: ModifierDef = content_library.get_modifier(instance.modifier_id)
		if modifier_def == null:
			continue
		var effects: Array = _get_modifier_effects_for_trigger(modifier_def, trigger_name)
		if not effects.is_empty():
			_run_effects(effects, instance, targets)

func _get_modifier_effects_for_trigger(modifier_def: ModifierDef, trigger_name: StringName) -> Array:
	match trigger_name:
		&"turn_start":
			return modifier_def.on_turn_start_effects
		&"turn_end":
			return modifier_def.on_turn_end_effects
		&"card_played":
			return modifier_def.on_card_played_effects
		&"customer_served":
			return modifier_def.on_customer_served_effects
		&"item_baked":
			return modifier_def.on_item_baked_effects
		_:
			return []

func _run_effects(effects: Array, source_modifier: ModifierInstance, targets: Array = []) -> void:
	var context: EffectContext = build_effect_context(null, targets, source_modifier)
	for effect_value in effects:
		var effect: BaseEffect = effect_value
		if effect == null:
			continue
		effect.apply(context)
		if event_bus != null:
			event_bus.emit_effect_applied(effect, context)

func _add_modifier_to_collection(collection: Array, target_kind: int, modifier_id: StringName, source_kind: StringName, source_id: StringName, duration_override: int) -> bool:
	var modifier_def: ModifierDef = content_library.get_modifier(modifier_id)
	if modifier_def == null:
		return false
	for existing_value in collection:
		var existing: ModifierInstance = existing_value
		if existing != null and existing.modifier_id == modifier_id:
			if modifier_def.stackable:
				existing.stacks = mini(modifier_def.max_stacks, existing.stacks + 1)
			if duration_override != -999:
				existing.remaining_turns = duration_override
			elif modifier_def.default_duration_turns > 0:
				existing.remaining_turns = modifier_def.default_duration_turns
			return true
	var instance: ModifierInstance = ModifierInstance.new()
	instance.modifier_id = modifier_id
	instance.remaining_turns = duration_override if duration_override != -999 else modifier_def.default_duration_turns
	instance.stacks = 1
	instance.source_kind = source_kind
	instance.source_id = source_id
	instance.applied_turn = combat_state.turn_number
	collection.append(instance)
	_apply_modifier_stats(instance, modifier_def, target_kind)
	if not modifier_def.on_apply_effects.is_empty():
		_run_effects(modifier_def.on_apply_effects, instance)
	return true

func _apply_modifier_stats(_instance: ModifierInstance, modifier_def: ModifierDef, target_kind: int) -> void:
	for key_value in modifier_def.stat_modifiers.keys():
		var key: String = String(key_value)
		var amount: int = int(modifier_def.stat_modifiers[key_value])
		match target_kind:
			GameEnums.ModifierTarget.PLAYER:
				match key:
					"max_energy":
						player_state.max_energy += amount
						player_state.energy += amount
					"max_stress":
						player_state.max_stress += amount
						player_state.stress += amount
					"starting_hand_size":
						player_state.starting_hand_size += amount
					"tips":
						player_state.gain_tips(amount)
					"oven_capacity":
						cafe_state.oven_capacity += amount
						_rebuild_oven_slots()
					"prep_capacity":
						cafe_state.prep_space_capacity += amount
					"table_capacity":
						cafe_state.serving_table_capacity += amount
			GameEnums.ModifierTarget.CUSTOMER:
				if key == "patience":
					for customer in combat_state.active_customers:
						customer.current_patience += amount
			GameEnums.ModifierTarget.ITEM:
				pass

func _revert_modifier_stats(_instance: ModifierInstance, modifier_def: ModifierDef, target_kind: int) -> void:
	for key_value in modifier_def.stat_modifiers.keys():
		var key: String = String(key_value)
		var amount: int = int(modifier_def.stat_modifiers[key_value])
		match target_kind:
			GameEnums.ModifierTarget.PLAYER:
				match key:
					"max_energy":
						player_state.max_energy = maxi(0, player_state.max_energy - amount)
						player_state.energy = mini(player_state.energy, player_state.max_energy)
					"max_stress":
						player_state.max_stress = maxi(1, player_state.max_stress - amount)
						player_state.stress = mini(player_state.stress, player_state.max_stress)
					"starting_hand_size":
						player_state.starting_hand_size = maxi(1, player_state.starting_hand_size - amount)
					"tips":
						player_state.tips = maxi(0, player_state.tips - amount)
					"oven_capacity":
						cafe_state.oven_capacity = maxi(1, cafe_state.oven_capacity - amount)
						_rebuild_oven_slots()
					"prep_capacity":
						cafe_state.prep_space_capacity = maxi(1, cafe_state.prep_space_capacity - amount)
					"table_capacity":
						cafe_state.serving_table_capacity = maxi(1, cafe_state.serving_table_capacity - amount)
			GameEnums.ModifierTarget.CUSTOMER:
				if key == "patience":
					for customer in combat_state.active_customers:
						customer.current_patience = maxi(0, customer.current_patience - amount)
			GameEnums.ModifierTarget.ITEM:
				pass

func after_card_played(card: CardInstance, targets: Array = []) -> void:
	if event_bus != null and card != null:
		event_bus.emit_card_played(card)
	_run_modifier_effects_from_collection(player_state.passive_modifiers, &"card_played")
	_run_modifier_effects_from_collection(player_state.active_buffs, &"card_played")
	_trigger_card_interaction_talents(card, targets)

func _trigger_card_interaction_talents(card: CardInstance, targets: Array) -> void:
	if card == null or card.card_def == null or card.card_def.interaction_traits.is_empty():
		return
	var customer_index: int = _resolve_interaction_customer_index(targets)
	for raw_trait in card.card_def.interaction_traits:
		var interaction_trait: StringName = StringName(raw_trait)
		var event_name: StringName = &""
		match interaction_trait:
			&"talk":
				event_name = &"talked_to"
			_:
				event_name = &""
		if event_name == &"":
			continue
		_trigger_customer_talents(event_name, customer_index, card, targets)

func _resolve_interaction_customer_index(targets: Array) -> int:
	var customer_indices: Array = _collect_customer_indices(targets)
	if not customer_indices.is_empty():
		return int(customer_indices[0])
	if combat_state.active_customers.is_empty():
		return -1
	return clampi(combat_state.focused_customer_index, 0, combat_state.active_customers.size() - 1)

func _trigger_customer_talents(event_name: StringName, customer_index: int, source_card: CardInstance, targets: Array) -> void:
	if event_name == &"" or customer_index < 0 or customer_index >= combat_state.active_customers.size():
		return
	var customer: CustomerInstance = combat_state.active_customers[customer_index]
	if customer == null:
		return
	for raw_talent_id in customer.get_talent_ids():
		_apply_customer_talent(event_name, customer_index, StringName(raw_talent_id), source_card, targets)

func _apply_customer_talent(
	event_name: StringName,
	customer_index: int,
	talent_id: StringName,
	_source_card: CardInstance,
	_targets: Array
) -> void:
	if customer_index < 0 or customer_index >= combat_state.active_customers.size():
		return
	var customer: CustomerInstance = combat_state.active_customers[customer_index]
	if customer == null:
		return
	match talent_id:
		&"social":
			if event_name == &"talked_to":
				customer.current_patience += 1
				_append_status_message("%s warmed up to the conversation and gained 1 patience." % customer.get_display_name())
		_:
			pass
func _find_recipe(input_item_ids: PackedStringArray, station: StringName) -> RecipeDef:
	for recipe in content_library.recipes.values():
		var recipe_def: RecipeDef = recipe
		if recipe_def == null or recipe_def.station != station:
			continue
		if _same_inputs(recipe_def.input_item_ids, input_item_ids):
			return recipe_def
	return null

func _same_inputs(left: PackedStringArray, right: PackedStringArray) -> bool:
	if left.size() != right.size():
		return false
	var left_copy: Array[String] = []
	var right_copy: Array[String] = []
	for value in left:
		left_copy.append(String(value))
	for value in right:
		right_copy.append(String(value))
	left_copy.sort()
	right_copy.sort()
	for index in range(left_copy.size()):
		if left_copy[index] != right_copy[index]:
			return false
	return true

func _create_baked_result(item: ItemInstance) -> ItemInstance:
	var recipe: RecipeDef = _find_recipe(PackedStringArray([String(item.get_item_id())]), &"oven")
	if recipe == null:
		return null
	var result_item: ItemInstance = create_item_instance(recipe.output_item_id)
	if result_item == null:
		return null
	result_item.steps_used = item.steps_used + 1
	result_item.quality = item.quality + recipe.quality_delta
	result_item.custom_tags = item.custom_tags.duplicate()
	for tag in recipe.added_tags:
		result_item.add_tag(StringName(tag))
	result_item.add_tag(&"warm")
	return result_item

func _score_pastry_for_customer(pastry: PastryInstance, customer: CustomerInstance) -> Dictionary:
	var customer_name: String = customer.get_display_name() if customer != null else "The customer"
	var result: Dictionary = {
		"accepted": false,
		"success": false,
		"reputation_delta": -1,
		"tips": 0,
		"matched_bonus_tags": 0,
		"message": "%s left disappointed." % customer_name,
	}
	if pastry == null or customer == null:
		return result
	if pastry.has_pastry_state(&"burned"):
		result["message"] = "%s refused the burned pastry." % customer.get_display_name()
		return result
	if not pastry.has_pastry_state(&"baked"):
		result["message"] = "%s expected the pastry to be fully baked." % customer.get_display_name()
		return result
	var required_tokens: PackedStringArray = customer.get_preferences()
	if not _pastry_matches_required_tokens(pastry, required_tokens):
		result["message"] = "%s did not get the pastry they asked for." % customer.get_display_name()
		return result
	if _pastry_matches_forbidden_tokens(pastry, customer.get_forbidden_tags()):
		result["message"] = "%s rejected the pastry outright." % customer.get_display_name()
		return result
	if pastry.quality < customer.get_minimum_quality():
		result["message"] = "%s expected a higher-quality pastry." % customer.get_display_name()
		return result
	var matched_bonus_tags: int = _count_matching_pastry_tokens(pastry, customer.get_bonus_tags())
	var reputation_delta: int = customer.get_base_reputation() + (matched_bonus_tags * customer.get_bonus_reputation_per_match())
	var tips_delta: int = customer.get_base_tips() + (matched_bonus_tags * customer.get_bonus_tips_per_match())
	var message: String = _build_pastry_success_message(customer, required_tokens, customer.get_bonus_tags(), matched_bonus_tags)
	result["accepted"] = true
	if customer.get_customer_type() == GameEnums.CustomerType.IMPATIENT and pastry.steps_used <= 2 and customer.turns_waited <= 1:
		reputation_delta += 1
		tips_delta += 1
		message = "%s was served quickly and got exactly what they wanted." % customer.get_display_name()
	if _customer_has_status(customer, &"critic_status") and not pastry.has_pastry_state(&"decorated"):
		reputation_delta = mini(reputation_delta, 0)
		tips_delta = mini(tips_delta, 0)
		message = "%s expected a more polished pastry." % customer.get_display_name()
	result["success"] = reputation_delta > 0 or tips_delta > 0
	result["reputation_delta"] = reputation_delta
	result["tips"] = tips_delta
	result["matched_bonus_tags"] = matched_bonus_tags
	result["message"] = message
	return result

func _pastry_matches_required_tokens(pastry: PastryInstance, required_tokens: PackedStringArray) -> bool:
	for required_token in required_tokens:
		if not _pastry_matches_token(pastry, String(required_token)):
			return false
	return true

func _pastry_matches_forbidden_tokens(pastry: PastryInstance, forbidden_tokens: PackedStringArray) -> bool:
	for forbidden_token in forbidden_tokens:
		if _pastry_matches_token(pastry, String(forbidden_token)):
			return true
	return false

func _count_matching_pastry_tokens(pastry: PastryInstance, tokens_to_match: PackedStringArray) -> int:
	var match_count: int = 0
	for token_to_match in tokens_to_match:
		if _pastry_matches_token(pastry, String(token_to_match)):
			match_count += 1
	return match_count

func _build_pastry_success_message(
	customer: CustomerInstance,
	required_tokens: PackedStringArray,
	bonus_tokens: PackedStringArray,
	matched_bonus_tags: int
) -> String:
	var customer_name: String = customer.get_display_name()
	if required_tokens.is_empty():
		return "%s was satisfied." % customer_name
	if matched_bonus_tags > 0 and not bonus_tokens.is_empty():
		return "%s got exactly what they wanted plus %d bonus flourish tag(s)." % [customer_name, matched_bonus_tags]
	return "%s got the pastry they asked for." % customer_name

func _pastry_matches_token(pastry: PastryInstance, token: String) -> bool:
	if pastry == null:
		return false
	var token_name: StringName = StringName(token)
	if token_name == &"":
		return false
	if token_name == &"quality":
		return pastry.quality > 0
	if token_name == &"unproofed":
		return bool(pastry.internal_flags.get(&"requires_proofing", false)) and not pastry.has_pastry_state(&"proofed")
	if pastry.dough_id == token_name:
		return true
	if bool(pastry.internal_flags.get(token_name, false)):
		return true
	return pastry.has_pastry_tag(token_name) or pastry.has_pastry_state(token_name)

func _score_item_for_customer(item: ItemInstance, customer: CustomerInstance) -> Dictionary:
	var result: Dictionary = {
		"reputation_delta": -1,
		"tips": 0,
		"message": "%s left disappointed." % customer.get_display_name(),
	}
	if item == null or customer == null:
		return result
	if item.has_tag(&"unservable") or item.get_item_id() == &"burned":
		return result
	if not item.has_tag(&"servable"):
		return result
	var required_tags: PackedStringArray = customer.get_preferences()
	if not _matches_required_tags(item, required_tags):
		result["message"] = "%s did not get the tags they asked for." % customer.get_display_name()
		return result
	if _matches_forbidden_tags(item, customer.get_forbidden_tags()):
		result["message"] = "%s rejected the pastry outright." % customer.get_display_name()
		return result
	if item.quality < customer.get_minimum_quality():
		result["message"] = "%s expected a higher-quality pastry." % customer.get_display_name()
		return result
	var matched_bonus_tags: int = _count_matching_tags(item, customer.get_bonus_tags())
	result["reputation_delta"] = customer.get_base_reputation() + (matched_bonus_tags * customer.get_bonus_reputation_per_match())
	result["tips"] = customer.get_base_tips() + (matched_bonus_tags * customer.get_bonus_tips_per_match())
	result["message"] = _build_tag_success_message(customer, required_tags, customer.get_bonus_tags(), matched_bonus_tags)
	if customer.get_customer_type() == GameEnums.CustomerType.IMPATIENT and item.steps_used <= 2 and customer.turns_waited <= 1:
		result["reputation_delta"] = int(result["reputation_delta"]) + 1
		result["tips"] = int(result["tips"]) + 1
		result["message"] = "%s was served quickly and got exactly what they wanted." % customer.get_display_name()
	if _customer_has_status(customer, &"critic_status") and not item.has_tag(&"decorated"):
		result["reputation_delta"] = mini(int(result["reputation_delta"]), 0)
		result["message"] = "%s expected a more polished pastry." % customer.get_display_name()
	return result

func _matches_required_tags(item: ItemInstance, required_tags: PackedStringArray) -> bool:
	for required_tag in required_tags:
		if not item.has_tag(StringName(required_tag)):
			return false
	return true

func _matches_forbidden_tags(item: ItemInstance, forbidden_tags: PackedStringArray) -> bool:
	for forbidden_tag in forbidden_tags:
		if item.has_tag(StringName(forbidden_tag)):
			return true
	return false

func _count_matching_tags(item: ItemInstance, tags_to_match: PackedStringArray) -> int:
	var match_count: int = 0
	for tag_to_match in tags_to_match:
		if item.has_tag(StringName(tag_to_match)):
			match_count += 1
	return match_count

func _build_tag_success_message(
	customer: CustomerInstance,
	required_tags: PackedStringArray,
	bonus_tags: PackedStringArray,
	matched_bonus_tags: int
) -> String:
	var customer_name: String = customer.get_display_name()
	if required_tags.is_empty():
		return "%s was satisfied." % customer_name
	if matched_bonus_tags > 0 and not bonus_tags.is_empty():
		return "%s got the tags they asked for plus %d extra flourish tag(s)." % [customer_name, matched_bonus_tags]
	return "%s got the tags they asked for." % customer_name

func _customer_has_status(customer: CustomerInstance, modifier_id: StringName) -> bool:
	for modifier in customer.active_statuses:
		if modifier != null and modifier.modifier_id == modifier_id:
			return true
	return false

func _collect_customer_indices(targets: Array) -> Array:
	var output: Array = []
	for target in targets:
		if StringName(target.get("zone", "")) == &"customer":
			output.append(int(target.get("index", -1)))
	return output

func _get_item_from_target(target: Dictionary) -> ItemInstance:
	var zone: StringName = StringName(target.get("zone", ""))
	var index: int = int(target.get("index", -1))
	if zone == &"prep" and index >= 0 and index < cafe_state.prep_items.size():
		return cafe_state.prep_items[index]
	if zone == &"table" and index >= 0 and index < cafe_state.table_items.size():
		return cafe_state.table_items[index]
	if zone == &"oven" and index >= 0 and index < cafe_state.oven_slots.size():
		var slot: OvenSlotState = cafe_state.oven_slots[index]
		if slot != null:
			return slot.item
	return null

func item_needs_proofing(item: ItemInstance) -> bool:
	return item != null and item.has_tag(&"proof_required")

func _can_bake_target(zone: StringName, index: int) -> bool:
	if zone == &"prep":
		if index < 0 or index >= cafe_state.prep_items.size():
			return false
		var prep_item: ItemInstance = cafe_state.prep_items[index]
		return prep_item != null and not item_needs_proofing(prep_item) and _first_empty_oven_slot() != null
	if zone == &"oven":
		if index < 0 or index >= cafe_state.oven_slots.size():
			return false
		var slot: OvenSlotState = cafe_state.oven_slots[index]
		return slot != null and slot.item != null and slot.stage == &"proofed"
	return false

func _can_proof_target(zone: StringName, index: int) -> bool:
	if zone != &"prep" or index < 0 or index >= cafe_state.prep_items.size():
		return false
	return item_needs_proofing(cafe_state.prep_items[index]) and _first_empty_oven_slot() != null

func _has_prepped_item_that_needs_proofing() -> bool:
	for prep_item in cafe_state.prep_items:
		if item_needs_proofing(prep_item):
			return true
	return false

func _is_slot_collect_ready(slot: OvenSlotState) -> bool:
	if slot == null or slot.item == null or slot.remaining_turns > 0:
		return false
	if slot.stage == &"":
		return slot.item.has_tag(&"baked")
	return slot.stage == &"ready"

func _first_empty_oven_slot() -> OvenSlotState:
	for slot in cafe_state.oven_slots:
		if slot != null and slot.item == null:
			return slot
	return null

func _rebuild_oven_slots() -> void:
	cafe_state.oven_slots.clear()
	for _index in range(cafe_state.oven_capacity):
		cafe_state.oven_slots.append(OvenSlotState.new())

func _to_packed_strings(values) -> PackedStringArray:
	var output: PackedStringArray = PackedStringArray()
	for value in values:
		output.append(String(value))
	return output

func _finish_run(won: bool, message: String) -> void:
	run_state.screen = GameEnums.Screen.SUMMARY
	run_state.run_phase = GameEnums.RunPhase.COMPLETE if won else GameEnums.RunPhase.FAILED
	run_state.won = won
	run_state.lost = not won
	var meta_reward: int = maxi(1, run_state.day_number) + player_state.reputation
	run_state.meta_currency_earned = meta_reward
	run_state.summary_message = "%s Reputation: %d. Run tips: %d. Satisfaction: %d. Gifted decorations: %s. Earned %d cafe tokens." % [
		message,
		player_state.reputation,
		player_state.tips,
		run_state.run_satisfaction_score,
		_format_decoration_name_list(run_state.gifted_decoration_ids_this_run),
		meta_reward,
	]
	if meta_profile_service != null:
		if won:
			meta_profile_service.unlock_customer(&"critic_boss")
		meta_profile_service.record_run_result(run_state.day_number, meta_reward)
	_set_status_message(run_state.summary_message)

func _set_status_message(message: String) -> void:
	run_state.status_message = message
	_last_status_message = message

func _append_status_message(message: String) -> void:
	if message == "":
		return
	if run_state.status_message == "":
		_set_status_message(message)
		return
	_set_status_message("%s %s" % [run_state.status_message, message])
