class_name GameplayView
extends Control

signal end_turn_requested()
signal play_card_requested(card_index: int)

@onready var _day_label: Label = %DayLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _turn_label: Label = %TurnLabel
@onready var _energy_label: Label = %EnergyLabel
@onready var _reputation_label: Label = %ReputationLabel
@onready var _chaos_label: Label = %ChaosLabel
@onready var _zones_label: RichTextLabel = %ZonesLabel
@onready var _status_label: Label = %StatusLabel
@onready var _hand_container: VBoxContainer = %HandContainer
@onready var _end_turn_button: Button = %EndTurnButton

func _ready() -> void:
	_end_turn_button.pressed.connect(_on_end_turn_pressed)

func render(session_service: SessionService, status_message: String = "") -> void:
	_day_label.text = "Day %d" % session_service.run_state.day_number
	_phase_label.text = "Phase: %s" % _run_phase_name(session_service.run_state.run_phase)
	_turn_label.text = "Turn: %d (%s)" % [
		session_service.combat_state.turn_number,
		_turn_state_name(session_service.combat_state.turn_state),
	]
	_energy_label.text = "Energy: %d / %d" % [
		session_service.player_state.energy,
		session_service.player_state.max_energy,
	]
	_reputation_label.text = "Reputation: %d / %d" % [
		session_service.player_state.reputation,
		session_service.player_state.max_reputation,
	]
	_chaos_label.text = "Chaos: %d" % session_service.player_state.chaos
	_zones_label.text = _build_zone_text(session_service.cafe_state)
	_status_label.text = status_message if status_message != "" else "Architecture scaffold ready. Start replacing sample content with real systems."
	_render_hand(session_service.deck_state.hand, session_service.player_state.energy)

func _build_zone_text(cafe_state: CafeState) -> String:
	return "[b]Zones[/b]\nServing Table %d/%d\nPrep Space %d/%d\nOven %d/%d" % [
		cafe_state.serving_table.size(),
		cafe_state.serving_table_capacity,
		cafe_state.prep_space.size(),
		cafe_state.prep_space_capacity,
		cafe_state.oven.size(),
		cafe_state.oven_capacity,
	]

func _render_hand(hand: Array[CardInstance], current_energy: int) -> void:
	for child in _hand_container.get_children():
		child.queue_free()
	for index in hand.size():
		var card := hand[index]
		var button := Button.new()
		button.text = "%s (Cost %d)\n%s" % [
			card.get_display_name(),
			card.get_cost(),
			card.get_preview_text(),
		]
		button.disabled = card.get_cost() > current_energy
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 72)
		button.pressed.connect(_on_card_button_pressed.bind(index))
		_hand_container.add_child(button)

func _on_end_turn_pressed() -> void:
	end_turn_requested.emit()

func _on_card_button_pressed(card_index: int) -> void:
	play_card_requested.emit(card_index)

func _run_phase_name(value: int) -> String:
	match value:
		GameEnums.RunPhase.PREP_PHASE:
			return "Prep Phase"
		GameEnums.RunPhase.GAMEPLAY:
			return "Gameplay"
		GameEnums.RunPhase.REWARD:
			return "Reward"
		GameEnums.RunPhase.EVENT:
			return "Event"
		GameEnums.RunPhase.DAY_END:
			return "Day End"
		GameEnums.RunPhase.RUN_END:
			return "Run End"
		_:
			return "Unknown"

func _turn_state_name(value: int) -> String:
	match value:
		GameEnums.TurnState.IDLE:
			return "Idle"
		GameEnums.TurnState.PLAYER_TURN:
			return "Player Turn"
		GameEnums.TurnState.RESOLVING_EFFECTS:
			return "Resolving Effects"
		GameEnums.TurnState.CUSTOMER_TURN:
			return "Customer Turn"
		GameEnums.TurnState.CHECK_END:
			return "Check End"
		_:
			return "Unknown"
