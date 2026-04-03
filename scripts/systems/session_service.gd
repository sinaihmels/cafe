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
	cafe_state.prep_space_capacity = BASE_PREP_CAPACITY
	cafe_state.serving_table_capacity = BASE_TABLE_CAPACITY
	cafe_state.oven_capacity = BASE_OVEN_CAPACITY
	_rebuild_oven_slots()
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
		if upgrade == null:
			continue
		for modifier_id in upgrade.passive_modifier_ids:
			add_passive_modifier(modifier_id, &"shop_upgrade", upgrade.upgrade_id)

func _apply_dough_passives(dough: DoughDef) -> void:
	for modifier_id in dough.passive_modifier_ids:
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
	run_state.day_number = day_number
	run_state.pending_day_number = 0
	run_state.encounter_index = maxi(0, day_number - 1)
	run_state.current_customer_ids = _to_packed_strings(ENCOUNTER_CUSTOMERS.get(day_number, []))
	run_state.pending_reward_ids.clear()
	run_state.pending_shop_offer_ids.clear()
	run_state.screen = GameEnums.Screen.ENCOUNTER
	run_state.run_phase = GameEnums.RunPhase.ENCOUNTER
	combat_state.turn_number = 1
	combat_state.turn_state = GameEnums.TurnState.IDLE
	cafe_state.prep_items.clear()
	cafe_state.table_items.clear()
	_rebuild_oven_slots()
	_rebuild_deck_from_master_ids()
	if not _create_prepped_day_dough(dough):
		return
	combat_state.active_customers = _create_customers(run_state.current_customer_ids)
	begin_player_turn(true)
	_set_status_message("Day %d begins with %s prepped. Modify it, bake it, then serve before patience runs out." % [day_number, dough.display_name])

func _rebuild_deck_from_master_ids() -> void:
	var cards: Array[CardInstance] = []
	for card_id in player_state.master_deck_ids:
		var instance: CardInstance = content_library.build_card_instance(StringName(card_id))
		if instance != null:
			cards.append(instance)
	deck_state.reset_from_cards(cards)

func _create_customers(customer_ids: PackedStringArray) -> Array[CustomerInstance]:
	var output: Array[CustomerInstance] = []
	for customer_id in customer_ids:
		var customer_def: CustomerDef = content_library.get_customer(StringName(customer_id))
		if customer_def == null:
			continue
		var customer: CustomerInstance = CustomerInstance.new()
		customer.reset_from_def(customer_def)
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
	if not is_new_day:
		advance_oven()
	_trigger_player_modifier_hooks(&"turn_start")
	_tick_item_statuses_turn_start()
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
	return player_state.energy >= card.get_cost()

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
		"select_two_prep_items":
			return 2
		"select_one_customer_and_one_table_item":
			return 2
		"select_one_prep_item", "select_one_baked_item", "select_one_item", "select_one_customer":
			return 1
		_:
			return 0

func get_target_prompt(card: CardInstance) -> String:
	if card == null or card.card_def == null:
		return ""
	match card.card_def.targeting_rules:
		"select_two_prep_items":
			return "Select 2 prep items."
		"select_one_customer_and_one_table_item":
			return "Select 1 customer and 1 table item."
		"select_one_prep_item":
			return "Select 1 prep item."
		"select_one_baked_item":
			return "Select 1 baked item on the table."
		"select_one_item":
			return "Select 1 item from prep or oven."
		"select_one_customer":
			return "Select 1 customer."
		_:
			return ""

func is_valid_target(card: CardInstance, zone: StringName, index: int) -> bool:
	if card == null or card.card_def == null:
		return false
	match card.card_def.targeting_rules:
		"select_two_prep_items":
			return zone == &"prep" and index >= 0 and index < cafe_state.prep_items.size()
		"select_one_customer_and_one_table_item":
			if zone == &"customer":
				return index >= 0 and index < combat_state.active_customers.size()
			if zone == &"table":
				return index >= 0 and index < cafe_state.table_items.size()
			return false
		"select_one_prep_item":
			return zone == &"prep" and index >= 0 and index < cafe_state.prep_items.size()
		"select_one_baked_item":
			if zone != &"table" or index < 0 or index >= cafe_state.table_items.size():
				return false
			var table_item: ItemInstance = cafe_state.table_items[index]
			return table_item != null and table_item.has_tag(&"baked")
		"select_one_item":
			if zone == &"prep":
				return index >= 0 and index < cafe_state.prep_items.size()
			if zone == &"oven":
				return index >= 0 and index < cafe_state.oven_slots.size() and cafe_state.oven_slots[index].item != null
			return false
		"select_one_customer":
			return zone == &"customer" and index >= 0 and index < combat_state.active_customers.size()
		_:
			return false

func get_valid_targets(card: CardInstance) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if card == null or card.card_def == null:
		return targets
	match card.card_def.targeting_rules:
		"select_two_prep_items", "select_one_prep_item":
			for prep_index in range(cafe_state.prep_items.size()):
				if is_valid_target(card, &"prep", prep_index):
					targets.append({
						"zone": &"prep",
						"index": prep_index,
					})
		"select_one_customer_and_one_table_item":
			for customer_index in range(combat_state.active_customers.size()):
				if is_valid_target(card, &"customer", customer_index):
					targets.append({
						"zone": &"customer",
						"index": customer_index,
					})
			for table_index in range(cafe_state.table_items.size()):
				if is_valid_target(card, &"table", table_index):
					targets.append({
						"zone": &"table",
						"index": table_index,
					})
		"select_one_baked_item":
			for table_index in range(cafe_state.table_items.size()):
				if is_valid_target(card, &"table", table_index):
					targets.append({
						"zone": &"table",
						"index": table_index,
					})
		"select_one_item":
			for prep_index in range(cafe_state.prep_items.size()):
				if is_valid_target(card, &"prep", prep_index):
					targets.append({
						"zone": &"prep",
						"index": prep_index,
					})
			for oven_index in range(cafe_state.oven_slots.size()):
				if is_valid_target(card, &"oven", oven_index):
					targets.append({
						"zone": &"oven",
						"index": oven_index,
					})
		"select_one_customer":
			for customer_index in range(combat_state.active_customers.size()):
				if is_valid_target(card, &"customer", customer_index):
					targets.append({
						"zone": &"customer",
						"index": customer_index,
					})
	return targets

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
	after_card_played(card)
	return true

func spawn_item_in_prep(item_id: StringName) -> bool:
	if cafe_state.prep_items.size() >= cafe_state.prep_space_capacity:
		_set_status_message("Prep is full.")
		return false
	var item: ItemInstance = create_item_instance(item_id)
	if item == null:
		_set_status_message("Could not create %s." % String(item_id))
		return false
	item.zone = &"prep"
	cafe_state.prep_items.append(item)
	_set_status_message("Created %s in prep." % item.get_display_name())
	return true

func mix_selected_prep_items(targets: Array) -> bool:
	if targets.size() != 2:
		_set_status_message("Mix needs exactly 2 prep items.")
		return false
	var first_index: int = int(targets[0].get("index", -1))
	var second_index: int = int(targets[1].get("index", -1))
	if first_index == second_index:
		_set_status_message("Select 2 different prep items.")
		return false
	if first_index < 0 or second_index < 0:
		return false
	if first_index >= cafe_state.prep_items.size() or second_index >= cafe_state.prep_items.size():
		return false
	var first_item: ItemInstance = cafe_state.prep_items[first_index]
	var second_item: ItemInstance = cafe_state.prep_items[second_index]
	var recipe: RecipeDef = _find_recipe(
		PackedStringArray([String(first_item.get_item_id()), String(second_item.get_item_id())]),
		&"prep"
	)
	if recipe == null:
		_set_status_message("Those items do not combine into a valid recipe.")
		return false
	var max_index: int = maxi(first_index, second_index)
	var min_index: int = mini(first_index, second_index)
	cafe_state.prep_items.remove_at(max_index)
	cafe_state.prep_items.remove_at(min_index)
	var output: ItemInstance = create_item_instance(recipe.output_item_id)
	if output == null:
		return false
	output.zone = &"prep"
	output.steps_used = maxi(first_item.steps_used, second_item.steps_used) + 1
	output.quality = maxi(first_item.quality, second_item.quality) + recipe.quality_delta
	for tag in recipe.added_tags:
		output.add_tag(StringName(tag))
	if first_item.has_tag(&"cinnamon") or second_item.has_tag(&"cinnamon"):
		output.add_tag(&"cinnamon")
	if first_item.has_tag(&"cream") or second_item.has_tag(&"cream"):
		output.add_tag(&"cream")
	cafe_state.prep_items.append(output)
	_set_status_message("Mixed into %s." % output.get_display_name())
	return true

func bake_selected_prep_item(targets: Array) -> bool:
	if targets.size() != 1:
		_set_status_message("Bake needs 1 prep item.")
		return false
	var index: int = int(targets[0].get("index", -1))
	if index < 0 or index >= cafe_state.prep_items.size():
		return false
	var slot: OvenSlotState = _first_empty_oven_slot()
	if slot == null:
		_set_status_message("No free oven slot.")
		return false
	var item: ItemInstance = cafe_state.prep_items[index]
	cafe_state.prep_items.remove_at(index)
	item.zone = &"oven"
	slot.item = item
	slot.remaining_turns = 1
	_set_status_message("%s is baking." % item.get_display_name())
	return true

func flash_bake_selected_item(targets: Array, burn_chance: float) -> bool:
	if targets.size() != 1:
		_set_status_message("Flash Bake needs 1 prep item.")
		return false
	var index: int = int(targets[0].get("index", -1))
	if index < 0 or index >= cafe_state.prep_items.size():
		return false
	if cafe_state.table_items.size() >= cafe_state.serving_table_capacity:
		_set_status_message("Table is full.")
		return false
	var item: ItemInstance = cafe_state.prep_items[index]
	cafe_state.prep_items.remove_at(index)
	var result_item: ItemInstance = null
	if randf() < burn_chance:
		result_item = create_item_instance(&"burned")
		if result_item != null:
			result_item.steps_used = item.steps_used + 1
		_set_status_message("Flash Bake burned the item.")
	else:
		result_item = _create_baked_result(item)
		if result_item == null:
			cafe_state.prep_items.insert(index, item)
			_set_status_message("That item cannot be baked.")
			return false
		_set_status_message("%s was flash baked." % result_item.get_display_name())
	if result_item == null:
		return false
	result_item.zone = &"table"
	cafe_state.table_items.append(result_item)
	_notify_item_baked(result_item, [{"zone": &"table", "index": cafe_state.table_items.size() - 1}])
	return true
func decorate_selected_table_item(targets: Array) -> bool:
	if targets.size() != 1:
		_set_status_message("Decorate needs 1 baked item.")
		return false
	var index: int = int(targets[0].get("index", -1))
	if index < 0 or index >= cafe_state.table_items.size():
		return false
	var item: ItemInstance = cafe_state.table_items[index]
	var recipe: RecipeDef = _find_recipe(PackedStringArray([String(item.get_item_id())]), &"prep")
	if recipe == null:
		_set_status_message("That item cannot be decorated.")
		return false
	var output: ItemInstance = create_item_instance(recipe.output_item_id)
	if output == null:
		return false
	output.zone = &"table"
	output.steps_used = item.steps_used + 1
	output.quality = item.quality + recipe.quality_delta
	for tag in recipe.added_tags:
		output.add_tag(StringName(tag))
	if item.has_tag(&"cinnamon"):
		output.add_tag(&"cinnamon")
	cafe_state.table_items[index] = output
	_set_status_message("Decorated into %s." % output.get_display_name())
	return true

func remove_selected_item(targets: Array) -> bool:
	if targets.size() != 1:
		return false
	var zone: StringName = StringName(targets[0].get("zone", ""))
	var index: int = int(targets[0].get("index", -1))
	if zone == &"prep" and index >= 0 and index < cafe_state.prep_items.size():
		var prep_item: ItemInstance = cafe_state.prep_items[index]
		cafe_state.prep_items.remove_at(index)
		_set_status_message("Removed %s from prep." % prep_item.get_display_name())
		return true
	if zone == &"oven" and index >= 0 and index < cafe_state.oven_slots.size():
		var slot: OvenSlotState = cafe_state.oven_slots[index]
		if slot.item == null:
			return false
		var removed_name: String = slot.item.get_display_name()
		slot.item = null
		slot.remaining_turns = 0
		_set_status_message("Removed %s from the oven." % removed_name)
		return true
	return false

func can_collect_oven_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= cafe_state.oven_slots.size():
		return false
	var slot: OvenSlotState = cafe_state.oven_slots[slot_index]
	return slot != null and slot.item != null and slot.remaining_turns <= 0

func collect_oven_item(slot_index: int) -> bool:
	if not can_collect_oven_item(slot_index):
		return false
	if cafe_state.table_items.size() >= cafe_state.serving_table_capacity:
		_set_status_message("Table is full.")
		return false
	var slot: OvenSlotState = cafe_state.oven_slots[slot_index]
	var item: ItemInstance = slot.item
	item.zone = &"table"
	cafe_state.table_items.append(item)
	slot.item = null
	slot.remaining_turns = 0
	_set_status_message("%s moved from the oven to the table." % item.get_display_name())
	return true

func serve_item_to_customer(customer_index: int, item_index: int) -> bool:
	if customer_index < 0 or customer_index >= combat_state.active_customers.size():
		return false
	if item_index < 0 or item_index >= cafe_state.table_items.size():
		return false
	var customer: CustomerInstance = combat_state.active_customers[customer_index]
	var item: ItemInstance = cafe_state.table_items[item_index]
	var outcome: Dictionary = _score_item_for_customer(item, customer)
	apply_reputation_delta(int(outcome.get("reputation_delta", 0)))
	player_state.gain_tips(int(outcome.get("tips", 0)))
	cafe_state.table_items.remove_at(item_index)
	combat_state.active_customers.remove_at(customer_index)
	_notify_customer_served(customer, item)
	_set_status_message(String(outcome.get("message", "Served a customer.")))
	if combat_state.active_customers.is_empty():
		_advance_after_encounter_clear()
	return true

func serve_targets(targets: Array[Dictionary]) -> bool:
	var customer_index: int = -1
	var item_index: int = -1
	for target in targets:
		var zone: StringName = StringName(target.get("zone", ""))
		var index: int = int(target.get("index", -1))
		if zone == &"customer":
			customer_index = index
		elif zone == &"table":
			item_index = index
	if customer_index == -1 or item_index == -1:
		_set_status_message("Serve needs 1 customer and 1 table item.")
		return false
	return serve_item_to_customer(customer_index, item_index)

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
	_set_status_message("The Final Critic is waiting. Choose the dough you want to prep for the boss day.")

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
	for slot_index in range(cafe_state.oven_slots.size()):
		var slot: OvenSlotState = cafe_state.oven_slots[slot_index]
		if slot == null or slot.item == null:
			continue
		if slot.remaining_turns > 0:
			slot.remaining_turns -= 1
		if slot.remaining_turns <= 0 and not slot.item.has_tag(&"baked"):
			var result_item: ItemInstance = _create_baked_result(slot.item)
			if result_item == null:
				continue
			result_item.zone = &"oven"
			result_item.active_statuses = slot.item.active_statuses.duplicate(true)
			slot.item = result_item
			slot.remaining_turns = 0
			_add_modifier_to_collection(
				result_item.active_statuses,
				GameEnums.ModifierTarget.ITEM,
				&"warm_status",
				&"oven",
				result_item.get_item_id(),
				1
			)
			_notify_item_baked(result_item, [{"zone": &"oven", "index": slot_index}])
			_set_status_message("%s is ready in the oven." % result_item.get_display_name())

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
	for customer_index in range(combat_state.active_customers.size()):
		var customer: CustomerInstance = combat_state.active_customers[customer_index]
		if customer == null:
			continue
		_trigger_customer_modifier_hooks(customer_index, &"turn_end")
		customer.turns_waited += 1
		customer.current_patience -= 1
		if customer.current_patience <= 0:
			var stress_damage: int = customer.customer_def.stress_damage if customer.customer_def != null else 2
			player_state.lose_stress(stress_damage)
			total_stress_loss += stress_damage
			unhappy_departures += 1
			continue
		remaining_customers.append(customer)
	combat_state.active_customers = remaining_customers
	if unhappy_departures > 0:
		_set_status_message("%d customer(s) left upset. Stress -%d." % [unhappy_departures, total_stress_loss])
	if player_state.stress <= 0:
		_finish_run(false, "The bakery became too stressful to continue.")
		return
	if combat_state.active_customers.is_empty():
		_advance_after_encounter_clear()

func _advance_after_encounter_clear() -> void:
	match run_state.day_number:
		1:
			run_state.screen = GameEnums.Screen.REWARD
			run_state.run_phase = GameEnums.RunPhase.REWARD
			run_state.pending_reward_ids = _to_packed_strings(DAY_REWARD_IDS.get(1, []))
			_set_status_message("Day 1 complete. Choose a reward for the run.")
		2:
			run_state.screen = GameEnums.Screen.RUN_SHOP
			run_state.run_phase = GameEnums.RunPhase.RUN_SHOP
			run_state.pending_shop_offer_ids = _to_packed_strings(DAY_SHOP_OFFER_IDS.get(2, []))
			_set_status_message("Day 2 complete. Spend your run tips in the shop.")
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

func _notify_customer_served(customer: CustomerInstance, item: ItemInstance) -> void:
	if event_bus != null and customer != null and customer.customer_def != null:
		event_bus.emit_customer_served(customer.customer_def.customer_id)
	_trigger_player_modifier_hooks(&"customer_served")

func _notify_item_baked(item: ItemInstance, targets: Array) -> void:
	if event_bus != null and item != null:
		event_bus.emit_item_baked(item.get_item_id())
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

func after_card_played(card: CardInstance) -> void:
	if event_bus != null and card != null:
		event_bus.emit_card_played(card)
	_run_modifier_effects_from_collection(player_state.passive_modifiers, &"card_played")
	_run_modifier_effects_from_collection(player_state.active_buffs, &"card_played")
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
	for tag in recipe.added_tags:
		result_item.add_tag(StringName(tag))
	if item.has_tag(&"cinnamon"):
		result_item.add_tag(&"cinnamon")
	if item.has_tag(&"cream"):
		result_item.add_tag(&"cream")
	result_item.add_tag(&"warm")
	return result_item

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

func _first_empty_oven_slot() -> OvenSlotState:
	for slot in cafe_state.oven_slots:
		if slot != null and slot.item == null:
			return slot
	return null

func _rebuild_oven_slots() -> void:
	cafe_state.oven_slots.clear()
	for _index in range(cafe_state.oven_capacity):
		cafe_state.oven_slots.append(OvenSlotState.new())

func _to_packed_strings(values: Array) -> PackedStringArray:
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
	run_state.summary_message = "%s Reputation: %d. Run tips: %d. Earned %d cafe tokens." % [message, player_state.reputation, player_state.tips, meta_reward]
	if meta_profile_service != null:
		if won:
			meta_profile_service.unlock_customer(&"critic_boss")
		meta_profile_service.record_run_result(run_state.day_number, meta_reward)
	_set_status_message(run_state.summary_message)

func _set_status_message(message: String) -> void:
	run_state.status_message = message
	_last_status_message = message
