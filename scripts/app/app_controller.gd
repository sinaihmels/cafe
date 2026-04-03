class_name AppController
extends Node

@export_node_path("SessionService") var session_service_path: NodePath
@export_node_path("SaveService") var meta_profile_service_path: NodePath
@export_node_path("EventBus") var event_bus_path: NodePath
@export_node_path("EffectQueueService") var effect_queue_path: NodePath
@export_node_path("AppView") var app_view_path: NodePath

@onready var _session_service: SessionService = get_node(session_service_path)
@onready var _meta_profile_service: SaveService = get_node(meta_profile_service_path)
@onready var _event_bus: EventBus = get_node(event_bus_path)
@onready var _effect_queue: EffectQueueService = get_node(effect_queue_path)
@onready var _app_view: AppView = get_node(app_view_path)

var _pending_card_index: int = -1
var _pending_targets: Array[Dictionary] = []

func _ready() -> void:
	_effect_queue.configure(_event_bus)
	_effect_queue.resolution_started.connect(_on_resolution_started)
	_effect_queue.resolution_finished.connect(_on_resolution_finished)
	_connect_view()
	_session_service.initialize(_meta_profile_service, _event_bus)
	_refresh_view()

func _connect_view() -> void:
	_app_view.continue_from_title_requested.connect(_on_continue_from_title_requested)
	_app_view.reset_profile_requested.connect(_on_reset_profile_requested)
	_app_view.open_dough_select_requested.connect(_on_open_dough_select_requested)
	_app_view.open_decoration_requested.connect(_on_open_decoration_requested)
	_app_view.close_decoration_requested.connect(_on_close_decoration_requested)
	_app_view.start_run_requested.connect(_on_start_run_requested)
	_app_view.buy_upgrade_requested.connect(_on_buy_upgrade_requested)
	_app_view.buy_decoration_requested.connect(_on_buy_decoration_requested)
	_app_view.place_decoration_requested.connect(_on_place_decoration_requested)
	_app_view.toggle_equipment_requested.connect(_on_toggle_equipment_requested)
	_app_view.choose_reward_requested.connect(_on_choose_reward_requested)
	_app_view.buy_offer_requested.connect(_on_buy_offer_requested)
	_app_view.continue_after_shop_requested.connect(_on_continue_after_shop_requested)
	_app_view.return_to_hub_requested.connect(_on_return_to_hub_requested)
	_app_view.start_boss_requested.connect(_on_start_boss_requested)
	_app_view.end_turn_requested.connect(_on_end_turn_requested)
	_app_view.play_card_requested.connect(_on_play_card_requested)
	_app_view.customer_item_requested.connect(_on_customer_item_requested)
	_app_view.prep_item_requested.connect(_on_prep_item_requested)
	_app_view.oven_item_requested.connect(_on_oven_item_requested)
	_app_view.table_item_requested.connect(_on_table_item_requested)

func _on_continue_from_title_requested() -> void:
	_session_service.continue_from_title()
	_refresh_view()

func _on_reset_profile_requested() -> void:
	_clear_pending_selection()
	_session_service.reset_profile()
	_refresh_view()

func _on_open_dough_select_requested() -> void:
	_session_service.open_dough_select()
	_refresh_view()

func _on_open_decoration_requested() -> void:
	_session_service.open_decoration_screen()
	_refresh_view()

func _on_close_decoration_requested() -> void:
	_session_service.close_decoration_screen()
	_refresh_view()

func _on_start_run_requested(dough_id: StringName) -> void:
	_clear_pending_selection()
	_session_service.start_new_run_with_dough(dough_id)
	_refresh_view()

func _on_buy_upgrade_requested(upgrade_id: StringName) -> void:
	_session_service.purchase_shop_upgrade(upgrade_id)
	_refresh_view()

func _on_buy_decoration_requested(decoration_id: StringName) -> void:
	_session_service.purchase_decoration(decoration_id)
	_refresh_view()

func _on_place_decoration_requested(slot_name: String, decoration_id: StringName) -> void:
	_session_service.place_decoration(slot_name, decoration_id)
	_refresh_view()

func _on_toggle_equipment_requested(equipment_id: StringName, equipped: bool) -> void:
	_session_service.toggle_equipment(equipment_id, equipped)
	_refresh_view()

func _on_choose_reward_requested(reward_id: StringName) -> void:
	_session_service.choose_reward(reward_id)
	_refresh_view()

func _on_buy_offer_requested(offer_id: StringName) -> void:
	_session_service.buy_offer(offer_id)
	_refresh_view()

func _on_continue_after_shop_requested() -> void:
	_session_service.continue_after_shop()
	_refresh_view()

func _on_return_to_hub_requested() -> void:
	_clear_pending_selection()
	_session_service.return_to_hub()
	_refresh_view()

func _on_start_boss_requested() -> void:
	_session_service.start_boss_encounter()
	_refresh_view()

func _on_end_turn_requested() -> void:
	_clear_pending_selection()
	_session_service.end_player_turn()
	_refresh_view()

func _on_play_card_requested(card_index: int) -> void:
	if _session_service.run_state.screen != GameEnums.Screen.ENCOUNTER:
		return
	if card_index < 0 or card_index >= _session_service.deck_state.hand.size():
		return
	if _pending_card_index == card_index:
		_clear_pending_selection()
		_refresh_view()
		return
	var card: CardInstance = _session_service.deck_state.hand[card_index]
	if not _session_service.can_play_card(card):
		_refresh_view()
		return
	var target_count: int = _session_service.get_required_target_count(card)
	if target_count == 0:
		var no_targets: Array[Dictionary] = []
		_resolve_card_play(card_index, no_targets)
		return
	var valid_targets: Array[Dictionary] = _session_service.get_valid_targets(card)
	if _can_auto_resolve_targets(card, target_count, valid_targets):
		_resolve_card_play(card_index, valid_targets)
		return
	_pending_card_index = card_index
	_pending_targets.clear()
	_refresh_view()

func _on_prep_item_requested(item_index: int) -> void:
	_handle_target_click(&"prep", item_index)

func _on_customer_item_requested(customer_index: int) -> void:
	_handle_target_click(&"customer", customer_index)

func _on_oven_item_requested(slot_index: int) -> void:
	if _pending_card_index == -1:
		if _session_service.collect_oven_item(slot_index):
			_refresh_view()
		return
	_handle_target_click(&"oven", slot_index)

func _on_table_item_requested(item_index: int) -> void:
	_handle_target_click(&"table", item_index)

func _handle_target_click(zone: StringName, index: int) -> void:
	if _pending_card_index == -1:
		return
	if _pending_card_index < 0 or _pending_card_index >= _session_service.deck_state.hand.size():
		_clear_pending_selection()
		return
	var card: CardInstance = _session_service.deck_state.hand[_pending_card_index]
	if not _session_service.is_valid_target(card, zone, index):
		return
	if card.card_def != null and card.card_def.targeting_rules == "select_one_customer_and_one_table_item":
		for pending_index in range(_pending_targets.size()):
			var pending_zone: StringName = StringName(_pending_targets[pending_index].get("zone", ""))
			if pending_zone == zone:
				var replacement_target: Dictionary = {
					"zone": zone,
					"index": index,
				}
				_pending_targets[pending_index] = replacement_target
				_refresh_view()
				return
	_pending_targets.append({
		"zone": zone,
		"index": index,
	})
	if _pending_targets.size() >= _session_service.get_required_target_count(card):
		var resolved_targets: Array[Dictionary] = []
		for pending_target in _pending_targets:
			var copied_target: Dictionary = pending_target.duplicate(true)
			resolved_targets.append(copied_target)
		_resolve_card_play(_pending_card_index, resolved_targets)
	else:
		_refresh_view()

func _resolve_card_play(card_index: int, targets: Array[Dictionary]) -> void:
	_clear_pending_selection()
	_session_service.play_card_from_hand(card_index, targets, _effect_queue)
	_refresh_view()

func _build_interaction_state() -> Dictionary:
	var pending_rule: String = ""
	var pending_prompt: String = ""
	if _pending_card_index != -1 and _pending_card_index < _session_service.deck_state.hand.size():
		var pending_card: CardInstance = _session_service.deck_state.hand[_pending_card_index]
		pending_rule = pending_card.card_def.targeting_rules
		pending_prompt = _session_service.get_target_prompt(pending_card)
	return {
		"pending_card_index": _pending_card_index,
		"pending_rule": pending_rule,
		"pending_prompt": pending_prompt,
		"selected_indices": _selected_target_indices(),
		"selected_targets": _selected_targets_copy(),
	}

func _selected_target_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()
	for target in _pending_targets:
		indices.append(int(target.get("index", -1)))
	return indices

func _selected_targets_copy() -> Array[Dictionary]:
	var copied_targets: Array[Dictionary] = []
	for target in _pending_targets:
		var copied_target: Dictionary = target.duplicate(true)
		copied_targets.append(copied_target)
	return copied_targets

func _clear_pending_selection() -> void:
	_pending_card_index = -1
	_pending_targets.clear()

func _can_auto_resolve_targets(card: CardInstance, target_count: int, valid_targets: Array[Dictionary]) -> bool:
	if card == null or card.card_def == null:
		return false
	if target_count == 1:
		return valid_targets.size() == 1
	if card.card_def.targeting_rules == "select_one_customer_and_one_table_item":
		var has_customer_target: bool = false
		var has_table_target: bool = false
		for target in valid_targets:
			var zone: StringName = StringName(target.get("zone", ""))
			if zone == &"customer":
				if has_customer_target:
					return false
				has_customer_target = true
			elif zone == &"table":
				if has_table_target:
					return false
				has_table_target = true
		return has_customer_target and has_table_target
	return false

func _on_resolution_started() -> void:
	_session_service.combat_state.turn_state = GameEnums.TurnState.RESOLVING_EFFECTS
	_refresh_view()

func _on_resolution_finished() -> void:
	if _session_service.run_state.screen == GameEnums.Screen.ENCOUNTER:
		_session_service.combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN
	_refresh_view()

func _refresh_view() -> void:
	_app_view.render(_session_service, _build_interaction_state())
