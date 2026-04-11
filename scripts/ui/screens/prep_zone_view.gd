class_name PrepZoneView
extends Control

signal prep_item_requested(item_index: int)

@export var item_card_scene: PackedScene

@onready var _grid: GridContainer = $PrepGrid
@onready var _empty_label: Label = $PrepEmptyLabel

func _ready() -> void:
	_apply_layout()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_apply_layout")

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
	var resolved_size: Vector2 = Vector2(maxf(140.0, size.x), maxf(160.0, size.y))
	var compactness: float = clampf(maxf((230.0 - resolved_size.x) / 90.0, (220.0 - resolved_size.y) / 80.0), 0.0, 1.0)
	var grid_width: float = clampf(resolved_size.x * lerpf(0.50, 0.68, compactness), 148.0, minf(resolved_size.x - 8.0, 220.0))
	var grid_height: float = clampf(resolved_size.y * lerpf(0.82, 0.9, compactness), 176.0, resolved_size.y - 6.0)
	var card_width: float = clampf(resolved_size.x * lerpf(0.44, 0.34, compactness), 126.0, 228.0)
	var card_height: float = clampf(resolved_size.y * lerpf(0.76, 0.58, compactness), 148.0, 286.0)
	for child in _grid.get_children():
		var card: ZoneItemCardView = child as ZoneItemCardView
		if card != null:
			card.custom_minimum_size = Vector2(card_width, card_height)
	_apply_node_rect(
		_grid,
		Rect2(
			Vector2((resolved_size.x - grid_width) * 0.5, maxf(0.0, (resolved_size.y - grid_height) * 0.38)),
			Vector2(grid_width, grid_height)
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
