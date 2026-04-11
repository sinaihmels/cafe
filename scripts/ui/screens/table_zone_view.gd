@tool
class_name TableZoneView
extends Control

signal table_item_requested(item_index: int)

@export var item_card_scene: PackedScene

@onready var _row: HBoxContainer = $TableRow
@onready var _empty_label: Label = $TableEmptyLabel

func _ready() -> void:
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	if Engine.is_editor_hint():
		render_editor_preview()
	_apply_layout()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_apply_layout")

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
	var resolved_size: Vector2 = Vector2(maxf(180.0, size.x), maxf(160.0, size.y))
	var compactness: float = clampf(maxf((320.0 - resolved_size.x) / 130.0, (220.0 - resolved_size.y) / 80.0), 0.0, 1.0)
	var side_padding: float = clampf(resolved_size.x * lerpf(0.08, 0.06, compactness), 8.0, 26.0)
	var top_padding: float = clampf(resolved_size.y * lerpf(0.09, 0.08, compactness), 10.0, 24.0)
	var bottom_padding: float = clampf(resolved_size.y * 0.06, 8.0, 20.0)
	var card_count: int = maxi(1, _row.get_child_count())
	var content_width: float = maxf(132.0, resolved_size.x - side_padding * 2.0)
	var separation: float = 10.0 if compactness > 0.5 else 12.0
	_row.add_theme_constant_override("separation", int(separation))
	var card_width: float = clampf((content_width - separation * float(maxi(0, card_count - 1))) / float(card_count), 120.0, 220.0)
	var card_height: float = clampf(resolved_size.y * lerpf(0.72, 0.56, compactness), 146.0, 270.0)
	for child in _row.get_children():
		var card: ZoneItemCardView = child as ZoneItemCardView
		if card != null:
			card.custom_minimum_size = Vector2(card_width, card_height)
	_apply_node_rect(
		_row,
		Rect2(
			Vector2(side_padding, top_padding),
			Vector2(
				maxf(132.0, resolved_size.x - side_padding * 2.0),
				maxf(120.0, resolved_size.y - top_padding - bottom_padding)
			)
		)
	)
	_apply_node_rect(
		_empty_label,
		Rect2(
			Vector2(maxf(0.0, (resolved_size.x - 180.0) * 0.5), maxf(0.0, (resolved_size.y - 26.0) * 0.5)),
			Vector2(minf(180.0, resolved_size.x), 26.0)
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
