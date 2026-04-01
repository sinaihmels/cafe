class_name SessionService
extends Node

const HAND_SIZE: int = 5
const STARTER_CARD_PATHS: Array[String] = [
	"res://data/cards/starter_flour.tres",
	"res://data/cards/starter_butter.tres",
	"res://data/cards/starter_sugar.tres",
	"res://data/cards/starter_mix.tres",
	"res://data/cards/starter_bake.tres",
	"res://data/cards/starter_flour.tres",
	"res://data/cards/starter_butter.tres",
	"res://data/cards/starter_sugar.tres",
	"res://data/cards/starter_decorate.tres",
	"res://data/cards/starter_improvise.tres",
]
const RECIPE_PATHS: Array[String] = [
	"res://data/recipes/flour_butter_to_dough.tres",
	"res://data/recipes/dough_sugar_to_sweet_dough.tres",
	"res://data/recipes/dough_chocolate_to_chocolate_dough.tres",
	"res://data/recipes/bake_dough_to_pastry.tres",
	"res://data/recipes/bake_sweet_dough_to_sweet_pastry.tres",
	"res://data/recipes/bake_chocolate_dough_to_chocolate_pastry.tres",
	"res://data/recipes/decorate_pastry_to_decorated_pastry.tres",
	"res://data/recipes/decorate_sweet_pastry_to_perfect_sweet_pastry.tres",
]
const ITEM_PATHS: Dictionary = {
	&"flour": "res://data/ingredients/flour.tres",
	&"butter": "res://data/ingredients/butter.tres",
	&"sugar": "res://data/ingredients/sugar.tres",
	&"chocolate": "res://data/ingredients/chocolate.tres",
	&"cinnamon": "res://data/ingredients/cinnamon.tres",
	&"dough": "res://data/ingredients/dough.tres",
	&"sweet_dough": "res://data/ingredients/sweet_dough.tres",
	&"chocolate_dough": "res://data/ingredients/chocolate_dough.tres",
	&"pastry": "res://data/ingredients/pastry.tres",
	&"sweet_pastry": "res://data/ingredients/sweet_pastry.tres",
	&"chocolate_pastry": "res://data/ingredients/chocolate_pastry.tres",
	&"decorated_pastry": "res://data/ingredients/decorated_pastry.tres",
	&"perfect_sweet_pastry": "res://data/ingredients/perfect_sweet_pastry.tres",
	&"burned": "res://data/ingredients/burned.tres",
}
const REWARD_CARD_PATHS: Dictionary = {
	&"reward_chocolate": "res://data/cards/reward_chocolate.tres",
	&"reward_flash_bake": "res://data/cards/reward_flash_bake.tres",
	&"reward_cinnamon": "res://data/cards/reward_cinnamon.tres",
	&"reward_prep_ahead": "res://data/cards/reward_prep_ahead.tres",
	&"reward_clean_up": "res://data/cards/reward_clean_up.tres",
}
const DAY_CUSTOMERS: Dictionary = {
	1: ["res://data/customers/sweet_tooth_customer.tres"],
	2: [
		"res://data/customers/sweet_tooth_customer.tres",
		"res://data/customers/fast_customer.tres",
	],
	3: [
		"res://data/customers/sweet_tooth_customer.tres",
		"res://data/customers/quality_customer.tres",
		"res://data/customers/fast_customer.tres",
	],
	4: ["res://data/customers/critic_boss.tres"],
}

var run_state: RunState
var combat_state: CombatState
var player_state: PlayerState
var cafe_state: CafeState
var deck_state: DeckState

var _last_status_message: String = ""
var _day_started: bool = false

func start_new_run() -> void:
	randomize()
	run_state = RunState.new()
	run_state.day_number = 1
	run_state.run_phase = GameEnums.RunPhase.GAMEPLAY

	combat_state = CombatState.new()
	combat_state.turn_number = 1
	combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN

	player_state = PlayerState.new()
	player_state.energy = 3
	player_state.max_energy = 3
	player_state.reputation = 10
	player_state.max_reputation = 10

	cafe_state = CafeState.new()
	cafe_state.prep_space_capacity = 99
	cafe_state.serving_table_capacity = 3
	cafe_state.oven_capacity = 2
	_rebuild_oven_slots()

	deck_state = DeckState.new()
	load_starter_deck()
	_begin_day(1)
	_set_status_message("Day 1 begins. Build something sweet for the first customer.")

func load_starter_deck() -> void:
	var cards: Array[CardInstance] = []
	for path_value in STARTER_CARD_PATHS:
		var path: String = path_value
		var card_def: CardDef = load(path) as CardDef
		if card_def == null:
			continue
		var instance: CardInstance = CardInstance.new()
		instance.card_def = card_def
		cards.append(instance)
	deck_state.reset_from_cards(cards)

func draw_starting_hand(hand_size: int = HAND_SIZE) -> void:
	deck_state.draw_to_hand_size(hand_size)

func begin_player_turn() -> void:
	if run_state.run_phase != GameEnums.RunPhase.GAMEPLAY:
		return
	player_state.reset_turn_energy()
	advance_oven()
	deck_state.draw_to_hand_size(HAND_SIZE)

func end_player_turn_cleanup() -> void:
	deck_state.discard_all_hand()

func can_play_card(card: CardInstance) -> bool:
	if card == null:
		return false
	return player_state.energy >= card.get_cost()

func spend_energy(amount: int) -> void:
	player_state.energy = max(player_state.energy - amount, 0)

func is_run_over() -> bool:
	return player_state.reputation <= 0 or run_state.run_phase == GameEnums.RunPhase.RUN_END

func build_effect_context(card: CardInstance) -> EffectContext:
	var context: EffectContext = EffectContext.new()
	context.run_state = run_state
	context.combat_state = combat_state
	context.player_state = player_state
	context.cafe_state = cafe_state
	context.deck_state = deck_state
	context.session_service = self
	context.source_card = card
	return context

func get_required_target_count(card: CardInstance) -> int:
	if card == null or card.card_def == null:
		return 0
	match card.card_def.targeting_rules:
		"select_two_prep_items":
			return 2
		"select_one_prep_item", "select_one_baked_item", "select_one_item":
			return 1
		_:
			return 0

func get_target_prompt(card: CardInstance) -> String:
	if card == null or card.card_def == null:
		return ""
	match card.card_def.targeting_rules:
		"select_two_prep_items":
			return "Select 2 Prep items for Mix."
		"select_one_prep_item":
			return "Select 1 Prep item."
		"select_one_baked_item":
			return "Select 1 baked item on the table."
		"select_one_item":
			return "Select 1 item from Prep or Oven."
		_:
			return ""

func is_valid_target(card: CardInstance, zone: StringName, index: int) -> bool:
	if card == null or card.card_def == null:
		return false
	match card.card_def.targeting_rules:
		"select_two_prep_items":
			return zone == &"prep" and index >= 0 and index < cafe_state.prep_items.size()
		"select_one_prep_item":
			return zone == &"prep" and index >= 0 and index < cafe_state.prep_items.size()
		"select_one_baked_item":
			if zone != &"table" or index < 0 or index >= cafe_state.table_items.size():
				return false
			var item: ItemInstance = cafe_state.table_items[index]
			return item != null and item.has_tag(&"baked")
		"select_one_item":
			if zone == &"prep":
				return index >= 0 and index < cafe_state.prep_items.size()
			if zone == &"oven":
				return index >= 0 and index < cafe_state.oven_slots.size() and cafe_state.oven_slots[index].item != null
			return false
		_:
			return false

func spawn_item_in_prep(item_id: StringName) -> bool:
	if cafe_state.prep_items.size() >= cafe_state.prep_space_capacity:
		_set_status_message("Prep is full.")
		return false
	var item: ItemInstance = create_item_instance(item_id)
	if item == null:
		_set_status_message("Could not create %s." % [String(item_id)])
		return false
	item.zone = &"prep"
	cafe_state.prep_items.append(item)
	_set_status_message("Created %s in Prep." % [item.get_display_name()])
	return true

func mix_selected_prep_items(targets: Array) -> bool:
	if targets.size() != 2:
		_set_status_message("Mix needs exactly 2 Prep items.")
		return false
	var first_target: Dictionary = targets[0]
	var second_target: Dictionary = targets[1]
	var first_index: int = int(first_target.get("index", -1))
	var second_index: int = int(second_target.get("index", -1))
	if first_index == second_index:
		_set_status_message("Pick 2 different Prep items.")
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
		_set_status_message("Those items do not combine into a recipe.")
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
	if first_item.has_tag(&"cinnamon") or second_item.has_tag(&"cinnamon"):
		output.add_tag(&"cinnamon")
	cafe_state.prep_items.append(output)
	_set_status_message("Mixed into %s." % [output.get_display_name()])
	return true

func bake_selected_prep_item(targets: Array) -> bool:
	if targets.size() != 1:
		_set_status_message("Bake needs 1 Prep item.")
		return false
	var target: Dictionary = targets[0]
	var index: int = int(target.get("index", -1))
	if index < 0 or index >= cafe_state.prep_items.size():
		return false
	var slot: OvenSlotState = _first_empty_oven_slot()
	if slot == null:
		_set_status_message("No free Oven slot.")
		return false
	var item: ItemInstance = cafe_state.prep_items[index]
	cafe_state.prep_items.remove_at(index)
	item.zone = &"oven"
	slot.item = item
	slot.remaining_turns = 1
	_set_status_message("%s is baking." % [item.get_display_name()])
	return true

func flash_bake_selected_item(targets: Array, burn_chance: float) -> bool:
	if targets.size() != 1:
		_set_status_message("Flash Bake needs 1 Prep item.")
		return false
	var target: Dictionary = targets[0]
	var index: int = int(target.get("index", -1))
	if index < 0 or index >= cafe_state.prep_items.size():
		return false
	if cafe_state.table_items.size() >= cafe_state.serving_table_capacity:
		_set_status_message("Table is full.")
		return false
	var item: ItemInstance = cafe_state.prep_items[index]
	cafe_state.prep_items.remove_at(index)
	var result_item: ItemInstance
	if randf() < burn_chance:
		result_item = create_item_instance(&"burned")
		result_item.steps_used = item.steps_used + 1
		_set_status_message("Flash Bake burned the item.")
	else:
		result_item = _create_baked_result(item)
		if result_item == null:
			cafe_state.prep_items.insert(index, item)
			_set_status_message("That item cannot be baked.")
			return false
		_set_status_message("%s was flash baked." % [result_item.get_display_name()])
	result_item.zone = &"table"
	cafe_state.table_items.append(result_item)
	return true

func decorate_selected_table_item(targets: Array) -> bool:
	if targets.size() != 1:
		_set_status_message("Decorate needs 1 baked item.")
		return false
	var target: Dictionary = targets[0]
	var index: int = int(target.get("index", -1))
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
	if item.has_tag(&"cinnamon"):
		output.add_tag(&"cinnamon")
	cafe_state.table_items[index] = output
	_set_status_message("Decorated into %s." % [output.get_display_name()])
	return true

func remove_selected_item(targets: Array) -> bool:
	if targets.size() != 1:
		return false
	var target: Dictionary = targets[0]
	var zone: StringName = StringName(target.get("zone", ""))
	var index: int = int(target.get("index", -1))
	if zone == &"prep" and index >= 0 and index < cafe_state.prep_items.size():
		var item: ItemInstance = cafe_state.prep_items[index]
		cafe_state.prep_items.remove_at(index)
		_set_status_message("Removed %s from Prep." % [item.get_display_name()])
		return true
	if zone == &"oven" and index >= 0 and index < cafe_state.oven_slots.size():
		var slot: OvenSlotState = cafe_state.oven_slots[index]
		if slot.item == null:
			return false
		var removed_name: String = slot.item.get_display_name()
		slot.item = null
		slot.remaining_turns = 0
		_set_status_message("Removed %s from the Oven." % [removed_name])
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
	_set_status_message("%s moved from the oven to the table." % [item.get_display_name()])
	return true

func serve_item_to_customer(customer_index: int, item_index: int) -> bool:
	if customer_index < 0 or customer_index >= combat_state.active_customers.size():
		return false
	if item_index < 0 or item_index >= cafe_state.table_items.size():
		return false
	var customer: CustomerInstance = combat_state.active_customers[customer_index]
	var item: ItemInstance = cafe_state.table_items[item_index]
	var outcome: Dictionary = _score_item_for_customer(item, customer)
	var reputation_delta: int = int(outcome.get("reputation_delta", 0))
	var message: String = String(outcome.get("message", ""))
	_apply_reputation_delta(reputation_delta)
	cafe_state.table_items.remove_at(item_index)
	combat_state.active_customers.remove_at(customer_index)
	_set_status_message("%s %s" % [customer.get_display_name(), message])
	_resolve_phase_after_customer_change()
	return true

func process_customer_turn() -> void:
	var remaining_customers: Array[CustomerInstance] = []
	var penalty_applied: bool = false
	var timeout_count: int = 0
	for customer in combat_state.active_customers:
		if customer == null:
			continue
		customer.turns_waited += 1
		customer.current_patience -= 1
		if customer.current_patience <= 0:
			_apply_reputation_delta(-3)
			penalty_applied = true
			timeout_count += 1
			continue
		remaining_customers.append(customer)
	combat_state.active_customers = remaining_customers
	if penalty_applied:
		_set_status_message("%d customer(s) left unhappy. Reputation -%d." % [timeout_count, timeout_count * 3])
	if player_state.reputation <= 0:
		_finish_run(false, "The cafe lost all reputation.")
		return
	if combat_state.active_customers.is_empty() and penalty_applied:
		if run_state.day_number >= 4:
			_finish_run(false, "The critic left disappointed.")
			return
		_set_status_message("The day ended with no customers left. Moving on without a reward.")
		_begin_day(run_state.day_number + 1)
		return
	_resolve_phase_after_customer_change()

func choose_reward(reward_id: StringName) -> void:
	if not run_state.pending_reward_ids.has(reward_id):
		return
	if reward_id == &"oven_capacity_upgrade":
		cafe_state.oven_capacity += 1
		var slot: OvenSlotState = OvenSlotState.new()
		cafe_state.oven_slots.append(slot)
		_set_status_message("Reward chosen: +1 Oven Slot.")
	else:
		var reward_card: CardInstance = _create_card_instance(String(REWARD_CARD_PATHS.get(reward_id, "")))
		if reward_card != null:
			deck_state.add_to_discard(reward_card)
			run_state.unlocked_ids.append(reward_id)
			_set_status_message("Reward chosen: %s added to your deck." % [reward_card.get_display_name()])
	run_state.pending_reward_ids.clear()
	_begin_day(run_state.day_number + 1)

func choose_event_option(option_id: StringName) -> void:
	if not run_state.pending_event_option_ids.has(option_id):
		return
	if option_id == &"improvise":
		var cinnamon_card: CardInstance = _create_card_instance(String(REWARD_CARD_PATHS.get(&"reward_cinnamon", "")))
		if cinnamon_card != null:
			deck_state.add_to_discard(cinnamon_card)
		run_state.unlocked_ids.append(&"reward_cinnamon")
		_set_status_message("You improvised and gained Cinnamon.")
	else:
		_apply_reputation_delta(1)
		_set_status_message("You played it safe and earned +1 reputation.")
	run_state.pending_event_id = &""
	run_state.pending_event_description = ""
	run_state.pending_event_option_ids.clear()
	_begin_day(run_state.day_number + 1)

func create_item_instance(item_id: StringName) -> ItemInstance:
	var item_path: String = String(ITEM_PATHS.get(item_id, ""))
	if item_path == "":
		return null
	var item_def: ItemDef = load(item_path) as ItemDef
	if item_def == null:
		return null
	var instance: ItemInstance = ItemInstance.new()
	instance.item_def = item_def
	instance.created_turn = combat_state.turn_number
	return instance

func pop_status_message() -> String:
	var message: String = _last_status_message
	_last_status_message = ""
	return message

func consume_day_started() -> bool:
	var started: bool = _day_started
	_day_started = false
	return started

func advance_oven() -> void:
	for slot in cafe_state.oven_slots:
		if slot == null or slot.item == null:
			continue
		if slot.remaining_turns > 0:
			slot.remaining_turns -= 1
		if slot.remaining_turns <= 0:
			if slot.item.has_tag(&"baked"):
				continue
			var result_item: ItemInstance = _create_baked_result(slot.item)
			if result_item == null:
				continue
			result_item.zone = &"oven"
			slot.item = result_item
			slot.remaining_turns = 0
			_set_status_message("%s is ready in the oven." % [result_item.get_display_name()])

func _begin_day(day_number: int) -> void:
	_day_started = true
	run_state.day_number = day_number
	run_state.run_phase = GameEnums.RunPhase.GAMEPLAY
	run_state.pending_reward_ids.clear()
	run_state.pending_event_id = &""
	run_state.pending_event_description = ""
	run_state.pending_event_option_ids.clear()
	combat_state.turn_number = 1
	combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN
	deck_state.discard_all_hand()
	combat_state.active_customers = _create_customers_for_day(day_number)

func _create_customers_for_day(day_number: int) -> Array[CustomerInstance]:
	var customers: Array[CustomerInstance] = []
	var customer_paths: Array = DAY_CUSTOMERS.get(day_number, [])
	for customer_path_value in customer_paths:
		var customer_path: String = String(customer_path_value)
		var customer_def: CustomerDef = load(customer_path) as CustomerDef
		if customer_def == null:
			continue
		var customer: CustomerInstance = CustomerInstance.new()
		customer.customer_def = customer_def
		customer.current_patience = customer_def.patience
		customers.append(customer)
	return customers

func _resolve_phase_after_customer_change() -> void:
	if player_state.reputation <= 0:
		_finish_run(false, "The cafe lost all reputation.")
		return
	if not combat_state.active_customers.is_empty():
		return
	match run_state.day_number:
		1:
			run_state.run_phase = GameEnums.RunPhase.REWARD
			run_state.pending_reward_ids = PackedStringArray([
				"reward_chocolate",
				"reward_flash_bake",
				"oven_capacity_upgrade",
			])
			_set_status_message("Day 1 clear. Choose a reward.")
		2:
			run_state.run_phase = GameEnums.RunPhase.EVENT
			run_state.pending_event_id = &"regular_surprise"
			run_state.pending_event_description = "A regular says: Surprise me."
			run_state.pending_event_option_ids = PackedStringArray(["improvise", "play_it_safe"])
			_set_status_message("Event: a regular asks for a surprise.")
		3:
			_set_status_message("Day 3 clear. The critic arrives next.")
			_begin_day(4)
		4:
			_finish_run(true, "The critic was impressed. The run is complete.")

func _finish_run(won: bool, message: String) -> void:
	run_state.run_phase = GameEnums.RunPhase.RUN_END
	if won:
		if not run_state.unlocked_ids.has(&"reward_chocolate"):
			run_state.unlocked_ids.append(&"reward_chocolate")
		if not run_state.unlocked_ids.has(&"reward_cinnamon"):
			run_state.unlocked_ids.append(&"reward_cinnamon")
		if not run_state.unlocked_ids.has(&"impatient_customer_unlock"):
			run_state.unlocked_ids.append(&"impatient_customer_unlock")
		run_state.summary_message = "%s Unlocked: Chocolate, Cinnamon, Impatient Customer." % [message]
	else:
		run_state.summary_message = message
	_set_status_message(run_state.summary_message)

func _apply_reputation_delta(delta: int) -> void:
	player_state.reputation = max(player_state.reputation + delta, 0)
	player_state.max_reputation = maxi(player_state.max_reputation, player_state.reputation)

func _find_recipe(input_item_ids: PackedStringArray, station: StringName) -> RecipeDef:
	for recipe_path in RECIPE_PATHS:
		var recipe: RecipeDef = load(recipe_path) as RecipeDef
		if recipe == null:
			continue
		if recipe.station != station:
			continue
		if _same_inputs(recipe.input_item_ids, input_item_ids):
			return recipe
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
	for index: int in range(left_copy.size()):
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
	result_item.quality = item.quality
	if item.has_tag(&"cinnamon"):
		result_item.add_tag(&"cinnamon")
	return result_item

func _score_item_for_customer(item: ItemInstance, customer: CustomerInstance) -> Dictionary:
	var result: Dictionary = {
		"reputation_delta": -2,
		"message": "was disappointed.",
	}
	if item == null or customer == null:
		return result
	if item.has_tag(&"unservable") or item.get_item_id() == &"burned":
		return result
	match customer.get_order_id():
		&"sweet_request":
			if not item.has_tag(&"sweet"):
				return result
			if item.has_tag(&"perfect") or (item.has_tag(&"decorated") and item.quality >= 1):
				result["reputation_delta"] = 3
				result["message"] = "loved the perfect sweet pastry. Reputation +3."
			else:
				result["reputation_delta"] = 2
				result["message"] = "got something sweet. Reputation +2."
		&"fast_request":
			if not item.has_tag(&"servable"):
				return result
			if item.steps_used <= 2 and customer.turns_waited <= 1:
				result["reputation_delta"] = 1
				result["message"] = "was served fast enough. Reputation +1."
			else:
				result["reputation_delta"] = 0
				result["message"] = "accepted the quick serve, but it was not impressive."
		&"quality_request":
			if item.has_tag(&"decorated") and item.quality >= 1:
				result["reputation_delta"] = 2
				if item.has_tag(&"perfect"):
					result["reputation_delta"] = 3
				result["message"] = "appreciated the quality. Reputation +%d." % [int(result.get("reputation_delta", 0))]
			else:
				result["reputation_delta"] = 0
				result["message"] = "wanted higher quality."
		&"sweet_decorated_request":
			if item.has_tag(&"sweet") and item.has_tag(&"decorated"):
				result["reputation_delta"] = 3
				result["message"] = "praised the special pastry. Reputation +3."
			else:
				return result
		_:
			if item.has_tag(&"servable"):
				result["reputation_delta"] = 1
				result["message"] = "was satisfied. Reputation +1."
	if item.has_tag(&"cinnamon") and int(result.get("reputation_delta", 0)) > 0:
		result["reputation_delta"] = int(result.get("reputation_delta", 0)) + 1
		result["message"] = "%s Cinnamon added +1 reputation." % [String(result.get("message", ""))]
	return result

func _first_empty_oven_slot() -> OvenSlotState:
	for slot in cafe_state.oven_slots:
		if slot != null and slot.item == null:
			return slot
	return null

func _rebuild_oven_slots() -> void:
	cafe_state.oven_slots.clear()
	for _index: int in range(cafe_state.oven_capacity):
		var slot: OvenSlotState = OvenSlotState.new()
		cafe_state.oven_slots.append(slot)

func _create_card_instance(card_path: String) -> CardInstance:
	if card_path == "":
		return null
	var card_def: CardDef = load(card_path) as CardDef
	if card_def == null:
		return null
	var card: CardInstance = CardInstance.new()
	card.card_def = card_def
	return card

func _set_status_message(message: String) -> void:
	_last_status_message = message
