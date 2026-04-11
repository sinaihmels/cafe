class_name OvenZoneView
extends Control

signal oven_item_requested(slot_index: int)

@export var item_card_scene: PackedScene

@onready var _row: HBoxContainer = $OvenRow

func _ready() -> void:
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_apply_layout()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_apply_layout")

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_row)
	var card: ZoneItemCardView = _instantiate_item_card()
	var pastry: PastryInstance = session_service.cafe_state.oven_pastry
	if pastry == null:
		card.configure(UiTextureLibrary.pastry_texture(null), "Oven", "", false, false, false)
		_row.add_child(card)
		_apply_layout()
		return
	var ready: bool = session_service.cafe_state.oven_mode == &"ready"
	var interactable: bool = interaction_state.is_zone_targetable(&"oven", 0) or ready or interaction_state.is_target_selected(&"oven", 0)
	card.configure(
		UiTextureLibrary.pastry_texture(pastry),
		pastry.get_display_name(),
		_status_text(session_service),
		interactable,
		interaction_state.is_target_selected(&"oven", 0),
		interaction_state.is_zone_targetable(&"oven", 0) or ready
	)
	card.action_requested.connect(func() -> void:
		oven_item_requested.emit(0)
	)
	_row.add_child(card)
	_apply_layout()

func _status_text(session_service: SessionService) -> String:
	if session_service.cafe_state.oven_pastry == null:
		return "Empty"
	match session_service.cafe_state.oven_mode:
		&"proofing":
			return "Proofing (%d turn left)" % max(1, session_service.cafe_state.oven_turns_remaining)
		&"baking":
			return "Baking (%d turn left)" % max(1, session_service.cafe_state.oven_turns_remaining)
		&"ready":
			return "Ready to plate"
		_:
			if session_service.cafe_state.oven_pastry.has_pastry_state(&"proofed"):
				return "Proofed and waiting"
			return UiTextFormatter.describe_pastry(session_service.cafe_state.oven_pastry)

func _instantiate_item_card() -> ZoneItemCardView:
	var node: Node = UiSceneUtils.instantiate_required(item_card_scene, "OvenZoneView.item_card_scene")
	var card: ZoneItemCardView = node as ZoneItemCardView
	assert(card != null, "OvenZoneView.item_card_scene must instantiate ZoneItemCardView.")
	return card

func get_pastry_card_control(item_index: int) -> Control:
	if item_index < 0 or item_index >= _row.get_child_count():
		return null
	return _row.get_child(item_index) as Control

func _apply_layout() -> void:
	if _row == null:
		return
	var resolved_size: Vector2 = Vector2(maxf(180.0, size.x), maxf(180.0, size.y))
	var compactness: float = clampf(maxf((300.0 - resolved_size.x) / 120.0, (240.0 - resolved_size.y) / 90.0), 0.0, 1.0)
	var side_padding: float = clampf(resolved_size.x * lerpf(0.12, 0.08, compactness), 10.0, 34.0)
	var top_padding: float = clampf(resolved_size.y * lerpf(0.10, 0.08, compactness), 10.0, 28.0)
	var bottom_padding: float = clampf(resolved_size.y * 0.08, 8.0, 22.0)
	var card_width: float = clampf(minf(resolved_size.x * lerpf(0.36, 0.28, compactness), resolved_size.y * lerpf(0.52, 0.38, compactness)), 132.0, 236.0)
	var card_height: float = clampf(resolved_size.y * lerpf(0.74, 0.58, compactness), 156.0, 292.0)
	for child in _row.get_children():
		var card: ZoneItemCardView = child as ZoneItemCardView
		if card != null:
			card.custom_minimum_size = Vector2(card_width, card_height)
	_apply_node_rect(
		_row,
		Rect2(
			Vector2(side_padding, top_padding),
			Vector2(
				maxf(120.0, resolved_size.x - side_padding * 2.0),
				maxf(140.0, resolved_size.y - top_padding - bottom_padding)
			)
		)
	)

func _apply_node_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
