@tool
class_name CustomerLaneView
extends Control

signal focus_customer_requested(customer_index: int)
signal customer_target_requested(customer_index: int)

@export var customer_spot_scene: PackedScene
@export_group("Lane Scale")
@export var reference_width: float = 900.0
@export var reference_height: float = 180.0
@export_range(0.5, 2.0, 0.01) var display_scale_min: float = 0.84
@export_range(0.5, 2.0, 0.01) var display_scale_max: float = 0.98
@export_group("Lane Spacing")
@export var multi_customer_gap: int = 12
@export var solo_customer_gap: int = 0
@export var height_fill_padding: float = 4.0
@export_group("Solo Customer")
@export_range(0.1, 1.0, 0.01) var solo_width_ratio: float = 0.34
@export var solo_width_min: float = 260.0
@export var solo_width_max: float = 340.0
@export var solo_height_min: float = 160.0
@export_range(0.5, 2.0, 0.01) var solo_display_scale_multiplier: float = 0.96
@export_range(0.5, 2.0, 0.01) var solo_display_scale_min: float = 0.82
@export_range(0.5, 2.0, 0.01) var solo_display_scale_max: float = 1.02
@export_group("Multi Customer")
@export var multi_available_width_min: float = 480.0
@export_range(0.1, 0.9, 0.01) var focus_ratio_default: float = 0.42
@export_range(0.1, 0.9, 0.01) var focus_ratio_for_two_customers: float = 0.48
@export_range(0.1, 0.9, 0.01) var focus_ratio_for_three_or_more: float = 0.36
@export var supporting_width_min: float = 152.0
@export var supporting_width_max: float = 248.0
@export var focused_width_min: float = 228.0
@export var focused_width_max: float = 360.0
@export var customer_height_min: float = 168.0
@export_range(0.1, 4.0, 0.01) var focused_stretch_ratio: float = 1.55

@onready var _empty_label: Label = $EmptyLabel
@onready var _row: HBoxContainer = $Row

var _spot_nodes: Array[CustomerStageSpotView] = []
var _focused_customer_index: int = -1
var _editor_refresh_signature: Array = []

func _ready() -> void:
	if Engine.is_editor_hint():
		_editor_refresh_signature = _make_editor_refresh_signature()
		set_process(true)
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

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var signature: Array = _make_editor_refresh_signature()
	if signature == _editor_refresh_signature:
		return
	_editor_refresh_signature = signature
	_refresh_editor_preview()

func _apply_layout_profile() -> void:
	if _row == null or _spot_nodes.is_empty():
		return
	var count: int = _spot_nodes.size()
	var reference_size: Vector2 = Vector2(maxf(1.0, reference_width), maxf(1.0, reference_height))
	var display_scale: float = clampf(
		minf(size.x / reference_size.x, size.y / reference_size.y),
		display_scale_min,
		display_scale_max
	)
	var gap: int = multi_customer_gap
	if count == 1:
		gap = solo_customer_gap
	_row.add_theme_constant_override("separation", gap)
	if count == 1:
		# Solo customers get a narrower card so their request block keeps a comfortable line length.
		_row.alignment = BoxContainer.ALIGNMENT_END
		var solo_spot: CustomerStageSpotView = _spot_nodes[0]
		var solo_width: float = clampf(
			size.x * solo_width_ratio,
			solo_width_min,
			minf(solo_width_max, size.x - height_fill_padding)
		)
		solo_spot.custom_minimum_size = Vector2(
			solo_width,
			maxf(solo_height_min * display_scale, size.y - height_fill_padding)
		)
		solo_spot.size_flags_horizontal = 0
		solo_spot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		solo_spot.size_flags_stretch_ratio = 1.0
		solo_spot.set_display_scale(
			clampf(
				display_scale * solo_display_scale_multiplier,
				solo_display_scale_min,
				solo_display_scale_max
			)
		)
		return
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	# Multi-customer mode keeps one focused customer wider than the supporting cast.
	var available_width: float = maxf(
		multi_available_width_min,
		size.x - float(gap * maxi(0, count - 1))
	)
	var focus_ratio: float = focus_ratio_default
	if count == 2:
		focus_ratio = focus_ratio_for_two_customers
	elif count >= 3:
		focus_ratio = focus_ratio_for_three_or_more
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
			(focused_width_min if is_focused else supporting_width_min) * display_scale,
			(focused_width_max if is_focused else supporting_width_max) * display_scale
		)
		spot.custom_minimum_size = Vector2(
			desired_width,
			maxf(customer_height_min * display_scale, size.y - height_fill_padding)
		)
		spot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spot.size_flags_stretch_ratio = focused_stretch_ratio if is_focused else 1.0
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

func _make_editor_refresh_signature() -> Array:
	return [
		customer_spot_scene,
		reference_width,
		reference_height,
		display_scale_min,
		display_scale_max,
		multi_customer_gap,
		solo_customer_gap,
		height_fill_padding,
		solo_width_ratio,
		solo_width_min,
		solo_width_max,
		solo_height_min,
		solo_display_scale_multiplier,
		solo_display_scale_min,
		solo_display_scale_max,
		multi_available_width_min,
		focus_ratio_default,
		focus_ratio_for_two_customers,
		focus_ratio_for_three_or_more,
		supporting_width_min,
		supporting_width_max,
		focused_width_min,
		focused_width_max,
		customer_height_min,
		focused_stretch_ratio,
	]

func _refresh_editor_preview() -> void:
	render_editor_preview()
