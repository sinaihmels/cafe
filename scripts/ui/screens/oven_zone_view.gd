@tool
class_name OvenZoneView
extends Control

signal oven_item_requested(slot_index: int)

@export var item_card_scene: PackedScene
@export_group("Layout")
@export var layout_min_size: Vector2 = Vector2(180.0, 180.0)
@export_range(0.0, 0.5, 0.01) var side_padding_ratio: float = 0.10
@export var side_padding_min: float = 10.0
@export var side_padding_max: float = 28.0
@export_range(0.0, 0.5, 0.01) var top_padding_ratio: float = 0.09
@export var top_padding_min: float = 10.0
@export var top_padding_max: float = 22.0
@export_range(0.0, 0.5, 0.01) var bottom_padding_ratio: float = 0.08
@export var bottom_padding_min: float = 8.0
@export var bottom_padding_max: float = 20.0
@export_range(0.0, 1.0, 0.01) var card_width_ratio_from_width: float = 0.32
@export_range(0.0, 1.0, 0.01) var card_width_ratio_from_height: float = 0.34
@export var card_width_min: float = 128.0
@export var card_width_max: float = 176.0
@export_range(0.0, 1.0, 0.01) var card_height_ratio: float = 0.60
@export var card_height_min: float = 148.0
@export var card_height_max: float = 224.0
@export var row_width_min: float = 120.0
@export var row_height_min: float = 140.0

@onready var _row: HBoxContainer = $OvenRow
var _editor_refresh_signature: Array = []

func _ready() -> void:
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	if Engine.is_editor_hint():
		_editor_refresh_signature = _make_editor_refresh_signature()
		set_process(true)
		render_editor_preview()
	_apply_layout()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_apply_layout")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var signature: Array = _make_editor_refresh_signature()
	if signature == _editor_refresh_signature:
		return
	_editor_refresh_signature = signature
	_refresh_editor_preview()

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
	var resolved_size: Vector2 = Vector2(maxf(layout_min_size.x, size.x), maxf(layout_min_size.y, size.y))
	var side_padding: float = clampf(resolved_size.x * side_padding_ratio, side_padding_min, side_padding_max)
	var top_padding: float = clampf(resolved_size.y * top_padding_ratio, top_padding_min, top_padding_max)
	var bottom_padding: float = clampf(resolved_size.y * bottom_padding_ratio, bottom_padding_min, bottom_padding_max)
	var card_width: float = clampf(
		minf(resolved_size.x * card_width_ratio_from_width, resolved_size.y * card_width_ratio_from_height),
		card_width_min,
		card_width_max
	)
	var card_height: float = clampf(resolved_size.y * card_height_ratio, card_height_min, card_height_max)
	for child in _row.get_children():
		var card: ZoneItemCardView = child as ZoneItemCardView
		if card != null:
			card.custom_minimum_size = Vector2(card_width, card_height)
	_apply_node_rect(
		_row,
		Rect2(
			Vector2(side_padding, top_padding),
			Vector2(
				maxf(row_width_min, resolved_size.x - side_padding * 2.0),
				maxf(row_height_min, resolved_size.y - top_padding - bottom_padding)
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

func render_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var preview_session: SessionService = EncounterEditorPreview.build_session()
	var preview_interaction_state: EncounterInteractionState = EncounterEditorPreview.build_interaction_state(preview_session)
	render(preview_session, preview_interaction_state)

func _make_editor_refresh_signature() -> Array:
	return [
		item_card_scene,
		layout_min_size,
		side_padding_ratio,
		side_padding_min,
		side_padding_max,
		top_padding_ratio,
		top_padding_min,
		top_padding_max,
		bottom_padding_ratio,
		bottom_padding_min,
		bottom_padding_max,
		card_width_ratio_from_width,
		card_width_ratio_from_height,
		card_width_min,
		card_width_max,
		card_height_ratio,
		card_height_min,
		card_height_max,
		row_width_min,
		row_height_min,
	]

func _refresh_editor_preview() -> void:
	render_editor_preview()
