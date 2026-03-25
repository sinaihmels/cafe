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

func _ready() -> void:
	_effect_queue.configure(_event_bus)
	_effect_queue.resolution_started.connect(_on_resolution_started)
	_effect_queue.resolution_finished.connect(_on_resolution_finished)
	_gameplay_view.end_turn_requested.connect(_on_end_turn_requested)
	_gameplay_view.play_card_requested.connect(_on_play_card_requested)
	_session_service.start_new_run()
	_session_service.draw_starting_hand()
	_start_player_turn()
	_refresh_view()

func _start_player_turn() -> void:
	_session_service.run_state.run_phase = GameEnums.RunPhase.GAMEPLAY
	_session_service.combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN
	_session_service.player_state.reset_turn_energy()
	_event_bus.emit_turn_started(_session_service.combat_state.turn_number)

func _on_end_turn_requested() -> void:
	if _session_service.combat_state.turn_state != GameEnums.TurnState.PLAYER_TURN:
		return
	_session_service.combat_state.turn_state = GameEnums.TurnState.CUSTOMER_TURN
	_event_bus.emit_turn_ended(_session_service.combat_state.turn_number)
	_run_customer_turn()

func _run_customer_turn() -> void:
	_session_service.combat_state.turn_state = GameEnums.TurnState.CHECK_END
	_session_service.combat_state.turn_number += 1
	if _session_service.is_run_over():
		_session_service.run_state.run_phase = GameEnums.RunPhase.RUN_END
	else:
		_start_player_turn()
	_refresh_view()

func _on_play_card_requested(card_index: int) -> void:
	if _session_service.combat_state.turn_state != GameEnums.TurnState.PLAYER_TURN:
		return
	if card_index < 0 or card_index >= _session_service.deck_state.hand.size():
		return
	var card := _session_service.deck_state.hand[card_index]
	if not _session_service.can_play_card(card):
		_refresh_view("Not enough energy to play %s." % [card.get_display_name()])
		return
	_session_service.spend_energy(card.get_cost())
	_event_bus.emit_energy_changed(_session_service.player_state.energy, -card.get_cost())
	var context := _session_service.build_effect_context(card)
	context.event_bus = _event_bus
	_effect_queue.enqueue_all(card.card_def.effects, context)
	_effect_queue.resolve_all()
	_event_bus.emit_card_played(card)
	_session_service.deck_state.discard_from_hand(card)
	_refresh_view("Played %s." % [card.get_display_name()])
	if _session_service.player_state.energy <= 0:
		_on_end_turn_requested()

func _on_resolution_started() -> void:
	_session_service.combat_state.turn_state = GameEnums.TurnState.RESOLVING_EFFECTS
	_refresh_view("Resolving effects...")

func _on_resolution_finished() -> void:
	_session_service.combat_state.turn_state = GameEnums.TurnState.PLAYER_TURN
	_refresh_view()

func _refresh_view(status_message: String = "") -> void:
	_gameplay_view.render(_session_service, status_message)
