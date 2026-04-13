@tool
class_name PrepZoneView
extends Control

signal prep_item_requested(item_index: int)

@export var item_card_scene: PackedScene
@export_group("Layout")
@export var layout_min_size: Vector2 = Vector2(140.0, 160.0)
@export_range(0.1, 1.0, 0.01) var grid_width_ratio: float = 0.58
@export var grid_width_min: float = 148.0
@export var grid_width_max: float = 208.0
@export_range(0.1, 1.0, 0.01) var grid_height_ratio: float = 0.86
@export var grid_height_min: float = 160.0
@export var grid_bottom_padding: float = 6.0
@export_range(0.0, 1.0, 0.01) var grid_vertical_bias: float = 0.35
@export_range(0.1, 1.0, 0.01) var card_width_ratio: float = 0.36
@export var card_width_min: float = 118.0
@export var card_width_max: float = 172.0
@export_range(0.1, 1.0, 0.01) var card_height_ratio: float = 0.66
@export var card_height_min: float = 140.0
@export var card_height_max: float = 214.0
@export_group("Empty State")
@export var empty_label_size: Vector2 = Vector2(180.0, 26.0)

@onready var _grid: GridContainer = $PrepGrid
@onready var _empty_label: Label = $PrepEmptyLabel
var _editor_refresh_signature: Array = []

func _ready() -> void:
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
	UiSceneUtils.clear_children(_grid)
	_empty_label.visible = session_service.cafe_state.active_pastry == null
	if session_service.cafe_state.active_pastry != null:
		var pastry: PastryInstance = session_service.cafe_state.active_pastry
		var interactable: bool = interaction_state.is_zone_targetable(&"prep", 0) or interaction_state.is_target_selected(&"prep", 0)
		var selected: bool = interaction_state.is_target_selected(&"prep", 0)
		var targetable: bool = interaction_state.is_zone_targetable(&"prep", 0)
		var card: ZoneItemCardView = _instantiate_item_card()
		card.configure(
			UiTextureLibrary.pastry_texture(pastry),
			pastry.get_display_name(),
			UiTextFormatter.describe_pastry(pastry),
			interactable,
			selected,
			targetable
		)
		card.action_requested.connect(func() -> void:
			prep_item_requested.emit(0)
		)
		_grid.add_child(card)
	_apply_layout()

func _instantiate_item_card() -> ZoneItemCardView:
	var node: Node = UiSceneUtils.instantiate_required(item_card_scene, "PrepZoneView.item_card_scene")
	var card: ZoneItemCardView = node as ZoneItemCardView
	assert(card != null, "PrepZoneView.item_card_scene must instantiate ZoneItemCardView.")
	return card

func get_pastry_card_control(item_index: int) -> Control:
	if item_index < 0 or item_index >= _grid.get_child_count():
		return null
	return _grid.get_child(item_index) as Control

func _apply_layout() -> void:
	if _grid == null or _empty_label == null:
		return
	var resolved_size: Vector2 = Vector2(maxf(layout_min_size.x, size.x), maxf(layout_min_size.y, size.y))
	var grid_width: float = clampf(
		resolved_size.x * grid_width_ratio,
		grid_width_min,
		minf(resolved_size.x - 8.0, grid_width_max)
	)
	var grid_height: float = clampf(
		resolved_size.y * grid_height_ratio,
		grid_height_min,
		resolved_size.y - grid_bottom_padding
	)
	var card_width: float = clampf(resolved_size.x * card_width_ratio, card_width_min, card_width_max)
	var card_height: float = clampf(resolved_size.y * card_height_ratio, card_height_min, card_height_max)
	for child in _grid.get_children():
		var card: ZoneItemCardView = child as ZoneItemCardView
		if card != null:
			card.custom_minimum_size = Vector2(card_width, card_height)
	_apply_node_rect(
		_grid,
		Rect2(
			Vector2((resolved_size.x - grid_width) * 0.5, maxf(0.0, (resolved_size.y - grid_height) * grid_vertical_bias)),
			Vector2(grid_width, grid_height)
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
		grid_width_ratio,
		grid_width_min,
		grid_width_max,
		grid_height_ratio,
		grid_height_min,
		grid_bottom_padding,
		grid_vertical_bias,
		card_width_ratio,
		card_width_min,
		card_width_max,
		card_height_ratio,
		card_height_min,
		card_height_max,
		empty_label_size,
	]

func _refresh_editor_preview() -> void:
	render_editor_preview()
