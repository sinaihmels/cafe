@tool
class_name TableZoneView
extends Control

signal table_item_requested(item_index: int)

@export var item_card_scene: PackedScene
@export_group("Layout")
@export var layout_min_size: Vector2 = Vector2(180.0, 160.0)
@export_range(0.0, 0.5, 0.01) var side_padding_ratio: float = 0.07
@export var side_padding_min: float = 8.0
@export var side_padding_max: float = 22.0
@export_range(0.0, 0.5, 0.01) var top_padding_ratio: float = 0.08
@export var top_padding_min: float = 10.0
@export var top_padding_max: float = 20.0
@export_range(0.0, 0.5, 0.01) var bottom_padding_ratio: float = 0.06
@export var bottom_padding_min: float = 8.0
@export var bottom_padding_max: float = 18.0
@export var row_content_width_min: float = 132.0
@export var row_content_height_min: float = 120.0
@export var row_separation: int = 12
@export var card_width_min: float = 112.0
@export var card_width_max: float = 164.0
@export_range(0.0, 1.0, 0.01) var card_height_ratio: float = 0.56
@export var card_height_min: float = 138.0
@export var card_height_max: float = 210.0
@export_group("Empty State")
@export var empty_label_size: Vector2 = Vector2(180.0, 26.0)

@onready var _row: HBoxContainer = $TableRow
@onready var _empty_label: Label = $TableEmptyLabel
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
	_empty_label.visible = session_service.cafe_state.plated_pastries.is_empty()
	for table_index in range(session_service.cafe_state.plated_pastries.size()):
		var pastry: PastryInstance = session_service.cafe_state.plated_pastries[table_index]
		var interactable: bool = interaction_state.is_zone_targetable(&"table", table_index) or interaction_state.is_target_selected(&"table", table_index)
		var card: ZoneItemCardView = _instantiate_item_card()
		card.configure(
			UiTextureLibrary.pastry_texture(pastry),
			pastry.get_display_name(),
			UiTextFormatter.describe_pastry(pastry),
			interactable,
			interaction_state.is_target_selected(&"table", table_index),
			interaction_state.is_zone_targetable(&"table", table_index)
		)
		var item_index: int = table_index
		card.action_requested.connect(func() -> void:
			table_item_requested.emit(item_index)
		)
		_row.add_child(card)
	_apply_layout()

func _instantiate_item_card() -> ZoneItemCardView:
	var node: Node = UiSceneUtils.instantiate_required(item_card_scene, "TableZoneView.item_card_scene")
	var card: ZoneItemCardView = node as ZoneItemCardView
	assert(card != null, "TableZoneView.item_card_scene must instantiate ZoneItemCardView.")
	return card

func get_pastry_card_control(item_index: int) -> Control:
	if item_index < 0 or item_index >= _row.get_child_count():
		return null
	return _row.get_child(item_index) as Control

func _apply_layout() -> void:
	if _row == null or _empty_label == null:
		return
	var resolved_size: Vector2 = Vector2(maxf(layout_min_size.x, size.x), maxf(layout_min_size.y, size.y))
	var side_padding: float = clampf(resolved_size.x * side_padding_ratio, side_padding_min, side_padding_max)
	var top_padding: float = clampf(resolved_size.y * top_padding_ratio, top_padding_min, top_padding_max)
	var bottom_padding: float = clampf(resolved_size.y * bottom_padding_ratio, bottom_padding_min, bottom_padding_max)
	var card_count: int = maxi(1, _row.get_child_count())
	var content_width: float = maxf(row_content_width_min, resolved_size.x - side_padding * 2.0)
	_row.add_theme_constant_override("separation", row_separation)
	var card_width: float = clampf(
		(content_width - float(row_separation * maxi(0, card_count - 1))) / float(card_count),
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
				maxf(row_content_width_min, resolved_size.x - side_padding * 2.0),
				maxf(row_content_height_min, resolved_size.y - top_padding - bottom_padding)
			)
		)
	)
	_apply_node_rect(
		_empty_label,
		Rect2(
			Vector2(
				maxf(0.0, (resolved_size.x - empty_label_size.x) * 0.5),
				maxf(0.0, (resolved_size.y - empty_label_size.y) * 0.5)
			),
			Vector2(minf(empty_label_size.x, resolved_size.x), empty_label_size.y)
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
		row_content_width_min,
		row_content_height_min,
		row_separation,
		card_width_min,
		card_width_max,
		card_height_ratio,
		card_height_min,
		card_height_max,
		empty_label_size,
	]

func _refresh_editor_preview() -> void:
	render_editor_preview()
