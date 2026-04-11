@tool
class_name CustomerLaneView
extends Control

signal focus_customer_requested(customer_index: int)
signal customer_target_requested(customer_index: int)

@export var customer_spot_scene: PackedScene

@onready var _empty_label: Label = $EmptyLabel
@onready var _row: HBoxContainer = $Row

var _spot_nodes: Array[CustomerStageSpotView] = []
var _focused_customer_index: int = -1

func _ready() -> void:
	if Engine.is_editor_hint():
		render_editor_preview()

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_row)
	_spot_nodes.clear()
	if session_service.combat_state.active_customers.is_empty():
		_empty_label.visible = true
		_row.visible = false
		_focused_customer_index = -1
		return
	_empty_label.visible = false
	_row.visible = true
	_focused_customer_index = clampi(
		interaction_state.focused_customer_index,
		0,
		session_service.combat_state.active_customers.size() - 1
	)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var display_indices: Array[int] = []
	for customer_index in range(session_service.combat_state.active_customers.size()):
		if customer_index == _focused_customer_index:
			continue
		display_indices.append(customer_index)
	if _focused_customer_index >= 0:
		display_indices.append(_focused_customer_index)
	for customer_index in display_indices:
		var customer: CustomerInstance = session_service.combat_state.active_customers[customer_index]
		var portrait_texture: Texture2D = UiTextureLibrary.customer_texture(customer.customer_def) if customer.customer_def != null else null
		var spot: CustomerStageSpotView = _instantiate_spot()
		var layout_variant: StringName = &"supporting"
		if session_service.combat_state.active_customers.size() == 1:
			layout_variant = &"solo"
		elif customer_index == _focused_customer_index:
			layout_variant = &"focused"
		spot.configure(
			customer_index,
			customer,
			portrait_texture,
			customer_index == _focused_customer_index,
			interaction_state.is_target_selected(&"customer", customer_index),
			interaction_state.is_zone_targetable(&"customer", customer_index),
			layout_variant
		)
		spot.focus_requested.connect(func(requested_index: int) -> void:
			focus_customer_requested.emit(requested_index)
		)
		spot.target_requested.connect(func(requested_index: int) -> void:
			customer_target_requested.emit(requested_index)
		)
		_row.add_child(spot)
		_spot_nodes.append(spot)
	_apply_layout_profile()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_apply_layout_profile")

func _apply_layout_profile() -> void:
	if _row == null or _spot_nodes.is_empty():
		return
	var count: int = _spot_nodes.size()
	var width_pressure: float = clampf((980.0 - size.x) / 280.0, 0.0, 1.0)
	var height_pressure: float = clampf((250.0 - size.y) / 90.0, 0.0, 1.0)
	var compactness: float = clampf(maxf(width_pressure, height_pressure), 0.0, 1.0)
	var display_scale: float = lerpf(1.08, 0.82, compactness)
	var gap: int = maxi(8, int(round(lerpf(26.0, 10.0, compactness))))
	if count == 1:
		gap = 0
	_row.add_theme_constant_override("separation", gap)
	if count == 1:
		# Solo customers use their own width cap so the focused request cluster does not
		# stretch across the full lane on smaller screens.
		_row.alignment = BoxContainer.ALIGNMENT_END
		var solo_spot: CustomerStageSpotView = _spot_nodes[0]
		var is_compact: bool = size.x < 420.0 or size.y < 220.0
		var solo_min_width: float = minf((280.0 if is_compact else 340.0), maxf(220.0, size.x - 24.0))
		var solo_max_width: float = minf((420.0 if is_compact else 540.0), maxf(solo_min_width, size.x - 4.0))
		var solo_ratio: float = 0.30 if is_compact else 0.34
		var solo_width: float = clampf(size.x * solo_ratio, solo_min_width, solo_max_width)
		solo_spot.custom_minimum_size = Vector2(solo_width, maxf((152.0 if is_compact else 176.0) * display_scale, size.y - 4.0))
		solo_spot.size_flags_horizontal = 0
		solo_spot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		solo_spot.size_flags_stretch_ratio = 1.0
		solo_spot.set_display_scale(clampf(display_scale * (0.88 if is_compact else 1.02), 0.74, 1.12))
		return
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	# Multi-customer mode keeps one focused customer wider than the supporting cast.
	var available_width: float = maxf(420.0, size.x - float(gap * maxi(0, count - 1)))
	var focus_ratio: float = 0.42
	if count == 2:
		focus_ratio = 0.48
	elif count >= 3:
		focus_ratio = 0.36
	var focus_width: float = available_width * focus_ratio
	var non_focus_width: float = available_width
	if count > 1:
		non_focus_width = (available_width - focus_width) / float(count - 1)
	for spot_index in range(_spot_nodes.size()):
		var spot: CustomerStageSpotView = _spot_nodes[spot_index]
		var is_focused: bool = spot_index == _spot_nodes.size() - 1 and _focused_customer_index >= 0
		var desired_width: float = focus_width if is_focused else non_focus_width
		desired_width = clampf(
			desired_width,
			(250.0 if is_focused else 160.0) * display_scale,
			(480.0 if is_focused else 300.0) * display_scale
		)
		spot.custom_minimum_size = Vector2(desired_width, maxf(168.0 * display_scale, size.y - 4.0))
		spot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spot.size_flags_stretch_ratio = 1.55 if is_focused else 1.0
		spot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		spot.set_display_scale(display_scale)

func _instantiate_spot() -> CustomerStageSpotView:
	var node: Node = UiSceneUtils.instantiate_required(customer_spot_scene, "CustomerLaneView.customer_spot_scene")
	var spot: CustomerStageSpotView = node as CustomerStageSpotView
	assert(spot != null, "CustomerLaneView.customer_spot_scene must instantiate CustomerStageSpotView.")
	return spot

func get_customer_spot_control(customer_index: int) -> Control:
	for spot in _spot_nodes:
		if spot != null and spot.get_customer_index() == customer_index:
			return spot
	return null

func render_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var preview_session: SessionService = EncounterEditorPreview.build_session()
	var preview_interaction_state: EncounterInteractionState = EncounterEditorPreview.build_interaction_state(preview_session)
	render(preview_session, preview_interaction_state)
