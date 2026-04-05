class_name HandFanView
extends Control

signal play_card_requested(card_index: int)

@export var hand_card_scene: PackedScene
@export var card_width: float = 154.0
@export var card_height: float = 214.0
@export var min_spacing: float = 34.0
@export var ideal_spacing: float = 94.0

@onready var _cards_layer: Control = $CardsLayer

var _card_nodes: Array[HandCardView] = []
var _hovered_card_index: int = -1
var _selected_card_index: int = -1

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_cards_layer)
	_card_nodes.clear()
	_selected_card_index = interaction_state.pending_card_index
	if _hovered_card_index >= session_service.deck_state.hand.size():
		_hovered_card_index = -1
	for card_index in range(session_service.deck_state.hand.size()):
		var card: CardInstance = session_service.deck_state.hand[card_index]
		var hand_card: HandCardView = _instantiate_hand_card()
		hand_card.configure(
			card,
			session_service.can_play_card(card),
			card_index == _selected_card_index
		)
		var hand_index: int = card_index
		hand_card.action_requested.connect(func() -> void:
			play_card_requested.emit(hand_index)
		)
		hand_card.hover_started.connect(func() -> void:
			_set_hovered_card(hand_index)
		)
		hand_card.hover_ended.connect(func() -> void:
			_clear_hovered_card(hand_index)
		)
		_cards_layer.add_child(hand_card)
		_card_nodes.append(hand_card)
	_layout_cards()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_cards")

func _set_hovered_card(card_index: int) -> void:
	if _hovered_card_index == card_index:
		return
	if _hovered_card_index >= 0 and _hovered_card_index < _card_nodes.size():
		_card_nodes[_hovered_card_index].set_hovered(false)
	_hovered_card_index = card_index
	if _hovered_card_index >= 0 and _hovered_card_index < _card_nodes.size():
		_card_nodes[_hovered_card_index].set_hovered(true)
	_layout_cards()

func _clear_hovered_card(card_index: int) -> void:
	if _hovered_card_index != card_index:
		return
	if _hovered_card_index >= 0 and _hovered_card_index < _card_nodes.size():
		_card_nodes[_hovered_card_index].set_hovered(false)
	_hovered_card_index = -1
	_layout_cards()

func _layout_cards() -> void:
	if _cards_layer == null or _card_nodes.is_empty():
		return
	var hand_count: int = _card_nodes.size()
	var available_width: float = maxf(180.0, size.x - 24.0)
	# The cards themselves are authored scenes; this method only handles the fan positioning math.
	var base_width: float = card_width
	var base_height: float = card_height
	var desired_spacing: float = ideal_spacing if hand_count <= 5 else 64.0
	var spacing: float = desired_spacing
	if hand_count > 1 and (base_width + (hand_count - 1) * spacing) > available_width:
		spacing = maxf(min_spacing, (available_width - base_width) / float(hand_count - 1))
	if hand_count > 1 and (base_width + (hand_count - 1) * spacing) > available_width:
		var shrunk_width: float = maxf(124.0, available_width - (hand_count - 1) * spacing)
		var width_scale: float = shrunk_width / base_width
		base_width = shrunk_width
		base_height *= width_scale
	var total_span: float = spacing * float(maxi(0, hand_count - 1))
	var start_x: float = (size.x - (base_width + total_span)) * 0.5
	for card_index in range(_card_nodes.size()):
		var card_button: HandCardView = _card_nodes[card_index]
		var normalized: float = 0.0
		if hand_count > 1:
			normalized = (float(card_index) / float(hand_count - 1)) * 2.0 - 1.0
		var curve_drop: float = pow(absf(normalized), 1.4) * 34.0
		var is_selected: bool = card_index == _selected_card_index
		var is_hovered: bool = card_index == _hovered_card_index
		var lift: float = 0.0
		if is_selected:
			lift = 40.0
		elif is_hovered:
			lift = 28.0
		var rotation_multiplier: float = 1.0
		if is_selected:
			rotation_multiplier = 0.0
		elif is_hovered:
			rotation_multiplier = 0.35
		card_button.size = Vector2(base_width, base_height)
		card_button.position = Vector2(start_x + spacing * float(card_index), maxf(6.0, size.y - base_height - 12.0 + curve_drop - lift))
		card_button.pivot_offset = card_button.size * 0.5
		card_button.rotation_degrees = normalized * 13.0 * rotation_multiplier
		card_button.z_index = 100 + card_index
		if is_hovered:
			card_button.z_index = 250
		elif is_selected:
			card_button.z_index = 225

func _instantiate_hand_card() -> HandCardView:
	var node: Node = UiSceneUtils.instantiate_required(hand_card_scene, "HandFanView.hand_card_scene")
	var hand_card: HandCardView = node as HandCardView
	assert(hand_card != null, "HandFanView.hand_card_scene must instantiate HandCardView.")
	return hand_card
