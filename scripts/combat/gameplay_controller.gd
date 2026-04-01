class_name GameplayController
extends Node

@export_node_path("SessionService") var session_service_path: NodePath
@export_node_path("EventBus") var event_bus_path: NodePath
@export_node_path("EffectQueueService") var effect_queue_path: NodePath
@export_node_path("GameplayView") var gameplay_view_path: NodePath

@onready var _session_service: SessionService = get_node(session_service_path)
@onready var _event_bus: EventBus = get_node(event_bus_path)
@onready var _effect_queue: EffectQueueService = get_node(effect_queue_path)
@onready var _gameplay_view: GameplayView = get_node(gameplay_view_path)

var _pending_card_index: int = -1
var _pending_targets: Array[Dictionary] = []

func _ready() -> void:
	_effect_queue.configure(_event_bus)
	_effect_queue.resolution_started.connect(_on_resolution_started)
	_effect_queue.resolution_finished.connect(_on_resolution_finished)
	_gameplay_view.end_turn_requested.connect(_on_end_turn_requested)
	_gameplay_view.play_card_requested.connect(_on_play_card_requested)
	_gameplay_view.prep_item_requested.connect(_on_prep_item_requested)
	_gameplay_view.oven_item_requested.connect(_on_oven_item_requested)
	_gameplay_view.table_item_requested.connect(_on_table_item_requested)
	_gameplay_view.serve_requested.connect(_on_serve_requested)
	_gameplay_view.reward_requested.connect(_on_reward_requested)
	_gameplay_view.event_option_requested.connect(_on_event_option_requested)
	call_deferred("_boot_game")

func _boot_game() -> void:
	_session_service.start_new_run()
	_start_player_turn()
	_refresh_view(_session_service.pop_status_message())

func _start_player_turn() -> void:
	_session_service.consume_day_started()
	if _session_service.run_state.run_phase != GameEnums.RunPhase.GAMEPLAY:
		_refresh_view(_session_service.pop_status_message())
		return
	_session_service.combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN
	_session_service.begin_player_turn()
	_event_bus.emit_turn_started(_session_service.combat_state.turn_number)
	_refresh_view(_session_service.pop_status_message())

func _on_end_turn_requested() -> void:
	if _session_service.run_state.run_phase != GameEnums.RunPhase.GAMEPLAY:
		return
	if _session_service.combat_state.turn_state != GameEnums.TurnState.PLAYER_TURN:
		return
	_clear_pending_selection()
	_session_service.end_player_turn_cleanup()
	_session_service.combat_state.turn_state = GameEnums.TurnState.CUSTOMER_TURN
	_event_bus.emit_turn_ended(_session_service.combat_state.turn_number)
	_session_service.process_customer_turn()
	if _session_service.is_run_over():
		_refresh_view(_session_service.pop_status_message())
		return
	if _session_service.run_state.run_phase == GameEnums.RunPhase.GAMEPLAY:
		if not _session_service.consume_day_started():
			_session_service.combat_state.turn_number += 1
		_start_player_turn()
	else:
		_session_service.combat_state.turn_state = GameEnums.TurnState.CHECK_END
		_refresh_view(_session_service.pop_status_message())

func _on_play_card_requested(card_index: int) -> void:
	if _session_service.run_state.run_phase != GameEnums.RunPhase.GAMEPLAY:
		return
	if _session_service.combat_state.turn_state != GameEnums.TurnState.PLAYER_TURN:
		return
	if card_index < 0 or card_index >= _session_service.deck_state.hand.size():
		return
	var card: CardInstance = _session_service.deck_state.hand[card_index]
	if not _session_service.can_play_card(card):
		_refresh_view("Not enough energy to play %s." % [card.get_display_name()])
		return
	var target_count: int = _session_service.get_required_target_count(card)
	if target_count == 0:
		_resolve_card_play(card_index, [])
		return
	_pending_card_index = card_index
	_pending_targets.clear()
	_refresh_view(_session_service.get_target_prompt(card))

func _on_prep_item_requested(item_index: int) -> void:
	_handle_target_click(&"prep", item_index)

func _on_oven_item_requested(slot_index: int) -> void:
	if _pending_card_index == -1:
		if _session_service.collect_oven_item(slot_index):
			_refresh_view(_session_service.pop_status_message())
		return
	_handle_target_click(&"oven", slot_index)

func _on_table_item_requested(item_index: int) -> void:
	_handle_target_click(&"table", item_index)

func _handle_target_click(zone: StringName, index: int) -> void:
	if _pending_card_index == -1:
		return
	var card: CardInstance = _session_service.deck_state.hand[_pending_card_index]
	if not _session_service.is_valid_target(card, zone, index):
		return
	_pending_targets.append({
		"zone": zone,
		"index": index,
	})
	if _pending_targets.size() >= _session_service.get_required_target_count(card):
		_resolve_card_play(_pending_card_index, _pending_targets.duplicate(true))
	else:
		_refresh_view("Selected 1 target. Pick one more.")

func _resolve_card_play(card_index: int, targets: Array) -> void:
	if card_index < 0 or card_index >= _session_service.deck_state.hand.size():
		return
	var card: CardInstance = _session_service.deck_state.hand[card_index]
	if not _session_service.can_play_card(card):
		_refresh_view("Not enough energy to play %s." % [card.get_display_name()])
		return
	_session_service.spend_energy(card.get_cost())
	_event_bus.emit_energy_changed(_session_service.player_state.energy, -card.get_cost())
	var context: EffectContext = _session_service.build_effect_context(card)
	context.event_bus = _event_bus
	context.targets = targets
	_effect_queue.enqueue_all(card.card_def.effects, context)
	_effect_queue.resolve_all()
	_event_bus.emit_card_played(card)
	_session_service.deck_state.discard_from_hand(card)
	_clear_pending_selection()
	var message: String = _session_service.pop_status_message()
	if message == "":
		message = "Played %s." % [card.get_display_name()]
	_refresh_view(message)
	if _session_service.player_state.energy <= 0 and _session_service.run_state.run_phase == GameEnums.RunPhase.GAMEPLAY:
		_on_end_turn_requested()

func _on_serve_requested(customer_index: int, item_index: int) -> void:
	if _session_service.run_state.run_phase != GameEnums.RunPhase.GAMEPLAY:
		return
	if _pending_card_index != -1:
		return
	_session_service.serve_item_to_customer(customer_index, item_index)
	if _session_service.run_state.run_phase == GameEnums.RunPhase.GAMEPLAY and _session_service.consume_day_started():
		_start_player_turn()
		return
	_refresh_view(_session_service.pop_status_message())

func _on_reward_requested(reward_id: StringName) -> void:
	if _session_service.run_state.run_phase != GameEnums.RunPhase.REWARD:
		return
	_session_service.choose_reward(reward_id)
	_start_player_turn()

func _on_event_option_requested(option_id: StringName) -> void:
	if _session_service.run_state.run_phase != GameEnums.RunPhase.EVENT:
		return
	_session_service.choose_event_option(option_id)
	_start_player_turn()

func _on_resolution_started() -> void:
	_session_service.combat_state.turn_state = GameEnums.TurnState.RESOLVING_EFFECTS
	_refresh_view("Resolving effects...")

func _on_resolution_finished() -> void:
	if _session_service.run_state.run_phase == GameEnums.RunPhase.GAMEPLAY:
		_session_service.combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN

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
	}

func _selected_target_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()
	for target in _pending_targets:
		indices.append(int(target.get("index", -1)))
	return indices

func _clear_pending_selection() -> void:
	_pending_card_index = -1
	_pending_targets.clear()

func _refresh_view(status_message: String = "") -> void:
	_gameplay_view.render(_session_service, status_message, _build_interaction_state())
