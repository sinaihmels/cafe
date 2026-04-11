class_name AppController
extends Node

@export_node_path("SessionService") var session_service_path: NodePath
@export_node_path("SaveService") var meta_profile_service_path: NodePath
@export_node_path("EventBus") var event_bus_path: NodePath
@export_node_path("EffectQueueService") var effect_queue_path: NodePath
@export_node_path("DialogueService") var dialogue_service_path: NodePath
@export_node_path("AppView") var app_view_path: NodePath

@onready var _session_service: SessionService = get_node(session_service_path)
@onready var _meta_profile_service: SaveService = get_node(meta_profile_service_path)
@onready var _event_bus: EventBus = get_node(event_bus_path)
@onready var _effect_queue: EffectQueueService = get_node(effect_queue_path)
@onready var _dialogue_service: DialogueService = get_node(dialogue_service_path)
@onready var _app_view: AppView = get_node(app_view_path)

var _pending_card_index: int = -1
var _pending_targets: Array[EncounterTargetRef] = []
var _focused_customer_index: int = 0

func _ready() -> void:
	_effect_queue.configure(_event_bus)
	_effect_queue.resolution_started.connect(_on_resolution_started)
	_effect_queue.resolution_finished.connect(_on_resolution_finished)
	_dialogue_service.configure(_session_service, _event_bus)
	_dialogue_service.presentation_changed.connect(_refresh_view)
	_connect_view()
	_session_service.initialize(_meta_profile_service, _event_bus)
	# AppView is a sibling scene, so its @onready node bindings are only valid after its own ready signal.
	if not _app_view.is_node_ready():
		await _app_view.ready
	_app_view.configure(_event_bus)
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
	_app_view.focus_customer_requested.connect(_on_focus_customer_requested)
	_app_view.customer_item_requested.connect(_on_customer_item_requested)
	_app_view.prep_item_requested.connect(_on_prep_item_requested)
	_app_view.oven_item_requested.connect(_on_oven_item_requested)
	_app_view.table_item_requested.connect(_on_table_item_requested)
	_app_view.dialogue_continue_requested.connect(_on_dialogue_continue_requested)
	_app_view.dialogue_response_requested.connect(_on_dialogue_response_requested)

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
	_focused_customer_index = 0
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
	_focused_customer_index = 0
	_session_service.continue_after_shop()
	_refresh_view()

func _on_return_to_hub_requested() -> void:
	_clear_pending_selection()
	_focused_customer_index = 0
	_session_service.return_to_hub()
	_refresh_view()

func _on_start_boss_requested() -> void:
	_focused_customer_index = 0
	_session_service.start_boss_encounter()
	_refresh_view()

func _on_end_turn_requested() -> void:
	if _is_dialogue_blocking_input():
		return
	_clear_pending_selection()
	_session_service.end_player_turn()
	_refresh_view()

func _on_play_card_requested(card_index: int) -> void:
	if _is_dialogue_blocking_input():
		return
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
		var no_targets: Array[EncounterTargetRef] = []
		_resolve_card_play(card_index, no_targets)
		return
	var valid_targets: Array[EncounterTargetRef] = _valid_targets_for_card(card)
	if valid_targets.is_empty():
		_session_service.notify_no_valid_targets_for_card(card)
		_refresh_view()
		return
	if _can_auto_resolve_targets(card, target_count, valid_targets):
		_resolve_card_play(card_index, valid_targets)
		return
	_pending_card_index = card_index
	_pending_targets.clear()
	_refresh_view()

func _on_prep_item_requested(item_index: int) -> void:
	if _is_dialogue_blocking_input():
		return
	_handle_target_click(&"prep", item_index)

func _on_customer_item_requested(customer_index: int) -> void:
	if _is_dialogue_blocking_input():
		return
	_focused_customer_index = customer_index
	_sync_focused_customer_index()
	_handle_target_click(&"customer", customer_index)

func _on_focus_customer_requested(customer_index: int) -> void:
	if _is_dialogue_blocking_input():
		return
	if _session_service.run_state.screen != GameEnums.Screen.ENCOUNTER:
		return
	_focused_customer_index = customer_index
	_sync_focused_customer_index()
	if _pending_card_index != -1 and _pending_card_index < _session_service.deck_state.hand.size():
		var card: CardInstance = _session_service.deck_state.hand[_pending_card_index]
		if _session_service.is_valid_target(card, &"customer", customer_index):
			_handle_target_click(&"customer", customer_index)
			return
	_session_service.request_customer_order_dialogue(customer_index)
	_refresh_view()

func _on_oven_item_requested(slot_index: int) -> void:
	if _is_dialogue_blocking_input():
		return
	if _pending_card_index == -1:
		if _session_service.collect_oven_item(slot_index):
			_refresh_view()
		return
	_handle_target_click(&"oven", slot_index)

func _on_table_item_requested(item_index: int) -> void:
	if _is_dialogue_blocking_input():
		return
	_handle_target_click(&"table", item_index)

func _on_dialogue_continue_requested() -> void:
	_dialogue_service.advance_dialogue()
	_refresh_view()

func _on_dialogue_response_requested(response_index: int) -> void:
	_dialogue_service.choose_response(response_index)
	_refresh_view()

func _handle_target_click(zone: StringName, index: int) -> void:
	if _pending_card_index == -1:
		return
	if _pending_card_index < 0 or _pending_card_index >= _session_service.deck_state.hand.size():
		_clear_pending_selection()
		return
	var card: CardInstance = _session_service.deck_state.hand[_pending_card_index]
	if not _session_service.is_valid_target(card, zone, index):
		return
	if card.card_def != null and card.card_def.targeting_rules == "select_one_customer_and_one_plated_pastry":
		for pending_index in range(_pending_targets.size()):
			var pending_zone: StringName = _pending_targets[pending_index].zone
			if pending_zone == zone:
				_pending_targets[pending_index] = EncounterTargetRef.new(zone, index)
				_refresh_view()
				return
	_pending_targets.append(EncounterTargetRef.new(zone, index))
	if _pending_targets.size() >= _session_service.get_required_target_count(card):
		var resolved_targets: Array[EncounterTargetRef] = []
		for pending_target in _pending_targets:
			resolved_targets.append(pending_target.duplicate_ref())
		_resolve_card_play(_pending_card_index, resolved_targets)
	else:
		_refresh_view()

func _resolve_card_play(card_index: int, targets: Array[EncounterTargetRef]) -> void:
	_clear_pending_selection()
	# SessionService still uses raw target dictionaries, so the controller is the typed boundary.
	var raw_targets: Array[Dictionary] = []
	for target in targets:
		raw_targets.append(target.to_dictionary())
	_session_service.play_card_from_hand(card_index, raw_targets, _effect_queue)
	_refresh_view()

func _build_interaction_state() -> EncounterInteractionState:
	var state: EncounterInteractionState = EncounterInteractionState.new()
	if _pending_card_index != -1 and _pending_card_index < _session_service.deck_state.hand.size():
		var pending_card: CardInstance = _session_service.deck_state.hand[_pending_card_index]
		if pending_card != null and pending_card.card_def != null:
			state.pending_card_index = _pending_card_index
			state.pending_rule = pending_card.card_def.targeting_rules
			state.pending_prompt = _session_service.get_target_prompt(pending_card)
			state.valid_targets = _valid_targets_for_card(pending_card)
	if not _session_service.combat_state.active_customers.is_empty():
		_focused_customer_index = clampi(_focused_customer_index, 0, _session_service.combat_state.active_customers.size() - 1)
		state.focused_customer_index = _focused_customer_index
	state.selected_targets = _selected_targets_copy()
	return state

func _selected_targets_copy() -> Array[EncounterTargetRef]:
	var copied_targets: Array[EncounterTargetRef] = []
	for target in _pending_targets:
		copied_targets.append(target.duplicate_ref())
	return copied_targets

func _clear_pending_selection() -> void:
	_pending_card_index = -1
	_pending_targets.clear()

func _can_auto_resolve_targets(card: CardInstance, target_count: int, valid_targets: Array[EncounterTargetRef]) -> bool:
	if card == null or card.card_def == null:
		return false
	if target_count == 1:
		return valid_targets.size() == 1
	if card.card_def.targeting_rules == "select_one_customer_and_one_plated_pastry":
		var has_customer_target: bool = false
		var has_table_target: bool = false
		for target in valid_targets:
			var zone: StringName = target.zone
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

func _valid_targets_for_card(card: CardInstance) -> Array[EncounterTargetRef]:
	var valid_targets: Array[EncounterTargetRef] = []
	for target_value in _session_service.get_valid_targets(card):
		var valid_target: Dictionary = target_value
		valid_targets.append(EncounterTargetRef.from_dictionary(valid_target.duplicate(true)))
	return valid_targets

func _on_resolution_started() -> void:
	_session_service.combat_state.turn_state = GameEnums.TurnState.RESOLVING_EFFECTS
	_refresh_view()

func _on_resolution_finished() -> void:
	if _session_service.run_state.screen == GameEnums.Screen.ENCOUNTER:
		_session_service.combat_state.turn_state = (
			GameEnums.TurnState.DIALOGUE
			if _dialogue_service != null and _dialogue_service.has_active_dialogue()
			else GameEnums.TurnState.PLAYER_TURN
		)
	_refresh_view()

func _refresh_view() -> void:
	_sync_focused_customer_index()
	_app_view.render(_session_service, _build_interaction_state(), _dialogue_service.get_presentation_state())

func _is_dialogue_blocking_input() -> bool:
	return _dialogue_service != null and _dialogue_service.is_blocking_input()

func _sync_focused_customer_index() -> void:
	if _session_service.run_state.screen != GameEnums.Screen.ENCOUNTER or _session_service.combat_state.active_customers.is_empty():
		_focused_customer_index = 0
		_session_service.combat_state.focused_customer_index = 0
		return
	_focused_customer_index = clampi(_focused_customer_index, 0, _session_service.combat_state.active_customers.size() - 1)
	_session_service.combat_state.focused_customer_index = _focused_customer_index
